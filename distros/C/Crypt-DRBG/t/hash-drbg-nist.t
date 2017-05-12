#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Crypt::DRBG::Hash;
use Test::DRBG;
use Test::More;

Test::DRBG::run_tests('Hash');

done_testing();
