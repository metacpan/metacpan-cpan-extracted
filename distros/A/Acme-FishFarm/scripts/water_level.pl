#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm ":all";
use Acme::FishFarm::WaterLevelMaintainer;

my $water_level = Acme::FishFarm::WaterLevelMaintainer->install;

say "Water level maintainer installed and switched on!\n";

while ( "Fish are living under the water..." ) {
    check_water_level( $water_level, reduce_precision(rand(8)) );
    sleep(1);
    say "";
}

=head1 use Acme::FishFarm's check_water_level
sub check_water_level {
    my $water_level = shift;
    my $current_reading = shift;
    my $height_increase = $water_level->water_level_increase_height; # for output
    my $water_level_threshold = $water_level->low_water_level_threshold;
    
    $water_level->current_water_level( $current_reading ); # input by user
    print "Current Water Level: ", $current_reading, " m (low: < ", $water_level_threshold, " m)\n";

    if ( $water_level->is_low_water_level ) {
        print "  !! Water level is low!\n";
        $water_level->pump_water_in;
        print "  Pumping in ", $height_increase, " m of water...\n";
        print "Current Water Level: ", $water_level->current_water_level, "\n";
    } else {
        print "  Water level is still normal.\n";
    }
    1;
}
=cut

# besiyata d'shmaya


