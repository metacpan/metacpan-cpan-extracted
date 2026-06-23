package DBIO::MySQL::Diff::ForeignKey;
# ABSTRACT: Diff operations for MySQL/MariaDB foreign keys

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fk_fields);

__PACKAGE__->mk_diff_accessors(qw(
  table_name constraint_name fk_info
));



sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  return $class->diff_nested(
    $source, $target,
    index_by      => 'constraint_name',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => \&changed_fk_fields,
    on_new => sub {
      my ($table_name, $constraint_name, $fk_info) = @_;
      $class->new(action => 'add', table_name => $table_name,
        constraint_name => $constraint_name, fk_info => $fk_info);
    },
    on_changed => sub {
      my ($table_name, $constraint_name, $old_info, $new_info) = @_;
      (
        $class->new(action => 'drop', table_name => $table_name,
          constraint_name => $constraint_name, fk_info => $old_info),
        $class->new(action => 'add',  table_name => $table_name,
          constraint_name => $constraint_name, fk_info => $new_info),
      );
    },
    on_gone => sub {
      my ($table_name, $constraint_name, $fk_info) = @_;
      $class->new(action => 'drop', table_name => $table_name,
        constraint_name => $constraint_name, fk_info => $fk_info);
    },
  );
}


sub as_sql {
  my ($self) = @_;
  my $tbl  = $self->table_name;
  my $name = $self->constraint_name;

  if ($self->action eq 'add') {
    my $info = $self->fk_info;
    my $from = join(', ', map { "`$_`" } @{ $info->{from_columns} });
    my $to   = join(', ', map { "`$_`" } @{ $info->{to_columns} });
    my $sql  = sprintf
      'ALTER TABLE `%s` ADD CONSTRAINT `%s` FOREIGN KEY (%s) REFERENCES `%s`(%s)',
      $tbl, $name, $from, $info->{to_table}, $to;
    $sql .= " ON UPDATE $info->{on_update}" if $info->{on_update} && $info->{on_update} ne 'NO ACTION';
    $sql .= " ON DELETE $info->{on_delete}" if $info->{on_delete} && $info->{on_delete} ne 'NO ACTION';
    return "$sql;";
  }
  return sprintf 'ALTER TABLE `%s` DROP FOREIGN KEY `%s`;', $tbl, $name;
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'add' ? '+' : '-';
  return sprintf '  %sfk: %s on %s', $prefix, $self->constraint_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::ForeignKey - Diff operations for MySQL/MariaDB foreign keys

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a foreign key diff operation: C<ADD CONSTRAINT> or
C<DROP FOREIGN KEY>. FKs that already exist on a brand-new table are
created inline by L<DBIO::MySQL::Diff::Table> -- this module only
handles FK changes on tables that exist in both source and target.

FK identity is by C<constraint_name>. A definition change becomes a
drop-then-add pair (MySQL has no C<ALTER FOREIGN KEY>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::MySQL::Diff::ForeignKey->diff(
        $source_fks, $target_fks, $source_tables, $target_tables,
    );

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
