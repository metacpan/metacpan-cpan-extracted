use strict;
use Test::More;
use_ok "DateTime::Astro";

if (! exists $ENV{PERL_DATETIME_ASTRO_BACKEND} ||
    $ENV{PERL_DATETIME_ASTRO_BACKEND} eq 'XS')
{
    is DateTime::Astro::BACKEND(), "XS";
} else {
    is DateTime::Astro::BACKEND(), "PP";
}

done_testing;
