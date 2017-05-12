#!/usr/bin/env perl
use strict;
use warnings;

## 06-pkcs.t
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::ES::PKCS1v15;
use Crypt::RSA::Key;
use Crypt::RSA::Key::Public;
use Crypt::RSA::Key::Private;
use MIME::Base64           qw(decode_base64);

plan tests => 4;

my $pkcs = new Crypt::RSA::ES::PKCS1v15;
my $message = "My plenteous";
my ($pub, $priv) = readkeys();

is( $pkcs->encryptblock ( Key => $pub ), 53, "encryptblock" );
is( $pkcs->decryptblock ( Key => $pub ), 64, "decryptblock" );

my $ct = $pkcs->encrypt (Key => $pub, Message => $message);
     die $pkcs->errstr unless $ct;
my $pt = $pkcs->decrypt (Key => $priv, Cyphertext => $ct);
     die $pkcs->errstr unless $pt;

is($pt, $message, "message->encrypt->decrypt = message");

# testing for null in plaintext bug in Crypt::RSA::ES::PKCS1v15

my $pl = decode_base64('LXKiHJUTtaMABa4dXM/dgg==');

my $cy = $pkcs->encrypt (Message => $pl, Key => $pub);
my $plr = $pkcs->decrypt (Cyphertext => $cy, Key => $priv);

is($pl, $plr, "encryption with nulls in message works");

sub readkeys {

    my $n = "73834345487788514568533774308502691535472856730213458245198623 \
             26913500918212899613538952044531113709736546304347778208211537 \
             356895300653369009683166191489";

    my $d = "42559776454402653689602825763344464625105789228943555733842995 \
             42606639366881642674904410038192736942200540859365906591454274 \
             243748563931879218810311206577";

    my $e = "65537";

    $n =~ s/[\n ]//ig;
    $d =~ s/[\n ]//ig;

    my $pub  = new Crypt::RSA::Key::Public;
    my $priv = new Crypt::RSA::Key::Private (Identity => 'f', Password => 'b');
    $pub->n ($n); $pub->e ($e);
    $priv->n ($n); $priv->d ($d);
    return ($pub, $priv);

}
