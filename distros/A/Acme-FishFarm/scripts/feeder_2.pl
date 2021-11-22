#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm ":all";
use Acme::FishFarm::Feeder;

my $feeder = Acme::FishFarm::Feeder->install( timer => 3, feeding_volume => 150 );

while ( "fish are living in the water..." ) {
    check_feeder( $feeder, verbose => 1 );
    sleep 2;
    say "";
}

# besiyata d'shmaya
