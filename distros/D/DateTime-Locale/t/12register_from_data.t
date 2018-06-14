use strict;
use warnings;

use Test::More;

use DateTime::Locale;

{
    my $base_locale = DateTime::Locale->load('en-US');
    my %data        = $base_locale->locale_data;
    $data{code} = 'en-US-CUSTOM';

    DateTime::Locale->register_from_data(%data);
    my $l = DateTime::Locale->load('en-US-CUSTOM');

    isa_ok( $l, 'DateTime::Locale::FromData' );
    ok( $l, 'was able to load en_US_CUSTOM' );
    is( $l->code, 'en-US-CUSTOM', 'code is set properly' );
}

done_testing();
