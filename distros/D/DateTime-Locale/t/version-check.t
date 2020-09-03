use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;
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

is(
    warnings { DateTime::Locale->load('fake') },
    array {
        item 0 => match qr/\Qfrom an older version (0)/;
        end();
    },
    'got a warning when loading a locale from an older CLDR version'
);

done_testing()
