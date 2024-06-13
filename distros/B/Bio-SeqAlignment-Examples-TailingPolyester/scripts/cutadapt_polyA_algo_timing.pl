#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
use strict;
use warnings;
use Time::HiRes qw(time);
use PDL;
use PDL::Primitive qw (where_both);
use PDL::Ufunc     qw (cumusumover);
use PDL::Stats::Basic;
use List::Util qw(reduce);
use constant ascii_A => ord('A');

## set the random seed
rand(323);

sub generate_string {
    my $length      = shift;
    my @nucleotides = ( 'A', 'C', 'T', 'G' );
    my $first_part  = join '', map $nucleotides[ rand @nucleotides ],
      1 .. int( 0.8 * $length );
    my $second_part = 'A' x ( $length - length($first_part) );
    return $first_part . $second_part;
}

sub benchmark_cutadapt {
    my $s          = shift;
    my $start_time = time;
    my $n          = length $s;
    my $best_index = $n;
    my $best_score = my $score = 0;
    foreach my $i ( reverse( 0 .. $n - 1 ) ) {
        my $nuc = substr $s, $i, 1;
        $score += $nuc eq 'A' ? +1 : -2;
        if ( $score > $best_score ) {
            $best_index = $i;
            $best_score = $score;
        }
    }
    $best_index = $n - $best_index;
    if ( $best_score < 0.4 * ( $best_index + 1 ) ) {
        $best_index = $n;
    }
    substr( $s, -$best_index ) = '';

    my $end_time = time;
    return $end_time - $start_time;
}

sub benchmark_cutadapt_map {
    my $s          = shift;
    my $start_time = time;
    my $n          = length $s;
    my $sum        = 0;
    my $best_score = my $score = 0;
    my @s =
      map { $sum += ( $_ eq 'A' ? +1 : -2 ) }
      split //, reverse $s;
    my $best_index = reduce { $s[$a] > $s[$b] ? $a : $b } 0 .. $#s;
    $best_index =
      ( $s[$best_index] < 0.4 * ( $best_index + 1 ) )
      ? $n
      : $n - $best_index - 1;
    $s = substr $s, 0, $best_index;
    my $end_time = time;
    return $end_time - $start_time;
}

sub benchmark_cutadapt_C {
    my $s          = shift;
    my $start_time = time;
    my $best_index = _cutadapt_in_C($s);
    substr( $s, -$best_index ) = '';
    my $end_time = time;
    return $end_time - $start_time;
}


sub benchmark_pdl {
    my $s          = shift;
    my $start_time = time;
    my $n          = length $s;

    my $pdl_s = PDL->new( [ unpack( "C*", reverse $s ) ] );
    my ( $pdl_index, $pdl_c_index ) = where_both( $pdl_s, $pdl_s == ascii_A );
    $pdl_index   .= 1;
    $pdl_c_index .= -2;
    my $score      = cumusumover($pdl_s);
    my $max_index  = $score->maximum_ind;
    my $best_index = $n - $max_index - 1;
    if ( $score->at( $score->maximum_ind ) < 0.4 * ( $max_index + 1 ) ) {
        $best_index = $n;
    }
    $s = substr $s, 0, $best_index;
    my $end_time = time;
    return $end_time - $start_time;
}

my $polyA_min_25_pct_A = qr/
                ( ## match a poly A tail which is 
                  ## delimited at its 5' by *at least* one A
                  A{1,}
                      ## followed by the tail proper which has a    
                  (?:     ## minimum composition of 25% A, i.e.
                      ## we are looking for snippets with 
                      (?: 
                              ## up to 3 CTGs followed by at 
                              ## least one A
                              [CTG]{0,3}A{1,}    
                      )
                      |     ## OR
                      (?: 
                              ## at least one A followed by 
                              ## up to 3 CTGs
                              A{1,}[CTG]{0,3}
                      )
                  )+    ## extend as much as possible
              )\z/xp;

sub benchmark_regex {
    my $s          = shift;
    my $start_time = time;
    my $n          = length $s;
    $s =~ m/$$polyA_min_25_pct_A/;
    my $best_index = length $1;
    substr( $s, -$best_index ) = '';
    my $end_time = time;
    return $end_time - $start_time;
}
use constant THRESHOLD_LOG_LR => 6.907755;

sub benchmark_ML {
    my $s          = shift;
    my $start_time = time;
    my $n          = length $s;
    my $best_index = find_change_point_using_ML_inline( $s, THRESHOLD_LOG_LR );
    substr( $s, $best_index - $n ) = '';

    my $end_time = time;
    return $end_time - $start_time;
}


