# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 24; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::KAS');
}

use AFS::KTC_TOKEN;
my $kas = AFS::KAS->AuthServerConn(AFS::KTC_TOKEN->nulltoken, &AFS::KA_MAINTENANCE_SERVICE);
is(ref($kas), 'AFS::KAS', 'KAS->AuthServerConn(nulltoken)');

$kas->DESTROY;
ok(! defined $kas, 'kas->DESTROY');


can_ok('AFS::KAS', qw(randomkey));
can_ok('AFS::KAS', qw(SingleServerConn));
can_ok('AFS::KAS', qw(Authenticate));
can_ok('AFS::KAS', qw(ChangePassword));
can_ok('AFS::KAS', qw(create));
can_ok('AFS::KAS', qw(KAM_CreateUser));
can_ok('AFS::KAS', qw(debug));
can_ok('AFS::KAS', qw(KAM_Debug));
can_ok('AFS::KAS', qw(delete));
can_ok('AFS::KAS', qw(KAM_DeleteUser));
can_ok('AFS::KAS', qw(getentry));
can_ok('AFS::KAS', qw(KAM_GetEntry));
can_ok('AFS::KAS', qw(getstats));
can_ok('AFS::KAS', qw(KAM_GetStats));
can_ok('AFS::KAS', qw(GetToken));
can_ok('AFS::KAS', qw(listentry));
can_ok('AFS::KAS', qw(KAM_ListEntry));
can_ok('AFS::KAS', qw(setpassword));
can_ok('AFS::KAS', qw(KAM_SetPassword));
can_ok('AFS::KAS', qw(setfields));
can_ok('AFS::KAS', qw(KAM_SetFields));
