package Algorithm::LinearManifoldDataClusterer;

#------------------------------------------------------------------------------------
# Copyright (c) 2015 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::LinearManifoldDataClusterer is a Perl module for clustering data that
# resides on a low-dimensional manifold in a high-dimensional measurement space.
# -----------------------------------------------------------------------------------

use 5.10.0;
use strict;
use warnings;
use Carp;
use List::Util qw(reduce any);
use File::Basename;
use Math::Random;
use Graphics::GnuplotIF;
use Math::GSL::Matrix;
use POSIX (); 

our $VERSION = '1.01';

# Constructor:
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if check_for_illegal_params(@params) == 0;
    bless {
        _datafile                     =>   $args{datafile} || croak("datafile required"),
        _mask                         =>   $args{mask}     || croak("mask required"),
        _K                            =>   $args{K}        || 0,
        _P                            =>   $args{P}        || 0,
        _terminal_output              =>   $args{terminal_output} || 0,
        _max_iterations               =>   $args{max_iterations} || 0,
        _delta_reconstruction_error   =>   $args{delta_reconstruction_error} || 0.001,
        _delta_normalized_error       =>   undef,
        _cluster_search_multiplier    =>   $args{cluster_search_multiplier} || 1,
        _visualize_each_iteration     =>   $args{visualize_each_iteration} == 0 ? 0 : 1,
        _show_hidden_in_3D_plots      =>   $args{show_hidden_in_3D_plots} == 0 ? 0 : 1,
        _make_png_for_each_iteration  =>   $args{make_png_for_each_iteration} == 0 ? 0 : 1,
        _debug                        =>   $args{debug} || 0,
        _N                            =>   0,
        _KM                           =>   $args{K} * $args{cluster_search_multiplier},
        _data_hash                    =>   {},
        _data_tags                    =>   [],
        _data_dimensions              =>   0,
        _final_clusters               =>   [],
        _auto_retry_flag              =>   0,
        _num_iterations_actually_used =>   undef,
        _scale_factor                 =>   undef,
        _data_tags_to_cluster_label_hash  => {},
        _final_reference_vecs_for_all_subspaces => [],
        _reconstruction_error_as_a_function_of_iteration => [],
        _final_trailing_eigenvec_matrices_for_all_subspaces => [],
        _subspace_construction_error_as_a_function_of_iteration => [],
    }, $class;
}

sub get_data_from_csv {
    my $self = shift;
    my $filename = $self->{_datafile} || die "you did not specify a file with the data to be clustered";
    my $mask = $self->{_mask};
    my @mask = split //, $mask;
    $self->{_data_dimensions} = scalar grep {$_ eq '1'} @mask;
    print "data dimensionality:  $self->{_data_dimensions} \n" if $self->{_terminal_output};
    open FILEIN, $filename or die "Unable to open $filename: $!";
    die("Aborted. get_training_data_csv() is only for CSV files") unless $filename =~ /\.csv$/;
    local $/ = undef;
    my @all_data = split /\s+/, <FILEIN>;
    my %data_hash = ();
    my @data_tags = ();
    foreach my $record (@all_data) {    
        my @splits = split /,/, $record;
        my $record_name = shift @splits;
        $data_hash{$record_name} = \@splits;
        push @data_tags, $record_name;
    }
    $self->{_data_hash} = \%data_hash;
    $self->{_data_tags} = \@data_tags;
    $self->{_N} = scalar @data_tags;
}

sub estimate_mean_and_covariance {
    my $self = shift;
    my $tag_set = shift;
    my $cluster_size = @$tag_set;
    my @cluster_center = @{$self->add_point_coords($tag_set)};
    @cluster_center = map {my $x = $_/$cluster_size; $x} @cluster_center;
    # for covariance calculation:
    my ($num_rows,$num_cols) = ($self->{_data_dimensions}, scalar(@$tag_set));
    print "\nThe data will be stuffed into a matrix of $num_rows rows and $num_cols columns\n\n"
        if $self->{_debug};
    my $matrix = Math::GSL::Matrix->new($num_rows,$num_cols);
    my $mean_vec = Math::GSL::Matrix->new($num_rows,1);
    # All the record labels are stored in the array $self->{_data_tags}.  The actual
    # data for clustering is stored in a hash at $self->{_data_hash} whose keys are
    # the record labels; the value associated with each key is the array holding the
    # corresponding numerical multidimensional data.
    $mean_vec->set_col(0, \@cluster_center);
    if ($self->{_debug}) {
        print "\nDisplaying the mean vector for the cluster:\n";
        display_matrix( $mean_vec ) if $self->{_terminal_output};
    }
    foreach my $j (0..$num_cols-1) {
        my $tag = $tag_set->[$j];            
        my $data = $self->{_data_hash}->{$tag};
        my @diff_from_mean = vector_subtract($data, \@cluster_center);
        $matrix->set_col($j, \@diff_from_mean);
    }
    my $transposed = transpose( $matrix );
    my $covariance = $matrix * $transposed;
    $covariance *= 1.0 / $num_cols;
    if ($self->{_debug}) {
        print "\nDisplaying the Covariance Matrix for cluster:";
        display_matrix( $covariance ) if $self->{_terminal_output};
    }
    return ($mean_vec, $covariance);
}

sub eigen_analysis_of_covariance {
    my $self = shift;
    my $covariance = shift;
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
    my @all_my_eigenvecs;
    foreach my $i (0..$num_of_eigens-1) {
        my @vec = $eigenvectors->[$i]->as_list;
        my @eigenvec;
        foreach my $ele (@vec) {
            my ($mag, $theta) = $ele =~ /\[(\d*\.?\d*e?[+-]?\d*),(\S+)\]/;
            if ($theta eq "0") {
                push @eigenvec, $mag;
            } elsif ($theta eq "pi") {
                push @eigenvec, -1.0 * $mag;   
            } else {
                die "Eigendecomposition produced a complex eigenvector -- " .
                    "which should not happen for a covariance matrix!";
            }
        }
        print "Eigenvector $i:   @eigenvec\n" if $self->{_debug};
        push @all_my_eigenvecs, \@eigenvec;
    }
    my @largest_eigen_vec = $eigenvectors->[$largest_eigen_index]->as_list;
    print "\nLargest eigenvector:   @largest_eigen_vec\n" if $self->{_debug};
    my @sorted_eigenvec_indexes = sort {$eigenvalues->[$b] <=> $eigenvalues->[$a]} 0..@all_my_eigenvecs-1;
    my @sorted_eigenvecs;
    my @sorted_eigenvals;
    foreach my $i (0..@sorted_eigenvec_indexes-1) {
        $sorted_eigenvecs[$i] = $all_my_eigenvecs[$sorted_eigenvec_indexes[$i]];        
        $sorted_eigenvals[$i] = $eigenvalues->[$sorted_eigenvec_indexes[$i]];       
    }
    if ($self->{_debug}) {
        print "\nHere come sorted eigenvectors --- from the largest to the smallest:\n";
        foreach my $i (0..@sorted_eigenvecs-1) {
            print "eigenvec:  @{$sorted_eigenvecs[$i]}       eigenvalue: $sorted_eigenvals[$i]\n";
        }
    }
    return (\@sorted_eigenvecs, \@sorted_eigenvals);
}

sub auto_retry_clusterer {
    my $self = shift;    
    $self->{_auto_retry_flag} = 1;
    my $clusters;
    $@ = 1;
    my $retry_attempts = 1;
    while ($@) {
        eval {
            $clusters = $self->linear_manifold_clusterer();
        };
        if ($@) {
            if ($self->{_terminal_output}) {
                print "Clustering failed. Trying again. --- $@";
                print "\n\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
                print     "VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV\n\n";
            }
            $retry_attempts++;
        } else {
            print "\n\nNumber of retry attempts: $retry_attempts\n\n" if $self->{_terminal_output};
            return $clusters;
        }
    }
}

