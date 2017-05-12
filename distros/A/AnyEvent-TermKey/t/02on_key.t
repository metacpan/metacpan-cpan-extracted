#!/usr/bin/perl

use strict;

use Test::More tests => 6;

use AnyEvent;
use AnyEvent::TermKey;

use IO::Handle;
pipe( my ( $rd, $wr ) ) or die "Cannot pipe() - $!";

# Sanitise this just in case
$ENV{TERM} = "vt100";

my $key;
my $cv = AnyEvent->condvar;

my $aetk = AnyEvent::TermKey->new(
   term => $rd,
   on_key => sub { ( $key ) = @_; $cv->send; },
);

$wr->syswrite( "h" );

undef $key;
$cv->recv;

is( $key->termkey, $aetk->termkey, '$key->termkey after h' );

ok( $key->type_is_unicode,     '$key->type_is_unicode after h' );
is( $key->codepoint, ord("h"), '$key->codepoint after h' );
is( $key->modifiers, 0,        '$key->modifiers after h' );

is( $key->utf8, "h", '$key->utf8 after h' );

is( $key->format( 0 ), "h", '$key->format after h' );

undef $aetk;
