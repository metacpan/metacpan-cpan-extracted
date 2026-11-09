package DBIO::ClickHouse::Test::Schema::Snapshot;
# ABSTRACT: Test result class -- a ReplacingMergeTree table for FINAL

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Core';


__PACKAGE__->load_components('ClickHouse::Result');

__PACKAGE__->table('dbio_test_snapshot');

__PACKAGE__->add_columns(
  id      => { data_type => 'integer', is_nullable => 0 },
  label   => { data_type => 'varchar', size => 64, is_nullable => 0 },
  version => { data_type => 'bigint', extra => { unsigned => 1 }, is_nullable => 0 }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  hits => 'DBIO::ClickHouse::Test::Schema::Hit',
  { 'foreign.snapshot' => 'self.id' }
);

__PACKAGE__->clickhouse_table({
  engine   => 'ReplacingMergeTree(version)',
  order_by => ['id']
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Schema::Snapshot - Test result class -- a ReplacingMergeTree table for FINAL

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

A C<ReplacingMergeTree(version)> table, the engine that makes the C<final>
resultset attribute (L<DBIO::ClickHouse::SQLMaker/final>) mean something:
insert the same C<id> twice and only C<FINAL> collapses the two rows to the one
with the higher C<version>.

It is also the only source in L<DBIO::ClickHouse::Test::Schema> whose
C<engine_expression> carries an argument, so the introspection of
C<engine_full> -- as opposed to C<system.tables.engine>, which drops the
argument -- is exercised by simply deploying this schema.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
