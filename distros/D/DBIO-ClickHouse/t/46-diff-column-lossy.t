use strict;
use warnings;
use Test::More;

use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::Diff;
use DBIO::ClickHouse::Diff::Column;

# t/46-diff-column-lossy.t -- which MODIFY COLUMN may alter stored values
# (core k399, ADR 0080). WHY: DBIO::Deploy::Base runs a diff that holds a lossy
# operation only with allow_destructive; the answer is the driver's, per type
# pair. A pair is lossless only where ClickHouse converts without changing any
# value; in doubt it is lossy, because the wrong answer on the other side
# rewrites data without anyone having asked. Offline: ops only, no server.

sub op {
  my ($from, $to) = @_;
  return DBIO::ClickHouse::Diff::Column->new(
    action => 'alter', table_name => 't', column_name => 'c',
    old_info => { data_type => $from }, new_info => { data_type => $to },
  );
}

my @lossless = (
  [ Int8    => 'Int16' ], [ Int32 => 'Int64' ], [ Int16 => 'Int256' ],
  [ UInt8   => 'UInt32' ], [ UInt32 => 'UInt64' ],
  [ 'Nullable(Int32)' => 'Nullable(Int64)' ],
  [ Int32   => 'Nullable(Int32)' ],
  [ String  => 'Nullable(String)' ],
  [ String  => 'LowCardinality(String)' ],
  [ 'Decimal(10, 2)' => 'Decimal(12, 2)' ],
  [ 'Decimal32(2)'   => 'Decimal64(2)' ],
  [ 'FixedString(4)' => 'FixedString(8)' ],
  [ Date    => 'Date32' ],
  [ DateTime => 'DateTime64(3)' ],
  [ 'DateTime64(3)' => 'DateTime64(6)' ],
  [ "DateTime64(3, 'UTC')" => "DateTime64(6, 'UTC')" ],
  [ "Enum8('a' = 1, 'b' = 2)" => "Enum8('a' = 1, 'b' = 2, 'c' = 3)" ],
  [ "Enum8('a' = 1)" => "Enum16('a' = 1, 'b' = 300)" ],
  [ 'Nullable(Int32)' => 'Nullable(Int32)' ],
);
ok !op(@$_)->lossy, "$_->[0] -> $_->[1] keeps every value" for @lossless;

my @lossy = (
  [ Int64   => 'Int32' ], [ Int32 => 'Int8' ],
  [ Int32   => 'UInt32' ], [ UInt8 => 'Int16' ],
  [ Int32   => 'Float64' ], [ Float32 => 'Float64' ], [ Float64 => 'Float32' ],
  [ 'Nullable(String)' => 'String' ],
  [ 'Nullable(Int32)'  => 'Int64' ],
  [ 'Nullable(Int32)'  => 'LowCardinality(Int32)' ],
  [ String  => 'Int32' ], [ Int32 => 'String' ],
  [ String  => 'FixedString(8)' ], [ 'FixedString(8)' => 'String' ],
  [ 'FixedString(8)' => 'FixedString(4)' ],
  [ 'Decimal(10, 2)' => 'Decimal(10, 3)' ], [ 'Decimal(12, 2)' => 'Decimal(10, 2)' ],
  [ 'Decimal(10, 2)' => 'Float64' ],
  [ Date32  => 'Date' ], [ Date => 'DateTime' ],
  [ 'DateTime64(6)' => 'DateTime64(3)' ],
  [ "DateTime64(3, 'UTC')" => "DateTime64(3, 'Europe/Berlin')" ],
  [ "Enum8('a' = 1, 'b' = 2)" => "Enum8('a' = 1)" ],
  [ "Enum8('a' = 1, 'b' = 2)" => "Enum8('a' = 2, 'b' = 1)" ],
  [ "Enum16('a' = 1)" => "Enum8('a' = 1)" ],
  [ 'Array(Int32)' => 'Array(Int64)' ],
  [ 'Map(String, Int32)' => 'Map(String, Int64)' ],
);
ok op(@$_)->lossy, "$_->[0] -> $_->[1] may alter values" for @lossy;

# only the type is judged
{
  my $default = DBIO::ClickHouse::Diff::Column->new(
    action => 'alter', table_name => 't', column_name => 'c',
    old_info => { data_type => 'Int32' },
    new_info => { data_type => 'Int32', default_value => '5' },
  );
  ok !$default->lossy, 'a change of the default alone keeps every value';

  for my $action (qw(add drop)) {
    my $op = DBIO::ClickHouse::Diff::Column->new(
      action => $action, table_name => 't', column_name => 'c',
      old_info => { data_type => 'Int32' }, new_info => { data_type => 'Int8' });
    ok !$op->lossy, "$action is not judged by lossy (a drop is destructive on its own)";
  }
}

# through the diff: the guard sees the operation
{
  sub model {
    my ($type) = @_;
    return {
      tables  => { t => { table_name => 't', kind => 'table', engine => 'MergeTree',
                          engine_expression => 'MergeTree', sorting_key_entries => ['id'],
                          primary_key_entries => ['id'], partition_key => '' } },
      columns => { t => [ { table_name => 't', column_name => 'id', data_type => 'Int32' },
                          { table_name => 't', column_name => 'c', data_type => $type } ] },
      data_skipping_indexes => {},
    };
  }

  my $narrow = DBIO::ClickHouse::Diff->new(source => model('Int64'), target => model('Int32'));
  is scalar($narrow->destructive_operations), 1, 'Int64 -> Int32 is a destructive operation of the diff';

  my $widen = DBIO::ClickHouse::Diff->new(source => model('Int32'), target => model('Int64'));
  ok $widen->has_changes, 'the widening is a change';
  is scalar($widen->destructive_operations), 0, '... and not a destructive one';
}

# apply refuses without the release, and executes nothing
{
  package Fake::Storage;
  sub new { bless {}, $_[0] }
  sub throw_exception { die "THROWN: $_[1]" }
  package Fake::Schema;
  sub new { bless { storage => Fake::Storage->new }, $_[0] }
  sub storage { $_[0]{storage} }
  package Fake::Deploy;
  use base 'DBIO::ClickHouse::Deploy';
  sub _dbh { die 'no handle expected' }
  sub _execute_ddl { my ($s, $dbh, @sql) = @_; push @{ $s->{executed} }, @sql; 1 }
}

{
  my $diff = DBIO::ClickHouse::Diff->new(source => model('Int64'), target => model('Int32'));
  my $deploy = Fake::Deploy->new(schema => Fake::Schema->new);

  my $err = do { local $@; eval { $deploy->apply($diff); 1 } ? '' : "$@" };
  like $err, qr/allow_destructive/, 'a lossy diff is refused without allow_destructive ...';
  like $err, qr/column: t\.c/, '... naming the column';
  is $deploy->{executed}, undef, '... and not a statement was executed';

  $deploy->apply($diff, dry_run => 1);
  is $deploy->{executed}, undef, 'dry_run executes nothing and checks nothing';
}

done_testing;
