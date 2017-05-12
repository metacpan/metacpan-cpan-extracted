#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent::TermKey qw( FORMAT_VIM KEYMOD_CTRL );
use AnyEvent;

my $cv = AnyEvent->condvar;

my $aetk = AnyEvent::TermKey->new(
   term => \*STDIN,

   on_key => sub {
      my ( $key ) = @_;

      print "Got key: ".$key->termkey->format_key( $key, FORMAT_VIM )."\n";

      $cv->send if $key->type_is_unicode and
                   $key->utf8 eq "C" and
                   $key->modifiers & KEYMOD_CTRL;
   },
);

$cv->recv;
