#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::More::UTF8;
use Test::Warn;
use Convert::Number::Armenian qw/ arm2int int2arm /;

## Try a few numbers 
is( int2arm( 3 ), "Գ", "Three" );
is( int2arm( 30 ), "Լ", "Thirty" );
is( int2arm( 33 ), "ԼԳ", "Thirty-three" );
is( int2arm( 303 ), "ՅԳ", "Three hundred three" );
is( int2arm( 3333 ), "ՎՅԼԳ", "Three thousand three hundred three" );
is( int2arm( 29000 ), "ՖՔ", "Twenty-nine thousand" );
is( int2arm( 29001 ), "ՖՔԱ", "Twenty-nine thousand one" );
is( int2arm( 8023 ), "ՓԻԳ", "Eight thousand twenty-three" );
is( int2arm( 5706 ), "ՐՉԶ", "Five thousand seven hundred six" );

## And out of range numbers
warnings_exist {
        int2arm( 30000 );
} [qr/Can only convert numbers between 1 - 29999/],
	"Got warning for number too large";
warnings_exist {
        int2arm( -2 );
} [qr/Can only convert numbers between 1 - 29999/],
	"Got warning for number too small";

## Try a few Armenian strings
is( arm2int('ռ'), 1000, "One thousand" );
is( arm2int('իդ'), 24, "Twenty-four" );
is( arm2int('ճխդռ'), 144000, "One hundred forty-four thousand" );
is( arm2int('ըճ'), 800, "Eight hundred" );
is( arm2int('ժզ'), 16, "Sixteen" );
is( arm2int('Ֆխգ'), 20043, "Twenty thousand forty-three" );
is( arm2int('ա'), 1, "One" );
is( arm2int('մի'), 220, "Two hundred twenty" );
is( arm2int('ﬔ'), 205, "Two hundred five" );
warnings_exist {
        arm2int( 'foo' );
} [qr/appears not to be an Armenian number/],
	"Got warning for Armenian out of range";

done_testing();