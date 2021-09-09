#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Output;

use AI::Perceptron::Simple;

#use local::lib;
use Text::Matrix;

use FindBin;

use constant TEST_FILE => $FindBin::Bin . "/book_list_test-filled.csv";
use constant NON_BINARY_FILE => $FindBin::Bin . "/book_list_test-filled-non-binary.csv";

my $nerve_file = $FindBin::Bin . "/perceptron_1.nerve";
my $perceptron = AI::Perceptron::Simple::load_perceptron( $nerve_file );

ok ( my %c_matrix = $perceptron->get_confusion_matrix( { 
        full_data_file => TEST_FILE, 
        actual_output_header => "brand",
        predicted_output_header => "predicted",
    } ), 
    "get_confusion_matrix method is working");

is ( ref \%c_matrix, ref {}, "Confusion matrix in correct data structure" );

is ( $c_matrix{ true_positive }, 2, "Correct true_positive" );
is ( $c_matrix{ true_negative }, 4, "Correct true_negative" );
is ( $c_matrix{ false_positive }, 1, "Correct false_positive" );
is ( $c_matrix{ false_negative }, 3, "Correct false_negative" );

is ( $c_matrix{ total_entries }, 10, "Total entries is correct" );
ok ( AI::Perceptron::Simple::_calculate_total_entries( \%c_matrix ), 
    "Testing the 'untestable' &_calculate_total_entries" );
is ( $c_matrix{ total_entries }, 10, "'illegal' calculation of total entries is correct" );

like ( $c_matrix{ accuracy }, qr/60/, "Accuracy seems correct to me" );
ok ( AI::Perceptron::Simple::_calculate_accuracy( \%c_matrix ), 
    "Testing the 'untestable' &_calculate_accuracy" );
like ( $c_matrix{ accuracy }, qr/60/, "'illegal' calculation of accuracy seems correct to me" );

like ( $c_matrix{ sensitivity }, qr/40/, "Accuracy seems correct to me" );
ok ( AI::Perceptron::Simple::_calculate_sensitivity( \%c_matrix ), 
    "Testing the 'untestable' &_calculate_sensitivity" );
like ( $c_matrix{ accuracy }, qr/60/, "'illegal' calculation of sensitivity seems correct to me" );

{
    local $@;
    eval {
        $perceptron->get_confusion_matrix( { 
            full_data_file => NON_BINARY_FILE,
            actual_output_header => "brand",
            predicted_output_header => "predicted",
        } );
    };

    like ( $@, qr/Something\'s wrong\!/, "Croaked! Found non-binary values in file");
}

my $piece;
my @pieces = ('A: ', 'P: ', 'actual', 'predicted', 'entries', 'Accuracy', 'Sensitivity', 'MP520', 'Yi Lin');

for $piece ( @pieces ) {
    stdout_like {
    
        ok ( $perceptron->display_exam_results( \%c_matrix, { zero_as => "MP520", one_as => "Yi Lin"  } ),
            "display_exam_results is working");
        
    } qr /(?:$piece)/, "$piece displayed";

}

{
    local $@;
    
    eval {
        $perceptron->display_confusion_matrix( \%c_matrix, { one_as => "Yi Lin" } );
    };
    
    like ( $@, qr/zero_as/, "Missing keys found: zero_as!" );
    unlike ( $@, qr/one_as/, "Confirmed one_as is present but not zero_as" );
}

{
    local $@;
    
    eval {
        $perceptron->display_confusion_matrix( \%c_matrix, { zero_as => "MP520" } );
    };
    
    like ( $@, qr/one_as/, "Missing keys found: one_as!" );
    unlike ( $@, qr/zero_as/, "Confirmed zero_as is present but not one_as" );
}

{
    local $@;
    
    eval {
        $perceptron->display_confusion_matrix( \%c_matrix );
    };
    
    like ( $@, qr/zero_as one_as/, "Both keys not found" );
}

# more_stats enabled

subtest "More stats" => sub {

    my %c_matrix_more_stats = $perceptron->get_confusion_matrix( { 
            full_data_file => TEST_FILE, 
            actual_output_header => "brand",
            predicted_output_header => "predicted",
            more_stats => 1,
        } );

    like ( $c_matrix_more_stats{ precision }, qr/66.66/, "Precision seems correct to me" );
    is ( $c_matrix_more_stats{ specificity }, 80, "Specificity seems correct to me" );
    is ( $c_matrix_more_stats{ F1_Score }, 50, "F1 Score seems correct to me" );
    like ( $c_matrix_more_stats{ negative_predicted_value }, qr/57.142/, "Negative Predicted Value seems correct to me" );
    is ( $c_matrix_more_stats{ false_negative_rate }, 60, "False Negative Rate seems correct to me" );
    is ( $c_matrix_more_stats{ false_positive_rate }, 20, "False positive Rate seems correct to me" );
    like ( $c_matrix_more_stats{ false_discovery_rate }, qr/33.33/, "False Discovery Rate seems correct to me" );
    like ( $c_matrix_more_stats{ false_omission_rate }, qr/42.85/, "False Omission Rate seems correct to me" );
    is ( $c_matrix_more_stats{ balanced_accuracy }, 60, "Balanced Acuracy seems correct to me" );


    my $piece;
    my @pieces = ('A: ', 'P: ', 'actual', 'predicted', 'entries', 'Accuracy', 'Sensitivity', 'MP520', 'Yi Lin', "Precision", "Specificity", "F1 Score", "Negative Predicted Value", "False Negative Rate", "False Positive Rate", "False Discovery Rate", "False Omission Rate", "Balanced Accuracy");

    for $piece ( @pieces ) {
        stdout_like {
        
            ok ( $perceptron->display_exam_results( \%c_matrix_more_stats, { zero_as => "MP520", one_as => "Yi Lin"  } ),
                "display_exam_results is working");
            
        } qr /(?:$piece)/, "$piece displayed";

    }
    $perceptron->display_exam_results( \%c_matrix_more_stats, { 
        zero_as => "MP520", 
        one_as => "Yi Lin"  } );
};

done_testing;

# besiyata d'shmaya




