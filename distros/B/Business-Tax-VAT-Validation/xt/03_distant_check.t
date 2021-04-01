#!/usr/bin/env perl
use strict;
use warnings;
use Test;

my %distant_checks = (
    AT      =>  ['U12345678'],
    BE      =>  ['0123456789'],
    BG      =>  ['123456789', '1234567890'],
    CY      =>  ['12345678A'],
    CZ	    =>  ['12345678', '123456789', '1234567890'],
    DE      =>  ['123456789'],
    DK      =>  ['12345678', '12 45 78 90', '1245 78 90'],
    EE	    =>  ['123456789'],
    EL      =>  ['123456789'],
    ES      =>  ['123456789', 'A2345678B'],
    FI      =>  ['12345678'],
    FR      =>  ['12345678901', '12 456789012', 'A2 456789012', '1B 456789012', 'AB 456789012'],
    GB      =>  ['123456789', '123456789012', '123 5678 01', '123 5678 12 234','GD345', 'HA123'],
    XI      =>  ['123456789', '123456789012', '123 5678 01', '123 5678 12 234','GD345', 'HA123'],
    HU      =>  ['12345678'],
    IE      =>  ['1234567A', '1B34567C', '1+34567C', '1*34567C'],
    IT      =>  ['12345678901'],
    LT      =>  ['123456789', '123456789012'],
    LU      =>  ['12345678'],
    LV      =>  ['12345678901'],
    MT	    =>  ['12345678'],
    NL      =>  ['123456789B12'],
    PL      =>  ['1234567890'],
    PT      =>  ['123456789'],
    RO      =>  ['12', '123', '1234', '12345', '123456', '1234567', '12345678', '123456789', '1234567890'],
    SE      =>  ['123456789012'],
    SI	    =>  ['12345678'],
    SK	    =>  ['1234567890']
);

use Business::Tax::VAT::Validation;

my $tests = 0;

for my $ms (keys %distant_checks) {
    $tests+= $#{$distant_checks{$ms}} + 1
}

plan tests => $tests;

my $hvat=Business::Tax::VAT::Validation->new();
for my $ms (keys %distant_checks) {
    for my $t (@{$distant_checks{$ms}}) {
        my $res=$hvat->check($t, $ms);
        if ($res){
            ok(1);
        } else {
            my $err = $hvat->get_last_error_code;
            if ($err == 2) {
                ok(1)
            } elsif ($err > 16 && $err < 257) {
                skip(1); 
            } elsif ($err > 257) {
                warn("skipping $ms$t : ".$hvat->get_last_error."\n");
                skip(1);
            } elsif ($err == 3 && $ms eq 'GB' && ($t eq 'GD345' || $t eq 'HA123')) {
                # These two codes are only successfully looked up in VIES, HMRC
                # throws a 400 error indicating that the code is malformed.
                # This does not seem correct, but is observed behaviour.
                warn("skipping $ms$t : ".$hvat->get_last_error."\n");
                skip(1);
            } else {
                warn("Distant check for $ms$t failed: ".$err.' '.$hvat->get_last_error."\n");
                ok(0);
            }
        }
        ### To be cool with VIES server !
        sleep(1);
    }
}
exit 0;
__END__
