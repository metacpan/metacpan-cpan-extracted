use strict;
use warnings;

use Test::More;
use Try::Tiny;

use BerkeleyDB::Easy;

my $db = BerkeleyDB::Easy::Btree->new();

is ref $db, 'BerkeleyDB::Easy::Btree', 'db ref';

my $err;
try { $db->get('asdf', 666) } catch { $err = $_ };

is ref $err, 'BerkeleyDB::Easy::Error', 'error ref';
cmp_ok $err, '==', 22, 'numerified error';
like $err, qr/EINVAL/, 'stringified error';

done_testing;


# bless({
#   code    => 22,
#   desc    => "Invalid argument",
#   detail  => "DB_READ_COMMITTED, DB_READ_UNCOMMITTED and DB_RMW require locking",
#   file    => "error.pl",
#   level   => "BDB_ERROR",
#   line    => 16,
#   message => "Invalid argument. DB_READ_COMMITTED, DB_READ_UNCOMMITTED and "
#            . "DB_RMW require locking",
#   name    => "EINVAL",
#   package => "main",
#   string  => "[BerkeleyDB::Easy::Handle::get] EINVAL (22): Invalid argument. "
#            . "DB_READ_COMMITTED, DB_READ_UNCOMMITTED and DB_RMW require locking "
#            . "at error.pl line 16.",
#   sub     => "BerkeleyDB::Easy::Handle::get",
#   time    => 1409926665.1101,
#   trace   => "at error.pl line 16.",
# }, "BerkeleyDB::Easy::Error")
