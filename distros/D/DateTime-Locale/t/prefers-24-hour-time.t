use strict;
use warnings;

use Test2::V0;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

my %tests = (
    'en'    => 0,
    'en-US' => 0,
    'en-GB' => 1,
    'fr'    => 1,
    'fr-FR' => 1,
    'fr-CA' => 1,
    'zh-TW' => 1,
);

for my $id ( sort keys %tests ) {
    my $l = DateTime::Locale->load($id);
    if ( $tests{$id} ) {
        ok( $l->prefers_24_hour_time, "$id prefers 24-hour time" );
    }
    else {
        ok( !$l->prefers_24_hour_time, "$id does not prefer 24-hour time" );
    }
}

done_testing();
