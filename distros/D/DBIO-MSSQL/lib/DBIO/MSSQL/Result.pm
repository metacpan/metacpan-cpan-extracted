package DBIO::MSSQL::Result;
# ABSTRACT: MSSQL-specific Result component for DBIO

use strict;
use warnings;

use base 'DBIO::Core';

__PACKAGE__->mk_classdata('_mssql_indexes' => {});



sub mssql_index {
  my ($class, $name, $def) = @_;
  if ($def) {
    my $indexes = { %{ $class->_mssql_indexes } };
    $indexes->{$name} = $def;
    $class->_mssql_indexes($indexes);
  }
  return $class->_mssql_indexes->{$name};
}


sub mssql_indexes {
  my ($class) = @_;
  return { %{ $class->_mssql_indexes } };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Result - MSSQL-specific Result component for DBIO

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MSSQL::Result> is a DBIO Result component that adds
MSSQL-native metadata to a result class: standalone indexes, including
clustered/nonclustered hints. It is the counterpart to
L<DBIO::MySQL::Result> / L<DBIO::PostgreSQL::Result> and is read by
L<DBIO::MSSQL::DDL> when generating install DDL.

Load it with:

    package MyApp::Schema::Result::User;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('MSSQL::Result');

    __PACKAGE__->table('users');

    __PACKAGE__->mssql_index('idx_users_name' => {
        columns => ['name'],
    });

    __PACKAGE__->mssql_index('idx_users_email' => {
        unique  => 1,
        kind    => 'nonclustered',
        columns => ['email'],
    });

=head1 METHODS

=head2 mssql_index

    __PACKAGE__->mssql_index('idx_users_email' => {
        unique  => 1,
        kind    => 'nonclustered',
        columns => ['email'],
    });

Get or set the definition for a named MSSQL index. The definition
hashref accepts:

=over 4

=item C<columns> - ArrayRef of column names

=item C<unique> - set to true for a UNIQUE index

=item C<kind> - C<clustered> or C<nonclustered>

=back

=head2 mssql_indexes

    my $all = $class->mssql_indexes;

Returns a copy of all index definitions registered on this result class.
Consumed by L<DBIO::MSSQL::DDL>.

=seealso

=over 4

=item * L<DBIO::MSSQL::DDL> - consumes C<mssql_indexes>

=item * L<DBIO::MySQL::Result> - the MySQL counterpart

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
