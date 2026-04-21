use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;

setup_test_db();

# dbiw without args returns SQL::Wizard instance
{
  my $sw = dbiw;
  isa_ok $sw, 'SQL::Wizard', 'dbiw() returns SQL::Wizard';
}

# dbiw with args returns ResultSet
{
  my $rs = dbiw('testdb:users');
  isa_ok $rs, 'DBIx::Wizard::ResultSet', 'dbiw(spec) returns ResultSet';
  is $rs->{db}, 'testdb', 'db parsed';
  is $rs->{table}, 'users', 'table parsed';
  is $rs->{inflate}, 1, 'inflate on by default';
}

# expression builder via dbiw
{
  my ($sql) = dbiw->func('COUNT', '*')->to_sql;
  is $sql, 'COUNT(*)', 'dbiw->func';
}
{
  my ($sql) = dbiw->now->to_sql;
  is $sql, 'NOW()', 'dbiw->now';
}
{
  my ($sql) = dbiw->col('u.name')->to_sql;
  is $sql, 'u.name', 'dbiw->col';
}
{
  my ($sql) = (dbiw->col('price') * dbiw->col('qty'))->to_sql;
  is $sql, 'price * qty', 'dbiw arithmetic';
}

cleanup_test_db();
done_testing;
