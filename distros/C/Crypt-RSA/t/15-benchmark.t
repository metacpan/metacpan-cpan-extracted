#!/usr/bin/perl -s
##
##
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 07-pss.t,v 1.3 2001/04/06 18:33:31 vipul Exp $ 

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::Key;
use Crypt::RSA::Key::Public;
use Crypt::RSA::Key::Private;
use Crypt::RSA::SS::PSS;
use Crypt::RSA::SS::PKCS1v15;
use Crypt::RSA::DataFormat qw(os2ip i2osp);
use Math::Pari qw(PARI);
use Benchmark;
use Data::Dumper;
no warnings;

print "1..1\n";
my $i = 0;
local $pss = new Crypt::RSA::SS::PSS;  
local $pkcs = new Crypt::RSA::SS::PKCS1v15;  

local $message =  " Whither should I fly? \
                 I have done no harm. But I remember now \
                 I am in this earthly world, where to do harm \
                 Is often laudable, to do good sometime \
                 Accounted dangerous folly. ";

local $keychain = Crypt::RSA::Key->new();

local ($pub, $priv) = readkeys();

my $keygen = new Crypt::RSA::Key; 

local ($pub2, $priv2) = 
$keygen->generate ( Size => 512, Verbosity => 0, Password => 'sdfd', Identity => 'sdsdf' );

local ($sig, $sigpkcs);
$count ||= 100;

local $sigcrt = $pss->sign (
          Message => $message,
          Key     => $priv,
        );

local $sigcrtpkcs = $pkcs->sign (
          Message => $message,
          Key     => $priv,
        );


my ($message, $pkcs, $pss, $pub, $pub2, $priv, $priv2, $sig, $keychain, $sigpkcs);
 
timethese ($count, {

    'PSS-sign-CRT' => ' 
            $pss->sign (
                Message => $message,
                Key     => $priv2,
            )
    ',

    'PSS-verify-CRT' => '
            $pss->verify (
                Key => $pub2, 
                Message => $message, 
                Signature => $sigcrt, 
        )
    ',


    'PSS-sign' => ' 
            $sig = $pss->sign (
                Message => $message,
                Key     => $priv,
            )
    ',

    'PSS-verify' => '
            $pss->verify (
                Key => $pub, 
                Message => $message, 
                Signature => $sig, 
        );
    ',

    'PKCS-sign' => ' 
            $sigpkcs = $pkcs->sign (
                Message => $message,
                Key     => $priv,
            )
    ',

    'PKCS-sign-CRT' => ' 
            $pkcs->sign (
                Message => $message,
                Key     => $priv2,
            )
    ',


    'PKCS-verify' => '
            $pkcs->verify (
                Key => $pub, 
                Message => $message, 
                Signature => $sigpkcs, 
        );
    ',    

    'PKCS-verify-CRT' => '
            $pkcs->verify (
                Key => $pub2, 
                Message => $message, 
                Signature => $sigcrtpkcs, 
        );
    ',
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

print "ok 1\n";

