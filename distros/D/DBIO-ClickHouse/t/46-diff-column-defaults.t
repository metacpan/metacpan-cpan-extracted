use strict;
use warnings;
use Test::More;

# t/46-diff-column-defaults.t -- what the upgrade does with a column's default
# and with a NOT NULL column added over rows (karr k43, Diff conformance).
#
# Offline: a recording handle stands in for the server.
#
#   1. A default the schema no longer declares is removed (REMOVE DEFAULT);
#      the rows keep the value they were written with. A column the schema
#      never prescribed a default for, but the live one has, used to be left
#      alone for ever -- the schema said "no default" and the server kept one.
#   2. A computed (MATERIALIZED/ALIAS) live column is still not touched.
#   3. A NOT NULL column without a default, added to a table that holds rows,
#      is refused BEFORE the first statement: ClickHouse would fill the rows
#      with the type's zero ('' / 0), a value nobody wrote. Empty table, a
#      default, or Nullable: the plan runs. The dry-run paths never read data.

use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::Diff;

package Fake::Storage;
sub new { bless {}, $_[0] }
sub throw_exception { die "THROWN: $_[1]" }

package Fake::Dbh;
sub new { bless { rows => $_[1], log => [] }, $_[0] }
sub selectrow_array { my ($s, $sql) = @_; push @{ $s->{log} }, $sql; return $s->{rows} }
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
sub col { my ($t, $n, $type, %a) = @_; +{ table_name => $t, column_name => $n, data_type => $type, %a } }
sub model { my (@cols) = @_;
  return { tables => { t => tbl('t') },
           columns => { t => [ col('t', 'id', 'Int32'), @cols ] },
           data_skipping_indexes => {} } }

sub diff_of { DBIO::ClickHouse::Diff->new(source => model(@{ $_[0] }), target => model(@{ $_[1] })) }

# --- 1. a removed default ----------------------------------------------------
{
  my $d = diff_of(
    [ col('t', 'c', 'String', default_kind => 'DEFAULT', default_value => q{'x'}) ],
    [ col('t', 'c', 'String') ]);
  ok $d->has_changes, 'a default the schema dropped is a change';
  is $d->as_sql, 'ALTER TABLE `t` MODIFY COLUMN `c` REMOVE DEFAULT;',
    '... rendered as REMOVE DEFAULT, not a type restatement';
  like $d->summary, qr/column: t\.c/, '... and shown in the summary';
}

# type and default change together: the default goes first, so the old
# expression is not re-checked against the new type
{
  my $d = diff_of(
    [ col('t', 'c', 'Int32', default_kind => 'DEFAULT', default_value => '7') ],
    [ col('t', 'c', 'String') ]);
  is $d->as_sql,
    "ALTER TABLE `t` MODIFY COLUMN `c` REMOVE DEFAULT;\nALTER TABLE `t` MODIFY COLUMN `c` String;",
    'type and default together: REMOVE DEFAULT first, then the type';
}

# a default both sides carry, equal: nothing; a changed one: the new default
ok !diff_of(
  [ col('t', 'c', 'String', default_kind => 'DEFAULT', default_value => q{'x'}) ],
  [ col('t', 'c', 'String', default_kind => 'DEFAULT', default_value => q{'x'}) ]
)->has_changes, 'an unchanged default is no change';
is diff_of(
  [ col('t', 'c', 'String', default_kind => 'DEFAULT', default_value => q{'x'}) ],
  [ col('t', 'c', 'String', default_kind => 'DEFAULT', default_value => q{'y'}) ]
)->as_sql, q{ALTER TABLE `t` MODIFY COLUMN `c` String DEFAULT 'y';},
  'a changed default is restated';

# --- 2. a computed live column is left alone ---------------------------------
ok !diff_of(
  [ col('t', 'c', 'String', default_kind => 'MATERIALIZED', default_value => 'lower(n)') ],
  [ col('t', 'c', 'String') ]
)->has_changes, 'a MATERIALIZED live column is not stripped';

# --- 3. NOT NULL without a default over rows ---------------------------------
sub run {
  my ($from, $to, $rows) = @_;
  my $dbh    = Fake::Dbh->new($rows);
  my $deploy = Fake::Deploy->new(schema => Fake::Schema->new($dbh));
  my $diff   = diff_of($from, $to);
  my $err    = do { local $@; eval { $deploy->apply($diff); 1 } ? '' : "$@" };
  return ($err, $dbh, $deploy, $diff);
}

{
  my $diff = diff_of([], [ col('t', 'code', 'String') ]);
  like $diff->as_sql, qr/ADD COLUMN `code` String/, 'dry run: as_sql renders the ADD without any handle';
  my ($op) = grep { $_->can('needs_row_check') && $_->needs_row_check } @{ $diff->operations };
  ok $op, '... and exactly that op says it needs the row check';
  is $op->row_check_sql, 'SELECT 1 FROM `t` LIMIT 1', '... with a read-only precondition';
}

{
  my ($err, $dbh, $deploy) = run([], [ col('t', 'code', 'String') ], 1);
  like $err, qr/THROWN: .*refus.*\bt\.code\b/s, 'rows: apply refuses, naming table.column';
  like $err, qr/default_value|DEFAULT/, '... and names the way out';
  is_deeply $deploy->{executed}, undef, '... and not a single statement was executed';
  is_deeply $dbh->{log}, ['SELECT 1 FROM `t` LIMIT 1'], '... only the read-only probe ran';
}

for my $case (
  [ [ col('t', 'code', 'String') ], 0, 'an empty table' ],
  [ [ col('t', 'code', 'String', default_kind => 'DEFAULT', default_value => q{'z'}) ], 1, 'a column with a default' ],
  [ [ col('t', 'code', 'Nullable(String)') ], 1, 'a Nullable column' ],
  [ [ col('t', 'code', 'String', default_kind => 'MATERIALIZED', default_value => 'lower(id)') ], 1, 'a computed column' ],
) {
  my ($to, $rows, $what) = @$case;
  my ($err, $dbh, $deploy) = run([], $to, $rows);
  is $err, '', "$what: the plan runs";
}

{
  my ($err, $dbh) = run([ col('t', 'a', 'String') ], [ col('t', 'a', 'String') ], 1);
  is $err, '', 'no change: nothing to refuse';
  is_deeply $dbh->{log}, [], '... and no query on the data';
}

done_testing;
