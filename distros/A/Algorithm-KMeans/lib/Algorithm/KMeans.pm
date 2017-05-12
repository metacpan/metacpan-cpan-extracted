package Algorithm::KMeans;

#------------------------------------------------------------------------------------
# Copyright (c) 2014 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::KMeans is a Perl module for clustering multidimensional data.
# -----------------------------------------------------------------------------------

#use 5.10.0;
use strict;
use warnings;
use Carp;
use File::Basename;
use Math::Random;
use Graphics::GnuplotIF;
use Math::GSL::Matrix;


our $VERSION = '2.05';

# from Perl docs:
my $_num_regex =  '^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$'; 

# Constructor:
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if check_for_illegal_params(@params) == 0;
    bless {
        _datafile                 =>   $args{datafile} || croak("datafile required"),
        _mask                     =>   $args{mask}     || croak("mask required"),
        _K                        =>   $args{K}        || 0,
        _K_min                    =>   $args{Kmin} || 'unknown',
        _K_max                    =>   $args{Kmax} || 'unknown',
        _cluster_seeding          =>   $args{cluster_seeding} || croak("must choose smart or random ".
                                                                       "for cluster seeding"),
        _var_normalize            =>   $args{do_variance_normalization} || 0,
        _use_mahalanobis_metric   =>   $args{use_mahalanobis_metric} || 0,  
        _clusters_2_files         =>   $args{write_clusters_to_files} || 0,
        _terminal_output          =>   $args{terminal_output} || 0,
        _debug                    =>   $args{debug} || 0,
        _N                        =>   0,
        _K_best                   =>   'unknown',
        _original_data            =>   {},
        _data                     =>   {},
        _data_id_tags             =>   [],
        _QoC_values               =>   {},
        _clusters                 =>   [],
        _cluster_centers          =>   [],
        _clusters_hash            =>   {},
        _cluster_centers_hash     =>   {},
        _cluster_covariances_hash =>   {},
        _data_dimensions          =>   0,

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
            "the size of at least one of the data records in the file: $!"
            unless scalar(@mask) == scalar(@splits);
        my $record_name = shift @splits;
        $data_hash{$record_name} = \@splits;
        push @data_tags, $record_name;
    }
    $self->{_original_data} = \%data_hash;
    $self->{_data_id_tags} = \@data_tags;
    $self->{_N} = scalar @data_tags;
    if ($self->{_var_normalize}) {
        $self->{_data} =  variance_normalization( $self->{_original_data} ); 
    } else {
        $self->{_data} = deep_copy_hash( $self->{_original_data} );
    }
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
    print "data dimensionality:  $self->{_data_dimensions} \n"if $self->{_terminal_output};
    open INPUT, $datafile or die "unable to open file $datafile: $!\n";
    chomp( my @raw_data = <INPUT> );
    close INPUT;
    # Transform strings into number data
    foreach my $record (@raw_data) {
        next unless $record;
        next if $record =~ /^#/;
        my @data_fields;
        my @fields = split /\s+/, $record;
        die "\nABORTED: Mask size does not correspond to row record size\n" if $#fields != $#mask;
        my $record_id;
        foreach my $i (0..@fields-1) {
            if ($mask[$i] eq '0') {
                next;
            } elsif ($mask[$i] eq 'N') {
                $record_id = $fields[$i];
            } elsif ($mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                die "misformed mask for reading the data file\n";
            }
        }
        my @nums = map {/$_num_regex/;$_} @data_fields;
        $self->{_original_data}->{ $record_id } = \@nums;
    }
    if ($self->{_var_normalize}) {
        $self->{_data} =  variance_normalization( $self->{_original_data} ); 
    } else {
        $self->{_data} = deep_copy_hash( $self->{_original_data} );
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
        print "\n\n\n";
    }
}

sub kmeans {
    my $self = shift;
    my $K = $self->{_K};
    if ( ($K == 0) ||
              ( ($self->{_K_min} ne 'unknown') &&
                ($self->{_K_max} ne 'unknown') ) ) {
        eval {
            $self->iterate_through_K();   
        };
        die "in kmeans(): $@" if ($@);
    } elsif ( $K =~ /\d+/) {
        eval {
            $self->cluster_for_fixed_K_multiple_random_tries($K) 
                                            if $self->{_cluster_seeding} eq 'random';
            $self->cluster_for_fixed_K_single_smart_try($K) 
                                            if $self->{_cluster_seeding} eq 'smart';
        };
        die "in kmeans(): $@" if ($@);
    } else {
        croak "Incorrect call syntax used.  See documentation.\n";
    }
    if ((defined $self->{_clusters}) && (defined $self->{_cluster_centers})){
        foreach my $i (0..@{$self->{_clusters}}-1) {
            $self->{_clusters_hash}->{"cluster$i"} = $self->{_clusters}->[$i];
            $self->{_cluster_centers_hash}->{"cluster$i"} = $self->{_cluster_centers}->[$i];
            $self->{_cluster_covariances_hash}->{"cluster$i"} = 
                               $self->estimate_cluster_covariance($self->{_clusters}->[$i]);
        }
        $self->write_clusters_to_files( $self->{_clusters} ) if $self->{_clusters_2_files};
        return ($self->{_clusters_hash}, $self->{_cluster_centers_hash});
    } else {
        croak "Clustering failed.  Try again.";
    }
}

# This is the subroutine to call if you prefer purely random choices for the initial
# seeding of the cluster centers.
sub cluster_for_fixed_K_multiple_random_tries {
    my $self = shift;
    my $K = shift;
    my @all_data_ids = @{$self->{_data_id_tags}};
    my $QoC;
    my @QoC_values;
    my @array_of_clusters;
    my @array_of_cluster_centers;
    my $clusters;
    my $new_clusters;
    my $cluster_centers;
    my $new_cluster_centers;
    print "Clustering for K = $K\n" if $self->{_terminal_output};
    foreach my $trial (1..20) {
        print ". ";
        my ($new_clusters, $new_cluster_centers);
        eval {
            ($new_clusters, $new_cluster_centers) = $self->cluster_for_given_K($K);
        };
        next if $@;
        next if @$new_clusters <= 1;
        my $newQoC = $self->cluster_quality( $new_clusters, $new_cluster_centers );
        if ( (!defined $QoC) || ($newQoC < $QoC) ) {
            $QoC = $newQoC;
            $clusters = deep_copy_AoA( $new_clusters );
            $cluster_centers = deep_copy_AoA( $new_cluster_centers );
        } 
    }
    die "\n\nThe constructor options you have chosen do not work with the data.  Try\n" .
        "turning off the Mahalanobis option if you are using it.\n"
        unless defined $clusters;
    $self->{_clusters} = $clusters;
    $self->{_cluster_centers} = $cluster_centers;  
    $self->{_QoC_values}->{"$K"} = $QoC; 
    if ($self->{_terminal_output}) {
        print "\nDisplaying final clusters for best K (= $K) :\n";
        display_clusters( $clusters );
        $self->display_cluster_centers( $clusters );
        print "\nQoC value (the smaller, the better): $QoC\n";
    }
}

# For the smart try, we do initial cluster seeding by subjecting the data to
# principal components analysis in order to discover the direction of maximum
# variance in the data space.  Subsequently, we try to find the K largest peaks along
# this direction.  The coordinates of these peaks serve as the seeds for the K
# clusters.
sub cluster_for_fixed_K_single_smart_try {
    my $self = shift;
    my $K = shift;
    my @all_data_ids = @{$self->{_data_id_tags}};
    print "Clustering for K = $K\n" if $self->{_terminal_output};
    my ($clusters, $cluster_centers);
    eval {
        ($clusters, $cluster_centers) = $self->cluster_for_given_K($K);
    };
    if ($@) {
        die "In cluster_for_fixed_K_single_smart_try:  insufficient data for clustering " .
            "with $self->{_K} clusters --- $@";
    }
    my $QoC = $self->cluster_quality( $clusters, $cluster_centers );
    $self->{_clusters} = $clusters;
    $self->{_cluster_centers} = $cluster_centers;  
    $self->{_QoC_values}->{"$K"} = $QoC; 
    if ($self->{_terminal_output}) {
        print "\nDisplaying final clusters for best K (= $K) :\n";
        display_clusters( $clusters );
        $self->display_cluster_centers( $clusters );
        print "\nQoC value (the smaller, the better): $QoC\n";
    }
}

