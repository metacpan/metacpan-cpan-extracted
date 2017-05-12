#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Data::Dumper;

my $PERL_HAS_UTF8;

BEGIN {
    if ( $] < 5.008 ) {
        eval q{ use Data::Structure::Util qw(signature) };
        die $@ if $@;
        $PERL_HAS_UTF8 = 0;
    }
    else {
        eval
          q{ use Data::Structure::Util qw(has_utf8 utf8_off utf8_on signature) };
        die $@ if $@;
        $PERL_HAS_UTF8 = 1;
    }
}

use Test::More tests => 15;

ok( 1, "we loaded fine..." );

my $obj = {};
isnt( signature( $obj ), signature( {} ), "Signature 1" );

my $obj2 = [];
isnt( signature( $obj2 ), signature( [] ), "Signature 2" );

my $obj3 = bless { key1 => 1 };
ok( my $sig3 = signature( $obj3 ) );
isnt( $sig3, signature( bless { key1 => 1 } ), "Signature 3" );
$obj3->{key1} = 1;
is( $sig3, signature( $obj3 ), "Signature 3" );

my $obj4 = bless {
    key1 => $obj3,
    key2 => $obj2,
    key3 => $obj,
    key4 => undef
};
ok( my $sig4 = signature( $obj4 ) );
isnt(
    $sig4,
    signature(
        bless {
            key1 => $obj3,
            key2 => $obj2,
            key3 => $obj,
            key4 => undef
        }
    ),
    "Signature 3"
);

$obj4->{key1} = bless { key1 => 1 };
isnt( signature( $obj4 ), $sig4, "Signature 4" );

ok( signature(), "none" );
is( signature(), signature(), "empty list" );
ok( my $sigundef = signature( undef ), "none" );

# BELOW THIS LINE REQUIRES PERL 5.8.0 OR GREATER
SKIP: {
    unless ( $PERL_HAS_UTF8 ) {
        my $reason
          = "This version of perl ($]) doesn't have proper utf8 support, 5.8.0 or higher is needed";
        skip( $reason, 2 );
        exit;
    }
 # Have to use a hash ref rather than a hash and keep taking references,
 # as temporary refs are in the signature, and their address can differ
 # each time round the loop
    my $hash = { key1 => "Hello" };
    utf8_off( $hash );
    my $sig5 = signature( $hash );
    ok( $sig5 eq signature( $hash ), "signature 5" );
    utf8_on( $hash );
    ok( $sig5 ne signature( $hash ), "signature 5" );
}

my $a;
my $r;
$a->[1] = \$r;

ok( signature( $a ),
    "signature where av_fetch() returns 0 should not SEGV" );
