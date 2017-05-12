# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 5; }
    else { plan tests => 4; }

    use_ok('AFS::KTC_EKEY');
}

my $dkey = AFS::KTC_EKEY->des_string_to_key('abc');
is(ref($dkey), 'AFS::KTC_EKEY', 'des_string_to_key(abc)');

can_ok('AFS::KTC_EKEY', qw(ReadPassword));
can_ok('AFS::KTC_EKEY', qw(UserReadPassword));

if (! AFS::FS::isafs('./')) { exit; }

use AFS::Cell qw(localcell);
my $skey = AFS::KTC_EKEY->StringToKey('abc', localcell);
is(ref($skey), 'AFS::KTC_EKEY', 'StringToKey(abc,localcell)');
