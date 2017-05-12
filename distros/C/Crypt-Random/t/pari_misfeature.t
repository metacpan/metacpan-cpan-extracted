#!/usr/bin/perl -sw
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: pari_misfeature.t,v 1.2 2001/06/22 18:17:19 vipul Exp $

use lib 'lib';
use lib '../lib';

print "1..1\n";

use Crypt::Random qw(makerandom makerandom_itv); 
use Math::Pari qw(PARI);

for ( 1 .. 100 ) { 
    my $I = PARI('34579687721723281952451');
    my $l = makerandom_itv(Lower => $I+1, Upper => 2*$I);
    print "$l\n";
}

print "ok 1\n";

