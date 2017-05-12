#!/usr/bin/perl -sw
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
use Math::Pari qw(PARI);
use Data::Dumper;

print "1..8\n";
my $i = 0;
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

    print length ($sig) == $pss->verifyblock (Key => $priv) ? 
            "ok" : "not ok"; print " ", ++$i, "\n";

    my $verify = $pss->verify (
                   Key => $pub, 
                   Message => $message, 
                   Signature => $sig, 
    ) || die $pss->errstr;

    print $verify ? "ok" : "not ok"; print " ", ++$i, "\n";

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

