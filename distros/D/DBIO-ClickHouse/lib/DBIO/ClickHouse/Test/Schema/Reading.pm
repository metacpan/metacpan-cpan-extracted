package DBIO::ClickHouse::Test::Schema::Reading;
# ABSTRACT: Test result class -- partition key, PRIMARY KEY prefix, LowCardinality

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Core';


__PACKAGE__->load_components('ClickHouse::Result');

__PACKAGE__->table('dbio_test_reading');

__PACKAGE__->add_columns(
  sensor => { data_type => 'varchar', size => 32, is_nullable => 0,
              extra => { low_cardinality => 1 } },
  ts     => { data_type => 'datetime', is_nullable => 0 },
  day    => { data_type => 'date',     is_nullable => 0 },
  value  => { data_type => 'double precision', is_nullable => 0 }
);

__PACKAGE__->set_primary_key('sensor', 'ts');

__PACKAGE__->clickhouse_table({
  engine       => 'MergeTree',
  partition_by => 'toYYYYMM(ts)',
  primary_key  => ['sensor'],
  order_by     => ['sensor', 'ts']
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Schema::Reading - Test result class -- partition key, PRIMARY KEY prefix, LowCardinality

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The table that exercises every C<clickhouse_table> clause a C<CREATE TABLE>
can carry at once: a C<PARTITION BY> expression, a C<PRIMARY KEY> that is a
strict B<prefix> of the sorting key, and a multi-column C<ORDER BY>.

Deploying it is what puts three separate live assumptions under test without a
single assertion being written for them:

=over 4

=item * C<system.tables> reports C<partition_key>, C<sorting_key> and
C<primary_key> as distinct values over the MySQL wire protocol -- if the
primary key merely mirrored the sorting key here, the round trip would come
back different from what was deployed.

=item * C<Date32> and C<DateTime64(3)> (what the portable C<date> and
C<datetime> map to, see L<DBIO::ClickHouse::DDL/Type mapping>) are accepted by
the server version under test.

=item * C<toYYYYMM()> accepts a C<DateTime64> argument, which is the partition
expression any time-series schema on this driver will write.

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
