use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DBI ();
use DBIO::MySQL::Storage::Async;

# The fork guard is installed only for a DBD::MariaDB handle, and the connect
# asks the handle for its DBD name to tell. A handle that does not name its
# driver (the stand-ins the offline tests connect with) is no MariaDB handle;
# asking must not warn (karr k122).

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

{
  package K122::FakeDBH;
  sub do { 1 }
  sub FETCH { undef }
}

no warnings 'redefine';
local *DBI::connect = sub { bless {}, 'K122::FakeDBH' };

my $storage = bless {}, 'DBIO::MySQL::Storage::Async';
my $conn = eval { $storage->_mysql_connect({ dsn => 'dbi:mysql:database=t', user => 'u', password => 'p' }) };
is ref($conn->{dbh} // ''), 'K122::FakeDBH', 'connect returns the handle of a driver-less stand-in'
  or diag $@;
is_deeply \@warnings, [], 'no warning while the handle names no driver';

done_testing;
