use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Deploy::Base;
use DBIO::Oracle::Deploy;
use DBIO::Oracle::Diff;
use DBIO::Oracle::Diff::Column;

# OFFLINE (core k399, ADR 0080). A column change that can alter or lose stored
# values is lossy: DBIO::Oracle::Diff::Column answers it, and the deploy runs
# such a diff only with allow_destructive => 1. What is lossless is the short
# list of %LOSSLESS_PAIRS and a size that stays or grows; in doubt it is lossy.
#
#   1. the matrix of Diff::Column->lossy;
#   2. the deploy: apply and upgrade are the base's, and the look at the rows
#      of the live tables runs through the base's _check_before_apply seam,
#      before the first statement.

no warnings 'redefine';
local *DBI::connect = sub { die 'the diff must not connect' };

sub col { my ($n, $t, %o) = @_; return { column_name => $n, data_type => $t, %o } }

sub model {
  my (@cols) = @_;
  return {
    tables  => { ITEM => { table_name => 'ITEM' } },
    columns => { ITEM => [ col(id => 'integer'), @cols ] },
  };
}

# the lossy answer of the column operation of a change from [type, %o] to [type, %o]
sub lossy {
  my ($from, $to) = @_;
  # the operation itself: a target that states no size is no change to the
  # diff, but lossy answers for any alter it is asked about
  return DBIO::Oracle::Diff::Column->new(
    action => 'alter', table_name => 'ITEM', column_name => 'c',
    old_info => col(c => @$from), new_info => col(c => @$to),
  )->lossy;
}

# --- 1. the matrix -------------------------------------------------------------

# the pairs the driver names
is_deeply [ sort keys %DBIO::Oracle::Diff::Column::LOSSLESS_PAIRS ],
  [ 'char->varchar2', 'date->timestamp', 'nchar->nvarchar2' ],
  'the lossless pairs are char->varchar2, nchar->nvarchar2 and date->timestamp';

for my $t (
  [ 'char to varchar2',           [ 'char', size => 5 ],     [ 'varchar', size => 20 ] ],
  [ 'char to varchar2 (same size)', [ 'char', size => 5 ],   [ 'varchar2', size => 5 ] ],
  [ 'nchar to nvarchar2',         [ 'nchar', size => 5 ],    [ 'nvarchar', size => 20 ] ],
  [ 'date to timestamp',          [ 'date' ],                [ 'timestamp' ] ],
  [ 'date to timestamp(9)',       [ 'date' ],                [ 'timestamp', size => 9 ] ],
  [ 'varchar2 wider',             [ 'varchar', size => 20 ], [ 'varchar', size => 30 ] ],
  [ 'varchar2 wider in CHAR',     [ 'varchar', size => '20 CHAR' ], [ 'varchar', size => '30 CHAR' ] ],
  [ 'varchar2 BYTE wider',        [ 'varchar', size => 20 ], [ 'varchar', size => '30 BYTE' ] ],
  [ 'nvarchar2 wider',            [ 'nvarchar', size => 20 ], [ 'nvarchar', size => 40 ] ],
  [ 'number wider',               [ 'numeric', size => [10, 2] ], [ 'numeric', size => [12, 2] ] ],
  [ 'number(p) to number(p,0)',   [ 'numeric', size => 10 ], [ 'numeric', size => [12, 0] ] ],
  [ 'number to unlimited number', [ 'numeric', size => [10, 2] ], [ 'numeric' ] ],
  [ 'integer to unlimited number', [ 'integer' ],            [ 'numeric' ] ],
  [ 'timestamp wider',            [ 'timestamp', size => 3 ], [ 'timestamp', size => 9 ] ],
  [ 'timestamp default to 9',     [ 'timestamp' ],           [ 'timestamp', size => 9 ] ],
  [ 'float wider',                [ 'float', size => 10 ],   [ 'float', size => 20 ] ],
  [ 'varchar spelled varchar2',   [ 'varchar', size => 20 ], [ 'varchar2', size => 20 ] ],
) {
  my ($name, $from, $to) = @$t;
  is lossy($from, $to), 0, "$name: lossless";
}

