use Test::More tests => 11;
use strict;
use warnings;

# pure Perl checks

BEGIN {
  use_ok('DBIx::PgLink');
  use_ok('DBIx::PgLink::Local');
  use_ok('DBIx::PgLink::Adapter');
  use_ok('DBIx::PgLink::Accessor::BaseAccessor');
  use_ok('DBIx::PgLink::Connector');
  use_ok('DBIx::PgLink::Adapter::MSSQL');
  use_ok('DBIx::PgLink::Adapter::Pg');
  use_ok('DBIx::PgLink::Adapter::SQLite');
  use_ok('DBIx::PgLink::Adapter::SybaseASE');
  use_ok('DBIx::PgLink::Adapter::XBase');
}

my $v = DBIx::PgLink->VERSION;
like( $v, qr/^[\d\._]+$/, qq{DBIx::PgLink->VERSION is $v"});
