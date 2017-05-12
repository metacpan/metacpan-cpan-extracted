use strict;
use warnings;

use Test::More;

use DateTimeX::Lite::Locale;


my @aliases = qw( C POSIX chi per khm );

plan tests => 5 + scalar @aliases;


for my $alias (@aliases)
{
    my $locale = eval { DateTimeX::Lite::Locale->load($alias) };
    ok( !$@ && $locale, "alias mapping for $alias exists" );
}

my $locale = DateTimeX::Lite::Locale->load('eng_US');

is( $locale->id, 'eng_US', 'variant()' );

is( $locale->name, 'English United States', 'name()' );
is( $locale->language, 'English', 'language()' );
is( $locale->territory, 'United States', 'territory()' );
is( $locale->variant, undef, 'variant()' );