for my $t (
  [ 'varchar2 to char (blank padding)',  [ 'varchar', size => 5 ], [ 'char', size => 20 ] ],
  [ 'varchar2 to nvarchar2 (character set)', [ 'varchar', size => 5 ], [ 'nvarchar', size => 20 ] ],
  [ 'varchar2 to nchar',                 [ 'varchar', size => 5 ], [ 'nchar', size => 20 ] ],
  [ 'nvarchar2 to varchar2',             [ 'nvarchar', size => 5 ], [ 'varchar', size => 20 ] ],
  [ 'nvarchar2 to nchar',                [ 'nvarchar', size => 5 ], [ 'nchar', size => 20 ] ],
  [ 'char to nchar',                     [ 'char', size => 5 ],    [ 'nchar', size => 20 ] ],
  [ 'timestamp to date',                 [ 'timestamp' ],          [ 'date' ] ],
  [ 'number to float',                   [ 'numeric', size => [10, 2] ], [ 'float' ] ],
  [ 'integer to varchar2',               [ 'integer' ],            [ 'varchar', size => 20 ] ],
  [ 'varchar2 to integer',               [ 'varchar', size => 20 ], [ 'integer' ] ],
  [ 'varchar2 to clob',                  [ 'varchar', size => 20 ], [ 'text' ] ],
  [ 'clob to varchar2',                  [ 'text' ],               [ 'varchar', size => 20 ] ],
  [ 'clob to blob',                      [ 'text' ],               [ 'blob' ] ],
  [ 'real to double',                    [ 'real' ],               [ 'double' ] ],
  [ 'date to varchar2',                  [ 'date' ],               [ 'varchar', size => 20 ] ],
  [ 'char to varchar2, narrower',        [ 'char', size => 20 ],   [ 'varchar', size => 5 ] ],
  [ 'varchar2 narrower',                 [ 'varchar', size => 30 ], [ 'varchar', size => 20 ] ],
  [ 'nvarchar2 narrower',                [ 'nvarchar', size => 40 ], [ 'nvarchar', size => 20 ] ],
  [ 'BYTE to CHAR semantics',            [ 'varchar', size => 20 ], [ 'varchar', size => '20 CHAR' ] ],
  [ 'CHAR to BYTE semantics',            [ 'varchar', size => '20 CHAR' ], [ 'varchar', size => '20 BYTE' ] ],
  [ 'char to varchar2, other semantics', [ 'char', size => '5 CHAR' ], [ 'varchar', size => '5 BYTE' ] ],
  [ 'number narrower precision',         [ 'numeric', size => [12, 2] ], [ 'numeric', size => [10, 2] ] ],
  [ 'number scale smaller',              [ 'numeric', size => [10, 2] ], [ 'numeric', size => [10, 0] ] ],
  [ 'number scale larger',               [ 'numeric', size => [10, 2] ], [ 'numeric', size => [10, 3] ] ],
  [ 'unlimited number to number(p)',     [ 'numeric' ],            [ 'numeric', size => [10, 2] ] ],
  [ 'unlimited number to integer',       [ 'numeric' ],            [ 'integer' ] ],
  [ 'integer to number(10)',             [ 'integer' ],            [ 'numeric', size => 10 ] ],
  [ 'timestamp narrower',                [ 'timestamp', size => 9 ], [ 'timestamp', size => 3 ] ],
  [ 'timestamp default to 3',            [ 'timestamp' ],          [ 'timestamp', size => 3 ] ],
  [ 'timestamp to timestamp with time zone', [ 'timestamp' ],      [ 'timestamptz' ] ],
) {
  my ($name, $from, $to) = @$t;
  is lossy($from, $to), 1, "$name: lossy";
}

# NOT NULL and the default alone keep every value
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(col(c => 'varchar', size => 20)),
    target => model(col(c => 'varchar', size => 20, not_null => 1, default_value => 'x')),
  );
  my @ops = grep { $_->isa('DBIO::Oracle::Diff::Column') } @{ $diff->operations };
  is scalar(@ops), 1, 'NOT NULL and a default are one column operation ...';
  is $ops[0]->lossy, 0, '... which is not lossy';
  is_deeply [ $diff->destructive_operations ], [], '... and not a destructive operation of the diff';
}

