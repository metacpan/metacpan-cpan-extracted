#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;

use DateTimeX::Lite;
use DateTimeX::Lite::Locale;

eval { DateTimeX::Lite->new( year => 100, locale => 'en_US' ) };
is( $@, '', 'make sure constructor accepts locale parameter' );

eval { DateTimeX::Lite->now( locale => 'en_US' ) };
is( $@, '', 'make sure constructor accepts locale parameter' );

eval { DateTimeX::Lite->today( locale => 'en_US' ) };
is( $@, '', 'make sure constructor accepts locale parameter' );

eval { DateTimeX::Lite->from_epoch( epoch => 1, locale => 'en_US' ) };
is( $@, '', 'make sure constructor accepts locale parameter' );

eval { DateTimeX::Lite->last_day_of_month( year => 100, month => 2, locale => 'en_US' ) };
is( $@, '', 'make sure constructor accepts locale parameter' );

{
    package DT::Object;
    sub utc_rd_values { ( 0, 0 ) }
}

eval { DateTimeX::Lite->from_object( object => (bless {}, 'DT::Object'), locale => 'en_US' ) };
is( $@, '', 'make sure constructor accepts locale parameter' );

eval { DateTimeX::Lite->new( year => 100, locale => DateTimeX::Lite::Locale->load('en_US') ) };
is( $@, '', 'make sure constructor accepts locale parameter as object' );

local $DateTimeX::Lite::DefaultLocale = 'it';
is( DateTimeX::Lite->now->locale->id, 'it', 'default locale should now be "it"' );
