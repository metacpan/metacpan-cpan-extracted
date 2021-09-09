#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Output;

use AI::Perceptron::Simple "shuffle_stimuli";
#use AI::Perceptron::Simple ":process_data";

use FindBin;
# this one will directly use "ORIGINAL_STIMULI" as the filename if use with "=>", strange
use constant ORIGINAL_STIMULI => $FindBin::Bin . "/book_list_to_shuffle.csv";

my $original_stimuli = $FindBin::Bin . "/book_list_to_shuffle.csv";
my $shuffled_data_1 = $FindBin::Bin . "/shuffled_1.csv";
my $shuffled_data_2 = $FindBin::Bin . "/shuffled_2.csv";
my $shuffled_data_3 = $FindBin::Bin . "/shuffled_3.csv";

ok( -e $original_stimuli, "Found the original file" );

{
local $@;
eval { shuffle_stimuli };
like( $@, qr/^Please specify/, "Croaked at invocation with any arguements" )
}

{
local $@;
eval { shuffle_stimuli($original_stimuli) };
like( $@, qr/output files/, "Croaked when new file names not present" )
}

shuffle_stimuli( $original_stimuli => $shuffled_data_1, $shuffled_data_2, $shuffled_data_3 );

stdout_like {
    shuffle_stimuli( ORIGINAL_STIMULI, $shuffled_data_1, $shuffled_data_2, $shuffled_data_3 );
} qr/^Saved/, "Correct output after saving file";


ok( -e $shuffled_data_1, "Found the first shuffled file" );
ok( -e $shuffled_data_2, "Found the second shuffled file" );
ok( -e $shuffled_data_3, "Found the third shuffled file" );

done_testing();

# besiyata d'shmaya



