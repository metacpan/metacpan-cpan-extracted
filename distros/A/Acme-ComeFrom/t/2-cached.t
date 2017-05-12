#!/usr/bin/perl

use strict;
use Test::More tests => 2;

BEGIN { use_ok('Acme::ComeFrom') };

sub OK  { ok(1, "comefrom @_") }
sub NOK { ok(0, "comefrom @_") }

$Acme::ComeFrom::CacheEXPR = 0;	# Avoid 'once' warnings

{
    my $i = 1;
    $Acme::ComeFrom::CacheEXPR = 1;

    DUMMY: 0;                   # This does not evalutes the "$i++" below.
    EXPR1: NOK('cached EXPR');
    if ($] eq "FORTRAN") {      # This is never true, but:
        comefrom 'EXPR'.$i++;   # Coming from "EXPR1:" above...
        OK('cached EXPR');      # ...and OKs the test
    }
}

__END__
