package DBIO::Informix::Diff::UniqueConstraint;
# ABSTRACT: Diff operations for Informix unique constraints

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Informix::Util qw(_quote_ident);

__PACKAGE__->mk_diff_accessors(qw(table_name constraint_name columns replaced));



sub _key { join ',', @{ $_[0]{columns} // [] } }

sub _keyed {
  my ($uniques) = @_;
  my %out;
  for my $table (keys %{ $uniques // {} }) {
    $out{$table} = [ map { +{ %$_, _content_key => _key($_) } } @{ $uniques->{$table} // [] } ];
  }
  return \%out;
}

# the name written on ADD: one the model states, never one the server assigned
sub _explicit_name {
  my ($name) = @_;
  return undef if !defined $name || !length $name || $name =~ /\Au\d+_\d+\z/;
  return $name;
}

sub _add {
  my ($class, $table, $uc) = @_;
  return $class->new(action => 'add', table_name => $table,
    constraint_name => _explicit_name($uc->{constraint_name}), columns => $uc->{columns});
}

sub _drop {
  my ($class, $table, $uc) = @_;
  return $class->new(action => 'drop', table_name => $table,
    constraint_name => $uc->{constraint_name}, columns => $uc->{columns});
}


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  my @ops = $class->diff_nested(_keyed($source), _keyed($target),
    index_by      => '_content_key',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    on_new  => sub { $class->_add($_[0], $_[2]) },
    on_gone => sub { $class->_drop($_[0], $_[2]) },
  );

  # Tables only in the target: their constraints are added after the CREATE TABLEs.
  my $keyed = _keyed($target);
  for my $table (sort keys %$keyed) {
    next if !$target_tables || !exists $target_tables->{$table};
    next if $source_tables && exists $source_tables->{$table};
    push @ops, map { $class->_add($table, $_) } @{ $keyed->{$table} };
  }

  my %back = map { join("\0", $_->table_name, $_->constraint_name) => 1 }
    grep { $_->action eq 'add' && defined $_->constraint_name } @ops;
  for my $op (grep { $_->action eq 'drop' } @ops) {
    my $name = $op->constraint_name;
    $op->replaced(1) if defined $name && $back{ join "\0", $op->table_name, $name };
  }

  return @ops;
}


sub dropped_keys {
  my ($class, @ops) = @_;
  return { map { join("\0", $_->table_name, sort @{ $_->columns }) => 1 }
    grep { $_->action eq 'drop' } @ops };
}


sub as_sql {
  my ($self) = @_;
  my $tbl = _quote_ident($self->table_name);

  if ($self->action eq 'drop') {
    my $name = $self->constraint_name;
    die sprintf "Informix unique constraint on table %s cannot be dropped: the model holds no name for it\n",
      $self->table_name unless defined $name;
    return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $tbl, _quote_ident($name);
  }

  return sprintf 'ALTER TABLE %s ADD CONSTRAINT UNIQUE (%s)%s;', $tbl,
    join(', ', map { _quote_ident($_) } @{ $self->columns }),
    (defined $self->constraint_name ? ' CONSTRAINT ' . _quote_ident($self->constraint_name) : '');
}


sub summary {
  my ($self) = @_;
  return sprintf '%s unique: (%s) on %s', $self->summary_prefix,
    join(', ', @{ $self->columns }), $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Diff::UniqueConstraint - Diff operations for Informix unique constraints

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a unique constraint diff operation: C<ALTER TABLE ... ADD
CONSTRAINT UNIQUE (...)> or C<ALTER TABLE ... DROP CONSTRAINT>. The
constraints of a brand-new table are added the same way, after every
C<CREATE TABLE> and before the foreign keys (a foreign key may reference
one). Constraints of a table that is dropped go with the table.

Constraints are compared by the columns they cover, in order, not by name:
the name the server gives a constraint without one (C<u E<lt>tabidE<gt>_E<lt>nE<gt>>,
written C<u136_41>) differs from one database to the next. The name serves to
drop a constraint, and is written on an add unless the server assigned it.
A changed constraint is its old form dropped and the new one added.

    ALTER TABLE t ADD CONSTRAINT UNIQUE (a, b) CONSTRAINT name;
    ALTER TABLE t DROP CONSTRAINT name;

=head1 ATTRIBUTES

=head2 replaced

True for the C<drop> of a unique constraint that comes back in the same diff as
an C<add> of the same table and the same name (a changed one): the first half
of a change, not destructive (core ADR 0080,
L<DBIO::Diff::Base/destructive_operations>). A constraint that disappears, or
one the server named itself, is destructive.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Informix::Diff::UniqueConstraint->diff(
        $source_uniques, $target_uniques, $source_tables, $target_tables,
    );

=head2 dropped_keys

    my $dropped = DBIO::Informix::Diff::UniqueConstraint->dropped_keys(@ops);

A hash reference naming the constraints the operations drop, each as the
table and the sorted column names joined by NUL, the form
L<DBIO::Informix::Diff::ForeignKey/diff> reads to find the keys over them.

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
