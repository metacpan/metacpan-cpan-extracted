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
use Crypt::RSA::SS::PKCS1v15;
use Crypt::RSA::DataFormat qw(os2ip i2osp);
use Benchmark;

my $count = shift || 5;

plan tests => 1;

my $pss = new Crypt::RSA::SS::PSS;
my $pkcs = new Crypt::RSA::SS::PKCS1v15;

my $message =  " Whither should I fly? \
                 I have done no harm. But I remember now \
                 I am in this earthly world, where to do harm \
                 Is often laudable, to do good sometime \
                 Accounted dangerous folly. ";
# With a very small message, GMP is so fast all we're benchmarking is helper
# functions.  If we make the message too long, then no-GMP/Pari systems take
# forever.  Compromise.
$message .= $message for 1..4;

my $keychain = Crypt::RSA::Key->new();

my ($pub, $priv) = readkeys();

my $keygen = new Crypt::RSA::Key;

my ($pub2, $priv2) =
$keygen->generate (
  Size => 512,
  Verbosity => 0,
  Password => 'sdfd',
  Identity => 'sdsdf',
);

my ($sig, $sigpkcs);

my $sigcrt = $pss->sign (
          Message => $message,
          Key     => $priv,
        );

my $sigcrtpkcs = $pkcs->sign (
          Message => $message,
          Key     => $priv,
        );


timethese ($count, {

    'PSS-sign-CRT' => sub {
            $pss->sign (
                Message => $message,
                Key     => $priv2,
            )
    },

    'PSS-verify-CRT' => sub {
            $pss->verify (
                Key => $pub2,
                Message => $message,
                Signature => $sigcrt,
        )
    },


    'PSS-sign' => sub {
            $sig = $pss->sign (
                Message => $message,
                Key     => $priv,
            )
    },

    'PSS-verify' => sub {
            $pss->verify (
                Key => $pub,
                Message => $message,
                Signature => $sig,
        );
    },

    'PKCS-sign' => sub {
            $sigpkcs = $pkcs->sign (
                Message => $message,
                Key     => $priv,
            )
    },

    'PKCS-sign-CRT' => sub {
            $pkcs->sign (
                Message => $message,
                Key     => $priv2,
            )
    },


    'PKCS-verify' => sub {
            $pkcs->verify (
                Key => $pub,
                Message => $message,
                Signature => $sigpkcs,
        );
    },

    'PKCS-verify-CRT' => sub {
            $pkcs->verify (
                Key => $pub2,
                Message => $message,
                Signature => $sigcrtpkcs,
        );
    },
});


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

ok(1, "benchmarks complete");