# add and drop answer 0 (a drop is destructive by itself)
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(col(gone => 'varchar', size => 20)),
    target => model(col(new => 'integer')),
  );
  my %by = map { $_->action => $_ } grep { $_->isa('DBIO::Oracle::Diff::Column') } @{ $diff->operations };
  is $by{add}->lossy,  0, 'add is not lossy';
  is $by{drop}->lossy, 0, 'drop is not lossy (the diff classes it as destructive)';
}

# a lossy change reaches the diff's destructive operations
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(col(c => 'varchar', size => 20)),
    target => model(col(c => 'integer')),
  );
  is scalar(my @risky = $diff->destructive_operations), 1,
    'a lossy column change is among the destructive operations of its diff';
}

# --- 2. the deploy -------------------------------------------------------------

is( DBIO::Oracle::Deploy->can($_), DBIO::Deploy::Base->can($_),
  "$_ is DBIO::Deploy::Base's own: the class defines neither" ) for qw(apply upgrade);

{
  package Dbl;
  sub new { bless { sql => [] }, shift }
  sub selectrow_array { my ($s, $sql) = @_; push @{ $s->{sql} }, $sql; return 1 }   # the table holds rows
  sub do { die 'no statement may run' }
}

sub not_null_add_diff {
  return DBIO::Oracle::Diff->new(
    source => model(),
    target => model(col(code => 'varchar', size => 10, not_null => 1)),
  );
}

{
  my $dbl = Dbl->new;
  no warnings qw(redefine once);
  local *DBIO::Oracle::Deploy::_dbh = sub { $dbl };
  local *DBIO::Deploy::Base::_execute_diff = sub { die 'the diff must not run' };
  my $deploy = bless {}, 'DBIO::Oracle::Deploy';

  my $diff = not_null_add_diff();
  is_deeply [ $diff->destructive_operations ], [],
    'a NOT NULL column added is not destructive: the guard of the base lets it through';

  my $ok = eval { $deploy->apply($diff); 1 };
  ok !$ok, 'apply of a NOT NULL add to a table with rows is refused ...';
  like "$@", qr/ORA-01758/, '... through the base apply and its _check_before_apply seam (ORA-01758)';
  like $dbl->{sql}[0], qr/\ASELECT 1 FROM "ITEM" WHERE ROWNUM = 1\z/, '... before the first statement: only the table was asked';

  local *DBIO::Oracle::Deploy::diff = sub { $diff };
  $ok = eval { $deploy->upgrade; 1 };
  like "$@", qr/ORA-01758/, 'upgrade of the base refuses it as well';

  $ok = eval { $deploy->apply($diff, dry_run => 1) };
  ok $ok, 'a dry_run checks nothing and runs nothing';
}

{
  # a released lossy change still passes the look at the rows
  my $dbl = Dbl->new;
  no warnings qw(redefine once);
  local *DBIO::Oracle::Deploy::_dbh = sub { $dbl };
  my @ran;
  local *DBIO::Deploy::Base::_execute_diff = sub { push @ran, 1; 1 };
  my $deploy = bless {}, 'DBIO::Oracle::Deploy';
  my $diff = DBIO::Oracle::Diff->new(
    source => model(col(c => 'varchar', size => 20)),
    target => model(col(c => 'varchar', size => 30)),
  );
  ok $deploy->apply($diff), 'a widening runs without allow_destructive';
  is scalar(@ran), 1, '... and is executed';

  my $lossy = DBIO::Oracle::Diff->new(
    source => model(col(c => 'varchar', size => 30)),
    target => model(col(c => 'varchar', size => 20)),
  );
  @ran = ();
  my $ok = eval { $deploy->apply($lossy); 1 };
  like "$@", qr/allow_destructive/, 'a narrowing is refused without allow_destructive ...';
  is scalar(@ran), 0, '... and nothing runs';
  ok eval { $deploy->apply($lossy, allow_destructive => 1) }, 'with allow_destructive => 1 it runs';
}

done_testing;
