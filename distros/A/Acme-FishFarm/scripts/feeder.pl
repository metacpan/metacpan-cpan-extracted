#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm::Feeder;

my $feeder = Acme::FishFarm::Feeder->install( timer => 3, feeding_volume => 150 );

say "Feeder installed and switched on!";
say "";

#while (1) {
for (0..20){

    if ( $feeder->timer_is_up ) {
        say "\nTimer is up, time to feed the fish!";
        say "Feeding ", $feeder->feeding_volume, " cm^3 of fish food to the fish...";
        
        $feeder->feed_fish ( verbose => 1 );
        
        say $feeder->food_remaining, " cm^3 of fish food remaining in the tank.\n";
    }
    
    if ( $feeder->food_remaining <=0  ) {
        $feeder->refill; # default back to 500 cm^3
        say "Refilled food tank back to ", $feeder->food_tank_capacity, " cm^3.\n";
    }
    
    say $feeder->time_remaining, " hours left until it's time to feed the fish.";

    sleep(1);
    $feeder->tick_clock;
}

say "";
say "Feeder was switched off, please remeber to feed your fish on time :)";

# besiyata d'shmaya
