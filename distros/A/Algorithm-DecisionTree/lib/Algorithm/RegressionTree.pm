package Algorithm::RegressionTree;

#--------------------------------------------------------------------------------------
# Copyright (c) 2016 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::RegressionTree is a Perl module for constructing regression trees.  It calls
# on the main Algorithm::DecisionTree module for some of its functionality.
# -------------------------------------------------------------------------------------

use lib 'blib/lib', 'blib/arch';

#use 5.10.0;
use strict;
use warnings;
use Carp;
use File::Basename;
use Algorithm::DecisionTree 3.42;
use List::Util qw(reduce min max pairmap sum);
use Math::GSL::Matrix;
use Graphics::GnuplotIF;

our $VERSION = '3.42';

@Algorithm::RegressionTree::ISA = ('Algorithm::DecisionTree');

############################################   Constructor  ##############################################
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument --- perhaps a misspelling\n" 
                           if check_for_illegal_params(@params) == 0;
    my %dtargs = %args;
    delete $dtargs{dependent_variable_column};
    delete $dtargs{predictor_columns};
    delete $dtargs{mse_threshold};
    delete $dtargs{need_data_normalization};
    delete $dtargs{jacobian_choice};
    delete $dtargs{debug1_r};
    delete $dtargs{debug2_r};
    delete $dtargs{debug3_r};
    my $instance = Algorithm::DecisionTree->new(%dtargs);
    bless $instance, $class;
    $instance->{_dependent_variable_column}       =  $args{dependent_variable_column} || undef;
    $instance->{_predictor_columns}               =  $args{predictor_columns} || 0;
    $instance->{_mse_threshold}                   =  $args{mse_threshold} || 0.01;
    $instance->{_jacobian_choice}                 =  $args{jacobian_choice} || 0;
    $instance->{_need_data_normalization}         =  $args{need_data_normalization} || 0;
    $instance->{_dependent_var}                   =  undef;
    $instance->{_dependent_var_values}            =  undef;
    $instance->{_samples_dependent_var_val_hash}  =  undef;
    $instance->{_root_node}                       =  undef;
    $instance->{_debug1_r}                        =  $args{debug1_r} || 0;
    $instance->{_debug2_r}                        =  $args{debug2_r} || 0;
    $instance->{_debug3_r}                        =  $args{debug3_r} || 0;
    $instance->{_sample_points_for_dependent_var} =  [];
    $instance->{_output_for_plots}                =  {};
    $instance->{_output_for_surface_plots}        =  {};
    bless $instance, $class;
}

##############################################  Methods  #################################################
sub get_training_data_for_regression {
    my $self = shift;
    die("Aborted. get_training_data_csv() is only for CSV files") unless $self->{_training_datafile} =~ /\.csv$/;
    my @dependent_var_values;
    my %all_record_ids_with_dependent_var_values;
    my $firstline;
    my %data_hash;
    $|++;
    open FILEIN, $self->{_training_datafile};
    my $record_index = 0;
    while (<FILEIN>) {
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        my $record = $self->{_csv_cleanup_needed} ? cleanup_csv($_) : $_;
        if ($record_index == 0) {
            $firstline = $record;
            $record_index++;
            next;
        }
        my @parts = split /,/, $record;
        my $record_label = shift @parts;
        $record_label  =~ s/^\s*\"|\"\s*$//g;
        $data_hash{$record_label} = \@parts;
        push @dependent_var_values, $parts[$self->{_dependent_variable_column}-1];
        $all_record_ids_with_dependent_var_values{$parts[0]} = $parts[$self->{_dependent_variable_column}-1];
        print "." if $record_index % 10000 == 0;
        $record_index++;
    }
    close FILEIN;    
    $self->{_how_many_total_training_samples} = $record_index; #it's less by 1 from total num of records; okay
    print "\n\nTotal number of training samples: $self->{_how_many_total_training_samples}\n" if $self->{_debug1_r};
    my @all_feature_names =   grep $_, split /,/, substr($firstline, index($firstline,','));
    my $dependent_var_column_heading = $all_feature_names[$self->{_dependent_variable_column} - 1];
    my @feature_names = map {$all_feature_names[$_-1]} @{$self->{_predictor_columns}};
    my %dependent_var_value_for_sample_hash = map {"sample_" . $_  =>  "$dependent_var_column_heading=" . $data_hash{$_}->[$self->{_dependent_variable_column} - 1 ] } keys %data_hash;
    my @sample_names = map {"sample_$_"} keys %data_hash;
    my %feature_values_for_samples_hash = map {my $sampleID = $_; "sample_" . $sampleID  =>  [map {my $fname = $all_feature_names[$_-1]; $fname . "=" . eval{$data_hash{$sampleID}->[$_-1] =~ /^\d+$/ ? sprintf("%.1f", $data_hash{$sampleID}->[$_-1] ) : $data_hash{$sampleID}->[$_-1] } } @{$self->{_predictor_columns}} ] }  keys %data_hash;    
    my %features_and_values_hash = map { my $a = $_; {$all_feature_names[$a-1] => [  map {my $b = $_; $b =~ /^\d+$/ ? sprintf("%.1f",$b) : $b} map {$data_hash{$_}->[$a-1]} keys %data_hash ]} } @{$self->{_predictor_columns}};     
    my %numeric_features_valuerange_hash   =   ();
    my %feature_values_how_many_uniques_hash  =  ();
    my %features_and_unique_values_hash = ();
    my $numregex =  '[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?';
    foreach my $feature (keys %features_and_values_hash) {
        my %seen = ();
        my @unique_values_for_feature =  grep {$_ if $_ ne 'NA' && !$seen{$_}++} @{$features_and_values_hash{$feature}};
        $feature_values_how_many_uniques_hash{$feature} = scalar @unique_values_for_feature;
        my $not_all_values_float = 0;
        map {$not_all_values_float = 1 if $_ !~ /^$numregex$/} @unique_values_for_feature;
        if ($not_all_values_float == 0) {
            my @minmaxvalues = minmax(\@unique_values_for_feature);
            $numeric_features_valuerange_hash{$feature} = \@minmaxvalues; 
        }
        $features_and_unique_values_hash{$feature} = \@unique_values_for_feature;
    }
    if ($self->{_debug1_r}) {
        print "\nDependent var values: @dependent_var_values\n";
        print "\nEach sample data record:\n";
        foreach my $kee (sort {sample_index($a) <=> sample_index($b)} keys %feature_values_for_samples_hash) {
            print "$kee    =>   @{$feature_values_for_samples_hash{$kee}}\n";
        }
        print "\ndependent var value for each data sample:\n";
        foreach my $kee (sort {sample_index($a) <=> sample_index($b)} keys %dependent_var_value_for_sample_hash) {
            print "$kee    =>   $dependent_var_value_for_sample_hash{$kee}\n";
        }
        print "\nfeatures and the values taken by them:\n";
        for my $kee  (sort keys %features_and_values_hash) {
            print "$kee    =>   @{$features_and_values_hash{$kee}}\n";                        
        }
        print "\nnumeric features and their ranges:\n";
        for my $kee  (sort keys %numeric_features_valuerange_hash) {
            print "$kee    =>   @{$numeric_features_valuerange_hash{$kee}}\n";
        }
        print "\nnumber of unique values in each feature:\n";        
        for my $kee  (sort keys %feature_values_how_many_uniques_hash) {
            print "$kee    =>   $feature_values_how_many_uniques_hash{$kee}\n";
        }
    }
    $self->{_XMatrix}  =  undef;
    $self->{_YVector}  =  undef;
    $self->{_dependent_var} = $dependent_var_column_heading;
    $self->{_dependent_var_values} = \@dependent_var_values;
    $self->{_feature_names} = \@feature_names;
    $self->{_samples_dependent_var_val_hash}  = \%dependent_var_value_for_sample_hash;
    $self->{_training_data_hash}  =  \%feature_values_for_samples_hash;
    $self->{_features_and_values_hash}  = \%features_and_values_hash;
    $self->{_features_and_unique_values_hash}  =  \%features_and_unique_values_hash;
    $self->{_numeric_features_valuerange_hash} = \%numeric_features_valuerange_hash;
    $self->{_feature_values_how_many_uniques_hash} = \%feature_values_how_many_uniques_hash;
    $self->SUPER::calculate_first_order_probabilities();
}

