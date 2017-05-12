package Algorithm::ExpectationMaximization;

#---------------------------------------------------------------------------
# Copyright (c) 2014 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::ExpectationMaximization is a pure Perl implementation for
# Expectation-Maximization based clustering of multi-dimensional data that can be
# modeled as a Gaussian mixture.
# ---------------------------------------------------------------------------

use 5.10.0;
use strict;
use warnings;
use Carp;
use File::Basename;
use Math::Random;
use Graphics::GnuplotIF;
use Math::GSL::Matrix;
use Scalar::Util 'blessed';

our $VERSION = '1.22';

# from perl docs:
my $_num_regex =  '^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$'; 

# Constructor:
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if check_for_illegal_params(@params) == 0;
    bless {
        _datafile         =>   $args{datafile} || croak("datafile required"),
        _mask             =>   $args{mask}     || croak("mask required"),
        _K                =>   $args{K}       || croak("number of clusters required"),
        _terminal_output  =>   $args{terminal_output}   || 0,
        _seeding          =>   $args{seeding}           || 'random',
        _seed_tags        =>   $args{seed_tags}         || [],
        _max_em_iterations=>   $args{max_em_iterations} || 100,
        _class_priors     =>   $args{class_priors}      || [],
        _debug            =>   $args{debug}             || 0,
        _N                =>   0,
        _data             =>   {},
        _data_id_tags     =>   [],
        _clusters         =>   [],
        _cluster_centers  =>   [],
        _data_dimensions  =>   0,
        _cluster_normalizers            => [],
        _cluster_means                  => [],
        _cluster_covariances            => [],
        _class_labels_for_data          => {},
        _class_probs_at_each_data_point => {},
        _expected_class_probs           => {}, 
        _old_priors                     => [],
        _old_old_priors                 => [],
        _fisher_quality_vs_iteration    => [],
        _mdl_quality_vs_iterations      => [],
    }, $class;
}


sub read_data_from_file {
    my $self = shift;
    my $filename = $self->{_datafile};
    $self->read_data_from_file_csv() if $filename =~ /.csv$/;
    $self->read_data_from_file_dat() if $filename =~ /.dat$/;
}

sub read_data_from_file_csv {
    my $self = shift;
    my $numregex =  '[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?';
    my $filename = $self->{_datafile} || die "you did not specify a file with the data to be clustered";
    my $mask = $self->{_mask};
    my @mask = split //, $mask;
    $self->{_data_dimensions} = scalar grep {$_ eq '1'} @mask;
    print "data dimensionality:  $self->{_data_dimensions} \n"if $self->{_terminal_output};
    open FILEIN, $filename or die "Unable to open $filename: $!";
    die("Aborted. get_training_data_csv() is only for CSV files") unless $filename =~ /\.csv$/;
    local $/ = undef;
    my @all_data = split /\s+/, <FILEIN>;
    my %data_hash = ();
    my @data_tags = ();
    foreach my $record (@all_data) {    
        my @splits = split /,/, $record;
        die "\nYour mask size (including `N' and 1's and 0's) does not match\n" .
            "the size of at least one of the data records in the file.\n"
            unless scalar(@mask) == scalar(@splits);
        my $record_name = shift @splits;
        $data_hash{$record_name} = \@splits;
        push @data_tags, $record_name;
    }
    $self->{_data} = \%data_hash;
    $self->{_data_id_tags} = \@data_tags;
    $self->{_N} = scalar @data_tags;
    # Need to make the following call to set the global mean and covariance:
    # my $covariance =  $self->estimate_mean_and_covariance(\@data_tags);
    # Need to make the following call to set the global eigenvec eigenval sets:
    # $self->eigen_analysis_of_covariance($covariance);
    if ( defined($self->{_K}) && ($self->{_K} > 0) ) {
        carp "\n\nWARNING: YOUR K VALUE IS TOO LARGE.\n The number of data " .
             "points must satisfy the relation N > 2xK**2 where K is " .
             "the number of clusters requested for the clusters to be " .
             "meaningful $!" 
                         if ( $self->{_N} < (2 * $self->{_K} ** 2) );
        print "\n\n\n";
    }
}

sub read_data_from_file_dat {
    my $self = shift;
    my $datafile = $self->{_datafile};
    my $mask = $self->{_mask};
    my @mask = split //, $mask;
    $self->{_data_dimensions} = scalar grep {$_ eq '1'} @mask;
    print "data dimensionality:  $self->{_data_dimensions} \n"
	if $self->{_terminal_output};
    open INPUT, $datafile
        or die "unable to open file $datafile: $!";
    chomp( my @raw_data = <INPUT> );
    close INPUT;
    # Transform strings into number data
    foreach my $record (@raw_data) {
        next unless $record;
        next if $record =~ /^#/;
        my @data_fields;
        my @fields = split /\s+/, $record;
        die "\nABORTED: Mask size does not correspond to row record size" 
            if $#fields != $#mask;
        my $record_id;
        foreach my $i (0..@fields-1) {
            if ($mask[$i] eq '0') {
                next;
            } elsif ($mask[$i] eq 'N') {
                $record_id = $fields[$i];
            } elsif ($mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "misformed mask for reading the data file";
            }
        }
        my @nums = map {/$_num_regex/;$_} @data_fields;
        $self->{_data}->{ $record_id } = \@nums;
    }
    my @all_data_ids = keys %{$self->{_data}};
    $self->{_data_id_tags} = \@all_data_ids;
    $self->{_N} = scalar @all_data_ids;
    if ( defined($self->{_K}) && ($self->{_K} > 0) ) {
        carp "\n\nWARNING: YOUR K VALUE IS TOO LARGE.\n The number of data " .
             "points must satisfy the relation N > 2xK**2 where K is " .
             "the number of clusters requested for the clusters to be " .
             "meaningful $!" 
                         if ( $self->{_N} < (2 * $self->{_K} ** 2) );
    }
}


# This is the heart of the module --- in the sense that this method implements the EM
# algorithm for the estimating the parameters of a Gaussian mixture model for the
# data. In the implementation shown below, we declare convergence for the EM
# algorithm when the change in the class priors over three iterations falls below a
# threshold.  The current value of this threshold, as can be seen in the function
# compare_array_floats(), is 0.00001.
sub EM {
    my $self = shift;
    $self->initialize_class_priors();
    for (my $em_iteration=0; $em_iteration < $self->{_max_em_iterations}; 
                                                             $em_iteration++) {
        if ($em_iteration == 0) {
            print "\nSeeding the EM algorithm with:\n";                     
            $self->display_seeding_stats();
            print "\nFinished displaying the seeding information\n";
            print "\nWill print out a dot for each iteration of EM:\n\n";
        }
        my $progress_indicator = $em_iteration % 5 == 0 ? $em_iteration : ".";
        print $progress_indicator;
        foreach my $data_id (@{$self->{_data_id_tags}}) {
            $self->{_class_probs_at_each_data_point}->{$data_id} = [];
            $self->{_expected_class_probs}->{$data_id} = [];
        }
        # Calculate prob(x | C_i) --- this is the prob of data point x as
        # a member of class C_i. You must do this for all K classes:
        foreach my $cluster_index(0..$self->{_K}-1) {
            $self->find_prob_at_each_datapoint_for_given_mean_and_covar(
                $self->{_cluster_means}->[$cluster_index],
                $self->{_cluster_covariances}->[$cluster_index] );
        }
        $self->{_cluster_normalizers} = [];
        if ($self->{_debug}) {
            print "\n\nDisplaying prob of a data point vis-a-vis each class:\n\n";
            foreach my $data_id (sort keys %{$self->{_data}}) {
                my $class_probs_at_a_point = 
                      $self->{_class_probs_at_each_data_point}->{$data_id};
                print "Class probs for $data_id: @$class_probs_at_a_point\n"
            }
        }
        # Calculate prob(C_i | x) which is the posterior prob of class
        # considered as a r.v. to be C_i at a given point x.  For a given
        # x, the sum of such probabilities over all C_i must add up to 1:
        $self->find_expected_classes_at_each_datapoint();
        if ($self->{_debug}) {
            print "\n\nDisplaying expected class probs at each data point:\n\n";
            foreach my $data_id (sort keys %{$self->{_expected_class_probs}}) {
                my $expected_classes_at_a_point = 
                                   $self->{_expected_class_probs}->{$data_id};
                print "Expected classes $data_id: @$expected_classes_at_a_point\n";
            }
        }
        # 1. UPDATE MEANS:        
        my @new_means;
        foreach my $cluster_index(0..$self->{_K}-1) {         
            $new_means[$cluster_index] = 
                       Math::GSL::Matrix->new($self->{_data_dimensions},1);        
            $new_means[$cluster_index]->zero();
            foreach my $data_id (keys %{$self->{_data}}) {                        
                my $data_record = $self->{_data}->{$data_id};
                my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
                $data_vec->set_col(0,$data_record);
                $new_means[$cluster_index] +=  
                    $self->{_expected_class_probs}->{$data_id}->[$cluster_index] *
                    $data_vec->copy();
                $self->{_cluster_normalizers}->[$cluster_index] +=
                    $self->{_expected_class_probs}->{$data_id}->[$cluster_index];
            }
            $new_means[$cluster_index] *= 1.0 / 
                                 $self->{_cluster_normalizers}->[$cluster_index];
        }
        if ($self->{_debug}) {
            foreach my $meanvec (@new_means) {
                display_matrix("At EM Iteration $em_iteration, new mean vector is", 
                                                                          $meanvec);
            }
        }
        $self->{_cluster_means} = \@new_means;
        # 2. UPDATE COVARIANCES:
        my @new_covariances;
        foreach my $cluster_index(0..$self->{_K}-1) {         
            $new_covariances[$cluster_index] = 
                  Math::GSL::Matrix->new($self->{_data_dimensions},
                                         $self->{_data_dimensions});
            $new_covariances[$cluster_index]->zero();
            my $normalizer = 0;
            foreach my $data_id (keys %{$self->{_data}}) {                        
                my $data_record = $self->{_data}->{$data_id};
                my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
                $data_vec->set_col(0,$data_record);
                my $mean_subtracted_data = 
                    $data_vec - $self->{_cluster_means}->[$cluster_index];
                my $outer_product = outer_product($mean_subtracted_data, 
                                                  $mean_subtracted_data);
                $new_covariances[$cluster_index] +=  
                    $self->{_expected_class_probs}->{$data_id}->[$cluster_index] *
                    $outer_product;
            }
            $new_covariances[$cluster_index] *= 
                                   1.0 / 
                                   $self->{_cluster_normalizers}->[$cluster_index];
        }
        $self->{_cluster_covariances} = \@new_covariances;
        # 3. UPDATE PRIORS:
        $self->{_old_old_priors} = deep_copy_array( $self->{_old_priors} )
                                    if @{$self->{_old_priors}} > 0;
        $self->{_old_priors} = deep_copy_array( $self->{_class_priors} ); 
        foreach my $cluster_index(0..$self->{_K}-1) {      
            $self->{_class_priors}->[$cluster_index] = 
                 $self->{_cluster_normalizers}->[$cluster_index] / $self->{_N};
        }
        my @priors = @{$self->{_class_priors}};
        print "\nUpdated priors: @priors\n\n\n" if $self->{_debug};
        push @{$self->{_fisher_quality_vs_iteration}}, 
                                                 $self->clustering_quality_fisher();
        push @{$self->{_mdl_quality_vs_iteration}}, $self->clustering_quality_mdl();
        if ( ($em_iteration > 5 && $self->reached_convergence()) 
             || ($em_iteration ==  $self->{_max_em_iterations} - 1) ) {
            my @old_old_priors = @{$self->{_old_old_priors}};  
            my @old_priors = @{$self->{_old_priors}};
            print "\n\nPrevious to previous priors:       @old_old_priors\n";
            print "Previous priors:                   @old_priors\n";
            print "Current class priors:              @{$self->{_class_priors}}\n";
            print "\n\nCONVERGENCE ACHIEVED AT ITERATION $em_iteration\n\n"
                if $em_iteration < $self->{_max_em_iterations} - 1; 
            last;
        }
    }
    print "\n\n\n";
}

sub reached_convergence {
    my $self = shift;
    return 1 if compare_array_floats($self->{_old_old_priors}, 
                                     $self->{_old_priors}) 
                &&
                compare_array_floats($self->{_old_priors}, 
                                     $self->{_class_priors});
    return 0;
}

# Classify the data into disjoint clusters using the Naive Bayes' classification:
sub run_bayes_classifier {
    my $self = shift;
    $self->classify_all_data_tuples_bayes($self->{_cluster_means}, 
                                         $self->{_cluster_covariances});
}

# Should NOT be called before run_bayes_classifier is run
sub return_disjoint_clusters {
    my $self = shift;
    return $self->{_clusters};
}

sub return_clusters_with_posterior_probs_above_threshold {
    my $self = shift;
    my $theta = shift;
    my @class_distributions;
    foreach my $cluster_index (0..$self->{_K}-1) {
        push @class_distributions, [];
    }
    foreach my $data_tag (@{$self->{_data_id_tags}}) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            push @{$class_distributions[$cluster_index]}, $data_tag
                if $self->{_expected_class_probs}->{$data_tag}->[$cluster_index] 
                                            > $theta;
        }
    }
    return \@class_distributions;
}    

sub return_individual_class_distributions_above_given_threshold {
    my $self = shift;
    my $theta = shift;
    my @probability_distributions;
    foreach my $cluster_index (0..$self->{_K}-1) {
        push @probability_distributions, [];
    }
    foreach my $cluster_index (0..$self->{_K}-1) {
        my $mean_vec = $self->{_cluster_means}->[$cluster_index];
        my $covar = $self->{_cluster_covariances}->[$cluster_index];
        foreach my $data_id (keys %{$self->{_data}}) {
            my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
            $data_vec->set_col( 0, $self->{_data}->{$data_id});
            my $datavec_minus_mean = $data_vec - $mean_vec;
            display_matrix( "datavec minus mean is ", $datavec_minus_mean )
                                    if $self->{_debug};
            my $exponent = undef;
            if ($self->{_data_dimensions} > 1) {
                $exponent = -0.5 * vector_matrix_multiply( 
                                               transpose($datavec_minus_mean),
                                matrix_vector_multiply($covar->inverse(), $datavec_minus_mean ) );
            } else {
                my @var_inverse = $covar->inverse()->as_list;
                my $var_inverse_val = $var_inverse[0];
                my @data_minus_mean = $datavec_minus_mean->as_list;
                my $data_minus_mean_val = $data_minus_mean[0];
                $exponent = -0.5 * ($data_minus_mean_val ** 2) * $var_inverse_val;
            }
            print "\nThe value of the exponent is: $exponent\n\n" if $self->{_debug};
            my $coefficient = 1.0 / \
                 ( (2 * $Math::GSL::Const::M_PI)**$self->{_data_dimensions} * sqrt($covar->det()) );
            my $prob = $coefficient * exp($exponent);
            push @{$probability_distributions[$cluster_index]}, $data_id 
                if $prob > $theta;
        }
    }
    return \@probability_distributions;
}

sub return_estimated_priors {
    my $self = shift;
    return $self->{_class_priors};
}

# Calculates the MDL (Minimum Description Length) clustering criterion according to
# Rissanen.  (J. Rissanen: "Modeling by Shortest Data Description," Automatica, 1978,
# and "A Universal Prior for Integers and Estimation by Minimum Description Length,"
# Annals of Statistics, 1983.)  The MDL criterion is a difference of a log-likelihood
# term for all of the observed data and a model-complexity penalty term. In general,
# both the log-likelihood and the model-complexity terms increase as the number of
# clusters increases.  The form of the MDL criterion used in the implementation below
# uses for the penalty term the Bayesian Information Criterion (BIC) of G. Schwartz,
# "Estimating the Dimensions of a Model," The Annals of Statistics, 1978.  In
# general, the smaller the value of the MDL quality measure calculated below, the
# better the clustering of the data.
sub clustering_quality_mdl {
    my $self = shift;
    # Calculate the inverses of all of the covariance matrices in order to avoid
    # having to calculate them repeatedly inside the inner 'foreach' loop in the
    # main part of this method.  Here we go:
    my @covar_inverses;
    foreach my $cluster_index (0..$self->{_K}-1) {
        my $covar = $self->{_cluster_covariances}->[$cluster_index];
        push @covar_inverses, $covar->inverse();
    }
    # For the clustering quality, first calculate the log-likelihood of all the
    # observed data:
    my $log_likelihood = 0;
    foreach my $tag (@{$self->{_data_id_tags}}) {
        my $likelihood_for_each_tag = 0;
        foreach my $cluster_index (0..$self->{_K}-1) {
            my $mean_vec = $self->{_cluster_means}->[$cluster_index];
            my $covar = $self->{_cluster_covariances}->[$cluster_index];
            my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
            $data_vec->set_col( 0, $self->{_data}->{$tag});
            my $datavec_minus_mean = $data_vec - $mean_vec;
            my $exponent = undef;
            if ($self->{_data_dimensions} > 1) {
                $exponent = -0.5 * vector_matrix_multiply( 
                                       transpose($datavec_minus_mean),
                                            matrix_vector_multiply($covar_inverses[$cluster_index], 
                                                       $datavec_minus_mean ) );
            } else {
                my @var_inverse = $covar_inverses[$cluster_index]->as_list;
                my $var_inverse_val = $var_inverse[0];
                my @data_minus_mean = $datavec_minus_mean->as_list;
                my $data_minus_mean_val = $data_minus_mean[0];
                $exponent = -0.5 * ($data_minus_mean_val ** 2) * $var_inverse_val;
            }
            next if $covar->det() < 0;
            my $coefficient = 1.0 / 
                ( (2 * $Math::GSL::Const::M_PI)**$self->{_data_dimensions} 
                                                       * sqrt($covar->det()) );
            my $prob = $coefficient * exp($exponent);
            $likelihood_for_each_tag += 
                              $prob * $self->{_class_priors}->[$cluster_index];
        }
        $log_likelihood += log( $likelihood_for_each_tag );
    }
    # Now calculate the model complexity penalty. $L is the total number of
    # parameters it takes to specify a mixture of K Gaussians. If d is the
    # dimensionality of the data space, the covariance matrix of each Gaussian takes
    # (d**2 -d)/2 + d = d(d+1)/2 parameters since this matrix must be symmetric. And
    # then you need d mean value parameters, and one prior probability parameter
    # for the Gaussian. So   $L = K[1 + d + d(d+1)/2] - 1  where the final '1' that
    # is subtracted is to account for the normalization on the class priors.
    my $L = (0.5 * $self->{_K} * 
             ($self->{_data_dimensions}**2 + 3*$self->{_data_dimensions} + 2) ) - 1;
    my $model_complexity_penalty = 0.5 * $L * log( $self->{_N} );
    my $mdl_criterion = -1 * $log_likelihood + $model_complexity_penalty;
    return $mdl_criterion;
}

