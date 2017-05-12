use strict;
use warnings;

use Test::More;

use_ok 'Data::Apple::PriceTier';

is Data::Apple::PriceTier->price_for( country => 'Japan', tier => 1 ), '85', 'japan tier 1 ok';
is Data::Apple::PriceTier->price_for( currency => 'Yen', tier => 2 ), '170', 'yen tier 2 ok';

is Data::Apple::PriceTier->proceed_for( country => 'U.S.', tier => 87 ), '700', 'U.S. proceed 87 ok';

my @prices = Data::Apple::PriceTier->prices( country => 'Japan' );
is scalar @prices, '87', 'tier 87 ok';
is $prices[0], '85', 'tier 1 ok';
is $prices[1], '170', 'tier 2 ok';
is $prices[-1], '85000', 'max tier ok';


my $tier_jp = Data::Apple::PriceTier->new( country => 'Japan' );
is $tier_jp->price_for_tier(1), '85', 'tier 1 jp ok';
is $tier_jp->proceed_for_tier(2), '119', 'tier 2 jp ok';
is $tier_jp->price_for_tier(0), '0', 'tier 0 is 0 ok';

done_testing;
