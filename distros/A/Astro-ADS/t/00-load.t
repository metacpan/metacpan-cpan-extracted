#!perl

use Test::More tests => 4;

BEGIN {
    use_ok( 'Astro::ADS' );
    use_ok( 'Astro::ADS::Query' );
    use_ok( 'Astro::ADS::Result' );
    use_ok( 'Astro::ADS::Result::Paper' );
}

diag( "Testing Astro::ADS $Astro::ADS::VERSION, Perl $], $^X" );
