#!/usr/bin/perl

use strict;

use Test::More tests => 4;

use AnyEvent;
use AnyEvent::TermKey;

use IO::Handle;
pipe( my ( $rd, $wr ) ) or die "Cannot pipe() - $!";

# Sanitise this just in case
$ENV{TERM} = "vt100";

my $key;
my $key_cv = AnyEvent->condvar;

my $aetk = AnyEvent::TermKey->new(
   term => $rd,
   on_key => sub { ( $key ) = @_; $key_cv->send },
);

$wr->syswrite( "\e" );

my $wait_cv = AnyEvent->condvar;
my $timeout = AnyEvent->timer(
   after => $aetk->get_waittime / 2000,
   cb => sub { $wait_cv->send },
);

$wait_cv->recv;

ok( !defined $key, '$key still not defined after 1/2 waittime' );

$key_cv->recv;

ok( $key->type_is_keysym,                    '$key->type_is_keysym after Escape timeout' );
is( $key->sym, $aetk->keyname2sym("Escape"), '$key->keysym after Escape timeout' );
is( $key->modifiers, 0,                      '$key->modifiers after Escape timeout' );