# For our second measure of clustering quality, we use `trace( SW^-1 . SB)' where SW
# is the within-class scatter matrix, more commonly denoted S_w, and SB the
# between-class scatter matrix, more commonly denoted S_b (the underscore means
# subscript).  This measure can be thought of as the normalized average distance
# between the clusters, the normalization being provided by average cluster
# covariance SW^-1. Therefore, the larger the value of this quality measure, the
# better the separation between the clusters.  Since this measure has its roots in
# the Fisher linear discriminant function, we incorporate the word 'fisher' in the
# name of the quality measure.  Note that this measure is good only when the clusters
# are disjoint.  When the clusters exhibit significant overlap, the numbers produced
# by this quality measure tend to be generally meaningless.  As an extreme case,
# let's say your data was produced by a set of Gaussians, all with the same mean
# vector, but each with a distinct covariance. For this extreme case, this measure
# will produce a value close to zero --- depending on the accuracy with which the
# means are estimated --- even when your clusterer is doing a good job of identifying
# the individual clusters.
sub clustering_quality_fisher {
    my $self = shift;
    my @cluster_quality_indices;
    my $fisher_trace = 0;
    my $S_w = 
        Math::GSL::Matrix->new($self->{_data_dimensions}, $self->{_data_dimensions});
    $S_w->zero;
    my $S_b = 
        Math::GSL::Matrix->new($self->{_data_dimensions}, $self->{_data_dimensions});
    $S_b->zero;
    my $global_mean = Math::GSL::Matrix->new($self->{_data_dimensions},1);    
    $global_mean->zero;
    foreach my $cluster_index(0..$self->{_K}-1) { 
        $global_mean = $self->{_class_priors}->[$cluster_index] *
                                    $self->{_cluster_means}->[$cluster_index];
    }
    foreach my $cluster_index(0..$self->{_K}-1) {      
        $S_w +=  $self->{_cluster_covariances}->[$cluster_index] * 
                            $self->{_class_priors}->[$cluster_index];
        my $class_mean_minus_global_mean = $self->{_cluster_means}->[$cluster_index] 
                                                               - $global_mean;
        my $outer_product = outer_product( $class_mean_minus_global_mean, 
                                               $class_mean_minus_global_mean );
        $S_b +=  $self->{_class_priors}->[$cluster_index] * $outer_product;
    }
    my $fisher = matrix_multiply($S_w->inverse, $S_b);
    return $fisher unless defined blessed($fisher);
    return matrix_trace($fisher);
}

sub display_seeding_stats {
    my $self = shift;
    foreach my $cluster_index(0..$self->{_K}-1) {      
        print "\nSeeding for cluster $cluster_index:\n";
        my $mean = $self->{_cluster_means}->[$cluster_index];
        display_matrix("The mean is: ", $mean);        
        my $covariance = $self->{_cluster_covariances}->[$cluster_index];
        display_matrix("The covariance is: ", $covariance);
    }
}

sub display_fisher_quality_vs_iterations {
    my $self = shift;
    print "\n\nFisher Quality vs. Iterations: " .
                      "@{$self->{_fisher_quality_vs_iteration}}\n\n";
}

sub display_mdl_quality_vs_iterations {
    my $self = shift;
    print "\n\nMDL Quality vs. Iterations: @{$self->{_mdl_quality_vs_iteration}}\n\n";
}

sub find_prob_at_each_datapoint_for_given_mean_and_covar {
    my $self = shift;
    my $mean_vec_ref = shift;
    my $covar_ref = shift;
    foreach my $data_id (keys %{$self->{_data}}) {
        my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);        
        $data_vec->set_col( 0, $self->{_data}->{$data_id});
        if ($self->{_debug}) {
            display_matrix("data vec in find prob function", $data_vec);
            display_matrix("mean vec in find prob function", $mean_vec_ref);
            display_matrix("covariance in find prob function", $covar_ref);
        }
        my $datavec_minus_mean = $data_vec - $mean_vec_ref;
        display_matrix( "datavec minus mean is ", $datavec_minus_mean ) if $self->{_debug};
        my $exponent = undef;
        if ($self->{_data_dimensions} > 1) {
            $exponent = -0.5 * vector_matrix_multiply( transpose($datavec_minus_mean),
                matrix_vector_multiply( $covar_ref->inverse(), $datavec_minus_mean ) );
        } elsif (defined blessed($covar_ref)) {
            my @data_minus_mean = $datavec_minus_mean->as_list;
            my $data_minus_mean_val = $data_minus_mean[0];
            my @covar_as_matrix = $covar_ref->as_list;
            my $covar_val = $covar_as_matrix[0];
            $exponent = -0.5 * ($data_minus_mean_val ** 2) / $covar_val;
        } else {
            my @data_minus_mean = $datavec_minus_mean->as_list;
            my $data_minus_mean_val = $data_minus_mean[0];
            $exponent = -0.5 * ($data_minus_mean_val ** 2) / $covar_ref;
        }
        print "\nThe value of the exponent is: $exponent\n\n" if $self->{_debug};
        my $coefficient = undef;
        if ($self->{_data_dimensions} > 1) {
            $coefficient = 1.0 / sqrt( ((2 * $Math::GSL::Const::M_PI) ** $self->{_data_dimensions}) * 
                                                                                $covar_ref->det()) ;
        } elsif (!defined blessed($covar_ref)) {
            $coefficient =  1.0 / sqrt(2 * $covar_ref * $Math::GSL::Const::M_PI);
        } else {         
            my @covar_as_matrix = $covar_ref->as_list;
            my $covar_val = $covar_as_matrix[0];
            $coefficient =  1.0 / sqrt(2 * $covar_val * $Math::GSL::Const::M_PI);
        }
        my $prob = $coefficient * exp($exponent);
        push @{$self->{_class_probs_at_each_data_point}->{$data_id}}, $prob;
    }
}

sub find_expected_classes_at_each_datapoint {
    my $self = shift;
    my @priors = @{$self->{_class_priors}};
    foreach my $data_id (sort keys %{$self->{_class_probs_at_each_data_point}}) {
        my $numerator = 
          vector_2_vector_multiply( 
                           $self->{_class_probs_at_each_data_point}->{$data_id}, 
                           $self->{_class_priors} );
        my $sum = 0;
        foreach my $part (@$numerator) {
            $sum += $part;
        }
        $self->{_expected_class_probs}->{$data_id} = [map $_/$sum, @{$numerator}];
    }
}

sub initialize_class_priors {
    my $self = shift;
    if (@{$self->{_class_priors}} == 0) {
        my $prior = 1.0 / $self->{_K};
        foreach my $class_index (0..$self->{_K}-1) {
            push @{$self->{_class_priors}}, $prior;
        }
    }
    die "Mismatch between number of values for class priors " .
          "and the number of clusters expected"
        unless @{$self->{_class_priors}} == $self->{_K};
    my $sum = 0;
    foreach my $prior (@{$self->{_class_priors}}) {
        $sum += $prior;
    }
    die "Your priors in the constructor call do not add up to 1"  
                       unless abs($sum - 1) < 0.001;
    print "\nInitially assumed class priors are: @{$self->{_class_priors}}\n";
}

sub estimate_class_priors {
    my $self = shift;
    foreach my $datatag (keys %{$self->{_data}}) {
        my $class_label = $self->{_class_labels}->{$datatag};
        $self->{_class_priors}[$class_label]++;
    }
    foreach my $prior (@{$self->{_class_priors}}) {
        $prior /= $self->{_total_number_data_tuples};
    }
    foreach my $prior (@{$self->{_class_priors}}) {
        print "class priors: @{$self->{_class_priors}}\n";
    }
}    

sub classify_all_data_tuples_bayes {
    my $self = shift;
    my $mean_vecs_ref = shift;
    my $covariances_ref = shift;
    my @new_clusters;
    foreach my $index (0..$self->{_K}-1) {
        push @new_clusters, [];
    }
    foreach my $data_id (@{$self->{_data_id_tags}}) {
        my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);        
        $data_vec->set_col( 0, deep_copy_array($self->{_data}->{$data_id}));
        my $cluster_index_for_tuple = 
            $self->classify_a_data_point_bayes($data_vec, 
                                 $mean_vecs_ref, $covariances_ref); 
        $self->{_class_labels}->{$data_id} = $cluster_index_for_tuple;
        push @{$new_clusters[$cluster_index_for_tuple]}, $data_id;
    }
    $self->{_clusters} = \@new_clusters;
}

sub classify_a_data_point_bayes {
    my $self = shift;
    my $data_vec = shift;
    my $mean_vecs_ref = shift;
    my $covariances_ref = shift;
    my @cluster_mean_vecs = @$mean_vecs_ref;
    my @cluster_covariances = @$covariances_ref;
    my @log_likelihoods;        
    foreach my $cluster_index (0..@cluster_mean_vecs-1) {
        my $mean = $cluster_mean_vecs[$cluster_index];
        my $covariance =  $cluster_covariances[$cluster_index];
        my $datavec_minus_mean = $data_vec - $mean;
        my $log_likely = undef; 
        if ($self->{_data_dimensions} > 1) {
            $log_likely =   -0.5 * vector_matrix_multiply( 
                                         transpose($datavec_minus_mean), 
                                           matrix_vector_multiply( $covariance->inverse(), 
                                                     $datavec_minus_mean ) );
        } else {

            my @data_minus_mean = $datavec_minus_mean->as_list;
            my $data_minus_mean_val = $data_minus_mean[0];
            my @covar_as_matrix = $covariance->as_list;
            my $covar_val = $covar_as_matrix[0];
            $log_likely = -0.5 * ($data_minus_mean_val ** 2) / $covar_val;

        }
        my $posterior_log_likely = $log_likely + 
                       log( $self->{_class_priors}[$cluster_index] );
        push @log_likelihoods, $posterior_log_likely;
    }
    my ($minlikely, $maxlikely) = minmax(\@log_likelihoods);
    my $cluster_index_for_data_point = 
                              get_index_at_value( $maxlikely, \@log_likelihoods ); 
    return $cluster_index_for_data_point; 
}

sub find_cluster_means_and_covariances {
    my $clusters = shift;
    my $data_dimensions = find_data_dimensionality($clusters);
    my (@cluster_mean_vecs, @cluster_covariances);
    foreach my $cluster_index (0..@$clusters-1) {
        my ($num_rows,$num_cols) = 
                    ($data_dimensions,scalar(@{$clusters->[$cluster_index]}));
        print "\nFor cluster $cluster_index: rows: $num_rows   and cols: $num_cols\n";
        my $matrix = Math::GSL::Matrix->new($num_rows,$num_cols);  
        my $mean_vec = Math::GSL::Matrix->new($num_rows,1);
        my $col_index = 0;
        foreach my $ele (@{$clusters->[$cluster_index]}) {
            $matrix->set_col($col_index++, $ele);
        }
        # display_matrix( "Displaying cluster matrix", $matrix );
        foreach my $j (0..$num_cols-1) {
            $mean_vec += $matrix->col($j);
        }
        $mean_vec *=  1.0 / $num_cols;
        push @cluster_mean_vecs, $mean_vec;
        display_matrix( "Displaying the mean vector",  $mean_vec );
        foreach my $j (0..$num_cols-1) {
            my @new_col = ($matrix->col($j) - $mean_vec)->as_list;
            $matrix->set_col($j, \@new_col);
        }
        # display_matrix("Displaying mean subtracted data as a matrix",  $matrix );
        my $transposed = transpose( $matrix );
        # display_matrix("Displaying transposed matrix",$transposed);
        my $covariance = matrix_multiply( $matrix, $transposed );
        $covariance *= 1.0 / $num_cols;
        push @cluster_covariances, $covariance;
        display_matrix("Displaying the cluster covariance",  $covariance );
    }
    return (\@cluster_mean_vecs, \@cluster_covariances);
}

sub find_data_dimensionality {
    my $clusters = shift;
    my @first_cluster = @{$clusters->[0]};
    my @first_data_element = @{$first_cluster[0]};
    return scalar(@first_data_element);
}

sub find_seed_centered_covariances {
    my $self = shift;
    my $seed_tags = shift;
    my (@seed_mean_vecs, @seed_based_covariances);
    foreach my $seed_tag (@$seed_tags) {
        my ($num_rows,$num_cols) = ($self->{_data_dimensions}, $self->{_N});
        my $matrix = Math::GSL::Matrix->new($num_rows,$num_cols);  
        my $mean_vec = Math::GSL::Matrix->new($num_rows,1);
        $mean_vec->set_col(0, $self->{_data}->{$seed_tag});
        push @seed_mean_vecs, $mean_vec;
        display_matrix( "Displaying the seed mean vector",  $mean_vec );
        my $col_index = 0;
        foreach my $tag (@{$self->{_data_id_tags}}) {
            $matrix->set_col($col_index++, $self->{_data}->{$tag});
        }
        foreach my $j (0..$num_cols-1) {
            my @new_col = ($matrix->col($j) - $mean_vec)->as_list;
            $matrix->set_col($j, \@new_col);
        }
        my $transposed = transpose( $matrix );
        my $covariance = matrix_multiply( $matrix, $transposed );
        $covariance *= 1.0 / $num_cols;
        push @seed_based_covariances, $covariance;
        display_matrix("Displaying the seed covariance",  $covariance )
            if $self->{_debug};
    }
    return (\@seed_mean_vecs, \@seed_based_covariances);
}

# The most popular seeding mode for EM is random. We include two other seeding modes
# --- kmeans and manual --- since they do produce good results for specialized cases.
# For example, when the clusters in your data are non-overlapping and not too
# anisotropic, the kmeans based seeding should work at least as well as the random
# seeding.  In such cases --- AND ONLY IN SUCH CASES --- the kmeans based seeding has
# the advantage of avoiding the getting stuck in a local-maximum problem of the EM
# algorithm.
sub seed_the_clusters {
    my $self = shift;
    if ($self->{_seeding} eq 'random') {
        my @covariances;
        my @means;
        my @all_tags = @{$self->{_data_id_tags}}; 
        my @seed_tags;
        foreach my $i (0..$self->{_K}-1) {
            push @seed_tags, $all_tags[int rand( $self->{_N} )];
        }
        print "Random Seeding: Randomly selected seeding tags are  @seed_tags\n\n";
        my ($seed_means, $seed_covars) = 
                        $self->find_seed_centered_covariances(\@seed_tags);
        $self->{_cluster_means} = $seed_means;
        $self->{_cluster_covariances} = $seed_covars;
    } elsif ($self->{_seeding} eq 'kmeans') {
        $self->kmeans();
        my $clusters = $self->{_clusters};
        my @dataclusters;
        foreach my $index (0..@$clusters-1) {
            push @dataclusters, [];
        }
        foreach my $cluster_index (0..$self->{_K}-1) {
            foreach my $tag (@{$clusters->[$cluster_index]}) {
                my $data = $self->{_data}->{$tag};
                push @{$dataclusters[$cluster_index]}, deep_copy_array($data);
            }
        }
        ($self->{_cluster_means}, $self->{_cluster_covariances}) =
                           find_cluster_means_and_covariances(\@dataclusters);
    } elsif ($self->{_seeding} eq 'manual') {
        die "You have not supplied the seeding tags for the option \"manual\""
            unless @{$self->{_seed_tags}} > 0;
        print "Manual Seeding: Seed tags are @{$self->{_seed_tags}}\n\n";
        foreach my $tag (@{$self->{_seed_tags}}) {
            die "invalid tag used for manual seeding" 
                unless exists $self->{_data}->{$tag};
        }
        my ($seed_means, $seed_covars) = 
            $self->find_seed_centered_covariances($self->{_seed_tags});
        $self->{_cluster_means} = $seed_means;
        $self->{_cluster_covariances} = $seed_covars;
    } else {
        die "Incorrect call syntax used.  See documentation.";
    }
}

