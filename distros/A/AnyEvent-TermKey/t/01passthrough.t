#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

use AnyEvent::TermKey;

my $aetk = AnyEvent::TermKey->new(
   term => \*STDIN,
   on_key => sub {},
);

defined $aetk or die "Cannot create termkey instance";

# We know 'Space' ought to exist
my $sym = $aetk->keyname2sym( 'Space' );

ok( defined $sym, "defined keyname2sym('Space')" );

is( $aetk->get_keyname( $sym ), 'Space', "get_keyname eq Space" );

my $key;

ok( defined( $key = $aetk->parse_key( "A", 0 ) ), '->parse_key "A" defined' );

ok( $key->type_is_unicode,     '$key->type_is_unicode' );
is( $key->codepoint, ord("A"), '$key->codepoint' );
is( $key->modifiers, 0,        '$key->modifiers' );

is( $aetk->format_key( $key, 0 ), "A", '->format_key yields "A"' );
