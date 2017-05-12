#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 14-ss-pkcs1v15.t,v 1.1 2001/04/06 18:33:31 vipul Exp $ 

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::Key;
use Crypt::RSA::SS::PKCS1v15;
use Math::Pari qw(PARI);
use Crypt::RSA::Key::Public;
use Crypt::RSA::Key::Private;

print "1..6\n";
my $i = 0;

my $message =  " Whither should I fly? \
                 I have done no harm. But I remember now \
                 I am in this earthly world, where to do harm \
                 Is often laudable, to do good sometime \
                 Accounted dangerous folly. ";

# my ($pub, $priv) = readkeys();
my ($pub, $priv) = Crypt::RSA::Key->new->generate  (
                        Size => 512, 
                        Identity => 'f', 
                        Password => 'f', 
                        Verbosity => 1
                    );

for (qw(MD2 MD5 SHA1)) { 
   
    my $pkcs = new Crypt::RSA::SS::PKCS1v15 ( Digest => $_ );
 
    my $sig = $pkcs->sign (
                Message => $message,
                Key     => $priv,
    ) || die $pkcs->errstr();

    print length($sig) == $pkcs->verifyblock(Key => $priv) ? 
            "ok " : "not ok " , ++$i , "\n";

    my $verify = $pkcs->verify (
                   Key => $pub, 
                   Message => $message, 
                   Signature => $sig, 
    ) || die $pkcs->errstr;

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
