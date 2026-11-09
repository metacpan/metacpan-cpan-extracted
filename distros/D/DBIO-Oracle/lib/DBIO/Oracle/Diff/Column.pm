package DBIO::Oracle::Diff::Column;
# ABSTRACT: Diff operations for Oracle columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Oracle::Identifier ();
use DBIO::Diff::Compare qw(changed_fields column_change_lossy);
use DBIO::Oracle::Type;

__PACKAGE__->mk_diff_accessors(qw(table_name column_name old_info new_info));


# Canonical comparison key for a column default_value. Introspection stores
# expression defaults as SCALAR refs (e.g. \'current_timestamp') and literal
# defaults as plain strings; a naive string compare stringifies the ref to
# SCALAR(0x...) and reports a phantom diff on every expression default. This
# mirrors the rendering in as_sql so comparison and emission cannot diverge.
#
# Returns undef for the "no default" cases (undef input, literal "null", or
# the \'null' expression ref), so the core's desired_state semantics still
# treat a target-undef as "don't care" and skip the field.
sub _default_key {
  my ($dv) = @_;
  return undef unless defined $dv;
  if (ref $dv eq 'SCALAR') {
    my $expr = lc $$dv;
    $expr =~ s/^\s+//;
    $expr =~ s/\s+\z//;
    return undef if $expr eq 'null';
    return $expr;
  }
  return undef if $dv eq 'null';
  return DBIO::Oracle::Type::render_default_value($dv);
}


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;
  my @ops;

  for my $table_name (sort keys %$target_cols) {
    next unless exists $source_tables->{$table_name}
             && exists $target_tables->{$table_name};

    # The columns of a view follow from its definition, which
    # DBIO::Oracle::Diff::View replaces as a whole (karr k65); ALTER TABLE does
    # not work on a view.
    next if ( $target_tables->{$table_name}{kind} // '' ) eq 'view'
         || ( $source_tables->{$table_name}{kind} // '' ) eq 'view';

    my %src_by_name = map { $_->{column_name} => $_ } @{ $source_cols->{$table_name} // [] };
    my %tgt_by_name = map { $_->{column_name} => $_ } @{ $target_cols->{$table_name} // [] };

    for my $col_name (sort keys %tgt_by_name) {
      my $tgt = $tgt_by_name{$col_name};

      if (!exists $src_by_name{$col_name}) {
        push @ops, $class->new(
          action      => 'add',
          table_name  => $table_name,
          column_name => $col_name,
          new_info    => $tgt,
        );
        next;
      }

      my $src = $src_by_name{$col_name};
      my @changed = _changed_column_fields($src, $tgt,
        defined $target_tables->{$table_name}{schema});
      next unless @changed;

      push @ops, $class->new(
        action      => 'alter',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $src,
        new_info    => $tgt,
      );
    }

    for my $col_name (sort keys %src_by_name) {
      next if exists $tgt_by_name{$col_name};
      push @ops, $class->new(
        action      => 'drop',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $src_by_name{$col_name},
      );
    }

  }

  return @ops;
}

# Run the canonical changed_fields over data_type / not_null / default_value.
# Pre-normalise default_value through _default_key so SCALAR-ref expression
# defaults compare by content (the core would stringify refs to SCALAR(0x..)).
#
# A target that is the introspection of a database (its table entry carries the
# schema) states every column in full: a column without a default is a column
# without one, and the default the source has is removed (karr k63). A model
# written by hand that states none leaves it alone, as the core's desired state
# does.
sub _changed_column_fields {
  my ($src, $tgt, $described) = @_;
  my @changed = _core_changed_fields($src, $tgt);
  push @changed, 'default_value'
    if $described && !defined _default_key($tgt->{default_value})
      && defined _default_key($src->{default_value})
      && !grep { $_ eq 'default_value' } @changed;
  return @changed;
}

sub _core_changed_fields {
  my ($src, $tgt) = @_;
  return changed_fields(
    { %$src, default_value => _default_key($src->{default_value}),
      size => _size_key($src), data_type => _type_key($src) },
    { %$tgt, default_value => _default_key($tgt->{default_value}),
      size => _size_key($tgt), data_type => _type_key($tgt) },
    type   => ['data_type'],
    bool   => ['not_null'],
    scalar => ['default_value'],
    dim    => ['size'],
    desired_state => 1,
  );
}

# The comparison key of a type: the Oracle type it is written as, sizes left
# out (those are the size key's). varchar and varchar2, datetime and
# timestamp, real and binary_float are one type to the server; a difference
# that renders the same cannot be altered (karr k38).
sub _type_key {
  my ($info) = @_;
  return $info->{data_type} unless defined $info->{data_type};
  return DBIO::Oracle::Type::map_dbio_type_to_oracle($info->{data_type});
}

# The comparison key of a size: what the server cannot keep apart is not a
# difference (karr k38).
#
#   * NUMBER(p) is NUMBER(p,0): a numeric size of [p, 0] compares as p.
#   * The defaults of an interval, YEAR(2) and DAY(2) TO SECOND(6), compare as
#     no size, and a scale of undef is a scale of 0.
#   * 6 on a timestamp and 126 on a float are the defaults, which the
#     dictionary reports without a size: they compare as no size.
#   * "20 CHAR" in any spelling is "20 CHAR", "20 BYTE" is 20 (BYTE is the
#     default semantics); CHAR and BYTE stay a difference. A national type is
#     of character semantics always, so its "5 CHAR" is 5.
sub _size_key {
  my ($info) = @_;
  my $size = $info->{size};
  my $type = lc($info->{data_type} // '');
  return $size unless defined $size;

  if (ref $size eq 'ARRAY') {
    return $size->[0] if $type =~ /^(?:numeric|decimal)\z/
      && @$size == 2 && (!defined $size->[1] || $size->[1] == 0);
    return undef if $type eq 'interval day to second'
      && @$size == 2 && ($size->[0] // 2) == 2 && ($size->[1] // 6) == 6;
    return $size;
  }

  return undef if $size eq '6' && $type =~ /^(?:timestamp|datetime)/;
  return undef if $size eq '126' && $type eq 'float';
  return undef if $size eq '2' && $type eq 'interval year to month';

  if ($size =~ /\A\s*(\d+)\s+(char|byte)\s*\z/i) {
    my ($n, $sem) = ($1, uc $2);
    return $n if $sem eq 'BYTE' || $type =~ /^n(?:var)?char2?\z/;
    return "$n CHAR";
  }
  return $size;
}


# Render an info hashref's Oracle DDL type string with size baked in (e.g.
# VARCHAR2(100), NUMBER(12,2)). Used both to emit ADD COLUMN types and to
# detect MODIFY-worthy type changes -- comparing rendered strings (rather
# than bare data_type) catches size-only changes like VARCHAR2(50) ->
# VARCHAR2(100), where data_type is identical on both sides.
sub _rendered_type {
  my ($info) = @_;
  return DBIO::Oracle::Type::map_dbio_type_to_oracle($info->{data_type}, size => $info->{size});
}

sub as_sql {
  my ($self) = @_;

  my $tbl = DBIO::Oracle::Identifier::quote_table($self->table_name);
  my $col = DBIO::Oracle::Identifier::quote($self->column_name);

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = _rendered_type($info);
    my $sql = sprintf 'ALTER TABLE %s ADD (%s %s', $tbl, $col, $type;
    if (defined $info->{default_value}
        && (ref $info->{default_value} || $info->{default_value} ne 'null')) {
      $sql .= ' DEFAULT '
        . DBIO::Oracle::Type::render_default_value($info->{default_value});
    }
    $sql .= ' NOT NULL' if $info->{not_null};
    $sql .= ')';
    return "$sql;";
  }

  if ($self->action eq 'drop') {
    # CASCADE CONSTRAINTS: a column that is part of a multi-column constraint
    # (a unique key over two columns) cannot be dropped without it (ORA-12991);
    # the constraint goes with the column, as the target no longer has it
    return sprintf 'ALTER TABLE %s DROP COLUMN %s CASCADE CONSTRAINTS;', $tbl, $col;
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info;
    my $new = $self->new_info;
    my @stmts;

    my @mods;
    if (_rendered_type($old) ne _rendered_type($new)) {
      push @mods, _rendered_type($new);
    }
    if (defined $new->{default_value}) {
      push @mods, 'DEFAULT ' . DBIO::Oracle::Type::render_default_value($new->{default_value})
        if ref $new->{default_value} || $new->{default_value} ne 'null';
    }
    elsif (!defined $new->{default_value} && defined $old->{default_value}) {
      push @mods, 'DEFAULT NULL';
    }
    if (($old->{not_null} // 0) != ($new->{not_null} // 0)) {
      push @mods, $new->{not_null} ? 'NOT NULL' : 'NULL';
    }

    if (@mods) {
      push @stmts, sprintf 'ALTER TABLE %s MODIFY (%s %s);',
        $tbl, $col, join(' ', @mods);
    }

    return join "\n", @stmts;
  }
}


our %LOSSLESS_PAIRS = map { $_ => 1 } qw(
  char->varchar2
  nchar->nvarchar2
  date->timestamp
);

# The column as column_change_lossy reads it: the Oracle base type in lower
# case (varchar and varchar2, datetime and timestamp, real and binary_float are
# one type) and the size of the rendered type. The character types carry
# their length semantics apart, BYTE when none is written and always CHAR for
# a national type.
sub _lossy_info {
  my ($info) = @_;
  my $rendered = uc _rendered_type({
    data_type => $info->{data_type}, size => $info->{size},
  });
  my @inner = $rendered =~ /\(([^)]*)\)/g;
  (my $base = $rendered) =~ s/\([^)]*\)//g;
  $base =~ s/\s+/ /g;
  $base =~ s/\A | \z//g;

  my %out;
  if ($base eq 'INTEGER') {
    ($base, @inner) = ('NUMBER', '38,0');
  }
  if ($base =~ /\A(?:N?CHAR|N?VARCHAR2)\z/) {
    my ($n, $sem) = ($inner[0] // '') =~ /\A\s*(\d+)(?:\s+(CHAR|BYTE))?\s*\z/
      ? ($1, $2) : ($inner[0]);
    $sem //= $base =~ /\AN/ ? 'CHAR' : 'BYTE';
    $out{sem}  = $sem;
    $out{size} = $n;
  }
  else {
    my $size = join ',', grep { length } @inner;
    $size .= ',0' if $base eq 'NUMBER' && length $size && $size !~ /,/;   # NUMBER(p) is NUMBER(p,0)
    $size = 6   if !length $size && $base =~ /\ATIMESTAMP/;
    $size = 126 if !length $size && $base eq 'FLOAT';
    $out{size} = $size if length $size;
  }
  delete $out{size} unless defined $out{size};
  return { data_type => lc $base, %out };
}


sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  my ($old, $new) = ($self->old_info // {}, $self->new_info // {});
  $new = { %$new, data_type => $old->{data_type} } unless defined $new->{data_type};

  my ($o, $n) = (_lossy_info($old), _lossy_info($new));
  return 1 if defined $o->{sem} && defined $n->{sem} && $o->{sem} ne $n->{sem};

  my $lossy = column_change_lossy($o, $n, \%LOSSLESS_PAIRS);
  if (!$lossy && $o->{data_type} ne $n->{data_type}
      && defined $o->{size} && defined $n->{size}) {
    $lossy = column_change_lossy(
      { data_type => 'x', size => $o->{size} },
      { data_type => 'x', size => $n->{size} },
    );
  }
  return $lossy ? 1 : 0;
}


sub summary {
  my ($self) = @_;
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff::Column - Diff operations for Oracle columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Column-level diff operations for Oracle. Oracle supports:

=over 4

=item * C<ALTER TABLE ... ADD column datatype [DEFAULT value]>

=item * C<ALTER TABLE ... DROP COLUMN column CASCADE CONSTRAINTS> (the
constraints the column is part of go with it; without the clause Oracle refuses
a column of a multi-column constraint, ORA-12991)

=item * C<ALTER TABLE ... MODIFY column datatype [DEFAULT value] [NULL|NOT NULL]>

=back

The table and the column are written double-quoted, as the model spells them
and as the install (L<DBIO::Oracle::DDL>) writes them; bare, Oracle would fold
them to upper case and miss a table made in lower case.

Note: the diff does not recognise a renamed column. A column that exists only
in the target is added and one that exists only in the source is dropped, so a
rename becomes DROP + ADD and the data of the column is lost (Oracle itself
has C<ALTER TABLE ... RENAME COLUMN>, but nothing here emits it).

=head1 ATTRIBUTES

=head2 lossy_pairs

    my %pairs = %DBIO::Oracle::Diff::Column::LOSSLESS_PAIRS;

The changes of the Oracle base type that keep every stored value, as the
C<< old->new >> keys L<DBIO::Diff::Compare/column_change_lossy> reads:
C<char> to C<varchar2> (measured on Oracle Database 23ai Free: the trailing
blanks of a C<CHAR> value stay), C<nchar> to C<nvarchar2> and C<date> to
C<timestamp>. Every other change of the type is lossy, in doubt it is:
C<varchar2> to C<char> pads with blanks, a change between the database and the
national character set may not be representable, C<timestamp> to C<date> cuts
the fractions, C<number> to C<float> changes the decimal reading, and every
change with a LOB changes the representation.

=head1 METHODS

=head2 diff

=head2 as_sql

=head2 lossy

True for an C<alter> that can alter or lose stored values, so that
L<DBIO::Deploy::Base/apply> runs it only with C<allow_destructive>.
The answer is L<DBIO::Diff::Compare/column_change_lossy> over the Oracle base
types and the sizes of the types the two columns are written as, with the
pairs of L</lossy_pairs>:

=over 4

=item * the size of the target is in every component at least that of the live
column, the scale being equal; a C<NUMBER> without a size is unlimited and
holds every size;

=item * C<VARCHAR2(20 CHAR)> and C<VARCHAR2(20 BYTE)> are not mixed: another
length semantics is lossy, and so is another size that is no number;

=item * a change within a pair of L</lossy_pairs> keeps every value as long as
the target is not shorter.

=back

A change of C<NOT NULL> or of the default alone is not lossy (C<NOT NULL> over
a C<NULL> is refused by L<DBIO::Oracle::Deploy/_refuse_unfillable>). C<add> and
C<drop> answer false: a dropped column is a drop, which the diff classes as
destructive by itself.

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
