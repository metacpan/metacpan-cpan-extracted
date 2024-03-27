#! perl

use v5.20;
use strict;

use CXC::Data::Visitor 'visit';
use DDP;

my $hoh = { fruit => { berry => 'purple' }, };

visit(
    $hoh,
    sub {
        my ( $key, $vref ) = @_;
        p $key;
        $$vref = 'blue' if $key eq 'berry';
    } );

say $hoh->{fruit}{berry}    # 'blue'

