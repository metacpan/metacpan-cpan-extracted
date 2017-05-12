#!/usr/bin/perl

use blib;
use strict;
use warnings;

use Data::Dumper;
use Storable qw(dclone);

use bytes;

BEGIN {
    if ( $] < 5.008 ) {
        my $reason
          = "This version of perl ($]) doesn't have proper utf8 support, 5.8.0 or higher is needed";
        eval qq{ use Test::More skip_all => "$reason" };
        exit;
    }
    else {
        eval q{
      use Data::Structure::Util qw(has_utf8 utf8_off utf8_on _utf8_on _utf8_off);
      use Test::More tests => 27;
    };
        die $@ if $@;
    }
}

ok( 1, "we loaded fine..." );

my $string = '';
for my $v ( 32 .. 126, 195 .. 255 ) {
    $string .= chr( $v );
}

my $hash = { key1 => $string . "\n", };

my $hash2 = test_utf8( $hash );
if ( $hash2 ) {
    ok( 1, "Got a utf8 string" );
}
else {
    $hash2 = dclone( $hash );
    ok( utf8_on( $hash ), "Have encoded utf8" );
}

$string = $hash->{key1};
my $string2 = $hash2->{key1};
is( utf8_on( $string ),   $string,  "Got string back" );
is( utf8_on( $string2 ),  $string2, "Got string back" );
is( utf8_off( $string ),  $string,  "Got string back" );
is( utf8_off( $string2 ), $string2, "Got string back" );

ok( !has_utf8( $hash ), "Has not utf8" );
ok( has_utf8( $hash2 ), "Has utf8" );
is( has_utf8( $hash2 ), $hash2, "Has utf8" );

is( $hash2->{key1}, $hash->{key1}, "Same string" );
ok( !compare( $hash2->{key1}, $hash->{key1} ), "Different encoding" );
ok( utf8_off( $hash2 ),  "Have decoded utf8" );
ok( !has_utf8( $hash2 ), "Has not utf8" );
is( $hash2->{key1}, $hash->{key1}, "Same string" );
ok( compare( $hash2->{key1}, $hash->{key1} ), "Same encoding" );

ok( utf8_on( $hash ), "Have encoded utf8" );
is( $hash2->{key1}, $hash->{key1}, "Same string" );
ok( !compare( $hash2->{key1}, $hash->{key1} ), "Different encoding" );

sub compare {
    my $str1   = shift;
    my $str2   = shift;
    my $i      = 0;
    my @chars2 = unpack 'C*', $str2;
    for my $char1 ( unpack 'C*', $str1 ) {
        return if ( ord( $char1 ) != ord( $chars2[ $i++ ] ) );
    }
    1;
}

sub test_utf8 {
    my $hash = shift;

    eval q{ use Encode };
    if ( $@ ) {
        warn "Encode not installed - will try XML::Simple\n";
        eval q{ use XML::Simple qw(XMLin XMLout) };
        if ( $@ ) {
            warn "XML::Simple not installed\n";
            return;
        }
        my $xml = XMLout(
            $hash,
            keyattr       => [],
            noattr        => 1,
            suppressempty => undef,
            xmldecl => '<?xml version="1.0" encoding="ISO-8859-1"?>'
        );
        return XMLin( $xml, keyattr => [], suppressempty => undef );
    }
    my $hash2 = dclone( $hash ) or die "Could not clone";
    my $utf8 = decode( "iso-8859-1", $hash->{key1} );
    $hash2->{key1} = $utf8;
    $hash2;
}

use utf8;

my $wide = { hello => ['world ᛰ'] };
ok( has_utf8( $wide ) );
ok( _utf8_off( $wide ), "remove utf8 flag" );
ok( !has_utf8( $wide ) );

my $latin = { hello => ['world'] };
ok( !has_utf8( $latin ) );
ok( _utf8_on( $latin ), "added utf8 flag" );
ok( has_utf8( $latin ) );

my $a;
$a->[1] = "Pie";
ok( !has_utf8( $a ) );
ok( utf8_on( $a ),   "convert to utf8" );
ok( _utf8_off( $a ), "utf8" );