# This is the top-level method for kmeans based initialization of the EM
# algorithm. The means and the covariances returned by kmeans are used to seed the EM
# algorithm.
sub kmeans {
    my $self = shift;
    my $K = $self->{_K};
    $self->cluster_for_fixed_K_single_smart_try($K);
    if ((defined $self->{_clusters}) && (defined $self->{_cluster_centers})){
        return ($self->{_clusters}, $self->{_cluster_centers});
    } else {
        die "kmeans clustering failed.";
    }
}

# Used by the kmeans algorithm for the initialization of the EM iterations.  We do
# initial kmeans cluster seeding by subjecting the data to principal components
# analysis in order to discover the direction of maximum variance in the data space.
# Subsequently, we try to find the K largest peaks along this direction.  The
# coordinates of these peaks serve as the seeds for the K clusters.
sub cluster_for_fixed_K_single_smart_try {
    my $self = shift;
    my $K = shift;
    print "Clustering for K = $K\n" if $self->{_terminal_output};
    my ($clusters, $cluster_centers) =
                              $self->cluster_for_given_K($K);
    $self->{_clusters} = $clusters;
    $self->{_cluster_centers} = $cluster_centers;  
}

# Used by the kmeans part of the code for the initialization of the EM algorithm:
sub cluster_for_given_K {
    my $self = shift;
    my $K = shift;
    my $cluster_centers = $self->get_initial_cluster_centers($K);
    my $clusters = $self->assign_data_to_clusters_initial($cluster_centers);  
    my $cluster_nonexistant_flag = 0;
    foreach my $trial (0..2) {
        ($clusters, $cluster_centers) =
                         $self->assign_data_to_clusters( $clusters, $K );
        my $num_of_clusters_returned = @$clusters;
        foreach my $cluster (@$clusters) {
            $cluster_nonexistant_flag = 1 if ((!defined $cluster) 
                                             ||  (@$cluster == 0));
        }
        last unless $cluster_nonexistant_flag;
    }
    return ($clusters, $cluster_centers);
}

# Used by the kmeans part of the code for the initialization of the EM algorithm:
sub get_initial_cluster_centers {
    my $self = shift;
    my $K = shift;
    if ($self->{_data_dimensions} == 1) {
        my @one_d_data;
        foreach my $j (0..$self->{_N}-1) {
            my $tag = $self->{_data_id_tags}[$j];     
            push @one_d_data, $self->{_data}->{$tag}->[0];
        }
        my @peak_points = 
                    find_peak_points_in_given_direction(\@one_d_data,$K);
        print "highest points at data values: @peak_points\n" 
                                                         if $self->{_debug};
        my @cluster_centers;
        foreach my $peakpoint (@peak_points) {
            push @cluster_centers, [$peakpoint];
        }
        return \@cluster_centers;
    }
    my ($num_rows,$num_cols) = ($self->{_data_dimensions},$self->{_N});
    my $matrix = Math::GSL::Matrix->new($num_rows,$num_cols);
    my $mean_vec = Math::GSL::Matrix->new($num_rows,1);
    # All the record labels are stored in the array $self->{_data_id_tags}.
    # The actual data for clustering is stored in a hash at $self->{_data}
    # whose keys are the record labels; the value associated with each
    # key is the array holding the corresponding numerical multidimensional
    # data.
    foreach my $j (0..$num_cols-1) {
        my $tag = $self->{_data_id_tags}[$j];     
        my $data = $self->{_data}->{$tag};
        $matrix->set_col($j, $data);
    }
    if ($self->{_debug}) {
        print "\nDisplaying the original data as a matrix:";
        display_matrix( $matrix ); 
    }
    foreach my $j (0..$num_cols-1) {
        $mean_vec += $matrix->col($j);
    }
    $mean_vec *=  1.0 / $num_cols;
    if ($self->{_debug}) {
        print "Displaying the mean vector for the data:";
        display_matrix( $mean_vec );
    }
    foreach my $j (0..$num_cols-1) {
        my @new_col = ($matrix->col($j) - $mean_vec)->as_list;
        $matrix->set_col($j, \@new_col);
    }
    if ($self->{_debug}) {
        print "Displaying mean subtracted data as a matrix:";
        display_matrix( $matrix ); 
    }
    my $transposed = transpose( $matrix );
    if ($self->{_debug}) {
        print "Displaying transposed data matrix:";
        display_matrix( $transposed );
    }
    my $covariance = matrix_multiply( $matrix, $transposed );
    $covariance *= 1.0 / $num_cols;
    if ($self->{_debug}) {
        print "\nDisplaying the Covariance Matrix for your data:";
        display_matrix( $covariance );
    }
    my ($eigenvalues, $eigenvectors) = $covariance->eigenpair;
    my $num_of_eigens = @$eigenvalues;     
    my $largest_eigen_index = 0;
    my $smallest_eigen_index = 0;
    print "Eigenvalue 0:   $eigenvalues->[0]\n" if $self->{_debug};
    foreach my $i (1..$num_of_eigens-1) {
        $largest_eigen_index = $i if $eigenvalues->[$i] > 
                                     $eigenvalues->[$largest_eigen_index];
        $smallest_eigen_index = $i if $eigenvalues->[$i] < 
                                     $eigenvalues->[$smallest_eigen_index];
        print "Eigenvalue $i:   $eigenvalues->[$i]\n" if $self->{_debug};
    }
    print "\nlargest eigen index: $largest_eigen_index\n" if $self->{_debug};
    print "\nsmallest eigen index: $smallest_eigen_index\n\n" 
                                                          if $self->{_debug};
    foreach my $i (0..$num_of_eigens-1) {
        my @vec = $eigenvectors->[$i]->as_list;
        print "Eigenvector $i:   @vec\n" if $self->{_debug};
    }
    my @largest_eigen_vec = $eigenvectors->[$largest_eigen_index]->as_list;
    print "\nLargest eigenvector:   @largest_eigen_vec\n" if $self->{_debug};
    my @max_var_direction;
    # Each element of the array @largest_eigen_vec is a Math::Complex object
    foreach my $k (0..@largest_eigen_vec-1) {
        my ($mag, $theta) = $largest_eigen_vec[$k] =~ /\[(\d*\.\d+),(\S+)\]/;
        if ($theta eq '0') {
            $max_var_direction[$k] = $mag;
        } elsif ($theta eq 'pi') {
            $max_var_direction[$k] = -1.0 * $mag;
        } else {
            die "eigendecomposition of covariance matrix produced a complex eigenvector --- something is wrong";
        }
    }
    # "Maximum variance direction: @max_var_direction
    print "\nMaximum Variance Direction: @max_var_direction\n\n" 
                                                 if $self->{_debug};
    # We now project all data points on the largest eigenvector.
    # Each projection will yield a single point on the eigenvector.
    my @projections;
    foreach my $j (0..$self->{_N}-1) {
        my $tag = $self->{_data_id_tags}[$j];     
        my $data = $self->{_data}->{$tag};
        die "Dimensionality of the largest eigenvector does not "
            . "match the dimensionality of the data" 
          unless @max_var_direction == $self->{_data_dimensions};
        my $projection = vector_multiply($data, \@max_var_direction);
        push @projections, $projection;
    }
    print "All projection points: @projections\n" if $self->{_debug};
    my @peak_points = find_peak_points_in_given_direction(\@projections, $K);
    print "highest points at points along largest eigenvec: @peak_points\n"
                                              if $self->{_debug};
    my @cluster_centers;
    foreach my $peakpoint (@peak_points) {
        my @actual_peak_coords = map {$peakpoint * $_} @max_var_direction;
        push @cluster_centers, \@actual_peak_coords;
    }
    return \@cluster_centers;
}

# Used by the kmeans part of the code: This method is called by the previous method
# to locate K peaks in a smoothed histogram of the data points projected onto the
# maximal variance direction.
sub find_peak_points_in_given_direction {
    my $dataref = shift;
    my $how_many = shift;
    my @data = @$dataref;
    my ($min, $max) = minmax(\@data);
    my $num_points = @data;
    my @sorted_data = sort {$a <=> $b} @data;
    #print "\n\nSorted data: @sorted_data\n";
    my $scale = $max - $min;
    foreach my $index (0..$#sorted_data-1) {
        $sorted_data[$index] = ($sorted_data[$index] - $min) / $scale;
    }
    my $avg_diff = 0;
    foreach my $index (0..$#sorted_data-1) {
        my $diff = $sorted_data[$index+1] - $sorted_data[$index];
        $avg_diff += ($diff - $avg_diff) / ($index + 1);
    }
    my $delta = 1.0 / 1000.0;
    #    It would be nice to set the delta adaptively, but I must
    #    change the number of cells in the next foreach loop accordingly
    #    my $delta = $avg_diff / 20;
    my @accumulator = (0) x 1000;
    foreach my $index (0..@sorted_data-1) {
        my $cell_index = int($sorted_data[$index] / $delta);
        my $smoothness = 40;
        for my $index ($cell_index-$smoothness..$cell_index+$smoothness) {
            next if $index < 0 || $index > 999;
            $accumulator[$index]++;
        }
    }
    my $peaks_array = non_maximum_supression( \@accumulator );
    my $peaks_index_hash = get_value_index_hash( $peaks_array );
    my @K_highest_peak_locations;
    my $k = 0;
    foreach my $peak (sort {$b <=> $a} keys %$peaks_index_hash) {
        my $unscaled_peak_point = 
                  $min + $peaks_index_hash->{$peak} * $scale * $delta;
        push @K_highest_peak_locations, $unscaled_peak_point
            if $k < $how_many;
        last if ++$k == $how_many;
    }
    return @K_highest_peak_locations;
}

# Used by the kmeans part of the code: The purpose of this routine is to form initial
# clusters by assigning the data samples to the initial clusters formed by the
# previous routine on the basis of the best proximity of the data samples to the
# different cluster centers.
sub assign_data_to_clusters_initial {
    my $self = shift;
    my @cluster_centers = @{ shift @_ };
    my @clusters;
    foreach my $ele (@{$self->{_data_id_tags}}) {
        my $best_cluster;
        my @dist_from_clust_centers;
        foreach my $center (@cluster_centers) {
            push @dist_from_clust_centers, $self->distance($ele, $center);
        }
        my ($min, $best_center_index) = minimum( \@dist_from_clust_centers );
        push @{$clusters[$best_center_index]}, $ele;
    }
    return \@clusters;
}    

# Used by the kmeans part of the code: This is the main routine that along with the
# update_cluster_centers() routine constitute the two key steps of the K-Means
# algorithm.  In most cases, the infinite while() loop will terminate automatically
# when the cluster assignments of the data points remain unchanged. For the sake of
# safety, we keep track of the number of iterations. If this number reaches 100, we
# exit the while() loop anyway.  In most cases, this limit will not be reached.
sub assign_data_to_clusters {
    my $self = shift;
    my $clusters = shift;
    my $K = shift;
    my $final_cluster_centers;
    my $iteration_index = 0;
    while (1) {
        my $new_clusters;
        my $assignment_changed_flag = 0;
        my $current_cluster_center_index = 0;
        my $cluster_size_zero_condition = 0;
        my $how_many = @$clusters;
        my $cluster_centers = $self->update_cluster_centers( 
                                    deep_copy_AoA_with_nulls( $clusters ) );
        $iteration_index++;
        foreach my $cluster (@$clusters) {
            my $current_cluster_center = 
                          $cluster_centers->[$current_cluster_center_index];
            foreach my $ele (@$cluster) {
                my @dist_from_clust_centers;
                foreach my $center (@$cluster_centers) {
                    push @dist_from_clust_centers, 
                               $self->distance($ele, $center);
                }
                my ($min, $best_center_index) = 
                              minimum( \@dist_from_clust_centers );
                my $best_cluster_center = 
                                 $cluster_centers->[$best_center_index];
                if (vector_equal($current_cluster_center, 
                                         $best_cluster_center)){
                    push @{$new_clusters->[$current_cluster_center_index]}, 
                                  $ele;
                } else {
                    $assignment_changed_flag = 1;             
                    push @{$new_clusters->[$best_center_index]}, $ele;
                }
            }
            $current_cluster_center_index++;
        }
        # Now make sure that we still have K clusters since K is fixed:
        next if ((@$new_clusters != @$clusters) && ($iteration_index < 100));
        # Now make sure that none of the K clusters is an empty cluster:
        foreach my $newcluster (@$new_clusters) {
            $cluster_size_zero_condition = 1 if ((!defined $newcluster) 
                                             or  (@$newcluster == 0));
        }
        push @$new_clusters, (undef) x ($K - @$new_clusters)
                                         if @$new_clusters < $K;
        my $largest_cluster;
        foreach my $local_cluster (@$new_clusters) {
            next if !defined $local_cluster;
            $largest_cluster = $local_cluster if !defined $largest_cluster;
            if (@$local_cluster > @$largest_cluster) {
                $largest_cluster = $local_cluster; 
            }
        }        
        foreach my $local_cluster (@$new_clusters) {
            if ( (!defined $local_cluster) || (@$local_cluster == 0) ) {
                push @$local_cluster, pop @$largest_cluster;
            }
        }
        next if (($cluster_size_zero_condition) && ($iteration_index < 100));
        last if $iteration_index == 100;
        # Now do a deep copy of new_clusters into clusters
	$clusters = deep_copy_AoA( $new_clusters );
        last if $assignment_changed_flag == 0;
    }
    $final_cluster_centers = $self->update_cluster_centers( $clusters );
    return ($clusters, $final_cluster_centers);
}

# Used by the kmeans part of the code: After each new assignment of the data points
# to the clusters on the basis of the current values for the cluster centers, we call
# the routine shown here for updating the values of the cluster centers.
sub update_cluster_centers {
    my $self = shift;
    my @clusters = @{ shift @_ };
    my @new_cluster_centers;
    my $largest_cluster;
    foreach my $cluster (@clusters) {
        next if !defined $cluster;
        $largest_cluster = $cluster if !defined $largest_cluster;
        if (@$cluster > @$largest_cluster) {
            $largest_cluster = $cluster; 
        }
    }        
    foreach my $cluster (@clusters) {
        if ( (!defined $cluster) || (@$cluster == 0) ) {
            push @$cluster, pop @$largest_cluster;
        }
    }
    foreach my $cluster (@clusters) {
        die "Cluster became empty --- untenable condition " .
            "for a given K.  Try again. " if !defined $cluster;
        my $cluster_size = @$cluster;
        die "Cluster size is zero --- untenable." if $cluster_size == 0;
        my @new_cluster_center = @{$self->add_point_coords( $cluster )};
        @new_cluster_center = map {my $x = $_/$cluster_size; $x} 
                                  @new_cluster_center;
        push @new_cluster_centers, \@new_cluster_center;
    }        
    return \@new_cluster_centers;
}

# The following routine is for computing the distance between a data point specified
# by its symbolic name in the master datafile and a point (such as the center of a
# cluster) expressed as a vector of coordinates:
sub distance {
    my $self = shift;
    my $ele1_id = shift @_;            # symbolic name of data sample
    my @ele1 = @{$self->{_data}->{$ele1_id}};
    my @ele2 = @{shift @_};
    die "wrong data types for distance calculation" if @ele1 != @ele2;
    my $how_many = @ele1;
    my $squared_sum = 0;
    foreach my $i (0..$how_many-1) {
        $squared_sum += ($ele1[$i] - $ele2[$i])**2;
    }    
    my $dist = sqrt $squared_sum;
    return $dist;
}

# The following routine does the same as above but now both
# arguments are expected to be arrays of numbers:
sub distance2 {
    my $self = shift;
    my @ele1 = @{shift @_};
    my @ele2 = @{shift @_};
    die "wrong data types for distance calculation" if @ele1 != @ele2;
    my $how_many = @ele1;
    my $squared_sum = 0;
    foreach my $i (0..$how_many-1) {
        $squared_sum += ($ele1[$i] - $ele2[$i])**2;
    }    
    return sqrt $squared_sum;
}

sub write_naive_bayes_clusters_to_files {
    my $self = shift;
    my @clusters = @{$self->{_clusters}};
    unlink glob "naive_bayes_cluster*.txt";
    foreach my $i (1..@clusters) {
        my $filename = "naive_bayes_cluster" . $i . ".txt";
        print "Writing cluster $i to file $filename\n"
                            if $self->{_terminal_output};
        open FILEHANDLE, "| sort > $filename" or die "Unable to open file: $!";
        foreach my $ele (@{$clusters[$i-1]}) {        
            print FILEHANDLE "$ele\n";
        }
        close FILEHANDLE;
    }
}

sub write_posterior_prob_clusters_above_threshold_to_files {
    my $self = shift;
    my $theta = shift;
    my @class_distributions;
    foreach my $cluster_index (0..$self->{_K}-1) {
        push @class_distributions, [];
    }
    foreach my $data_tag (@{$self->{_data_id_tags}}) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            push @{$class_distributions[$cluster_index]}, $data_tag
                if $self->{_expected_class_probs}->{$data_tag}->[$cluster_index] 
                                            > $theta;
        }
    }
    unlink glob "posterior_prob_cluster*.txt";
    foreach my $i (1..@class_distributions) {
        my $filename = "posterior_prob_cluster" . $i . ".txt";
        print "Writing posterior prob cluster $i to file $filename\n"
                            if $self->{_terminal_output};
        open FILEHANDLE, "| sort > $filename" or die "Unable to open file: $!";
        foreach my $ele (@{$class_distributions[$i-1]}) {        
            print FILEHANDLE "$ele\n";
        }
        close FILEHANDLE;
    }
}

