#!/usr/bin/env perl
use strict;
use warnings;

## 11-wrapper.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA;

my $bigintlib = Math::BigInt->config()->{lib};
my @keysizes = ($bigintlib =~ /^Math::BigInt::(GMP|Pari)$/)
             ? (384, 512, 1536)
             : (384);            # Calc is too slow

plan tests => 4 * scalar @keysizes;

my $rsa = new Crypt::RSA;

my $plaintext =<<'EOM';
   "They met me in the day of success, and I have
    learned by the perfectest report they have more in them than
    mortal knowledge. When I burned in desire to question them
    further, they made themselves air, into which they vanished.

    Whiles I stood rapt in the wonder of it, came missives from the
    King, who all-hailed me 'Thane of Cawdor'; by which title,
    before, these weird sisters saluted me and referred me to the
    coming on of time with 'Hail, King that shalt be!' This have I
    thought good to deliver thee, my dearest partner of greatness,
    that thou mightst not lose the dues of rejoicing, by being
    ignorant of what greatness is promised thee. Lay it to thy heart,
    and farewell.

    Glamis thou art, and Cawdor, and shalt be
    What thou art promised. Yet do I fear thy nature.
    It is too full o' the milk of human kindness
    To catch the nearest way. Thou wouldst be great;
    Art not without ambition, but without
    The illness should attend it. What thou wouldst highly,
    That wouldst thou holily; wouldst not play false,
    And yet wouldst wrongly win. Thou'ldst have, great Glamis,
    That which cries, "Thus thou must do, if thou have it;
    And that which rather thou dost fear to do
    Than wishest should be undone." Hie thee hither,
    That I may pour my spirits in thine ear,
    And chastise with the valor of my tongue
    All that impedes thee from the golden round,
    Which fate and metaphysical aid doth seem
    To have thee crown'd withal."

EOM

for my $keysize (@keysizes) {

    # $plaintext = "" if $keysize == 512;

    my ($pub, $pri) = $rsa->keygen (
                        Size      => $keysize,
                        Identity  => "Lord Macbeth",
                        Password  => "xx"
                      ) or die $rsa->errstr();

    my $ctxt = $rsa->encrypt (
                        Message => $plaintext,
                        Key     => $pub,
                        Armour  => 1,
                     ) || die $rsa->errstr();

    # diag($ctxt);
    like( $ctxt, qr/Scheme: Crypt::RSA::ES::OAEP/, "Encrypted $keysize bits with armor" );

    my $ptxt = $rsa->decrypt (
                        Cyphertext => $ctxt,
                        Key        => $pri,
                        Armour     => 1,
                     );
    die $rsa->errstr() if $rsa->errstr();

    # diag($ptxt);
    is($ptxt, $plaintext, "Decrypted with armor");

    my $signature = $rsa->sign (
                        Message => $plaintext,
                        Key => $pri,
                        Armour => 1,
                    ) || die $rsa->errstr();

    # diag($signature);
    like( $signature, qr/Scheme: Crypt::RSA::SS::PSS/, "RSA signature" );

    my $verify = $rsa->verify (
                    Message => $plaintext,
                    Key => $pub,
                    Signature => $signature,
                    Armour => 1,
                 );

    ok($verify, "Verified RSA signature");

}
