#!/usr/bin/perl

use AI::Perceptron::Simple;
use Test::More;

plan( skip_all => "This is just the specification" );
done_testing;

######### specifications ##############
#
# This specification is based on My::Perceptron (see my github repo) and packed into AI::Perceptron::Simple v1.00
#
# Version 0.01 - completed on 8 August 2021
#   [v] able to create perceptron
#   [v] able to process data: &train method
#       [v] read csv - for training stage
#   [v] able to save the actual perceptron object and load it back
#
# Version 0.02 - completed on 17 August 2021
#   [v] implement output algorithm for train and finalize it
#   [v] read and calculate data line by line, not bulk, so no shuffling method
#   [v] implement validate method
#       [v] read csv bulk - for validating and testing stages
#       [v] write into a new csv file - validation and testing stages
#   [v] implement testing method
#       [v] read csv bulk - for validating and testing stages
#       [v] write into a new csv file - validation and testing stages
#
# Version 0.03 - completed on 19 August 2021
#   [v] implement confusion matrix
#       [v] read only expected and predicted columns, line by line
#       [v] return a hash of data
#           [v] TP, TN, FP, FN
#           [v] accuracy
#           [v] sensitivity
#   [v] remove the return value for "train" method
#   [v] display confusion matrix data to console
#       [v] use Text:Matrix
#
# Version 0.04 / Version 1.0 - completed on 23 AUGUST 2021
#   [v] add synonyms
#       [v] synonyms MUST call actual subroutines and not copy pasting!
#       train: [v] tame  [v] exercise
#       validate: [v] take_mock_exam  [v] take_lab_test
#       test: [v] take_real_exam  [v] work_in_real_world
#       generate_confusion_matrix: [v] get_exam_results
#       display_confusion_matrix: [v] display_exam_results
#       save_perceptron: [v] preserve
#       load_perceptron: [v] revive
#
# Version 1.01
#   [v] fixed currently known issues as much as possible (see 'Changes')
#       - the "long size integer" problem happens when tests are run in the incorrect sequence, at least that's what 
#           happened when I tested it on Windows :) Running the test a second time didn't give eny errors.
#
# Version 1.02
#   [] support for more file types (nerve file) for portability
#   [] refactor codes
#   [] improve the documentation
#
# Version 0.0x
#   -implement shuffling system
#
# ...
#
############ "flow" of the codes ############

# these three steps could be done in seperated scripts if necessary
# &train and &validate could be put inside a loop or something
# the parameters make more sense when they are taken from @ARGV
    # so when it's the first time training, it will create the nerve_file,
    # the second time and up it will directly overrride that file since everything is read from it
    # ... anyway :) afterall training stage wasn't meant to be a fully working program, so it shouldnt be a problem
# just assume that 
$perceptron->train( $stimuli_train, $save_nerve_to_file ); 
    # reads training stimuli from csv
    # tune attributes based on csv data
        # calls the same subroutine to do the calculation
    # shouldn't give any output upon completion
    # should save a copy of itselt into a new file
    # returns the nerve's data filename to be used in validate()
        # these two can go into a loop with conditions checking
        # which means that we can actuall write this
            # $perceptron->validate( $stimuli_validate, 
            #                        $perceptron->train( $stimuli_train, $save_nerve_to_file ) 
            #                       );
            # and then check the confusion matrix, if not satisfied, run the loop again :)
$perceptron->validate( $stimuli_validate, $nerve_data_to_read );
$perceptron->test( $stimuli_test ); # loads nerve data from data file, turn into a object, then do the following:
    # reads from csv :
        # validation stimuli
        # testing stimuli
    # both will call the same subroutine to do calculation
    # both will write predicted data into the original data file

# show results ie confusion matrix (TP-true positive, TN-true negative, FP-false positive, FN-false negative)
# this should only be done during validation and testing
$perceptron->generate_confusion_matrix( { 1 => $csv_header_true, 0 => $csv_header_false } );
    # calculates the 4 thingy based on the current data on hand (RAM), don't read from file again, it shouldn't be a problem
        # returns a hash
    # ie it must be used together with validate() and test() to avoid problems
        # ie validate() and test() must be in different scripts, which makes sense
        # unless, create 3 similar objects to do the work in one go
        
# save data of the trained perceptron
$perceptron->save_data( $data_file );
    # see train() on saving copy of the perceptron

# load data of percpetron for use in actual program
My::Perceptron::load_data( $data_file );
    # loads the perceptron and returns the actual My::Perceptron object
        # should work though as Storable claims it can do that


# besiyata d'shmaya