sub construct_XMatrix_and_YVector_all_data {
    my $self = shift;
    my $matrix_rows_as_lists =  [ map {my @arr = @$_; [map substr($_,index($_,'=')+1), @arr] } map {$self->{_training_data_hash}->{$_}} sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_training_data_hash}} ];
    map {push @$_, 1} @{$matrix_rows_as_lists};
    map {print "XMatrix row: @$_\n"} @{$matrix_rows_as_lists} if $self->{_debug1_r};
    my $XMatrix = Math::GSL::Matrix->new(scalar @{$matrix_rows_as_lists}, scalar @{$matrix_rows_as_lists->[0]});
    pairmap {$XMatrix->set_row($a,$b)} ( 0..@{$matrix_rows_as_lists}-1, @{$matrix_rows_as_lists} )
                       [ map { $_, $_ + @{$matrix_rows_as_lists} } ( 0 .. @{$matrix_rows_as_lists}-1 ) ];
    if ($self->{_debug1_r}) {
        foreach my $rowindex (0..@{$matrix_rows_as_lists}-1) {
            my @onerow = $XMatrix->row($rowindex)->as_list;
            print "XMatrix row again: @onerow\n";
        }
    }
    $self->{_XMatrix} = $XMatrix;
    my @dependent_var_values =  map {my $val = $self->{_samples_dependent_var_val_hash}->{$_}; substr($val,index($val,'=')+1)} sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_samples_dependent_var_val_hash}};
    print "dependent var values: @dependent_var_values\n" if $self->{_debug1_r};
    my $YVector = Math::GSL::Matrix->new(scalar @{$matrix_rows_as_lists}, 1);
    pairmap {$YVector->set_row($a,$b)} ( 0..@{$matrix_rows_as_lists}-1, map {[$_]} @dependent_var_values )
                       [ map { $_, $_ + @{$matrix_rows_as_lists} } ( 0 .. @{$matrix_rows_as_lists}-1 ) ];
    if ($self->{_debug1_r}) {
        foreach my $rowindex (0..@{$matrix_rows_as_lists}-1) {
            my @onerow = $YVector->row($rowindex)->as_list;
            print "YVector row: @onerow\n";
        }
    }
    $self->{_YVector} = $YVector;
    return ($XMatrix, $YVector);
}

sub estimate_regression_coefficients {
    my $self = shift;
    my ($XMatrix, $YVector, $display) = @_;
    $display = 0 unless defined $display;
    my ($nrows, $ncols) = $XMatrix->dim;
    print "nrows=$nrows   ncols=$ncols\n" if $self->{_debug2_r};
    my $jacobian_choice = $self->{_jacobian_choice};
    my $X = $XMatrix->copy();
    my $y = $YVector->copy();
    if ($self->{_need_data_normalization}) {
        die "normalization feature is yet to be added to the module --- sorry";
    }
    my $beta0 = (transpose($X) * $X)->inverse() * transpose($X) * $y;
    my ($betarows, $betacols) = $beta0->dim;
    die "Something has gone wrong with the calculation of beta coefficients" if $betacols > 1;
    if ($jacobian_choice == 0) {
#        my $error = sum(abs_vector_as_list( $y - ($X * $beta) )) / $nrows;   
        my $error = sum( map abs, ($y - ($X * $beta0) )->col(0)->as_list ) / $nrows;   
        my $predictions = $X * $beta0;
        if ($display) {
            if ($ncols == 2) {
                my @xvalues = $X->col(0)->as_list;
                my @yvalues = $predictions->col(0)->as_list;
                $self->{_output_for_plots}->{scalar(keys %{$self->{_output_for_plots}}) + 1} = [\@xvalues,\@yvalues];
            } elsif ($ncols == 3) {
                my @xvalues;
                my @yvalues = $predictions->col(0)->as_list;
                foreach my $row_index (0 .. $X->rows - 1) {
                    my @onerow = $X->row($row_index)->as_list;
                    pop @onerow;
                    push @xvalues, "@onerow";
                }
                $self->{_output_for_surface_plots}->{scalar(keys %{$self->{_output_for_surface_plots}}) + 1} = [\@xvalues,\@yvalues];
            } else {
                print "no display when the overall dimensionality of the data exceeds 3\n";
            }
        }
        return ($error, $beta0);    
    }
    my $beta = $beta0; 
    if ($self->{_debug2_r}) {
        print "\ndisplaying beta0 matrix\n";
        display_matrix($beta);
    }
    my $gamma = 0.1;
    my $iterate_again_flag = 1;
    my $delta = 0.001;
    my $master_interation_index = 0;
    $|++;
    while (1) {
        print "*" unless $master_interation_index++ % 100;
        last unless $iterate_again_flag;
        $gamma *= 0.1;
        $beta0 = 0.99 * $beta0;
        print "\n\n======== starting iterations with gamma= $gamma ===========\n\n\n" if $self->{_debug2_r};
        $beta = $beta0;
        my $beta_old = Math::GSL::Matrix->new($betarows, 1)->zero;
        my $error_old = sum( map abs, ($y - ($X * $beta_old) )->col(0)->as_list ) / $nrows;   
        my $error;
        foreach my $iteration (0 .. 1499) {
            print "." unless $iteration % 100;
            $beta_old = $beta->copy;
            my $jacobian;
            if ($jacobian_choice == 1) {
                $jacobian = $X;
            } elsif ($jacobian_choice == 2) {      
                my $x_times_delta_beta = $delta * $X * $beta;
                $jacobian = Math::GSL::Matrix->new($nrows, $ncols);
                foreach my $i (0 .. $nrows - 1) {
                    my @row = ($x_times_delta_beta->get_elem($i,0)) x $ncols;
                    $jacobian->set_row($i, \@row);
                }
                $jacobian = (1.0/$delta) * $jacobian;
            } else {
                die "wrong choice for the jacobian_choice";
            }
#            $beta = $beta_old + 2 * $gamma * transpose($X) * ( $y - ($X * $beta) );
            $beta = $beta_old + 2 * $gamma * transpose($jacobian) * ( $y - ($X * $beta) );
            $error = sum( map abs, ($y - ($X * $beta) )->col(0)->as_list ) / $nrows;   
            if ($error > $error_old) {
                if (vector_norm($beta - $beta_old) < (0.00001 * vector_norm($beta_old))) {
                    $iterate_again_flag = 0;
                    last;
                } else {
                    last;
                }
            }
            if ($self->{_debug2_r}) {
                print "\n\niteration: $iteration   gamma: $gamma   current error: $error\n";
                print "\nnew beta:\n";
                display_matrix $beta;
            }
            if ( vector_norm($beta - $beta_old) < (0.00001 * vector_norm($beta_old)) ) { 
                print "iterations used: $iteration with gamma: $gamma\n" if $self->{_debug2_r};
                $iterate_again_flag = 0;
                last;
            }
            $error_old = $error;
        }
    }
    display_matrix($beta) if $self->{_debug2_r};
    my $predictions = $X * $beta;
    my @error_distribution = ($y - ($X * $beta))->as_list;
    my $squared_error =  sum map abs, @error_distribution;
    my $error = $squared_error / $nrows;
    if ($display) {
        if ($ncols == 2) {
            my @xvalues = $X->col(0)->as_list;
            my @yvalues = $predictions->col(0)->as_list;
            $self->{_output_for_plots}->{scalar(keys %{$self->{_output_for_plots}}) + 1} = [\@xvalues,\@yvalues];
        } elsif ($ncols == 3) {
            my @xvalues;
            my @yvalues = $predictions->col(0)->as_list;
            foreach my $row_index (0 .. $X->rows - 1) {
                my @onerow = $X->row($row_index)->as_list;
                pop @onerow;
                push @xvalues, "@onerow";
            }
            $self->{_output_for_surface_plots}->{scalar(keys %{$self->{_output_for_surface_plots}}) + 1} = [\@xvalues,\@yvalues];
        } else {
            print "no display when the overall dimensionality of the data exceeds 3\n";
        }
    }
    return ($error, $beta);
}

