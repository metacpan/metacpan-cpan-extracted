# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More tests => 6;

BEGIN {
    use_ok('AFS::KTC_PRINCIPAL');
}

my $user = AFS::KTC_PRINCIPAL->new('admin');
is(ref($user), 'AFS::KTC_PRINCIPAL', 'AFS::KTC_PRINCIPAL->new()');

is($user->name(), 'admin', "princ->name");

can_ok('AFS::KTC_PRINCIPAL', qw(ListTokens));

can_ok('AFS::KTC_PRINCIPAL', qw(ParseLoginName));

$user->set('blabla', $user->instance(), $user->cell());
is($user->name(), 'blabla', "princ->set()");