sub linear_manifold_clusterer {
    my $self = shift;
    my $KM = $self->{_KM};
    my @initial_cluster_center_tags;
    my $visualization_msg;
    my @initial_cluster_center_indexes = $self->initialize_cluster_centers($KM, $self->{_N});
    print "Randomly selected indexes for cluster center tags:  @initial_cluster_center_indexes\n"
        if $self->{_debug};
    @initial_cluster_center_tags = map {$self->{_data_tags}->[$_]} @initial_cluster_center_indexes;
    my @initial_cluster_center_coords = map {$self->{_data_hash}->{$_}} @initial_cluster_center_tags;
    if ($self->{_debug}) {
        foreach my $centroid (@initial_cluster_center_coords) {
            print "Initial cluster center coords:  @{$centroid}\n";
        }
    }
    my $initial_clusters = $self->assign_data_to_clusters_initial(\@initial_cluster_center_coords);
    if ($self->{_data_dimensions} == 3) {
        $visualization_msg = "initial_clusters";
        $self->visualize_clusters_on_sphere($visualization_msg, $initial_clusters) 
            if $self->{_visualize_each_iteration};
        $self->visualize_clusters_on_sphere($visualization_msg, $initial_clusters, "png")
            if $self->{_make_png_for_each_iteration};
    }
    foreach my $cluster (@$initial_clusters) {
        my ($mean, $covariance) = $self->estimate_mean_and_covariance($cluster);
        display_mean_and_covariance($mean, $covariance) if $self->{_debug};
    }
    my @clusters = @$initial_clusters;
    display_clusters(\@clusters) if $self->{_debug};
    my $iteration_index = 0;
    my $unimodal_correction_flag;
    my $previous_min_value_for_unimodality_quotient;
    while ($iteration_index < $self->{_max_iterations}) {
        print "\n\n========================== STARTING ITERATION $iteration_index =====================\n\n"
            if $self->{_terminal_output};
        my $total_reconstruction_error_this_iteration = 0;
        my @subspace_construction_errors_this_iteration;
        my @trailing_eigenvec_matrices_for_all_subspaces;
        my @reference_vecs_for_all_subspaces;
        foreach my $cluster (@clusters) {
            next if @$cluster == 0;
            my ($mean, $covariance) = $self->estimate_mean_and_covariance($cluster);
            display_mean_and_covariance($mean, $covariance) if $self->{_debug};
            print "--------------end of displaying mean and covariance\n\n" if $self->{_debug};
            my ($eigenvecs, $eigenvals) = $self->eigen_analysis_of_covariance($covariance);
            my @trailing_eigenvecs =  @{$eigenvecs}[$self->{_P} .. $self->{_data_dimensions}-1];
            my @trailing_eigenvals =  @{$eigenvals}[$self->{_P} .. $self->{_data_dimensions}-1];
            my $subspace_construction_error = reduce {abs($a) + abs($b)} @trailing_eigenvals;
            push @subspace_construction_errors_this_iteration, $subspace_construction_error;
            my $trailing_eigenvec_matrix = Math::GSL::Matrix->new($self->{_data_dimensions}, 
                                                                 scalar(@trailing_eigenvecs));
            foreach my $j (0..@trailing_eigenvecs-1) {
                print "trailing eigenvec column: @{$trailing_eigenvecs[$j]}\n" if $self->{_debug};
                $trailing_eigenvec_matrix->set_col($j, $trailing_eigenvecs[$j]);
            }
            push @trailing_eigenvec_matrices_for_all_subspaces,$trailing_eigenvec_matrix;
            push @reference_vecs_for_all_subspaces, $mean;
        }
        $self->set_termination_reconstruction_error_threshold(\@reference_vecs_for_all_subspaces);
        my %best_subspace_based_partition_of_data;
        foreach my $i (0..$self->{_KM}-1) {
            $best_subspace_based_partition_of_data{$i} = [];
        }
        foreach my $data_tag (@{$self->{_data_tags}}) {
            my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
            $data_vec->set_col(0, $self->{_data_hash}->{$data_tag});
            my @errors = map {$self->reconstruction_error($data_vec,
                                  $trailing_eigenvec_matrices_for_all_subspaces[$_],
                                  $reference_vecs_for_all_subspaces[$_])}
                         0 .. $self->{_KM}-1;
            my ($minval, $index_for_closest_subspace) = minimum(\@errors);
            $total_reconstruction_error_this_iteration += $minval;
            push @{$best_subspace_based_partition_of_data{$index_for_closest_subspace}},
                                                                      $data_tag;
        }
        print "Finished calculating the eigenvectors for the clusters produced by the previous\n" .
              "iteration and re-assigning the data samples to the new subspaces on the basis of\n".
              "the least reconstruction error.\n\n" .
              "Total reconstruction error in this iteration: $total_reconstruction_error_this_iteration\n"
                  if $self->{_terminal_output};
        foreach my $i (0..$self->{_KM}-1) {
            $clusters[$i] = $best_subspace_based_partition_of_data{$i};
        }
        display_clusters(\@clusters) if $self->{_terminal_output};
        # Check if any cluster has lost all its elements. If so, fragment the worst
        # existing cluster to create the additional clusters needed:
        if (any {@$_ == 0} @clusters) {
            die "empty cluster found" if $self->{_auto_retry_flag};
            print "\nOne or more clusters have become empty.  Will carve out the needed clusters\n" .
                  "from the cluster with the largest subspace construction error.\n\n";
            $total_reconstruction_error_this_iteration = 0;
            @subspace_construction_errors_this_iteration = ();
            my $how_many_extra_clusters_needed = $self->{_KM} - scalar(grep {@$_ != 0} @clusters);
            print "number of extra clusters needed at iteration $iteration_index: $how_many_extra_clusters_needed\n";
            my $max = List::Util::max @subspace_construction_errors_this_iteration;
            my $maxindex = List::Util::first {$_ == $max} @subspace_construction_errors_this_iteration;
            my @cluster_fragments = cluster_split($clusters[$maxindex], 
                                                  $how_many_extra_clusters_needed + 1);
            my @newclusters;
            push @newclusters, @clusters[0 .. $maxindex-1];
            push @newclusters, @clusters[$maxindex+1 .. $self->{_KM}-1];
            push @newclusters, @cluster_fragments;
            @newclusters = grep {@$_ != 0} @newclusters; 
            die "something went wrong with cluster fragmentation" 
                unless $self->{_KM} = @newclusters;
            @trailing_eigenvec_matrices_for_all_subspaces = ();
            @reference_vecs_for_all_subspaces = ();
            foreach my $cluster (@newclusters) {
                die "Linear Manifold Clustering did not work $!" if @$cluster == 0;
                my ($mean, $covariance) = estimate_mean_and_covariance($cluster);
                my ($eigenvecs, $eigenvals) = eigen_analysis_of_covariance($covariance);
                my @trailing_eigenvecs =  @{$eigenvecs}[$self->{_P} .. $self->{_data_dimensions}-1];
                my @trailing_eigenvals =  @{$eigenvals}[$self->{_P} .. $self->{_data_dimensions}-1];
                my $subspace_construction_error = reduce {abs($a) + abs($b)} @trailing_eigenvals;
                push @subspace_construction_errors_this_iteration, $subspace_construction_error;
                my $trailing_eigenvec_matrix = Math::GSL::Matrix->new($self->{_data_dimensions}, 
                                                      scalar(@trailing_eigenvecs));
                foreach my $j (0..@trailing_eigenvecs-1) {
                    $trailing_eigenvec_matrix->set_col($j, $trailing_eigenvecs[$j]);
                }
                push @trailing_eigenvec_matrices_for_all_subspaces,$trailing_eigenvec_matrix;
                push @reference_vecs_for_all_subspaces, $mean;
            }
            my %best_subspace_based_partition_of_data;
            foreach my $i (0..$self->{_KM}-1) {
                $best_subspace_based_partition_of_data{$i} = [];
            }
            foreach my $data_tag (@{$self->{_data_tags}}) {
                my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
                $data_vec->set_col(0, $self->{_data_hash}->{$data_tag});
                my @errors = map {reconstruction_error($data_vec,
                                      $trailing_eigenvec_matrices_for_all_subspaces[$_],
                                      $reference_vecs_for_all_subspaces[$_])}
                             0 .. $self->{_KM}-1;
                my ($minval, $index_for_closest_subspace) = minimum(\@errors);
                $total_reconstruction_error_this_iteration += $minval;
                push @{$best_subspace_based_partition_of_data{$index_for_closest_subspace}},
                                                                      $data_tag;
            }
            print "empty-cluster jag: total reconstruction error in this iteration: \n" .
                  "$total_reconstruction_error_this_iteration\n"
                if $self->{_debug};
            foreach my $i (0..$self->{_KM}-1) {
                $clusters[$i] = $best_subspace_based_partition_of_data{$i};
            }
            display_clusters(\@newclusters) if $self->{_terminal_output};
            @clusters = grep {@$_ != 0} @newclusters;
            die "linear manifold based algorithm does not appear to work in this case $!" 
                unless @clusters == $self->{_KM};
        }# end of foreach my $cluster (@clusters) ... loop  followed by if clause for empty clusters
        if ($self->{_data_dimensions} == 3) {
            $visualization_msg = "clustering_at_iteration_$iteration_index";
            $self->visualize_clusters_on_sphere($visualization_msg, \@clusters)
                if $self->{_visualize_each_iteration};
            $self->visualize_clusters_on_sphere($visualization_msg, \@clusters, "png")
                if $self->{_make_png_for_each_iteration};
        }
        my @cluster_unimodality_quotients = map {$self->cluster_unimodality_quotient($clusters[$_], 
                                                      $reference_vecs_for_all_subspaces[$_])} 0..@clusters-1;
        my $min_value_for_unimodality_quotient = List::Util::min @cluster_unimodality_quotients;
        print "\nCluster unimodality quotients: @cluster_unimodality_quotients\n" if $self->{_terminal_output};
        die "\n\nBailing out!\n" .
            "It does not look like these iterations will lead to a good clustering result.\n" .
            "Program terminating.  Try running again.\n" 
            if defined($previous_min_value_for_unimodality_quotient)
               && ($min_value_for_unimodality_quotient < 0.4)
               && ($min_value_for_unimodality_quotient < (0.5 * $previous_min_value_for_unimodality_quotient));
        if ( $min_value_for_unimodality_quotient < 0.5 ) {
            $unimodal_correction_flag = 1;
            print "\nApplying unimodality correction:\n\n" if $self->{_terminal_output};
            my @sorted_cluster_indexes = 
               sort {$cluster_unimodality_quotients[$b] <=> $cluster_unimodality_quotients[$a]} 0..@clusters-1;
            my @newclusters;
            foreach my $cluster_index (0..@clusters - 1) {
                push @newclusters, $clusters[$sorted_cluster_indexes[$cluster_index]];
            }
            @clusters = @newclusters;
            my $worst_cluster = pop @clusters;
            print "\nthe worst cluster: @$worst_cluster\n" if $self->{_terminal_output};
            my $second_worst_cluster = pop @clusters;
            print "\nthe second worst cluster: @$second_worst_cluster\n" if $self->{_terminal_output};
            push @$worst_cluster, @$second_worst_cluster;
            fisher_yates_shuffle($worst_cluster);
            my @first_half = @$worst_cluster[0 .. int(scalar(@$worst_cluster)/2) - 1];
            my @second_half = @$worst_cluster[int(scalar(@$worst_cluster)/2) .. @$worst_cluster - 1];
            push @clusters, \@first_half;
            push @clusters, \@second_half;
            if ($self->{_terminal_output}) {
                print "\n\nShowing the clusters obtained after applying the unimodality correction:\n";
                display_clusters(\@clusters);      
            }
        }
        if (@{$self->{_reconstruction_error_as_a_function_of_iteration}} > 0) {
            my $last_recon_error = pop @{$self->{_reconstruction_error_as_a_function_of_iteration}};
            push @{$self->{_reconstruction_error_as_a_function_of_iteration}}, $last_recon_error;
            if (($last_recon_error - $total_reconstruction_error_this_iteration) 
                                                        < $self->{_delta_normalized_error}) {
                push @{$self->{_reconstruction_error_as_a_function_of_iteration}}, 
                                                      $total_reconstruction_error_this_iteration;
                last;
            }
        }
        push @{$self->{_reconstruction_error_as_a_function_of_iteration}}, 
                                              $total_reconstruction_error_this_iteration;
        $iteration_index++;
        $previous_min_value_for_unimodality_quotient =  $min_value_for_unimodality_quotient;
    } # end of while loop on iteration_index
    $self->{_num_iterations_actually_used} = 
                                 scalar @{$self->{_reconstruction_error_as_a_function_of_iteration}};
    if ($self->{_terminal_output}) {
        print "\nIterations of the main loop terminated at iteration number $iteration_index.\n";
        print "Will now invoke graph partitioning to discover dominant clusters and to\n" .
              "merge small clusters.\n\n" if $self->{_cluster_search_multiplier} > 1;
        print "Total reconstruction error as a function of iterations: " .
                                       "@{$self->{_reconstruction_error_as_a_function_of_iteration}}";
    }
    # now merge sub-clusters if cluster_search_multiplier > 1
    my @final_clusters;
    if ($self->{_cluster_search_multiplier} > 1) {
        print "\n\nInvoking recursive graph partitioning to merge small clusters\n\n";
        my @array_of_partitioned_cluster_groups = (\@clusters);
        my @partitioned_cluster_groups;
        my $how_many_clusters_looking_for = $self->{_K};
        while (scalar(@final_clusters) < $self->{_K}) {
            @partitioned_cluster_groups = 
                   $self->graph_partition(shift @array_of_partitioned_cluster_groups, 
                                                             $how_many_clusters_looking_for );
            if (@{$partitioned_cluster_groups[0]} == 1) {
                my $singular_cluster = shift @{$partitioned_cluster_groups[0]};
                push @final_clusters, $singular_cluster;
                $how_many_clusters_looking_for--;
                push @array_of_partitioned_cluster_groups, $partitioned_cluster_groups[1];
            } elsif (@{$partitioned_cluster_groups[1]} == 1) {
                my $singular_cluster = shift @{$partitioned_cluster_groups[1]};
                push @final_clusters, $singular_cluster;
                $how_many_clusters_looking_for--;
                push @array_of_partitioned_cluster_groups, $partitioned_cluster_groups[0];
            } else {
                push @array_of_partitioned_cluster_groups, $partitioned_cluster_groups[0];
                push @array_of_partitioned_cluster_groups, $partitioned_cluster_groups[1];
            }
        }
        my @data_clustered;
        foreach my $cluster (@final_clusters) {
            push @data_clustered, @$cluster;
        }
        unless (scalar(@data_clustered) == scalar(@{$self->{_data_tags}})) {
            $self->{_final_clusters} = \@final_clusters;
            my %data_clustered = map {$_ => 1} @data_clustered;
            my @data_tags_not_clustered = 
                   grep {$_} map {exists $data_clustered{$_} ? undef : $_} @{$self->{_data_tags}};
            if ($self->{_terminal_output}) {
                print "\n\nNot all data clustered.  The most reliable clusters found by graph partitioning:\n";
                display_clusters(\@final_clusters);
                print "\n\nData not yet clustered:\n\n@data_tags_not_clustered\n";
            }
            if ($self->{_data_dimensions} == 3) {
                $visualization_msg = "$self->{_K}_best_clusters_produced_by_graph_partitioning";
                $self->visualize_clusters_on_sphere($visualization_msg, \@final_clusters)
                    if $self->{_visualize_each_iteration};
                $self->visualize_clusters_on_sphere($visualization_msg, \@final_clusters, "png")
                    if $self->{_make_png_for_each_iteration};
            }
            my %data_tags_to_cluster_label_hash;
            foreach my $i (0..@final_clusters-1) {
                map {$data_tags_to_cluster_label_hash{$_} = $i} @{$final_clusters[$i]};
            }
            $self->{_data_tags_to_cluster_label_hash} = \%data_tags_to_cluster_label_hash;
            foreach my $tag (@data_tags_not_clustered) {
                my $which_cluster = $self->which_cluster_for_new_element($tag);
                $self->{_data_tags_to_cluster_label_hash}->{$tag} = $which_cluster;
            }
            die "Some data elements are still missing from the final tally" 
              unless scalar(keys %{$self->{_data_tags_to_cluster_label_hash}}) == 
                scalar(@{$self->{_data_tags}});
            my @new_final_clusters;
            map { foreach my $ele (keys %{$self->{_data_tags_to_cluster_label_hash}}) {
                      push @{$new_final_clusters[$_]}, $ele 
                            if $self->{_data_tags_to_cluster_label_hash}->{$ele} == $_ } 
                } 0..$self->{_K}-1;
            if ($self->{_debug}) {
                print "\ndisplaying the final clusters after accounting for unclustered data:\n"; 
                display_clusters(\@new_final_clusters);
            }
            $self->{_final_clusters} = \@new_final_clusters;
            @final_clusters = @new_final_clusters;
        }
    } else {
        @final_clusters = @clusters;
    }
    print "\n\nDisplaying final clustering results:\n\n" if $self->{_terminal_output};
    display_clusters(\@final_clusters) if $self->{_terminal_output};
    return \@final_clusters;
} 

