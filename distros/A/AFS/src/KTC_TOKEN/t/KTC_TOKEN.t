# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

my $has_KAS;

BEGIN {
    $has_KAS = 1;
    if ($has_KAS) { plan tests => 10; }
    else          { plan tests => 7; }
    use_ok('AFS::KTC_TOKEN');
}

is(ref(AFS::KTC_TOKEN->nulltoken), 'AFS::KTC_TOKEN', 'AFS::KTC_TOKEN->nulltoken()');

can_ok('AFS::KTC_TOKEN', qw(GetToken));
can_ok('AFS::KTC_TOKEN', qw(SetToken));
can_ok('AFS::KTC_TOKEN', qw(UserAuthenticateGeneral));
can_ok('AFS::KTC_TOKEN', qw(ForgetAllTokens));
can_ok('AFS::KTC_TOKEN', qw(FromString));
if ($has_KAS) {
    can_ok('AFS::KTC_TOKEN', qw(GetAuthToken));
    can_ok('AFS::KTC_TOKEN', qw(GetServerToken));
    can_ok('AFS::KTC_TOKEN', qw(GetAdminToken));
}
