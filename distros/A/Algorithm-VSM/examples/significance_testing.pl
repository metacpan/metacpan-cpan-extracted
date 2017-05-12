#!/usr/bin/perl -w

##  significance_testing.pl

##  See Item 11 in the README of the `examples' directory.

use strict;
use Algorithm::VSM;


my $debug_signi = 0;

die "Must supply one command-line argument, which must either be 'randomization' or 't-test'\n" 
    unless @ARGV == 1;
my $significance_testing_method = shift @ARGV;
die "The command-line argument must either be 'randomization' or " .
    "'t-test' for this module to be useful\n"
             if ($significance_testing_method ne 'randomization') and
                ($significance_testing_method ne 't-test');

print "Proceeding with significance testing based on $significance_testing_method\n";
    
my $MAX_ITERATIONS = 100000;
my $THRESHOLD_1    = 0.02;               # for LSA-1
my $THRESHOLD_2    = 0.12;               # for LSA-2

my $corpus_dir = "corpus";  

my $query_file      = "test_queries.txt";
my $stop_words_file = "stop_words.txt";  
my $relevancy_file   = "relevancy.txt"; 


#   Significance testing is applied to the output of two retrieval
#   algorithms.  We want to know if the difference between the MAP values
#   for the two algorithms are statistically significant.  Our example here
#   is based to LSA retrieval algorithms with different values for the
#   singular value acceptance threshold lsa_svd_threshold.  Under the 
#   null hypothesis, we assume that the two algorithms are the same.  
#   Our test statistic will be the difference between the MAP values.

########################  Algorithm 1  #########################

my $lsa1 = Algorithm::VSM->new( 
                   break_camelcased_and_underscored  => 1,  # default: 1
                   case_sensitive      => 0,                # default: 0 
                   corpus_directory    => $corpus_dir,
                   file_types          => ['.txt', '.java'],
                   lsa_svd_threshold   => $THRESHOLD_1,
                   min_word_length     => 4,
                   query_file          => $query_file,
                   relevancy_file      => $relevancy_file,
                   stop_words_file     => $stop_words_file,
                   want_stemming       => 1,                # default: 0
          );

$lsa1->get_corpus_vocabulary_and_word_counts();
$lsa1->generate_document_vectors();
$lsa1->construct_lsa_model();
$lsa1->upload_document_relevancies_from_file();
$lsa1->precision_and_recall_calculator('lsa');
my $avg_precisions_1 = $lsa1->get_query_sorted_average_precision_for_queries();
my $MAP_Algo_1 = 0;
map {$MAP_Algo_1 += $_} @$avg_precisions_1;
$MAP_Algo_1 /= @$avg_precisions_1;
print "MAP value for LSA-1: $MAP_Algo_1\n";
print "Avg precisions for LSA-1: @$avg_precisions_1\n" 
                                            if $debug_signi;


########################  Algorithm 2  #########################

my $lsa2 = Algorithm::VSM->new( 
                   break_camelcased_and_underscored  => 1,  # default: 1
                   case_sensitive      => 0,                # default: 0 
                   corpus_directory    => $corpus_dir,
                   file_types          => ['.txt', '.java'],
                   lsa_svd_threshold   => $THRESHOLD_2,
                   min_word_length     => 4,
                   query_file          => $query_file,
                   relevancy_file      => $relevancy_file,
                   stop_words_file     => $stop_words_file,
                   want_stemming       => 1,                # default: 0
          );

$lsa2->get_corpus_vocabulary_and_word_counts();
$lsa2->generate_document_vectors();
$lsa2->construct_lsa_model();
$lsa2->upload_document_relevancies_from_file();
$lsa2->precision_and_recall_calculator('lsa');
my $avg_precisions_2 = $lsa2->get_query_sorted_average_precision_for_queries();
my $MAP_Algo_2 = 0;
map {$MAP_Algo_2 += $_} @$avg_precisions_2;
$MAP_Algo_2 /= @$avg_precisions_2;
print "MAP value for LSA-2: $MAP_Algo_2\n";
print "Average precisions for LSA-2: @$avg_precisions_2\n"
                                          if $debug_signi;

#  This is the observed value for the test statistic that will be subject to 
#  significance testing:
my $OBSERVED_t = $MAP_Algo_1 - $MAP_Algo_2;

print "\n\nMAP Difference that will be Subject to Significance Testing: $OBSERVED_t\n\n";
                               

########################   Significance Testing  ######################

my @range = 0..@$avg_precisions_1-1;

if ($debug_signi) {
    my $total_number_of_permutations = 2 ** @range;
    print "\n\nTotal num of permuts $total_number_of_permutations\n\n";
}

#   For each permutation of the algorithm labels over the queries, we 
#   will store the test_statistic in the array \@test_statistic.
my @test_statistic = ();

#  At each iteration, we create a random permutation of the algo_1 and
#  algo_2 labels over the queries as explained on slides 39 and 45 of my
#  tutorial on Significance Testing.  For each assignment of average
#  precision values to algo_1, we calculate the MAP value for algo_1, and
#  the same for algo_2.  The difference between the two MAP values is the
#  value of the test_statistic for that iteration.  Our goal is create
#  test_statistic values for, say, 100,000 iterations of this calculation.

