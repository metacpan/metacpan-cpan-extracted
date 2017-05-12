#!/usr/bin/perl -s
##
## 09-publickey.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 10-keygen.t,v 1.1 2001/04/06 18:33:31 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::Key;
use Data::Dumper;

my $i = 0;
print "1..15\n";
my $keychain = new Crypt::RSA::Key; 

for my $ksize (qw(128 256 512 768 1024)) { 

    my ($pub, $pri) = $keychain->generate ( Identity => 'mail@vipul.net', 
                                            Password => 'a day so foul and fair', 
                                            Verbosity => 1,
                                            Size     => $ksize );

    die $keychain->errstr if $keychain->errstr();
    print $pub->Identity eq 'mail@vipul.net' ? "ok" : "not ok"; print " ", ++$i, "\n";
    print $pub->n eq $pri->p * $pri->q  ? "ok" : "not ok"; print " ", ++$i, "\n";
    $pri->check || die $pri->errstr();
    print $pri->check  ? "ok" : "not ok"; print " ", ++$i, "\n";

}


