#!perl

use 5.010;
use strict;
use warnings;
use Test::More tests => 2;
use Test::Needs 'Text::Unaccent::PurePerl';
use FindBin '$Bin';
require "$Bin/testlib.pl";

prepare_for_testing();

test_perlmv(["rêve.mp3"], {extra_opt=>"unaccent"}, ["reve.mp3"], 'unaccent');

end_testing();
