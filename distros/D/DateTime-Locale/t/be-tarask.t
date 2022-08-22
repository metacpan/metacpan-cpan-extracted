use strict;
use warnings;
use utf8;

use Test2::V0;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

{
    my $locale = DateTime::Locale->load('Belarusian');
    is( $locale->code, 'be', ' Belarusian name loads be locale' );
}

{
    my $locale = DateTime::Locale->load('be-tarask');
    is(
        $locale->name,
        'Belarusian Taraskievica orthography',
        ' be-tarask has correct name',
    );
}

done_testing();