sub DESTROY {
    unlink "__temp_" . basename($_[0]->{_datafile});
    unlink "__temp_data_" . basename($_[0]->{_datafile});
    unlink "__temp2_" . basename($_[0]->{_datafile});
    unlink glob "__temp1dhist*";
    unlink glob "__contour*";
}

#############################  Visualization Code ###############################

#  The visualize_clusters() implementation displays as a plot in your terminal window
#  the clusters constructed by the EM algorithm.  It can show either 2D plots or
#  3D plots that you can rotate interactively for better visualization.  For
#  multidimensional data, as to which 2D or 3D dimensions are used for visualization
#  is controlled by the mask you must supply as an argument to the method.  Should it
#  happen that only one on bit is specified for the mask, visualize_clusters()
#  aborts.
#
#  The visualization code consists of first accessing each of clusters created by the
#  EM() subroutine.  Note that the clusters contain only the symbolic names for the
#  individual records in the source data file.  We therefore next reach into the
#  $self->{_data} hash and get the data coordinates associated with each symbolic
#  label in a cluster.  The numerical data thus generated is then written out to a
#  temp file.  When doing so we must remember to insert TWO BLANK LINES between the
#  data blocks corresponding to the different clusters.  This constraint is imposed
#  on us by Gnuplot when plotting data from the same file since we want to use
#  different point styles for the data points in different cluster files.
#  Subsequently, we call upon the Perl interface provided by the Graphics::GnuplotIF
#  module to plot the data clusters.
sub visualize_clusters {
    my $self = shift;
    my $v_mask;
    my $pause_time;
    if (@_ == 1) {
        $v_mask = shift || die "visualization mask missing";
    } elsif (@_ == 2) {
        $v_mask = shift || die "visualization mask missing";    
        $pause_time = shift;
    } else {
        die "visualize_clusters() called with wrong args";
    }
    my $master_datafile = $self->{_datafile};
    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    die "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    # The following section is for the superimposed one-Mahalanobis-distance-unit 
    # ellipses that are shown only for 2D plots:
    if ($visualization_data_field_width == 2) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            my $contour_filename = "__contour_" . $cluster_index . ".dat";
            my $mean = $self->{_cluster_means}->[$cluster_index];
            my $covariance = $self->{_cluster_covariances}->[$cluster_index];
            my ($mux,$muy) = $mean->as_list();
            my ($varx,$sigmaxy) = $covariance->row(0)->as_list();
            my ($sigmayx,$vary) = $covariance->row(1)->as_list();
            die "Your covariance matrix does not look right" 
                unless $sigmaxy == $sigmayx;
            my ($sigmax,$sigmay) = (sqrt($varx),sqrt($vary));
my $argstring = <<"END";
set contour
mux = $mux
muy = $muy
sigmax = $sigmax
sigmay = $sigmay
sigmaxy = $sigmaxy
determinant = (sigmax**2)*(sigmay**2) - sigmaxy**2 
exponent(x,y)  = -0.5 * (1.0 / determinant) * ( ((x-mux)**2)*sigmay**2 + ((y-muy)**2)*sigmax**2 - 2*sigmaxy*(x-mux)*(y-muy) )
f(x,y) = exp( exponent(x,y) ) - 0.2
xmax = mux + 2 * sigmax
xmin = mux - 2 * sigmax
ymax = muy + 2 * sigmay
ymin = muy - 2 * sigmay
set xrange [ xmin : xmax ]
set yrange [ ymin : ymax ]
set isosamples 200
unset surface
set cntrparam levels discrete 0
set table \"$contour_filename\"
splot f(x,y)
unset table
END
            my $plot = Graphics::GnuplotIF->new();
            $plot->gnuplot_cmd( $argstring );
        }
    }
    my %visualization_data;
    while ( my ($record_id, $data) = each %{$self->{_data}} ) {
        my @fields = @$data;
        die "\nABORTED: Visualization mask size exceeds data record size" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "Misformed visualization mask. It can only have 1s and 0s";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my $K = scalar @{$self->{_clusters}};
    my $filename = basename($master_datafile);
    my $temp_file = "__temp_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    foreach my $cluster (@{$self->{_clusters}}) {
        foreach my $item (@$cluster) {
            print OUTPUT "@{$visualization_data{$item}}";
            print OUTPUT "\n";
        }
        print OUTPUT "\n\n";
    }
    close OUTPUT;
    my $plot;
    if (!defined $pause_time) {
        $plot = Graphics::GnuplotIF->new( persist => 1 );
    } else {
        $plot = Graphics::GnuplotIF->new();
    }
    my $arg_string = "";
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd("set noclip");
        $plot->gnuplot_cmd("set pointsize 2");
        foreach my $i (0..$K-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"Cluster (naive Bayes) $i\" with points lt $j pt $j, ";
        }
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd("set noclip");
        $plot->gnuplot_cmd("set pointsize 2");
        foreach my $i (0..$K-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2 title \"Cluster (naive Bayes) $i\" with points lt $j pt $j, ";
            my $ellipse_filename = "__contour_" . $i . ".dat";
            $arg_string .= "\"$ellipse_filename\" with line lt $j title \"\", ";
        }
    } elsif ($visualization_data_field_width == 1 ) {
        open INPUT, "$temp_file" or die "Unable to open a temp file in this directory: $!";
        my @all_data = <INPUT>;
        close INPUT;
        @all_data = map {chomp $_; $_ =~ /\d/ ? $_ : "SEPERATOR" } @all_data;
        my $all_joined_data = join ':', @all_data;
        my @separated = split /:SEPERATOR:SEPERATOR/, $all_joined_data;
        my (@all_clusters_for_hist, @all_minvals, @all_maxvals, @all_minmaxvals);
        foreach my $i (0..@separated-1) {
            $separated[$i] =~ s/SEPERATOR//g;
            my @cluster_for_hist = split /:/, $separated[$i];
            @cluster_for_hist = grep $_, @cluster_for_hist;
            my ($minval,$maxval) = minmax(\@cluster_for_hist);
            push @all_minvals, $minval;
            push @all_maxvals, $maxval;
            push @all_clusters_for_hist, \@cluster_for_hist;
        }
        push @all_minmaxvals, @all_minvals;
        push @all_minmaxvals, @all_maxvals;
        my ($abs_minval,$abs_maxval) = minmax(\@all_minmaxvals);
        my $delta = ($abs_maxval - $abs_minval) / 100.0;
        $plot->gnuplot_cmd("set boxwidth 3");
        $plot->gnuplot_cmd("set style fill solid border -1");
        $plot->gnuplot_cmd("set ytics out nomirror");
        $plot->gnuplot_cmd("set style data histograms");
        $plot->gnuplot_cmd("set style histogram clustered");
        $plot->gnuplot_cmd("set title 'Clusters shown through histograms'");
        $plot->gnuplot_cmd("set xtics rotate by 90 offset 0,-5 out nomirror");
        foreach my $cindex (0..@all_clusters_for_hist-1) {
            my $filename = basename($master_datafile);
            my $temp_file = "__temp1dhist_" . "$cindex" . "_" .  $filename;
            unlink $temp_file if -e $temp_file;
            open OUTPUT, ">$temp_file" or die "Unable to open a temp file in this directory: $!";
            print OUTPUT "Xstep histval\n";
            my @histogram = (0) x 100;
            foreach my $i (0..@{$all_clusters_for_hist[$cindex]}-1) {
                $histogram[int( ($all_clusters_for_hist[$cindex][$i] - $abs_minval) / $delta )]++;
            }
            foreach my $i (0..@histogram-1) {
                print OUTPUT "$i $histogram[$i]\n";        
            }
            $arg_string .= "\"$temp_file\" using 2:xtic(1) ti col smooth frequency with boxes lc $cindex, ";
            close OUTPUT;
        }
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "splot $arg_string" );
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "plot $arg_string" );
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    } elsif ($visualization_data_field_width == 1) {
        $plot->gnuplot_cmd( "plot $arg_string" );
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    }
}

# This subroutine is the same as above except that it makes PNG plots (for hardcopy
# printing) of the clusters.
sub plot_hardcopy_clusters {
    my $self = shift;
    my $v_mask;
    my $pause_time;
    if (@_ == 1) {
        $v_mask = shift || die "visualization mask missing";
    } elsif (@_ == 2) {
        $v_mask = shift || die "visualization mask missing";    
        $pause_time = shift;
    } else {
        die "visualize_clusters() called with wrong args";
    }
    my $master_datafile = $self->{_datafile};
    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    die "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    if ($visualization_data_field_width == 2) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            my $contour_filename = "__contour_" . $cluster_index . ".dat";
            my $mean = $self->{_cluster_means}->[$cluster_index];
            my $covariance = $self->{_cluster_covariances}->[$cluster_index];
            my ($mux,$muy) = $mean->as_list();
            my ($varx,$sigmaxy) = $covariance->row(0)->as_list();
            my ($sigmayx,$vary) = $covariance->row(1)->as_list();
            die "Your covariance matrix does not look right" 
                unless $sigmaxy == $sigmayx;
            my ($sigmax,$sigmay) = (sqrt($varx),sqrt($vary));
my $argstring = <<"END";
set contour
mux = $mux
muy = $muy
sigmax = $sigmax
sigmay = $sigmay
sigmaxy = $sigmaxy
determinant = (sigmax**2)*(sigmay**2) - sigmaxy**2 
exponent(x,y)  = -0.5 * (1.0 / determinant) * ( ((x-mux)**2)*sigmay**2 + ((y-muy)**2)*sigmax**2 - 2*sigmaxy*(x-mux)*(y-muy) )
f(x,y) = exp( exponent(x,y) ) - 0.2
xmax = mux + 2 * sigmax
xmin = mux - 2 * sigmax
ymax = muy + 2 * sigmay
ymin = muy - 2 * sigmay
set xrange [ xmin : xmax ]
set yrange [ ymin : ymax ]
set isosamples 200
unset surface
set cntrparam levels discrete 0
set table \"$contour_filename\"
splot f(x,y)
unset table
END
            my $plot = Graphics::GnuplotIF->new();
            $plot->gnuplot_cmd( $argstring );
        }
    }
    my %visualization_data;
    while ( my ($record_id, $data) = each %{$self->{_data}} ) {
        my @fields = @$data;
        die "\nABORTED: Visualization mask size exceeds data record size" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "Misformed visualization mask. It can only have 1s and 0s";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my $K = scalar @{$self->{_clusters}};
    my $filename = basename($master_datafile);
    my $temp_file = "__temp_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    foreach my $cluster (@{$self->{_clusters}}) {
        foreach my $item (@$cluster) {
            print OUTPUT "@{$visualization_data{$item}}";
            print OUTPUT "\n";
        }
        print OUTPUT "\n\n";
    }
    close OUTPUT;
    my $plot;
    if (!defined $pause_time) {
        $plot = Graphics::GnuplotIF->new( persist => 1 );
    } else {
        $plot = Graphics::GnuplotIF->new();
    }
    my $arg_string = "";
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "set noclip" );
        $plot->gnuplot_cmd( "set pointsize 2" );
        foreach my $i (0..$K-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"Cluster (naive Bayes) $i\" with points lt $j pt $j, ";
        }
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "set noclip" );
        $plot->gnuplot_cmd( "set pointsize 2" );
        foreach my $i (0..$K-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2 title \"Cluster (naive Bayes) $i\" with points lt $j pt $j, ";
            my $ellipse_filename = "__contour_" . $i . ".dat";
            $arg_string .= "\"$ellipse_filename\" with line lt $j title \"\", ";
        }
    } elsif ($visualization_data_field_width == 1 ) {
        open INPUT, "$temp_file" or die "Unable to open a temp file in this directory: $!";
        my @all_data = <INPUT>;
        close INPUT;
        @all_data = map {chomp $_; $_ =~ /\d/ ? $_ : "SEPERATOR" } @all_data;
        my $all_joined_data = join ':', @all_data;
        my @separated = split /:SEPERATOR:SEPERATOR/, $all_joined_data;
        my (@all_clusters_for_hist, @all_minvals, @all_maxvals, @all_minmaxvals);
        foreach my $i (0..@separated-1) {
            $separated[$i] =~ s/SEPERATOR//g;
            my @cluster_for_hist = split /:/, $separated[$i];
            @cluster_for_hist = grep $_, @cluster_for_hist;
            my ($minval,$maxval) = minmax(\@cluster_for_hist);
            push @all_minvals, $minval;
            push @all_maxvals, $maxval;
            push @all_clusters_for_hist, \@cluster_for_hist;
        }
        push @all_minmaxvals, @all_minvals;
        push @all_minmaxvals, @all_maxvals;
        my ($abs_minval,$abs_maxval) = minmax(\@all_minmaxvals);
        my $delta = ($abs_maxval - $abs_minval) / 100.0;
        $plot->gnuplot_cmd("set boxwidth 3");
        $plot->gnuplot_cmd("set style fill solid border -1");
        $plot->gnuplot_cmd("set ytics out nomirror");
        $plot->gnuplot_cmd("set style data histograms");
        $plot->gnuplot_cmd("set style histogram clustered");
        $plot->gnuplot_cmd("set title 'Clusters shown through histograms'");
        $plot->gnuplot_cmd("set xtics rotate by 90 offset 0,-5 out nomirror");
        foreach my $cindex (0..@all_clusters_for_hist-1) {
            my $filename = basename($master_datafile);
            my $temp_file = "__temp1dhist_" . "$cindex" . "_" .  $filename;
            unlink $temp_file if -e $temp_file;
            open OUTPUT, ">$temp_file" or die "Unable to open a temp file in this directory: $!";
            print OUTPUT "Xstep histval\n";
            my @histogram = (0) x 100;
            foreach my $i (0..@{$all_clusters_for_hist[$cindex]}-1) {
                $histogram[int( ($all_clusters_for_hist[$cindex][$i] - $abs_minval) / $delta )]++;
            }
            foreach my $i (0..@histogram-1) {
                print OUTPUT "$i $histogram[$i]\n";        
            }
#            $arg_string .= "\"$temp_file\" using 1:2 ti col smooth frequency with boxes lc $cindex, ";
            $arg_string .= "\"$temp_file\" using 2:xtic(1) ti col smooth frequency with boxes lc $cindex, ";
            close OUTPUT;
        }
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( 'set terminal png color',
                            'set output "cluster_plot.png"');
        $plot->gnuplot_cmd( "splot $arg_string" );
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd('set terminal png',
                           'set output "cluster_plot.png"');
        $plot->gnuplot_cmd( "plot $arg_string" );
    } elsif ($visualization_data_field_width == 1) {
        $plot->gnuplot_cmd('set terminal png',
                           'set output "cluster_plot.png"');
        $plot->gnuplot_cmd( "plot $arg_string" );
    }
}

