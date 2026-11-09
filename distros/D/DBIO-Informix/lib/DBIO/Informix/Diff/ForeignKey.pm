package DBIO::Informix::Diff::ForeignKey;
# ABSTRACT: Diff operations for Informix foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Informix::Util qw(_quote_ident);

__PACKAGE__->mk_diff_accessors(qw(table_name constraint_name fk_info replaced));




sub fk_name {
  my ($table, $fk) = @_;
  return $fk->{constraint_name} // $fk->{fk_name}
    // join '_', 'fk', $table, @{ $fk->{from_columns} // [] }, $fk->{to_table};
}

# The name the model gives a key, as DROP CONSTRAINT needs it (the server's
# own included).
sub _real_name {
  my ($fk) = @_;
  my $n = $fk->{constraint_name} // $fk->{fk_name};
  return (defined $n && length $n) ? $n : undef;
}

# The name that is written on ADD: one the model states, never one the server
# assigned (r<tabid>_<n>).
sub _explicit_name {
  my ($fk) = @_;
  my $n = _real_name($fk);
  return undef if !defined $n || $n =~ /\Ar\d+_\d+\z/;
  return $n;
}

sub _rule {
  my ($v) = @_;
  return '' if !defined $v || $v eq '';
  $v = uc $v;
  $v =~ s/\s+/ /g;
  return 'NONE' if $v eq 'R' || $v eq 'RESTRICT' || $v eq 'NO ACTION';
  return 'CASCADE' if $v eq 'CASCADE' || $v eq 'C';
  return $v;
}

