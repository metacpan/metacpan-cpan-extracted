use strict;
use warnings;

use Test::Requires {
    Storable => '0',
};

use Test::More;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;
use Storable;

my $loc1   = DateTime::Locale->load('en-US');
my $frozen = Storable::nfreeze($loc1);

ok(
    length $frozen < 2000,
    'the serialized locale object should not be immense'
);

my $loc2 = Storable::thaw($frozen);

is( $loc2->id, 'en-US', 'thaw frozen locale object' );

my $loc3 = Storable::dclone($loc1);

is( $loc3->id, 'en-US', 'dclone object' );

done_testing();
