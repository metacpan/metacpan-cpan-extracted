#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use AI::Perceptron::Simple;

use FindBin;
use constant TRAINING_DATA => $FindBin::Bin . "/book_list_train.csv";
use constant MODULE_NAME => "AI::Perceptron::Simple";
use constant WANT_STATS => 1;
use constant IDENTIFIER => "book_name";

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

my %attribs = $perceptron->get_attributes; # merging will cause problems
my $perceptron_headers = keys %attribs; # scalar context directly return number of keys

is( $perceptron_headers, $total_headers, "Correct headers" );
# print $FindBin::Bin, "\n";
# print TRAINING_DATA, "\n";
ok ( -e TRAINING_DATA, "Found the training file" );

# saving and loading - this should go into a new test script
my $nerve_file = $FindBin::Bin . "/perceptron_tame.nerve";
#ok( $perceptron->train( TRAINING_DATA, "brand", $nerve_file, WANT_STATS, IDENTIFIER ), "No problem with \'train\' method so far" );

{
local $@ = "";
eval { $perceptron->train( TRAINING_DATA, "brand", $nerve_file, WANT_STATS, IDENTIFIER) };
is ( $@, "", "No problem with \'train\' method (verbose) so far" );
}

ok ( $perceptron->train( TRAINING_DATA, "brand", $nerve_file), "No problem with \'train\' method (non-verbose) so far" );

# no longer returns the file anymore since v0.03
# is ( $perceptron->train( TRAINING_DATA, "brand", $nerve_file), $nerve_file, "\'train\' method returns the correct value" );

ok( AI::Perceptron::Simple->can("save_perceptron"), "&save_perceptron is persent" );
ok( AI::Perceptron::Simple->can("load_perceptron"), "&loaded_perceptron is present" );

ok( AI::Perceptron::Simple::save_perceptron( $perceptron, $nerve_file ), "save_perceptron is working good so far" );
ok( -e $nerve_file, "Found the perceptron file" );

ok( AI::Perceptron::Simple::load_perceptron( $nerve_file ), "Perceptron loaded" );
my $loaded_perceptron = AI::Perceptron::Simple::load_perceptron( $nerve_file );
is( ref $loaded_perceptron, MODULE_NAME, "Correct class after loading" );

done_testing();

# besiyata d'shmaya




