#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use AI::Perceptron::Simple;

use FindBin;
use constant MODULE_NAME => "AI::Perceptron::Simple";

# 36 headers
my @attributes = qw ( 
    glossy_cover	has_plastic_layer_on_cover	male_present	female_present	total_people_1	total_people_2	total_people_3
	total_people_4	total_people_5_n_above	has_flowers	flower_coverage_more_than_half	has_leaves	leaves_coverage_more_than_half	has_trees
	trees_coverage_more_than_half	has_other_living_things	has_fancy_stuff	has_obvious_inanimate_objects	red_shades	blue_shades	yellow_shades
	orange_shades	green_shades	purple_shades	brown_shades	black_shades	overall_red_dominant	overall_green_dominant
	overall_yellow_dominant	overall_pink_dominant	overall_purple_dominant	overall_orange_dominant	overall_blue_dominant	overall_brown_dominant
	overall_black_dominant	overall_white_dominant );

my $total_headers = scalar @attributes;

my $perceptron = AI::Perceptron::Simple->new( {
    initial_value => 0.01,
    attribs => \@attributes
} );

ok( AI::Perceptron::Simple->can("preserve"), "&preserve is persent" );
ok( AI::Perceptron::Simple->can("revive"), "&revive is present" );

my $nerve_file = $FindBin::Bin . "/perceptron_state_synonyms.nerve";
ok( AI::Perceptron::Simple::preserve( $perceptron, $nerve_file ), "preserve is working good so far" );
ok( -e $nerve_file, "Found the perceptron file" );

ok( AI::Perceptron::Simple::revive( $nerve_file ), "Perceptron loaded" );
my $loaded_perceptron = AI::Perceptron::Simple::revive( $nerve_file );
is( ref $loaded_perceptron, MODULE_NAME, "Correct class after loading" );

done_testing();

# besiyata d'shmaya


