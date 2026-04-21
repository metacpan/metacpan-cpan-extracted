use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;
use DBIx::Wizard::DB;

setup_test_db();

# package-level default
{
  is(DBIx::Wizard->default_inflate_class, 'Time::Moment', 'default inflate_class');
}

# change via class method
{
  DBIx::Wizard->default_inflate_class('Custom::DT');
  is(DBIx::Wizard->default_inflate_class, 'Custom::DT', 'set default inflate_class');
}

# ResultSet resolves to package default
{
  my $rs = dbiw('testdb:users');
  is($rs->_resolve_inflate_class, 'Custom::DT', 'resolves to package default');
}

# ResultSet-level override
{
  my $rs = dbiw('testdb:users')->inflate_class('RS::DT');
  is($rs->_resolve_inflate_class, 'RS::DT', 'resolves to RS level');
}

# DB-level override
{
  DBIx::Wizard::DB->declare('inflatedb', "dbi:SQLite:dbname=$DBFILE", '', '', {
    RaiseError    => 1,
    inflate_class => 'DB::Level::DT',
  });
  my $rs = dbiw('inflatedb:users');
  is($rs->_resolve_inflate_class, 'DB::Level::DT', 'resolves to DB level');
}

# RS overrides DB level
{
  my $rs = dbiw('inflatedb:users')->inflate_class('RS::Override');
  is($rs->_resolve_inflate_class, 'RS::Override', 'RS overrides DB level');
}

# restore default
DBIx::Wizard->default_inflate_class('Time::Moment');

cleanup_test_db();
done_testing;
