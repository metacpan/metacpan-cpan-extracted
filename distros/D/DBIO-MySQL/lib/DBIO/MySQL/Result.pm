package DBIO::MySQL::Result;
# ABSTRACT: MySQL/MariaDB-specific Result component for DBIO

use strict;
use warnings;

use base 'DBIO::Core';

__PACKAGE__->mk_classdata('_mysql_indexes' => {});
__PACKAGE__->mk_classdata('_mysql_engine');
__PACKAGE__->mk_classdata('_mysql_charset');
__PACKAGE__->mk_classdata('_mysql_collate');



sub mysql_engine {
  my ($class, $v) = @_;
  $class->_mysql_engine($v) if defined $v;
  return $class->_mysql_engine;
}


sub mysql_charset {
  my ($class, $v) = @_;
  $class->_mysql_charset($v) if defined $v;
  return $class->_mysql_charset;
}


sub mysql_collate {
  my ($class, $v) = @_;
  $class->_mysql_collate($v) if defined $v;
  return $class->_mysql_collate;
}


sub mysql_index {
  my ($class, $name, $def) = @_;
  if ($def) {
    my $indexes = { %{ $class->_mysql_indexes } };
    $indexes->{$name} = $def;
    $class->_mysql_indexes($indexes);
  }
  return $class->_mysql_indexes->{$name};
}


sub mysql_indexes {
  my ($class) = @_;
  return { %{ $class->_mysql_indexes } };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Result - MySQL/MariaDB-specific Result component for DBIO

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MySQL::Result> is a DBIO Result component that adds
MySQL/MariaDB-native metadata to a result class: the table engine,
character set, collation, and custom indexes. It is the counterpart to
L<DBIO::PostgreSQL::Result> / L<DBIO::SQLite::Result> and is read by
L<DBIO::MySQL::DDL> when generating install DDL.

Load it with:

    package MyApp::DB::Result::User;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('MySQL::Result');

    __PACKAGE__->table('users');
    __PACKAGE__->mysql_engine('InnoDB');
    __PACKAGE__->mysql_charset('utf8mb4');
    __PACKAGE__->mysql_collate('utf8mb4_unicode_ci');

    __PACKAGE__->mysql_index('idx_users_name' => {
        columns => ['name'],
    });

    __PACKAGE__->mysql_index('idx_users_fulltext' => {
        using   => 'FULLTEXT',
        columns => ['bio'],
    });

=head1 METHODS

=head2 mysql_engine

    __PACKAGE__->mysql_engine('InnoDB');
    my $e = $class->mysql_engine;

Get or set the MySQL storage engine for this result class's table.
Defaults to C<InnoDB> in the generated DDL when unset.

=head2 mysql_charset

    __PACKAGE__->mysql_charset('utf8mb4');
    my $c = $class->mysql_charset;

Get or set the default character set for this table. Defaults to
C<utf8mb4> in generated DDL when unset.

=head2 mysql_collate

    __PACKAGE__->mysql_collate('utf8mb4_unicode_ci');
    my $c = $class->mysql_collate;

Get or set the default collation for this table. Defaults to
C<utf8mb4_unicode_ci> in generated DDL when unset.

=head2 mysql_index

    __PACKAGE__->mysql_index('idx_users_name' => {
        columns => ['name'],
    });
    __PACKAGE__->mysql_index('idx_users_fulltext' => {
        using   => 'FULLTEXT',
        columns => ['bio'],
    });

Get or set the definition for a named MySQL index. The definition
hashref accepts:

=over 4

=item C<columns> - ArrayRef of column names

=item C<unique> - set to true for a UNIQUE index

=item C<using> - C<BTREE>, C<HASH>, C<FULLTEXT>, or C<SPATIAL>

=back

=head2 mysql_indexes

    my $all = $class->mysql_indexes;

Returns a copy of all index definitions registered on this result class.

=seealso

=over 4

=item * L<DBIO::MySQL::DDL> - consumes C<mysql_indexes>, C<mysql_engine>, C<mysql_charset>, C<mysql_collate>

=item * L<DBIO::PostgreSQL::Result> - the PostgreSQL counterpart

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
