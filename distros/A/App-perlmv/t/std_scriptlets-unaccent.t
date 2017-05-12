#!perl

use 5.010;
use strict;
use warnings;

BEGIN {
    eval { require Text::Unaccent::PurePerl };
    if ($@) {
        require Test::More;
        Test::More::plan(skip_all => "Text::Unaccent::PurePerl not available");
    }
}

use Test::More tests => 2;
use FindBin '$Bin';
require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["rêve.mp3"], {extra_opt=>"unaccent"}, ["reve.mp3"], 'unaccent');

end_testing();