# The following subroutine is the top-level routine to call if you want the system to
# figure out on its own what value to use for K, the number of clusters.  If you call
# the KMeans constructor with the K=0 option, the method below will try every
# possible value of K between 2 and the maximum possible depending on the number of
# data points available. For example, if the number of data points is 10,000, it will
# try all possible values of K between 2 and 70. For how the maximum value is set for
# K, see the comments made under Description.  Note also how this method makes 20
# different tries for each value of K as a defense against the problem of the final
# result corresponding to some local minimum in the values of the QoC metric.  Out of
# these 20 tries for each K, it retains the clusters and the cluster centers for only
# that try that yields the smallest value for the QoC metric.  After estimating the
# "best" QoC values for all possible K in this manner, it then finds the K for which
# the QoC is the minimum.  This is taken to be the best value for K.  Finally, the
# output clusters are written out to separate files.
#
# If the KMeans constructor is invoked with the (Kmin, Kmax) options, then, instead
# of iterating through 2 and the maximum permissible value for K, the iterations are
# carried out only between Kmin and Kmax.
sub iterate_through_K {
    my $self = shift;
    my @all_data_ids = @{$self->{_data_id_tags}};
    my $N = $self->{_N};
    croak "You need more than 8 data samples. The number of data points must satisfy " .
          "the relation N > 2xK**2 where K is the number of clusters.  The smallest " .
          "value for K is 2.\n"  if $N <= 8;
    my $K_statistical_max = int( sqrt( $N / 2.0 ) );
    my $Kmin = $self->{_K_min} eq 'unknown' 
                          ? 2
                          : $self->{_K_min};
    my $Kmax = $self->{_K_max} eq 'unknown' 
                          ? int( sqrt( $N / 2.0 ) )
                          : $self->{_K_max};
    croak  "\n\nYour Kmax value is too high.  Ideally, it should not exceed sqrt(N/2) " .
           "where N is the number of data points" if $Kmax > $K_statistical_max;
    print "Value of Kmax is: $Kmax\n" if $self->{_terminal_output};
    my @QoC_values;
    my @array_of_clusters;
    my @array_of_cluster_centers;
    foreach my $K ($Kmin..$Kmax) {
        my $QoC;
        my $clusters;
        my $cluster_centers;
        print "Clustering for K = $K\n" if $self->{_terminal_output};
        if ($self->{_cluster_seeding} eq 'random') {
            foreach my $trial (1..21) {
                print ". ";
                my ($new_clusters, $new_cluster_centers);
                if ($self->{_use_mahalanobis_metric}) {
                    eval {
                       ($new_clusters, $new_cluster_centers) = $self->cluster_for_given_K($K);
                    };
                    next if $@;
                } else {
                   ($new_clusters, $new_cluster_centers) = $self->cluster_for_given_K($K);
                }
                my $newQoC = $self->cluster_quality( $new_clusters, $new_cluster_centers );
                if ( (!defined $QoC) || ($newQoC < $QoC) ) {
                    $QoC = $newQoC;
                    $clusters = deep_copy_AoA( $new_clusters );
                    $cluster_centers = deep_copy_AoA( $new_cluster_centers );
                } 
            }
            print "\n";
        } elsif ($self->{_cluster_seeding} eq 'smart') {
            eval {
            ($clusters, $cluster_centers) = $self->cluster_for_given_K($K);
            };
            if ($@) {
                $Kmax = $K - 1;
                last;
            }
            $QoC = $self->cluster_quality($clusters,$cluster_centers);
        } else {
            die "You must either choose 'smart' for cluster_seeding or 'random'. " .
                "Fix your constructor call." 
        }
        push @QoC_values, $QoC;
        push @array_of_clusters, $clusters;
        push @array_of_cluster_centers, $cluster_centers;
    }
    my ($min, $max) = minmax( \@QoC_values );
    my $K_best_relative_to_Kmin = get_index_at_value($min, \@QoC_values );
    my $K_best = $K_best_relative_to_Kmin + $Kmin;
    if ($self->{_terminal_output}) {
        print "\nDisplaying final clusters for best K (= $K_best) :\n";
        display_clusters( $array_of_clusters[$K_best_relative_to_Kmin] );
        $self->display_cluster_centers($array_of_clusters[$K_best_relative_to_Kmin]);
        print "\nBest clustering achieved for K=$K_best with QoC = $min\n" if defined $min;
        my @printableQoC = grep {$_} @QoC_values;
        print "\nQoC values array (the smaller the value, the better it is) for different " . 
              "K starting with K=$Kmin:  @printableQoC\n";
    }
    $self->{_K_best} = $K_best;
    foreach my $i (0..@QoC_values-1) {
        my $k = $i + $Kmin;
        $self->{_QoC_values}->{"$k"} = $QoC_values[$i]; 
    }
    $self->{_clusters} = $array_of_clusters[$K_best_relative_to_Kmin];
    $self->{_cluster_centers} =  
                $array_of_cluster_centers[$K_best_relative_to_Kmin];
}

# This is the function to call if you already know what value you want to use for K,
# the number of expected clusters.  The purpose of this function is to do the
# initialization of the cluster centers and to carry out the initial assignment of
# the data to the clusters with the initial cluster centers.  The initialization
# consists of 3 steps: Construct a random sequence of K integers between 0 and N-1
# where N is the number of data points to be clustered; 2) Call
# get_initial_cluster_centers() to index into the data array with the random integers
# to get a list of K data points that would serve as the initial cluster centers; and
# (3) Call assign_data_to_clusters_initial() to assign the rest of the data to each
# of the K clusters on the basis of the proximity to the cluster centers.
sub cluster_for_given_K {
    my $self = shift;
    my $K = shift;
    my @all_data_ids = @{$self->{_data_id_tags}};
    my $cluster_centers;
    if ($self->{_cluster_seeding} eq 'smart') {
        $cluster_centers = $self->get_initial_cluster_centers_smart($K);
    } elsif ($self->{_cluster_seeding} eq 'random') {
        $cluster_centers = $self->get_initial_cluster_centers($K);
    } else {
        die "You must either choose 'smart' for cluster_seeding or 'random'. " .
            "Fix your constructor call." 
    }
    my $clusters;
    if ($self->{_use_mahalanobis_metric}) {
        my $clusters_and_determinants = 
                   $self->assign_data_to_clusters_initial_mahalanobis($cluster_centers);  
        $clusters = $clusters_and_determinants->[0];
        my @determinants = @{$clusters_and_determinants->[1]};
        my ($min,$max) = minmax(\@determinants);
        die "In cluster_for_given_K(): min determinant of covariance matrix for at " .
            "least one cluster is too small" if $min / $max < 0.001;
    } else {
        $clusters = $self->assign_data_to_clusters_initial($cluster_centers);  
    }
    my $cluster_nonexistent_flag = 0;
    foreach my $trial (0..2) {
        if ($self->{_use_mahalanobis_metric}) {
            ($clusters, $cluster_centers) = $self->assign_data_to_clusters_mahalanobis($clusters, $K);
        } else {
            ($clusters, $cluster_centers) = $self->assign_data_to_clusters( $clusters, $K );
        }
        my $num_of_clusters_returned = @$clusters;
        foreach my $cluster (@$clusters) {
            $cluster_nonexistent_flag = 1 if ((!defined $cluster) ||  (@$cluster == 0));
        }
        last unless $cluster_nonexistent_flag;
    }
    return ($clusters, $cluster_centers);
}

# This function is used when you set the "cluster_seeding" option to 'random' in the
# constructor.  Returns a set of K random integers.  These serve as indices to reach
# into the data array.  A data element whose index is one of the random numbers
# returned by this routine serves as an initial cluster center.  Note the quality
# check it runs on the list of K random integers constructed.  We first make sure
# that all K random integers are different.  Subsequently, we carry out a quality
# assessment of the K random integers constructed.  This quality measure consists of
# the ratio of the values spanned by the random integers to the value of N, the total
# number of data points to be clustered.  Currently, if this ratio is less than 0.3,
# we discard the K integers and try again.
sub initialize_cluster_centers {
    my $self = shift;
    my $K = shift;
    my $data_store_size = $self->{_N};
    my @cluster_center_indices;
    while (1) {
        foreach my $i (0..$K-1) {
            $cluster_center_indices[$i] = int rand( $data_store_size );
            next if $i == 0;
            foreach my $j (0..$i-1) {
                while ( $cluster_center_indices[$j] == 
                        $cluster_center_indices[$i] ) {
                    my $old = $cluster_center_indices[$i];
                    $cluster_center_indices[$i] = int rand($data_store_size);
                }
            }
        }
        my ($min,$max) = minmax(\@cluster_center_indices );
        my $quality = ($max - $min) / $data_store_size;
        last if $quality > 0.3;
    }
    return @cluster_center_indices;
}

# This function is used when you set the "cluster_seeding" option to 'random' in the
# constructor.  This routine merely reaches into the data array with the random
# integers, as constructed by the previous routine, serving as indices and fetching
# values corresponding to those indices.  The fetched data samples serve as the
# initial cluster centers.
sub get_initial_cluster_centers {
    my $self = shift;
    my $K = shift;
    my @cluster_center_indices = $self->initialize_cluster_centers($K);
    my @result;
    foreach my $i (@cluster_center_indices) {    
        my $tag = $self->{_data_id_tags}[$i];     
        push @result, $self->{_data}->{$tag};
    }
    return \@result;
}

# This method is invoked when you choose the 'smart' option for the "cluster_seeding"
# option in the constructor.  It subjects the data to a principal components analysis
# to figure out the direction of maximal variance.  Subsequently, it tries to locate
# K peaks in a smoothed histogram of the data points projected onto the maximal
# variance direction.
sub get_initial_cluster_centers_smart {
    my $self = shift;
    my $K = shift;
    if ($self->{_data_dimensions} == 1) {
        my @one_d_data;
        foreach my $j (0..$self->{_N}-1) {
            my $tag = $self->{_data_id_tags}[$j];     
            push @one_d_data, $self->{_data}->{$tag}->[0];
        }
        my @peak_points = find_peak_points_in_given_direction(\@one_d_data,$K);
        print "highest points at data values: @peak_points\n" if $self->{_debug};
        my @cluster_centers;
        foreach my $peakpoint (@peak_points) {
            push @cluster_centers, [$peakpoint];
        }
        return \@cluster_centers;
    }
    my ($num_rows,$num_cols) = ($self->{_data_dimensions},$self->{_N});
    my $matrix = Math::GSL::Matrix->new($num_rows,$num_cols);
    my $mean_vec = Math::GSL::Matrix->new($num_rows,1);
    # All the record labels are stored in the array $self->{_data_id_tags}.  The
    # actual data for clustering is stored in a hash at $self->{_data} whose keys are
    # the record labels; the value associated with each key is the array holding the
    # corresponding numerical multidimensional data.
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
        $largest_eigen_index = $i if $eigenvalues->[$i] > $eigenvalues->[$largest_eigen_index];
        $smallest_eigen_index = $i if $eigenvalues->[$i] < $eigenvalues->[$smallest_eigen_index];
        print "Eigenvalue $i:   $eigenvalues->[$i]\n" if $self->{_debug};
    }
    print "\nlargest eigen index: $largest_eigen_index\n" if $self->{_debug};
    print "\nsmallest eigen index: $smallest_eigen_index\n\n" if $self->{_debug};
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
            die "eigendecomposition of covariance matrix produced a complex " .
                "eigenvector --- something is wrong";
        }
    }
    print "\nMaximum Variance Direction: @max_var_direction\n\n" if $self->{_debug};
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
    print "highest points at points along largest eigenvec: @peak_points\n" if $self->{_debug};
    my @cluster_centers;
    foreach my $peakpoint (@peak_points) {
        my @actual_peak_coords = map {$peakpoint * $_} @max_var_direction;
        push @cluster_centers, \@actual_peak_coords;
    }
    return \@cluster_centers;
}

