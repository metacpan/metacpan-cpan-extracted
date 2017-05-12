use strict;
use warnings;

use Test::More;
use Test::Warnings qw( warnings :no_end_test );
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

{
    package DateTime::Locale::fake;

    use strict;
    use warnings;

    use DateTime::Locale;

    use base 'DateTime::Locale::Base';

    sub cldr_version {0}

    DateTime::Locale->register(
        id          => 'fake',
        en_language => 'Fake',
    );
}

my @warnings = warnings { DateTime::Locale->load('fake') };
is( scalar @warnings, 1, 'got one warning from loading old locale' );
like(
    $warnings[0],
    qr/\Qfrom an older version (0)/,
    'loading locale from an older CLDR version warns'
);

done_testing()
