#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id$

use strict;
use Test;

BEGIN { plan tests => 8 }

use Crypt::Primes qw(maurer);

ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0, 
		      Intermediates => 1, Generator => 1, Factors => 1 );
     $p->{Prime} and $#{$p->{Intermediates}} and $#{$p->{Factors}} and $p->{Generator};
   });

ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0, 
		      Intermediates => 1, Factors => 1 );
     $p->{Prime} and $#{$p->{Intermediates}} and not $p->{Generator} and $#{$p->{Factors}};
   });

ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0, 
		      Intermediates => 1, Generator => 1 );
     $p->{Prime} and $#{$p->{Intermediates}} and $p->{Generator} and not $p->{Factors};
   });


ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0, 
		      Generator => 1, Factors => 1 );
     $p->{Prime} and not $p->{Intermediates} and $p->{Generator} and $#{$p->{Factors}};
   });

ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0, Intermediates => 1 );
     $p->{Prime} and $#{$p->{Intermediates}} and not $p->{Generator} and not $p->{Factors};
   });

ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0, Factors => 1 );
     $p->{Prime} and not $p->{Intermediates} and not $p->{Generator} and $#{$p->{Factors}};
   });

ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0, Generator => 1 );
     $p->{Prime} and not $p->{Intermediates} and $p->{Generator} and not $p->{Factors};
   });

ok(sub {
     my $p = maurer ( Size => 128, Verbosity => 0 );
     ref $p eq 'Math::Pari';
   });