# This method is invoked when you choose the 'smart' option for the "cluster_seeding"
# option in the constructor.  It is called by the previous method to locate K peaks
# in a smoothed histogram of the data points projected onto the maximal variance
# direction.
sub find_peak_points_in_given_direction {
    my $dataref = shift;
    my $how_many = shift;
    my @data = @$dataref;
    my ($min, $max) = minmax(\@data);
    my $num_points = @data;
    my @sorted_data = sort {$a <=> $b} @data;
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
    my @accumulator = (0) x 1000;
    foreach my $index (0..@sorted_data-1) {
        my $cell_index = int($sorted_data[$index] / $delta);
        my $smoothness = 40;
        for my $index ($cell_index-$smoothness..$cell_index+$smoothness) {
            next if $index < 0 || $index > 999;
            $accumulator[$index]++;
        }
    }
    my $peaks_array = non_maximum_suppression( \@accumulator );
    my $peaks_index_hash = get_value_index_hash( $peaks_array );
    my @K_highest_peak_locations;
    my $k = 0;
    foreach my $peak (sort {$b <=> $a} keys %$peaks_index_hash) {
        my $unscaled_peak_point = $min + $peaks_index_hash->{$peak} * $scale * $delta;
        push @K_highest_peak_locations, $unscaled_peak_point
            if $k < $how_many;
        last if ++$k == $how_many;
    }
    return @K_highest_peak_locations;
}

# The purpose of this routine is to form initial clusters by assigning the data
# samples to the initial clusters formed by the previous routine on the basis of the
# best proximity of the data samples to the different cluster centers.
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

sub assign_data_to_clusters_initial_mahalanobis {
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
        push @{$clusters[$best_center_index]}, $ele if defined $best_center_index;
    }
    # Since a cluster center may not correspond to any particular sample, it is possible
    # for one of the elements of the array @clusters to be null using the above 
    # strategy for populating the initial clusters.  Let's say there are five cluster
    # centers in the array @cluster_centers.  The $best_center_index may populate the
    # the elements of the array @clusters for the indices 0, 1, 2, 4, which would leave
    # $clusters[3] as undefined.  So, in what follows, we must first check if all of
    # the elements of @clusters are defined.
    my @determinants;
    foreach my $cluster(@clusters) {
        die "The clustering program started with bad initialization.  Please start over" 
            unless defined $cluster;
        my $covariance = $self->estimate_cluster_covariance($cluster);
        my $determinant = $covariance->det();
        push @determinants, $determinant;
    }
    return [\@clusters, \@determinants];
}    

# This is the main routine that along with the update_cluster_centers() routine
# constitute the two key steps of the K-Means algorithm.  In most cases, the infinite
# while() loop will terminate automatically when the cluster assignments of the data
# points remain unchanged. For the sake of safety, we keep track of the number of
# iterations. If this number reaches 100, we exit the while() loop anyway.  In most
# cases, this limit will not be reached.
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
        my $cluster_centers = $self->update_cluster_centers( deep_copy_AoA_with_nulls( $clusters ) );
        $iteration_index++;
        foreach my $cluster (@$clusters) {
            my $current_cluster_center = $cluster_centers->[$current_cluster_center_index];
            foreach my $ele (@$cluster) {
                my @dist_from_clust_centers;
                foreach my $center (@$cluster_centers) {
                    push @dist_from_clust_centers, 
                               $self->distance($ele, $center);
                }
                my ($min, $best_center_index) = minimum( \@dist_from_clust_centers );
                my $best_cluster_center = $cluster_centers->[$best_center_index];
                if (vector_equal($current_cluster_center, $best_cluster_center)){
                    push @{$new_clusters->[$current_cluster_center_index]}, $ele;
                } else {
                    $assignment_changed_flag = 1;             
                    push @{$new_clusters->[$best_center_index]}, $ele;
                }
            }
            $current_cluster_center_index++;
        }
        next if ((@$new_clusters != @$clusters) && ($iteration_index < 100));
        # Now make sure that none of the K clusters is an empty cluster:
        foreach my $newcluster (@$new_clusters) {
            $cluster_size_zero_condition = 1 if ((!defined $newcluster) or  (@$newcluster == 0));
        }
        push @$new_clusters, (undef) x ($K - @$new_clusters) if @$new_clusters < $K;
        # During clustering for a fixed K, should a cluster inadvertently
        # become empty, steal a member from the largest cluster to hopefully
        # spawn a new cluster:
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
	$clusters = deep_copy_AoA( $new_clusters );
        last if $assignment_changed_flag == 0;
    }
    $final_cluster_centers = $self->update_cluster_centers( $clusters );
    return ($clusters, $final_cluster_centers);
}

sub assign_data_to_clusters_mahalanobis {
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
        my $cluster_centers_and_covariances = 
        $self->update_cluster_centers_and_covariances_mahalanobis(deep_copy_AoA_with_nulls($clusters));
        my $cluster_centers = $cluster_centers_and_covariances->[0];
        my $cluster_covariances = $cluster_centers_and_covariances->[1];
        $iteration_index++;
        foreach my $cluster (@$clusters) {
            my $current_cluster_center = $cluster_centers->[$current_cluster_center_index];
            my $current_cluster_covariance = $cluster_covariances->[$current_cluster_center_index]; 
            foreach my $ele (@$cluster) {
                my @mahalanobis_dist_from_clust_centers;
                foreach my $i (0..@$clusters-1) {
                    my $center = $cluster_centers->[$i];
                    my $covariance = $cluster_covariances->[$i];
                    my $maha_distance;
                    eval {
                        $maha_distance = $self->distance_mahalanobis($ele, $center, $covariance);
                    };
                    next if $@;
                    push @mahalanobis_dist_from_clust_centers, $maha_distance; 
                }
                my ($min, $best_center_index) = minimum( \@mahalanobis_dist_from_clust_centers );
                die "The Mahalanobis metric may not be appropriate for the data" 
                    unless defined $best_center_index;
                my $best_cluster_center = $cluster_centers->[$best_center_index];
                if (vector_equal($current_cluster_center, $best_cluster_center)){
                    push @{$new_clusters->[$current_cluster_center_index]}, $ele;
                } else {
                    $assignment_changed_flag = 1;             
                    push @{$new_clusters->[$best_center_index]}, $ele;
                }
            }
            $current_cluster_center_index++;
        }
        next if ((@$new_clusters != @$clusters) && ($iteration_index < 100));
        # Now make sure that none of the K clusters is an empty cluster:
        foreach my $newcluster (@$new_clusters) {
            $cluster_size_zero_condition = 1 if ((!defined $newcluster) or  (@$newcluster == 0));
        }
        push @$new_clusters, (undef) x ($K - @$new_clusters) if @$new_clusters < $K;
        # During clustering for a fixed K, should a cluster inadvertently
        # become empty, steal a member from the largest cluster to hopefully
        # spawn a new cluster:
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

sub update_cluster_centers_and_covariances_mahalanobis {
    my $self = shift;
    my @clusters = @{ shift @_ };
    my @new_cluster_centers;
    my @new_cluster_covariances;
    # During clustering for a fixed K, should a cluster inadvertently become empty,
    # steal a member from the largest cluster to hopefully spawn a new cluster:
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
            "for a given K.  Try again. \n" if !defined $cluster;
        my $cluster_size = @$cluster;
        die "Cluster size is zero --- untenable.\n" if $cluster_size == 0;
        my @new_cluster_center = @{$self->add_point_coords( $cluster )};
        @new_cluster_center = map {my $x = $_/$cluster_size; $x} @new_cluster_center;
        push @new_cluster_centers, \@new_cluster_center;
        # for covariance calculation:
        my ($num_rows,$num_cols) = ($self->{_data_dimensions}, scalar(@$cluster));
        my $matrix = Math::GSL::Matrix->new($num_rows,$num_cols);
        my $mean_vec = Math::GSL::Matrix->new($num_rows,1);
        # All the record labels are stored in the array $self->{_data_id_tags}.  The
        # actual data for clustering is stored in a hash at $self->{_data} whose keys are
        # the record labels; the value associated with each key is the array holding the
        # corresponding numerical multidimensional data.
        foreach my $j (0..$num_cols-1) {
            my $tag = $cluster->[$j];            
            my $data = $self->{_data}->{$tag};
            my @diff_from_mean = vector_subtract($data, \@new_cluster_center);
            $matrix->set_col($j, \@diff_from_mean);
        }
        my $transposed = transpose( $matrix );
        my $covariance = matrix_multiply( $matrix, $transposed );
        $covariance *= 1.0 / $num_cols;
        if ($self->{_debug}) {
            print "\nDisplaying the Covariance Matrix for cluster:";
            display_matrix( $covariance );
        }
        push @new_cluster_covariances, $covariance;
    }
    return [\@new_cluster_centers, \@new_cluster_covariances];
}

# After each new assignment of the data points to the clusters on the basis of the
# current values for the cluster centers, we call the routine shown here for updating
# the values of the cluster centers.
sub update_cluster_centers {
    my $self = shift;
    my @clusters = @{ shift @_ };
    my @new_cluster_centers;
    # During clustering for a fixed K, should a cluster inadvertently become empty,
    # steal a member from the largest cluster to hopefully spawn a new cluster:
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
            "for a given K.  Try again. \n" if !defined $cluster;
        my $cluster_size = @$cluster;
        die "Cluster size is zero --- untenable.\n" if $cluster_size == 0;
        my @new_cluster_center = @{$self->add_point_coords( $cluster )};
        @new_cluster_center = map {my $x = $_/$cluster_size; $x} 
                                  @new_cluster_center;
        push @new_cluster_centers, \@new_cluster_center;
    }        
    return \@new_cluster_centers;
}

sub which_cluster_for_new_data_element {
    my $self = shift;
    my $ele = shift;
    die "The dimensionality of the new data element is not correct: $!"
        unless @$ele == $self->{_data_dimensions};
    my %distance_to_new_ele_hash;
    foreach my $cluster_id (sort keys %{$self->{_cluster_centers_hash}}) {
        $distance_to_new_ele_hash{$cluster_id} = $self->distance2($ele, 
                                             $self->{_cluster_centers_hash}->{$cluster_id});
    }
    my @values = values %distance_to_new_ele_hash;
    my ($min,$max) = minmax(\@values);
    my $answer;
    foreach my $cluster_id (keys %distance_to_new_ele_hash) {
        $answer = $cluster_id if $distance_to_new_ele_hash{$cluster_id} == $min;
    }
    return $answer;
}

