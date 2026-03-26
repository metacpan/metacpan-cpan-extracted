#! perl

use v5.28;
use strict;
use feature 'signatures';

# 8<8<8<8<8<8<

use CXC::Data::Visitor 'visit', 'RESULT_CONTINUE';

my %root = (
    fruit => {
        berry  => 'purple',
        apples => [ 'fuji', 'macoun' ],
    } );

visit(
    \%root,
    sub ( $kydx, $vref, @ ) {
        $vref->$* = 'blue' if $kydx eq 'berry';
        return RESULT_CONTINUE;
    } );

say $root{fruit}{berry}

