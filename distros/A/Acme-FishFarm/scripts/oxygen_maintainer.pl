#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Acme::FishFarm::OxygenMaintainer;

my $oxygen = Acme::FishFarm::OxygenMaintainer->install( DO_generation_volume => 3 );
say "Oxygen maintainer installed!\n";


while ( "fish are using up oxygen" ) {
    say "Current Oxygen Level: ", $oxygen->current_DO, " mg/L",
        " (low: < ", $oxygen->DO_threshold, ")";
    #say "Low Oxygen Level: ", $oxygen->DO_threshold, " mg/L";

    if ( $oxygen->is_low_DO ) {
        say "Fish status: Suffocating";
        say "  !! Low oxygen level!";
        say "Pumping ", $oxygen->oxygen_generation_volume, " mg/L of oxygen into the water..." ;
        $oxygen->generate_oxygen;
    } else {
        say "Fish status: Happy";
    }
    
    #consume_oxygen( $oxygen, 3 ); # die
    consume_oxygen( $oxygen, rand(2.5) );
    
    sleep(3);
    say "";
}


# must pass in a decimal
sub consume_oxygen {
    my $o2_maintainer = shift;
    my $consumed_oxygen = reduce_precision ( shift );
    #$consumed_oxygen =~ /(\d+\.\d{3})/;
    say "$consumed_oxygen mg/L of oxygen consumed...";
    my $o2_remaining = $o2_maintainer->current_DO - $consumed_oxygen;
    $o2_maintainer->current_DO( $o2_remaining );
}

sub reduce_precision {
    my $sensor_reading = shift;
    die "Please pass in a decimal value" if not $sensor_reading =~ /\./;
    $sensor_reading =~ /(\d+\.\d{3})/;
    $1;
}

# besiyata d'shmaya