sub which_cluster_for_new_data_element_mahalanobis {
    my $self = shift;
    my $ele = shift;
    die "The dimensionality of the new data element is not correct: $!"
        unless @$ele == $self->{_data_dimensions};
    my %distance_to_new_ele_hash;
    foreach my $cluster_id (sort keys %{$self->{_cluster_centers_hash}}) {
        $distance_to_new_ele_hash{$cluster_id} = 
                $self->distance_mahalanobis2($ele, $self->{_cluster_centers_hash}->{$cluster_id},
                                             $self->{_cluster_covariances_hash}->{$cluster_id});
    }
    my @values = values %distance_to_new_ele_hash;
    my ($min,$max) = minmax(\@values);
    my $answer;
    foreach my $cluster_id (keys %distance_to_new_ele_hash) {
        $answer = $cluster_id if $distance_to_new_ele_hash{$cluster_id} == $min;
    }
    return $answer;
}

# The following function returns the value of QoC for a given partitioning of the
# data into K clusters.  It calculates two things: the average value for the distance
# between a data point and the center of the cluster in which the data point resides,
# and the average value for the distances between the cluster centers.  We obviously
# want to minimize the former and maximize the latter.  All of the "from center"
# distances within each cluster are stored in the variable
# $sum_of_distances_for_one_cluster.  When this variable, after it is divided by the
# number of data elements in the cluster, is summed over all the clusters, we get a
# value that is stored in $avg_dist_for_cluster.  The inter-cluster-center distances
# are stored in the variable $inter_cluster_center_dist.
sub cluster_quality {
    my $self = shift;
    my $clusters = shift;
    my $cluster_centers = shift;
    my $K = @$cluster_centers;          # Number of clusters
    my $cluster_radius = 0;
    foreach my $i (0..@$clusters-1) {
        my $sum_of_distances_for_one_cluster = 0;
        foreach my $ele (@{$clusters->[$i]}) {
            $sum_of_distances_for_one_cluster += 
                $self->distance( $ele, $cluster_centers->[$i] );
        }
       $cluster_radius += 
           $sum_of_distances_for_one_cluster / @{$clusters->[$i]};
    }
    my $inter_cluster_center_dist = 0;
    foreach my $i (0..@$cluster_centers-1) {
        foreach my $j (0..@$cluster_centers-1) {
            $inter_cluster_center_dist += 
              $self->distance2( $cluster_centers->[$i], 
                                $cluster_centers->[$j] );
        }
    }
    my $avg_inter_cluster_center_dist = $inter_cluster_center_dist /
                    ( $K * ($K-1) / 2.0 );
    return $cluster_radius / $avg_inter_cluster_center_dist;
}

# The following routine is for computing the distance between a data point specified
# by its symbolic name in the master datafile and a point (such as the center of a
# cluster) expressed as a vector of coordinates:
sub distance {
    my $self = shift;
    my $ele1_id = shift @_;            # symbolic name of data sample
    my @ele1 = @{$self->{_data}->{$ele1_id}};
    my @ele2 = @{shift @_};
    die "wrong data types for distance calculation\n" if @ele1 != @ele2;
    my $how_many = @ele1;
    my $squared_sum = 0;
    foreach my $i (0..$how_many-1) {
        $squared_sum += ($ele1[$i] - $ele2[$i])**2;
    }    
    my $dist = sqrt $squared_sum;
    return $dist;
}

# The following routine does the same as above but now both arguments are expected to
# be arrays of numbers:
sub distance2 {
    my $self = shift;
    my @ele1 = @{shift @_};
    my @ele2 = @{shift @_};
    die "wrong data types for distance calculation\n" if @ele1 != @ele2;
    my $how_many = @ele1;
    my $squared_sum = 0;
    foreach my $i (0..$how_many-1) {
        $squared_sum += ($ele1[$i] - $ele2[$i])**2;
    }    
    return sqrt $squared_sum;
}

# Requires three args: $ele for the symbolic tag of the element, $center for the
# coordinates of the center of the cluster, and $covariance for the covariance of
# cluster.  Our goal is to find the distance of the element ele from the cluster
# whose mean and covariance are provided.
sub distance_mahalanobis {
    my $self = shift;
    my $ele = shift;
    my $cluster_center = shift;
    my $cluster_covariance = shift;
    my $det_of_covar = $cluster_covariance->det();
    my $ele_data = $self->{_data}->{$ele};
    my @diff_from_mean = vector_subtract($ele_data, $cluster_center);
    my $vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
    $vec->set_col(0, \@diff_from_mean);
    my $transposed = transpose( $vec );
    my $covariance_inverse;
    if ($cluster_covariance->det() > 0.001) {
        $covariance_inverse = $cluster_covariance->inverse;
    } else {
        die "covariance matrix may not have an inverse";
    }
    my $determinant = $covariance_inverse->det();
    my $distance = $transposed * $covariance_inverse * $vec;
    my @distance = $distance->as_list;
    $distance = $distance[0];
    return sqrt $distance;
}
# Same as the previous method except that the first argument can be the actual
# coordinates of the data element.  Our goal is to find the Mahalanobis distance
# from a given data element to a cluster whose center and covariance are known.  As
# for the previous method, it requires three arguments.
sub distance_mahalanobis2 {
    my $self = shift;
    my $ele = shift;              # is now a ref to the array of coords for a point
    my $cluster_center = shift;
    my $cluster_covariance = shift;
    return undef unless defined $cluster_covariance;
    my $det_of_covar = $cluster_covariance->det();
    my @diff_from_mean = vector_subtract($ele, $cluster_center);
    my $vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
    $vec->set_col(0, \@diff_from_mean);
    my $transposed = transpose( $vec );
    my $covariance_inverse;
    if ($cluster_covariance->det() > 0.001) {
        $covariance_inverse = $cluster_covariance->inverse;
    } else {
        die "covariance matrix may not have an inverse";
    }
    my $determinant = $covariance_inverse->det();
    my $distance = $transposed * $covariance_inverse * $vec;
    my @distance = $distance->as_list;
    $distance = $distance[0];
    return sqrt $distance;
}

sub estimate_cluster_covariance {
    my $self = shift;
    my $cluster = shift;
    my $cluster_size = @$cluster;
    my @cluster_center = @{$self->add_point_coords( $cluster )};
    @cluster_center = map {my $x = $_/$cluster_size; $x} @cluster_center;
    # for covariance calculation:
    my ($num_rows,$num_cols) = ($self->{_data_dimensions}, scalar(@$cluster));
    my $matrix = Math::GSL::Matrix->new($num_rows,$num_cols);
    my $mean_vec = Math::GSL::Matrix->new($num_rows,1);
    # All the record labels are stored in the array $self->{_data_id_tags}.  The
    # actual data for clustering is stored in a hash at $self->{_data} whose keys are
    # the record labels; the value associated with each key is the array holding the
    # corresponding numerical multidimensional data.
    foreach my $j (0..$num_cols-1) {
        my $tag = $cluster->[$j];            
        my $data = $self->{_data}->{$tag};
        my @diff_from_mean = vector_subtract($data, \@cluster_center);
        $matrix->set_col($j, \@diff_from_mean);
    }
    my $transposed = transpose( $matrix );
    my $covariance = $matrix * $transposed;
    $covariance *= 1.0 / $num_cols;
    if ($self->{_debug}) {
        print "\nDisplaying the Covariance Matrix for cluster:";
        display_matrix( $covariance );
    }
    return $covariance;
}

sub write_clusters_to_files {
    my $self = shift;
    my @clusters = @{$self->{_clusters}};
    unlink glob "cluster*.dat";
    foreach my $i (0..@clusters-1) {
        my $filename = "cluster" . $i . ".txt";
        print "\nWriting cluster $i to file $filename\n" if $self->{_terminal_output};
        open FILEHANDLE, "| sort > $filename"  or die "Unable to open file: $!";
        foreach my $ele (@{$clusters[$i]}) {        
            print FILEHANDLE "$ele ";
        }
        close FILEHANDLE;
    }
}

sub get_K_best {
    my $self = shift;
    croak "You need to run the clusterer with K=0 option " .
          "before you can call this method" if $self->{_K_best} eq 'unknown';
    print "\nThe best value of K: $self->{_K_best}\n" if $self->{_terminal_output};
    return $self->{_K_best};
}

sub show_QoC_values {
    my $self = shift;
    croak "\nYou need to run the clusterer with K=0 option before you can call this method" 
                            if $self->{_K_best} eq 'unknown';
    print "\nShown below are K on the left and the QoC values on the right (the smaller " .
          "the QoC, the better it is)\n";
    foreach my $key (sort keys %{$self->{_QoC_values}} ) {
        print " $key  =>  $self->{_QoC_values}->{$key}\n" if defined $self->{_QoC_values}->{$key};
    }
}

sub DESTROY {
    unlink "__temp_" . basename($_[0]->{_datafile});
    unlink "__temp_data_" . basename($_[0]->{_datafile});
    unlink "__temp_normed_data_" . basename($_[0]->{_datafile});
}

##################################  Visualization Code ###################################

