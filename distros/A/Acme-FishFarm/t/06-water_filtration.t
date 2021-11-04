#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( "Acme::FishFarm::WaterFiltration" ) || BAIL_OUT;
}

my $water_filter = Acme::FishFarm::WaterFiltration->install;
is( ref($water_filter), "Acme::FishFarm::WaterFiltration", "Correct class" );
is( $water_filter->current_waste_count, 0, "Correct default waste count" );
$water_filter->current_waste_count(50);
is( $water_filter->current_waste_count, 50, "Correct new waste count" );
is( $water_filter->waste_count_threshold, 75, "Correct default waste count threshold" );
$water_filter->set_waste_count_threshold(100);
is( $water_filter->waste_count_threshold, 100, "Correct new waste count threshold" );

is( $water_filter->reduce_waste_count_by, 10, "Correct waste count reduction" );
$water_filter->set_waste_count_to_reduce(15);
is( $water_filter->reduce_waste_count_by, 15, "Correct new waste count reduction" );

# turn on spatulas, if not cleaning process will not happen
$water_filter->current_waste_count(10);

is( $water_filter->is_on_spatulas, 0, "Spatulas not on" );
$water_filter->clean_cylinder;
is( $water_filter->current_waste_count, 10, "Spatulas not on, can't clean anything" );
$water_filter->turn_on_spatulas;
is( $water_filter->is_on_spatulas, 1, "Spatulas switched on" );
$water_filter->clean_cylinder;
is( $water_filter->current_waste_count, 0, "Cylinder is totaly clean :)" );

$water_filter->current_waste_count(15);
$water_filter->clean_cylinder(-2);
is( $water_filter->current_waste_count, 13, "Cylinder is cleaned correctly even with a negative value" );

is( $water_filter->is_cylinder_dirty, 0, "Cylinder not dirty yet" );
$water_filter->current_waste_count(120);
is( $water_filter->is_cylinder_dirty, 1, "Cylinder is dirty!" );
is( $water_filter->is_filter_layer_dirty, 1, "Synonym 'is_filter_layer_dirty' working" );

# custom installation
my $water_filter_2 = Acme::FishFarm::WaterFiltration->install( 
    current_waste_count => 35, waste_threshold =>50 );
is( $water_filter_2->current_waste_count, 35, "Correct custom waste count" );
is( $water_filter_2->waste_count_threshold, 50, "Correct custom waste count threshold" );
is( $water_filter_2->is_filter_layer_dirty, 0, "Cylinder not dirty yet" );
$water_filter_2->current_waste_count(50);
is( $water_filter_2->is_filter_layer_dirty, 1, "Cylinder is now dirty" );
is( $water_filter_2->is_on_spatulas, 0, "Spatulas not turned on, can't clean cylinder" );
$water_filter_2->turn_on_spatulas;
is( $water_filter_2->is_on_spatulas, 1, "Spatulas turned on, ready to clean" );
$water_filter_2->clean_filter_layer;
is( $water_filter_2->current_waste_count, 0, "Synonym 'clean_filter_layer' working" );

done_testing;

# besiyata d'shmaya



