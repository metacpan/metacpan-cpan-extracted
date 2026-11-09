use strict;
use warnings;
use Test::More;

# t/45-deploy-null-check.t -- Deploy->apply looks before it leaps (karr k32).
#
# Offline: a recording handle stands in for the server. The claim under test:
# a MODIFY COLUMN that narrows Nullable(T) to T is preceded, BEFORE the first
# statement of the plan, by a SELECT count() ... IS NULL; with NULL rows it
# throws and executes nothing, without them it executes the whole plan. The
# dry-run paths (as_sql, summary, has_changes) never touch the handle.
# The live counterpart is t/32-upgrade-live.t.

use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::Diff;
use DBIO::ClickHouse::Diff::Column qw(is_nullable_type);

ok  is_nullable_type('Nullable(String)'),                    'Nullable(T) is nullable';
ok  is_nullable_type('LowCardinality(Nullable(String))'),    '... also under LowCardinality';
ok !is_nullable_type('String'),                              'String is not';
ok !is_nullable_type('Array(Nullable(String))'),             'Nullable inside Array is not top level';
ok !is_nullable_type(undef),                                 'undef is not';

package Fake::Storage;
sub new { bless { null_rows => $_[1] }, $_[0] }
sub throw_exception { die "THROWN: $_[1]" }

package Fake::Dbh;
sub new { bless { null_rows => $_[1], log => [] }, $_[0] }
sub selectrow_array { my ($s, $sql) = @_; push @{ $s->{log} }, $sql; return $s->{null_rows} }
sub do { my ($s, $sql) = @_; push @{ $s->{log} }, "DO $sql"; 1 }

package Fake::Schema;
sub new { my ($c, $dbh) = @_; bless { storage => Fake::Storage->new, dbh => $dbh }, $c }
sub storage { $_[0]{storage} }

package Fake::Deploy;
use base 'DBIO::ClickHouse::Deploy';
sub _dbh { $_[0]{schema}{dbh} }
sub _execute_ddl { my ($s, $dbh, @sql) = @_; push @{ $s->{executed} }, @sql; 1 }

package main;

sub tbl { +{ table_name => $_[0], kind => 'table', engine => 'MergeTree',
             engine_expression => 'MergeTree',
             sorting_key_entries => ['id'], primary_key_entries => ['id'],
             partition_key => '' } }
sub col { +{ table_name => $_[0], column_name => $_[1], data_type => $_[2] } }

sub model {
  my ($ctype) = @_;
  return {
    tables  => { t => tbl('t') },
    columns => { t => [ col('t', 'id', 'Int32'), col('t', 'c', $ctype) ] },
    data_skipping_indexes => {},
  };
}

sub run {
  my ($from, $to, $nulls, @opts) = @_;
  my $dbh    = Fake::Dbh->new($nulls);
  my $deploy = Fake::Deploy->new(schema => Fake::Schema->new($dbh));
  my $diff   = DBIO::ClickHouse::Diff->new(source => model($from), target => model($to));
  my $err    = do { local $@; eval { $deploy->apply($diff, @opts); 1 } ? '' : "$@" };
  return ($err, $dbh, $deploy, $diff);
}

# dry run: no handle involved at all
{
  my $diff = DBIO::ClickHouse::Diff->new(
    source => model('Nullable(String)'), target => model('String'));
  ok $diff->has_changes, 'the narrowing is a change';
  like $diff->as_sql, qr/MODIFY COLUMN `c` String/, '... as_sql renders it without any handle';
  my ($op) = grep { $_->can('needs_null_check') && $_->needs_null_check } @{ $diff->operations };
  ok $op, '... and exactly the op that needs the check says so';
  is $op->null_check_sql, 'SELECT count() FROM `t` WHERE `c` IS NULL', '... with its precondition SQL';
}

# NULL rows: refused, nothing executed
{
  my ($err, $dbh, $deploy) = run('Nullable(String)', 'String', 3, allow_destructive => 1);
  like $err, qr/THROWN: .*t\.c.*\b3 NULL row/s, 'NULL rows: apply throws with table.column and the count';
  like $err, qr/UPDATE `c` = <value> WHERE `c` IS NULL SETTINGS mutations_sync = 1/, '... and names the way out';
  is_deeply $deploy->{executed}, undef, '... and not a single statement was executed';
  is_deeply $dbh->{log}, ['SELECT count() FROM `t` WHERE `c` IS NULL'], '... only the read-only count ran';
}

# no NULL rows: the plan runs
{
  my ($err, $dbh, $deploy) = run('Nullable(String)', 'String', 0, allow_destructive => 1);
  is $err, '', 'no NULL rows: apply goes through';
  like join("\n", @{ $deploy->{executed} }), qr/MODIFY COLUMN `c` String/, '... the MODIFY was executed';
}

# changes that cannot lose data never read it
for my $case (
  [ 'String', 'Nullable(String)', 'NOT NULL -> Nullable' ],
  [ 'Int32',  'Int64',            'a plain widening' ],
  [ 'Nullable(Int32)', 'Nullable(Int64)', 'a Nullable widening' ],
) {
  my ($from, $to, $what) = @$case;
  my ($err, $dbh, $deploy) = run($from, $to, 99);
  is $err, '', "$what: applied";
  is_deeply $dbh->{log}, [], "... without any query on the data";
}

done_testing;
