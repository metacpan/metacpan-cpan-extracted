package DBIO::MySQL::Diff::Column;
# ABSTRACT: Diff operations for MySQL/MariaDB columns

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fields);

__PACKAGE__->mk_diff_accessors(qw(
  table_name column_name old_info new_info
));



sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  return $class->diff_nested(
    $source_cols, $target_cols,
    index_by      => 'column_name',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => \&_mysql_column_changed,
    on_new => sub {
      my ($table_name, $column_name, $new_info) = @_;
      $class->new(action => 'add', table_name => $table_name,
        column_name => $column_name, new_info => $new_info);
    },
    on_changed => sub {
      my ($table_name, $column_name, $old_info, $new_info) = @_;
      $class->new(action => 'modify', table_name => $table_name,
        column_name => $column_name, old_info => $old_info, new_info => $new_info);
    },
    on_gone => sub {
      my ($table_name, $column_name, $old_info) = @_;
      $class->new(action => 'drop', table_name => $table_name,
        column_name => $column_name, old_info => $old_info);
    },
  );
}

# MySQL-specific field spec. Compares type/character-set/precision as
# scalar strings, not_null/default_value/comment as the canonical model
# does. desired_state => 1 means "if the target left it undef, treat as
# don't-care" (we do not know what the live DB will assign for charset
# on a portable text column, see Diff.pm ESCALATION NOTE).
sub _mysql_column_changed {
  my ($old, $new) = @_;
  my @changed = changed_fields($old, $new,
    type    => ['data_type'],
    scalar  => [qw(default_value character_set collation comment)],
    bool    => ['not_null'],
    dim     => [qw(numeric_precision numeric_scale datetime_precision)],
    array   => ['values'],
    desired_state => 1,
  );

  # column_type carries the parameterised type (char(32), decimal(10,2)) and is
  # the real width/precision discriminator, so it is compared here rather than as
  # a plain scalar: MySQL 8.0.17+ drops the *display width* from integer types
  # (bigint(20) -> bigint) while MariaDB and MySQL < 8.0.17 keep it. Normalising
  # the integer display width away on BOTH sides keeps that server-version
  # difference from surfacing as a phantom MODIFY. Desired-state contract: only
  # compare when the target ($new) prescribes a column_type.
  if (defined $new->{column_type}
        && _norm_int_display_width($old->{column_type})
        ne _norm_int_display_width($new->{column_type})) {
    push @changed, 'column_type';
  }

  return scalar @changed;
}

# Strip the parenthesised display width from integer-family column types
# (int / integer / tinyint / smallint / mediumint / bigint), e.g.
# 'bigint(20)' -> 'bigint', 'int(10) unsigned' -> 'int unsigned'. tinyint(1) is
# preserved because MySQL keeps that width to signal BOOLEAN. decimal / numeric
# / char / varchar widths are NOT stripped -- there the parenthesised value is
# semantic, not a display width.
sub _norm_int_display_width {
  my ($ct) = @_;
  return '' unless defined $ct;
  my $s = lc $ct;
  $s =~ s/\s+/ /g;
  $s =~ s/^\s+|\s+$//g;
  $s =~ s/\btinyint\((?!1\))\d+\)/tinyint/g;
  $s =~ s/\b(bigint|smallint|mediumint|integer|int)\(\d+\)/$1/g;
  return $s;
}


sub as_sql {
  my ($self) = @_;
  my $tbl = $self->table_name;
  my $col = $self->column_name;

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = $info->{column_type} || $info->{data_type} || 'text';
    my $sql  = sprintf 'ALTER TABLE `%s` ADD COLUMN `%s` %s', $tbl, $col, $type;
    $sql .= ' NOT NULL' if $info->{not_null};
    if (defined $info->{default_value}) {
      $sql .= " DEFAULT '$info->{default_value}'";
    }
    return "$sql;";
  }
  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE `%s` DROP COLUMN `%s`;', $tbl, $col;
  }
  if ($self->action eq 'modify') {
    my $info = $self->new_info;
    my $type = $info->{column_type} || $info->{data_type} || 'text';
    my $sql  = sprintf 'ALTER TABLE `%s` MODIFY COLUMN `%s` %s', $tbl, $col, $type;
    $sql .= ' NOT NULL' if $info->{not_null};
    if (defined $info->{default_value}) {
      $sql .= " DEFAULT '$info->{default_value}'";
    }
    return "$sql;";
  }
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'add' ? '+'
             : $self->action eq 'drop' ? '-' : '~';
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s',
    $prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::Column - Diff operations for MySQL/MariaDB columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a column-level diff operation in MySQL/MariaDB. Unlike
SQLite, MySQL has full C<ALTER TABLE> support so all of C<ADD COLUMN>,
C<DROP COLUMN>, and C<MODIFY COLUMN> are emitted directly.

Brand-new tables get their columns inline via L<DBIO::MySQL::Diff::Table>
-- this module only sees columns of tables that exist in both source
and target.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MySQL::Diff::Column->diff(
        $source_cols, $target_cols,
        $source_tables, $target_tables,
    );

Compares column lists for tables that exist in both source and target.
Detects added columns, dropped columns, and modified columns (data type,
C<NOT NULL>, or default value changes). Returns a list of
C<DBIO::MySQL::Diff::Column> objects.

The MySQL column shape carries extras beyond the canonical model
(C<column_type>, C<character_set>, C<collation>, C<numeric_precision>,
C<numeric_scale>, C<datetime_precision>, C<values>, C<comment>) so we
use L<DBIO::Diff::Compare/changed_fields> with a MySQL-specific field
spec instead of the canonical L<changed_column_fields|/changed_column_fields>.

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
