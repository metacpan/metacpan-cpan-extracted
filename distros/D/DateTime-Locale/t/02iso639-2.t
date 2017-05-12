use strict;
use warnings;

use Test::More;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

my @aliases = qw( chi per khm );

for my $alias (@aliases) {
    ok( DateTime::Locale->load($alias), "alias mapping for $alias exists" );
}

my $locale = DateTime::Locale->load('eng_US');

is( $locale->code, 'en-US', 'code is en-US' );

is( $locale->name,      'English United States', 'name()' );
is( $locale->language,  'English',               'language()' );
is( $locale->territory, 'United States',         'territory()' );
is( $locale->variant,   undef,                   'variant()' );

done_testing();