#  It makes sense to call visualize_clusters() only AFTER you have called kmeans().
#
#  The visualize_clusters() implementation automatically figures out whether it
#  should do a 2D plot or a 3D plot.  If the number of on bits in the mask that is
#  supplied as one of the arguments is greater than 2, it does a 3D plot for the
#  first three data coordinates.  That is, the clusters will be displayed in the 3D
#  space formed by the first three data coordinates. On the other hand, if the number
#  of on bits in the mask is exactly 2, it does a 2D plot.  Should it happen that
#  only one on bit is specified for the mask, visualize_clusters() aborts.
#
#  The visualization code consists of first accessing each of clusters created by the
#  kmeans() subroutine.  Note that the clusters contain only the symbolic names for
#  the individual records in the source data file.  We therefore next reach into the
#  $self->{_original_data} hash and get the data coordinates associated with each
#  symbolic label in a cluster.  The numerical data thus generated is then written
#  out to a temp file.  When doing so we must remember to insert TWO BLANK LINES
#  between the data blocks corresponding to the different clusters.  This constraint
#  is imposed on us by Gnuplot when plotting data from the same file since we want to
#  use different point styles for the data points in different cluster files.
#
#  Subsequently, we call upon the Perl interface provided by the Graphics::GnuplotIF
#  module to plot the data clusters.
sub visualize_clusters {
    my $self = shift;
    my $v_mask;
    my $pause_time;
    if (@_ == 1) {
        $v_mask = shift || croak "visualization mask missing";
    } elsif (@_ == 2) {
        $v_mask = shift || croak "visualization mask missing";    
        $pause_time = shift;
    } else {
        croak "visualize_clusters() called with wrong args";
    }
    my $master_datafile = $self->{_datafile};
    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    croak "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    my %visualization_data;
    while ( my ($record_id, $data) = each %{$self->{_original_data}} ) {
        my @fields = @$data;
        croak "\nABORTED: Visualization mask size exceeds data record size\n" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                croak "Misformed visualization mask. It can only have 1s and 0s\n";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my @all_data_ids = @{$self->{_data_id_tags}};
    my $K = scalar @{$self->{_clusters}};
    my $filename = basename($master_datafile);
    my $temp_file = "__temp_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!\n";
    foreach my $cluster (@{$self->{_clusters}}) {
        foreach my $item (@$cluster) {
            print OUTPUT "@{$visualization_data{$item}}";
            print OUTPUT "\n";
        }
        print OUTPUT "\n\n";
    }
    close OUTPUT;
    my $plot;
    my $hardcopy_plot;
    if (!defined $pause_time) {
        $plot = Graphics::GnuplotIF->new( persist => 1 );
        $hardcopy_plot = Graphics::GnuplotIF->new();
        $hardcopy_plot->gnuplot_cmd('set terminal png', "set output \"clustering_results.png\"");
    } else {
        $plot = Graphics::GnuplotIF->new();
    }
    $plot->gnuplot_cmd( "set noclip" );
    $plot->gnuplot_cmd( "set pointsize 2" );
    my $arg_string = "";
    if ($visualization_data_field_width > 2) {
        foreach my $i (0..$K-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"Cluster $i\" with points lt $j pt $j, ";
        }
    } elsif ($visualization_data_field_width == 2) {
        foreach my $i (0..$K-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1:2 title \"Cluster $i\" with points lt $j pt $j, ";
        }
    } elsif ($visualization_data_field_width == 1 ) {
        foreach my $i (0..$K-1) {
            my $j = $i + 1;
            $arg_string .= "\"$temp_file\" index $i using 1 title \"Cluster $i\" with points lt $j pt $j, ";
        }
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "splot $arg_string" );
        $hardcopy_plot->gnuplot_cmd( "splot $arg_string" ) unless defined $pause_time;
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "plot $arg_string" );
        $hardcopy_plot->gnuplot_cmd( "plot $arg_string" ) unless defined $pause_time;
        $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
    } elsif ($visualization_data_field_width == 1) {
        croak "No provision for plotting 1-D data\n";
    }
}

#  It makes sense to call visualize_data() only AFTER you have called the method
#  read_data_from_file().
#
#  The visualize_data() is meant for the visualization of the original data in its
#  various 2D or 3D subspaces.  The method can also be used to visualize the normed
#  data in a similar manner.  Recall the normed data is the original data after each
#  data dimension is normalized by the standard-deviation along that dimension.
#
#  Whether you see the original data or the normed data depends on the second
#  argument supplied in the method call.  It must be either the string 'original' or
#  the string 'normed'.
sub visualize_data {
    my $self = shift;
    my $v_mask = shift || croak "visualization mask missing";
    my $datatype = shift;    # must be either 'original' or 'normed'
    croak "\n\nABORTED: You called visualize_data() for normed data " .
          "but without first turning on data normalization in the " .
          "in the KMeans constructor"
          if ($datatype eq 'normed') && ! $self->{_var_normalize}; 
    my $master_datafile = $self->{_datafile};
    my @v_mask = split //, $v_mask;
    my $visualization_mask_width = @v_mask;
    my $original_data_mask = $self->{_mask};
    my @mask = split //, $original_data_mask;
    my $data_field_width = scalar grep {$_ eq '1'} @mask;    
    croak "\n\nABORTED: The width of the visualization mask (including " .
          "all its 1s and 0s) must equal the width of the original mask " .
          "used for reading the data file (counting only the 1's)"
          if $visualization_mask_width != $data_field_width;
    my $visualization_data_field_width = scalar grep {$_ eq '1'} @v_mask;
    my %visualization_data;
    my $data_source;
    if ($datatype eq 'original') {
        $data_source  =  $self->{_original_data};
    } elsif ($datatype eq 'normed') {
        $data_source  =  $self->{_data};
    } else {
        croak "\n\nABORTED: improper call to visualize_data()";
    }
    while ( my ($record_id, $data) = each %{$data_source} ) {
        my @fields = @$data;
        croak "\nABORTED: Visualization mask size exceeds data record size\n" 
            if $#v_mask > $#fields;
        my @data_fields;
        foreach my $i (0..@fields-1) {
            if ($v_mask[$i] eq '0') {
                next;
            } elsif ($v_mask[$i] eq '1') {
                push @data_fields, $fields[$i];
            } else {
                croak "Misformed visualization mask. It can only have 1s and 0s\n";
            }
        }
        $visualization_data{ $record_id } = \@data_fields;
    }
    my $filename = basename($master_datafile);
    my $temp_file;
    if ($datatype eq 'original') {
        $temp_file = "__temp_data_" . $filename;
    } elsif ($datatype eq 'normed') {
        $temp_file = "__temp_normed_data_" . $filename;
    } else {
        croak "ABORTED: Improper call to visualize_data()";
    }
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!\n";
    foreach my $datapoint (values %visualization_data) {
        print OUTPUT "@$datapoint";
        print OUTPUT "\n";
    }
    close OUTPUT;
    my $plot = Graphics::GnuplotIF->new( persist => 1 );
    $plot->gnuplot_cmd( "set noclip" );
    $plot->gnuplot_cmd( "set pointsize 2" );
    my $plot_title =  $datatype eq 'original' ? '"data"' : '"normed data"';
    my $arg_string ;
    if ($visualization_data_field_width > 2) {
        $arg_string = "\"$temp_file\" using 1:2:3 title $plot_title with points lt -1 pt 1";
    } elsif ($visualization_data_field_width == 2) {
        $arg_string = "\"$temp_file\" using 1:2 title $plot_title with points lt -1 pt 1";
    } elsif ($visualization_data_field_width == 1 ) {
        $arg_string = "\"$temp_file\" using 1 notitle with points lt -1 pt 1";
    }
    if ($visualization_data_field_width > 2) {
        $plot->gnuplot_cmd( "splot $arg_string" );
    } elsif ($visualization_data_field_width == 2) {
        $plot->gnuplot_cmd( "plot $arg_string" );
    } elsif ($visualization_data_field_width == 1) {
        croak "No provision for plotting 1-D data\n";
    }
}

###########################  Generating Synthetic Data for Clustering  ##############################

#  The data generated corresponds to a multivariate distribution.  The mean and the
#  covariance of each Gaussian in the distribution are specified individually in a
#  parameter file.  See the example parameter file param.txt in the examples
#  directory.  Just edit this file for your own needs.
#
#  The multivariate random numbers are generated by calling the Math::Random module.
#  As you would expect, that module will insist that the covariance matrix you
#  specify be symmetric and positive definite.
sub cluster_data_generator {
    my $class = shift;
    croak "illegal call of a class method" unless $class eq 'Algorithm::KMeans';
    my %args = @_;
    my $input_parameter_file = $args{input_parameter_file};
    my $output_file = $args{output_datafile};
    my $N = $args{number_data_points_per_cluster};
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
        $param_string = "cluster 5 0 0  1 0 0 0 1 0 0 0 1 " .
                        "cluster 0 5 0  1 0 0 0 1 0 0 0 1 " .
                        "cluster 0 0 5  1 0 0 0 1 0 0 0 1";
    }
    my @cluster_strings = split /[ ]*cluster[ ]*/, $param_string;
    @cluster_strings = grep  $_, @cluster_strings;
    my $K = @cluster_strings;
    croak "Too many clusters requested" if $K > 12;
    my @point_labels = ('a'..'z');
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
    random_seed_from_phrase( 'hellojello' );
    my @data_dump;
    foreach my $i (0..$K-1) {
        my @m = @{shift @means};
        my @covar = @{shift @covariances};
        my @new_data = Math::Random::random_multivariate_normal( $N, @m, @covar );
        my $p = 0;
        my $label = $point_labels[$i];
        @new_data = map {unshift @$_, $label.$i; $i++; $_} @new_data;
        push @data_dump, @new_data;     
    }
    fisher_yates_shuffle( \@data_dump );
    open OUTPUT, ">$output_file";
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

sub add_point_coords_from_original_data {
    my $self = shift;
    my @arr_of_ids = @{shift @_};      # array of data element names
    my @result;
    my $data_dimensionality = $self->{_data_dimensions};
    foreach my $i (0..$data_dimensionality-1) {
        $result[$i] = 0.0;
    }
    foreach my $id (@arr_of_ids) {
        my $ele = $self->{_original_data}->{$id};
        my $i = 0;
        foreach my $component (@$ele) {
            $result[$i] += $component;
            $i++;
        }
    }
    return \@result;
}

###################################   Support Routines  ########################################

sub get_index_at_value {
    my $value = shift;
    my @array = @{shift @_};
    foreach my $i (0..@array-1) {
        return $i if $value == $array[$i];
    }
    return -1;
}

