#!/usr/bin/env perl
use strict;
use warnings;

## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::Key;
use Crypt::RSA::Key::Public;
use Crypt::RSA::Key::Private;
use Crypt::RSA::SS::PSS;

plan tests => 9;

my $pss = new Crypt::RSA::SS::PSS;

my $message =  " Whither should I fly? \
                 I have done no harm. But I remember now \
                 I am in this earthly world, where to do harm \
                 Is often laudable, to do good sometime \
                 Accounted dangerous folly. ";

my $keychain = Crypt::RSA::Key->new();

my ($pub, $priv) = readkeys();

for (1 .. 4) {

    $message .= "\n$message";

    my $sig = $pss->sign (
                Message => $message,
                Key     => $priv,
    ) || die $pss->errstr();

    is ( $pss->verifyblock (Key => $priv), length($sig), "verifyblock" );

    my $verify = $pss->verify (
                   Key => $pub,
                   Message => $message,
                   Signature => $sig,
    ) || die $pss->errstr;

    ok ( $verify, "verify successful" );

}

# Again with salt
{
  my $message = "Oh what can ail thee, knight-at-arms,\n  Alone and palely loitering?\nThe sedge has withered from the lake,\n  And no birds sing.";

  my($sig, $salt) = $pss->sign( Message => $message, Key => $priv )
                    or die $pss->errstr();

  my $verify = $pss->verify_with_salt (
                   Key => $pub,
                   Message => $message,
                   Signature => $sig,
                   Salt => $salt,
  ) || die $pss->errstr;

    ok ( $verify, "verify with salt successful" );
}


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
