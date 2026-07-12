package DBIO::SQLite::Result;
# ABSTRACT: SQLite-specific Result component for DBIO

use strict;
use warnings;

use base 'DBIO::Base';

__PACKAGE__->mk_classdata('_sqlite_indexes' => {});



sub sqlite_index {
  my ($class, $name, $def) = @_;
  if ($def) {
    my $indexes = { %{ $class->_sqlite_indexes } };
    $indexes->{$name} = $def;
    $class->_sqlite_indexes($indexes);
  }
  return $class->_sqlite_indexes->{$name};
}


sub sqlite_indexes {
  my ($class) = @_;
  return { %{ $class->_sqlite_indexes } };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Result - SQLite-specific Result component for DBIO

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::SQLite::Result> is a DBIO Result component that adds
SQLite-native metadata to a result class: custom indexes (including
partial and expression indexes). It is the counterpart to
L<DBIO::PostgreSQL::Result> / L<DBIO::MySQL::Result> and is read by
L<DBIO::SQLite::DDL> when generating install DDL.

Load it with:

    package MyApp::DB::Result::User;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('SQLite::Result');

    __PACKAGE__->table('users');

    __PACKAGE__->sqlite_index('idx_users_active' => {
        columns => ['role'],
        where   => "role != 'suspended'",   # partial index
    });

    __PACKAGE__->sqlite_index('idx_users_name_lower' => {
        expression => 'lower(name)',         # expression index
    });

=head1 METHODS

=head2 sqlite_index

    __PACKAGE__->sqlite_index('idx_users_tags' => {
        columns => ['tags'],
    });
    __PACKAGE__->sqlite_index('idx_users_active' => {
        columns => ['role'],
        where   => "role != 'suspended'",
    });

Get or set the definition for a named SQLite index. The definition
hashref accepts:

=over 4

=item C<columns> - ArrayRef of column names

=item C<unique> - set to true for a UNIQUE index

=item C<where> - partial index predicate (SQL expression string)

=item C<expression> - expression index expression (replaces C<columns>)

=back

=head2 sqlite_indexes

    my $all = $class->sqlite_indexes;  # hashref of name => def

Returns a copy of all index definitions registered on this result class.

=seealso

=over 4

=item * L<DBIO::SQLite::DDL> - consumes C<sqlite_indexes> when generating DDL

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
