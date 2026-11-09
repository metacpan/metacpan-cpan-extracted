package DBIO::ClickHouse::Test::Schema::Unsorted;
# ABSTRACT: Test result class -- the source with no primary key

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Core';


__PACKAGE__->table('dbio_test_unsorted');

__PACKAGE__->add_columns(
  foo => { data_type => 'integer', is_nullable => 0 },
  bar => { data_type => 'varchar', size => 32, is_nullable => 0 }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Schema::Unsorted - Test result class -- the source with no primary key

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

A source with B<no> primary key, which L<DBIO::ClickHouse::DDL> renders as
C<ORDER BY tuple()> -- ClickHouse's spelling for "no sorting key". Every other
table in L<DBIO::ClickHouse::Test::Schema> has one, so this is the only place
the empty-key path is deployed.

What it proves on a live server is that C<system.tables.sorting_key> comes back
as the B<empty string> rather than the literal C<tuple()>, which is what
L<DBIO::ClickHouse::Introspect::Tables> assumes when it splits the key into
entries. If the server ever reported C<tuple()> instead, this table would
round-trip to a one-entry sorting key and the diff would demand a rebuild that
can never converge.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
