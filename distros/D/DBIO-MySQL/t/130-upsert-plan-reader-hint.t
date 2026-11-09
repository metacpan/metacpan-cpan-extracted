use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Test::Storage;

# _mysql_upsert_plan and the reader hint (dbio-mysql-ev k47): a transport that
# reads SELECT LAST_INSERT_ID() instead of RETURNING passes `returning => 0`
# in the options. The plan then keeps the LAST_INSERT_ID(pk) idiom on MariaDB
# 10.5+, where it is otherwise left out because the sync path reads RETURNING.
# Without the hint the plan is what it always was.

my %server;
{
  no warnings 'redefine';
  *DBIO::Test::Storage::_server_info = sub { \%server };
}

sub plan_for {
  my ($raw, $normalized, %opts) = @_;
  %server = ( dbms_version => $raw, normalized_dbms_version => $normalized );
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );
  my $storage = $schema->storage;
  return $storage->_mysql_upsert_plan(
    $schema->source('Artist'),
    { name => 'aphex' },
    { on_conflict => { action => 'update', set => { name => 'aphex' } }, %opts },
  );
}

my @servers = (
  [ 'MySQL 8.0'      => '8.0.46',          '8.000046', 1 ],
  [ 'MariaDB 10.4'   => '10.4.34-MariaDB', '10.004034', 1 ],
  [ 'MariaDB 10.5'   => '10.5.0-MariaDB',  '10.005000', 0 ],
  [ 'MariaDB 10.11'  => '10.11.2-MariaDB', '10.011002', 0 ],
  [ 'MariaDB 11.8'   => '11.8.8-MariaDB',  '11.008008', 0 ],
);

for my $s (@servers) {
  my ($name, $raw, $norm, $idiom_without_hint) = @$s;

  my $plain = plan_for($raw, $norm);
  is $plain->{extra}{identity_column}, ($idiom_without_hint ? 'artistid' : undef),
    "$name, no hint: the idiom is " . ($idiom_without_hint ? 'in' : 'left out');
  ok $plain->{nameable}, "$name, no hint: the row is nameable";

  my $hinted = plan_for($raw, $norm, returning => 0);
  is $hinted->{extra}{identity_column}, 'artistid',
    "$name, returning => 0: the idiom is in (the reader reads LAST_INSERT_ID)";
  ok $hinted->{nameable}, "$name, returning => 0: the row is nameable";

  my $true = plan_for($raw, $norm, returning => 1);
  is $true->{extra}{identity_column}, $plain->{extra}{identity_column},
    "$name, returning => 1: same as no hint";
}

done_testing;