sub display_reconstruction_errors_as_a_function_of_iterations {
    my $self = shift;            
    print "\n\nNumber of iterations used in Phase 1: $self->{_num_iterations_actually_used}\n";
    print "\nTotal reconstruction error as a function of iterations in Phase 1: " .
          "@{$self->{_reconstruction_error_as_a_function_of_iteration}}\n";
}

sub set_termination_reconstruction_error_threshold {
    my $self = shift;        
    my $all_ref_vecs = shift;
    my @mean_vecs = @$all_ref_vecs;
    my $sum_of_mean_magnitudes = reduce {$a+$b} map { my $result = transpose($_) * $_; 
                                                      my @result = $result->as_list; 
                                                      sqrt($result[0])
                                                    } @mean_vecs;
    $self->{_scale_factor} = $sum_of_mean_magnitudes / @mean_vecs;
    $self->{_delta_normalized_error} = ($sum_of_mean_magnitudes / @mean_vecs ) * 
                                       $self->{_delta_reconstruction_error};
}

# This method is called only in the `unless' clause at the end of the main
# linear_manifold_clusterer() method.  It is called to find the cluster labels for
# those data elements that were left unclustered by the main part of the algorithm
# when graph partitioning is used to merge similar sub-clusters.  The operating logic
# here is that graph partition yields K main clusters even though each main cluster
# may not yet be fully populated.
sub which_cluster_for_new_element {
    my $self = shift;    
    my $data_tag = shift;
    # The following `unless' clause is called only the first time the current method
    # is called:
    unless (@{$self->{_final_trailing_eigenvec_matrices_for_all_subspaces}} > 0) {
        my @trailing_eigenvec_matrices_for_all_subspaces;
        my @reference_vecs_for_all_subspaces;
        foreach my $cluster (@{$self->{_final_clusters}}) {
            my ($mean, $covariance) = $self->estimate_mean_and_covariance($cluster);
            my ($eigenvecs, $eigenvals) = $self->eigen_analysis_of_covariance($covariance);
            my @trailing_eigenvecs =  @{$eigenvecs}[$self->{_P} .. $self->{_data_dimensions}-1];
            my $trailing_eigenvec_matrix = Math::GSL::Matrix->new($self->{_data_dimensions}, 
                                                                 scalar(@trailing_eigenvecs));
            foreach my $j (0..@trailing_eigenvecs-1) {
                $trailing_eigenvec_matrix->set_col($j, $trailing_eigenvecs[$j]);
            }
            push @trailing_eigenvec_matrices_for_all_subspaces,$trailing_eigenvec_matrix;
            push @reference_vecs_for_all_subspaces, $mean;
        }
        $self->{_final_trailing_eigenvec_matrices_for_all_subspaces} = 
                                        \@trailing_eigenvec_matrices_for_all_subspaces;
        $self->{_final_reference_vecs_for_all_subspaces} = \@reference_vecs_for_all_subspaces;
    }
    my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
    $data_vec->set_col(0, $self->{_data_hash}->{$data_tag});
    my @errors = map {$self->reconstruction_error($data_vec,
                          $self->{_final_trailing_eigenvec_matrices_for_all_subspaces}->[$_],
                          $self->{_final_reference_vecs_for_all_subspaces}->[$_])}
                         0 .. $self->{_K}-1;
    my ($minval, $index_for_closest_subspace) = minimum(\@errors);
    return $index_for_closest_subspace;
}

sub graph_partition {
    my $self = shift;
    my $clusters = shift;
    my $how_many_clusters_looking_for = shift;
    print "\n\nGraph partitioning looking for $how_many_clusters_looking_for clusters\n\n";
    my $num_nodes = scalar @$clusters;
    my $W = Math::GSL::Matrix->new($num_nodes,$num_nodes);
    my $D = Math::GSL::Matrix->new($num_nodes,$num_nodes);
    $D->identity;
    my $neg_sqrt_of_D = Math::GSL::Matrix->new($num_nodes,$num_nodes);
    $neg_sqrt_of_D->identity;
    my @subspace_construction_errors;
    my @trailing_eigenvec_matrices_for_all_subspaces;
    my @reference_vecs_for_all_subspaces;
    foreach my $cluster (@$clusters) {
        my ($mean, $covariance) = $self->estimate_mean_and_covariance($cluster);
        my ($eigenvecs, $eigenvals) = $self->eigen_analysis_of_covariance($covariance);
        my @trailing_eigenvecs =  @{$eigenvecs}[$self->{_P} .. $self->{_data_dimensions}-1];
        my @trailing_eigenvals =  @{$eigenvals}[$self->{_P} .. $self->{_data_dimensions}-1];
        my $subspace_construction_error = reduce {abs($a) + abs($b)} @trailing_eigenvals;
        push @subspace_construction_errors, $subspace_construction_error;
        my $trailing_eigenvec_matrix = Math::GSL::Matrix->new($self->{_data_dimensions}, 
                                                             scalar(@trailing_eigenvecs));
        foreach my $j (0..@trailing_eigenvecs-1) {
            print "trailing eigenvec column: @{$trailing_eigenvecs[$j]}\n" if $self->{_debug};
            $trailing_eigenvec_matrix->set_col($j, $trailing_eigenvecs[$j]);
        }
        push @trailing_eigenvec_matrices_for_all_subspaces,$trailing_eigenvec_matrix;
        push @reference_vecs_for_all_subspaces, $mean;
    }
    # We consider the similarity matrix W to be a sum of two parts W_recon_based and
    # W_dist_bet_means based. IMPORTANT: For coding reasons, we first store the two
    # similarity measures separately in W_recon_based and W_dist_bet_means based. Our
    # goal is to fill up these component matrices with the raw values while at the
    # same time collecting information needed for normalizing these two separate
    # measures of similarity.
    my $W_reconstruction_error_based = Math::GSL::Matrix->new($num_nodes,$num_nodes);
    my $W_dist_between_means_based = Math::GSL::Matrix->new($num_nodes,$num_nodes);
    my @all_pairwise_reconstruction_errors;
    my @all_dist_between_means_errors;
    foreach my $i (0..$num_nodes-1) {
        foreach my $j (0..$num_nodes-1) {
            my ($recon_error_similarity, $dist_bet_means) = $self->pairwise_cluster_similarity(
                                                      $clusters->[$i], 
                                                      $trailing_eigenvec_matrices_for_all_subspaces[$i],
                                                      $reference_vecs_for_all_subspaces[$i],
                                                      $clusters->[$j],
                                                      $trailing_eigenvec_matrices_for_all_subspaces[$j],
                                                      $reference_vecs_for_all_subspaces[$j]);
            $W_reconstruction_error_based->set_elem($i, $j, $recon_error_similarity);
            $W_dist_between_means_based->set_elem($i, $j, $dist_bet_means);
            push @all_pairwise_reconstruction_errors, $recon_error_similarity;
            push @all_dist_between_means_errors, $dist_bet_means;
        }
    }
    my $recon_error_normalizer = (reduce {$a + $b} @all_pairwise_reconstruction_errors) / 
                                 (scalar @all_pairwise_reconstruction_errors);
    my $dist_bet_means_based_normalizer = (reduce {$a + $b} @all_dist_between_means_errors ) /
                                 (scalar @all_dist_between_means_errors );
    die "\n\nBailing out!\n" .
        "Dealing with highly defective clusters.  Try again.\n" 
        if ($recon_error_normalizer == 0) || ($dist_bet_means_based_normalizer == 0);
    foreach my $i (0..$num_nodes-1) {
        foreach my $j (0..$num_nodes-1) {
            my $recon_val = $W_reconstruction_error_based->get_elem($i,$j);
            my $new_recon_val = exp( -1.0 * $recon_val / $recon_error_normalizer );
            $W_reconstruction_error_based->set_elem($i,$j,$new_recon_val);
            my $mean_dist_val = $W_dist_between_means_based->get_elem($i,$j);
            my $new_mean_dist_val = exp( -1.0 * $mean_dist_val / $dist_bet_means_based_normalizer );
            $W_dist_between_means_based->set_elem($i,$j,$new_mean_dist_val);
        }
    }
    $W = $W_reconstruction_error_based + $W_dist_between_means_based;
    if ($self->{_debug}) {
        print "\nDisplaying the similarity matrix W for the cluster graph:\n";
        display_matrix($W) if $self->{_terminal_output};
    }
    my $add_all_columns = Math::GSL::Matrix->new($num_nodes,1);
    foreach my $col (0..$num_nodes-1) {
        $add_all_columns += $W->col($col);
    }
    foreach my $i (0..$num_nodes-1) {
        $D->set_elem($i,$i, $add_all_columns->get_elem($i,0));
        $neg_sqrt_of_D->set_elem($i,$i, 1.0 / sqrt($add_all_columns->get_elem($i,0)));
    }
    # the Laplacian matrix:
    my $Laplacian = $D - $W;
    # the Symmetric Normalized Laplacian matrix A:
    my $A = $neg_sqrt_of_D * $Laplacian * $neg_sqrt_of_D;
    foreach my $i (0..$num_nodes-1) {
        foreach my $j (0..$num_nodes-1) {
            $A->set_elem($i,$j,0) if abs($A->get_elem($i,$j)) < 0.01;
        }
    }
    if ($self->{_terminal_output}) {
        print "\nDisplaying the Symmetric Normalized Laplacian matrix A:\n" .
              "A = neg_sqrt(D) * Laplacian_matrix * neg_sqrt(D)\n";
        display_matrix( $A );
    }
    my ($eigenvalues, $eigenvectors) = $A->eigenpair;
    my $num_of_eigens = @$eigenvalues;     
    my $largest_eigen_index = 0;
    my $smallest_eigen_index = 0;
    if ($self->{_debug2}) {
        print "Eigenvalue 0:   $eigenvalues->[0]\n";
        foreach my $i (1..$num_of_eigens-1) {
            $largest_eigen_index = $i if $eigenvalues->[$i] > $eigenvalues->[$largest_eigen_index];
            $smallest_eigen_index = $i if $eigenvalues->[$i] < $eigenvalues->[$smallest_eigen_index];
            print "Eigenvalue $i:   $eigenvalues->[$i]\n";
        }
        print "\nlargest eigen index: $largest_eigen_index\n";
        print "\nsmallest eigen index: $smallest_eigen_index\n\n";
    }
    my @all_my_eigenvecs;
    foreach my $i (0..$num_of_eigens-1) {
        my @vec = $eigenvectors->[$i]->as_list;
        my @eigenvec;
        foreach my $ele (@vec) {
            my ($mag, $theta) = $ele =~ /\[(\d*\.?\d*e?[+-]?\d*),(\S+)\]/;
            if ($theta eq "0") {
                push @eigenvec, $mag;
            } elsif ($theta eq "pi") {
                push @eigenvec, -1.0 * $mag;   
            } else {
                die "Eigendecomposition produced a complex eigenvector!";
            }
        }
        print "Eigenvector $i:   @eigenvec\n" if $self->{_debug2};
        push @all_my_eigenvecs, \@eigenvec;
    }
    if ($self->{_debug2}) {
        my @largest_eigen_vec = $eigenvectors->[$largest_eigen_index]->as_list;
        print "\nLargest eigenvector of A:   @largest_eigen_vec\n";
    }
    my @sorted_eigenvec_indexes = sort {$eigenvalues->[$b] <=> $eigenvalues->[$a]} 0..@all_my_eigenvecs-1;
    print "sorted eigenvec indexes for A: @sorted_eigenvec_indexes\n" if $self->{_debug2};
    my @sorted_eigenvecs;
    my @sorted_eigenvals;
    foreach my $i (0..@sorted_eigenvec_indexes-1) {
        $sorted_eigenvecs[$i] = $all_my_eigenvecs[$sorted_eigenvec_indexes[$i]];        
        $sorted_eigenvals[$i] = $eigenvalues->[$sorted_eigenvec_indexes[$i]];       
    }
    if ($self->{_debug2}) {
        print "\nHere come sorted eigenvectors for A --- from the largest to the smallest:\n";
        foreach my $i (0..@sorted_eigenvecs-1) {
            print "eigenvec:  @{$sorted_eigenvecs[$i]}       eigenvalue: $sorted_eigenvals[$i]\n";
        }
    }
    my $best_partitioning_eigenvec = $sorted_eigenvecs[@sorted_eigenvec_indexes-2];
    print "\nBest graph partitioning eigenvector: @$best_partitioning_eigenvec\n" if $self->{_terminal_output};
    my $how_many_positive = reduce {$a + $b} map {$_ > 0 ? 1 : 0 } @$best_partitioning_eigenvec;
    my $how_many_negative = scalar(@$best_partitioning_eigenvec) - $how_many_positive;
    print "Have $how_many_positive positive and $how_many_negative negative elements in the partitioning vec\n"
        if $self->{_terminal_output};
    if ($how_many_clusters_looking_for <= 3) {
        my @merged_cluster;
        my $final_cluster;
        my @newclusters;
        if ($how_many_positive == 1) {
            foreach my $i (0..@$clusters-1) {
                if ($best_partitioning_eigenvec->[$i] > 0) {
                    $final_cluster = $clusters->[$i]; 
                } else {
                    push @newclusters, $clusters->[$i];
                }
            }
            return ([$final_cluster], \@newclusters);
        } elsif ($how_many_negative == 1) {
            foreach my $i (0..@$clusters-1) {
                if ($best_partitioning_eigenvec->[$i] < 0) {
                    $final_cluster = $clusters->[$i]; 
                } else {
                    push @newclusters, $clusters->[$i];
                }
            }
            return ([$final_cluster], \@newclusters);
        } elsif ($how_many_positive <= $self->{_cluster_search_multiplier}) {
            foreach my $i (0..@$clusters-1) {
                if ($best_partitioning_eigenvec->[$i] > 0) {
                    push @merged_cluster, @{$clusters->[$i]}; 
                } else {
                    push @newclusters, $clusters->[$i];
                }
            }
            return ([\@merged_cluster], \@newclusters);
        } elsif ($how_many_negative <= $self->{_cluster_search_multiplier}) {
            foreach my $i (0..@$clusters-1) {
                if ($best_partitioning_eigenvec->[$i] < 0) {
                    push @merged_cluster, @{$clusters->[$i]}; 
                } else {
                    push @newclusters, $clusters->[$i];
                }
            }
            return ([\@merged_cluster], \@newclusters);
        } else {
            die "\n\nBailing out!\n\n" .
                "No consensus support for dominant clusters in the graph partitioning step\n" .
                "of the algorithm. This can be caused by bad random selection of initial\n" .
                "cluster centers.  Please run this program again.\n";
        }
    } else {
        my @positive_clusters;
        my @negative_clusters;
        foreach my $i (0..@$clusters-1) {
            if ($best_partitioning_eigenvec->[$i] > 0) {
                push @positive_clusters, $clusters->[$i]; 
            } else {
                    push @negative_clusters, $clusters->[$i];
            }
        }
        return (\@positive_clusters, \@negative_clusters);
    }
}