# This method is for the visualization of the posterior class distributions.  In
# other words, this method allows us to see the soft clustering produced by the EM
# algorithm.  While much of the gnuplot logic here is the same as in the
# visualize_clusters() method, there are significant differences in how the data is
# pooled for the purpose of display.
sub visualize_distributions {
    my $self = shift;
    my $v_mask;
    my $pause_time;
    if (@_ == 1) {
        $v_mask = shift || die "visualization mask missing";
    } elsif (@_ == 2) {
        $v_mask = shift || die "visualization mask missing";    
        $pause_time = shift;
    } else {
        die "visualize_distributions() called with wrong args";
    }
    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    die "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    if ($visualization_data_field_width == 2) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            my $contour_filename = "__contour2_" . $cluster_index . ".dat";
            my $mean = $self->{_cluster_means}->[$cluster_index];
            my $covariance = $self->{_cluster_covariances}->[$cluster_index];
            my ($mux,$muy) = $mean->as_list();
            my ($varx,$sigmaxy) = $covariance->row(0)->as_list();
            my ($sigmayx,$vary) = $covariance->row(1)->as_list();
            die "Your covariance matrix does not look right" 
                unless $sigmaxy == $sigmayx;
            my ($sigmax,$sigmay) = (sqrt($varx),sqrt($vary));
my $argstring = <<"END";
set contour
mux = $mux
muy = $muy
sigmax = $sigmax
sigmay = $sigmay
sigmaxy = $sigmaxy
determinant = (sigmax**2)*(sigmay**2) - sigmaxy**2 
exponent(x,y)  = -0.5 * (1.0 / determinant) * ( ((x-mux)**2)*sigmay**2 + ((y-muy)**2)*sigmax**2 - 2*sigmaxy*(x-mux)*(y-muy) )
f(x,y) = exp( exponent(x,y) ) - 0.2
xmax = mux + 2 * sigmax
xmin = mux - 2 * sigmax
ymax = muy + 2 * sigmay
ymin = muy - 2 * sigmay
set xrange [ xmin : xmax ]
set yrange [ ymin : ymax ]
set isosamples 200
unset surface
set cntrparam levels discrete 0
set table \"$contour_filename\"
splot f(x,y)
unset table
END
            my $plot = Graphics::GnuplotIF->new();
            $plot->gnuplot_cmd( $argstring );
         }
    }
    my %visualization_data;
    while ( my ($record_id, $data) = each %{$self->{_data}} ) {
        my @fields = @$data;
        die "\nABORTED: Visualization mask size exceeds data record size" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "Misformed visualization mask. It can only have 1s and 0s";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my $filename = basename($self->{_datafile});
    my $temp_file = "__temp2_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    my @class_distributions;
    foreach my $cluster_index (0..$self->{_K}-1) {
        push @class_distributions, [];
    }
    foreach my $data_tag (@{$self->{_data_id_tags}}) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            push @{$class_distributions[$cluster_index]}, $self->{_data}->{$data_tag}
                if $self->{_expected_class_probs}->{$data_tag}->[$cluster_index] > 0.2;
        }
    }
    foreach my $distribution (@class_distributions) {
        foreach my $item (@$distribution) {
            print OUTPUT "@$item";
            print OUTPUT "\n";
        }
        print OUTPUT "\n\n";
    }
    close OUTPUT;
    my $plot;
    if (!defined $pause_time) {
        $plot = Graphics::GnuplotIF->new( persist => 1 );
    } else {
        $plot = Graphics::GnuplotIF->new();
    }
    my $arg_string = "";
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "set noclip" );
        $plot->gnuplot_cmd( "set pointsize 2" );
        foreach my $i (0..$self->{_K}-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"Cluster $i (based on posterior probs)\" with points lt $j pt $j, ";
        }
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "set noclip" );
        $plot->gnuplot_cmd( "set pointsize 2" );
        foreach my $i (0..$self->{_K}-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2 title \"Cluster $i (based on posterior probs)\" with points lt $j pt $j, ";
            my $ellipse_filename = "__contour2_" . $i . ".dat";
            $arg_string .= "\"$ellipse_filename\" with line lt $j title \"\", ";
        }
    } elsif ($visualization_data_field_width == 1 ) {
        open INPUT, "$temp_file" or die "Unable to open a temp file in this directory: $!";
        my @all_data = <INPUT>;
        close INPUT;
        @all_data = map {chomp $_; $_ =~ /\d/ ? $_ : "SEPERATOR" } @all_data;
        my $all_joined_data = join ':', @all_data;
        my @separated = split /:SEPERATOR:SEPERATOR/, $all_joined_data;
        my (@all_clusters_for_hist, @all_minvals, @all_maxvals, @all_minmaxvals);
        foreach my $i (0..@separated-1) {
            $separated[$i] =~ s/SEPERATOR//g;
            my @cluster_for_hist = split /:/, $separated[$i];
            @cluster_for_hist = grep $_, @cluster_for_hist;
            my ($minval,$maxval) = minmax(\@cluster_for_hist);
            push @all_minvals, $minval;
            push @all_maxvals, $maxval;
            push @all_clusters_for_hist, \@cluster_for_hist;
        }
        push @all_minmaxvals, @all_minvals;
        push @all_minmaxvals, @all_maxvals;
        my ($abs_minval,$abs_maxval) = minmax(\@all_minmaxvals);
        my $delta = ($abs_maxval - $abs_minval) / 100.0;
        $plot->gnuplot_cmd("set boxwidth 3");
        $plot->gnuplot_cmd("set style fill solid border -1");
        $plot->gnuplot_cmd("set ytics out nomirror");
        $plot->gnuplot_cmd("set style data histograms");
        $plot->gnuplot_cmd("set style histogram clustered");
        $plot->gnuplot_cmd("set title 'Individual distributions shown through histograms'");
        $plot->gnuplot_cmd("set xtics rotate by 90 offset 0,-5 out nomirror");
        foreach my $cindex (0..@all_clusters_for_hist-1) {
            my $localfilename = basename($filename);
            my $temp_file = "__temp1dhist_" . "$cindex" . "_" .  $localfilename;
            unlink $temp_file if -e $temp_file;
            open OUTPUT, ">$temp_file" or die "Unable to open a temp file in this directory: $!";
            print OUTPUT "Xstep histval\n";

            my @histogram = (0) x 100;
            foreach my $i (0..@{$all_clusters_for_hist[$cindex]}-1) {
                $histogram[int( ($all_clusters_for_hist[$cindex][$i] - $abs_minval) / $delta )]++;
            }
            foreach my $i (0..@histogram-1) {
                print OUTPUT "$i $histogram[$i]\n";        
            }
#            $arg_string .= "\"$temp_file\" using 1:2 ti col smooth frequency with boxes lc $cindex, ";
            $arg_string .= "\"$temp_file\" using 2:xtic(1) ti col smooth frequency with boxes lc $cindex, ";
            close OUTPUT;
        }
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "splot $arg_string" );
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "plot $arg_string" );
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    } elsif ($visualization_data_field_width == 1) {
        $plot->gnuplot_cmd( "plot $arg_string" );
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    }
}

# This method is basically the same as the previous method, except that it is
# intended for making PNG files from the distributions.
sub plot_hardcopy_distributions {
    my $self = shift;
    my $v_mask;
    my $pause_time;
    if (@_ == 1) {
        $v_mask = shift || die "visualization mask missing";
    } elsif (@_ == 2) {
        $v_mask = shift || die "visualization mask missing";    
        $pause_time = shift;
    } else {
        die "visualize_distributions() called with wrong args";
    }
    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    die "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    if ($visualization_data_field_width == 2) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            my $contour_filename = "__contour2_" . $cluster_index . ".dat";
            my $mean = $self->{_cluster_means}->[$cluster_index];
            my $covariance = $self->{_cluster_covariances}->[$cluster_index];
            my ($mux,$muy) = $mean->as_list();
            my ($varx,$sigmaxy) = $covariance->row(0)->as_list();
            my ($sigmayx,$vary) = $covariance->row(1)->as_list();
            die "Your covariance matrix does not look right" 
                unless $sigmaxy == $sigmayx;
            my ($sigmax,$sigmay) = (sqrt($varx),sqrt($vary));
my $argstring = <<"END";
set contour
mux = $mux
muy = $muy
sigmax = $sigmax
sigmay = $sigmay
sigmaxy = $sigmaxy
determinant = (sigmax**2)*(sigmay**2) - sigmaxy**2 
exponent(x,y)  = -0.5 * (1.0 / determinant) * ( ((x-mux)**2)*sigmay**2 + ((y-muy)**2)*sigmax**2 - 2*sigmaxy*(x-mux)*(y-muy) )
f(x,y) = exp( exponent(x,y) ) - 0.2
xmax = mux + 2 * sigmax
xmin = mux - 2 * sigmax
ymax = muy + 2 * sigmay
ymin = muy - 2 * sigmay
set xrange [ xmin : xmax ]
set yrange [ ymin : ymax ]
set isosamples 200
unset surface
set cntrparam levels discrete 0
set table \"$contour_filename\"
splot f(x,y)
unset table
END
            my $plot = Graphics::GnuplotIF->new();
            $plot->gnuplot_cmd( $argstring );
         }
    }
    my %visualization_data;
    while ( my ($record_id, $data) = each %{$self->{_data}} ) {
        my @fields = @$data;
        die "\nABORTED: Visualization mask size exceeds data record size" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "Misformed visualization mask. It can only have 1s and 0s";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my $filename = basename($self->{_datafile});
    my $temp_file = "__temp2_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    my @class_distributions;
    foreach my $cluster_index (0..$self->{_K}-1) {
        push @class_distributions, [];
    }
    foreach my $data_tag (@{$self->{_data_id_tags}}) {
        foreach my $cluster_index (0..$self->{_K}-1) {
            push @{$class_distributions[$cluster_index]}, $self->{_data}->{$data_tag}
                if $self->{_expected_class_probs}->{$data_tag}->[$cluster_index] > 0.2;
        }
    }
    foreach my $distribution (@class_distributions) {
        foreach my $item (@$distribution) {
            print OUTPUT "@$item";
            print OUTPUT "\n";
        }
        print OUTPUT "\n\n";
    }
    close OUTPUT;
    my $plot;
    if (!defined $pause_time) {
        $plot = Graphics::GnuplotIF->new( persist => 1 );
    } else {
        $plot = Graphics::GnuplotIF->new();
    }
    my $arg_string = "";
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "set noclip" );
        $plot->gnuplot_cmd( "set pointsize 2" );
        foreach my $i (0..$self->{_K}-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"Cluster $i (based on posterior probs)\" with points lt $j pt $j, ";
        }
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "set noclip" );
        $plot->gnuplot_cmd( "set pointsize 2" );
        foreach my $i (0..$self->{_K}-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2 title \"Cluster $i (based on posterior probs)\" with points lt $j pt $j, ";
            my $ellipse_filename = "__contour2_" . $i . ".dat";
            $arg_string .= "\"$ellipse_filename\" with line lt $j title \"\", ";
        }
    } elsif ($visualization_data_field_width == 1 ) {
        open INPUT, "$temp_file" or die "Unable to open a temp file in this directory: $!";
        my @all_data = <INPUT>;
        close INPUT;
        @all_data = map {chomp $_; $_ =~ /\d/ ? $_ : "SEPERATOR" } @all_data;
        my $all_joined_data = join ':', @all_data;
        my @separated = split /:SEPERATOR:SEPERATOR/, $all_joined_data;
        my (@all_clusters_for_hist, @all_minvals, @all_maxvals, @all_minmaxvals);
        foreach my $i (0..@separated-1) {
            $separated[$i] =~ s/SEPERATOR//g;
            my @cluster_for_hist = split /:/, $separated[$i];
            @cluster_for_hist = grep $_, @cluster_for_hist;
            my ($minval,$maxval) = minmax(\@cluster_for_hist);
            push @all_minvals, $minval;
            push @all_maxvals, $maxval;
            push @all_clusters_for_hist, \@cluster_for_hist;
        }
        push @all_minmaxvals, @all_minvals;
        push @all_minmaxvals, @all_maxvals;
        my ($abs_minval,$abs_maxval) = minmax(\@all_minmaxvals);
        my $delta = ($abs_maxval - $abs_minval) / 100.0;
        $plot->gnuplot_cmd("set boxwidth 3");
        $plot->gnuplot_cmd("set style fill solid border -1");
        $plot->gnuplot_cmd("set ytics out nomirror");
        $plot->gnuplot_cmd("set style data histograms");
        $plot->gnuplot_cmd("set style histogram clustered");
        $plot->gnuplot_cmd("set title 'Individual distributions shown through histograms'");
        $plot->gnuplot_cmd("set xtics rotate by 90 offset 0,-5 out nomirror");
        foreach my $cindex (0..@all_clusters_for_hist-1) {
            my $localfilename = basename($filename);
            my $temp_file = "__temp1dhist_" . "$cindex" . "_" .  $localfilename;
            unlink $temp_file if -e $temp_file;
            open OUTPUT, ">$temp_file" or die "Unable to open a temp file in this directory: $!";
            print OUTPUT "Xstep histval\n";

            my @histogram = (0) x 100;
            foreach my $i (0..@{$all_clusters_for_hist[$cindex]}-1) {
                $histogram[int( ($all_clusters_for_hist[$cindex][$i] - $abs_minval) / $delta )]++;
            }
            foreach my $i (0..@histogram-1) {
                print OUTPUT "$i $histogram[$i]\n";        
            }
            $arg_string .= "\"$temp_file\" using 2:xtic(1) ti col smooth frequency with boxes lc $cindex, ";
            close OUTPUT;
        }
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;

    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( 'set terminal png',
                            'set output "posterior_prob_plot.png"');
        $plot->gnuplot_cmd( "splot $arg_string" );
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( 'set terminal png',
                            'set output "posterior_prob_plot.png"');
        $plot->gnuplot_cmd( "plot $arg_string" );
    } elsif ($visualization_data_field_width == 1) {
        $plot->gnuplot_cmd( 'set terminal png',
                            'set output "posterior_prob_plot.png"');
        $plot->gnuplot_cmd( "plot $arg_string" );
    }
}

#  The method shown below should be called only AFTER you have called the method
#  read_data_from_file().  The visualize_data() is meant for the visualization of the
#  original data in its various 2D or 3D subspaces.
sub visualize_data {
    my $self = shift;
    my $v_mask = shift || die "visualization mask missing";

    my $master_datafile = $self->{_datafile};

    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    die "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    my %visualization_data;
    my $data_source = $self->{_data};
    while ( my ($record_id, $data) = each %{$data_source} ) {
        my @fields = @$data;
        die "\nABORTED: Visualization mask size exceeds data record size" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "Misformed visualization mask. It can only have 1s and 0s";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my $filename = basename($master_datafile);
    my $temp_file;
    $temp_file = "__temp_data_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    foreach my $datapoint (values %visualization_data) {
        print OUTPUT "@$datapoint";
        print OUTPUT "\n";
    }
    close OUTPUT;
    my $plot = Graphics::GnuplotIF->new( persist => 1 );
    $plot->gnuplot_cmd( "set noclip" );
    $plot->gnuplot_cmd( "set pointsize 2" );
    my $plot_title =  '"original data provided for EM"';
    my $arg_string ;
    if ($visualization_data_field_width > 2) {
        $arg_string = "\"$temp_file\" using 1:2:3 title $plot_title with points lt -1 pt 1";
    } elsif ($visualization_data_field_width == 2) {
        $arg_string = "\"$temp_file\" using 1:2 title $plot_title with points lt -1 pt 1";
    } elsif ($visualization_data_field_width == 1 ) {
        open INPUT, "$temp_file" or die "Unable to open a temp file in this directory: $!";
        my @all_data = <INPUT>;
        close INPUT;
        @all_data = map {chomp $_; $_} @all_data;
        @all_data = grep $_, @all_data;
        my ($minval,$maxval) = minmax(\@all_data);
        my $delta = ($maxval - $minval) / 100.0;
        $plot->gnuplot_cmd("set boxwidth 3");
        $plot->gnuplot_cmd("set style fill solid border -1");
        $plot->gnuplot_cmd("set ytics out nomirror");
        $plot->gnuplot_cmd("set style data histograms");
        $plot->gnuplot_cmd("set style histogram clustered");
        $plot->gnuplot_cmd("set title 'Overall distribution of 1D data'");
        $plot->gnuplot_cmd("set xtics rotate by 90 offset 0,-5 out nomirror");
        my $localfilename = basename($filename);
        my $temp_file = "__temp1dhist_" .  $localfilename;
        unlink $temp_file if -e $temp_file;
        open OUTPUT, ">$temp_file" or die "Unable to open a temp file in this directory: $!";
        print OUTPUT "Xstep histval\n";
        my @histogram = (0) x 100;
        foreach my $i (0..@all_data-1) {
            $histogram[int( ($all_data[$i] - $minval) / $delta )]++;
        }
        foreach my $i (0..@histogram-1) {
            print OUTPUT "$i $histogram[$i]\n";        
        }
        $arg_string = "\"$temp_file\" using 2:xtic(1) ti col smooth frequency with boxes lc rgb 'green'";
        close OUTPUT;
    }
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "splot $arg_string" );
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "plot $arg_string" );
    } elsif ($visualization_data_field_width == 1) {
        $plot->gnuplot_cmd( "plot $arg_string" );
    }
}

# This method is the same as the one shown above, except that it is meant for
# creating PNG files of the displays.
sub plot_hardcopy_data {
    my $self = shift;
    my $v_mask = shift || die "visualization mask missing";
    my $master_datafile = $self->{_datafile};
    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    die "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    my %visualization_data;
    my $data_source = $self->{_data};
    while ( my ($record_id, $data) = each %{$data_source} ) {
        my @fields = @$data;
        die "\nABORTED: Visualization mask size exceeds data record size" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "Misformed visualization mask. It can only have 1s and 0s";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my $filename = basename($master_datafile);
    my $temp_file;
    $temp_file = "__temp_data_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    foreach my $datapoint (values %visualization_data) {
        print OUTPUT "@$datapoint";
        print OUTPUT "\n";
    }
    close OUTPUT;

    my $plot = Graphics::GnuplotIF->new( persist => 1 );
    $plot->gnuplot_cmd( "set noclip" );
    $plot->gnuplot_cmd( "set pointsize 2" );
    my $plot_title =  '"original data provided for EM"';
    my $arg_string ;
    if ($visualization_data_field_width > 2) {
        $arg_string = "\"$temp_file\" using 1:2:3 title $plot_title with points lt -1 pt 1";
    } elsif ($visualization_data_field_width == 2) {
        $arg_string = "\"$temp_file\" using 1:2 title $plot_title with points lt -1 pt 1";
    } elsif ($visualization_data_field_width == 1 ) {
        open INPUT, "$temp_file" or die "Unable to open a temp file in this directory: $!";
        my @all_data = <INPUT>;
        close INPUT;
        @all_data = map {chomp $_; $_} @all_data;
        @all_data = grep $_, @all_data;
        my ($minval,$maxval) = minmax(\@all_data);
        my $delta = ($maxval - $minval) / 100.0;
        $plot->gnuplot_cmd("set boxwidth 3");
        $plot->gnuplot_cmd("set style fill solid border -1");
        $plot->gnuplot_cmd("set ytics out nomirror");
        $plot->gnuplot_cmd("set style data histograms");
        $plot->gnuplot_cmd("set style histogram clustered");
        $plot->gnuplot_cmd("set title 'Overall distribution of 1D data'");
        $plot->gnuplot_cmd("set xtics rotate by 90 offset 0,-5 out nomirror");
        my $localfilename = basename($filename);
        my $temp_file = "__temp1dhist_" .  $localfilename;
        unlink $temp_file if -e $temp_file;
        open OUTPUT, ">$temp_file" or die "Unable to open a temp file in this directory: $!";
        print OUTPUT "Xstep histval\n";
        my @histogram = (0) x 100;
        foreach my $i (0..@all_data-1) {
            $histogram[int( ($all_data[$i] - $minval) / $delta )]++;
        }
        foreach my $i (0..@histogram-1) {
            print OUTPUT "$i $histogram[$i]\n";        
        }
        $arg_string = "\"$temp_file\" using 2:xtic(1) ti col smooth frequency with boxes lc rgb 'green'";
        close OUTPUT;
    }
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( 'set terminal png',
                            'set output "data_scatter_plot.png"');
        $plot->gnuplot_cmd( "splot $arg_string" );
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( 'set terminal png',
                            'set output "data_scatter_plot.png"');
        $plot->gnuplot_cmd( "plot $arg_string" );
    } elsif ($visualization_data_field_width == 1) {
        $plot->gnuplot_cmd( 'set terminal png',
                            'set output "data_scatter_plot.png"');
        $plot->gnuplot_cmd( "plot $arg_string" );
    }
}


