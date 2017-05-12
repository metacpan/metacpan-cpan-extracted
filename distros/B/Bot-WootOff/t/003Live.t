######################################################################
# Test suite for Bot::WootOff
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;

use Bot::WootOff;
my $bot = Bot::WootOff->new(spawn => 0);

    if($ENV{LIVE_TESTS}) {
        plan tests => 3;
    } else {
        plan skip_all => "only with LIVE_TESTS set";
    }

my($item, $price) = $bot->scraper_test();
ok defined $item, "item defined";
ok defined $price, "price defined";
like $price, qr/^\d+\.\d+$/, "price is a number";
