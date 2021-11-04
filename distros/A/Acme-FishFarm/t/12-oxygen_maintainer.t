#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Output;

BEGIN {
    use_ok( "Acme::FishFarm::OxygenMaintainer" ) || BAIL_OUT;
}

# default installer
my $o2_maintainer = Acme::FishFarm::OxygenMaintainer->install;
is( ref($o2_maintainer), "Acme::FishFarm::OxygenMaintainer", "Correct class");
is( $o2_maintainer->current_DO, 8, "Correct default DO level" );
is( $o2_maintainer->DO_threshold, 5, "Correct default DO threshold");

is( $o2_maintainer->is_low_DO, 0, "Enough oxygen" );

$o2_maintainer->set_DO_threshold(10);
is( $o2_maintainer->DO_threshold, 10, "Correct new DO threshold" );

$o2_maintainer->current_DO(2);
is( $o2_maintainer->is_low_DO, 1, "Your fish is suffocating" );

# test oxygen generation rate
is( $o2_maintainer->oxygen_generation_volume, 0.2, "Correct O2 generation rate" );
$o2_maintainer->set_oxygen_generation_volume(1);
is( $o2_maintainer->oxygen_generation_volume, 1, "Correct new O2 generation rate" );

# pump oxygen
# reset everything
$o2_maintainer->current_DO(1);
$o2_maintainer->set_DO_threshold(5);
is( $o2_maintainer->current_DO, 1, "Correct DO level" );
is( $o2_maintainer->DO_threshold, 5, "Correct DO threshold");
is( $o2_maintainer->is_low_DO, 1, "Your fish is suffocating" );
ok( $o2_maintainer->generate_oxygen, "Generating oxygen..." ); # +1 mg/L of O2, not changed
is( $o2_maintainer->current_DO, 2, "Pumped in correct volume of oxygen" );

# custom installer
my $custom_o2_maintainer = Acme::FishFarm::OxygenMaintainer->install(
    current_DO => 3, DO_threshold => 6
);

is( $custom_o2_maintainer->current_DO, 3, "Correct custom DO level" );
is( $custom_o2_maintainer->DO_threshold, 6, "Correct custom DO threshold");
is( $custom_o2_maintainer->oxygen_generation_volume, 0.2, "Correct custom O2 generation rate" );
is( $custom_o2_maintainer->is_low_DO, 1, "Time to pump oxygen!" );
$custom_o2_maintainer->generate_oxygen; # 3+0.2 = 3.2
is( $custom_o2_maintainer->current_DO, 3.2, "Pumps are pumping correct amount of O2" );

# for decreasing O2, use current_DO to update
    # this feature will not be included in this module, probably in Acme::FishFarm :)

done_testing;

# besiyata d'shmaya



