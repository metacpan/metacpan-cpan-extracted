use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;
use DBIx::Wizard::DB;

my $dbh = setup_test_db();

# declare and dbh
{
  my $h = DBIx::Wizard::DB->dbh('testdb');
  isa_ok $h, 'DBI::db';
}

# dbname
{
  my $name = DBIx::Wizard::DB->dbname('testdb');
  like $name, qr/dbiw_test/, 'dbname returns db file path';
}

# environment-based declaration
{
  $ENV{DBIW_DECLARE_ENVDB} = "dbi:SQLite:dbname=$DBFILE||";
  my $h = DBIx::Wizard::DB->dbh('envdb');
  isa_ok $h, 'DBI::db', 'env-based dbh';

  dbiw('testdb:users')->insert({ name => 'Test', email => 'test@test.com', status => 'active' });
  my $count = dbiw('envdb:users')->inflate(0)->count;
  ok $count > 0, 'env db can query';
  delete $ENV{DBIW_DECLARE_ENVDB};
}

# undeclared db croaks
{
  eval { DBIx::Wizard::DB->dbh('nonexistent') };
  like $@, qr/undeclared db/, 'undeclared db croaks';
}

cleanup_test_db();
done_testing;