###################  Generating Synthetic Data for Clustering  ###################

#  The data generated corresponds to a multivariate distribution.  The mean and the
#  covariance of each Gaussian in the distribution are specified individually in a
#  parameter file. The parameter file must also state the prior probabilities to be
#  associated with each Gaussian.  See the example parameter file param1.txt in the
#  examples directory.  Just edit this file for your own needs.
#
#  The multivariate random numbers are generated by calling the Math::Random module.
#  As you would expect, that module will insist that the covariance matrix you
#  specify be symmetric and positive definite.
sub cluster_data_generator {
    my $class = shift;
    die "illegal call of a class method" 
        unless $class eq 'Algorithm::ExpectationMaximization';
    my %args = @_;
    my $input_parameter_file = $args{input_parameter_file};
    my $output_file = $args{output_datafile};
    my $N = $args{total_number_of_data_points};
    my @all_params;
    my $param_string;
    if (defined $input_parameter_file) {
        open INPUT, $input_parameter_file || "unable to open parameter file: $!";
        @all_params = <INPUT>;
        @all_params = grep { $_ !~ /^[ ]*#/ } @all_params;
        chomp @all_params;
        $param_string = join ' ', @all_params;
    } else {
        # Just for testing. Used in t/test.t
        $param_string = "priors 0.34 0.33 0.33 " .
                        "cluster 5 0 0  1 0 0 0 1 0 0 0 1 " .
                        "cluster 0 5 0  1 0 0 0 1 0 0 0 1 " .
                        "cluster 0 0 5  1 0 0 0 1 0 0 0 1";
    }
    my ($priors_string) = $param_string =~ /priors(.+?)cluster/;
    croak "You did not specify the prior probabilities in the parameter file"
        unless $priors_string;
    my @priors = split /\s+/, $priors_string;
    @priors = grep {/$_num_regex/; $_} @priors;
    my $sum = 0;
    foreach my $prior (@priors) {
        $sum += $prior;
    }
    croak "Your priors in the parameter file do not add up to 1"  unless $sum == 1;
    my ($rest_of_string) = $param_string =~ /priors\s*$priors_string(.*)$/;
    my @cluster_strings = split /[ ]*cluster[ ]*/, $rest_of_string;
    @cluster_strings = grep  $_, @cluster_strings;

    my $K = @cluster_strings;
    croak "Too many clusters requested" if $K > 12;
    croak "Mismatch between the number of values for priors and the number " . 
        "of clusters" unless $K == @priors;
    my @point_labels = ('a'..'z');
    print "Prior probabilities recorded from param file: @priors\n";
    print "Number of Gaussians used for the synthetic data: $K\n";
    my @means;
    my @covariances;
    my $data_dimension;
    foreach my $i (0..$K-1) {
        my @num_strings = split /  /, $cluster_strings[$i];
        my @cluster_mean = map {/$_num_regex/;$_} split / /, $num_strings[0];
        $data_dimension = @cluster_mean;
        push @means, \@cluster_mean;
        my @covariance_nums = map {/$_num_regex/;$_} split / /, $num_strings[1];
        croak "dimensionality error" if @covariance_nums != 
                                      ($data_dimension ** 2);
        my $cluster_covariance;
        foreach my $j (0..$data_dimension-1) {
            foreach my $k (0..$data_dimension-1) {        
                $cluster_covariance->[$j]->[$k] = 
                         $covariance_nums[$j*$data_dimension + $k];
            }
        }
        push @covariances, $cluster_covariance;
    }
    random_seed_from_phrase( 'hellomellojello' );
    my @data_dump;
    foreach my $i (0..$K-1) {
        my @m = @{shift @means};
        my @covar = @{shift @covariances};
        my @new_data = Math::Random::random_multivariate_normal( 
                           int($N * $priors[$i]), @m, @covar );
        my $p = 0;
        my $label = $point_labels[$i];
        @new_data = map {unshift @$_, $label.$i; $i++; $_} @new_data;
        push @data_dump, @new_data;     
    }
    fisher_yates_shuffle( \@data_dump );
    open OUTPUT, ">$output_file";
    print OUTPUT "\#Data generated from the parameter file: $input_parameter_file\n"
        if $input_parameter_file;
    print OUTPUT "\#Total number of data points in this file: $N\n";
    print OUTPUT "\#Prior class probabilities for this data: @priors\n";
    foreach my $ele (@data_dump) {
        foreach my $coord ( @$ele ) {
            print OUTPUT "$coord ";
        }
        print OUTPUT "\n";
    }
    print "Data written out to file $output_file\n";
    close OUTPUT;
}

sub add_point_coords {
    my $self = shift;
    my @arr_of_ids = @{shift @_};      # array of data element names
    my @result;
    my $data_dimensionality = $self->{_data_dimensions};
    foreach my $i (0..$data_dimensionality-1) {
        $result[$i] = 0.0;
    }
    foreach my $id (@arr_of_ids) {
        my $ele = $self->{_data}->{$id};
        my $i = 0;
        foreach my $component (@$ele) {
            $result[$i] += $component;
            $i++;
        }
    }
    return \@result;
}

######################   Support Routines  ########################

# computer the outer product of two column vectors
sub outer_product {
    my $vec1 = shift;
    my $vec2 = shift;
    my ($nrows1, $ncols1) = ($vec1->rows(), $vec1->cols());
    my ($nrows2, $ncols2) = ($vec2->rows(), $vec2->cols());
    die "Outer product operation called with non-matching vectors"
        unless $ncols1 == 1 && $ncols2 == 1 && $nrows1 == $nrows2;
    my @vec_arr1 = $vec1->as_list();
    my @vec_arr2 = $vec2->as_list();
    my $outer_product = Math::GSL::Matrix->new($nrows1, $nrows2);
    foreach my $index (0..$nrows1-1) {
        my @new_row = map $vec_arr1[$index] * $_, @vec_arr2;
        $outer_product->set_row($index, \@new_row);
    }
    return $outer_product;
}

sub get_index_at_value {
    my $value = shift;
    my @array = @{shift @_};
    foreach my $i (0..@array-1) {
        return $i if $value == $array[$i];
    }
}

# This routine is really not necessary in light of the new `~~' operator in Perl.
# Will use the new operator in the next version.
sub vector_equal {
    my $vec1 = shift;
    my $vec2 = shift;
    die "wrong data types for distance calculation" if @$vec1 != @$vec2;
    foreach my $i (0..@$vec1-1){
        return 0 if $vec1->[$i] != $vec2->[$i];
    }
    return 1;
}

sub compare_array_floats {
    my $vec1 = shift;
    my $vec2 = shift;
    foreach my $i (0..@$vec1-1){
        return 0 if abs($vec1->[$i] - $vec2->[$i]) > 0.00001;
    }
    return 1;
}

# Returns the minimum value and its positional index in an array
sub minimum {
    my $arr = shift;
    my $min;
    my $index;
    foreach my $i (0..@{$arr}-1) {
        if ( (!defined $min) || ($arr->[$i] < $min) ) {
            $index = $i;
            $min = $arr->[$i];
        }
    }
    return ($min, $index);
}

sub minmax {
    my $arr = shift;
    my $min;
    my $max;
    foreach my $i (0..@{$arr}-1) {
        if ( (!defined $min) && (!defined $max) ) {
            $min = $arr->[$i];
            $max = $arr->[$i];
        } elsif ( $arr->[$i] < $min ) {
            $min = $arr->[$i];
        } elsif ( $arr->[$i] > $max ) {
            $max = $arr->[$i];
        }
    }
    return ($min, $max);
}

# Meant only for constructing a deep copy of an array of
# arrays:
sub deep_copy_AoA {
    my $ref_in = shift;
    my $ref_out;
    foreach my $i (0..@{$ref_in}-1) {
        foreach my $j (0..@{$ref_in->[$i]}-1) {
            $ref_out->[$i]->[$j] = $ref_in->[$i]->[$j];
        }
    }
    return $ref_out;
}

# Meant only for constructing a deep copy of an array of arrays for the case when
# some elements of the top-level array may be undefined:
sub deep_copy_AoA_with_nulls {
    my $ref_in = shift;
    my $ref_out;
    foreach my $i (0..@{$ref_in}-1) {
        if ( !defined $ref_in->[$i] ) {
            $ref_out->[$i] = undef;
            next;
        }
        foreach my $j (0..@{$ref_in->[$i]}-1) {
            $ref_out->[$i]->[$j] = $ref_in->[$i]->[$j];
        }
    }
    return $ref_out;
}

# Meant only for constructing a deep copy of a hash in which each value is an
# anonymous array of numbers:
sub deep_copy_hash {
    my $ref_in = shift;
    my $ref_out;
    while ( my ($key, $value) = each( %$ref_in ) ) {
        $ref_out->{$key} = deep_copy_array( $value );
    }
    return $ref_out;
}

# Meant only for an array of numbers:
sub deep_copy_array {
    my $ref_in = shift;
    my $ref_out;
    foreach my $i (0..@{$ref_in}-1) {
        $ref_out->[$i] = $ref_in->[$i];
    }
    return $ref_out;
}

# from perl docs:
sub fisher_yates_shuffle {                
    my $arr =  shift;                
    my $i = @$arr;                   
    while (--$i) {                   
        my $j = int rand( $i + 1 );  
        @$arr[$i, $j] = @$arr[$j, $i]; 
    }
}

sub mean_and_variance {
    my @data = @{shift @_};
    my ($mean, $variance);
    foreach my $i (1..@data) {
        if ($i == 1) {
            $mean = $data[0];
            $variance = 0;
        } else {
            # data[$i-1] because of zero-based indexing of vector
            $mean = ( (($i-1)/$i) * $mean ) + $data[$i-1] / $i;
            $variance = ( (($i-1)/$i) * $variance ) 
                           + ($data[$i-1]-$mean)**2 / ($i-1);
        }
    }
    return ($mean, $variance);
}

sub check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / datafile
                            mask
                            K
                            terminal_output
                            max_em_iterations
                            seeding
                            class_priors
                            seed_tags
                            debug
                          /;
    my $found_match_flag;
    foreach my $param (@params) {
        foreach my $legal (@legal_params) {
            $found_match_flag = 0;
            if ($param eq $legal) {
                $found_match_flag = 1;
                last;
            }
        }
        last if $found_match_flag == 0;
    }
    return $found_match_flag;
}

sub get_value_index_hash {
    my $arr = shift;
    my %hash;
    foreach my $index (0..@$arr-1) {
        $hash{$arr->[$index]} = $index if $arr->[$index] > 0;
    }
    return \%hash;
}

sub non_maximum_supression {
    my $arr = shift;
    my @output = (0) x @$arr;
    my @final_output = (0) x @$arr;
    my %hash;
    my @array_of_runs = ([$arr->[0]]);
    foreach my $index (1..@$arr-1) {
        if ($arr->[$index] == $arr->[$index-1]) {
            push @{$array_of_runs[-1]}, $arr->[$index];
        } else {  
            push @array_of_runs, [$arr->[$index]];
        }
    }
    my $runstart_index = 0;
    foreach my $run_index (1..@array_of_runs-2) {
        $runstart_index += @{$array_of_runs[$run_index-1]};
        if ($array_of_runs[$run_index]->[0] > 
            $array_of_runs[$run_index-1]->[0]  &&
            $array_of_runs[$run_index]->[0] > 
            $array_of_runs[$run_index+1]->[0]) {
            my $run_center = @{$array_of_runs[$run_index]} / 2;
            my $assignment_index = $runstart_index + $run_center;
            $output[$assignment_index] = $arr->[$assignment_index];
        }
    }
    if ($array_of_runs[-1]->[0] > $array_of_runs[-2]->[0]) {
        $runstart_index += @{$array_of_runs[-2]};
        my $run_center = @{$array_of_runs[-1]} / 2;
        my $assignment_index = $runstart_index + $run_center;
        $output[$assignment_index] = $arr->[$assignment_index];
    }
    if ($array_of_runs[0]->[0] > $array_of_runs[1]->[0]) {
        my $run_center = @{$array_of_runs[0]} / 2;
        $output[$run_center] = $arr->[$run_center];
    }
    return \@output;
}

sub display_matrix {
    my $message = shift;
    my $matrix = shift;
    if (!defined blessed($matrix)) {
        print "display_matrix called on a scalar value: $matrix\n";
        return;
    }
    my $nrows = $matrix->rows();
    my $ncols = $matrix->cols();
    print "$message ($nrows rows and $ncols columns)\n";
    foreach my $i (0..$nrows-1) {
        my $row = $matrix->row($i);
        my @row_as_list = $row->as_list;
        print "@row_as_list\n";
    }
    print "\n";
}

sub transpose {
    my $matrix = shift;
    my $num_rows = $matrix->rows();
    my $num_cols = $matrix->cols();
    my $transpose = Math::GSL::Matrix->new($num_cols, $num_rows);
    foreach my $i (0..$num_rows-1) {
        my @row = $matrix->row($i)->as_list;
        $transpose->set_col($i, \@row );
    }
    return $transpose;
}

sub vector_multiply {
    my $vec1 = shift;
    my $vec2 = shift;
    die "vec_multiply called with two vectors of different sizes"
        unless @$vec1 == @$vec2;
    my $result = 0;
    foreach my $i (0..@$vec1-1) {
        $result += $vec1->[$i] * $vec2->[$i];
    }
    return $result;
}

sub vector_2_vector_multiply {
    my $vec1 = shift;
    my $vec2 = shift;
    die "vec_multiply called with two vectors of different sizes"
        unless @$vec1 == @$vec2;
    my @result_vec;
    foreach my $i (0..@$vec1-1) {
        $result_vec[$i] = $vec1->[$i] * $vec2->[$i];
    }
    return \@result_vec;
}

sub matrix_multiply {
    my $matrix1 = shift;
    my $matrix2 = shift;
    my ($nrows1, $ncols1) = ($matrix1->rows(), $matrix1->cols());
    my ($nrows2, $ncols2) = ($matrix2->rows(), $matrix2->cols());
    die "matrix multiplication called with non-matching matrix arguments"
#        unless $ncols1 == $nrows2;
        unless $nrows1 == $ncols2 && $ncols1 == $nrows2;
    if ($nrows1 == 1) {
        my @row = $matrix1->row(0)->as_list;
        my @col = $matrix2->col(0)->as_list;
        my $result;
        foreach my $j (0..$ncols1-1) {
            $result += $row[$j] * $col[$j];
        }
        return $result;
    }
    my $product = Math::GSL::Matrix->new($nrows1, $nrows1);
    foreach my $i (0..$nrows1-1) {
        my $row = $matrix1->row($i);
        my @product_row;
        foreach my $j (0..$ncols2-1) {
            my $col = $matrix2->col($j);
            my $row_times_col = matrix_multiply($row, $col);
            push @product_row, $row_times_col;
        }
        $product->set_row($i, \@product_row);
    }
    return $product;
}

sub vector_matrix_multiply {
    my $matrix1 = shift;
    my $matrix2 = shift;
    my ($nrows1, $ncols1) = ($matrix1->rows, $matrix1->cols);
    my ($nrows2, $ncols2) = ($matrix2->rows, $matrix2->cols);
    die "matrix multiplication called with non-matching matrix arguments"
        unless $nrows1 == 1 && $ncols1 == $nrows2;
    if ($ncols2 == 1) {
        my @row = $matrix1->row(0)->as_list;
        my @col = $matrix2->col(0)->as_list;
        my $result;
        foreach my $j (0..$ncols1-1) {
            $result += $row[$j] * $col[$j];
        }
        return $result;
    }
    my $product = Math::GSL::Matrix->new(1, $ncols2);
    my $row = $matrix1->row(0);
    my @product_row;
    foreach my $j (0..$ncols2-1) {
        my $col = $matrix2->col($j);
        my $row_times_col = vector_matrix_multiply($row, $col);
            push @product_row, $row_times_col;
    }
    $product->set_row(0, \@product_row);
    return $product;
}

