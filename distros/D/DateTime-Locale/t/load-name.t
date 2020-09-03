use strict;
use warnings;
use utf8;

use Test2::V0;
use Test2::Plugin::UTF8;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

for my $code (qw( English French Italian Latvian latviešu )) {
    ok(
        DateTime::Locale->load($code),
        "code $code loaded a locale"
    );
}

done_testing();
