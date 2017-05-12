#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Crypt::NSS config_dir => "db", cipher_suite => "US";
use LWP;
use Net::HTTPS;

if (LWP->Version < 5.819) {
    plan skip_all => "LWP 5.819 or later required";
}
else {
    plan tests => 1;
}

is($Net::HTTPS::ISA[0], "Net::NSS::SSL::LWPCompat");