# This routine is really not necessary in light of the new `~~' operator in Perl.
# Will use the new operator in the next version.
sub vector_equal {
    my $vec1 = shift;
    my $vec2 = shift;
    die "wrong data types for vector-equal predicate\n" if @$vec1 != @$vec2;
    foreach my $i (0..@$vec1-1){
        return 0 if $vec1->[$i] != $vec2->[$i];
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
        next if !defined $arr->[$i];
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

# Meant only for constructing a deep copy of an array of arrays:
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

sub display_cluster_centers {
    my $self = shift;
    my @clusters = @{shift @_};
    my $i = 0;
    foreach my $cluster (@clusters) {
        my $cluster_size = @$cluster;
        my @cluster_center = 
            @{$self->add_point_coords_from_original_data( $cluster )};
        @cluster_center = map {my $x = $_/$cluster_size; $x} @cluster_center;
        print "\ncluster $i ($cluster_size records):\n";
        print "cluster center $i: " .
               "@{[map {my $x = sprintf('%.4f', $_); $x} @cluster_center]}\n";
        $i++;
    }
}

# For displaying the individual clusters on a terminal screen.  Each cluster is
# displayed through the symbolic names associated with the data points.
sub display_clusters {
    my @clusters = @{shift @_};
    my $i = 0;
    foreach my $cluster (@clusters) {
        @$cluster = sort @$cluster;
        my $cluster_size = @$cluster;
        print "\n\nCluster $i ($cluster_size records):\n";
        foreach my $ele (@$cluster) {
            print "  $ele";
        }
        $i++
    }
    print "\n\n";
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

sub variance_normalization {
    my %data_hash = %{shift @_};
    my @all_data_points = values %data_hash;
    my $dimensions = @{$all_data_points[0]};
    my @data_projections;
    foreach my $data_point (@all_data_points) {
        my $i = 0;
        foreach my $proj (@$data_point) {
            push @{$data_projections[$i++]}, $proj;
        }
    }
    my @variance_vec;
    foreach my $vec (@data_projections) {
        my ($mean, $variance) = mean_and_variance( $vec );
        push @variance_vec, $variance;
    }
    my %new_data_hash;
    while (my ($label, $data) = each(%data_hash) ) {
        my @new_data;
        foreach my $i (0..@{$data}-1) {
            my $new = $data->[$i] / sqrt($variance_vec[$i]);
            push @new_data, $data->[$i] / sqrt($variance_vec[$i]);
        }
        $new_data_hash{$label} = \@new_data;
    }
    return \%new_data_hash;
}

sub mean_and_variance {
    my @data = @{shift @_};
    my ($mean, $variance);
    foreach my $i (1..@data) {
        if ($i == 1) {
            $mean = $data[0];
            $variance = 0;
        } else {
            $mean = ( (($i-1)/$i) * $mean ) + $data[$i-1] / $i;
            $variance = ( (($i-1)/$i) * $variance )  + ($data[$i-1]-$mean)**2 / ($i-1);
        }
    }
    return ($mean, $variance);
}

sub check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / datafile
                            mask
                            K
                            Kmin
                            Kmax
                            terminal_output
                            write_clusters_to_files
                            do_variance_normalization
                            cluster_seeding
                            use_mahalanobis_metric
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

sub non_maximum_suppression {
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
    my $matrix = shift;
    my $nrows = $matrix->rows();
    my $ncols = $matrix->cols();
    print "\n\nDisplaying matrix of size $nrows rows and $ncols columns:\n";
    foreach my $i (0..$nrows-1) {
        my $row = $matrix->row($i);
        my @row_as_list = $row->as_list;
        print "@row_as_list\n";
    }
    print "\n\n";
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

sub vector_subtract {
    my $vec1 = shift;
    my $vec2 = shift;
    die "wrong data types for vector subtract calculation\n" if @$vec1 != @$vec2;
    my @result;
    foreach my $i (0..@$vec1-1){
        push @result, $vec1->[$i] - $vec2->[$i];
    }
    return @result;
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

sub matrix_multiply {
    my $matrix1 = shift;
    my $matrix2 = shift;
    my ($nrows1, $ncols1) = ($matrix1->rows(), $matrix1->cols());
    my ($nrows2, $ncols2) = ($matrix2->rows(), $matrix2->cols());
    die "matrix multiplication called with non-matching matrix arguments"
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

1;

=pod

=head1 NAME

Algorithm::KMeans - for clustering multidimensional data

=head1 SYNOPSIS

  # You now have four different choices for clustering your data with this module:
  #
  #     1)  With Euclidean distances and with random cluster seeding
  #    
  #     2)  With Mahalanobis distances and with random cluster seeding
  #   
  #     3)  With Euclidean distances and with smart cluster seeding
  #
  #     4)  With Mahalanobis distances and with smart cluster seeding
  #
  # Despite the qualifier 'smart' in 'smart cluster seeding', it may not always
  # produce results that are superior to those obtained with random seeding.  (If you
  # also factor in the choice regarding variance normalization, you actually have
  # eight different choices for data clustering with this module.)
  #
  # In all cases, you'd obviously begin with

  use Algorithm::KMeans;

  # You'd then name the data file:

  my $datafile = "mydatafile.csv";

  # Next, set the mask to indicate which columns of the datafile to use for
  # clustering and which column contains a symbolic ID for each data record. For
  # example, if the symbolic name is in the first column, you want the second column
  # to be ignored, and you want the next three columns to be used for 3D clustering,
  # you'd set the mask to:

  my $mask = "N0111";

  # Now construct an instance of the clusterer.  The parameter K controls the number
  # of clusters.  If you know how many clusters you want (let's say 3), call

  my $clusterer = Algorithm::KMeans->new( datafile        => $datafile,
                                          mask            => $mask,
                                          K               => 3,
                                          cluster_seeding => 'random',
                                          terminal_output => 1,
                                          write_clusters_to_files => 1,
                                        );

  # By default, this constructor call will set you up for clustering based on
  # Euclidean distances.  If you want the module to use Mahalanobis distances, your
  # constructor call will look like:

  my $clusterer = Algorithm::KMeans->new( datafile        => $datafile,
                                          mask            => $mask,
                                          K               => 3,
                                          cluster_seeding => 'random',
                                          use_mahalanobis_metric => 1,
                                          terminal_output => 1,
                                          write_clusters_to_files => 1,
                                        );

  # For both constructor calls shown above, you can use smart seeding of the clusters
  # by changing 'random' to 'smart' for the cluster_seeding option.  See the
  # explanation of smart seeding in the Methods section of this documentation.

  # If your data is such that its variability along the different dimensions of the
  # data space is significantly different, you may get better clustering if you first
  # normalize your data by setting the constructor parameter
  # do_variance_normalization as shown below:

  my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                          mask     => $mask,
                                          K        => 3,
                                          cluster_seeding => 'smart',    # or 'random'
                                          terminal_output => 1,
                                          do_variance_normalization => 1,
                                          write_clusters_to_files => 1,
                                        );

  # But bear in mind that such data normalization may actually decrease the
  # performance of the clusterer if the variability in the data is more a result of
  # the separation between the means than a consequence of intra-cluster variance.

  # Set K to 0 if you want the module to figure out the optimum number of clusters
  # from the data. (It is best to run this option with the terminal_output set to 1
  # so that you can see the different value of QoC for the different K):

  my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                          mask     => $mask,
                                          K        => 0,
                                          cluster_seeding => 'random',    # or 'smart'
                                          terminal_output => 1,
                                          write_clusters_to_files => 1,
                                        );

  # Although not shown above, you can obviously set the 'do_variance_normalization'
  # flag here also if you wish.

  # For very large data files, setting K to 0 will result in searching through too
  # many values for K.  For such cases, you can range limit the values of K to search
  # through by

  my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                          mask     => "N111",
                                          Kmin     => 3,
                                          Kmax     => 10,
                                          cluster_seeding => 'random',    # or 'smart'
                                          terminal_output => 1,
                                          write_clusters_to_files => 1,
                                        );

  # FOR ALL CASES ABOVE, YOU'D NEED TO MAKE THE FOLLOWING CALLS ON THE CLUSTERER
  # INSTANCE TO ACTUALLY CLUSTER THE DATA:

  $clusterer->read_data_from_file();
  $clusterer->kmeans();

  # If you want to directly access the clusters and the cluster centers in your own
  # top-level script, replace the above two statements with:

  $clusterer->read_data_from_file();
  my ($clusters_hash, $cluster_centers_hash) = $clusterer->kmeans();

  # You can subsequently access the clusters directly in your own code, as in:

  foreach my $cluster_id (sort keys %{$clusters_hash}) {
      print "\n$cluster_id   =>   @{$clusters_hash->{$cluster_id}}\n";
  }
  foreach my $cluster_id (sort keys %{$cluster_centers_hash}) {
      print "\n$cluster_id   =>   @{$cluster_centers_hash->{$cluster_id}}\n";
  }


  # CLUSTER VISUALIZATION:

  # You must first set the mask for cluster visualization. This mask tells the module
  # which 2D or 3D subspace of the original data space you wish to visualize the
  # clusters in:

  my $visualization_mask = "111";
  $clusterer->visualize_clusters($visualization_mask);


  # SYNTHETIC DATA GENERATION:

  # The module has been provided with a class method for generating multivariate data
  # for experimenting with clustering.  The data generation is controlled by the
  # contents of the parameter file that is supplied as an argument to the data
  # generator method.  The mean and covariance matrix entries in the parameter file
  # must be according to the syntax shown in the param.txt file in the examples
  # directory. It is best to edit this file as needed:

  my $parameter_file = "param.txt";
  my $out_datafile = "mydatafile.dat";
  Algorithm::KMeans->cluster_data_generator(
                          input_parameter_file => $parameter_file,
                          output_datafile => $out_datafile,
                          number_data_points_per_cluster => $N );

=head1 CHANGES

Version 2.05 removes the restriction on the version of Perl that is required.  This
is based on Srezic's recommendation.  He had no problem building and testing the
previous version with Perl 5.8.9.  Version 2.05 also includes a small augmentation of
the code in the method C<read_data_from_file_csv()> for guarding against user errors
in the specification of the mask that tells the module which columns of the data file
are to be used for clustering.

Version 2.04 allows you to use CSV data files for clustering.

Version 2.03 incorporates minor code cleanup.  The main implementation of the module
remains unchanged.

Version 2.02 downshifts the version of Perl that is required for this module.  The
module should work with versions 5.10 and higher of Perl.  The implementation code
for the module remains unchanged.

Version 2.01 removes many errors in the documentation. The changes made to the module
in Version 2.0 were not reflected properly in the documentation page for that
version.  The implementation code remains unchanged.

Version 2.0 includes significant additional functionality: (1) You now have the
option to cluster using the Mahalanobis distance metric (the default is the Euclidean
metric); and (2) With the two C<which_cluster> methods that have been added to the
module, you can now determine the best cluster for a new data sample after you have
created the clusters with the previously available data.  Finding the best cluster
for a new data sample can be done using either the Euclidean metric or the
Mahalanobis metric.

Version 1.40 includes a C<smart> option for seeding the clusters.  This option,
supplied through the constructor parameter C<cluster_seeding>, means that the
clusterer will (1) Subject the data to principal components analysis in order to
determine the maximum variance direction; (2) Project the data onto this direction;
(3) Find peaks in a smoothed histogram of the projected points; and (4) Use the
locations of the highest peaks as initial guesses for the cluster centers.  If you
don't want to use this option, set C<cluster_seeding> to C<random>. That should work
as in the previous version of the module.

Version 1.30 includes a bug fix for the case when the datafile contains empty lines,
that is, lines with no data records.  Another bug fix in Version 1.30 deals with the
case when you want the module to figure out how many clusters to form (this is the
C<K=0> option in the constructor call) and the number of data records is close to the
minimum.

Version 1.21 includes fixes to handle the possibility that, when clustering the data
for a fixed number of clusters, a cluster may become empty during iterative
calculation of cluster assignments of the data elements and the updating of the
cluster centers.  The code changes are in the C<assign_data_to_clusters()> and
C<update_cluster_centers()> subroutines.

Version 1.20 includes an option to normalize the data with respect to its variability
along the different coordinates before clustering is carried out.  

Version 1.1.1 allows for range limiting the values of C<K> to search through.  C<K>
stands for the number of clusters to form.  This version also declares the module
dependencies in the C<Makefile.PL> file.

Version 1.1 is a an object-oriented version of the implementation presented in
version 1.0.  The current version should lend itself more easily to code extension.
You could, for example, create your own class by subclassing from the class presented
here and, in your subclass, use your own criteria for the similarity distance between
the data points and for the QoC (Quality of Clustering) metric, and, possibly a
different rule to stop the iterations.  Version 1.1 also allows you to directly
access the clusters formed and the cluster centers in your calling script.


=head1 SPECIAL USAGE NOTE

If you were directly accessing in your own scripts the clusters produced by the older
versions of this module, you'd need to make changes to your code if you wish to use
Version 2.0 or higher.  Instead of returning arrays of clusters and cluster centers,
Versions 2.0 and higher return hashes. This change was made necessary by the logic
required for implementing the two new C<which_cluster> methods that were introduced
in Version 2.0.  These methods return the best cluster for a new data sample from the
clusters you created using the existing data.  One of the C<which_cluster> methods is
based on the Euclidean metric for finding the cluster that is closest to the new data
sample, and the other on the Mahalanobis metric.  Another point of incompatibility
with the previous versions is that you must now explicitly set the C<cluster_seeding>
parameter in the call to the constructor to either C<random> or C<smart>.  This
parameter does not have a default associated with it starting with Version 2.0.


=head1 DESCRIPTION

Clustering with K-Means takes place iteratively and involves two steps: 1) assignment
of data samples to clusters on the basis of how far the data samples are from the
cluster centers; and 2) Recalculation of the cluster centers (and cluster covariances
if you are using the Mahalanobis distance metric for clustering).

Obviously, before the two-step approach can proceed, we need to initialize the the
cluster centers.  How this initialization is carried out is important.  The module
gives you two very different ways for carrying out this initialization.  One option,
called the C<smart> option, consists of subjecting the data to principal components
analysis to discover the direction of maximum variance in the data space.  The data
points are then projected on to this direction and a histogram constructed from the
projections.  Centers of the smoothed histogram are used to seed the clustering
operation.  The other option is to choose the cluster centers purely randomly.  You
get the first option if you set C<cluster_seeding> to C<smart> in the constructor,
and you get the second option if you set it to C<random>.

How to specify the number of clusters, C<K>, is one of the most vexing issues in any
approach to clustering.  In some case, we can set C<K> on the basis of prior
knowledge.  But, more often than not, no such prior knowledge is available.  When the
programmer does not explicitly specify a value for C<K>, the approach taken in the
current implementation is to try all possible values between 2 and some largest
possible value that makes statistical sense.  We then choose that value for C<K>
which yields the best value for the QoC (Quality of Clustering) metric.  It is
generally believed that the largest value for C<K> should not exceed C<sqrt(N/2)>
where C<N> is the number of data samples to be clustered.

What to use for the QoC metric is obviously a critical issue unto itself.  In the
current implementation, the value of QoC is the ratio of the average radius of the
clusters and the average distance between the cluster centers.

Every iterative algorithm requires a stopping criterion.  The criterion implemented
here is that we stop iterations when there is no re-assignment of the data points
during the assignment step.

Ordinarily, the output produced by a K-Means clusterer will correspond to a local
minimum for the QoC values, as opposed to a global minimum.  The current
implementation protects against that when the module constructor is called with the
C<random> option for C<cluster_seeding> by trying different randomly selected initial
cluster centers and then selecting the one that gives the best overall QoC value.

A K-Means clusterer will generally produce good results if the overlap between the
clusters is minimal and if each cluster exhibits variability that is uniform in all
directions.  When the data variability is different along the different directions in
the data space, the results you obtain with a K-Means clusterer may be improved by
first normalizing the data appropriately, as can be done in this module when you set
the C<do_variance_normalization> option in the constructor.  However, as pointed out
elsewhere in this documentation, such normalization may actually decrease the
performance of the clusterer if the overall data variability along any dimension is
more a result of separation between the means than a consequence of intra-cluster
variability.


=head1 METHODS

The module provides the following methods for clustering, for cluster visualization,
for data visualization, for the generation of data for testing a clustering
algorithm, and for determining the cluster membership of a new data sample:

=over 4

=item B<new():>

    my $clusterer = Algorithm::KMeans->new(datafile        => $datafile,
                                           mask            => $mask,
                                           K               => $K,
                                           cluster_seeding => 'random',     # also try 'smart'
                                           use_mahalanobis_metric => 1,     # also try '0'
                                           terminal_output => 1,     
                                           write_clusters_to_files => 1,
                                          );

A call to C<new()> constructs a new instance of the C<Algorithm::KMeans> class.  When
C<$K> is a non-zero positive integer, the module will construct exactly that many
clusters.  However, when C<$K> is 0, the module will find the best number of clusters
to partition the data into.  As explained in the Description, setting
C<cluster_seeding> to C<smart> causes PCA (principal components analysis) to be used
for discovering the best choices for the initial cluster centers.  If you want purely
random decisions to be made for the initial choices for the cluster centers, set
C<cluster_seeding> to C<random>.

The data file is expected to contain entries in the following format

   c20  0  10.7087017086940  9.63528386251712  10.9512155258108  ...
   c7   0  12.8025925026787  10.6126270065785  10.5228482095349  ...
   b9   0  7.60118206283120  5.05889245193079  5.82841781759102  ...
   ....
   ....

where the first column contains the symbolic ID tag for each data record and the rest
of the columns the numerical information.  As to which columns are actually used for
clustering is decided by the string value of the mask.  For example, if we wanted to
cluster on the basis of the entries in just the 3rd, the 4th, and the 5th columns
above, the mask value would be C<N0111> where the character C<N> indicates that the
ID tag is in the first column, the character C<0> that the second column is to be
ignored, and the C<1>'s that follow that the 3rd, the 4th, and the 5th columns are to
be used for clustering.

If you wish for the clusterer to search through a C<(Kmin,Kmax)> range of values for
C<K>, the constructor should be called in the following fashion:

    my $clusterer = Algorithm::KMeans->new(datafile => $datafile,
                                           mask     => $mask,
                                           Kmin     => 3,
                                           Kmax     => 10,
                                           cluster_seeding => 'smart',   # try 'random' also
                                           terminal_output => 1,     
                                          );

where obviously you can choose any reasonable values for C<Kmin> and C<Kmax>.  If you
choose a value for C<Kmax> that is statistically too large, the module will let you
know. Again, you may choose C<random> for C<cluster_seeding>, the default value being
C<smart>.

If you believe that the variability of the data is very different along the different
dimensions of the data space, you may get better clustering by first normalizing the
data coordinates by the standard-deviations along those directions.  When you set the
constructor option C<do_variance_normalization> as shown below, the module uses the
overall data standard-deviation along a direction for the normalization in that
direction.  (As mentioned elsewhere in the documentation, such a normalization could
backfire on you if the data variability along a dimension is more a result of the
separation between the means than a consequence of the intra-cluster variability.):

    my $clusterer = Algorithm::KMeans->new( datafile => $datafile,
                                            mask     => "N111",   
                                            K        => 2,        
                                            cluster_seeding => 'smart',   # try 'random' also
                                            terminal_output => 1,
                                            do_variance_normalization => 1,
                    );

=back

=head2 Constructor Parameters

=over 8

=item C<datafile>:

This parameter names the data file that contains the multidimensional data records
you want the module to cluster.

=item C<mask>:

This parameter supplies the mask to be applied to the columns of your data file. See
the explanation in Synopsis for what this mask looks like.

=item C<K>:

This parameter supplies the number of clusters you are looking for.  If you set this
option to 0, that means that you want the module to search for the best value for
C<K>.  (Keep in mind the fact that searching for the best C<K> may take a long time
for large data files.)

=item C<Kmin>:

If you supply an integer value for C<Kmin>, the search for the best C<K> will begin
with that value.

=item C<Kmax>:

If you supply an integer value for C<Kmax>, the search for the best C<K> will end at
that value.

=item C<cluster_seeding>:

This parameter must be set to either C<random> or C<smart>.  Depending on your data,
you may get superior clustering with the C<random> option.  The choice C<smart> means
that the clusterer will (1) subject the data to principal components analysis to
determine the maximum variance direction; (2) project the data onto this direction;
(3) find peaks in a smoothed histogram of the projected points; and (4) use the
locations of the highest peaks as seeds for cluster centers.  If the C<smart> option
produces bizarre results, try C<random>.

=item C<use_mahalanobis_metric>:

When set to 1, this option causes Mahalanobis distances to be used for clustering.
The default is 0 for this parameter. By default, the module uses the Euclidean
distances for clustering.  In general, Mahalanobis distance based clustering will
fail if your data resides on a lower-dimensional hyperplane in the data space, if you
seek too many clusters, and if you do not have a sufficient number of samples in your
data file.  A necessary requirement for the module to be able to compute Mahalanobis
distances is that the cluster covariance matrices be non-singular. (Let's say your
data dimensionality is C<D> and the module is considering a cluster that has only
C<d> samples in it where C<d> is less than C<D>.  In this case, the covariance matrix
will be singular since its rank will not exceed C<d>.  For the covariance matrix to
be non-singular, it must be of full rank, that is, its rank must be C<D>.)

=item C<do_variance_normalization>:

When set, the module will first normalize the data variance along the different
dimensions of the data space before attempting clustering.  Depending on your data,
this option may or may not result in better clustering.

=item C<terminal_output>:

This boolean parameter, when not supplied in the call to C<new()>, defaults to 0.
When set, you will see in your terminal window the different clusters as lists of the
symbolic IDs and their cluster centers. You will also see the QoC (Quality of
Clustering) values for the clusters displayed.

=item C<write_clusters_to_files>:

This parameter is also boolean.  When set to 1, the clusters are written out to files
that are named in the following manner:

     cluster0.txt 
     cluster1.txt 
     cluster2.txt
     ...
     ...

Before the clusters are written to these files, the module destroys all files with
such names in the directory in which you call the module.


=back

=over

=item B<read_data_from_file()>

    $clusterer->read_data_from_file()

=item B<kmeans()>

    $clusterer->kmeans();

    or 

    my ($clusters_hash, $cluster_centers_hash) = $clusterer->kmeans();

The first call above works solely by side-effect.  The second call also returns the
clusters and the cluster centers. See the C<cluster_and_visualize.pl> script in the
C<examples> directory for how you can in your own code extract the clusters and the
cluster centers from the variables C<$clusters_hash> and C<$cluster_centers_hash>.

=item B<get_K_best()>

    $clusterer->get_K_best();

This call makes sense only if you supply either the C<K=0> option to the constructor,
or if you specify values for the C<Kmin> and C<Kmax> options. The C<K=0> and the
C<(Kmin,Kmax)> options cause the module to determine the best value for C<K>.
Remember, C<K> is the number of clusters the data is partitioned into.

=item B<show_QoC_values()>

    $clusterer->show_QoC_values();

presents a table with C<K> values in the left column and the corresponding QoC
(Quality-of-Clustering) values in the right column.  Note that this call makes sense
only if you either supply the C<K=0> option to the constructor, or if you specify
values for the C<Kmin> and C<Kmax> options.

=item B<visualize_clusters()>

    $clusterer->visualize_clusters( $visualization_mask )

The visualization mask here does not have to be identical to the one used for
clustering, but must be a subset of that mask.  This is convenient for visualizing
the clusters in two- or three-dimensional subspaces of the original space.

=item B<visualize_data()>

    $clusterer->visualize_data($visualization_mask, 'original');

    $clusterer->visualize_data($visualization_mask, 'normed');

This method requires a second argument and, as shown, it must be either the string
C<original> or the string C<normed>, the former for the visualization of the raw data
and the latter for the visualization of the data after its different dimensions are
normalized by the standard-deviations along those directions.  If you call the method
with the second argument set to C<normed>, but do so without turning on the
C<do_variance_normalization> option in the KMeans constructor, it will let you know.


=item  B<which_cluster_for_new_data_element()>

If you wish to determine the cluster membership of a new data sample after you have
created the clusters with the existing data samples, you would need to call this
method. The C<which_cluster_for_new_data.pl> script in the C<examples> directory
shows how to use this method.


=item  B<which_cluster_for_new_data_element_mahalanobis()>

This does the same thing as the previous method, except that it determines the
cluster membership using the Mahalanobis distance metric.  As for the previous
method, see the C<which_cluster_for_new_data.pl> script in the C<examples> directory
for how to use this method.


=item  B<cluster_data_generator()>

    Algorithm::KMeans->cluster_data_generator(
                            input_parameter_file => $parameter_file,
                            output_datafile => $out_datafile,
                            number_data_points_per_cluster => 20 );

for generating multivariate data for clustering if you wish to play with synthetic
data for clustering.  The input parameter file contains the means and the variances
for the different Gaussians you wish to use for the synthetic data.  See the file
C<param.txt> provided in the examples directory.  It will be easiest for you to just
edit this file for your data generation needs.  In addition to the format of the
parameter file, the main constraint you need to observe in specifying the parameters
is that the dimensionality of the covariance matrix must correspond to the
dimensionality of the mean vectors.  The multivariate random numbers are generated by
calling the C<Math::Random> module.  As you would expect, this module requires that
the covariance matrices you specify in your parameter file be symmetric and positive
definite.  Should the covariances in your parameter file not obey this condition, the
C<Math::Random> module will let you know.

=back

=head1 HOW THE CLUSTERS ARE OUTPUT

When the option C<terminal_output> is set in the call to the constructor, the
clusters are displayed on the terminal screen.

When the option C<write_clusters_to_files> is set in the call to the constructor, the
module dumps the clusters in files named

    cluster0.txt
    cluster1.txt
    cluster2.txt
    ...
    ...

in the directory in which you execute the module.  The number of such files will
equal the number of clusters formed.  All such existing files in the directory are
destroyed before any fresh ones are created.  Each cluster file contains the symbolic
ID tags of the data samples in that cluster.

The module also leaves in your directory a printable `.png' file that is a point plot
of the different clusters. The name of this file is always C<clustering_results.png>.

Also, as mentioned previously, a call to C<kmeans()> in your own code will return the
clusters and the cluster centers.

=head1 REQUIRED

This module requires the following three modules:

   Math::Random
   Graphics::GnuplotIF
   Math::GSL

With regard to the third item above, what is actually required is the
C<Math::GSL::Matrix> module.  However, that module is a part of the C<Math::GSL>
distribution. The acronym GSL stands for the GNU Scientific Library.  C<Math::GSL> is
a Perl interface to the GSL C-based library.


=head1 THE C<examples> DIRECTORY

The C<examples> directory contains several scripts to help you become familiar with
this module.  The following script is an example of how the module can be expected to
be used most of the time. It calls for clustering to be carried out with a fixed
C<K>:

        cluster_and_visualize.pl

The more time you spend with this script, the more comfortable you will become with
the use of this module. The script file contains a large comment block that mentions
six locations in the script where you have to make decisions about how to use the
module.

See the following script if you do not know what value to use for C<K> for clustering
your data:

        find_best_K_and_cluster.pl

This script uses the C<K=0> option in the constructor that causes the module to
search for the best C<K> for your data.  Since this search is virtually unbounded ---
limited only by the number of samples in your data file --- the script may take a
long time to run for a large data file.  Hence the next script.

If your datafile is too large, you may need to range limit the values of C<K> that
are searched through, as in the following script:

        find_best_K_in_range_and_cluster.pl

If you also want to include data normalization (it may reduce the performance of the
clusterer in some cases), see the following script:

        cluster_after_data_normalization.pl

When you include the data normalization step and you would like to visualize the data
before and after normalization, see the following script:

        cluster_and_visualize_with_data_visualization.pl*

After you are done clustering, let's say you want to find the cluster membership of a
new data sample. To see how you can do that, see the script:

        which_cluster_for_new_data.pl

This script returns two answers for which cluster a new data sample belongs to: one
using the Euclidean metric to calculate the distances between the new data sample and
the cluster centers, and the other using the Mahalanobis metric.  If the clusters are
strongly elliptical in shape, you are likely to get better results with the
Mahalanobis metric.  (To see that you can get two different answers using the two
different distance metrics, run the C<which_cluster_for_new_data.pl> script on the
data in the file C<mydatafile3.dat>.  To make this run, note that you have to comment
out and uncomment the lines at four different locations in the script.)

The C<examples> directory also contains the following support scripts:

For generating the data for experiments with clustering:

        data_generator.pl

For cleaning up the examples directory:

        cleanup_directory.pl

The examples directory also includes a parameter file, C<param.txt>, for generating
synthetic data for clustering.  Just edit this file if you would like to generate
your own multivariate data for clustering.  The parameter file is for the 3D case,
but you can generate data with any dimensionality through appropriate entries in the
parameter file.

=head1 EXPORT

None by design.

=head1 CAVEATS

K-Means based clustering usually does not work well when the clusters are strongly
overlapping and when the extent of variability along the different dimensions is
different for the different clusters.  The module does give you the ability to
normalize the variability in your data with the constructor option
C<do_variance_normalization>.  However, as described elsewhere, this may actually
reduce the performance of the clusterer if the data variability along a direction is
more a result of the separation between the means than because of intra-cluster
variability.  For better clustering with difficult-to-cluster data, you could try
using the author's C<Algorithm::ExpectationMaximization> module.

=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'KMeans' in the subject line.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-KMeans-2.05.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-KMeans-2.05>.  Enter this directory and execute the following commands
for a standard install of the module if you have root privileges:

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


=head1 THANKS

I thank Slaven for pointing out that I needed to downshift the required version of Perl
for this module.  Fortunately, I had access to an old machine still running Perl
5.10.1.  The current version, 2.02, is based on my testing the module on that machine.

I added two C<which_cluster> methods in Version 2.0 as a result of an email from
Jerome White who expressed a need for such methods in order to determine the best
cluster for a new data record after you have successfully clustered your existing
data.  Thanks Jerome for your feedback!

It was an email from Nadeem Bulsara that prompted me to create Version 1.40 of this
module.  Working with Version 1.30, Nadeem noticed that occasionally the module would
produce variable clustering results on the same dataset.  I believe that this
variability was caused (at least partly) by the purely random mode that was used in
Version 1.30 for the seeding of the cluster centers.  Version 1.40 now includes a
C<smart> mode. With the new mode the clusterer uses a PCA (Principal Components
Analysis) of the data to make good guesses for the cluster centers.  However,
depending on how the data is jumbled up, it is possible that the new mode will not
produce uniformly good results in all cases.  So you can still use the old mode by
setting C<cluster_seeding> to C<random> in the constructor.  Thanks Nadeem for your
feedback!

Version 1.30 resulted from Martin Kalin reporting problems with a very small data
set. Thanks Martin!

Version 1.21 came about in response to the problems encountered by Luis Fernando
D'Haro with version 1.20.  Although the module would yield the clusters for some of
its runs, more frequently than not the module would abort with an "empty cluster"
message for his data. Luis Fernando has also suggested other improvements (such as
clustering directly from the contents of a hash) that I intend to make in future
versions of this module.  Thanks Luis Fernando.

Chad Aeschliman was kind enough to test out the interface of this module and to give
suggestions for its improvement.  His key slogan: "If you cannot figure out how to
use a module in under 10 minutes, it's not going to be used."  That should explain
the longish Synopsis included here.

=head1 AUTHOR

Avinash Kak, kak@purdue.edu

If you send email, please place the string "KMeans" in your subject line to get past
my spam filter.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2014 Avinash Kak

=cut