###################################################################################
my @lengths     = ( 100, 1000, 2000, 10000 );
my $repetitions = 2000;
my %methods     = (
    'benchmark_cutadapt'     => \&benchmark_cutadapt,
    'benchmark_cutadapt_map' => \&benchmark_cutadapt_map,
    'benchmark_cutadapt_C'   => \&benchmark_cutadapt_C,
    'benchmark_pdl'          => \&benchmark_pdl,
    'benchmark_regex'        => \&benchmark_regex,
    'benchmark_ML'           => \&benchmark_ML,
);
for my $method ( sort keys %methods ) {
    print "-" x 80 . "\n";
    print "Benchmarking with $method\n";
    print "-" x 80 . "\n";
    foreach my $length (@lengths) {
        my @times;
        foreach ( 1 .. $repetitions ) {
            my $s          = generate_string($length);
            my $time_taken = $methods{$method}->($s);
            push @times, $time_taken;
        }
        my $times       = pdl(@times);
        my $min_time    = $times->min;
        my $max_time    = $times->max;
        my $mean_time   = $times->average;
        my $stdev_time  = $times->stdv_unbiased;
        my $median_time = $times->median;
        print "\nStatistics for string of length $length:\n";
        printf "Mean time: %.1e microseconds\n",          1000000 * $mean_time;
        printf "Standard deviation: %.1e microseconds\n", 1000000 * $stdev_time;
        printf "Median time: %.1e microseconds\n", 1000000 * $median_time;
        printf "Min time: %.1e microseconds\n",    1000000 * $min_time;
        printf "Max time: %.1e microseconds\n",    1000000 * $max_time;
    }
}

use Inline C => <<'END_OF_C_CODE';
#include <stdlib.h> 
#include <string.h>
#include<stdio.h>  
#include <math.h>   

int _cutadapt_in_C(char *s) {
    int n = strlen(s);
    int best_index = n;
    int best_score = 0;
    int score = 0;
    for (int i = n - 1; i >= 0; i--) {
        char nuc = s[i];
        if (nuc == 'A') {
            score += 1;
        }
        else {
            score -= 2;
        }
        if (score > best_score) {
            best_index = i;
            best_score = score;
        }
    }
    best_index = (best_score < -0.4 * (best_index + 1)) ? n : n - best_index;
    return best_index;

}

int find_change_point_using_ML_inline( char *sequence_read,
    float threshold_log_LR) {

    float log_p1, log_q1, log_p0, log_q0, p1,q1;
    float loglik,  max_loglik ,H0_loglik;
     int change_point, len_3p, len_5p, l3n5p,n_of_A_3p_seq;
     int size_n_of_A_5p_seq,i;
     int* n_of_A_5p_seq;
     int seq_read_len = strlen(sequence_read);

    n_of_A_5p_seq = ( int*)malloc(seq_read_len * sizeof( int));
    if (n_of_A_5p_seq == NULL) {
        printf("can't alloc mem\n");
        return 1;
    }

    // A's as  binary sequences
    for(i=0;i<seq_read_len;i++)
        n_of_A_5p_seq[i] = (sequence_read[i]=='A') ? 1 : 0;
    
    // forward pass to compute the cumulative sums of As and not A's
    for( i =1; i< seq_read_len; i++){
        n_of_A_5p_seq[i]     += n_of_A_5p_seq[i-1];
    }
    
    //find the total number of As and non A's in the sequence
    int total_As     = n_of_A_5p_seq[seq_read_len-1];
    int total_non_As = seq_read_len - total_As ;
    change_point = size_n_of_A_5p_seq = seq_read_len-1;
    p1 = (float)total_As/seq_read_len;
    if (total_As == 0 || p1 ==seq_read_len) {
    	log_p1 = log_p0 = 0.0;
    }
    else{
    	log_p1 = log(p1);
        log_p0 = log(1-p1);
    }
    loglik = max_loglik = H0_loglik 
            = (float)total_As * log_p1 + total_non_As * log_p0;
    

    for(i = size_n_of_A_5p_seq - 1; i>=0; i--) {

        len_5p = i + 1 ;
        len_3p = size_n_of_A_5p_seq - i ;

        n_of_A_3p_seq = total_As - n_of_A_5p_seq[i] ;
        p1 = (float)n_of_A_5p_seq[i] / len_5p ;
        q1 = (float)n_of_A_3p_seq / len_3p;
        if (p1 == 0.0 || p1 == 1.0) {
            log_p1 = log_p0 = 0.0;
        }
        else{
            log_p1 = log(p1);
            log_p0 = log(1-p1);
        }
        if (q1 == 0.0 || q1 == 1.0) {
            log_q1 = log_q0 = 0.0;
        }
        else{
            log_q1 = log(q1);
            log_q0 = log(1-q1);
        }

        loglik = n_of_A_5p_seq[i] * log_p1 
                  + (len_5p - n_of_A_5p_seq[i]) * log_p0
                  + n_of_A_3p_seq * log_q1 
                  + (len_3p - n_of_A_3p_seq) * log_q0
                  ;
        //printf("I am here: %u, len of 3p is %u, len of 5p is %u and loglik is %lf\n",
        //    i,len_3p,len_5p,loglik);
        if(loglik >= max_loglik) {
            change_point = i;
            max_loglik = loglik;
        }

    }
    free(n_of_A_5p_seq);

    // shift change point by 1 because we the loop starts at zero
    change_point ++ ;

    return ( max_loglik - H0_loglik >= threshold_log_LR  
            ? change_point: size_n_of_A_5p_seq+1); 
}
 
END_OF_C_CODE

1;