my $iter = 0;
while (1) {
    #  Here is the logic we use for permuting the algo_1 and algo_2 labels
    #  over the average precision values.  We first create a random
    #  permutation of the integers between 0 and the size of the query set.
    #  We refer to this permuted list as permuted_range in what follows.
    #  We then walk through the elements of the list permuted_range and at
    #  each position test when the value at that position is less than or
    #  greater than half the size of the number of queries.  This
    #  determines which of the two avg. precision values for a given query
    #  gets algo_1 label and which gets the algo_2 label.
    my @permuted_range = 0..@range-1;
    fisher_yates_shuffle( \@permuted_range );
    my @algo_1 = ();
    my @algo_2 = ();
    foreach (0..@range-1) {
        if ($permuted_range[$_] < @range / 2.0) {
            push @algo_1, $avg_precisions_1->[$_];
            push @algo_2, $avg_precisions_2->[$_];
        } else {
            push @algo_1, $avg_precisions_2->[$_];
            push @algo_2, $avg_precisions_1->[$_];
        }
    }
    my $MAP_1 = 0;
    my $MAP_2 = 0;
    if ($debug_signi) {
        print "\n\nHere come algo_1 and algo_2 average precisions:\n\n";
        print "\npretend produced by algo 1: @algo_1\n\n";
        print "pretend produced by algo 2: @algo_2\n";
    }
    map {$MAP_1 += $_} @algo_1;
    map {$MAP_2 += $_} @algo_2;
    $MAP_1 /= @range;
    $MAP_2 /= @range;        
    if ($debug_signi) {
        print "\nMAP_1: $MAP_1\n";
        print "MAP_2: $MAP_2\n\n";
    }
    $test_statistic[$iter] = $MAP_1 - $MAP_2;
    last if $iter++ == $MAX_ITERATIONS;
    print "." if $iter % 100 == 0;
}

if ($significance_testing_method eq 'randomization') {
    print "\n\nIn randomization based p-value calculation:\n\n";
    print "test-statistic values for different permutations: @test_statistic\n"
        if $debug_signi;

    #  This count keeps track of how many of the test_statistic values are
    #  less than and greater than the value in $OBSERVED_t
    my $count = 0;
    foreach (@test_statistic) {
        $count++ if $_ <= -1 * abs($OBSERVED_t);
        $count++ if $_ > abs($OBSERVED_t);
    }
    my $p_value = $count / @test_statistic;

    print "\n\n\nTesting the significance of the test statistic: $OBSERVED_t\n\n";
  
    print "\n\np_value for THRESHOLD_1 = $THRESHOLD_1 and THRESHOLD_2 = $THRESHOLD_2:   $p_value\n\n";

} elsif ($significance_testing_method eq 't-test') {
    print "\n\nIn Student's t-Test based p-value calculation:\n\n";

    my $mean = 0;
    my $variance = 0;
    my $previous_mean = 0;
    my $index = 0;
    map {    $index++;
             $previous_mean = $mean;
             $mean += ($_-$mean)/$index; 
             $variance = $variance*($index-1)+($_-$mean)*($_-$previous_mean);
             $variance /= $index;
        } @test_statistic;

    print "\n\nMean for test statistic values: $mean  and the variance: $variance\n";
###### The following commented out code is for verification:
#    use Statistics::OnLine;
#    my $S = Statistics::OnLine->new;
#    $S->add_data(@test_statistic);
#    my $verifymean = $S->mean;
#    my $verifyvariance = $S->variance;
#    print "\n\nVerification mean for test statistic values: $verifymean  and the verification variance: $verifyvariance\n";

    print "\n\nMAP Difference that will be Subject to Significance Testing: $OBSERVED_t\n\n";

    my $normalized_bound;
    my $p_value;
    if ($variance > 0.0000001) {
        $normalized_bound = ($OBSERVED_t - $mean) / sqrt($variance);
        print "Normalized bound: $normalized_bound\n\n";
        $p_value = 2*(1-cumulative_distribution_function(abs($normalized_bound)));
    } else {
        $p_value = 1.0;
    }
    print "\n\n\nTesting the significance of the test statistic: $OBSERVED_t\n\n";
    print "\n\np_value for THRESHOLD_1 = $THRESHOLD_1 and THRESHOLD_2 = $THRESHOLD_2:   $p_value\n\n";
}

############################  Utility Functions   #######################

# from perl docs:                                                              
sub fisher_yates_shuffle {                                                     
    my $arr =  shift;                                                          
    my $i = @$arr;                                                             
    while (--$i) {                                                             
        my $j = int rand( $i + 1 );                                            
        @$arr[$i, $j] = @$arr[$j, $i];                                         
    }                                                                          
}              

#  Abramowitz and Stugun's high-quality approximation to the normal CDF:
#  This approximation works only for positive arguments.
sub cumulative_distribution_function {
    my $x = shift;
    my $PI = 3.14159265358;
    my $normalized_pdf_value = exp(-($x**2)/2.0) / sqrt(2*$PI);
    my $t = 1 / (1 + 0.2316419 * $x);
    my $cdf = 1 - $normalized_pdf_value * (  0.319381530*$t 
                                       - 0.356563782*($t**2) 
                                       + 1.781477937*($t**3) 
                                       - 1.821255978*($t**4) 
                                       + 1.330274429*($t**5));
    return $cdf;
}