sub matrix_vector_multiply {
    my $matrix1 = shift;
    my $matrix2 = shift;
    my ($nrows1, $ncols1) = ($matrix1->rows(), $matrix1->cols());
    my ($nrows2, $ncols2) = ($matrix2->rows(), $matrix2->cols());
    die "matrix multiplication called with non-matching matrix arguments"
        unless $ncols1 == $nrows2 && $ncols2 == 1;
    if ($nrows1 == 1) {
        my @row = $matrix1->row(0)->as_list;
        my @col = $matrix2->col(0)->as_list;
        my $result;
        foreach my $j (0..$ncols1-1) {
            $result += $row[$j] * $col[$j];
        }
        return $result;
    }
    my $product = Math::GSL::Matrix->new($nrows1, 1);
    my $col = $matrix2->col(0);
    my @product_col;
    foreach my $i (0..$nrows1-1) {
        my $row = $matrix1->row($i);
        my $row_times_col = matrix_vector_multiply($row, $col);
            push @product_col, $row_times_col;
    }
    $product->set_col(0, \@product_col);
    return $product;
}

sub matrix_trace {
    my $matrix = shift;
    my ($nrows, $ncols) = ($matrix->rows(), $matrix->cols());
    die "trace can only be calculated for a square matrix"
                                      unless $ncols == $nrows;
    my @elements = $matrix->as_list;
    my $trace = 0;
    foreach my $i (0..$nrows-1) {
        $trace += $elements[$i +  $i * $ncols];
    }
    return $trace;
}

1;

=pod

=head1 NAME

Algorithm::ExpectationMaximization -- A Perl module for clustering numerical
multi-dimensional data with the Expectation-Maximization algorithm.

=head1 SYNOPSIS

  use Algorithm::ExpectationMaximization;

  #  First name the data file:

  my $datafile = "mydatafile.csv";

  #  Next, set the mask to indicate which columns of the datafile to use for
  #  clustering and which column contains a symbolic ID for each data record. For
  #  example, if the symbolic name is in the first column, you want the second column
  #  to be ignored, and you want the next three columns to be used for 3D clustering:

  my $mask = "N0111";

  #  Now construct an instance of the clusterer.  The parameter `K' controls the
  #  number of clusters.  Here is an example call to the constructor for instance
  #  creation:

  my $clusterer = Algorithm::ExpectationMaximization->new(
                                      datafile            => $datafile,
                                      mask                => $mask,
                                      K                   => 3,
                                      max_em_iterations   => 300,
                                      seeding             => 'random',
                                      terminal_output     => 1,
                  );
 
  #  Note the choice for `seeding'. The choice `random' means that the clusterer will
  #  randomly select `K' data points to serve as initial cluster centers.  Other
  #  possible choices for the constructor parameter `seeding' are `kmeans' and
  #  `manual'.  With the `kmeans' option for `seeding', the output of a K-means
  #  clusterer is used for the cluster seeds and the initial cluster covariances.  If
  #  you use the `manual' option for seeding, you must also specify the data elements
  #  to use for seeding the clusters.

  #  Here is an example of a call to the constructor when we choose the `manual'
  #  option for seeding the clusters and for specifying the data elements for
  #  seeding.  The data elements are specified by their tag names.  In this case,
  #  these names are `a26', `b53', and `c49':

  my $clusterer = Algorithm::ExpectationMaximization->new(
                                      datafile            => $datafile,
                                      mask                => $mask,
                                      class_priors        => [0.6, 0.2, 0.2],
                                      K                   => 3,
                                      max_em_iterations   => 300,
                                      seeding             => 'manual',
                                      seed_tags           => ['a26', 'b53', 'c49'],
                                      terminal_output     => 1,
                                    );

  #  This example call to the constructor also illustrates how you can inject class
  #  priors into the clustering process. The class priors are the prior probabilities
  #  of the class distributions in your dataset.  As explained later, injecting class
  #  priors in the manner shown above makes statistical sense only for the case of
  #  manual seeding.  When you do inject class priors, the order in which the priors
  #  are expressed must correspond to the manually specified seeds for the clusters.

  #  After the invocation of the constructor, the following calls are mandatory
  #  for reasons that should be obvious from the names of the methods:

  $clusterer->read_data_from_file();
  srand(time);
  $clusterer->seed_the_clusters();
  $clusterer->EM();
  $clusterer->run_bayes_classifier();
  my $clusters = $clusterer->return_disjoint_clusters();

  #  where the call to `EM()' is the invocation of the expectation-maximization
  #  algorithm.  The call to `srand(time)' is to seed the pseudo random number
  #  generator afresh for each run of the cluster seeding procedure.  If you want to
  #  see repeatable results from one run to another of the algorithm with random
  #  seeding, you would obviously not invoke `srand(time)'.

  #  The call `run_bayes_classifier()' shown above carries out a disjoint clustering
  #  of all the data points using the naive Bayes' classifier. And the call
  #  `return_disjoint_clusters()' returns the clusters thus formed to you.  Once you
  #  have obtained access to the clusters in this manner, you can display them in
  #  your terminal window by

  foreach my $index (0..@$clusters-1) {
      print "Cluster $index (Naive Bayes):   @{$clusters->[$index]}\n\n"
  }

  #  If you would like to also see the clusters purely on the basis of the posterior
  #  class probabilities exceeding a threshold, call

  my $theta1 = 0.2;
  my $posterior_prob_clusters =
           $clusterer->return_clusters_with_posterior_probs_above_threshold($theta1);

  #  where you can obviously set the threshold $theta1 to any value you wish.  Note
  #  that now you may end up with clusters that overlap.  You can display them in
  #  your terminal window in the same manner as shown above for the naive Bayes'
  #  clusters.

  #  You can write the naive Bayes' clusters out to files, one cluster per file, by
  #  calling

  $clusterer->write_naive_bayes_clusters_to_files();  

  #  The clusters are placed in files with names like

         naive_bayes_cluster1.txt
         naive_bayes_cluster2.txt
         ...

  #  In the same manner, you can write out the posterior probability based possibly
  #  overlapping clusters to files by calling:

  $clusterer->write_posterior_prob_clusters_above_threshold_to_files($theta1);

  #  where the threshold $theta1 sets the probability threshold for deciding which
  #  data elements to place in a cluster.  These clusters are placed in files with
  #  names like

         posterior_prob_cluster1.txt
         posterior_prob_cluster2.txt
         ...

  # CLUSTER VISUALIZATION:

  #  You must first set the mask for cluster visualization. This mask tells the 
  #  module which 2D or 3D subspace of the original data space you wish to visualize 
  #  the clusters in:

  my $visualization_mask = "111";
  $clusterer->visualize_clusters($visualization_mask);
  $clusterer->visualize_distributions($visualization_mask);
  $clusterer->plot_hardcopy_clusters($visualization_mask);
  $clusterer->plot_hardcopy_distributions($visualization_mask);

  #  where the last two invocations are for writing out the PNG plots of the
  #  visualization displays to disk files.  The PNG image of the posterior
  #  probability distributions is written out to a file named posterior_prob_plot.png
  #  and the PNG image of the disjoint clusters to a file called cluster_plot.png.

  # SYNTHETIC DATA GENERATION:

  #  The module has been provided with a class method for generating multivariate
  #  data for experimenting with the EM algorithm.  The data generation is controlled
  #  by the contents of a parameter file that is supplied as an argument to the data
  #  generator method.  The priors, the means, and the covariance matrices in the
  #  parameter file must be according to the syntax shown in the `param1.txt' file in
  #  the `examples' directory. It is best to edit a copy of this file for your
  #  synthetic data generation needs.

  my $parameter_file = "param1.txt";
  my $out_datafile = "mydatafile1.dat";
  Algorithm::ExpectationMaximization->cluster_data_generator(
                          input_parameter_file => $parameter_file,
                          output_datafile => $out_datafile,
                          total_number_of_data_points => $N );

  #  where the value of $N is the total number of data points you would like to see
  #  generated for all of the Gaussians.  How this total number is divided up amongst
  #  the Gaussians is decided by the prior probabilities for the Gaussian components
  #  as declared in input parameter file.  The synthetic data may be visualized in a
  #  terminal window and the visualization written out as a PNG image to a diskfile
  #  by

  my $data_visualization_mask = "11";                                            
  $clusterer->visualize_data($data_visualization_mask);                          
  $clusterer->plot_hardcopy_data($data_visualization_mask);


=head1 CHANGES

Version 1.22 should work with data in CSV files.

Version 1.21 incorporates minor code clean up.  Overall, the module implementation
remains unchanged.

Version 1.2 allows the module to also be used for 1-D data.  The visualization code
for 1-D shows the clusters through their histograms.

Version 1.1 incorporates much cleanup of the documentation associated with the
module.  Both the top-level module documentation, especially the Description part,
and the comments embedded in the code were revised for better utilization of the
module.  The basic implementation code remains unchanged.


=head1 DESCRIPTION

B<Algorithm::ExpectationMaximization> is a I<perl5> module for the
Expectation-Maximization (EM) method of clustering numerical data that lends itself
to modeling as a Gaussian mixture.  Since the module is entirely in Perl (in the
sense that it is not a Perl wrapper around a C library that actually does the
clustering), the code in the module can easily be modified to experiment with several
aspects of EM.

Gaussian Mixture Modeling (GMM) is based on the assumption that the data consists of
C<K> Gaussian components, each characterized by its own mean vector and its own
covariance matrix.  Obviously, given observed data for clustering, we do not know
which of the C<K> Gaussian components was responsible for any of the data elements.
GMM also associates a prior probability with each Gaussian component.  In general,
these priors will also be unknown.  So the problem of clustering consists of
estimating the posterior class probability at each data element and also estimating
the class priors. Once these posterior class probabilities and the priors are
estimated with EM, we can use the naive Bayes' classifier to partition the data into
disjoint clusters.  Or, for "soft" clustering, we can find all the data elements that
belong to a Gaussian component on the basis of the posterior class probabilities at
the data elements exceeding a prescribed threshold.

If you do not mind the fact that it is possible for the EM algorithm to occasionally
get stuck in a local maximum and to, therefore, produce a wrong answer even when you
know the data to be perfectly multimodal Gaussian, EM is probably the most magical
approach to clustering multidimensional data.  Consider the case of clustering
three-dimensional data.  Each Gaussian cluster in 3D space is characterized by the
following 10 variables: the 6 unique elements of the C<3x3> covariance matrix (which
must be symmetric positive-definite), the 3 unique elements of the mean, and the
prior associated with the Gaussian. Now let's say you expect to see six Gaussians in
your data.  What that means is that you would want the values for 59 variables
(remember the unit-summation constraint on the class priors which reduces the overall
number of variables by one) to be estimated by the algorithm that seeks to discover
the clusters in your data.  What's amazing is that, despite the large number of
variables that must be optimized simultaneously, the EM algorithm will very likely
give you a good approximation to the right answer.

At its core, EM depends on the notion of unobserved data and the averaging of the
log-likelihood of the data actually observed over all admissible probabilities for
the unobserved data.  But what is unobserved data?  While in some cases where EM is
used, the unobserved data is literally the missing data, in others, it is something
that cannot be seen directly but that nonetheless is relevant to the data actually
observed. For the case of clustering multidimensional numerical data that can be
modeled as a Gaussian mixture, it turns out that the best way to think of the
unobserved data is in terms of a sequence of random variables, one for each observed
data point, whose values dictate the selection of the Gaussian for that data point.
This point is explained in great detail in my on-line tutorial at
L<https://engineering.purdue.edu/kak/Tutorials/ExpectationMaximization.pdf>.

The EM algorithm in our context reduces to an iterative invocation of the following
steps: (1) Given the current guess for the means and the covariances of the different
Gaussians in our mixture model, use Bayes' Rule to update the posterior class
probabilities at each of the data points; (2) Using the updated posterior class
probabilities, first update the class priors; (3) Using the updated class priors,
update the class means and the class covariances; and go back to Step (1).  Ideally,
the iterations should terminate when the expected log-likelihood of the observed data
has reached a maximum and does not change with any further iterations.  The stopping
rule used in this module is the detection of no change over three consecutive
iterations in the values calculated for the priors.

This module provides three different choices for seeding the clusters: (1) random,
(2) kmeans, and (3) manual.  When random seeding is chosen, the algorithm randomly
selects C<K> data elements as cluster seeds.  That is, the data vectors associated
with these seeds are treated as initial guesses for the means of the Gaussian
distributions.  The covariances are then set to the values calculated from the entire
dataset with respect to the means corresponding to the seeds. With kmeans seeding, on
the other hand, the means and the covariances are set to whatever values are returned
by the kmeans algorithm.  And, when seeding is set to manual, you are allowed to
choose C<K> data elements --- by specifying their tag names --- for the seeds.  The
rest of the EM initialization for the manual mode is the same as for the random mode.
The algorithm allows for the initial priors to be specified for the manual mode of
seeding.

Much of code for the kmeans based seeding of EM was drawn from the
C<Algorithm::KMeans> module by me. The code from that module used here corresponds to
the case when the C<cluster_seeding> option in the C<Algorithm::KMeans> module is set
to C<smart>.  The C<smart> option for KMeans consists of subjecting the data to a
principal components analysis (PCA) to discover the direction of maximum variance in
the data space.  The data points are then projected on to this direction and a
histogram constructed from the projections.  Centers of the C<K> largest peaks in
this smoothed histogram are used to seed the KMeans based clusterer.  As you'd
expect, the output of the KMeans used to seed the EM algorithm.

This module uses two different criteria to measure the quality of the clustering
achieved. The first is the Minimum Description Length (MDL) proposed originally by
Rissanen (J. Rissanen: "Modeling by Shortest Data Description," Automatica, 1978, and
"A Universal Prior for Integers and Estimation by Minimum Description Length," Annals
of Statistics, 1983.)  The MDL criterion is a difference of a log-likelihood term for
all of the observed data and a model-complexity penalty term. In general, both the
log-likelihood and the model-complexity terms increase as the number of clusters
increases.  The form of the MDL criterion in this module uses for the penalty term
the Bayesian Information Criterion (BIC) of G. Schwartz, "Estimating the Dimensions
of a Model," The Annals of Statistics, 1978.  In general, the smaller the value of
MDL quality measure, the better the clustering of the data.

