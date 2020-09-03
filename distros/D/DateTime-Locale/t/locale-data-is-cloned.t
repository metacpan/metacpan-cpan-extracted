use strict;
use warnings;

use Test2::V0;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;
use Storable qw( dclone );

{
    my $cldr = DateTime::Locale->load('en');

    my %locale_data = $cldr->locale_data;
    my $orig_data   = dclone( \%locale_data );

    delete $locale_data{available_formats};

    is(
        { $cldr->locale_data },
        $orig_data,
        'modifying locale_data does not affect the data in the locale object'
    );
}

done_testing();