sub pairwise_cluster_similarity {
    my $self = shift;
    my $cluster1 = shift;
    my $trailing_eigenvec_matrix_cluster1 = shift;   
    my $reference_vec_cluster1 = shift;
    my $cluster2 = shift;
    my $trailing_eigenvec_matrix_cluster2 = shift;   
    my $reference_vec_cluster2 = shift;
    my $total_reconstruction_error_in_this_iteration = 0;
    my @errors_for_1_on_2 = map {my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
                                 $data_vec->set_col(0, $self->{_data_hash}->{$_});
                                 $self->reconstruction_error($data_vec,
                                                             $trailing_eigenvec_matrix_cluster2,
                                                             $reference_vec_cluster2)} 
                                 @$cluster1;
    my @errors_for_2_on_1 = map {my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
                                 $data_vec->set_col(0, $self->{_data_hash}->{$_});
                                 $self->reconstruction_error($data_vec,
                                                             $trailing_eigenvec_matrix_cluster1,
                                                             $reference_vec_cluster1)} 
                                 @$cluster2;
    my $type_1_error = reduce {abs($a) + abs($b)} @errors_for_1_on_2;
    my $type_2_error = reduce {abs($a) + abs($b)} @errors_for_2_on_1;
    my $total_reconstruction_error = $type_1_error + $type_2_error;
    my $diff_between_the_means = $reference_vec_cluster1 - $reference_vec_cluster2;
    my $dist_squared = transpose($diff_between_the_means) * $diff_between_the_means;
    my @dist_squared_as_list = $dist_squared->as_list();
    my $dist_between_means_based_error = shift @dist_squared_as_list;
    return ($total_reconstruction_error, $dist_between_means_based_error);
}

# delta ball
sub cluster_unimodality_quotient {
    my $self = shift;
    my $cluster = shift;
    my $mean = shift;   
    my $delta = 0.4 * $self->{_scale_factor};  # Radius of the delta ball along each dimension
    my @mean = $mean->as_list;
    my @data_tags_for_range_tests;
    foreach my $dimen (0..$self->{_data_dimensions}-1) {
        my @values = map {$_->[$dimen]} map {$self->{_data_hash}->{$_}} @$cluster;
        my ($min, $max) = (List::Util::min(@values), List::Util::max(@values));
        my $range = $max - $min;
        my $mean_along_this_dimen = $mean[$dimen];
        my @tags =  grep {$_} 
                    map { ( ($self->{_data_hash}->{$_}->[$dimen] > $mean_along_this_dimen - $delta * $range) 
                            && 
                            ($self->{_data_hash}->{$_}->[$dimen] < $mean_along_this_dimen + $delta * $range) ) 
                          ? $_ : undef }
                    @$cluster; 
        push @data_tags_for_range_tests, \@tags;
    }
    # Now find the intersection of the tag sets for each of the dimensions
    my %intersection_hash;
    foreach my $dimen (0..$self->{_data_dimensions}-1) {
        my %tag_hash_for_this_dimen  = map {$_ => 1} @{$data_tags_for_range_tests[$dimen]};
        if ($dimen == 0) {
            %intersection_hash = %tag_hash_for_this_dimen;
        } else {
            %intersection_hash = map {$_ => 1} grep {$tag_hash_for_this_dimen{$_}} 
                                 keys %intersection_hash;
        }
    }
    my @intersection_set = keys %intersection_hash;
    my $cluster_unimodality_index = scalar(@intersection_set) / scalar(@$cluster);
    return $cluster_unimodality_index;
}

sub find_best_ref_vector {
    my $self = shift;
    my $cluster = shift;
    my $trailing_eigenvec_matrix = shift;
    my $mean = shift;        # a GSL marix ref
    my @min_bounds;
    my @max_bounds;
    my @ranges;
    foreach my $dimen (0..$self->{_data_dimensions}-1) {
        my @values = map {$_->[$dimen]} map {$self->{_data_hash}->{$_}} @$cluster;
        my ($min, $max) = (List::Util::min(@values), List::Util::max(@values));
        push @min_bounds, $min;
        push @max_bounds, $max;
        push @ranges, $max - $min;
    }
    print "min bounds are: @min_bounds\n";
    print "max bounds are: @max_bounds\n";
    my $max_iterations = 100;
    my @random_points;
    my $iteration = 0;
    while ($iteration++ < $max_iterations) {
        my @coordinate_vec;
        foreach my $dimen (0..$self->{_data_dimensions}-1) {        
            push @coordinate_vec,  $min_bounds[$dimen] + rand($ranges[$dimen]);
        }
        push @random_points, \@coordinate_vec;
    }
    if ($self->{_debug}) {
        print "\nrandom points\n";
        map {print "@$_\n"} @random_points;
    }
    my @mean = $mean->as_list;
    unshift @random_points, \@mean;
    my @reconstruction_errors;
    foreach my $candidate_ref_vec (@random_points) {
        my $ref_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
        $ref_vec->set_col(0, $candidate_ref_vec);
        my $reconstruction_error_for_a_ref_vec = 0;
        foreach my $data_tag (@{$self->{_data_tags}}) {
            my $data_vec = Math::GSL::Matrix->new($self->{_data_dimensions},1);
            $data_vec->set_col(0, $self->{_data_hash}->{$data_tag});
            my $error = $self->reconstruction_error($data_vec,$trailing_eigenvec_matrix,$ref_vec);
            $reconstruction_error_for_a_ref_vec += $error;
        }
        push @reconstruction_errors, $reconstruction_error_for_a_ref_vec;
    }
    my $recon_error_for_original_mean = shift @reconstruction_errors;
    my $smallest_error_randomly_selected_ref_vecs = List::Util::min(@reconstruction_errors);
    my $minindex = List::Util::first { $_ == $smallest_error_randomly_selected_ref_vecs }
                                                    @reconstruction_errors;
    my $refvec = $random_points[$minindex];
    return $refvec;
}

##  The reconstruction error relates to the size of the perpendicular from a data
##  point X to the hyperplane that defines a given subspace on the manifold.
sub reconstruction_error {
    my $self = shift;
    my $data_vec = shift;
    my $trailing_eigenvecs = shift;
    my $ref_vec = shift;    
    my $error_squared = transpose($data_vec - $ref_vec) * $trailing_eigenvecs *  
                                 transpose($trailing_eigenvecs) * ($data_vec - $ref_vec);
    my @error_squared_as_list = $error_squared->as_list();
    my $error_squared_as_scalar = shift @error_squared_as_list;
    return $error_squared_as_scalar;
}

