#!/usr/bin/perl
use strict;
use warnings;

## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::Key;
use Crypt::RSA::SS::PKCS1v15;
use Crypt::RSA::Key::Public;
use Crypt::RSA::Key::Private;

plan tests => 14;

my $message =  " Whither should I fly? \
                 I have done no harm. But I remember now \
                 I am in this earthly world, where to do harm \
                 Is often laudable, to do good sometime \
                 Accounted dangerous folly. ";

# my ($pub, $priv) = readkeys();

# SHA384 and SHA512 require a key length of at least 768.
# SHA224 amd SJA256 require a key length of at least 512.
# SHA1, MD5, and MD2 require at least 384.
my ($pub, $priv) = Crypt::RSA::Key->new->generate  (
                        Size => 768,
                        Identity => 'i am i',
                        Password => 'guess me',
                    );

foreach my $hash (qw(MD2 MD5 SHA1 SHA224 SHA256 SHA384 SHA512)) {

    my $pkcs = new Crypt::RSA::SS::PKCS1v15 ( Digest => $hash );

    my $sig = $pkcs->sign (
                Message => $message,
                Key     => $priv,
    ) || die $pkcs->errstr();

    is( $pkcs->verifyblock(Key => $priv), length($sig), "verifyblock" );

    my $verify = $pkcs->verify (
                   Key => $pub,
                   Message => $message,
                   Signature => $sig,
    ) || die $pkcs->errstr;

    ok($verify, "Signed and verified using $hash hash");

}



# Not used
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
