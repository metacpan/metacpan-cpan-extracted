use strict;
use warnings;

use Test::More;

use DBI;
use File::Temp ();
use DBIO::Deploy::Base::TempDatabase;

# karr k365. CREATE/DROP DATABASE of a temp-database driver run on a handle
# with AutoCommit on, and a driver never ends a transaction itself (PostgreSQL,
# MSSQL and Sybase would commit the one they find open). So the handle is not
# the live one whenever the live handle is in a transaction -- also one the
# storage does not know of (begin_work on the raw dbh, AutoCommit => 0 in the
# connect info).
#
# What this file claims:
#   1. Live handle with AutoCommit off, storage depth 0: the driver gets a
#      connection of its own with AutoCommit on; the transaction of the live
#      handle stays open, its INSERT stays invisible to a second connection
#      and a rollback removes it; the own connection is closed afterwards.
#   2. Live handle with AutoCommit on: it is used, no connection is added.
#
# Substitution: SQLite through DBI directly (a file database, so a second
# connection sees the committed data); the driver class only records the handle.

my $dir  = File::Temp->newdir;
my $file = "$dir/live.db";
my $dsn  = "dbi:SQLite:dbname=$file";

{
  package T::Storage;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub storage { $_[0] }
  sub transaction_depth { 0 }
  sub _dbh { $_[0]{dbh} }
  sub _dbi_connect_info { [ $dsn, '', '', {} ] }

  package T::Deploy;
  use base 'DBIO::Deploy::Base::TempDatabase';
  our @calls;
  sub schema { $_[0]{schema} }
  sub _dbh   { $_[0]{schema}->_dbh }
  sub _create_temp_db { push @calls, [ create => $_[1], $_[1]{AutoCommit} ]; 'tmp365' }
  sub _drop_temp_db   { push @calls, [ drop   => $_[1], $_[1]{AutoCommit} ] }
  sub _deploy_and_introspect_temp { { model => 1 } }
}

sub connect_live {
  my ($ac) = @_;
  DBI->connect($dsn, '', '', { RaiseError => 1, PrintError => 0, AutoCommit => $ac });
}

my $setup = connect_live(1);
$setup->do('CREATE TABLE t (v INTEGER)');
$setup->disconnect;

my @opened;
{
  no warnings 'redefine';
  my $orig = \&DBI::connect;
  *DBI::connect = sub { my $h = $orig->(@_); push @opened, $h if $h; $h };
}

{
  my $live = connect_live(1);
  $live->begin_work;
  $live->do('INSERT INTO t VALUES (1)');

  @T::Deploy::calls = ();
  @opened = ();
  my $deploy = T::Deploy->new(schema => T::Storage->new(dbh => $live));
  my $model = $deploy->_build_target_model;
  is_deeply $model, { model => 1 }, 'live handle in a transaction: the model comes back';
  is scalar(@T::Deploy::calls), 2, '... one create, one drop';
  for my $call (@T::Deploy::calls) {
    my ($what, $dbh, $ac) = @$call;
    isnt $dbh, $live, "... $what does not run on the live handle";
    ok $ac, "... $what gets a handle with AutoCommit on";
  }
  is $T::Deploy::calls[0][1], $T::Deploy::calls[1][1], '... create and drop share one connection';
  ok !$T::Deploy::calls[0][1]{Active}, '... which is closed again afterwards';
  ok $live->{Active}, 'the live handle is left open';
  ok !$live->{AutoCommit}, '... still in its transaction (AutoCommit off)';
  ok $live->{BegunWork}, '... begun by begin_work';

  my $other = connect_live(1);
  is $other->selectrow_array('SELECT COUNT(*) FROM t'), 0,
    '... and its INSERT is invisible to a second connection';
  $live->rollback;
  is $other->selectrow_array('SELECT COUNT(*) FROM t'), 0, '... a rollback removes it';
  is $live->selectrow_array('SELECT COUNT(*) FROM t'), 0, '... on the live handle too';
  $other->disconnect;
  $live->disconnect;
}

{
  my $live = connect_live(1);
  @T::Deploy::calls = ();
  @opened = ();
  my $deploy = T::Deploy->new(schema => T::Storage->new(dbh => $live));
  $deploy->_build_target_model;
  is $_->[1], $live, "live handle with AutoCommit on: $_->[0] runs on it" for @T::Deploy::calls;
  is scalar(grep { $_ != $live } @opened), 0, '... and no extra connection is opened';
  $live->disconnect;
}

done_testing;
