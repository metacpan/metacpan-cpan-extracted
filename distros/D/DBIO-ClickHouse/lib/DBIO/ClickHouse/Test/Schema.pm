package DBIO::ClickHouse::Test::Schema;
# ABSTRACT: ClickHouse-native test schema for the DBIO::ClickHouse live suite

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Schema';

__PACKAGE__->load_components('ClickHouse');

__PACKAGE__->load_classes(qw/
  Hit
  HotHit
  Probe
  Reading
  Snapshot
  Unsorted
/);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Schema - ClickHouse-native test schema for the DBIO::ClickHouse live suite

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  my $schema = DBIO::ClickHouse::Test->init_schema;
  my $rs     = $schema->resultset('Hit');

=head1 DESCRIPTION

The test schema the L<DBIO::ClickHouse> live suite deploys. It exists because
the family-wide L<DBIO::Test::Schema> B<cannot> be the test schema for this
driver -- see L</WHY NOT DBIO::Test::Schema> -- and it is deliberately small:
six sources, each of which is the only place one ClickHouse-specific decision
gets deployed against a real server.

=head1 WHY NOT DBIO::Test::Schema

Every other driver distribution calls C<< DBIO::Test->init_schema >> and gets
L<DBIO::Test::Schema>, the ~50-source fixture the family shares.
L<DBIO::ClickHouse::Test> does not, for four reasons in descending order of
severity:

=over 4

=item 1. B<Its identity model is the one thing this driver documents as
impossible.> Nearly every source there has an integer C<is_auto_increment>
primary key. ClickHouse has no sequences and no identity columns, so
L<DBIO::ClickHouse::DDL> emits no default for such a column and
L<DBIO::ClickHouse::Storage/last_insert_id> throws by design. A schema whose
C<< $rs->create({ name => 'x' }) >> cannot work is not a fixture, it is a trap:
the test would be exercising the error path while claiming to exercise the
happy one.

=item 2. B<It carries nothing this driver deploys and everything it drops.>
Foreign keys, unique constraints and standalone indexes are all silently
omitted by the DDL layer (C<docs/adr/0004-no-foreign-keys.md>), so the
relationship-heavy half of that schema deploys to nothing at all -- while the
part that would actually be interesting here, C<ENGINE> and the MergeTree keys,
is a concept it has no way to express.

=item 3. B<A deploy round trip has to be clean to be worth anything.> The whole
premise of L<DBIO::ClickHouse::Deploy> is that a freshly deployed schema
diffs empty against itself. That is a strong statement about C<forty> tables
whose types were designed for SQLite, and a weak one about the handful of
constructs ClickHouse actually has. Here it is the opposite: the schema is
chosen so that a clean diff means every branch of the type map and every
C<clickhouse_table> clause survived the trip through C<system.*>.

=item 4. B<Live runs are rationed.> ClickHouse has no in-memory mode, so every
one of these tables is a real C<CREATE TABLE> on a real server that the
maintainer started by hand for one serial run. Forty of them per test file,
none of which asserts anything ClickHouse-specific, is not a cost this suite
gets to spend.

=back

The offline half of the suite is unaffected -- it never deploys anything.

=head1 THE SOURCES

=over 4

=item * L<DBIO::ClickHouse::Test::Schema::Hit> -- plain C<MergeTree>, UUID key,
the source the insert and mutation paths run against.

=item * L<DBIO::ClickHouse::Test::Schema::Snapshot> --
C<ReplacingMergeTree(version)>, so C<FINAL> has something to deduplicate.

=item * L<DBIO::ClickHouse::Test::Schema::Reading> -- C<PARTITION BY>, a
C<PRIMARY KEY> prefix of a two-column sorting key, C<LowCardinality>.

=item * L<DBIO::ClickHouse::Test::Schema::Probe> -- one column per branch of
the DDL type map.

=item * L<DBIO::ClickHouse::Test::Schema::Unsorted> -- no primary key, hence
C<ORDER BY tuple()>.

=item * L<DBIO::ClickHouse::Test::Schema::HotHit> -- a non-virtual view, the
only C<CREATE VIEW> this driver ever executes.

=back

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Test> - deploys this schema into a scratch database

=item * L<DBIO::Test::Schema> - the family fixture this one replaces, and why

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