##-------------------------------  Construct Regression Tree  ------------------------------------


##  At the root node, you do ordinary linear regression for the entire dataset so that you
##  can later compare the linear regression fit with the results obtained through the 
##  regression tree.  Subsequently, you call the recursive_descent() method to construct
##  the tree.

sub construct_regression_tree {
    my $self = shift;
    print "\nConstructing regression tree...\n";
    my $root_node = RTNode->new(undef, undef, undef, [], $self, 'root');
    my ($XMatrix,$YVector) = $self->construct_XMatrix_and_YVector_all_data();
    my ($error,$beta) = $self->estimate_regression_coefficients($XMatrix, $YVector, 1); 
    $root_node->set_node_XMatrix($XMatrix);
    $root_node->set_node_YVector($YVector);
    $root_node->set_node_error($error);
    $root_node->set_node_beta($beta);
    $root_node->set_num_data_points($XMatrix->cols);
    print "\nerror at root: $error\n";
    print "\nbeta at root:\n";
    display_matrix($beta);
    $self->{_root_node} = $root_node;
    $self->recursive_descent($root_node) if $self->{_max_depth_desired} > 0;
    return $root_node;
}

##  We first look for a feature, along with its partitioning point, that yields the 
##  largest reduction in MSE compared to the MSE at the parent node.  This feature and
##  its partitioning point are then used to create two child nodes in the tree.
sub recursive_descent {
    my $self = shift;
    my $node = shift;
    print "\n==================== ENTERING RECURSIVE DESCENT ==========================\n";
    my $node_serial_number = $node->get_serial_num();
    my @features_and_values_or_thresholds_on_branch = @{$node->get_branch_features_and_values_or_thresholds()};
    my @copy_of_path_attributes = @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
    if (@features_and_values_or_thresholds_on_branch > 0) {
        my ($error,$beta,$XMatrix,$YVector) = 
          $self->_error_for_given_sequence_of_features_and_values_or_thresholds(\@copy_of_path_attributes);
        $node->set_node_XMatrix($XMatrix);
        $node->set_node_YVector($YVector);
        $node->set_node_error($error);
        $node->set_node_beta($beta);
        $node->set_num_data_points($XMatrix->cols);
        print "\nNODE SERIAL NUMBER: $node_serial_number\n";
        print "\nFeatures and values or thresholds on branch: @features_and_values_or_thresholds_on_branch\n";
        return if $error <= $self->{_mse_threshold}; 
    }
    my ($best_feature,$best_minmax_error_at_partitioning_point,$best_feature_partitioning_point) = 
                                               $self->best_feature_calculator(\@copy_of_path_attributes);
    return unless defined $best_feature_partitioning_point;
    print "\nBest feature found: $best_feature\n";
    print "Best feature partitioning_point: $best_feature_partitioning_point\n";
    print "Best minmax error at partitioning point: $best_minmax_error_at_partitioning_point\n";
    $node->set_feature($best_feature);
    $node->display_node() if $self->{_debug2_r}; 
    return if (defined $self->{_max_depth_desired}) && 
                            (@features_and_values_or_thresholds_on_branch >= $self->{_max_depth_desired}); 
    if ($best_minmax_error_at_partitioning_point > $self->{_mse_threshold}) {
        my @extended_branch_features_and_values_or_thresholds_for_lessthan_child = 
                                        @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
        my @extended_branch_features_and_values_or_thresholds_for_greaterthan_child  = 
                                        @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)}; 
        my $feature_threshold_combo_for_less_than = "$best_feature" . '<' . "$best_feature_partitioning_point";
        my $feature_threshold_combo_for_greater_than = "$best_feature" . '>' . "$best_feature_partitioning_point";
        push @extended_branch_features_and_values_or_thresholds_for_lessthan_child, 
                                                                  $feature_threshold_combo_for_less_than;
        push @extended_branch_features_and_values_or_thresholds_for_greaterthan_child, 
                                                               $feature_threshold_combo_for_greater_than;
        my $left_child_node = RTNode->new(undef, undef, undef, 
                          \@extended_branch_features_and_values_or_thresholds_for_lessthan_child, $self);
        $node->add_child_link($left_child_node);
        $self->recursive_descent($left_child_node);
        my $right_child_node = RTNode->new(undef, undef, undef, 
                        \@extended_branch_features_and_values_or_thresholds_for_greaterthan_child, $self);
        $node->add_child_link($right_child_node);
        $self->recursive_descent($right_child_node);
    }
}

