#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Output;

use AI::Perceptron::Simple;

use FindBin;

# TRAINING_DATA & VALIDATION_DATA have the same contents, in real world, don't do this
    # use different sets of data for training and validating the nerve. Same goes to testing data.
    # I'm doing this only to make sure the nerve is working correctly

use constant TRAINING_DATA => $FindBin::Bin . "/book_list_train.csv";
use constant VALIDATION_DATA => $FindBin::Bin . "/book_list_validate.csv";


use constant VALIDATION_DATA_OUTPUT_FILE => $FindBin::Bin . "/book_list_validate_lab-filled.csv";
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
    learning_rate => 0.001,
    threshold => 0.8,
    attribs => \@attributes
} );

my $nerve_file = $FindBin::Bin . "/perceptron_1.nerve";

for ( 0..5 ) {
    print "Round $_\n";
    $perceptron->train( TRAINING_DATA, "brand", $nerve_file, WANT_STATS, IDENTIFIER );
    print "\n";
}
#print Dumper($perceptron), "\n";

# write ack to original file
my $ori_file_size = -s VALIDATION_DATA;
stdout_like {
    ok ( $perceptron->take_lab_test( {
                stimuli_validate => VALIDATION_DATA,
                predicted_column_index => 4,
            } ), 
            "Validate succedded!" );
} qr/book_list_validate\.csv/, "Correct output for take_lab_test when saving file";

# with new output file
stdout_like {
    ok ( $perceptron->take_lab_test( {
            stimuli_validate => VALIDATION_DATA,
            predicted_column_index => 4,
            results_write_to => VALIDATION_DATA_OUTPUT_FILE
        } ), 
        "Validate succedded!" );

} qr/book_list_validate_lab\-filled\.csv/, "Correct output for take_lab_test when saving to NEW file";

ok( -e VALIDATION_DATA_OUTPUT_FILE, "New validation file found" );
isnt( -s VALIDATION_DATA_OUTPUT_FILE, 0, "New output file is not empty" );

done_testing;
# besiyata d'shmaya







