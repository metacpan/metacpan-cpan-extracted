#!/usr/bin/perl 

use strict;
use warnings;

use Data::Dump qw( pp );

use Test::More tests => 5;
BEGIN { use_ok('Data::Password::Check::JPassword') };


my $c = Data::Password::Check::JPassword->security( "hello" );
is_deeply( $c, {
        number => 1,
        punctuation => 1,
        special => 1,
        lowercase => 6,
        uppercase => 1,
        password => "hello",
        level => log( 36 )  # ~3.58
    }, "Simple" ) or die pp $c;

$c = Data::Password::Check::JPassword->security( "hello-WORLD" );
is_deeply( $c, {
        number => 1,
        punctuation => 3,
        special => 1,
        lowercase => 6,
        uppercase => 6,
        password => "hello-WORLD",
        level => log( 36*36*9 ) # ~9.36
    }, "Slightly more complex" ) or die pp $c;

$c = Data::Password::Check::JPassword->security( "Id3-ad0rm" );
is_deeply( $c, {
        number => 3,
        punctuation => 3,
        special => 1,
        lowercase => 6,
        uppercase => 2,
        password => "Id3-ad0rm",
        level => log( 36*4*9*9 ) # ~3.36
    }, "Same complexity" ) or die pp $c;

$c = Data::Password::Check::JPassword->security( "go-away-PLEASE" );
is_deeply( $c, {
        number => 1,
        punctuation => 5,
        special => 1,
        lowercase => 7,
        uppercase => 7,
        password => "go-away-PLEASE",
        level => log( 25*49*49 ) # ~11
}, "higher complex" ) or die pp $c;