For our second measure of clustering quality, we use `trace( SW^-1 . SB)' where SW is
the within-class scatter matrix, more commonly denoted S_w, and SB the between-class
scatter matrix, more commonly denoted S_b (the underscore means subscript).  This
measure can be thought of as the normalized average distance between the clusters,
the normalization being provided by average cluster covariance SW^-1. Therefore, the
larger the value of this quality measure, the better the separation between the
clusters.  Since this measure has its roots in the Fisher linear discriminant
function, we incorporate the word C<fisher> in the name of the quality measure.
I<Note that this measure is good only when the clusters are disjoint.> When the
clusters exhibit significant overlap, the numbers produced by this quality measure
tend to be generally meaningless.

=head1 METHODS

The module provides the following methods for EM based
clustering, for cluster visualization, for data
visualization, and for the generation of data for testing a
clustering algorithm:

=over

=item B<new():>

A call to C<new()> constructs a new instance of the
C<Algorithm::ExpectationMaximization> class.  A typical form
of this call when you want to use random option for seeding
the algorithm is:

    my $clusterer = Algorithm::ExpectationMaximization->new(
                                datafile            => $datafile,
                                mask                => $mask,
                                K                   => 3,
                                max_em_iterations   => 300,
                                seeding             => 'random',
                                terminal_output     => 1,
                    );

where C<K> is the expected number of clusters and
C<max_em_iterations> the maximum number of EM iterations
that you want to allow until convergence is achieved.
Depending on your dataset and on the choice of the initial
seeds, the actual number of iterations used could be as few
as 10 and as many as reaching 300.  The output produced by
the algorithm shows the actual number of iterations used to
arrive at convergence.

The data file supplied through the C<datafile> option is
expected to contain entries in the following format

   c20  0  10.7087017086940  9.63528386251712  10.9512155258108  ...
   c7   0  12.8025925026787  10.6126270065785  10.5228482095349  ...
   b9   0  7.60118206283120  5.05889245193079  5.82841781759102  ...
   ....
   ....

where the first column contains the symbolic ID tag for each
data record and the rest of the columns the numerical
information.  As to which columns are actually used for
clustering is decided by the string value of the mask.  For
example, if we wanted to cluster on the basis of the entries
in just the 3rd, the 4th, and the 5th columns above, the
mask value would be C<N0111> where the character C<N>
indicates that the ID tag is in the first column, the
character C<0> that the second column is to be ignored, and
the C<1>'s that follow that the 3rd, the 4th, and the 5th
columns are to be used for clustering.

If instead of random seeding, you wish to use the kmeans
based seeding, just replace the option C<random> supplied
for C<seeding> by C<kmeans>.  You can also do manual seeding
by designating a specified set of data elements to serve as
cluster seeds.  The call to the constructor in this case
looks like

    my $clusterer = Algorithm::ExpectationMaximization->new(
                                datafile            => $datafile,
                                mask                => $mask,
                                K                   => 3,
                                max_em_iterations   => 300,
                                seeding             => 'manual',
                                seed_tags           => ['a26', 'b53', 'c49'],
                                terminal_output     => 1,
                    );

where the option C<seed_tags> is set to an anonymous array
of symbolic names associated with the data elements.

If you know the class priors, you can supply them through an
additional option to the constructor that looks like

    class_priors    => [0.6, 0.2, 0.2],

for the case of C<K> equal to 3.  B<In general, this would
be a useful thing to do only for the case of manual
seeding.> If you go for manual seeding, the order in which
the priors are expressed should correspond to the order of
the manually chosen tags supplied through the C<seed_tags>
option.

Note that the parameter C<terminal_output> is boolean; when
not supplied in the call to C<new()> it defaults to 0.  When
set, this parameter displays useful information in the
window of the terminal screen in which you invoke the
algorithm.

=item B<read_data_from_file():>

    $clusterer->read_data_from_file()

This is a required call after the constructor is invoked. As
you would expect, this call reads in the data for
clustering.

=item B<seed_the_clusters():>

    $clusterer->seed_the_clusters();

This is also a required call.  It processes the option you
supplied for C<seeding> in the constructor call to choose
the data elements for seeding the C<K> clusters.

=item B<EM():>

    $clusterer->EM();

This is the workhorse of the module, as you would expect.
The means, the covariances, and the priors estimated by this
method are stored in instance variables that are subsequently
accessed by other methods for the purpose of displaying the
clusters, the probability distributions, etc.

=item B<run_bayes_classifier():>

    $clusterer->run_bayes_classifier();

Using the posterior probability distributions estimated by
the C<EM()> method, this method partitions the data into the
C<K> disjoint clusters using the naive Bayes' classifier.

=item B<return_disjoint_clusters():>

    my $clusters = $clusterer->return_disjoint_clusters();

This allows you to access the clusters obtained with the
application of the naive Bayes' classifier in your own
scripts.  If, say, you wanted to see the data records placed
in each cluster, you could subsequently invoke the following
loop in your own script:

    foreach my $index (0..@$clusters-1) {
        print "Cluster $index (Naive Bayes):   @{$clusters->[$index]}\n\n"
    }

where C<$clusters> holds the array reference returned by the
call to C<return_disjoint_clusters()>.

=item B<write_naive_bayes_clusters_to_files():>

    $clusterer->write_naive_bayes_clusters_to_files();

This method writes the clusters obtained by applying the
naive Bayes' classifier to disk files, one cluster per
file.  What is written out to each file consists of the
symbolic names of the data records that belong to the
cluster corresponding to that file.  The clusters are placed
in files with names like

    naive_bayes_cluster1.txt
    naive_bayes_cluster2.txt
    ...

=item B<return_clusters_with_posterior_probs_above_threshold($theta1):>

    my $theta1 = 0.2;
    my $posterior_prob_clusters =
       $clusterer->return_clusters_with_posterior_probs_above_threshold($theta1);

This method returns a reference to an array of C<K>
anonymous arrays, each consisting of the symbolic names for
the data records where the posterior class probability
exceeds the threshold as specified by C<$theta1>.
Subsequently, you can access each of these
posterior-probability based clusters through a loop
construct such as

    foreach my $index (0..@$posterior_prob_clusters-1) {
        print "Cluster $index (based on posterior probs exceeding $theta1): " .
              "@{$posterior_prob_clusters->[$index]}\n\n"
    }

=item B<write_posterior_prob_clusters_above_threshold_to_files($theta1):>

    $clusterer->write_posterior_prob_clusters_above_threshold_to_files($theta1);

This call writes out the posterior-probability based soft
clusters to disk files.  As in the previous method, the
threshold C<$theta1> sets the probability threshold for
deciding which data elements belong to a cluster.  These
clusters are placed in files with names like

    posterior_prob_cluster1.txt
    posterior_prob_cluster2.txt
    ...

=item B<return_individual_class_distributions_above_given_threshold($theta):>

    my $theta2 = 0.00001;
    my $class_distributions =
      $clusterer->return_individual_class_distributions_above_given_threshold($theta2);

This is the method to call if you wish to see the individual
Gaussians in your own script. The method returns a reference
to an array of anonymous arrays, with each anonymous array
representing data membership in each Gaussian.  Only those
data points are included in each Gaussian where the
probability exceeds the threshold C<$theta2>. Note that the
larger the covariance and the higher the data
dimensionality, the smaller this threshold must be for you
to see any of the data points in a Gaussian.  After you have
accessed the Gaussian mixture in this manner, you can
display the data membership in each Gaussian through the
following sort of a loop:

    foreach my $index (0..@$class_distributions-1) {
        print "Gaussian Distribution $index (only shows data elements " .
              "whose probabilities exceed the threshold $theta2:  " .
              "@{$class_distributions->[$index]}\n\n"
    }

=item B<visualize_clusters($visualization_mask):>

    my $visualization_mask = "11";
    $clusterer->visualize_clusters($visualization_mask);

The visualization mask here does not have to be identical to
the one used for clustering, but must be a subset of that
mask.  This is convenient for visualizing the clusters in
two- or three-dimensional subspaces of the original space.
The subset is specified by placing `0's in the positions
corresponding to the dimensions you do NOT want to see
through visualization.  Depending on the mask used, this
method creates a 2D or a 3D scatter plot of the clusters
obtained through the naive Bayes' classification rule.

=item B<visualize_distributions($visualization_mask):>

    $clusterer->visualize_distributions($visualization_mask);

This is the method to call if you want to visualize the soft
clustering corresponding to the posterior class
probabilities exceeding the threshold specified in the call
to
C<return_clusters_with_posterior_probs_above_threshold($theta1)>.
Again, depending on the visualization mask used, you will
see either a 2D plot or a 3D scatter plot.

=item B<plot_hardcopy_clusters($visualization_mask):>

    $clusterer->plot_hardcopy_clusters($visualization_mask);

This method create a PNG file from the C<gnuplot> created
display of the naive Bayes' clusters obtained from the data.
The plotting functionality of C<gnuplot> is accessed through
the Perl wrappers provided by the C<Graphics::GnuplotIF>
module.

=item B<plot_hardcopy_distributions($visualization_mask):>

    $clusterer->plot_hardcopy_distributions($visualization_mask);

This method create a PNG file from the C<gnuplot> created
display of the clusters that correspond to the posterior
class probabilities exceeding a specified threshold. The
plotting functionality of C<gnuplot> is accessed through the
Perl wrappers provided by the C<Graphics::GnuplotIF> module.

=item B<display_fisher_quality_vs_iterations():>

    $clusterer->display_fisher_quality_vs_iterations();

This method measures the quality of clustering by
calculating the normalized average squared distance between
the cluster centers, the normalization being provided by the
average cluster covariance. See the Description for further
details.  In general, this measure is NOT useful for
overlapping clusters.

=item B<display_mdl_quality_vs_iterations():>

    $clusterer->display_mdl_quality_vs_iterations();

At the end of each iteration, this method measures the
quality of clustering my calculating its MDL (Minimum
Description Length).  As stated earlier in Description, the
MDL measure is a difference of a log-likelihood term for all
of the observed data and a model-complexity penalty term.
The smaller the value returned by this method, the better
the clustering.

=item B<return_estimated_priors():>

    my $estimated_priors = $clusterer->return_estimated_priors();
    print "Estimated class priors: @$estimated_priors\n";

This method can be used to access the final values of the
class priors as estimated by the EM algorithm.

=item  B<cluster_data_generator()>

    Algorithm::ExpectationMaximization->cluster_data_generator(
                            input_parameter_file => $parameter_file,
                            output_datafile => $out_datafile,
                            total_number_of_data_points => 300 
    );

for generating multivariate data for clustering if you wish to play with synthetic
data for experimenting with the EM algorithm.  The input parameter file must specify
the priors to be used for the Gaussians, their means, and their covariance matrices.
The format of the information contained in the parameter file must be as shown in the
file C<param1.txt> provided in the C<examples> directory.  It will be easiest for you
to just edit a copy of this file for your data generation needs.  In addition to the
format of the parameter file, the main constraint you need to observe in specifying
the parameters is that the dimensionality of the covariance matrices must correspond
to the dimensionality of the mean vectors.  The multivariate random numbers are
generated by calling the C<Math::Random> module.  As you would expect, this module
requires that the covariance matrices you specify in your parameter file be symmetric
and positive definite.  Should the covariances in your parameter file not obey this
condition, the C<Math::Random> module will let you know.

=item B<visualize_data($data_visualization_mask):>

    $clusterer->visualize_data($data_visualization_mask);                          

This is the method to call if you want to visualize the data
you plan to cluster with the EM algorithm.  You'd need to
specify argument mask in a manner similar to the
visualization of the clusters, as explained earlier.

=item B<plot_hardcopy_data($data_visualization_mask):>

    $clusterer->plot_hardcopy_data($data_visualization_mask); 

This method creates a PNG file that can be used to print out
a hardcopy of the data in different 2D and 3D subspaces of
the data space. The visualization mask is used to select the
subspace for the PNG image.

=back

=head1 HOW THE CLUSTERS ARE OUTPUT

This module produces two different types of clusters: the "hard" clusters and the
"soft" clusters.  The hard clusters correspond to the naive Bayes' classification of
the data points on the basis of the Gaussian distributions and the class priors
estimated by the EM algorithm. Such clusters partition the data into disjoint
subsets.  On the other hand, the soft clusters correspond to the posterior class
probabilities calculated by the EM algorithm.  A data element belongs to a cluster if
its posterior probability for that Gaussian exceeds a threshold.

After the EM algorithm has finished running, the hard clusters are created by
invoking the method C<run_bayes_classifier()> on an instance of the module and then
made user-accessible by calling C<return_disjoint_clusters()>.  These clusters may
then be displayed in a terminal window by dereferencing each element of the array
whose reference is returned b C<return_disjoint_clusters()>.  The hard clusters can
be written out to disk files by invoking C<write_naive_bayes_clusters_to_files()>.
This method writes out the clusters to files, one cluster per file.  What is written
out to each file consists of the symbolic names of the data records that belong to
the cluster corresponding to that file.  The clusters are placed in files with names
like

    naive_bayes_cluster1.txt
    naive_bayes_cluster2.txt
    ...

The soft clusters on the other hand are created by calling
C<return_clusters_with_posterior_probs_above_threshold($theta1)>
on an instance of the module, where the argument C<$theta1>
is the threshold for deciding whether a data element belongs
in a soft cluster.  The posterior class probability at a
data element must exceed the threshold for the element to
belong to the corresponding cluster.  The soft cluster can
be written out to disk files by calling
C<write_posterior_prob_clusters_above_threshold_to_files($theta1)>.
As with the hard clusters, each cluster is placed in a separate
file. The filenames for such clusters look like:

    posterior_prob_cluster1.txt
    posterior_prob_cluster2.txt
    ...

=head1 WHAT IF THE NUMBER OF CLUSTERS IS UNKNOWN?

The module constructor requires that you supply a value for the parameter C<K>, which
is the number of clusters you expect to see in the data.  But what if you do not have
a good value for C<K>?  Note that it is possible to search for the best C<K> by using
the two clustering quality criteria included in the module.  However, I have
intentionally not yet incorporated that feature in the module because it slows down
the execution of the code --- especially when the dimensionality of the data
increases.  However, nothing prevents you from writing a script --- along the lines
of the five "canned_example" scripts in the C<examples> directory --- that would use
the two clustering quality metrics for finding the best choice for C<K> for a given
dataset.  Obviously, you will now have to incorporate the call to the constructor in
a loop and check the value of the quality measures for each value of C<K>.

=head1 SOME RESULTS OBTAINED WITH THIS MODULE

If you would like to see some results that have been obtained with this module, check
out Section 7 of the report
L<https://engineering.purdue.edu/kak/Tutorials/ExpectationMaximization.pdf>.

=head1 THE C<examples> DIRECTORY

Becoming familiar with this directory should be your best
strategy to become comfortable with this module (and its
future versions).  You are urged to start by executing the
following five example scripts:

=over 16

=item I<canned_example1.pl>

This example applies the EM algorithm to the data contained in the datafile
C<mydatafile.dat>.  The mixture data in the file corresponds to three overlapping
Gaussian components in a star-shaped pattern.  The EM based clustering for this data
is shown in the files C<save_example_1_cluster_plot.png> and
C<save_example_1_posterior_prob_plot.png>, the former displaying the hard clusters
obtained by using the naive Bayes' classifier and the latter showing the soft
clusters obtained on the basis of the posterior class probabilities at the data
points.  

=item I<canned_example2.pl>

The datafile used in this example is C<mydatafile2.dat>.  This mixture data
corresponds to two well-separated relatively isotropic Gaussians.  EM based clustering for this
data is shown in the files C<save_example_2_cluster_plot.png> and
C<save_example_2_posterior_prob_plot.png>, the former displaying the hard clusters
obtained by using the naive Bayes' classifier and the latter showing the soft
clusters obtained by using the posterior class probabilities at the data points.

=item I<canned_example3.pl>

Like the first example, this example again involves three Gaussians, but now their
means are not co-located.  Additionally, we now seed the clusters manually by
specifying three selected data points as the initial guesses for the cluster means.
The datafile used for this example is C<mydatafile3.dat>.  The EM based clustering
for this data is shown in the files C<save_example_3_cluster_plot.png> and
C<save_example_3_posterior_prob_plot.png>, the former displaying the hard clusters
obtained by using the naive Bayes' classifier and the latter showing the soft
clusters obtained on the basis of the posterior class probabilities at the data
points.

=item I<canned_example4.pl>

Whereas the three previous examples demonstrated EM based clustering of 2D data, we
now present an example of clustering in 3D.  The datafile used in this example is
C<mydatafile4.dat>.  This mixture data corresponds to three well-separated but highly
anisotropic Gaussians. The EM derived clustering for this data is shown in the files
C<save_example_4_cluster_plot.png> and C<save_example_4_posterior_prob_plot.png>, the
former displaying the hard clusters obtained by using the naive Bayes' classifier and
the latter showing the soft clusters obtained on the basis of the posterior class
probabilities at the data points.

You may also wish to run this example on the data in a CSV file in the C<examples>
directory. The name of the file is C<sphericaldata.csv>.  

=item I<canned_example5.pl>

We again demonstrate clustering in 3D but now we have one Gaussian cluster that
"cuts" through the other two Gaussian clusters.  The datafile used in this example is
C<mydatafile5.dat>.  The three Gaussians in this case are highly overlapping and
highly anisotropic.  The EM derived clustering for this data is shown in the files
C<save_example_5_cluster_plot.png> and C<save_example_5_posterior_prob_plot.png>, the
former displaying the hard clusters obtained by using the naive Bayes' classifier and
the latter showing the soft clusters obtained through the posterior class
probabilities at the data points.

=item I<canned_example6.pl>

This example, added in Version 1.2, demonstrates the use of this module for 1-D data.
In order to visualize the clusters for the 1-D case, we show them through their
respective histograms.  The datafile used in this example is C<mydatafile7.dat>.  The
data consists of two overlapping Gaussians.  The EM derived clustering for this data
is shown in the files C<save_example_6_cluster_plot.png> and
C<save_example_6_posterior_prob_plot.png>, the former displaying the hard clusters
obtained by using the naive Bayes' classifier and the latter showing the soft
clusters obtained through the posterior class probabilities at the data points.

=back

Going through the six examples listed above will make you familiar with how to make
the calls to the clustering and the visualization methods.  The C<examples> directory
also includes several parameter files with names like

    param1.txt
    param2.txt
    param3.txt 
    ...

These were used to generate the synthetic data for which the results are shown in the
C<examples> directory.  Just make a copy of one of these files and edit it if you
would like to generate your own multivariate data for clustering.  Note that you can
generate data with any dimensionality through appropriate entries in the parameter
file.

=head1 CAVEATS

When you run the scripts in the C<examples> directory, your results will NOT always
look like what I have shown in the PNG image files in the directory.  As mentioned
earlier in Description, the EM algorithm starting from randomly chosen initial
guesses for the cluster means can get stuck in a local maximum.

That raises an interesting question of how one judges the correctness of clustering
results when dealing with real experimental data.  For real data, the best approach
is to try the EM algorithm multiple times with all of the seeding options included in
this module.  It would be safe to say that, at least in low dimensional spaces and
with sufficient data, a majority of your runs should yield "correct" results.

Also bear in mind that a pure Perl implementation is not meant for the clustering of
very large data files.  It is really designed more for researching issues related to
EM based approaches to clustering.


=head1 REQUIRED

This module requires the following three modules:

   Math::Random
   Graphics::GnuplotIF
   Math::GSL::Matrix

the first for generating the multivariate random numbers, the second for the
visualization of the clusters, and the last for access to the Perl wrappers for the
GNU Scientific Library.  The C<Matrix> module of this library is used for various
algebraic operations on the covariance matrices of the Gaussians.

=head1 EXPORT

None by design.


=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'Algorithm EM' in the subject line.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-ExpectationMaximization-1.22.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-ExpectationMaximization-1.22>.  Enter this directory and execute the
following commands for a standard install of the module if you have root privileges:

    perl Makefile.PL
    make
    make test
    sudo make install

If you do not have root privileges, you can carry out a non-standard install the
module in any directory of your choice by:

    perl Makefile.PL prefix=/some/other/directory/
    make
    make test
    make install

With a non-standard install, you may also have to set your PERL5LIB environment
variable so that this module can find the required other modules. How you do that
would depend on what platform you are working on.  In order to install this module in
a Linux machine on which I use tcsh for the shell, I set the PERL5LIB environment
variable by

    setenv PERL5LIB /some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/

If I used bash, I'd need to declare:

    export PERL5LIB=/some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/


=head1 ACKNOWLEDGMENTS

Version 1.2 is a result of the feedback received from Paul
May of University of Birmingham. Thanks, Paul!

=head1 AUTHOR

Avinash Kak, kak@purdue.edu

If you send email, please place the string "EM Algorithm" in your
subject line to get past my spam filter.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2014 Avinash Kak

=cut

