#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Crypt::DRBG::HMAC;
use Test::DRBG;
use Test::More;

Test::DRBG::run_tests('HMAC');

done_testing();
