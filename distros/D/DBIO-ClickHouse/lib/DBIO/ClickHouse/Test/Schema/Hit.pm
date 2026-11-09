package DBIO::ClickHouse::Test::Schema::Hit;
# ABSTRACT: Test result class -- the plain MergeTree table with a UUID key

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Core';


__PACKAGE__->table('dbio_test_hit');

__PACKAGE__->add_columns(
  id       => { data_type => 'uuid',    is_auto_increment => 1, is_nullable => 0 },
  url      => { data_type => 'varchar', size => 2048, is_nullable => 0 },
  hits     => { data_type => 'integer', extra => { unsigned => 1 }, is_nullable => 0 },
  snapshot => { data_type => 'integer', is_nullable => 1 },
  ts       => { data_type => 'datetime', is_nullable => 1 }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  snapshot_row => 'DBIO::ClickHouse::Test::Schema::Snapshot',
  { 'foreign.id' => 'self.snapshot' },
  { join_type => 'left', is_foreign_key_constraint => 0 }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Schema::Hit - Test result class -- the plain MergeTree table with a UUID key

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The ordinary table of L<DBIO::ClickHouse::Test::Schema>: plain C<MergeTree>,
sorting key from the DBIO primary key, and a UUID key declared
C<< is_auto_increment => 1 >> -- which on this driver means "the client
generates it" (L<DBIO::ClickHouse::Storage/PRIMARY KEYS AND IDENTITY>) and
makes C<< $rs->create >> work at all.

C<snapshot> is the join column for the C<snapshot_row> relationship; it exists so a live test can
put a C<FINAL> query under a join without inventing a second schema. There is
no foreign key in the database -- ClickHouse has none
(C<docs/adr/0004-no-foreign-keys.md>) -- the relationship is DBIO metadata only.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