# Die unless the key uses only what Informix can express.
sub _assert_supported {
  my ($table, $fk) = @_;
  my $name = fk_name($table, $fk);
  my $del = _rule($fk->{on_delete} // $fk->{del_rule});
  my $upd = _rule($fk->{on_update} // $fk->{upd_rule});
  die sprintf "Informix foreign key %s on table %s: ON DELETE %s is not supported "
    . "(Informix has only ON DELETE CASCADE); refusing to drop it silently\n",
    $name, $table, $fk->{on_delete} // $fk->{del_rule}
    if $del ne '' && $del ne 'NONE' && $del ne 'CASCADE';
  die sprintf "Informix foreign key %s on table %s: ON UPDATE %s is not supported "
    . "(Informix has no ON UPDATE); refusing to drop it silently\n",
    $name, $table, $fk->{on_update} // $fk->{upd_rule}
    if $upd ne '' && $upd ne 'NONE';
  return;
}

sub _cascade {
  my ($fk) = @_;
  return _rule($fk->{on_delete} // $fk->{del_rule}) eq 'CASCADE' ? 1 : 0;
}


sub fk_clause {
  my ($table, $fk) = @_;
  _assert_supported($table, $fk);
  my $name = _explicit_name($fk);
  return sprintf 'FOREIGN KEY (%s) REFERENCES %s(%s)%s%s',
    join(', ', map { _quote_ident($_) } @{ $fk->{from_columns} }),
    _quote_ident($fk->{to_table}),
    join(', ', map { _quote_ident($_) } @{ $fk->{to_columns} }),
    (_cascade($fk) ? ' ON DELETE CASCADE' : ''),
    (defined $name ? ' CONSTRAINT ' . _quote_ident($name) : '');
}

# Defaults compare as '', cascade as CASCADE, anything else as itself (so the
# change is seen and the add refuses it).
sub _view_rule {
  my ($v) = @_;
  my $r = _rule($v);
  return $r eq 'NONE' ? '' : $r;
}

# Comparison view: Informix knows only cascade or not, and no ON UPDATE.
sub _view {
  my ($fk) = @_;
  return {
    from_columns => $fk->{from_columns},
    to_columns   => $fk->{to_columns},
    to_table     => $fk->{to_table},
    on_delete    => _view_rule($fk->{on_delete} // $fk->{del_rule}),
    on_update    => _view_rule($fk->{on_update} // $fk->{upd_rule}),
  };
}

# Identity of a key: what it says, not what it is called.
sub _content_key {
  my ($fk) = @_;
  my $v = _view($fk);
  return join "\0", join(',', @{ $v->{from_columns} // [] }), $v->{to_table} // '',
    join(',', @{ $v->{to_columns} // [] }), $v->{on_delete}, $v->{on_update};
}

sub _keyed {
  my ($fks) = @_;
  my %out;
  for my $table (keys %{ $fks // {} }) {
    $out{$table} = [ map { +{ %$_, _content_key => _content_key($_) } }
      @{ $fks->{$table} // [] } ];
  }
  return \%out;
}

sub _add {
  my ($class, $table, $fk) = @_;
  _assert_supported($table, $fk);
  return $class->new(action => 'add', table_name => $table,
    constraint_name => _explicit_name($fk), fk_info => $fk);
}

sub _drop {
  my ($class, $table, $fk) = @_;
  return $class->new(action => 'drop', table_name => $table,
    constraint_name => _real_name($fk), fk_info => $fk);
}


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $dropped_keys) = @_;

  my @ops = $class->diff_nested(_keyed($source), _keyed($target),
    index_by      => '_content_key',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    on_new  => sub { $class->_add($_[0], $_[2]) },
    on_gone => sub { $class->_drop($_[0], $_[2]) },
  );
  # a changed key is its old form dropped, then the new one added
  @ops = ((grep { $_->action eq 'drop' } @ops), (grep { $_->action ne 'drop' } @ops));

  # A key that stays but points at a unique constraint dropped here: the
  # server takes the key along with the constraint (a later DROP CONSTRAINT of
  # the key is -623), so the key is dropped first and added again after
  # (karr k27). A key the target no longer has is already an ordinary drop.
  if ($dropped_keys && %$dropped_keys) {
    my $want = _keyed($target);
    my %gone = map { $_->table_name . "\0" . _content_key($_->fk_info) => 1 } grep { $_->action eq 'drop' } @ops;
    my (@rebuilt_drop, @rebuilt_add);
    for my $table (sort keys %{ _keyed($source) }) {
      next if !$source_tables || !exists $source_tables->{$table} || !$target_tables || !exists $target_tables->{$table};
      my %stays = map { $_->{_content_key} => $_ } @{ $want->{$table} // [] };
      for my $fk (@{ $source->{$table} // [] }) {
        my $key = _content_key($fk);
        next if $gone{"$table\0$key"} || !exists $stays{$key};
        next unless $dropped_keys->{ join "\0", $fk->{to_table} // '', sort @{ $fk->{to_columns} // [] } };
        push @rebuilt_drop, $class->_drop($table, $fk);
        push @rebuilt_add,  $class->_add($table, $stays{$key});
      }
    }
    push @ops, @rebuilt_drop, @rebuilt_add;
    @ops = ((grep { $_->action eq 'drop' } @ops), (grep { $_->action ne 'drop' } @ops));
  }

  # Tables only in the target: their keys are added after the CREATE TABLEs.
  my $keyed = _keyed($target);
  for my $table (sort keys %$keyed) {
    next if !$target_tables || !exists $target_tables->{$table};
    next if $source_tables && exists $source_tables->{$table};
    push @ops, map { $class->_add($table, $_) }
      sort { $a->{_content_key} cmp $b->{_content_key} } @{ $keyed->{$table} };
  }

  # A drop whose key comes back in this diff is the first half of a change.
  # "Comes back" is the same table and the same name when the model states
  # one; the names the server assigns differ from one database to the next, so
  # a key without a stated name comes back as a key over the same columns.
  my (%back_name, %back_cols);
  for my $op (grep { $_->action eq 'add' } @ops) {
    $back_name{ join "\0", $op->table_name, $op->constraint_name } = 1 if defined $op->constraint_name;
    $back_cols{ join "\0", $op->table_name, @{ $op->fk_info->{from_columns} // [] } } = 1;
  }
  for my $op (grep { $_->action eq 'drop' } @ops) {
    my $name = $op->constraint_name;
    my $by_name = defined $name && $name !~ /\Ar\d+_\d+\z/
      && $back_name{ join "\0", $op->table_name, $name };
    my $by_cols = (!defined $name || $name =~ /\Ar\d+_\d+\z/)
      && $back_cols{ join "\0", $op->table_name, @{ $op->fk_info->{from_columns} // [] } };
    $op->replaced(1) if $by_name || $by_cols;
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $tbl = _quote_ident($self->table_name);

  if ($self->action eq 'drop') {
    my $name = $self->constraint_name;
    die sprintf "Informix foreign key on table %s cannot be dropped: the model holds no name for it\n",
      $self->table_name unless defined $name;
    return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $tbl, _quote_ident($name);
  }

  return sprintf 'ALTER TABLE %s ADD CONSTRAINT %s;', $tbl,
    fk_clause($self->table_name, $self->fk_info);
}


sub summary {
  my ($self) = @_;
  return sprintf '%s fk: %s on %s', $self->summary_prefix,
    $self->constraint_name // fk_name($self->table_name, $self->fk_info),
    $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Diff::ForeignKey - Diff operations for Informix foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a foreign key diff operation on a table that exists in both
models: C<ALTER TABLE ... ADD CONSTRAINT FOREIGN KEY ...> or
C<ALTER TABLE ... DROP CONSTRAINT>. The keys of a brand-new table are added
the same way, after every C<CREATE TABLE> (never inline: the referenced table
may be created later in the same diff). Keys of a table that is dropped go
with the table.

Keys are compared by what they say, not by name: columns, target table, target
columns and the delete action. Informix has no ON UPDATE. The name the server
gives a key without one, C<r E<lt>tabidE<gt>_E<lt>nE<gt>> (written C<r136_41>,
no blank), differs from one database to the next and is never a difference.
The name (C<constraint_name>; the raw introspector key C<fk_name> is read as
well) serves only to drop a key. A key is added without a name, unless the
model names one that is not a server-assigned one. A changed key becomes a
drop followed by an add. A key to drop whose model holds no name dies at
C<as_sql>, naming the table.

The syntax is the documented Informix one (constraint name B<after> the
definition):

    ALTER TABLE t ADD CONSTRAINT FOREIGN KEY (a, b) REFERENCES r (x, y)
      [ON DELETE CASCADE] CONSTRAINT name;
    ALTER TABLE t DROP CONSTRAINT name;

B<Live unmeasured:> there is no Informix server nor a buildable
DBD::Informix here; the statements are written from the IBM/HCL
documentation and have never run against a server.

B<Rules, source:> C<sysreferences.delrule> is CHAR(1): C<C> cascading
delete, C<R> restrict (the default); C<updrule> and C<matchtype> are
documented as reserved for future use and always show C<R> and C<N>
(HCL OneDB SQL reference, I<sysreferences> table,
L<https://help.hcl-software.com/onedb/1.0.1/sqr/ids_sqr_055.html>; the same
text is in the IBM Informix SQL reference).

B<Refusal:> Informix knows exactly one referential action, C<ON DELETE
CASCADE>; there is no C<ON UPDATE>. Every other action (C<on_delete> /
C<on_update>, or the raw C<del_rule> / C<upd_rule>, with a value other than
the default) is refused with a C<die> naming table, constraint and reason,
for a key of an existing table as well as for one of a new table, instead of
being left out silently. Silent defaults: undefined or empty, C<NO ACTION>,
C<RESTRICT>, raw C<R>; cascade is C<CASCADE> or raw C<C> on the delete side.
C<DISABLED>/C<INDEX DISABLED> modes are not modelled.

=head1 ATTRIBUTES

=head2 replaced

True for the C<drop> of a foreign key that comes back in the same diff as an
C<add> of the same table and the same name (a changed key, or one rebuilt
around a constraint it references): the first half of a change, not
destructive (core ADR 0080, L<DBIO::Diff::Base/destructive_operations>). A key
the server named itself comes back as a key over the same columns. A key that
disappears is destructive.

=head1 METHODS

=head2 fk_name

    my $name = DBIO::Informix::Diff::ForeignKey::fk_name($table, $fk);

The name of a key, for messages and summaries: C<constraint_name>, else
C<fk_name>, else the descriptive
C<fk_E<lt>tableE<gt>_E<lt>colsE<gt>_E<lt>targetE<gt>>. It is not written
into SQL unless the model names the key (see C<fk_clause>).

=head2 fk_clause

    my $sql = DBIO::Informix::Diff::ForeignKey::fk_clause($table, $fk);

C<FOREIGN KEY (...) REFERENCES r (...) [ON DELETE CASCADE] [CONSTRAINT name]>,
used by the C<ALTER TABLE ... ADD CONSTRAINT>. The name is left out when the
model names none or only a server-assigned one.

=head2 diff

    my @ops = DBIO::Informix::Diff::ForeignKey->diff(
        $source_fks, $target_fks, $source_tables, $target_tables,
        $dropped_keys,
    );

C<$dropped_keys> (optional) is a hash reference whose keys name the unique
constraints dropped in the same diff, as the table, a NUL and the sorted
column names joined by NUL (C<DBIO::Informix::Diff::UniqueConstraint::dropped_keys>).
A key that stays but references one of them is dropped and added again.

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