##  This is the heart of the regression tree constructor.  Its main job is to figure
##  out the best feature to use for partitioning the training data samples at the
##  current node.  The partitioning criterion is that the largest of the MSE's in 
##  the two partitions should be smaller than the error associated with the parent
##  node.
sub best_feature_calculator {
    my $self = shift;
    my $features_and_values_or_thresholds_on_branch = shift;
    my @features_and_values_or_thresholds_on_branch =  @$features_and_values_or_thresholds_on_branch;
    print "\n\nfeatures_and_values_or_thresholds_on_branch: @features_and_values_or_thresholds_on_branch\n";
    if (@features_and_values_or_thresholds_on_branch == 0) {
        my $best_partition_point_for_feature_hash = { map {$_ => undef} @{$self->{_feature_names}} };
        my $best_minmax_error_for_feature_hash = { map {$_ => undef} @{$self->{_feature_names}} };
        foreach my $i (0 .. @{$self->{_feature_names}}-1) {
            my $feature_name = $self->{_feature_names}->[$i];
            my @values = @{$self->{_sampling_points_for_numeric_feature_hash}->{$feature_name}};
            my @partitioning_errors;
            my %partitioning_error_hash;
            foreach my $value (@values[10 .. $#values - 10]) {
                my $feature_and_less_than_value_string =  "$feature_name" . '<' . "$value";
                my $feature_and_greater_than_value_string = "$feature_name" . '>' . "$value";
                my @for_left_child;
                my @for_right_child;
                if (@features_and_values_or_thresholds_on_branch) {
                    @for_left_child = @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
                    push @for_left_child, $feature_and_less_than_value_string;
                    @for_right_child = @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
                    push @for_right_child, $feature_and_greater_than_value_string;
                } else {
                    @for_left_child = ($feature_and_less_than_value_string);
                    @for_right_child = ($feature_and_greater_than_value_string);
                }
                my ($error1,$beta1,$XMatrix1,$YVector1) = 
                        $self->_error_for_given_sequence_of_features_and_values_or_thresholds(\@for_left_child);
                my ($error2,$beta2,$XMatrix2,$YVector2) = 
                        $self->_error_for_given_sequence_of_features_and_values_or_thresholds(\@for_right_child);
                my $partitioning_error = max($error1, $error2);
                push @partitioning_errors, $partitioning_error;
                $partitioning_error_hash{$partitioning_error} = $value;
            }
            my $min_max_error_for_feature = min(@partitioning_errors);
            $best_partition_point_for_feature_hash->{$feature_name} = 
                                             $partitioning_error_hash{$min_max_error_for_feature};
            $best_minmax_error_for_feature_hash->{$feature_name} = $min_max_error_for_feature;
        }
        my $best_feature_name;
        my $best_feature_paritioning_point;
        my $best_minmax_error_at_partitioning_point;
        foreach my $feature (keys %{$best_minmax_error_for_feature_hash}) {
            if (! defined $best_minmax_error_at_partitioning_point) {
                $best_minmax_error_at_partitioning_point = $best_minmax_error_for_feature_hash->{$feature};
                $best_feature_name = $feature;
            } elsif ($best_minmax_error_at_partitioning_point > $best_minmax_error_for_feature_hash->{$feature}) {
                $best_minmax_error_at_partitioning_point = $best_minmax_error_for_feature_hash->{$feature};
                $best_feature_name = $feature;
            }
        }
        my $best_feature_partitioning_point =  $best_partition_point_for_feature_hash->{$best_feature_name};
        return ($best_feature_name,$best_minmax_error_at_partitioning_point,$best_feature_partitioning_point);
    } else {
        my $pattern1 = '(.+)=(.+)';
        my $pattern2 = '(.+)<(.+)';
        my $pattern3 = '(.+)>(.+)';
        my @true_numeric_types;
        my @symbolic_types;
        my @true_numeric_types_feature_names;
        my @symbolic_types_feature_names;
        foreach my $item (@features_and_values_or_thresholds_on_branch) {
            if ($item =~ /$pattern2/) {
                push @true_numeric_types, $item;
                push @true_numeric_types_feature_names, $1;
            } elsif ($item =~ /$pattern3/) {
                push @true_numeric_types, $item;
                push @true_numeric_types_feature_names, $1;
            } elsif ($item =~ /$pattern1/) {
                push @symbolic_types, $item;
                push @symbolic_types_feature_names, $1;
            } else {
                die "format error in the representation of feature and values or thresholds";
            }
        }
        my %seen = ();
        @true_numeric_types_feature_names = grep {$_ if !$seen{$_}++} @true_numeric_types_feature_names;
        %seen = ();
        @symbolic_types_feature_names = grep {$_ if !$seen{$_}++} @symbolic_types_feature_names;
        my @bounded_intervals_numeric_types = 
                           @{$self->find_bounded_intervals_for_numeric_features(\@true_numeric_types)};
        # Calculate the upper and the lower bounds to be used when searching for the best
        # threshold for each of the numeric features that are in play at the current node:
        my (%upperbound, %lowerbound);
        foreach my $feature (@true_numeric_types_feature_names) {
            $upperbound{$feature} = undef;
            $lowerbound{$feature} = undef;
        }
        foreach my $item (@bounded_intervals_numeric_types) {
            foreach my $feature_grouping (@$item) {
                if ($feature_grouping->[1] eq '>') {
                    $lowerbound{$feature_grouping->[0]} = $feature_grouping->[2];
                } else {
                    $upperbound{$feature_grouping->[0]} = $feature_grouping->[2];
                }
            }
        }
        my $best_partition_point_for_feature_hash = { map {$_ => undef} @{$self->{_feature_names}} };
        my $best_minmax_error_for_feature_hash = { map {$_ => undef} @{$self->{_feature_names}} };
        foreach my $i (0 .. @{$self->{_feature_names}}-1) {
            my $feature_name = $self->{_feature_names}->[$i];
            my @values = @{$self->{_sampling_points_for_numeric_feature_hash}->{$feature_name}};
            my @newvalues;
            if (contained_in($feature_name, @true_numeric_types_feature_names)) {
                if (defined($upperbound{$feature_name}) && defined($lowerbound{$feature_name}) &&
                              $lowerbound{$feature_name} >= $upperbound{$feature_name}) {
                    next;
                } elsif (defined($upperbound{$feature_name}) && defined($lowerbound{$feature_name}) &&
                                    $lowerbound{$feature_name} < $upperbound{$feature_name}) {
                    foreach my $x (@values) {
                        push @newvalues, $x if $x > $lowerbound{$feature_name} && $x <= $upperbound{$feature_name};
                    }
                } elsif (defined($upperbound{$feature_name})) {
                    foreach my $x (@values) {
                        push @newvalues, $x if $x <= $upperbound{$feature_name};
                    }
                } elsif (defined($lowerbound{$feature_name})) {
                    foreach my $x (@values) {
                        push @newvalues, $x if $x > $lowerbound{$feature_name};
                    }
                } else {
                    die "Error is bound specifications in best feature calculator";
                }
            } else {
                @newvalues = @{deep_copy_array(\@values)};
            }
            next if @newvalues < 30;
            my @partitioning_errors;
            my %partitioning_error_hash;
            foreach my $value (@newvalues[10 .. $#newvalues - 10]) {
                my $feature_and_less_than_value_string =  "$feature_name" . '<' . "$value";
                my $feature_and_greater_than_value_string = "$feature_name" . '>' . "$value";
                my @for_left_child;
                my @for_right_child;
                if (@features_and_values_or_thresholds_on_branch) {
                    @for_left_child = @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
                    push @for_left_child, $feature_and_less_than_value_string;
                    @for_right_child = @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
                    push @for_right_child, $feature_and_greater_than_value_string;
                } else {
                    @for_left_child = ($feature_and_less_than_value_string);
                    @for_right_child = ($feature_and_greater_than_value_string);
                }
                my ($error1,$beta1,$XMatrix1,$YVector1) = 
                        $self->_error_for_given_sequence_of_features_and_values_or_thresholds(\@for_left_child);
                my ($error2,$beta2,$XMatrix2,$YVector2) = 
                        $self->_error_for_given_sequence_of_features_and_values_or_thresholds(\@for_right_child);
                my $partitioning_error = max($error1, $error2);
                push @partitioning_errors, $partitioning_error;
                $partitioning_error_hash{$partitioning_error} = $value;
            }
            my $min_max_error_for_feature = min(@partitioning_errors);
            $best_partition_point_for_feature_hash->{$feature_name} = 
                                             $partitioning_error_hash{$min_max_error_for_feature};
            $best_minmax_error_for_feature_hash->{$feature_name} = $min_max_error_for_feature;
        }
        my $best_feature_name;
        my $best_feature_paritioning_point;
        my $best_minmax_error_at_partitioning_point;
        foreach my $feature (keys %{$best_minmax_error_for_feature_hash}) {
            if (! defined $best_minmax_error_at_partitioning_point) {
                $best_minmax_error_at_partitioning_point = $best_minmax_error_for_feature_hash->{$feature};
                $best_feature_name = $feature;
            } elsif ($best_minmax_error_at_partitioning_point > $best_minmax_error_for_feature_hash->{$feature}) {
                $best_minmax_error_at_partitioning_point = $best_minmax_error_for_feature_hash->{$feature};
                $best_feature_name = $feature;
            }
        }
        my $best_feature_partitioning_point =  $best_partition_point_for_feature_hash->{$best_feature_name};
        return ($best_feature_name,$best_minmax_error_at_partitioning_point,$best_feature_partitioning_point);
    }
}

##  This method requires that all truly numeric types only be expressed as '<' or '>'
##  constructs in the array of branch features and thresholds
sub _error_for_given_sequence_of_features_and_values_or_thresholds{
    my $self = shift;
    my $array_of_features_and_values_or_thresholds = shift;
    if (@$array_of_features_and_values_or_thresholds == 0) { 
        my ($XMatrix,$YVector) = $self->construct_XMatrix_and_YVector_all_data();
        my ($errors,$beta) = $self->estimate_regression_coefficients($XMatrix,$YVector);
        return ($errors,$beta,$XMatrix,$YVector)
    }
    my $pattern1 = '(.+)=(.+)';
    my $pattern2 = '(.+)<(.+)';
    my $pattern3 = '(.+)>(.+)';
    my @true_numeric_types;
    my @symbolic_types;
    my @true_numeric_types_feature_names;
    my @symbolic_types_feature_names;
    foreach my $item (@$array_of_features_and_values_or_thresholds) {
        if ($item =~ /$pattern2/) {
            push @true_numeric_types, $item;
            push @true_numeric_types_feature_names, $1;
        } elsif ($item =~ /$pattern3/) {
            push @true_numeric_types, $item;
            push @true_numeric_types_feature_names, $1;
        } elsif ($item =~ /$pattern1/) {
            push @symbolic_types, $item;
            push @symbolic_types_feature_names, $1;
        } else {
            die "format error in the representation of feature and values or thresholds";
        }
    }
    my %seen = ();
    @true_numeric_types_feature_names = grep {$_ if !$seen{$_}++} @true_numeric_types_feature_names;
    %seen = ();
    @symbolic_types_feature_names = grep {$_ if !$seen{$_}++} @symbolic_types_feature_names;
    my @bounded_intervals_numeric_types = 
                           @{$self->find_bounded_intervals_for_numeric_features(\@true_numeric_types)};
    # Calculate the upper and the lower bounds to be used when searching for the best
    # threshold for each of the numeric features that are in play at the current node:
    my (%upperbound, %lowerbound);
    foreach my $feature (@true_numeric_types_feature_names) {
        $upperbound{$feature} = undef;
        $lowerbound{$feature} = undef;
    }
    foreach my $item (@bounded_intervals_numeric_types) {
        foreach my $feature_grouping (@$item) {
            if ($feature_grouping->[1] eq '>') {
                $lowerbound{$feature_grouping->[0]} = $feature_grouping->[2];
            } else {
                $upperbound{$feature_grouping->[0]} = $feature_grouping->[2];
            }
        }
    }
    my %training_samples_at_node;
    foreach my $feature_name (@true_numeric_types_feature_names) {
        if ((defined $lowerbound{$feature_name}) && (defined $upperbound{$feature_name}) && 
                                     ($upperbound{$feature_name} <= $lowerbound{$feature_name})) {
            return (undef,undef,undef,undef); 
        } elsif ((defined $lowerbound{$feature_name}) && (defined $upperbound{$feature_name})) {
            foreach my $sample (keys %{$self->{_training_data_hash}}) {
                my @feature_val_pairs = @{$self->{_training_data_hash}->{$sample}};
                foreach my $feature_and_val (@feature_val_pairs) {
                    my $value_for_feature = substr($feature_and_val, index($feature_and_val,'=')+1 );
                    my $feature_involved =  substr($feature_and_val, 0, index($feature_and_val,'=') );
                    if (($feature_name eq $feature_involved) && 
                        ($lowerbound{$feature_name} < $value_for_feature) && 
                        ($value_for_feature <= $upperbound{$feature_name})) {
                        $training_samples_at_node{$sample} = 1;
                        last;
                    }
                }
            }  
        } elsif ((defined $upperbound{$feature_name}) && (! defined $lowerbound{$feature_name})) {
            foreach my $sample (keys %{$self->{_training_data_hash}}) {
                my @feature_val_pairs = @{$self->{_training_data_hash}->{$sample}};
                foreach my $feature_and_val (@feature_val_pairs) {
                    my $value_for_feature = substr($feature_and_val, index($feature_and_val,'=')+1 );
                    my $feature_involved =  substr($feature_and_val, 0, index($feature_and_val,'=') );
                    if (($feature_name eq $feature_involved) && 
                        ($value_for_feature <= $upperbound{$feature_name})) {
                        $training_samples_at_node{$sample} = 1;
                        last;
                    }
                }
            }  
        } elsif ((defined $lowerbound{$feature_name}) && (! defined $upperbound{$feature_name})) {
            foreach my $sample (keys %{$self->{_training_data_hash}}) {
                my @feature_val_pairs = @{$self->{_training_data_hash}->{$sample}};
                foreach my $feature_and_val (@feature_val_pairs) {
                    my $value_for_feature = substr($feature_and_val, index($feature_and_val,'=')+1 );
                    my $feature_involved =  substr($feature_and_val, 0, index($feature_and_val,'=') );
                    if (($feature_name eq $feature_involved) && 
                        ($value_for_feature > $lowerbound{$feature_name})) {
                        $training_samples_at_node{$sample} = 1;
                        last;
                    }
                }
            }  
        } else {
            die "Ill formatted call to the '_error_for_given_sequence_...' method";
        }   
    }
    foreach my $feature_and_value (@symbolic_types) {
        if ($feature_and_value =~ /$pattern1/) {
            my ($feature,$value) = ($1,$2);
            foreach my $sample (keys %{$self->{_training_data_hash}}) {
                my @feature_val_pairs = @{$self->{_training_data_hash}->{$sample}};
                foreach my $feature_and_val (@feature_val_pairs) {
                    my $feature_in_sample =  substr($feature_and_val, 0, index($feature_and_val,'=') );
                    my $value_in_sample = substr($feature_and_val, index($feature_and_val,'=')+1 );
                    if (($feature eq $feature_in_sample) && ($value eq $value_in_sample)) {
                        $training_samples_at_node{$sample} = 1;
                        last;
                    }
                }
            }
        }
    }
    my @training_samples_at_node = keys %training_samples_at_node;
    my $matrix_rows_as_lists =  [ map {my @arr = @$_; [map substr($_,index($_,'=')+1), @arr] } map {$self->{_training_data_hash}->{$_}} sort {sample_index($a) <=> sample_index($b)} @training_samples_at_node ];;
    map {push @$_, 1} @{$matrix_rows_as_lists};
    my $XMatrix = Math::GSL::Matrix->new(scalar @{$matrix_rows_as_lists}, scalar @{$matrix_rows_as_lists->[0]});
    pairmap {$XMatrix->set_row($a,$b)} ( 0..@{$matrix_rows_as_lists}-1, @{$matrix_rows_as_lists} )
                       [ map { $_, $_ + @{$matrix_rows_as_lists} } ( 0 .. @{$matrix_rows_as_lists}-1 ) ];
    if ($self->{_debug3_r}) {
        print "\nXMatrix as its transpose:";        
        my $displayX = transpose($XMatrix);
        display_matrix($displayX);
    }
    my @dependent_var_values =  map {my $val = $self->{_samples_dependent_var_val_hash}->{$_}; substr($val,index($val,'=')+1)} sort {sample_index($a) <=> sample_index($b)} @training_samples_at_node;
    print "dependent var values: @dependent_var_values\n" if $self->{_debug1_r};
    my $YVector = Math::GSL::Matrix->new(scalar @{$matrix_rows_as_lists}, 1);
    pairmap {$YVector->set_row($a,$b)} ( 0..@{$matrix_rows_as_lists}-1, map {[$_]} @dependent_var_values )
                       [ map { $_, $_ + @{$matrix_rows_as_lists} } ( 0 .. @{$matrix_rows_as_lists}-1 ) ];
    if ($self->{_debug3_r}) {
        print "\nYVector:";  
        my $displayY = transpose($YVector);
        display_matrix($displayY);
    }
    my ($error,$beta) = $self->estimate_regression_coefficients($XMatrix, $YVector);
    if ($self->{_debug3_r}) {
        display_matrix($beta);
        print("\n\nerror distribution at node: ", $error);
    }
    return ($error,$beta,$XMatrix,$YVector);
}

#-----------------------------    Predict with Regression Tree   ------------------------------

sub predictions_for_all_data_used_for_regression_estimation {
    my $self = shift;
    my $root_node = shift;
    my %predicted_values;
    my %leafnode_for_values;
    my $ncols = $self->{_XMatrix}->cols;
    if ($ncols == 2) {
        foreach my $sample (keys %{$self->{_training_data_hash}}) {
            my $pattern = '(\S+)\s*=\s*(\S+)';
            $self->{_training_data_hash}->{$sample}->[0] =~ /$pattern/;
            my ($feature,$value) =  ($1, $2);
            my $new_feature_and_value = "$feature=$value";
            my $answer = $self->prediction_for_single_data_point($root_node, [$new_feature_and_value]);
            $predicted_values{$value} = $answer->{'prediction'};
            $leafnode_for_values{"$value,$predicted_values{$value}"} = $answer->{'solution_path'}->[-1];
        }
        my @leaf_nodes_used = keys %{{map {$_ => 1} values %leafnode_for_values}};
        foreach my $leaf (@leaf_nodes_used) {
            my @xvalues;
            my @yvalues;
            foreach my $x (sort {$a <=> $b} keys %predicted_values) {
                if ($leaf == $leafnode_for_values{"$x,$predicted_values{$x}"}) {
                    push @xvalues, $x;
                    push @yvalues, $predicted_values{$x};
                }
            }
            $self->{_output_for_plots}->{scalar(keys %{$self->{_output_for_plots}}) + 1} = [\@xvalues,\@yvalues];
        }
    } elsif ($ncols == 3) {
        foreach my $sample (keys %{$self->{_training_data_hash}}) {
            my $pattern = '(\S+)\s*=\s*(\S+)';        
            my @features_and_vals;
            my @newvalues;
            foreach my $feature_and_val (@{$self->{_training_data_hash}->{$sample}}) {
                $feature_and_val =~ /$pattern/;
                my ($feature,$value) =  ($1, $2);
                push @newvalues, $value;
                my $new_feature_and_value = "$feature=$value";
                push @features_and_vals, $new_feature_and_value;
            }
            my $answer = $self->prediction_for_single_data_point($root_node, \@features_and_vals);
            $predicted_values{"@newvalues"} = $answer->{'prediction'};
            $leafnode_for_values{"@newvalues"} = $answer->{'solution_path'}->[-1];
        }
        my @leaf_nodes_used = keys %{{map {$_ => 1} values %leafnode_for_values}};
        foreach my $leaf (@leaf_nodes_used) {
            my @xvalues;
            my @yvalues;
            foreach my $kee (keys %predicted_values) {
                if ($leaf == $leafnode_for_values{$kee}) {
                    push @xvalues, $kee;
                    push @yvalues, $predicted_values{$kee};
                }
            }
            $self->{_output_for_surface_plots}->{scalar(keys %{$self->{_output_for_surface_plots}}) + 1} = [\@xvalues,\@yvalues];
        }
    } else {
        die "\nThe module does not yet include regression based predictions when you have more than " .
            "two predictor variables --- on account of the difficulty of properly visualizing the " .
            "quality of such predictions.  Future versions of this modue may nonetheless allow for " .
            "regression based predictions in such cases (depending on user feedback)";
    }
}

sub bulk_predictions_for_data_in_a_csv_file {
    my $self = shift;
    my ($root_node, $filename, $columns) = @_;
    die("Aborted. bulk_predictions_for_data_in_a_csv_file() is only for CSV files") unless $filename =~ /\.csv$/;
    my $basefilename = basename($filename, '.csv');
    my $out_file_name = $basefilename . "_output.csv";
    unlink $out_file_name if -e $out_file_name;
    open FILEOUT, "> $out_file_name" or die "Unable to open $out_file_name: $!";
    $|++;
    open FILEIN, $filename or die "Unable to open $filename: $!";
    my $record_index = 0;
    my @fieldnames;
    while (<FILEIN>) {
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        my $record = $self->{_csv_cleanup_needed} ? cleanup_csv($_) : $_;
        if ($record_index == 0) {
            @fieldnames =   grep $_, split /,/, substr($record, index($record,','));
            $record_index++;
            next;
        }
        my @feature_vals = grep $_, split /,/, $record;
        my @features_and_vals;
        foreach my $col_index (@$columns) {
            push @features_and_vals, "$fieldnames[$col_index-1]=$feature_vals[$col_index-1]"
        }
        my $answer = $self->prediction_for_single_data_point($root_node, \@features_and_vals);
        print FILEOUT "$record        =>        $answer->{'prediction'}\n";
    }
    close FILEIN;
    close FILEOUT;
}

sub mse_for_tree_regression_for_all_training_samples {
    my $self = shift;
    my $root_node = shift;
    my %predicted_values;
    my %dependent_var_values;
    my %leafnode_for_values;
    my $total_error = 0.0;
    my %samples_at_leafnode;
    foreach my $sample (keys %{$self->{_training_data_hash}}) {
        my $pattern = '(\S+)\s*=\s*(\S+)';        
        my @features_and_vals;
        my $newvalue;
        foreach my $feature_and_val (@{$self->{_training_data_hash}->{$sample}}) {
            $feature_and_val =~ /$pattern/;
            my ($feature,$value) =  ($1, $2);
            if (contained_in($feature, @{$self->{_feature_names}})) {
                my $new_feature_and_value = "$feature=$value";
                push @features_and_vals, "$feature=$value";
            }
            $newvalue = $value;
        } 
        my $answer = $self->prediction_for_single_data_point($root_node, \@features_and_vals);
        $predicted_values{"@features_and_vals"} = $answer->{'prediction'};
        $self->{_samples_dependent_var_val_hash}->{$sample} =~ /$pattern/;
        my ($dep_feature,$dep_value) = ($1, $2);
        $dependent_var_values{"@features_and_vals"} = $dep_value;
        my $leafnode_for_sample = $answer->{'solution_path'}->[-1];
        $leafnode_for_values{"@features_and_vals"} = $answer->{'solution_path'}->[-1];
        my $error_for_sample = abs($predicted_values{"@features_and_vals"} - $dependent_var_values{"@features_and_vals"});
        $total_error += $error_for_sample;
        if (exists $samples_at_leafnode{$leafnode_for_sample}) {
            push @{$samples_at_leafnode{$leafnode_for_sample}}, $sample;
        } else {
            $samples_at_leafnode{$leafnode_for_sample} = [$sample];
        }
    }
    my @leafnodes_used = keys %{{map {$_ => 1} values %leafnode_for_values}};
    my $errors_at_leafnode = { map {$_ => 0.0} @leafnodes_used };
    foreach my $kee (keys %predicted_values) {
        foreach my $leaf (@leafnodes_used) {
            $errors_at_leafnode->{$leaf} += abs($predicted_values{$kee} - $dependent_var_values{$kee})
                          if $leaf == $leafnode_for_values{$kee};
        }
    }
    my $total_error_per_data_point = $total_error / (scalar keys %{$self->{_training_data_hash}});
    print "\n\nTree Regression: Total MSE per sample with tree regression: $total_error_per_data_point\n";
    foreach my $leafnode (@leafnodes_used) {
        my $error_per_data_point = $errors_at_leafnode->{$leafnode} / @{$samples_at_leafnode{$leafnode}};
        print "    MSE per sample at leafnode $leafnode: $error_per_data_point\n";
    }
    my $error_with_linear_regression = $self->{_root_node}->get_node_error();
    print "For comparision, the MSE per sample error with Linear Regression: $error_with_linear_regression\n";
}

##  Calculated the predicted value for the dependent variable from a given value for all
##  the predictor variables.
sub prediction_for_single_data_point {
    my $self = shift;
    my $root_node = shift;
    my $features_and_values = shift;
    die "Error in the names you have used for features and/or values when calling " .
        "prediction_for_single_data_point()" unless $self->_check_names_used($features_and_values);
    my $pattern = '(\S+)\s*=\s*(\S+)';        
    my @new_features_and_values;
    foreach my $feature_and_value (@$features_and_values) {
        $feature_and_value =~ /$pattern/;
        my ($feature,$value) =  ($1, $2);
        push @new_features_and_values, "$feature=$value";
    }
    my %answer;
    $answer{'solution_path'} = [];
    my $prediction = $self->recursive_descent_for_prediction($root_node,\@new_features_and_values, \%answer);
    $answer{'solution_path'} = [reverse( @{$answer{'solution_path'}} )];
    return \%answer;
}

sub recursive_descent_for_prediction {
    my $self = shift;
    my $node = shift;
    my $feature_and_values = shift;
    my $answer = shift;
    my @children = @{$node->get_children()};
    if (@children == 0) {
        my $leaf_node_prediction = $node->node_prediction_from_features_and_values($feature_and_values); 
        $answer->{'prediction'} = $leaf_node_prediction;
        push @{$answer->{'solution_path'}}, $node->get_serial_num();
        return $answer;
    }
    my $feature_tested_at_node = $node->get_feature();
    print "\nFeature tested at node for prediction: $feature_tested_at_node\n" if $self->{_debug3};
    my $value_for_feature;
    my $path_found;
    my $pattern = '(\S+)\s*=\s*(\S+)';
    my ($feature,$value);
    foreach my $feature_and_value (@$feature_and_values) {
        $feature_and_value =~ /$pattern/;
        my ($feature,$value) =  ($1, $2);
        if ($feature eq $feature_tested_at_node) {
            $value_for_feature = $value;
        }
    }
    if (! defined $value_for_feature) {
        my $leaf_node_prediction = $node->node_prediction_from_features_and_values($feature_and_values); 
        $answer->{'prediction'} = $leaf_node_prediction;
        push @{$answer->{'solution_path'}}, $node->get_serial_num();
        return $answer;
    }
    foreach my $child (@children) {
        my @branch_features_and_values = @{$child->get_branch_features_and_values_or_thresholds()};
        my $last_feature_and_value_on_branch = $branch_features_and_values[-1]; 
        my $pattern1 = '(.+)<(.+)';
        my $pattern2 = '(.+)>(.+)';
        if ($last_feature_and_value_on_branch =~ /$pattern1/) {
            my ($feature,$threshold) = ($1, $2);
            if ($value_for_feature <= $threshold) {
                $path_found = 1;
                $answer = $self->recursive_descent_for_prediction($child, $feature_and_values, $answer);
                push @{$answer->{'solution_path'}}, $node->get_serial_num();
                last;
            }
        }
        if ($last_feature_and_value_on_branch =~ /$pattern2/) {
            my ($feature,$threshold) = ($1, $2);
            if ($value_for_feature > $threshold) {
                $path_found = 1;
                $answer = $self->recursive_descent_for_prediction($child, $feature_and_values, $answer);
                push @{$answer->{'solution_path'}}, $node->get_serial_num();
                last;
            }
        }
    }
    return $answer if $path_found;
}

#--------------------------------------  Utility Methods   ----------------------------------------

##  This method is used to verify that you used legal feature names in the test
##  sample that you want to classify with the decision tree.
sub _check_names_used {
    my $self = shift;
    my $features_and_values_test_data = shift;
    my @features_and_values_test_data = @$features_and_values_test_data;
    my $pattern = '(\S+)\s*=\s*(\S+)';
    foreach my $feature_and_value (@features_and_values_test_data) {
        $feature_and_value =~ /$pattern/;
        my ($feature,$value) = ($1,$2);
        die "Your test data has formatting error" unless defined($feature) && defined($value);
        return 0 unless contained_in($feature, @{$self->{_feature_names}});
    }
    return 1;
}

sub display_all_plots {
    my $self = shift;
    my $ncols = $self->{_XMatrix}->cols;
    unlink "regression_plots.png" if -e "regression_plots.png";
    my $master_datafile = $self->{_training_datafile};
    my $filename = basename($master_datafile);
    my $temp_file = "__temp_" . $filename;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!\n";
    if ($ncols == 2) {
        my @predictor_entries = $self->{_XMatrix}->col(0)->as_list;
        my @dependent_val_vals = $self->{_YVector}->col(0)->as_list;
        map {print OUTPUT "$predictor_entries[$_] $dependent_val_vals[$_]\n"} 0 .. $self->{_XMatrix}->rows - 1;
        print OUTPUT "\n\n";
        foreach my $plot (sort {$a <=> $b} keys %{$self->{_output_for_plots}}) {
            map {print OUTPUT "$self->{_output_for_plots}->{$plot}->[0]->[$_] $self->{_output_for_plots}->{$plot}->[1]->[$_]\n"} 0 .. @{$self->{_output_for_plots}->{$plot}->[0]} - 1;
            print OUTPUT "\n\n"
        }
        close OUTPUT;
        my $gplot = Graphics::GnuplotIF->new( persist => 1 );
        my $hardcopy_plot = Graphics::GnuplotIF->new();
        $hardcopy_plot->gnuplot_cmd('set terminal png', "set output \"regression_plots.png\"");        
        $gplot->gnuplot_cmd( "set noclip" );
        $gplot->gnuplot_cmd( "set pointsize 2" );
        my $arg_string = "";
        foreach my $i (0 .. scalar(keys %{$self->{_output_for_plots}})) {
            if ($i == 0) {            
                $arg_string .= "\"$temp_file\" index $i using 1:2 notitle with points lt -1 pt 1, ";
            } elsif ($i == 1) {
                $arg_string .= "\"$temp_file\" index $i using 1:2 title \"linear regression\" with lines lt 1 lw 4, ";
            } elsif ($i == 2) {
                $arg_string .= "\"$temp_file\" index $i using 1:2 title \"tree regression\" with lines lt 3 lw 4, ";
            } else {
                $arg_string .= "\"$temp_file\" index $i using 1:2 notitle with lines lt 3 lw 4, ";
            }
        }
        $arg_string = $arg_string =~ /^(.*),[ ]+$/;
        $arg_string = $1;
        $hardcopy_plot->gnuplot_cmd( "plot $arg_string" );
        $gplot->gnuplot_cmd( "plot $arg_string" );
        $gplot->gnuplot_pause(-1);
    } elsif ($ncols == 3) {
        my @dependent_val_vals = $self->{_YVector}->col(0)->as_list;
        foreach my $i (0 .. $self->{_XMatrix}->rows - 1) {
            my @onerow = $self->{_XMatrix}->row($i)->as_list;
            pop @onerow;
            print OUTPUT "@onerow $dependent_val_vals[$i]\n";
        }
        print OUTPUT "\n\n";
        foreach my $plot (sort {$a <=> $b} keys %{$self->{_output_for_surface_plots}}) {
            my @plot_data = @{$self->{_output_for_surface_plots}->{$plot}};
            my @predictors = @{$plot_data[0]};
            my @predictions = @{$plot_data[1]};
            map {print OUTPUT "$predictors[$_] $predictions[$_]\n"} 0 .. @predictions - 1;
            print OUTPUT "\n\n"
        }
        close OUTPUT;
        my $gplot = Graphics::GnuplotIF->new( persist => 1 );
        my $hardcopy_plot = Graphics::GnuplotIF->new();
        $hardcopy_plot->gnuplot_cmd('set terminal png', "set output \"regression_plots.png\"");        
        $gplot->gnuplot_cmd( "set noclip" );
        $gplot->gnuplot_cmd( "set pointsize 2" );
        my $arg_string = "";
        foreach my $i (0 .. scalar(keys %{$self->{_output_for_surface_plots}})) {
            if ($i == 0) {            
                $arg_string .= "\"$temp_file\" index $i using 1:2:3 notitle with points lt -1 pt 1, ";
            } elsif ($i == 1) {
                $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"linear regression\" with points lt 1 pt 2, ";
            } elsif ($i == 2) {
                $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"tree regression\" with points lt 3 pt 3, ";
            } else {
                $arg_string .= "\"$temp_file\" index $i using 1:2:3 notitle with points lt 3 pt 3, ";
            }
        }
        $arg_string = $arg_string =~ /^(.*),[ ]+$/;
        $arg_string = $1;
        $hardcopy_plot->gnuplot_cmd( "splot $arg_string" );
        $gplot->gnuplot_cmd( "splot $arg_string" );
        $gplot->gnuplot_pause(-1);
    } else {
        die "no visual displays for regression from more then 2 predictor vars";
    }   
}  

sub DESTROY {
    unlink glob "__temp_*";
}

############################################## Utility Routines ##########################################
# checks whether an element is in an array:
sub contained_in {
    my $ele = shift;
    my @array = @_;
    my $count = 0;
    map {$count++ if $ele eq $_} @array;
    return $count;
}

sub minmax {
    my $arr = shift;
    my ($min, $max);
    foreach my $i (0..@{$arr}-1) {
        if ( (!defined $min) || ($arr->[$i] < $min) ) {
            $min = $arr->[$i];
        }
        if ( (!defined $max) || ($arr->[$i] > $max) ) {
            $max = $arr->[$i];
        }
    }
    return ($min, $max);
}

sub sample_index {
    my $arg = shift;
    $arg =~ /_(.+)$/;
    return $1;
}    

sub check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / training_datafile
                            max_depth_desired
                            dependent_variable_column
                            predictor_columns
                            mse_threshold
                            need_data_normalization
                            jacobian_choice
                            csv_cleanup_needed
                            debug1_r
                            debug2_r
                            debug3_r
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

sub cleanup_csv {
    my $line = shift;
    $line =~ tr/\/:?()[]{}'/          /;
    my @double_quoted = substr($line, index($line,',')) =~ /\"[^\"]+\"/g;
    for (@double_quoted) {
        my $item = $_;
        $item = substr($item, 1, -1);
        $item =~ s/^s+|,|\s+$//g;
        $item = join '_',  split /\s+/, $item;
        substr($line, index($line, $_), length($_)) = $item;
    }
    my @white_spaced = $line =~ /,(\s*[^,]+)(?=,|$)/g;
    for (@white_spaced) {
        my $item = $_;
        $item =~ s/\s+/_/g;
        $item =~ s/^\s*_|_\s*$//g;
        substr($line, index($line, $_), length($_)) = $item;
    }
    $line =~ s/,\s*(?=,|$)/,NA/g;
    return $line;
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

sub vector_norm {
    my $vec = shift;       # assume it to be a column vector
    my ($rows, $cols) = $vec->dim;
    die "vector_norm() can only be called for a single column matrix" if $cols > 1;
    my @norm = (transpose($vec) * $vec)->as_list;
    return sqrt($norm[0]);
}

sub display_matrix {
    my $matrix = shift;
    my $nrows = $matrix->rows();
    my $ncols = $matrix->cols();
    print "\nDisplaying a matrix of size $nrows rows and $ncols columns:\n";
    foreach my $i (0..$nrows-1) {
        my $row = $matrix->row($i);
        my @row_as_list = $row->as_list;
        map { printf("%.4f ", $_) } @row_as_list;
        print "\n";
    }
    print "\n\n";
}

# Meant only for an array of strings (no nesting):
sub deep_copy_array {
    my $ref_in = shift;
    my $ref_out;
    return [] if scalar @$ref_in == 0;
    foreach my $i (0..@{$ref_in}-1) {
        $ref_out->[$i] = $ref_in->[$i];
    }
    return $ref_out;
}


#############################################  Class RTNode  #############################################

# The nodes of a regression tree are instances of this class:
package RTNode;

use strict; 
use Carp;

# $feature is the feature test at the current node.  $branch_features_and_values is
# an anonymous array holding the feature names and corresponding values on the path
# from the root to the current node:
sub new {                                                           
    my ($class, $feature, $error, $beta, $branch_features_and_values_or_thresholds, $rt, $root_or_not) = @_; 
    $root_or_not = '' if !defined $root_or_not;
    if ($root_or_not eq 'root') {
        $rt->{nodes_created} = -1;
        $rt->{class_names} = undef;
    }
    my $self = {                                                         
            _rt                      => $rt,
            _feature                 => $feature,                                       
            _error                   => $error,                                       
            _beta                    => $beta,                                       
            _branch_features_and_values_or_thresholds => $branch_features_and_values_or_thresholds,
            _num_data_points         => undef,                                       
            _XMatrix                 => undef,
            _YVector                 => undef,
            _linked_to               => [],                                          
    };
    bless $self, $class;
    $self->{_serial_number} =  $self->get_next_serial_num();
    return $self;
}

sub node_prediction_from_features_and_values {
    my $self = shift;
    my $feature_and_values = shift;
    my $ncols = $self->{_XMatrix}->cols;
    my $pattern = '(\S+)\s*=\s*(\S+)';
    my ($feature,$value);
    my @Xlist;
    foreach my $feature_name (@{$self->{_rt}->{_feature_names}}) {
        foreach my $feature_and_value (@{$feature_and_values}) {
            $feature_and_value =~ /$pattern/;
            my ($feature, $value) = ($1, $2);
            push @Xlist, $value if $feature_name eq $feature; 
        }
    }
    push @Xlist, 1;
    my $dataMatrix = Math::GSL::Matrix->new(1, $ncols);
    $dataMatrix->set_row(0, \@Xlist);
    my $prediction = $dataMatrix * $self->get_node_beta();
    return $prediction->get_elem(0,0);
}

sub node_prediction_from_data_as_matrix {
    my $self = shift;
    my $dataMatrix = shift;
    my $prediction = $dataMatrix * $self->get_node_beta();
    return $prediction->get_elem(0,0);
}

sub node_prediction_from_data_as_list {
    my $self = shift;
    my $data_as_list = shift;
    my @data_arr =  @{$data_as_list};
    my $ncols = $self->{_XMatrix}->cols;
    die "wrong number of elements in data list" if @data_arr != $ncols - 1;
    push @data_arr, 1;
    my $dataMatrix = Math::GSL::Matrix->new(1, $self->{_XMatrix}->cols);
    my $prediction = $dataMatrix * $self->get_node_beta();
    return $prediction->get_elem(0,0);
}

sub how_many_nodes {
    my $self = shift;
    return $self->{_rt}->{nodes_created} + 1;
}

sub get_num_data_points {
    my $self = shift;
    return $self->{_num_data_points};
}  

sub set_num_data_points {
    my $self = shift;
    my $how_many = shift;
    $self->{_num_data_points} = $how_many;
}

sub set_node_XMatrix {
    my $self = shift;
    my $xmatrix = shift;
    $self->{_XMatrix} = $xmatrix;
}

sub get_node_XMatrix {
    my $self = shift;
    return $self->{_XMatrix};
}

sub set_node_YVector {
    my $self = shift;
    my $yvector = shift;
    $self->{_YVector} = $yvector;
}

sub get_node_YVector {
    my $self = shift;
    return $self->{_YVector};
}  

sub set_node_error {
    my $self = shift;
    my $error = shift;
    $self->{_error} = $error;
}

sub get_node_error {
    my $self = shift;
    return $self->{_error};
}

sub set_node_beta {
    my $self = shift;
    my $beta = shift;
    $self->{_beta} = $beta;
}

sub get_node_beta {
    my $self = shift;
    return $self->{_beta};
}

sub get_next_serial_num {
    my $self = shift;
    $self->{_rt}->{nodes_created} += 1;
    return $self->{_rt}->{nodes_created};
}

sub get_serial_num {
    my $self = shift;
    $self->{_serial_number};
}

# this returns the feature test at the current node
sub get_feature {                                  
    my $self = shift;                              
    return $self->{ _feature };                    
}

sub set_feature {
    my $self = shift;
    my $feature = shift;
    $self->{_feature} = $feature;
}

sub get_branch_features_and_values_or_thresholds {
    my $self = shift; 
    return $self->{_branch_features_and_values_or_thresholds};
}

sub get_children {       
    my $self = shift;                   
    return $self->{_linked_to};
}

sub add_child_link {         
    my ($self, $new_node, ) = @_;                            
    push @{$self->{_linked_to}}, $new_node;                  
}

sub delete_all_links {                  
    my $self = shift;                   
    $self->{_linked_to} = undef;        
}

sub display_node {
    my $self = shift; 
    my $feature_at_node = $self->get_feature() || " ";
    my $serial_num = $self->get_serial_num();
    my @branch_features_and_values_or_thresholds = @{$self->get_branch_features_and_values_or_thresholds()};
    print "\n\nNODE $serial_num" .
          ":\n   Branch features and values to this node: @branch_features_and_values_or_thresholds" .
          "\n   Best feature test at current node: $feature_at_node\n\n";
    $self->{_rt}->estimate_regression_coefficients($self->get_node_XMatrix(), $self->get_node_YVector(), 1);
}

sub display_regression_tree {
    my $self = shift;
    my $offset = shift;
    my $serial_num = $self->get_serial_num();
    if (@{$self->get_children()} > 0) {
        my $feature_at_node = $self->get_feature() || " ";
        my @branch_features_and_values_or_thresholds = @{$self->get_branch_features_and_values_or_thresholds()};
        print "NODE $serial_num: $offset BRANCH TESTS TO NODE: @branch_features_and_values_or_thresholds\n";
        my $second_line_offset = "$offset" . " " x (8 + length("$serial_num"));
        print "$second_line_offset" . "Decision Feature: $feature_at_node\n\n";
        $offset .= "   ";
        foreach my $child (@{$self->get_children()}) {
            $child->display_regression_tree($offset);
        }
    } else {
        my @branch_features_and_values_or_thresholds = @{$self->get_branch_features_and_values_or_thresholds()};
        print "NODE $serial_num: $offset BRANCH TESTS TO LEAF NODE: @branch_features_and_values_or_thresholds\n";
        my $second_line_offset = "$offset" . " " x (8 + length("$serial_num"));
    }
}

1;
