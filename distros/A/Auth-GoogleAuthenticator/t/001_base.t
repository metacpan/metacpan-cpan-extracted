#!perl -w
use Test::More tests => 2;
use strict;

use Auth::GoogleAuthenticator;

my $auth= Auth::GoogleAuthenticator->new(
    account => 'test2 <OTP>',
    secret_base32 => 'oyyhsm3zoa2tmmdf',
);

is $auth->totp(1352146604), 434872,
    "Simple value works";
isn't $auth->totp(1352146604+30), 434872,
    "Simple value changes after 30 seconds";