# Returns a set of KM random integers.  These serve as indices to reach into the data
# array.  A data element whose index is one of the random numbers returned by this
# routine serves as an initial cluster center.  Note the quality check it runs on the
# list of the random integers constructed.  We first make sure that all the random
# integers returned are different.  Subsequently, we carry out a quality assessment
# of the random integers constructed.  This quality measure consists of the ratio of
# the values spanned by the random integers to the value of N, the total number of
# data points to be clustered.  Currently, if this ratio is less than 0.3, we discard
# the K integers and try again.
sub initialize_cluster_centers {
    my $self = shift;
    my $K = shift;   # This value is set to the parameter KM in the call to this subroutine
    my $data_store_size = shift;
    my @cluster_center_indices;
    while (1) {
        foreach my $i (0..$K-1) {
            $cluster_center_indices[$i] = int rand( $data_store_size );
            next if $i == 0;
            foreach my $j (0..$i-1) {
                while ( $cluster_center_indices[$j] == $cluster_center_indices[$i] ) {
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

# The purpose of this routine is to form initial clusters by assigning the data
# samples to the initial clusters formed by the previous routine on the basis of the
# best proximity of the data samples to the different cluster centers.
sub assign_data_to_clusters_initial {
    my $self = shift;
    my @cluster_centers = @{ shift @_ };
    my @clusters;
    foreach my $ele (@{$self->{_data_tags}}) {
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

# The following routine is for computing the distance between a data point specified
# by its symbolic name in the master datafile and a point (such as the center of a
# cluster) expressed as a vector of coordinates:
sub distance {
    my $self = shift;
    my $ele1_id = shift @_;            # symbolic name of data sample
    my @ele1 = @{$self->{_data_hash}->{$ele1_id}};
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

sub write_clusters_to_files {
    my $self = shift;
    my $clusters = shift;
    my @clusters = @$clusters;
    unlink glob "cluster*.txt";
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

sub DESTROY {
    my $filename = basename($_[0]->{_datafile});
    $filename =~ s/\.\w+$/\.txt/;
    unlink "__temp_" . $filename;
}

##################################  Visualization Code ###################################

sub add_point_coords {
    my $self = shift;
    my @arr_of_ids = @{shift @_};      # array of data element names
    my @result;
    my $data_dimensionality = $self->{_data_dimensions};
    foreach my $i (0..$data_dimensionality-1) {
        $result[$i] = 0.0;
    }
    foreach my $id (@arr_of_ids) {
        my $ele = $self->{_data_hash}->{$id};
        my $i = 0;
        foreach my $component (@$ele) {
            $result[$i] += $component;
            $i++;
        }
    }
    return \@result;
}

# This is the main module version:
sub visualize_clusters_on_sphere {
    my $self = shift;
    my $visualization_msg = shift;
    my $clusters = deep_copy_AoA(shift);
    my $hardcopy_format = shift;
    my $pause_time = shift;
    my $d = $self->{_data_dimensions};
    my $temp_file = "__temp_" . $self->{_datafile};
    $temp_file =~ s/\.\w+$/\.txt/;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    my @all_tags = "A".."Z";
    my @retagged_clusters;
    foreach my $cluster (@$clusters) {
        my $label = shift @all_tags;
        my @retagged_cluster = 
           map {$_ =~ s/^(\w+?)_(\w+)/$label . "_$2 @{$self->{_data_hash}->{$_}}"/e;$_} @$cluster;
        push @retagged_clusters, \@retagged_cluster;
    }
    my %clusters;
    foreach my $cluster (@retagged_clusters) {    
        foreach my $record (@$cluster) { 
            my @splits = grep $_, split /\s+/, $record;
            $splits[0] =~ /(\w+?)_.*/;
            my $primary_cluster_label = $1;
            my @coords = @splits[1..$d];
            push @{$clusters{$primary_cluster_label}}, \@coords;
        }
    }
    foreach my $key (sort {"\L$a" cmp "\L$b"} keys %clusters) {
        map {print OUTPUT "$_"} map {"@$_\n"} @{$clusters{$key}};
        print OUTPUT "\n\n";
    }
    my @sorted_cluster_keys = sort {"\L$a" cmp "\L$b"} keys %clusters;
    close OUTPUT;   
    my $plot;
    unless (defined $pause_time) {
        $plot = Graphics::GnuplotIF->new( persist => 1 );
    } else {
        $plot = Graphics::GnuplotIF->new();
    }
    my $arg_string = "";
    $plot->gnuplot_cmd( "set hidden3d" ) unless $self->{_show_hidden_in_3D_plots};
    $plot->gnuplot_cmd( "set title \"$visualization_msg\"" );
    $plot->gnuplot_cmd( "set noclip" );
    $plot->gnuplot_cmd( "set pointsize 2" );
    $plot->gnuplot_cmd( "set parametric" );
    $plot->gnuplot_cmd( "set size ratio 1" );
    $plot->gnuplot_cmd( "set xlabel \"X\"" );
    $plot->gnuplot_cmd( "set ylabel \"Y\"" );
    $plot->gnuplot_cmd( "set zlabel \"Z\"" );
    if ($hardcopy_format) {
        $plot->gnuplot_cmd( "set terminal png" );
        my $image_file_name = "$visualization_msg\.$hardcopy_format";
        $plot->gnuplot_cmd( "set output \"$image_file_name\"" );
        $plot->gnuplot_cmd( "unset hidden3d" );
    }
    # set the range for azimuth angles:
    $plot->gnuplot_cmd( "set urange [0:2*pi]" );
    # set the range for the elevation angles:
    $plot->gnuplot_cmd( "set vrange [-pi/2:pi/2]" );
    # Parametric functions for the sphere
#    $plot->gnuplot_cmd( "r=1" );
    if ($self->{_scale_factor}) {
        $plot->gnuplot_cmd( "r=$self->{_scale_factor}" );
    } else {
        $plot->gnuplot_cmd( "r=1" );
    }
    $plot->gnuplot_cmd( "fx(v,u) = r*cos(v)*cos(u)" );
    $plot->gnuplot_cmd( "fy(v,u) = r*cos(v)*sin(u)" );
    $plot->gnuplot_cmd( "fz(v)   = r*sin(v)" );
    my $sphere_arg_str = "fx(v,u),fy(v,u),fz(v) notitle with lines lt 0,";
    foreach my $i (0..scalar(keys %clusters)-1) {
        my $j = $i + 1;
        # The following statement puts the titles on the data points
        $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"$sorted_cluster_keys[$i] \" with points lt $j pt $j, ";
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;
    $plot->gnuplot_cmd( "splot $sphere_arg_str $arg_string" );
    $plot->gnuplot_pause( $pause_time ) if defined $pause_time;
}


###################################   Support Routines  ########################################

sub cluster_split {
    my $cluster = shift;
    my $how_many = shift;
    my @cluster_fragments;
    foreach my $i (0..$how_many-1) {
        $cluster_fragments[$i] = [];
    }
    my $delta = int( scalar(@$cluster) / $how_many );
    my $j = 0;
    foreach my $i (0..@$cluster-1) {
        push @{$cluster_fragments[int($i/$delta)]}, $cluster->[$i];
    }
    my $how_many_accounted_for = reduce {$a + $b} map {scalar(@$_)} @cluster_fragments;
    foreach my $frag (@cluster_fragments) {
        print "fragment: @$frag\n";
    }
    die "the fragmentation could not account for all the data" 
        unless @$cluster == $how_many_accounted_for;
    return @cluster_fragments;
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

sub display_mean_and_covariance {
    my $mean = shift;
    my $covariance = shift;
    print "\nDisplay the mean:\n";
    display_matrix($mean);
    print "\nDisplay the covariance:\n";
    display_matrix($covariance);
}

sub check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / datafile
                            mask
                            K
                            P
                            terminal_output
                            cluster_search_multiplier
                            max_iterations
                            delta_reconstruction_error
                            visualize_each_iteration
                            show_hidden_in_3D_plots
                            make_png_for_each_iteration
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

sub display_matrix {
    my $matrix = shift;
    my $nrows = $matrix->rows();
    my $ncols = $matrix->cols();
    print "\nDisplaying a matrix of size $nrows rows and $ncols columns:\n";
    foreach my $i (0..$nrows-1) {
        my $row = $matrix->row($i);
        my @row_as_list = $row->as_list;
#        print "@row_as_list\n";
        map { printf("%.4f ", $_) } @row_as_list;
        print "\n";
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

# from perl docs:
sub fisher_yates_shuffle {                
    my $arr =  shift;                
    my $i = @$arr;                   
    while (--$i) {                   
        my $j = int rand( $i + 1 );  
        @$arr[$i, $j] = @$arr[$j, $i]; 
    }
}

#########################  Generating Synthetic Data for Manifold Clustering  ##########################

##################################      Class DataGenerator     ########################################

##  The embedded class defined below is for generating synthetic data for
##  experimenting with linear manifold clustering when the data resides on the
##  surface of a sphere.  See the script generate_data_on_a_sphere.pl in the
##  `examples' directory for how to specify the number of clusters and the spread of
##  each cluster in the data that is generated.

package DataGenerator;

use strict;                                                         
use Carp;

sub new {                                                           
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if _check_for_illegal_params3(@params) == 0;   
    bless {
        _output_file                       =>   $args{output_file} 
                                                   || croak("name for output_file required"),
        _total_number_of_samples_needed    =>   $args{total_number_of_samples_needed} 
                                                   || croak("total_number_of_samples_needed required"),
        _number_of_clusters_on_sphere      =>   $args{number_of_clusters_on_sphere}   || 3,
        _cluster_width                     =>   $args{cluster_width}   || 0.1,
        _show_hidden_in_3D_plots           =>   $args{show_hidden_in_3D_plots} || 1,
        _debug                             =>   $args{debug} || 0,
    }, $class;
}

sub _check_for_illegal_params3 {
    my @params = @_;
    my @legal_params = qw / output_file
                            total_number_of_samples_needed
                            number_of_clusters_on_sphere
                            cluster_width
                            show_hidden_in_3D_plots
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

##  We first generate a set of points randomly on the unit sphere --- the number of
##  points being equal to the number of clusters desired.  These points will serve as
##  cluster means (or, as cluster centroids) subsequently when we ask
##  Math::Random::random_multivariate_normal($N, @m, @covar) to return $N number of
##  points on the sphere.  The second argument is the cluster mean and the third
##  argument the cluster covariance.  For the synthetic data, we set the cluster
##  covariance to a 2x2 diagonal matrix, with the (0,0) element corresponding to the
##  variance along the azimuth direction and the (1,1) element corresponding to the
##  variance along the elevation direction.
##
##  When you generate the points in the 2D spherical coordinates of
##  (azimuth,elevation), you also need `wrap-around' logic for those points yielded by
##  the multivariate-normal function whose azimuth angle is outside the interval
##  (0,360) and/or whose elevation angle is outside the interval (-90,90).
##
##  Note that the first of the two dimensions for which the multivariate-normal
##  function returns the points is for the azimuth angle and the second for the
##  elevation angle.
##
##  With regard to the relationship of the Cartesian coordinates to the spherical
##  (azimuth, elevation) coordinates, we assume that (x,y) is the horizontal plane
##  and z the vertical axis.  The elevation angle theta is measure with respect to
##  the XY-plane.  The highest point on the sphere (the Zenith) corresponds to the
##  elevation angle of +90 and the lowest points on the sphere (the Nadir)
##  corresponds to the elevation angle of -90.  The azimuth is measured with respect
##  X-axis.  The range of the azimuth is from 0 to 360 degrees.  The elevation is
##  measured from the XY plane and its range is (-90,90) degrees.
sub gen_data_and_write_to_csv {
    my $self = shift;
    my $K = $self->{_number_of_clusters_on_sphere};
    # $N is the number of samples to be generated for each cluster:
    my $N = int($self->{_total_number_of_samples_needed} / $K);
    my $output_file = $self->{_output_file};
    # Designated all of the data elements in a cluster by a letter that is followed by
    # an integer that identifies a specific data element.
    my @point_labels = ('a'..'z');
    # Our first job is to define $K random points in the 2D space (azimuth,
    # elevation) to serve as cluster centers on the surface of the sphere.  This we
    # do by calling a uniformly distributed 1-D random number generator, first for
    # the azimuth and then for the elevation in the loop shown below:
    my @cluster_centers;
    my @covariances;
    foreach my $i (0..$K-1) {
        my $azimuth = rand(360);
        my $elevation =  rand(90) - 90; 
        my @mean = ($azimuth, $elevation);
        push @cluster_centers, \@mean;
        my $cluster_covariance;
        # The j-th dimension is for azimuth and k-th for elevation for the directions
        # to surface of the sphere:
        foreach my $j (0..1) {
            foreach my $k (0..1) {
                $cluster_covariance->[$j]->[$k] = ($self->{_cluster_width} * 360.0) ** 2 
                                                                        if $j == 0 && $k == 0;
                $cluster_covariance->[$j]->[$k] = ($self->{_cluster_width} * 180.0) ** 2 
                                                                        if $j == 1 && $k == 1;
                $cluster_covariance->[$j]->[$k] = 0.0 if $j != $k;
            }
        }
        push @covariances, $cluster_covariance;
    }
    if ($self->{_debug}) {
        foreach my $i (0..$K-1) {
            print "\n\nCluster center:  @{$cluster_centers[$i]}\n";
            print "\nCovariance:\n";
            foreach my $j (0..1) {
                foreach my $k (0..1) {
                    print "$covariances[$i]->[$j]->[$k]  ";
                }
                print "\n";
            }
        }
    }
    my @data_dump;
    foreach my $i (0..$K-1) {
        my @m = @{shift @cluster_centers};
        my @covar = @{shift @covariances};
        my @new_data = Math::Random::random_multivariate_normal($N, @m, @covar);
        if ($self->{_debug}) {
            print "\nThe points for cluster $i:\n";
            map { print "@$_   "; } @new_data;
            print "\n\n";        
        }
        my @wrapped_data;
        foreach my $d (@new_data) {
            my $wrapped_d;
            if ($d->[0] >= 360.0) {
                $wrapped_d->[0] = $d->[0] - 360.0;
            } elsif ($d->[0] < 0) {
                $wrapped_d->[0] = 360.0 - abs($d->[0]);
            }
            if ($d->[1] >= 90.0) {
                $wrapped_d->[0] = POSIX::fmod($d->[0] + 180.0, 360);
                $wrapped_d->[1] = 180.0 - $d->[1];
            } elsif ($d->[1] < -90.0) {
                $wrapped_d->[0] = POSIX::fmod($d->[0] + 180, 360);
                $wrapped_d->[1] = -180.0 - $d->[1];
            } 
            $wrapped_d->[0] = $d->[0] unless defined $wrapped_d->[0];
            $wrapped_d->[1] = $d->[1] unless defined $wrapped_d->[1];
            push @wrapped_data, $wrapped_d;
        }
        if ($self->{_debug}) {
            print "\nThe unwrapped points for cluster $i:\n";
            map { print "@$_   "; } @wrapped_data;
            print "\n\n";        
        }
        my $label = $point_labels[$i];
        my $j = 0;
        @new_data = map {unshift @$_, $label."_".$j; $j++; $_} @wrapped_data;
        push @data_dump, @new_data;
    }
    if ($self->{_debug}) {
        print "\n\nThe labeled points for clusters:\n";
        map { print "@$_\n"; } @data_dump;
    }
    fisher_yates_shuffle( \@data_dump );
    open OUTPUT, ">$output_file";
    my $total_num_of_points = $N * $K;
    print "Total number of data points that will be written out to the file: $total_num_of_points\n"
        if $self->{_debug};
    foreach my $ele (@data_dump) {
        my ($x,$y,$z);
        my $label = $ele->[0];
        my $azimuth = $ele->[1];
        my $elevation = $ele->[2];
        $x = cos($elevation) * cos($azimuth);
        $y = cos($elevation) * sin($azimuth); 
        $z = sin($elevation);
        my $csv_str = join ",", ($label,$x,$y,$z);
        print OUTPUT "$csv_str\n";
    }
    print "\n\n";
    print "Data written out to file $output_file\n" if $self->{_debug};
    close OUTPUT;
}

# This version for the embedded class for data generation
sub visualize_data_on_sphere {
    my $self = shift;
    my $datafile = shift;
    my $filename = File::Basename::basename($datafile);
    my $temp_file = "__temp_" . $filename;
    $temp_file =~ s/\.\w+$/\.txt/;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    open INPUT, "< $filename" or die "Unable to open $filename: $!";
    local $/ = undef;
    my @all_records = split /\s+/, <INPUT>;
    my %clusters;
    foreach my $record (@all_records) {    
        my @splits = split /,/, $record;
        my $record_name = shift @splits;
        $record_name =~ /(\w+?)_.*/;
        my $primary_cluster_label = $1;
        push @{$clusters{$primary_cluster_label}}, \@splits;
    }
    foreach my $key (sort {"\L$a" cmp "\L$b"} keys %clusters) {
        map {print OUTPUT "$_"} map {"@$_\n"} @{$clusters{$key}};
        print OUTPUT "\n\n";
    }
    my @sorted_cluster_keys = sort {"\L$a" cmp "\L$b"} keys %clusters;
    close OUTPUT;   
    my $plot = Graphics::GnuplotIF->new( persist => 1 );
    my $arg_string = "";
    $plot->gnuplot_cmd( "set noclip" );
    $plot->gnuplot_cmd( "set hidden3d" ) unless $self->{_show_hidden_in_3D_plots};
    $plot->gnuplot_cmd( "set pointsize 2" );
    $plot->gnuplot_cmd( "set parametric" );
    $plot->gnuplot_cmd( "set size ratio 1" );
    $plot->gnuplot_cmd( "set xlabel \"X\"" );
    $plot->gnuplot_cmd( "set ylabel \"Y\"" );
    $plot->gnuplot_cmd( "set zlabel \"Z\"" );
    # set the range for azimuth angles:
    $plot->gnuplot_cmd( "set urange [0:2*pi]" );
    # set the range for the elevation angles:
    $plot->gnuplot_cmd( "set vrange [-pi/2:pi/2]" );
    # Parametric functions for the sphere
    $plot->gnuplot_cmd( "r=1" );
    $plot->gnuplot_cmd( "fx(v,u) = r*cos(v)*cos(u)" );
    $plot->gnuplot_cmd( "fy(v,u) = r*cos(v)*sin(u)" );
    $plot->gnuplot_cmd( "fz(v)   = r*sin(v)" );
    my $sphere_arg_str = "fx(v,u),fy(v,u),fz(v) notitle with lines lt 0,";
    foreach my $i (0..scalar(keys %clusters)-1) {
        my $j = $i + 1;
        # The following statement puts the titles on the data points
        $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"$sorted_cluster_keys[$i] \" with points lt $j pt $j, ";
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;
#    $plot->gnuplot_cmd( "splot $arg_string" );
    $plot->gnuplot_cmd( "splot $sphere_arg_str $arg_string" );
}

sub DESTROY {
    use File::Basename;
    my $filename = basename($_[0]->{_output_file});
    $filename =~ s/\.\w+$/\.txt/;
    unlink "__temp_" . $filename;
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

1;

=pod

=head1 NAME

Algorithm::LinearManifoldDataClusterer --- for clustering data that resides on a
low-dimensional manifold in a high-dimensional measurement space

=head1 SYNOPSIS

  #  You'd begin with:

  use Algorithm::LinearManifoldDataClusterer;

  #  You'd next name the data file:

  my $datafile = "mydatafile.csv";

  #  Your data must be in the CSV format, with one of the columns containing a unique
  #  symbolic tag for each data record. You tell the module which column has the
  #  symbolic tag and which columns to use for clustering through a mask such as

  my $mask = "N111";

  #  which says that the symbolic tag is in the first column and that the numerical
  #  data in the next three columns is to be used for clustering.  If your data file
  #  had, say, five columns and you wanted only the last three columns to be
  #  clustered, the mask would become `N0111' assuming that that the symbolic tag is
  #  still in the first column.

  #  Now you must construct an instance of the clusterer through a call such as:

  my $clusterer = Algorithm::LinearManifoldDataClusterer->new(
                                    datafile => $datafile,
                                    mask     => $mask,
                                    K        => 3,     
                                    P        => 2,     
                                    max_iterations => 15,
                                    cluster_search_multiplier => 2,
                                    delta_reconstruction_error => 0.001,
                                    terminal_output => 1,
                                    visualize_each_iteration => 1,
                                    show_hidden_in_3D_plots => 1,
                                    make_png_for_each_iteration => 1,
                  );

  #  where the parameter K specifies the number of clusters you expect to find in
  #  your data and the parameter P is the dimensionality of the manifold on which the
  #  data resides.  The parameter cluster_search_multiplier is for increasing the
  #  odds that the random seeds chosen initially for clustering will populate all the
  #  clusters.  Set this parameter to a low number like 2 or 3. The parameter
  #  max_iterations places a hard limit on the number of iterations that the
  #  algorithm is allowed.  The actual number of iterations is controlled by the
  #  parameter delta_reconstruction_error.  The iterations stop when the change in
  #  the total "reconstruction error" from one iteration to the next is smaller than
  #  the value specified by delta_reconstruction_error.

  #  Next, you must get the module to read the data for clustering:

  $clusterer->get_data_from_csv();

  #  Finally, you invoke linear manifold clustering by:

  my $clusters = $clusterer->linear_manifold_clusterer();

  #  The value returned by this call is a reference to an array of anonymous arrays,
  #  with each anonymous array holding one cluster.  If you wish, you can have the
  #  module write the clusters to individual files by the following call:

  $clusterer->write_clusters_to_files($clusters);

  #  If you want to see how the reconstruction error changes with the iterations, you
  #  can make the call:

  $clusterer->display_reconstruction_errors_as_a_function_of_iterations();

  #  When your data is 3-dimensional and when the clusters reside on a surface that
  #  is more or less spherical, you can visualize the clusters by calling

  $clusterer->visualize_clusters_on_sphere("final clustering", $clusters);

  #  where the first argument is a label to be displayed in the 3D plot and the
  #  second argument the value returned by calling linear_manifold_clusterer().

  #  SYNTHETIC DATA GENERATION:

  #  The module includes an embedded class, DataGenerator, for generating synthetic
  #  three-dimensional data that can be used to experiment with the clustering code.
  #  The synthetic data, written out to a CSV file, consists of Gaussian clusters on
  #  the surface of a sphere.  You can control the number of clusters, the width of
  #  each cluster, and the number of samples in the clusters by giving appropriate
  #  values to the constructor parameters as shown below:

  use strict;
  use Algorithm::LinearManifoldDataClusterer;

  my $output_file = "4_clusters_on_a_sphere_1000_samples.csv";

  my $training_data_gen = DataGenerator->new(
                             output_file => $output_file,
                             cluster_width => 0.015,
                             total_number_of_samples_needed => 1000,
                             number_of_clusters_on_sphere => 4,
                             show_hidden_in_3D_plots => 0,
                          );
  $training_data_gen->gen_data_and_write_to_csv();
  $training_data_gen->visualize_data_on_sphere($output_file);


=head1 CHANGES

Version 1.01: Typos and other errors removed in the documentation. Also included in
the documentation a link to a tutorial on data processing on manifolds.


=head1 DESCRIPTION

If you are new to machine learning and data clustering on linear and nonlinear
manifolds, your first question is likely to be: What is a manifold?  A manifold is a
space that is locally Euclidean. And a space is locally Euclidean if it allows for
the points in a small neighborhood to be represented by, say, the Cartesian
coordinates and if the distances between the points in the neighborhood are given by
the Euclidean metric.  For an example, the set of all points on the surface of a
sphere does NOT constitute a Euclidean space.  Nonetheless, if you confined your
attention to a small enough neighborhood around a point, the space would seem to be
locally Euclidean.  The surface of a sphere is a 2-dimensional manifold embedded in a
3-dimensional space.  A plane in a 3-dimensional space is also a 2-dimensional
manifold. You would think of the surface of a sphere as a nonlinear manifold, whereas
a plane would be a linear manifold.  However, note that any nonlinear manifold is
locally a linear manifold.  That is, given a sufficiently small neighborhood on a
nonlinear manifold, you can always think of it as a locally flat surface.

As to why we need machine learning and data clustering on manifolds, there exist many
important applications in which the measured data resides on a nonlinear manifold.
For example, when you record images of a human face from different angles, all the
image pixels taken together fall on a low-dimensional surface in a high-dimensional
measurement space. The same is believed to be true for the satellite images of a land
mass that are recorded with the sun at different angles with respect to the direction
of the camera.

Reducing the dimensionality of the sort of data mentioned above is critical to the
proper functioning of downstream classification algorithms, and the most popular
traditional method for dimensionality reduction is the Principal Components Analysis
(PCA) algorithm.  However, using PCA is tantamount to passing a linear least-squares
hyperplane through the surface on which the data actually resides.  As to why that
might be a bad thing to do, just imagine the consequences of assuming that your data
falls on a straight line when, in reality, it falls on a strongly curving arc.  This
is exactly what happens with PCA --- it gives you a linear manifold approximation to
your data that may actually reside on a curved surface.

That brings us to the purpose of this module, which is to cluster data that resides
on a nonlinear manifold.  Since a nonlinear manifold is locally linear, we can think
of each data cluster on a nonlinear manifold as falling on a locally linear portion
of the manifold, meaning on a hyperplane.  The logic of the module is based on
finding a set of hyperplanes that best describes the data, with each hyperplane
derived from a local data cluster.  This is like constructing a piecewise linear
approximation to data that falls on a curve as opposed to constructing a single
straight line approximation to all of the data.  So whereas the frequently used PCA
algorithm gives you a single hyperplane approximation to all your data, what this
module returns is a set of hyperplane approximations, with each hyperplane derived by
applying the PCA algorithm locally to a data cluster.

That brings us to the problem of how to actually discover the best set of hyperplane
approximations to the data.  What is probably the most popular algorithm today for
that purpose is based on the following key idea: Given a set of subspaces to which a
data element can be assigned, you assign it to that subspace for which the
B<reconstruction error> is the least.  But what do we mean by a B<subspace> and what
is B<reconstruction error>?

To understand the notions of B<subspace> and B<reconstruction-error>, let's revisit
the traditional approach of dimensionality reduction by the PCA algorithm.  The PCA
algorithm consists of: (1) Subtracting from each data element the global mean of the
data; (2) Calculating the covariance matrix of the data; (3) Carrying out an
eigendecomposition of the covariance matrix and ordering the eigenvectors according
to decreasing values of the corresponding eigenvalues; (4) Forming a B<subspace> by
discarding the trailing eigenvectors whose corresponding eigenvalues are relatively
small; and, finally, (5) projecting all the data elements into the subspace so
formed. The error incurred in representing a data element by its projection into the
subspace is known as the B<reconstruction error>.  This error is the projection of
the data element into the space spanned by the discarded trailing eigenvectors.

I<In linear-manifold based machine learning, instead of constructing a single
subspace in the manner described above, we construct a set of subspaces, one for each
data cluster on the nonlinear manifold.  After the subspaces have been constructed, a
data element is assigned to that subspace for which the reconstruction error is the
least.> On the face of it, this sounds like a chicken-and-egg sort of a problem.  You
need to have already clustered the data in order to construct the subspaces at
different places on the manifold so that you can figure out which cluster to place a
data element in.

Such problems, when they do possess a solution, are best tackled through iterative
algorithms in which you start with a guess for the final solution, you rearrange the
measured data on the basis of the guess, and you then use the new arrangement of the
data to refine the guess.  Subsequently, you iterate through the second and the third
steps until you do not see any discernible changes in the new arrangements of the
data.  This forms the basis of the clustering algorithm that is described under
B<Phase 1> in the section that follows.  This algorithm was first proposed in the
article "Dimension Reduction by Local Principal Component Analysis" by Kambhatla and
Leen that appeared in the journal Neural Computation in 1997.

Unfortunately, experiments show that the algorithm as proposed by Kambhatla and Leen
is much too sensitive to how the clusters are seeded initially.  To get around this
limitation of the basic clustering-by-minimization-of-reconstruction-error, this
module implements a two phased approach.  In B<Phase 1>, we introduce a multiplier
effect in our search for clusters by looking for C<M*K> clusters instead of the main
C<K> clusters.  In this manner, we increase the odds that each original cluster will
be visited by one or more of the C<M*K> randomly selected seeds at the beginning,
where C<M> is the integer value given to the constructor parameter
C<cluster_search_multiplier>.  Subsequently, we merge the clusters that belong
together in order to form the final C<K> clusters.  That work is done in B<Phase 2>
of the algorithm.

For the cluster merging operation in Phase 2, we model the C<M*K> clusters as the
nodes of an attributed graph in which the weight given to an edge connecting a pair
of nodes is a measure of the similarity between the two clusters corresponding to the
two nodes.  Subsequently, we use spectral clustering to merge the most similar nodes
in our quest to partition the data into C<K> clusters.  For that purpose, we use the
Shi-Malik normalized cuts algorithm.  The pairwise node similarity required by this
algorithm is measured by the C<pairwise_cluster_similarity()> method of the
C<LinearManifoldDataClusterer> class.  The smaller the overall reconstruction error
when all of the data elements in one cluster are projected into the other's subspace
and vice versa, the greater the similarity between two clusters.  Additionally, the
smaller the distance between the mean vectors of the clusters, the greater the
similarity between two clusters.  The overall similarity between a pair of clusters
is a combination of these two similarity measures.

For additional information regarding the theoretical underpinnings of the algorithm
implemented in this module, visit
L<https://engineering.purdue.edu/kak/Tutorials/ClusteringDataOnManifolds.pdf>


=head1 SUMMARY OF THE ALGORITHM

We now present a summary of the two phases of the algorithm implemented in this
module.  Note particularly the important role played by the constructor parameter
C<cluster_search_multiplier>.  It is only when the integer value given to this
parameter is greater than 1 that Phase 2 of the algorithm kicks in.

=over 4

=item B<Phase 1:>

Through iterative minimization of the total reconstruction error, this phase of the
algorithm returns C<M*K> clusters where C<K> is the actual number of clusters you
expect to find in your data and where C<M> is the integer value given to the
constructor parameter C<cluster_search_multiplier>.  As previously mentioned, on
account of the sensitivity of the reconstruction-error based clustering to how the
clusters are initially seeded, our goal is to look for C<M*K> clusters with the idea
of increasing the odds that each of the C<K> clusters will see at least one seed at
the beginning of the algorithm.

=over 4

=item Step 1:

Randomly choose C<M*K> data elements to serve as the seeds for that many clusters.

=item Step 2:

Construct initial C<M*K> clusters by assigning each data element to that cluster
whose seed it is closest to.

=item Step 3:

Calculate the mean and the covariance matrix for each of the C<M*K> clusters and
carry out an eigendecomposition of the covariance matrix.  Order the eigenvectors in
decreasing order of the corresponding eigenvalues.  The first C<P> eigenvectors
define the subspace for that cluster.  Use the space spanned by the remaining
eigenvectors --- we refer to them as the trailing eigenvectors --- for calculating
the reconstruction error.

=item Step 4:

Taking into account the mean associated with each cluster, re-cluster the entire data
set on the basis of the least reconstruction error.  That is, assign each data
element to that subspace for which it has the smallest reconstruction error.
Calculate the total reconstruction error associated with all the data elements.  (See
the definition of the reconstruction error in the C<Description> section.)

=item Step 5:

Stop iterating if the change in the total reconstruction error from the previous 
iteration to the current iteration is less than the value specified by the constructor
parameter C<delta_reconstruction_error>.  Otherwise, go back to Step 3.

=back

=item B<Phase 2:>

This phase of the algorithm uses graph partitioning to merge the C<M*K> clusters back
into the C<K> clusters you expect to see in your data.  Since the algorithm whose
steps are presented below is invoked recursively, let's assume that we have C<N>
clusters that need to be merged by invoking the Shi-Malik spectral clustering
algorithm as described below:

=over 4

=item Step 1: 

Form a graph whose C<N> nodes represent the C<N> clusters.  (For the very first
invocation of this step, we have C<N = M*K>.)

=item Step 2:

Construct an C<NxN> similarity matrix for the nodes in the graph. The C<(i,j)>-th
element of this matrix is the pairwise similarity between the clusters indexed C<i>
and C<j>. Calculate this similarity on the basis of the following two criteria: (1)
The total reconstruction error when the data elements in the cluster indexed C<j> are
projected into the subspace for the cluster indexed C<i> and vice versa. And (2) The
distance between the mean vectors associated with the two clusters.

=item Step 3:

Calculate the symmetric normalized Laplacian of the similarity matrix.  We use C<A>
to denote the symmetric normalized Laplacian.

=item Step 4:

Carry out an eigendecomposition of the C<A> matrix and choose the eigenvector
corresponding to the second smallest eigenvalue for bipartitioning the graph on the
basis of the sign of the values in the eigenvector.

=item Step 5:

If the bipartition of the previous step yields one-versus-the-rest kind of a
partition, add the `one' cluster to the output list of clusters and invoke graph
partitioning recursively on the `rest' by going back to Step 1.  On the other hand,
if the cardinality of both the partitions returned by Step 4 exceeds 1, invoke graph
partitioning recursively on both partitions.  Stop when the list of clusters in the
output list equals C<K>.

=item Step 6:

In general, the C<K> clusters obtained by recursive graph partitioning will not cover
all of the data.  So, for the final step, assign each data element not covered by the
C<K> clusters to that cluster for which its reconstruction error is the least.

=back

=back

=head1 FAIL-FIRST BIAS OF THE MODULE

As you would expect for all such iterative algorithms, the module carries no
theoretical guarantee that it will give you correct results. But what does that mean?
Suppose you create synthetic data that consists of Gaussian looking disjoint clusters
on the surface of a sphere, would the module always succeed in separating out the
clusters?  The module carries no guarantees to that effect --- especially considering
that Phase 1 of the algorithm is sensitive to how the clusters are seeded at the
beginning. Although this sensitivity is mitigated by the cluster merging step when
greater-than-1 value is given to the constructor option C<cluster_search_multiplier>,
a plain vanilla implementation of the steps in Phase 1 and Phase 2 would nonetheless
carry significant risk that you'll end up with incorrect clustering results.

To further reduce this risk, the module has been programmed so that it terminates
immediately if it suspects that the cluster solution being developed is unlikely to
be fruitful.  The heuristics used for such terminations are conservative --- since
the cost of termination is only that the user will have to run the code again, which
at worst only carries an element of annoyance with it.  The three "Fail First"
heuristics currently programmed into the module are based on simple "unimodality
testing", testing for "congruent clusters," and testing for dominant cluster support
in the final stage of the recursive invocation of the graph partitioning step.  The
unimodality testing is as elementary as it can be --- it only checks for the number
of data samples within a certain radius of the mean in relation to the total number
of data samples in the cluster.

When the program terminates under such conditions, it prints out the following message
in your terminal window:

    Bailing out!  

Given the very simple nature of testing that is carried for the "Fail First" bias, do
not be surprised if the results you get for your data simply look wrong.  If most
runs of the module produce wrong results for your application, that means that the
module logic needs to be strengthened further.  The author of this module would love
to hear from you if that is the case.

=head1 METHODS

The module provides the following methods for linear-manifold based clustering, for
cluster visualization, and for the generation of data for testing the clustering algorithm:

=over 4

=item B<new():>

    my $clusterer = Algorithm::LinearManifoldDataClusterer->new(
                                        datafile                    => $datafile,
                                        mask                        => $mask,
                                        K                           => $K,
                                        P                           => $P,     
                                        cluster_search_multiplier   => $C,
                                        max_iterations              => $max_iter,
                                        delta_reconstruction_error  => 0.001,
                                        terminal_output             => 1,
                                        write_clusters_to_files     => 1,
                                        visualize_each_iteration    => 1,
                                        show_hidden_in_3D_plots     => 1,
                                        make_png_for_each_iteration => 1,
                    );

A call to C<new()> constructs a new instance of the
C<Algorithm::LinearManifoldDataClusterer> class.

=back

=head2 Constructor Parameters

=over 8

=item C<datafile>:

This parameter names the data file that contains the multidimensional data records
you want the module to cluster.  This file must be in CSV format and each record in
the file must include a symbolic tag for the record.  Here are first few rows of such
a CSV file in the C<examples> directory:

    d_161,0.0739248630173239,0.231119293395665,-0.970112873251437
    a_59,0.459932215884786,0.0110216469739639,0.887885623314902
    a_225,0.440503220903039,-0.00543366086464691,0.897734586447273
    a_203,0.441656364946433,0.0437191337788422,0.896118459046532
    ...
    ...

What you see in the first column --- C<d_161>, C<a_59>, C<a_225>, C<a_203> --- are
the symbolic tags associated with four 3-dimensional data records.

=item C<mask>:

This parameter supplies the mask to be applied to the columns of your data file.  For
the data file whose first few records are shown above, the mask should be C<N111>
since the symbolic tag is in the first column of the CSV file and since, presumably,
you want to cluster the data in the next three columns.

=item C<K>:

This parameter supplies the number of clusters you are looking for.

=item C<P>:

This parameter specifies the dimensionality of the manifold on which the data resides.

=item C<cluster_search_multiplier>:

As should be clear from the C<Summary of the Algorithm> section, this parameter plays
a very important role in the successful clustering of your data.  As explained in
C<Description>, the basic algorithm used for clustering in Phase 1 --- clustering by
the minimization of the reconstruction error --- is sensitive to the choice of the
cluster seeds that are selected randomly at the beginning of the algorithm.  Should
it happen that the seeds miss one or more of the clusters, the clustering produced is
likely to not be correct.  By giving an integer value to C<cluster_search_multiplier>
that is greater than 1, you'll increase the odds that the randomly selected seeds
will see all clusters.  When you set C<cluster_search_multiplier> to C<M>, you ask
Phase 1 of the algorithm to construct C<M*K> clusters as opposed to just C<K>
clusters. Subsequently, in Phase 2, the module uses inter-cluster similarity based
graph partitioning to merge the C<M*K> clusters into C<K> clusters.

=item C<max_iterations>:

This hard limits the number of iterations in Phase 1 of the algorithm.  Ordinarily,
the iterations stop automatically when the change in the total reconstruction error
from one iteration to the next is less than the value specified by the parameter
C<delta_reconstruction_error>.

=item C<delta_reconstruction_error>:

It is this parameter that determines when the iterations will actually terminate in
Phase 1 of the algorithm.  When the difference in the total reconstruction error from
one iteration to the next is less than the value given to this parameter, the
iterations come to an end. B<IMPORTANT: I have noticed that the larger the number of
data samples that need to be clustered, the larger must be the value give to this
parameter.  That makes intuitive sense since the total reconstruction error is the
sum of all such errors for all of the data elements.> Unfortunately, the best value
for this parameter does NOT appear to depend linearly on the total number of data
records to be clustered.

=item C<terminal_output>:

When this parameter is set, you will see in your terminal window the different
clusters as lists of the symbolic tags associated with the data records.  You will
also see in your terminal window the output produced by the different steps of the
graph partitioning algorithm as smaller clusters are merged to form the final C<K>
clusters --- assuming that you set the parameter C<cluster_search_multiplier> to an
integer value that is greater than 1.

=item C<visualize_each_iteration>:

As its name implies, when this option is set to 1, you'll see 3D plots of the
clustering results for each iteration --- but only if your data is 3-dimensional.

=item C<show_hidden_in_3D_plots>:

This parameter is important for controlling the visualization of the clusters on the
surface of a sphere.  If the clusters are too spread out, seeing all of the clusters
all at once can be visually confusing.  When you set this parameter, the clusters on
the back side of the sphere will not be visible.  Note that no matter how you set
this parameter, you can interact with the 3D plot of the data and rotate it with your
mouse pointer to see all of the data that is output by the clustering code.

=item C<make_png_for_each_iteration>:

If you set this option to 1, the module will output a Gnuplot in the form of a PNG
image for each iteration in Phase 1 of the algorithm.  In Phase 2, the module will
output the clustering result produced by the graph partitioning algorithm.

=back

=over

=item B<get_data_from_csv()>:

    $clusterer->get_data_from_csv();

As you can guess from its name, the method extracts the data from the CSV file named
in the constructor.

=item B<linear_manifold_clusterer()>:

    $clusterer->linear_manifold_clusterer();   

    or 

    my $clusters = $clusterer->linear_manifold_clusterer();

This is the main call to the linear-manifold based clusterer.  The first call works
by side-effect, meaning that you will see the clusters in your terminal window and
they would be written out to disk files (depending on the constructor options you
have set).  The second call also returns the clusters as a reference to an array of
anonymous arrays, each holding the symbolic tags for a cluster.

=item B<display_reconstruction_errors_as_a_function_of_iterations()>:

    $clusterer->display_reconstruction_errors_as_a_function_of_iterations();

This method would normally be called after the clustering is completed to see how the
reconstruction errors decreased with the iterations in Phase 1 of the overall
algorithm.

=item B<write_clusters_to_files()>:

    $clusterer->write_clusters_to_files($clusters);

As its name implies, when you call this methods, the final clusters would be written
out to disk files.  The files have names like:

     cluster0.txt 
     cluster1.txt 
     cluster2.txt
     ...
     ...

Before the clusters are written to these files, the module destroys all files with
such names in the directory in which you call the module.

=item B<visualize_clusters_on_sphere()>:

    $clusterer->visualize_clusters_on_sphere("final clustering", $clusters);

or

    $clusterer->visualize_clusters_on_sphere("final_clustering", $clusters, "png");

If your data is 3-dimensional and it resides on the surface of a sphere (or in the
vicinity of such a surface), you may be able to use these methods for the
visualization of the clusters produced by the algorithm.  The first invocation
produces a Gnuplot in a terminal window that you can rotate with your mouse pointer.
The second invocation produces a `.png' image of the plot.

=item B<auto_retry_clusterer()>:

    $clusterer->auto_retry_clusterer();

or

    my $clusters = $clusterer->auto_retry_clusterer();

As mentioned earlier, the module is programmed in such a way that it is more likely
to fail than to give you a wrong answer.  If manually trying the clusterer repeatedly
on a data file is frustrating, you can use C<auto_retry_clusterer()> to automatically
make repeated attempts for you.  See the script C<example4.pl> for how you can use
C<auto_retry_clusterer()> in your own code.

=back

=head1 GENERATING SYNTHETIC DATA FOR EXPERIMENTING WITH THE CLUSTERER

The module file also contains a class named C<DataGenerator> for generating synthetic
data for experimenting with linear-manifold based clustering.  At this time, only
3-dimensional data that resides in the form of Gaussian clusters on the surface of a
sphere is generated.  The generated data is placed in a CSV file.  You construct an
instance of the C<DataGenerator> class by a call like:

=over 4

=item B<new():>

    my $training_data_gen = DataGenerator->new(
                                 output_file => $output_file,
                                 cluster_width => 0.0005,
                                 total_number_of_samples_needed => 1000,
                                 number_of_clusters_on_sphere => 4,
                                 show_hidden_in_3D_plots => 0,
                            );

=back

=head2 Parameters for the DataGenerator constructor:

=over 8

=item C<output_file>:

The numeric values are generated using a bivariate Gaussian distribution whose two
independent variables are the azimuth and the elevation angles on the surface of a
unit sphere.  The mean of each cluster is chosen randomly and its covariance set in
proportion to the value supplied for the C< cluster_width> parameter.

=item C<cluster_width>:

This parameter controls the spread of each cluster on the surface of the unit sphere.

=item C<total_number_of_samples_needed>:

As its name implies, this parameter specifies the total number of data samples that
will be written out to the output file --- provided this number is divisible by the
number of clusters you asked for.  If the divisibility condition is not satisfied,
the number of data samples actually written out will be the closest it can be to the
number you specify for this parameter under the condition that equal number of
samples will be created for each cluster.

=item C<number_of_clusters_on_sphere>:

Again as its name implies, this parameters specifies the number of clusters that will
be produced on the surface of a unit sphere.

=item C<show_hidden_in_3D_plots>:

This parameter is important for the visualization of the clusters and it controls
whether you will see the generated data on the back side of the sphere.  If the
clusters are not too spread out, you can set this parameter to 0 and see all the
clusters all at once.  However, when the clusters are spread out, it can be visually
confusing to see the data on the back side of the sphere.  Note that no matter how
you set this parameter, you can interact with the 3D plot of the data and rotate it
with your mouse pointer to see all of the data that is generated.

=back

=over 4

=item B<gen_data_and_write_to_csv()>:

    $training_data_gen->gen_data_and_write_to_csv();

As its name implies, this method generates the data according to the parameters
specified in the DataGenerator constructor.

=item B<visualize_data_on_sphere()>:

    $training_data_gen->visualize_data_on_sphere($output_file);

You can use this method to visualize the clusters produced by the data generator.
Since the clusters are located at randomly selected points on a unit sphere, by
looking at the output visually, you can quickly reject what the data generator has
produced and try again.

=back

=head1 HOW THE CLUSTERS ARE OUTPUT

When the option C<terminal_output> is set in the constructor of the
C<LinearManifoldDataClusterer> class, the clusters are displayed on the terminal
screen.

And, when the option C<write_clusters_to_files> is set in the same constructor, the
module dumps the clusters in files named

    cluster0.txt
    cluster1.txt
    cluster2.txt
    ...
    ...

in the directory in which you execute the module.  The number of such files will
equal the number of clusters formed.  All such existing files in the directory are
destroyed before any fresh ones are created.  Each cluster file contains the symbolic
tags of the data samples in that cluster.

Assuming that the data dimensionality is 3, if you have set the constructor parameter
C<visualize_each_iteration>, the module will deposit in your directory printable PNG
files that are point plots of the different clusters in the different iterations of
the algorithm.  Such printable files are also generated for the initial clusters at
the beginning of the iterations and for the final clusters in Phase 1 of the
algorithm.  You will also see in your directory a PNG file for the clustering result
produced by graph partitioning in Phase 2.

Also, as mentioned previously, a call to C<linear_manifold_clusterer()> in your own
code will return the clusters to you directly.

=head1 REQUIRED

This module requires the following modules:

    List::Util
    File::Basename
    Math::Random
    Graphics::GnuplotIF
    Math::GSL::Matrix
    POSIX

=head1 THE C<examples> DIRECTORY

The C<examples> directory contains the following four scripts that you might want to
play with in order to become familiar with the module:

    example1.pl

    example2.pl

    example3.pl

    example4.pl

These scripts demonstrate linear-manifold based clustering on the 3-dimensional data
in the following three CSV files:

    3_clusters_on_a_sphere_498_samples.csv            (used in example1.pl and example4.pl)

    3_clusters_on_a_sphere_3000_samples.csv           (used in example2.pl)

    4_clusters_on_a_sphere_1000_samples.csv           (used in example3.pl)

Note that even though the first two of these files both contain exactly three
clusters, the clusters look very different in the two data files.  The clusters are
much more spread out in C<3_clusters_on_a_sphere_3000_samples.csv>.

The code in C<example4.pl> is special because it shows how you can call the
C<auto_retry_clusterer()> method of the module for automatic repeated invocations of
the clustering program until success is achieved.  The value of the constructor
parameter C<cluster_search_multiplier> is set to 1 in C<example4.pl>, implying that
when you execute C<example4.pl> you will not be invoking Phase 2 of the algorithm.
You might wish to change the value given to the parameter
C<cluster_search_multiplier> to see how it affects the number of attempts needed to
achieve success.

The C<examples> directory also includes PNG image files that show some intermediate
and the best final results that can be achieved by the first three examples, that
is, for the scripts C<example1.pl>, C<example2.pl>, and C<example3.pl>. If you are on
a Linux machine and if you have the C<ImageMagick> library installed, you can use the
C<display> command to see the results in the PNG images.  The results you get with
your own runs of the three example scripts may or may not look like what you see in
the outputs shown in the PNG files depending on how the module seeds the clusters.
Your best results should look like what you see in the PNG images.

The C<examples> directory also contains the following utility scripts:

For generating the data for experiments with clustering:

    generate_data_on_a_sphere.pl

For visualizing the data generated by the above script:

    data_visualizer.pl

For cleaning up the examples directory:

    cleanup_directory.pl

Invoking the C<cleanup_directory.pl> script will get rid of all the PNG image files
that are generated by the module when you run it with the constructor option
C<make_png_for_each_iteration> set to 1.

=head1 EXPORT

None by design.

=head1 CAVEATS

The performance of the algorithm depends much on the values you choose for the
constructor parameters.  And, even for the best choices for the parameters, the
algorithm is not theoretically guaranteed to return the best results.

Even after you have discovered the best choices for the constructor parameters, the
best way to use this module is to try it multiple times on any given data and accept
only those results that make the best intuitive sense.

The module was designed with the hope that it would rather fail than give you wrong
results. So if you see it failing a few times before it returns a good answer, that's
a good thing.  

However, if the module fails too often or is too quick to give you wrong answers,
that means the module is not working on your data.  If that happens, I'd love to hear
from you.  That might indicate to me how I should enhance the power of this module
for its future versions.

=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'LinearManifoldDataClusterer' in the subject line.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-LinearManifoldDataClusterer-1.01.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-LinearManifoldDataClusterer-1.01>.  Enter this directory and execute the following commands
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

I have learned much from my conversations with Donghun Kim whose research on face
recognition in the wild involves clustering image data on manifolds.  I have also had
several fruitful conversations with Bharath Kumar Comandur and Tanmay Prakash with
regard to the ideas that are incorporated in this module.

=head1 AUTHOR

Avinash Kak, kak@purdue.edu

If you send email, please place the string "LinearManifoldDataClusterer" in your subject line to get past
my spam filter.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2015 Avinash Kak

=cut

