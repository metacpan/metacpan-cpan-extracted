package Algorithm::DecisionTree;

#--------------------------------------------------------------------------------------
# Copyright (c) 2016 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::DecisionTree is a Perl module for decision-tree based classification of 
# multidimensional data.
# -------------------------------------------------------------------------------------

#use 5.10.0;
use strict;
use warnings;
use Carp;

our $VERSION = '3.42';

############################################   Constructor  ##############################################
sub new { 
    my ($class, %args, $eval_or_boosting_mode);
    if (@_ % 2 != 0) {
        ($class, %args) = @_;
    } else {
        $class = shift;
        $eval_or_boosting_mode = shift;
        die unless $eval_or_boosting_mode eq 'evalmode' || $eval_or_boosting_mode eq 'boostingmode';
        die "Only one string arg allowed in eval and boosting modes" if @_;
    }
    unless ($eval_or_boosting_mode) {
        my @params = keys %args;
        croak "\nYou have used a wrong name for a keyword argument --- perhaps a misspelling\n" 
                           if check_for_illegal_params2(@params) == 0;
    }
    bless {
        _training_datafile                   =>    $args{training_datafile}, 
        _entropy_threshold                   =>    $args{entropy_threshold} || 0.01,
        _max_depth_desired                   =>    exists $args{max_depth_desired} ? 
                                                                       $args{max_depth_desired} : undef,
        _debug1                              =>    $args{debug1} || 0,
        _debug2                              =>    $args{debug2} || 0,
        _debug3                              =>    $args{debug3} || 0,
        _csv_class_column_index              =>    $args{csv_class_column_index} || undef,
        _csv_columns_for_features            =>    $args{csv_columns_for_features} || undef,
        _symbolic_to_numeric_cardinality_threshold
                                             =>    $args{symbolic_to_numeric_cardinality_threshold} || 10,
        _number_of_histogram_bins            =>    $args{number_of_histogram_bins} || undef,
        _csv_cleanup_needed                  =>    $args{csv_cleanup_needed} || 0,
        _training_data                       =>    [],
        _root_node                           =>    undef,
        _probability_cache                   =>    {},
        _entropy_cache                       =>    {},
        _training_data_hash                  =>    {},
        _features_and_values_hash            =>    {},
        _samples_class_label_hash            =>    {},
        _class_names                         =>    [],
        _class_priors                        =>    [],
        _class_priors_hash                   =>    {},
        _feature_names                       =>    [],
        _numeric_features_valuerange_hash    =>    {},
        _sampling_points_for_numeric_feature_hash      =>      {},
        _feature_values_how_many_uniques_hash          =>      {},
        _prob_distribution_numeric_features_hash       =>      {},
        _histogram_delta_hash                          =>      {},
        _num_of_histogram_bins_hash                    =>      {},
    }, $class;

}

####################################  Classify with Decision Tree  #######################################

##  Classifies one test sample at a time using the decision tree constructed from
##  your training file.  The data record for the test sample must be supplied as
##  shown in the scripts in the `examples' subdirectory.  See the scripts
##  construct_dt_and_classify_one_sample_caseX.pl in that subdirectory.
sub classify {
    my $self = shift;
    my $root_node = shift;
    my $feature_and_values = shift;
    my $numregex =  '[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?';
    my @features_and_values = @$feature_and_values;
    @features_and_values = @{deep_copy_array(\@features_and_values)};
    die "\n\nError in the names you have used for features and/or values.  " .
        "Try using the csv_cleanup_needed option in the constructor call." 
                        unless $self->check_names_used(\@features_and_values);
    my @new_features_and_values = ();
    my $pattern = '(\S+)\s*=\s*(\S+)';
    foreach my $feature_and_value (@features_and_values) {
        $feature_and_value =~ /$pattern/;
        my ($feature, $value) = ($1, $2);
        my $newvalue = $value;
        my @unique_values_for_feature = @{$self->{_features_and_unique_values_hash}->{$feature}};
        my $not_all_values_float = 0;
        map {$not_all_values_float = 1 if $_ !~ /^$numregex$/} @unique_values_for_feature;
        if (! contained_in($feature, keys %{$self->{_prob_distribution_numeric_features_hash}}) &&
                                                                       $not_all_values_float == 0) {
            $newvalue = closest_sampling_point($value, \@unique_values_for_feature);
        }
        push @new_features_and_values, "$feature" . '=' . "$newvalue";
    }
    @features_and_values = @new_features_and_values;
    print "\nCL1 New feature and values: @features_and_values\n" if $self->{_debug3};
    my %answer = ();
    foreach my $class_name (@{$self->{_class_names}}) {
        $answer{$class_name} = undef;
    }
    $answer{'solution_path'} = [];
    my %classification = %{$self->recursive_descent_for_classification($root_node, 
                                                                    \@features_and_values,\%answer)};
    @{$answer{'solution_path'}} = reverse @{$answer{'solution_path'}};
    if ($self->{_debug3}) {
        print "\nCL2 The classification:\n";
        foreach my $class_name (@{$self->{_class_names}}) {
            print "    $class_name  with probability $classification{$class_name}\n";
        }
    }
    my %classification_for_display = ();
    foreach my $item (keys %classification) {
        if ($item ne 'solution_path') {
            $classification_for_display{$item} = sprintf("%0.3f", $classification{$item});
        } else {
            my @outlist = ();
            foreach my $x (@{$classification{$item}}) {
                push @outlist, "NODE$x";
            }
            $classification_for_display{$item} =  \@outlist;
        }
    }
    return \%classification_for_display;
}

sub recursive_descent_for_classification {
    my $self = shift;
    my $node = shift;
    my $features_and_values = shift;
    my $answer = shift;
    my @features_and_values = @$features_and_values;
    my %answer = %$answer;
    my @children = @{$node->get_children()};
    if (@children == 0) {
        my @leaf_node_class_probabilities = @{$node->get_class_probabilities()};
        foreach my $i (0..@{$self->{_class_names}}-1) {
            $answer{$self->{_class_names}->[$i]} = $leaf_node_class_probabilities[$i];
        }
        push @{$answer{'solution_path'}}, $node->get_serial_num();
        return \%answer;
    }
    my $feature_tested_at_node = $node->get_feature();
    print "\nCLRD1 Feature tested at node for classification: $feature_tested_at_node\n" 
        if $self->{_debug3};
    my $value_for_feature;
    my $path_found;
    my $pattern = '(\S+)\s*=\s*(\S+)';
    foreach my $feature_and_value (@features_and_values) {
        $feature_and_value =~ /$pattern/;
        $value_for_feature = $2 if $feature_tested_at_node eq $1;
    }
    # The following clause introduced in Version 3.20
    if (!defined $value_for_feature) {
        my @leaf_node_class_probabilities = @{$node->get_class_probabilities()};
        foreach my $i (0..@{$self->{_class_names}}-1) {
            $answer{$self->{_class_names}->[$i]} = $leaf_node_class_probabilities[$i];
        }
        push @{$answer{'solution_path'}}, $node->get_serial_num();
        return \%answer;
    }
    if ($value_for_feature) {
        if (contained_in($feature_tested_at_node, keys %{$self->{_prob_distribution_numeric_features_hash}})) {
            print( "\nCLRD2 In the truly numeric section") if $self->{_debug3};
            my $pattern1 = '(.+)<(.+)';
            my $pattern2 = '(.+)>(.+)';
            foreach my $child (@children) {
                my @branch_features_and_values = @{$child->get_branch_features_and_values_or_thresholds()};
                my $last_feature_and_value_on_branch = $branch_features_and_values[-1]; 
                if ($last_feature_and_value_on_branch =~ /$pattern1/) {
                    my ($feature, $threshold) = ($1,$2); 
                    if ($value_for_feature <= $threshold) {
                        $path_found = 1;
                        %answer = %{$self->recursive_descent_for_classification($child,
                                                                             $features_and_values,\%answer)};
                        push @{$answer{'solution_path'}}, $node->get_serial_num();
                        last;
                    }
                }
                if ($last_feature_and_value_on_branch =~ /$pattern2/) {
                    my ($feature, $threshold) = ($1,$2); 
                    if ($value_for_feature > $threshold) {
                        $path_found = 1;
                        %answer = %{$self->recursive_descent_for_classification($child,
                                                                            $features_and_values,\%answer)};
                        push @{$answer{'solution_path'}}, $node->get_serial_num();
                        last;
                    }
                }
            }
            return \%answer if $path_found;
        } else {
            my $feature_value_combo = "$feature_tested_at_node" . '=' . "$value_for_feature";
            print "\nCLRD3 In the symbolic section with feature_value_combo: $feature_value_combo\n" 
                if $self->{_debug3};
            foreach my $child (@children) {
                my @branch_features_and_values = @{$child->get_branch_features_and_values_or_thresholds()};
                print "\nCLRD4 branch features and values: @branch_features_and_values\n" if $self->{_debug3};
                my $last_feature_and_value_on_branch = $branch_features_and_values[-1]; 
                if ($last_feature_and_value_on_branch eq $feature_value_combo) {
                    %answer = %{$self->recursive_descent_for_classification($child,
                                                                              $features_and_values,\%answer)};
                    push @{$answer{'solution_path'}}, $node->get_serial_num();
                    $path_found = 1;
                    last;
                }
            }
            return \%answer if $path_found;
        }
    }
    if (! $path_found) {
        my @leaf_node_class_probabilities = @{$node->get_class_probabilities()};
        foreach my $i (0..@{$self->{_class_names}}-1) {
            $answer{$self->{_class_names}->[$i]} = $leaf_node_class_probabilities[$i];
        }
        push @{$answer{'solution_path'}}, $node->get_serial_num();
    }
    return \%answer;
}

##  If you want classification to be carried out by engaging a human user in a
##  question-answer session, this is the method to use for that purpose.  See, for
##  example, the script classify_by_asking_questions.pl in the `examples'
##  subdirectory for an illustration of how to do that.
sub classify_by_asking_questions {
    my $self = shift;
    my $root_node = shift;
    my %answer = ();
    foreach my $class_name (@{$self->{_class_names}}) {
        $answer{$class_name} = undef;
    }
    $answer{'solution_path'} = [];
    my %scratchpad_for_numeric_answers = ();
    foreach my $feature_name (keys %{$self->{_prob_distribution_numeric_features_hash}}) {
        $scratchpad_for_numeric_answers{$feature_name} = undef;
    }
    my %classification = %{$self->interactive_recursive_descent_for_classification($root_node,
                                                       \%answer, \%scratchpad_for_numeric_answers)};
    @{$classification{'solution_path'}} = reverse @{$classification{'solution_path'}};
    my %classification_for_display = ();
    foreach my $item (keys %classification) {
        if ($item ne 'solution_path') {
            $classification_for_display{$item} = sprintf("%0.3f", $classification{$item});
        } else {
            my @outlist = ();
            foreach my $x (@{$classification{$item}}) {
                push @outlist, "NODE$x";
            }
            $classification_for_display{$item} =  \@outlist;
        }
    }
    return \%classification_for_display;
}

sub interactive_recursive_descent_for_classification {
    my $self = shift;
    my $node = shift;
    my $answer = shift;
    my $scratchpad_for_numerics = shift;
    my %answer = %$answer;
    my %scratchpad_for_numerics = %$scratchpad_for_numerics;
    my $pattern1 = '(.+)<(.+)';
    my $pattern2 = '(.+)>(.+)';
    my $user_value_for_feature;
    my @children = @{$node->get_children()};
    if (@children == 0) {
        my @leaf_node_class_probabilities = @{$node->get_class_probabilities()};
        foreach my $i (0..@{$self->{_class_names}}-1) {
            $answer{$self->{_class_names}->[$i]} = $leaf_node_class_probabilities[$i];
        }
        push @{$answer{'solution_path'}}, $node->get_serial_num();
        return \%answer;
    }
    my @list_of_branch_attributes_to_children = ();
    foreach my $child (@children) {   
        my @branch_features_and_values = @{$child->get_branch_features_and_values_or_thresholds()};
        my $feature_and_value_on_branch = $branch_features_and_values[-1];
        push @list_of_branch_attributes_to_children, $feature_and_value_on_branch;
    }
    my $feature_tested_at_node = $node->get_feature();
    my $feature_value_combo;
    my $path_found = 0;
    if (contained_in($feature_tested_at_node, keys %{$self->{_prob_distribution_numeric_features_hash}})) {
        if ($scratchpad_for_numerics{$feature_tested_at_node}) {
            $user_value_for_feature = $scratchpad_for_numerics{$feature_tested_at_node};
        } else {
            my @valuerange =  @{$self->{_numeric_features_valuerange_hash}->{$feature_tested_at_node}};
            while (1) { 
                print "\nWhat is the value for the feature $feature_tested_at_node ?\n";
                print "\nEnter a value in the range (@valuerange): ";
                $user_value_for_feature = <STDIN>;
                $user_value_for_feature =~ s/\r?\n?$//;
                $user_value_for_feature =~ s/^\s*(\S+)\s*$/$1/;
                my $answer_found = 0;
                if ($user_value_for_feature >= $valuerange[0] && $user_value_for_feature <= $valuerange[1]) {
                    $answer_found = 1;
                    last;
                }
                last if $answer_found;
                print("You entered illegal value. Let's try again")
            }
            $scratchpad_for_numerics{$feature_tested_at_node} = $user_value_for_feature;
        }
        foreach my $i (0..@list_of_branch_attributes_to_children-1) {
            my $branch_attribute = $list_of_branch_attributes_to_children[$i];
            if ($branch_attribute =~ /$pattern1/) {
                my ($feature,$threshold) = ($1,$2);
                if ($user_value_for_feature <= $threshold) {
                    %answer = %{$self->interactive_recursive_descent_for_classification($children[$i],
                                                                     \%answer, \%scratchpad_for_numerics)};
                    $path_found = 1;
                    push @{$answer{'solution_path'}}, $node->get_serial_num();
                    last;
                }
            }
            if ($branch_attribute =~ /$pattern2/) {
                my ($feature,$threshold) = ($1,$2);
                if ($user_value_for_feature > $threshold) {
                    %answer = %{$self->interactive_recursive_descent_for_classification($children[$i],
                                                                     \%answer, \%scratchpad_for_numerics)};
                    $path_found = 1;
                    push @{$answer{'solution_path'}}, $node->get_serial_num();
                    last;
                }
            }
        }
        return \%answer if $path_found;
    } else {
        my @possible_values_for_feature = @{$self->{_features_and_unique_values_hash}->{$feature_tested_at_node}};
        while (1) {
            print "\nWhat is the value for the feature $feature_tested_at_node ?\n";
            print "\nEnter a value from the list (@possible_values_for_feature): ";
            $user_value_for_feature = <STDIN>;
            $user_value_for_feature =~ s/\r?\n?$//;
            $user_value_for_feature =~ s/^\s*(\S+)\s*$/$1/;
            my $answer_found = 0;
            if (contained_in($user_value_for_feature, @possible_values_for_feature)) {
                $answer_found = 1;
                last;
            }
            last if $answer_found;
            print("You entered illegal value. Let's try again");
        }
        $feature_value_combo = "$feature_tested_at_node=$user_value_for_feature";
        foreach my $i (0..@list_of_branch_attributes_to_children-1) {
            my $branch_attribute = $list_of_branch_attributes_to_children[$i];
            if ($branch_attribute eq $feature_value_combo) {
                %answer = %{$self->interactive_recursive_descent_for_classification($children[$i],
                                                                     \%answer, \%scratchpad_for_numerics)};
                $path_found = 1;
                push @{$answer{'solution_path'}}, $node->get_serial_num();
                last;
            }
        }
        return \%answer if $path_found;
    }
    if (! $path_found) {
        my @leaf_node_class_probabilities = @{$node->get_class_probabilities()};
        foreach my $i (0..@{$self->{_class_names}}-1) {
            $answer{$self->{_class_names}->[$i]} = $leaf_node_class_probabilities[$i];
        }
        push @{$answer{'solution_path'}}, $node->get_serial_num();
    }
    return \%answer;
}

######################################    Decision Tree Construction  ####################################

##  At the root node, we find the best feature that yields the greatest reduction in
##  class entropy from the entropy based on just the class priors. The logic for
##  finding this feature is different for symbolic features and for numeric features.
##  That logic is built into the method shown later for best feature calculations.
sub construct_decision_tree_classifier {
    print "\nConstructing the decision tree ...\n";
    my $self = shift;
    if ($self->{_debug3}) {        
        $self->determine_data_condition(); 
        print "\nStarting construction of the decision tree:\n";
    }
    my @class_probabilities = map {$self->prior_probability_for_class($_)} @{$self->{_class_names}};
    if ($self->{_debug3}) { 
        print "\nPrior class probabilities: @class_probabilities\n";
        print "\nClass names: @{$self->{_class_names}}\n";
    }
    my $entropy = $self->class_entropy_on_priors();
    print "\nClass entropy on priors: $entropy\n" if $self->{_debug3};
    my $root_node = DTNode->new(undef, $entropy, \@class_probabilities, [], $self, 'root');
    $root_node->set_class_names(\@{$self->{_class_names}});
    $self->{_root_node} = $root_node;
    $self->recursive_descent($root_node);
    return $root_node;
}

##  After the root node of the decision tree is calculated by the previous methods,
##  we invoke this method recursively to create the rest of the tree.  At each node,
##  we find the feature that achieves the largest entropy reduction with regard to
##  the partitioning of the training data samples that correspond to that node.
sub recursive_descent {
    my $self = shift;
    my $node = shift;
    print "\n==================== ENTERING RECURSIVE DESCENT ==========================\n"
        if $self->{_debug3};
    my $node_serial_number = $node->get_serial_num();
    my @features_and_values_or_thresholds_on_branch = @{$node->get_branch_features_and_values_or_thresholds()};
    my $existing_node_entropy = $node->get_node_entropy();
    if ($self->{_debug3}) { 
        print "\nRD1 NODE SERIAL NUMBER: $node_serial_number\n";
        print "\nRD2 Existing Node Entropy: $existing_node_entropy\n";
        print "\nRD3 features_and_values_or_thresholds_on_branch: @features_and_values_or_thresholds_on_branch\n";
        my @class_probs = @{$node->get_class_probabilities()};
        print "\nRD4 Class probabilities: @class_probs\n";
    }
    if ($existing_node_entropy < $self->{_entropy_threshold}) { 
        print "\nRD5 returning because existing node entropy is below threshold\n" if $self->{_debug3};
        return;
    }
    my @copy_of_path_attributes = @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
    my ($best_feature, $best_feature_entropy, $best_feature_val_entropies, $decision_val) =
                    $self->best_feature_calculator(\@copy_of_path_attributes, $existing_node_entropy);
    $node->set_feature($best_feature);
    $node->display_node() if $self->{_debug3};
    if (defined($self->{_max_depth_desired}) && 
               (@features_and_values_or_thresholds_on_branch >= $self->{_max_depth_desired})) {
        print "\nRD6 REACHED LEAF NODE AT MAXIMUM DEPTH ALLOWED\n" if $self->{_debug3}; 
        return;
    }
    return if ! defined $best_feature;
    if ($self->{_debug3}) { 
        print "\nRD7 Existing entropy at node: $existing_node_entropy\n";
        print "\nRD8 Calculated best feature is $best_feature and its value $decision_val\n";
        print "\nRD9 Best feature entropy: $best_feature_entropy\n";
        print "\nRD10 Calculated entropies for different values of best feature: @$best_feature_val_entropies\n";
    }
    my $entropy_gain = $existing_node_entropy - $best_feature_entropy;
    print "\nRD11 Expected entropy gain at this node: $entropy_gain\n" if $self->{_debug3};
    if ($entropy_gain > $self->{_entropy_threshold}) {
        if (exists $self->{_numeric_features_valuerange_hash}->{$best_feature} && 
              $self->{_feature_values_how_many_uniques_hash}->{$best_feature} > 
                                        $self->{_symbolic_to_numeric_cardinality_threshold}) {
            my $best_threshold = $decision_val;            # as returned by best feature calculator
            my ($best_entropy_for_less, $best_entropy_for_greater) = @$best_feature_val_entropies;
            my @extended_branch_features_and_values_or_thresholds_for_lessthan_child = 
                                        @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
            my @extended_branch_features_and_values_or_thresholds_for_greaterthan_child  = 
                                        @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)}; 
            my $feature_threshold_combo_for_less_than = "$best_feature" . '<' . "$best_threshold";
            my $feature_threshold_combo_for_greater_than = "$best_feature" . '>' . "$best_threshold";
            push @extended_branch_features_and_values_or_thresholds_for_lessthan_child, 
                                                                  $feature_threshold_combo_for_less_than;
            push @extended_branch_features_and_values_or_thresholds_for_greaterthan_child, 
                                                               $feature_threshold_combo_for_greater_than;
            if ($self->{_debug3}) {
                print "\nRD12 extended_branch_features_and_values_or_thresholds_for_lessthan_child: " .
                      "@extended_branch_features_and_values_or_thresholds_for_lessthan_child\n";
                print "\nRD13 extended_branch_features_and_values_or_thresholds_for_greaterthan_child: " .
                      "@extended_branch_features_and_values_or_thresholds_for_greaterthan_child\n";
            }
            my @class_probabilities_for_lessthan_child_node = 
                map {$self->probability_of_a_class_given_sequence_of_features_and_values_or_thresholds($_,
                 \@extended_branch_features_and_values_or_thresholds_for_lessthan_child)} @{$self->{_class_names}};
            my @class_probabilities_for_greaterthan_child_node = 
                map {$self->probability_of_a_class_given_sequence_of_features_and_values_or_thresholds($_,
              \@extended_branch_features_and_values_or_thresholds_for_greaterthan_child)} @{$self->{_class_names}};
            if ($self->{_debug3}) {
                print "\nRD14 class entropy for going down lessthan child: $best_entropy_for_less\n";
                print "\nRD15 class_entropy_for_going_down_greaterthan_child: $best_entropy_for_greater\n";
            }
            if ($best_entropy_for_less < $existing_node_entropy - $self->{_entropy_threshold}) {
                my $left_child_node = DTNode->new(undef, $best_entropy_for_less,
                                                         \@class_probabilities_for_lessthan_child_node,
                              \@extended_branch_features_and_values_or_thresholds_for_lessthan_child, $self);
                $node->add_child_link($left_child_node);
                $self->recursive_descent($left_child_node);
            }
            if ($best_entropy_for_greater < $existing_node_entropy - $self->{_entropy_threshold}) {
                my $right_child_node = DTNode->new(undef, $best_entropy_for_greater,
                                                         \@class_probabilities_for_greaterthan_child_node,
                            \@extended_branch_features_and_values_or_thresholds_for_greaterthan_child, $self);
                $node->add_child_link($right_child_node);
                $self->recursive_descent($right_child_node);
            }
        } else {
            print "\nRD16 RECURSIVE DESCENT: In section for symbolic features for creating children"
                if $self->{_debug3};
            my @values_for_feature = @{$self->{_features_and_unique_values_hash}->{$best_feature}};
            print "\nRD17 Values for feature $best_feature are @values_for_feature\n" if $self->{_debug3};
            my @feature_value_combos = sort map {"$best_feature" . '=' . $_} @values_for_feature;
            my @class_entropies_for_children = ();
            foreach my $feature_and_value_index (0..@feature_value_combos-1) {
                print "\nRD18 Creating a child node for: $feature_value_combos[$feature_and_value_index]\n"
                    if $self->{_debug3};
                my @extended_branch_features_and_values_or_thresholds;
                if (! @features_and_values_or_thresholds_on_branch) {
                    @extended_branch_features_and_values_or_thresholds = 
                                                          ($feature_value_combos[$feature_and_value_index]);
                } else {
                    @extended_branch_features_and_values_or_thresholds = 
                        @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
                    push @extended_branch_features_and_values_or_thresholds, 
                                           $feature_value_combos[$feature_and_value_index];
                }
                my @class_probabilities =
                   map {$self->probability_of_a_class_given_sequence_of_features_and_values_or_thresholds($_,
                               \@extended_branch_features_and_values_or_thresholds)} @{$self->{_class_names}};
                my $class_entropy_for_child = 
                      $self->class_entropy_for_a_given_sequence_of_features_and_values_or_thresholds(
                                                         \@extended_branch_features_and_values_or_thresholds);
                if ($self->{_debug3}) {
                    print "\nRD19 branch attributes: @extended_branch_features_and_values_or_thresholds\n";
                    print "\nRD20 class entropy for child: $class_entropy_for_child\n"; 
                }
                if ($existing_node_entropy - $class_entropy_for_child > $self->{_entropy_threshold}) {
                    my $child_node = DTNode->new(undef, $class_entropy_for_child,
                          \@class_probabilities, \@extended_branch_features_and_values_or_thresholds, $self);
                    $node->add_child_link($child_node);
                    $self->recursive_descent($child_node);
                } else {
                    print "\nRD21 This child will NOT result in a node\n" if $self->{_debug3};
                }
            }
        }
    } else {
        print "\nRD22 REACHED LEAF NODE NATURALLY for: @features_and_values_or_thresholds_on_branch\n" 
            if $self->{_debug3};
        return;
    }
}

##  This is the heart of the decision tree constructor.  Its main job is to figure
##  out the best feature to use for partitioning the training data samples that
##  correspond to the current node.  The search for the best feature is carried out
##  differently for symbolic features and for numeric features.  For a symbolic
##  feature, the method estimates the entropy for each value of the feature and then
##  averages out these entropies as a measure of the discriminatory power of that
##  features.  For a numeric feature, on the other hand, it estimates the entropy
##  reduction that can be achieved if were to partition the set of training samples
##  for each possible threshold.  For a numeric feature, all possible sampling points
##  relevant to the node in question are considered as candidates for thresholds.
sub best_feature_calculator {
    my $self = shift;
    my $features_and_values_or_thresholds_on_branch = shift;
    my $existing_node_entropy = shift;
    my @features_and_values_or_thresholds_on_branch =  @$features_and_values_or_thresholds_on_branch;
    my $pattern1 = '(.+)=(.+)';
    my $pattern2 = '(.+)<(.+)';
    my $pattern3 = '(.+)>(.+)';
    my @all_symbolic_features = ();
    foreach my $feature_name (@{$self->{_feature_names}}) {
        push @all_symbolic_features, $feature_name 
            if ! exists $self->{_prob_distribution_numeric_features_hash}->{$feature_name};
    }
    my @symbolic_features_already_used = ();  
    foreach my $feature_and_value_or_threshold (@features_and_values_or_thresholds_on_branch) {
        push @symbolic_features_already_used, $1 if $feature_and_value_or_threshold =~ /$pattern1/;
    }
    my @symbolic_features_not_yet_used;
    foreach my $x (@all_symbolic_features) {
        push @symbolic_features_not_yet_used, $x unless contained_in($x, @symbolic_features_already_used);
    }
    my @true_numeric_types = ();
    my @symbolic_types = ();
    my @true_numeric_types_feature_names = ();
    my @symbolic_types_feature_names = ();
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
    my %entropy_values_for_different_features = ();
    my %partitioning_point_child_entropies_hash = ();
    my %partitioning_point_threshold = ();
    my %entropies_for_different_values_of_symbolic_feature = ();
    foreach my $feature (@{$self->{_feature_names}}) {
        $entropy_values_for_different_features{$feature} = [];
        $partitioning_point_child_entropies_hash{$feature} = {};
        $partitioning_point_threshold{$feature} = undef;
        $entropies_for_different_values_of_symbolic_feature{$feature} = [];
    }
    foreach my $i (0..@{$self->{_feature_names}}-1) {
        my $feature_name = $self->{_feature_names}->[$i];
        print "\n\nBFC1          FEATURE BEING CONSIDERED: $feature_name\n" if $self->{_debug3};
        if (contained_in($feature_name, @symbolic_features_already_used)) {
            next;
        } elsif (contained_in($feature_name, keys %{$self->{_numeric_features_valuerange_hash}}) &&
                 $self->{_feature_values_how_many_uniques_hash}->{$feature_name} >
                                      $self->{_symbolic_to_numeric_cardinality_threshold}) {
            my @values = @{$self->{_sampling_points_for_numeric_feature_hash}->{$feature_name}};
            print "\nBFC4 values for $feature_name are @values\n" if $self->{_debug3};      
            my @newvalues = ();
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
            next if @newvalues == 0;
            my @partitioning_entropies = ();            
            foreach my $value (@newvalues) {
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
                my $entropy1 = $self->class_entropy_for_less_than_threshold_for_feature(
                                    \@features_and_values_or_thresholds_on_branch, $feature_name, $value);
                my $entropy2 = $self->class_entropy_for_greater_than_threshold_for_feature(
                                    \@features_and_values_or_thresholds_on_branch, $feature_name, $value);
                my $partitioning_entropy = $entropy1 * 
                     $self->probability_of_a_sequence_of_features_and_values_or_thresholds(\@for_left_child) +
                                           $entropy2 *
                     $self->probability_of_a_sequence_of_features_and_values_or_thresholds(\@for_right_child);

                push @partitioning_entropies, $partitioning_entropy;
                $partitioning_point_child_entropies_hash{$feature_name}{$value} = [$entropy1, $entropy2];
            }
            my ($min_entropy, $best_partition_point_index) = minimum(\@partitioning_entropies);
            if ($min_entropy < $existing_node_entropy) {
                $partitioning_point_threshold{$feature_name} = $newvalues[$best_partition_point_index];
                $entropy_values_for_different_features{$feature_name} = $min_entropy;
            }
        } else {
            print "\nBFC2:  Entering section reserved for symbolic features\n" if $self->{_debug3};
            print "\nBFC3 Feature name: $feature_name\n" if $self->{_debug3};
            my %seen;
            my @values = grep {$_ ne 'NA' && !$seen{$_}++} 
                                    @{$self->{_features_and_unique_values_hash}->{$feature_name}};
            @values = sort @values;
            print "\nBFC4 values for feature $feature_name are @values\n" if $self->{_debug3};

            my $entropy = 0;
            foreach my $value (@values) {
                my $feature_value_string = "$feature_name" . '=' . "$value";
                print "\nBFC4 feature_value_string: $feature_value_string\n" if $self->{_debug3};
                my @extended_attributes = @{deep_copy_array(\@features_and_values_or_thresholds_on_branch)};
                if (@features_and_values_or_thresholds_on_branch) {
                    push @extended_attributes, $feature_value_string;
                } else {
                    @extended_attributes = ($feature_value_string);
                }
                $entropy += 
           $self->class_entropy_for_a_given_sequence_of_features_and_values_or_thresholds(\@extended_attributes) * 
           $self->probability_of_a_sequence_of_features_and_values_or_thresholds(\@extended_attributes);
                print "\nBFC5 Entropy calculated for symbolic feature value choice ($feature_name,$value) " .
                      "is $entropy\n" if $self->{_debug3};
                push @{$entropies_for_different_values_of_symbolic_feature{$feature_name}}, $entropy;
            }
            if ($entropy < $existing_node_entropy) {
                $entropy_values_for_different_features{$feature_name} = $entropy;
            }
        }
    }
    my $min_entropy_for_best_feature;
    my $best_feature_name;
    foreach my $feature_nom (keys %entropy_values_for_different_features) { 
        if (!defined($best_feature_name)) {
            $best_feature_name = $feature_nom;
            $min_entropy_for_best_feature = $entropy_values_for_different_features{$feature_nom};
        } else {
            if ($entropy_values_for_different_features{$feature_nom} < $min_entropy_for_best_feature) {
                $best_feature_name = $feature_nom;
                $min_entropy_for_best_feature = $entropy_values_for_different_features{$feature_nom};
            }
        }
    }
    my $threshold_for_best_feature;
    if (exists $partitioning_point_threshold{$best_feature_name}) {
        $threshold_for_best_feature = $partitioning_point_threshold{$best_feature_name};
    } else {
        $threshold_for_best_feature = undef;
    }
    my $best_feature_entropy = $min_entropy_for_best_feature;
    my @val_based_entropies_to_be_returned;
    my $decision_val_to_be_returned;
    if (exists $self->{_numeric_features_valuerange_hash}->{$best_feature_name} && 
          $self->{_feature_values_how_many_uniques_hash}->{$best_feature_name} > 
                                    $self->{_symbolic_to_numeric_cardinality_threshold}) {
        @val_based_entropies_to_be_returned = 
            @{$partitioning_point_child_entropies_hash{$best_feature_name}{$threshold_for_best_feature}};
    } else {
        @val_based_entropies_to_be_returned = ();
    }
    if (exists $partitioning_point_threshold{$best_feature_name}) {
        $decision_val_to_be_returned = $partitioning_point_threshold{$best_feature_name};
    } else {
        $decision_val_to_be_returned = undef;
    }
    print "\nBFC6 Val based entropies to be returned for feature $best_feature_name are " .
        "@val_based_entropies_to_be_returned\n"  if $self->{_debug3};
    return ($best_feature_name, $best_feature_entropy, \@val_based_entropies_to_be_returned, 
                                                                      $decision_val_to_be_returned);
}

#########################################    Entropy Calculators     #####################################

sub class_entropy_on_priors {
    my $self = shift;
    return $self->{_entropy_cache}->{'priors'} 
        if exists $self->{_entropy_cache}->{"priors"};
    my @class_names = @{$self->{_class_names}};
    my $entropy;
    foreach my $class (@class_names) {
        my $prob = $self->prior_probability_for_class($class);
        my $log_prob = log($prob) / log(2) if ($prob >= 0.0001) && ($prob <= 0.999) ;
        $log_prob = 0 if $prob < 0.0001;           # since X.log(X)->0 as X->0
        $log_prob = 0 if $prob > 0.999;            # since log(1) = 0
        if (!defined $entropy) {
            $entropy = -1.0 * $prob * $log_prob; 
            next;
        }
        $entropy += -1.0 * $prob * $log_prob;
    }
    $self->{_entropy_cache}->{'priors'} = $entropy;
    return $entropy;
}

sub entropy_scanner_for_a_numeric_feature {
    local $| = 1;
    my $self = shift;
    my $feature = shift;
    my @all_sampling_points = @{$self->{_sampling_points_for_numeric_feature_hash}->{$feature}};
    my @entropies_for_less_than_thresholds = ();
    my @entropies_for_greater_than_thresholds = ();
    foreach my $point (@all_sampling_points) {
        print ". ";
        push @entropies_for_less_than_thresholds, 
                         $self->class_entropy_for_less_than_threshold_for_feature([], $feature, $point);
        push @entropies_for_greater_than_thresholds,
                      $self->class_entropy_for_greater_than_threshold_for_feature([], $feature, $point);
    }
    print "\n\nSCANNER: All entropies less than thresholds for feature $feature are: ". 
                                                                "@entropies_for_less_than_thresholds\n";
    print "\nSCANNER: All entropies greater than thresholds for feature $feature are: ". 
                                                             "@entropies_for_greater_than_thresholds\n";
}   

sub class_entropy_for_less_than_threshold_for_feature {
    my $self = shift;
    my $arr = shift;
    my $feature = shift;
    my $threshold = shift;
    my @array_of_features_and_values_or_thresholds = @$arr;
    my $feature_threshold_combo = "$feature" . '<' . "$threshold";
    my $sequence = join ":", @array_of_features_and_values_or_thresholds;
    $sequence .= ":" . $feature_threshold_combo;
    return $self->{_entropy_cache}->{$sequence}  if exists $self->{_entropy_cache}->{$sequence};
    my @copy_of_array_of_features_and_values_or_thresholds = 
                                       @{deep_copy_array(\@array_of_features_and_values_or_thresholds)};
    push @copy_of_array_of_features_and_values_or_thresholds, $feature_threshold_combo;
    my $entropy = 0;
    foreach my $class_name (@{$self->{_class_names}}) {
        my $log_prob = undef;
        my $prob = $self->probability_of_a_class_given_sequence_of_features_and_values_or_thresholds(
                                   $class_name, \@copy_of_array_of_features_and_values_or_thresholds);
        if ($prob >= 0.0001 && $prob <= 0.999) {
            $log_prob = log($prob) / log(2.0);
        } elsif ($prob < 0.0001) {
            $log_prob = 0;
        } elsif ($prob > 0.999) {
            $log_prob = 0;
        } else {
            die "An error has occurred in log_prob calculation";
        }
        $entropy +=  -1.0 * $prob * $log_prob;
    }
    if (abs($entropy) < 0.0000001) {
        $entropy = 0.0;
    }
    $self->{_entropy_cache}->{$sequence} = $entropy;
    return $entropy;
}

sub class_entropy_for_greater_than_threshold_for_feature {
    my $self = shift;
    my $arr = shift;
    my $feature = shift;
    my $threshold = shift;
    my @array_of_features_and_values_or_thresholds = @$arr;
    my $feature_threshold_combo = "$feature" . '>' . "$threshold";
    my $sequence = join ":", @array_of_features_and_values_or_thresholds;
    $sequence .= ":" . $feature_threshold_combo;
    return $self->{_entropy_cache}->{$sequence}  if exists $self->{_entropy_cache}->{$sequence};
    my @copy_of_array_of_features_and_values_or_thresholds = 
                                       @{deep_copy_array(\@array_of_features_and_values_or_thresholds)};
    push @copy_of_array_of_features_and_values_or_thresholds, $feature_threshold_combo;
    my $entropy = 0;
    foreach my $class_name (@{$self->{_class_names}}) {
        my $log_prob = undef;
        my $prob = $self->probability_of_a_class_given_sequence_of_features_and_values_or_thresholds(
                                   $class_name, \@copy_of_array_of_features_and_values_or_thresholds);
        if ($prob >= 0.0001 && $prob <= 0.999) {
            $log_prob = log($prob) / log(2.0);
        } elsif ($prob < 0.0001) {
            $log_prob = 0;
        } elsif ($prob > 0.999) {
            $log_prob = 0;
        } else {
            die "An error has occurred in log_prob calculation";
        }
        $entropy +=  -1.0 * $prob * $log_prob;
    }
    if (abs($entropy) < 0.0000001) {
        $entropy = 0.0;
    }
    $self->{_entropy_cache}->{$sequence} = $entropy;
    return $entropy;
}

sub class_entropy_for_a_given_sequence_of_features_and_values_or_thresholds {
    my $self = shift;
    my $array_of_features_and_values_or_thresholds = shift;
    my @array_of_features_and_values_or_thresholds = @$array_of_features_and_values_or_thresholds;
    my $sequence = join ":", @array_of_features_and_values_or_thresholds;
    return $self->{_entropy_cache}->{$sequence}  if exists $self->{_entropy_cache}->{$sequence};
    my $entropy = 0;
    foreach my $class_name (@{$self->{_class_names}}) {
        my $log_prob = undef;
        my $prob = $self->probability_of_a_class_given_sequence_of_features_and_values_or_thresholds(
                                             $class_name, \@array_of_features_and_values_or_thresholds);
        if ($prob >= 0.0001 && $prob <= 0.999) {
            $log_prob = log($prob) / log(2.0);
        } elsif ($prob < 0.0001) {
            $log_prob = 0;
        } elsif ($prob > 0.999) {
            $log_prob = 0;
        } else {
            die "An error has occurred in log_prob calculation";
        }
        $entropy +=  -1.0 * $prob * $log_prob;
    }
    if (abs($entropy) < 0.0000001) {
        $entropy = 0.0;
    }
    $self->{_entropy_cache}->{$sequence} = $entropy;
    return $entropy;
}


#####################################   Probability Calculators   ########################################

sub prior_probability_for_class {
    my $self = shift;
    my $class = shift;
    my $class_name_in_cache = "prior" . '::' . $class;
    return $self->{_probability_cache}->{$class_name_in_cache}
        if exists $self->{_probability_cache}->{$class_name_in_cache};
    my $total_num_of_samples = keys %{$self->{_samples_class_label_hash}};
    my @values = values %{$self->{_samples_class_label_hash}};
    foreach my $class_name (@{$self->{_class_names}}) {
        my @trues = grep {$_ eq $class_name} @values;
        my $prior_for_this_class = (1.0 * @trues) / $total_num_of_samples; 
        my $this_class_name_in_cache = "prior" . '::' . $class_name;
        $self->{_probability_cache}->{$this_class_name_in_cache} = $prior_for_this_class;
    }
    return $self->{_probability_cache}->{$class_name_in_cache};
}

sub calculate_class_priors {
    my $self = shift;
    return if scalar keys %{$self->{_class_priors_hash}} > 1;
    foreach my $class_name (@{$self->{_class_names}}) {
        my $class_name_in_cache = "prior::$class_name";
        my $total_num_of_samples = scalar keys %{$self->{_samples_class_label_hash}};
        my @all_values = values %{$self->{_samples_class_label_hash}};
        my @trues_for_this_class = grep {$_ eq $class_name} @all_values;
        my $prior_for_this_class = (1.0 * (scalar @trues_for_this_class)) / $total_num_of_samples;
        $self->{_class_priors_hash}->{$class_name} = $prior_for_this_class;
        my $this_class_name_in_cache = "prior::$class_name";
        $self->{_probability_cache}->{$this_class_name_in_cache} = $prior_for_this_class;
    }
    if ($self->{_debug1}) {
        foreach my $class (sort keys %{$self->{_class_priors_hash}}) {
            print "$class  =>  $self->{_class_priors_hash}->{$class}\n";
        }
    }
}

sub calculate_first_order_probabilities {
    print "\nEstimating probabilities...\n";
    my $self = shift;
    foreach my $feature (@{$self->{_feature_names}}) {
        $self->probability_of_feature_value($feature, undef);   
        if ($self->{_debug2}) {
            if (exists $self->{_prob_distribution_numeric_features_hash}->{$feature}) {
                print "\nPresenting probability distribution for a numeric feature:\n";
                foreach my $sampling_point (sort {$a <=> $b} keys 
                                   %{$self->{_prob_distribution_numeric_features_hash}->{$feature}}) {
                    my $sampling_pt_for_display = sprintf("%.2f", $sampling_point);
                    print "$feature :: $sampling_pt_for_display=" . sprintf("%.5f", 
                          $self->{_prob_distribution_numeric_features_hash}->{$feature}{$sampling_point}) . "\n";
                }
            } else {
                print "\nPresenting probabilities for the values of a feature considered to be symbolic:\n";
                my @values_for_feature = @{$self->{_features_and_unique_values_hash}->{$feature}};
                foreach my $value (sort @values_for_feature) {
                    my $prob = $self->probability_of_feature_value($feature,$value); 
                    print "$feature :: $value = " . sprintf("%.5f", $prob) . "\n";
                }
            }
        }
    }
}

sub probability_of_feature_value {
    my $self = shift;
    my $feature_name = shift;
    my $value = shift;
    $value = sprintf("%.1f", $value) if defined($value) && $value =~ /^\d+$/;
    if (defined($value) && exists($self->{_sampling_points_for_numeric_feature_hash}->{$feature_name})) {
        $value = closest_sampling_point($value, 
                                        $self->{_sampling_points_for_numeric_feature_hash}->{$feature_name});
    }
    my $feature_and_value;
    if (defined($value)) {
        $feature_and_value = "$feature_name=$value";
    }
    if (defined($value) && exists($self->{_probability_cache}->{$feature_and_value})) {
        return $self->{_probability_cache}->{$feature_and_value};
    }
    my ($histogram_delta, $num_of_histogram_bins, @valuerange, $diffrange) = (undef,undef,undef,undef);
    if (exists $self->{_numeric_features_valuerange_hash}->{$feature_name}) {
        if ($self->{_feature_values_how_many_uniques_hash}->{$feature_name} > 
                                $self->{_symbolic_to_numeric_cardinality_threshold}) {
            if (! exists $self->{_sampling_points_for_numeric_feature_hash}->{$feature_name}) {
                @valuerange = @{$self->{_numeric_features_valuerange_hash}->{$feature_name}}; 
                $diffrange = $valuerange[1] - $valuerange[0];
                my %seen = ();
                my @unique_values_for_feature =  sort {$a <=> $b}  grep {$_ if $_ ne 'NA' && !$seen{$_}++} 
                                         @{$self->{_features_and_values_hash}->{$feature_name}};
                my @diffs = sort {$a <=> $b} map {$unique_values_for_feature[$_] - 
                                    $unique_values_for_feature[$_-1]}  1..@unique_values_for_feature-1;
                my $median_diff = $diffs[int(@diffs/2) - 1];
                $histogram_delta =  $median_diff * 2;
                if ($histogram_delta < $diffrange / 500.0) {
                    if (defined $self->{_number_of_histogram_bins}) {
                        $histogram_delta = $diffrange / $self->{_number_of_histogram_bins};
                    } else {
                        $histogram_delta = $diffrange / 500.0;
                    }
                }
                $self->{_histogram_delta_hash}->{$feature_name} = $histogram_delta;
                $num_of_histogram_bins = int($diffrange / $histogram_delta) + 1;
                $self->{_num_of_histogram_bins_hash}->{$feature_name} = $num_of_histogram_bins;
                my @sampling_points_for_feature = map {$valuerange[0] + $histogram_delta * $_} 
                                                                    0..$num_of_histogram_bins-1;
                $self->{_sampling_points_for_numeric_feature_hash}->{$feature_name} = 
                                                                           \@sampling_points_for_feature;
            }
        }
    }
    if (exists $self->{_numeric_features_valuerange_hash}->{$feature_name}) {
        if ($self->{_feature_values_how_many_uniques_hash}->{$feature_name} > 
                                   $self->{_symbolic_to_numeric_cardinality_threshold}) {
            my @sampling_points_for_feature = 
                               @{$self->{_sampling_points_for_numeric_feature_hash}->{$feature_name}};
            my @counts_at_sampling_points = (0) x @sampling_points_for_feature;
            my @actual_values_for_feature = grep {$_ ne 'NA'} 
                                              @{$self->{_features_and_values_hash}->{$feature_name}};
            foreach my $i (0..@sampling_points_for_feature-1) {
                foreach my $j (0..@actual_values_for_feature-1) {
                    if (abs($sampling_points_for_feature[$i]-$actual_values_for_feature[$j]) < $histogram_delta) {
                        $counts_at_sampling_points[$i]++
                    }
                }
            }
            my $total_counts = 0;
            map {$total_counts += $_} @counts_at_sampling_points;
            my @probs = map {$_ / (1.0 * $total_counts)} @counts_at_sampling_points;
            my %bin_prob_hash = ();
            foreach my $i (0..@sampling_points_for_feature-1) {
                $bin_prob_hash{$sampling_points_for_feature[$i]} = $probs[$i];
            }
            $self->{_prob_distribution_numeric_features_hash}->{$feature_name} = \%bin_prob_hash;
            my @values_for_feature = map "$feature_name=$_", map {sprintf("%.5f", $_)} 
                                                                             @sampling_points_for_feature;
            foreach my $i (0..@values_for_feature-1) {
                $self->{_probability_cache}->{$values_for_feature[$i]} = $probs[$i];
            }
            if (defined($value) && exists $self->{_probability_cache}->{$feature_and_value}) {
                return $self->{_probability_cache}->{$feature_and_value};
            } else {
                return 0;
            }
        } else {
            my %seen = ();
            my @values_for_feature = grep {$_ if $_ ne 'NA' && !$seen{$_}++} 
                                                 @{$self->{_features_and_values_hash}->{$feature_name}};
            @values_for_feature = map {"$feature_name=$_"} @values_for_feature;
            my @value_counts = (0) x @values_for_feature;
#            foreach my $sample (sort {sample_index($a) cmp sample_index($b)}keys %{$self->{_training_data_hash}}){
            foreach my $sample (sort {sample_index($a) <=> sample_index($b)}keys %{$self->{_training_data_hash}}){
                my @features_and_values = @{$self->{_training_data_hash}->{$sample}};
                foreach my $i (0..@values_for_feature-1) {
                    foreach my $current_value (@features_and_values) {
                        $value_counts[$i]++ if $values_for_feature[$i] eq $current_value;
                    }
                }
            }
            my $total_counts = 0;
            map {$total_counts += $_} @value_counts;
            die "PFV Something is wrong with your training file. It contains no training samples \
                         for feature named $feature_name" if $total_counts == 0;
            my @probs = map {$_ / (1.0 * $total_counts)} @value_counts;
            foreach my $i (0..@values_for_feature-1) {
                $self->{_probability_cache}->{$values_for_feature[$i]} = $probs[$i];
            }
            if (defined($value) && exists $self->{_probability_cache}->{$feature_and_value}) {
                return $self->{_probability_cache}->{$feature_and_value};
            } else {
                return 0;
            }
        }
    } else {
        # This section is only for purely symbolic features:  
        my @values_for_feature = @{$self->{_features_and_values_hash}->{$feature_name}};        
        @values_for_feature = map {"$feature_name=$_"} @values_for_feature;
        my @value_counts = (0) x @values_for_feature;
#        foreach my $sample (sort {sample_index($a) cmp sample_index($b)} keys %{$self->{_training_data_hash}}) {
        foreach my $sample (sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_training_data_hash}}) {
            my @features_and_values = @{$self->{_training_data_hash}->{$sample}};
            foreach my $i (0..@values_for_feature-1) {
                for my $current_value (@features_and_values) {
                    $value_counts[$i]++ if $values_for_feature[$i] eq $current_value;
                }
            }
        }
        foreach my $i (0..@values_for_feature-1) {
            $self->{_probability_cache}->{$values_for_feature[$i]} = 
                $value_counts[$i] / (1.0 * scalar(keys %{$self->{_training_data_hash}}));
        }
        if (defined($value) && exists $self->{_probability_cache}->{$feature_and_value}) {
            return $self->{_probability_cache}->{$feature_and_value};
        } else {
            return 0;
        }
    }
}

sub probability_of_feature_value_given_class {
    my $self = shift;
    my $feature_name = shift;
    my $feature_value = shift;
    my $class_name = shift;
    $feature_value = sprintf("%.1f", $feature_value) if defined($feature_value) && $feature_value =~ /^\d+$/;
    if (defined($feature_value) && exists($self->{_sampling_points_for_numeric_feature_hash}->{$feature_name})) {
        $feature_value = closest_sampling_point($feature_value, 
                                        $self->{_sampling_points_for_numeric_feature_hash}->{$feature_name});
    }
    my $feature_value_class;
    if (defined($feature_value)) {
        $feature_value_class = "$feature_name=$feature_value" . "::" . "$class_name";
    }
    if (defined($feature_value) && exists($self->{_probability_cache}->{$feature_value_class})) {
        print "\nNext answer returned by cache for feature $feature_name and " .
            "value $feature_value given class $class_name\n" if $self->{_debug2};
        return $self->{_probability_cache}->{$feature_value_class};
    }
    my ($histogram_delta, $num_of_histogram_bins, @valuerange, $diffrange) = (undef,undef,undef,undef);

    if (exists $self->{_numeric_features_valuerange_hash}->{$feature_name}) {
        if ($self->{_feature_values_how_many_uniques_hash}->{$feature_name} > 
                                $self->{_symbolic_to_numeric_cardinality_threshold}) {
            $histogram_delta = $self->{_histogram_delta_hash}->{$feature_name};
            $num_of_histogram_bins = $self->{_num_of_histogram_bins_hash}->{$feature_name};
            @valuerange = @{$self->{_numeric_features_valuerange_hash}->{$feature_name}};
            $diffrange = $valuerange[1] - $valuerange[0];
        }
    }
    my @samples_for_class = ();
    # Accumulate all samples names for the given class:
    foreach my $sample_name (keys %{$self->{_samples_class_label_hash}}) {
        if ($self->{_samples_class_label_hash}->{$sample_name} eq $class_name) {
            push @samples_for_class, $sample_name;
        }
    }
    if (exists($self->{_numeric_features_valuerange_hash}->{$feature_name})) {
        if ($self->{_feature_values_how_many_uniques_hash}->{$feature_name} > 
                                $self->{_symbolic_to_numeric_cardinality_threshold}) {
            my @sampling_points_for_feature = 
                              @{$self->{_sampling_points_for_numeric_feature_hash}->{$feature_name}};
            my @counts_at_sampling_points = (0) x @sampling_points_for_feature;
            my @actual_feature_values_for_samples_in_class = ();
            foreach my $sample (@samples_for_class) {           
                foreach my $feature_and_value (@{$self->{_training_data_hash}->{$sample}}) {
                    my $pattern = '(.+)=(.+)';
                    $feature_and_value =~ /$pattern/;
                    my ($feature, $value) = ($1, $2);
                    if (($feature eq $feature_name) && ($value ne 'NA')) {
                        push @actual_feature_values_for_samples_in_class, $value;
                    }
                }
            }
            foreach my $i (0..@sampling_points_for_feature-1) {
                foreach my $j (0..@actual_feature_values_for_samples_in_class-1) {
                    if (abs($sampling_points_for_feature[$i] - 
                            $actual_feature_values_for_samples_in_class[$j]) < $histogram_delta) {
                        $counts_at_sampling_points[$i]++;
                    }
                }
            }
            my $total_counts = 0;
            map {$total_counts += $_} @counts_at_sampling_points;
            die "PFVC1 Something is wrong with your training file. It contains no training " .
                    "samples for Class $class_name and Feature $feature_name" if $total_counts == 0;
            my @probs = map {$_ / (1.0 * $total_counts)} @counts_at_sampling_points;
            my @values_for_feature_and_class = map {"$feature_name=$_" . "::" . "$class_name"} 
                                                                     @sampling_points_for_feature;
            foreach my $i (0..@values_for_feature_and_class-1) {
                $self->{_probability_cache}->{$values_for_feature_and_class[$i]} = $probs[$i];
            }
            if (exists $self->{_probability_cache}->{$feature_value_class}) {
                return $self->{_probability_cache}->{$feature_value_class};
            } else {
                return 0;
            }
        } else {
            # This section is for numeric features that will be treated symbolically
            my %seen = ();
            my @values_for_feature = grep {$_ if $_ ne 'NA' && !$seen{$_}++} 
                                                 @{$self->{_features_and_values_hash}->{$feature_name}};
            @values_for_feature = map {"$feature_name=$_"} @values_for_feature;
            my @value_counts = (0) x @values_for_feature;
            foreach my $sample (@samples_for_class) {
                my @features_and_values = @{$self->{_training_data_hash}->{$sample}};
                foreach my $i (0..@values_for_feature-1) {
                    foreach my $current_value (@features_and_values) {
                        $value_counts[$i]++ if $values_for_feature[$i] eq $current_value;
                    }
                }
            }
            my $total_counts = 0;
            map {$total_counts += $_} @value_counts;
            die "PFVC2 Something is wrong with your training file. It contains no training " .
                "samples for Class $class_name and Feature $feature_name" if $total_counts == 0;
            # We normalize by total_count because the probabilities are conditioned on a given class
            foreach my $i (0..@values_for_feature-1) {
                my $feature_and_value_and_class =  "$values_for_feature[$i]" . "::" . "$class_name";
                $self->{_probability_cache}->{$feature_and_value_and_class} = 
                                                           $value_counts[$i] / (1.0 * $total_counts);
            }
            if (exists $self->{_probability_cache}->{$feature_value_class}) {
                return $self->{_probability_cache}->{$feature_value_class};
            } else {
                return 0;
            }
        }
    } else {
        # This section is for purely symbolic features
        my @values_for_feature = @{$self->{_features_and_values_hash}->{$feature_name}};
        my %seen = ();
        @values_for_feature = grep {$_ if $_ ne 'NA' && !$seen{$_}++} 
                                             @{$self->{_features_and_values_hash}->{$feature_name}};
        @values_for_feature = map {"$feature_name=$_"} @values_for_feature;
        my @value_counts = (0) x @values_for_feature;
        foreach my $sample (@samples_for_class) {
            my @features_and_values = @{$self->{_training_data_hash}->{$sample}};
            foreach my $i (0..@values_for_feature-1) {
                foreach my $current_value (@features_and_values) {
                    $value_counts[$i]++ if $values_for_feature[$i] eq $current_value;
                }
            }
        }
        my $total_counts = 0;
        map {$total_counts += $_} @value_counts;
        die "PFVC2 Something is wrong with your training file. It contains no training " .
            "samples for Class $class_name and Feature $feature_name" if $total_counts == 0;
        # We normalize by total_count because the probabilities are conditioned on a given class
        foreach my $i (0..@values_for_feature-1) {
            my $feature_and_value_and_class =  "$values_for_feature[$i]" . "::" . "$class_name";
            $self->{_probability_cache}->{$feature_and_value_and_class} = 
                                                       $value_counts[$i] / (1.0 * $total_counts);
        }
        if (exists $self->{_probability_cache}->{$feature_value_class}) {
            return $self->{_probability_cache}->{$feature_value_class};
        } else {
            return 0;
        }
    }
}

sub probability_of_feature_less_than_threshold {
    my $self = shift;
    my $feature_name = shift;
    my $threshold = shift;
    my $feature_threshold_combo = "$feature_name" . '<' . "$threshold";
    return $self->{_probability_cache}->{$feature_threshold_combo}
                     if (exists $self->{_probability_cache}->{$feature_threshold_combo});
    my @all_values = grep {$_ if $_ ne 'NA'} @{$self->{_features_and_values_hash}->{$feature_name}};
    my @all_values_less_than_threshold = grep {$_ if $_ <= $threshold} @all_values;
    my $probability = (1.0 * @all_values_less_than_threshold) / @all_values;
    $self->{_probability_cache}->{$feature_threshold_combo} = $probability;
    return $probability;
}

sub probability_of_feature_less_than_threshold_given_class {
    my $self = shift;
    my $feature_name = shift;
    my $threshold = shift;
    my $class_name = shift;
    my $feature_threshold_class_combo = "$feature_name" . "<" . "$threshold" . "::" . "$class_name";
    return $self->{_probability_cache}->{$feature_threshold_class_combo}
                     if (exists $self->{_probability_cache}->{$feature_threshold_class_combo});
    my @data_samples_for_class = ();
    # Accumulate all samples names for the given class:
    foreach my $sample_name (keys %{$self->{_samples_class_label_hash}}) {
        push @data_samples_for_class, $sample_name 
                  if $self->{_samples_class_label_hash}->{$sample_name} eq $class_name;
    }
    my @actual_feature_values_for_samples_in_class = ();
    foreach my $sample (@data_samples_for_class) {
        foreach my $feature_and_value (@{$self->{_training_data_hash}->{$sample}}) {
            my $pattern = '(.+)=(.+)';
            $feature_and_value =~ /$pattern/;
            my ($feature,$value) = ($1,$2);
            push @actual_feature_values_for_samples_in_class, $value
                                    if $feature eq $feature_name && $value ne 'NA';
        }
    }
    my @actual_points_for_feature_less_than_threshold = grep {$_ if $_ <= $threshold} @actual_feature_values_for_samples_in_class;
    # The condition in the assignment that follows was a bug correction in Version 3.20
    my $probability = @actual_feature_values_for_samples_in_class > 0 ? ((1.0 * @actual_points_for_feature_less_than_threshold) / @actual_feature_values_for_samples_in_class) : 0.0;
    $self->{_probability_cache}->{$feature_threshold_class_combo} = $probability;
    return $probability;
}

# This method requires that all truly numeric types only be expressed as '<' or '>'
# constructs in the array of branch features and thresholds
sub probability_of_a_sequence_of_features_and_values_or_thresholds {
    my $self = shift;
    my $arr = shift;
    my @array_of_features_and_values_or_thresholds = @$arr;
    return if scalar @array_of_features_and_values_or_thresholds == 0;
    my $sequence = join ':', @array_of_features_and_values_or_thresholds;
    return $self->{_probability_cache}->{$sequence} if exists $self->{_probability_cache}->{$sequence};
    my $probability = undef;
    my $pattern1 = '(.+)=(.+)';
    my $pattern2 = '(.+)<(.+)';
    my $pattern3 = '(.+)>(.+)';
    my @true_numeric_types = ();
    my @true_numeric_types_feature_names = ();
    my @symbolic_types = ();
    my @symbolic_types_feature_names = ();
    foreach my $item (@array_of_features_and_values_or_thresholds) {
        if ($item =~ /$pattern2/) {
            push @true_numeric_types, $item;
            my ($feature,$value) = ($1,$2);
            push @true_numeric_types_feature_names, $feature;
        } elsif ($item =~ /$pattern3/) {
            push @true_numeric_types, $item;
            my ($feature,$value) = ($1,$2);
            push @true_numeric_types_feature_names, $feature;
        } else {
            push @symbolic_types, $item;
            $item =~ /$pattern1/;
            my ($feature,$value) = ($1,$2);
            push @symbolic_types_feature_names, $feature;
        }
    }
    my %seen1 = ();
    @true_numeric_types_feature_names = grep {$_ if !$seen1{$_}++} @true_numeric_types_feature_names;
    my %seen2 = ();
    @symbolic_types_feature_names = grep {$_ if !$seen2{$_}++} @symbolic_types_feature_names;
    my $bounded_intervals_numeric_types = $self->find_bounded_intervals_for_numeric_features(\@true_numeric_types);
    print_array_with_msg("POS: Answer returned by find_bounded: ", 
                                       $bounded_intervals_numeric_types) if $self->{_debug2};
    # Calculate the upper and the lower bounds to be used when searching for the best
    # threshold for each of the numeric features that are in play at the current node:
    my (%upperbound, %lowerbound);
    foreach my $feature_name (@true_numeric_types_feature_names) {
        $upperbound{$feature_name} = undef;
        $lowerbound{$feature_name} = undef;
    }
    foreach my $item (@$bounded_intervals_numeric_types) {
        foreach my $feature_grouping (@$item) {
            if ($feature_grouping->[1] eq '>') {
                $lowerbound{$feature_grouping->[0]} = $feature_grouping->[2];
            } else {
                $upperbound{$feature_grouping->[0]} = $feature_grouping->[2];
            }
        }
    }
    foreach my $feature_name (@true_numeric_types_feature_names) {
        if (defined($lowerbound{$feature_name}) && defined($upperbound{$feature_name}) && 
                          $upperbound{$feature_name} <= $lowerbound{$feature_name}) { 
            return 0;
        } elsif (defined($lowerbound{$feature_name}) && defined($upperbound{$feature_name})) {
            if (! $probability) {
                $probability = $self->probability_of_feature_less_than_threshold($feature_name, 
                                                                                 $upperbound{$feature_name}) -
                   $self->probability_of_feature_less_than_threshold($feature_name, $lowerbound{$feature_name});
            } else {
                $probability *= ($self->probability_of_feature_less_than_threshold($feature_name, 
                                                                                   $upperbound{$feature_name}) -
                 $self->probability_of_feature_less_than_threshold($feature_name, $lowerbound{$feature_name}))
            }
        } elsif (defined($upperbound{$feature_name}) && ! defined($lowerbound{$feature_name})) {
            if (! $probability) {
                $probability = $self->probability_of_feature_less_than_threshold($feature_name,
                                                                                 $upperbound{$feature_name});
            } else {
                $probability *= $self->probability_of_feature_less_than_threshold($feature_name, 
                                                                                  $upperbound{$feature_name});
            }
        } elsif (defined($lowerbound{$feature_name}) && ! defined($upperbound{$feature_name})) {
            if (! $probability) {
                $probability = 1.0 - $self->probability_of_feature_less_than_threshold($feature_name,
                                                                                 $lowerbound{$feature_name});
            } else {
                $probability *= (1.0 - $self->probability_of_feature_less_than_threshold($feature_name, 
                                                                                $lowerbound{$feature_name}));
            }
        } else {
            die("Ill formatted call to 'probability_of_sequence' method");
        }
    }
    foreach my $feature_and_value (@symbolic_types) {
        if ($feature_and_value =~ /$pattern1/) {
            my ($feature,$value) = ($1,$2);
            if (! $probability) {        
                $probability = $self->probability_of_feature_value($feature, $value);
            } else {
                $probability *= $self->probability_of_feature_value($feature, $value);
            }
        }
    }
    $self->{_probability_cache}->{$sequence} = $probability;
    return $probability;
}

##  The following method requires that all truly numeric types only be expressed as
##  '<' or '>' constructs in the array of branch features and thresholds
sub probability_of_a_sequence_of_features_and_values_or_thresholds_given_class {
    my $self = shift;
    my $arr = shift;
    my $class_name = shift;
    my @array_of_features_and_values_or_thresholds = @$arr;
    return if scalar @array_of_features_and_values_or_thresholds == 0;
    my $sequence = join ':', @array_of_features_and_values_or_thresholds;
    my $sequence_with_class = "$sequence" . "::" . $class_name;
    return $self->{_probability_cache}->{$sequence_with_class} 
                      if exists $self->{_probability_cache}->{$sequence_with_class};
    my $probability = undef;
    my $pattern1 = '(.+)=(.+)';
    my $pattern2 = '(.+)<(.+)';
    my $pattern3 = '(.+)>(.+)';
    my @true_numeric_types = ();
    my @true_numeric_types_feature_names = ();
    my @symbolic_types = ();
    my @symbolic_types_feature_names = ();
    foreach my $item (@array_of_features_and_values_or_thresholds) {
        if ($item =~ /$pattern2/) {
            push @true_numeric_types, $item;
            my ($feature,$value) = ($1,$2);
            push @true_numeric_types_feature_names, $feature;
        } elsif ($item =~ /$pattern3/) {
            push @true_numeric_types, $item;
            my ($feature,$value) = ($1,$2);
            push @true_numeric_types_feature_names, $feature;
        } else {
            push @symbolic_types, $item;
            $item =~ /$pattern1/;
            my ($feature,$value) = ($1,$2);
            push @symbolic_types_feature_names, $feature;
        }
    }
    my %seen1 = ();
    @true_numeric_types_feature_names = grep {$_ if !$seen1{$_}++} @true_numeric_types_feature_names;
    my %seen2 = ();
    @symbolic_types_feature_names = grep {$_ if !$seen2{$_}++} @symbolic_types_feature_names;
    my $bounded_intervals_numeric_types = $self->find_bounded_intervals_for_numeric_features(\@true_numeric_types);
    print_array_with_msg("POSC: Answer returned by find_bounded: ", 
                                       $bounded_intervals_numeric_types) if $self->{_debug2};
    # Calculate the upper and the lower bounds to be used when searching for the best
    # threshold for each of the numeric features that are in play at the current node:
    my (%upperbound, %lowerbound);
    foreach my $feature_name (@true_numeric_types_feature_names) {
        $upperbound{$feature_name} = undef;
        $lowerbound{$feature_name} = undef;
    }
    foreach my $item (@$bounded_intervals_numeric_types) {
        foreach my $feature_grouping (@$item) {
            if ($feature_grouping->[1] eq '>') {
                $lowerbound{$feature_grouping->[0]} = $feature_grouping->[2];
            } else {
                $upperbound{$feature_grouping->[0]} = $feature_grouping->[2];
            }
        }
    }
    foreach my $feature_name (@true_numeric_types_feature_names) {
        if ($lowerbound{$feature_name} && $upperbound{$feature_name} && 
                          $upperbound{$feature_name} <= $lowerbound{$feature_name}) { 
            return 0;
        } elsif (defined($lowerbound{$feature_name}) && defined($upperbound{$feature_name})) {
            if (! $probability) {

                $probability =   $self->probability_of_feature_less_than_threshold_given_class($feature_name, 
                                                               $upperbound{$feature_name}, $class_name) -
                                 $self->probability_of_feature_less_than_threshold_given_class($feature_name, 
                                                               $lowerbound{$feature_name}, $class_name);
            } else {
                $probability *= ($self->probability_of_feature_less_than_threshold_given_class($feature_name, 
                                                               $upperbound{$feature_name}, $class_name) -
                                 $self->probability_of_feature_less_than_threshold_given_class($feature_name, 
                                                               $lowerbound{$feature_name}, $class_name))
            }
        } elsif (defined($upperbound{$feature_name}) && ! defined($lowerbound{$feature_name})) {
            if (! $probability) {
                $probability =   $self->probability_of_feature_less_than_threshold_given_class($feature_name,
                                                               $upperbound{$feature_name}, $class_name);
            } else {
                $probability *=  $self->probability_of_feature_less_than_threshold_given_class($feature_name, 
                                                               $upperbound{$feature_name}, $class_name);
            }
        } elsif (defined($lowerbound{$feature_name}) && ! defined($upperbound{$feature_name})) {
            if (! $probability) {
                $probability =   1.0 - $self->probability_of_feature_less_than_threshold_given_class($feature_name,
                                                               $lowerbound{$feature_name}, $class_name);
            } else {
                $probability *= (1.0 - $self->probability_of_feature_less_than_threshold_given_class($feature_name,
                                                               $lowerbound{$feature_name}, $class_name));
            }
        } else {
            die("Ill formatted call to 'probability of sequence given class' method");
        }
    }
    foreach my $feature_and_value (@symbolic_types) {
        if ($feature_and_value =~ /$pattern1/) {
            my ($feature,$value) = ($1,$2);
            if (! $probability) {        
                $probability = $self->probability_of_feature_value_given_class($feature, $value, $class_name);
            } else {
                $probability *= $self->probability_of_feature_value_given_class($feature, $value, $class_name);
            }
        }
    }
    $self->{_probability_cache}->{$sequence_with_class} = $probability;
    return $probability;
}

sub probability_of_a_class_given_sequence_of_features_and_values_or_thresholds {
    my $self = shift;
    my $class_name = shift;    
    my $arr = shift;
    my @array_of_features_and_values_or_thresholds = @$arr;
    my $sequence = join ':', @array_of_features_and_values_or_thresholds;
    my $class_and_sequence = "$class_name" . "::" . $sequence;
    return $self->{_probability_cache}->{$class_and_sequence} 
                      if exists $self->{_probability_cache}->{$class_and_sequence};
    my @array_of_class_probabilities = (0) x scalar @{$self->{_class_names}};
    foreach my $i (0..@{$self->{_class_names}}-1) {
        my $class_name = $self->{_class_names}->[$i];
        my $prob = $self->probability_of_a_sequence_of_features_and_values_or_thresholds_given_class(
                                               \@array_of_features_and_values_or_thresholds, $class_name);
        if ($prob < 0.000001) {
            $array_of_class_probabilities[$i] = 0.0;
            next;
        }
        my $prob_of_feature_sequence = $self->probability_of_a_sequence_of_features_and_values_or_thresholds(
                                                            \@array_of_features_and_values_or_thresholds);
#        die "PCS Something is wrong with your sequence of feature values and thresholds in " .
#                "probability_of_a_class_given_sequence_of_features_and_values_or_thresholds()"
#                if ! $prob_of_feature_sequence;
        my $prior = $self->{_class_priors_hash}->{$self->{_class_names}->[$i]};
        if ($prob_of_feature_sequence) {
            $array_of_class_probabilities[$i] = $prob * $prior / $prob_of_feature_sequence;
        } else {
            $array_of_class_probabilities[$i] =  $prior;
        }
    }
    my $sum_probability;
    map {$sum_probability += $_} @array_of_class_probabilities;
    if ($sum_probability == 0) {
        @array_of_class_probabilities =  map {1.0 / (scalar @{$self->{_class_names}})}  
                                                               (0..@{$self->{_class_names}}-1);
    } else {
        @array_of_class_probabilities = map {$_ * 1.0 / $sum_probability} @array_of_class_probabilities;
    }
    foreach my $i (0..@{$self->{_class_names}}-1) {
        my $this_class_and_sequence = "$self->{_class_names}->[$i]" . "::" . "$sequence";
        $self->{_probability_cache}->{$this_class_and_sequence} = $array_of_class_probabilities[$i];
    }
    return $self->{_probability_cache}->{$class_and_sequence};
}

#######################################  Class Based Utilities  ##########################################

##  Given a list of branch attributes for the numeric features of the form, say,
##  ['g2<1','g2<2','g2<3','age>34','age>36','age>37'], this method returns the
##  smallest list that is relevant for the purpose of calculating the probabilities.
##  To explain, the probability that the feature `g2' is less than 1 AND, at the same
##  time, less than 2, AND, at the same time, less than 3, is the same as the
##  probability that the feature less than 1. Similarly, the probability that 'age'
##  is greater than 34 and also greater than 37 is the same as `age' being greater
##  than 37.
sub find_bounded_intervals_for_numeric_features {
    my $self = shift;
    my $arr = shift;    
    my @arr = @$arr;
    my @features = @{$self->{_feature_names}};
    my @arr1 = map {my @x = split /(>|<)/, $_; \@x} @arr;   
    print_array_with_msg("arr1", \@arr1) if $self->{_debug2};
    my @arr3 = ();
    foreach my $feature_name (@features) {
        my @temp = ();
        foreach my $x (@arr1) {
            push @temp, $x if @$x > 0 && $x->[0] eq $feature_name;
        }
        push @arr3, \@temp if @temp > 0;
    }
    print_array_with_msg("arr3", \@arr3) if $self->{_debug2};
    # Sort each list so that '<' entries occur before '>' entries:
    my @arr4;
    foreach my $li (@arr3) {
        my @sorted = sort {$a->[1] cmp $b->[1]} @$li;
        push @arr4, \@sorted;
    }
    print_array_with_msg("arr4", \@arr4) if $self->{_debug2};
    my @arr5;
    foreach my $li (@arr4) {
        my @temp1 = ();
        my @temp2 = ();
        foreach my $inner (@$li) {
            if ($inner->[1] eq '<') {
                push @temp1, $inner;
            } else {
                push @temp2, $inner;
            }
        }
        if (@temp1 > 0 && @temp2 > 0) {
            push @arr5, [\@temp1, \@temp2];
        } elsif (@temp1 > 0) {
            push @arr5, [\@temp1];
        } else {
            push @arr5, [\@temp2];
        }
    }
    print_array_with_msg("arr5", \@arr5) if $self->{_debug2};
    my @arr6 = ();
    foreach my $li (@arr5) {
        my @temp1 = ();
        foreach my $inner (@$li) {
            my @sorted = sort {$a->[2] <=> $b->[2]} @$inner;
            push @temp1, \@sorted;
        }
        push @arr6, \@temp1;
    }
    print_array_with_msg("arr6", \@arr6) if $self->{_debug2};
    my @arr9 = ();
    foreach my $li (@arr6) {
        foreach my $alist (@$li) {
            my @newalist = ();
            if ($alist->[0][1] eq '<') {
                push @newalist, $alist->[0];
            } else {
                push @newalist, $alist->[-1];
            }
            if ($alist->[0][1] ne $alist->[-1][1]) {
                push @newalist, $alist->[-1];
            }
            push @arr9, \@newalist;
        }
    }
    print_array_with_msg('arr9', \@arr9) if $self->{_debug2};
    return \@arr9;

}

##  This method is used to verify that you used legal feature names in the test
##  sample that you want to classify with the decision tree.
sub check_names_used {
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

#######################################  Data Condition Calculator  ######################################

##  This method estimates the worst-case fan-out of the decision tree taking into
##  account the number of values (and therefore the number of branches emanating from
##  a node) for the symbolic features.
sub determine_data_condition {
    my $self = shift;
    my $num_of_features = scalar @{$self->{_feature_names}};
    my @values = ();
    my @number_of_values;
    foreach my $feature (keys %{$self->{_features_and_unique_values_hash}}) {  
        push @values, @{$self->{_features_and_unique_values_hash}->{$feature}}
            if ! contained_in($feature, keys %{$self->{_numeric_features_valuerange_hash}});
        push @number_of_values, scalar @values;
    }
    return if ! @values;
    print "Number of features: $num_of_features\n";
    my @minmax = minmax(\@number_of_values);
    my $max_num_values = $minmax[1];
    print "Largest number of values for symbolic features is: $max_num_values\n";
    my $estimated_number_of_nodes = $max_num_values ** $num_of_features;
    print "\nWORST CASE SCENARIO: The decision tree COULD have as many as $estimated_number_of_nodes " .
          "nodes. The exact number of nodes created depends critically on " .
          "the entropy_threshold used for node expansion (the default value " .
          "for this threshold is 0.01) and on the value set for max_depth_desired " .
          "for the depth of the tree.\n";
    if ($estimated_number_of_nodes > 10000) {
        print "\nTHIS IS WAY TOO MANY NODES. Consider using a relatively " .
              "large value for entropy_threshold and/or a small value for " .
              "for max_depth_desired to reduce the number of nodes created.\n";
        print "\nDo you wish to continue anyway? Enter 'y' for yes:  ";
        my $answer = <STDIN>;
        $answer =~ s/\r?\n?$//;
        while ( ($answer !~ /y(es)?/i) && ($answer !~ /n(o)?/i) ) {
            print "\nAnswer not recognized.  Let's try again. Enter 'y' or 'n': ";
            $answer = <STDIN>;
            $answer =~ s/\r?\n?$//;
        }
        die unless $answer =~ /y(es)?/i;
    }
}


####################################  Read Training Data From File  ######################################


sub get_training_data {
    my $self = shift;
    die("Aborted. get_training_data_csv() is only for CSV files") unless $self->{_training_datafile} =~ /\.csv$/;
    my %class_names = ();
    my %all_record_ids_with_class_labels;
    my $firstline;
    my %data_hash;
    $|++;
    open FILEIN, $self->{_training_datafile} || die "unable to open $self->{_training_datafile}: $!";
    my $record_index = 0;
    my $firsetline;
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
        my $classname = $parts[$self->{_csv_class_column_index}];
        $class_names{$classname} = 1;
        my $record_label = shift @parts;
        $record_label  =~ s/^\s*\"|\"\s*$//g;
        $data_hash{$record_label} = \@parts;
        $all_record_ids_with_class_labels{$record_label} = $classname;
        print "." if $record_index % 10000 == 0;
        $record_index++;
    }
    close FILEIN;    
    $|--;
    $self->{_how_many_total_training_samples} = $record_index - 1;  # must subtract 1 for the header record
    print "\n\nTotal number of training samples: $self->{_how_many_total_training_samples}\n" if $self->{_debug1};
    my @all_feature_names =   split /,/, substr($firstline, index($firstline,','));
    my $class_column_heading = $all_feature_names[$self->{_csv_class_column_index}];
    my @all_class_names = sort map {"$class_column_heading=$_"} keys %class_names;
    my @feature_names = map {$all_feature_names[$_]} @{$self->{_csv_columns_for_features}};
    my %class_for_sample_hash = map {"sample_" . $_  =>  "$class_column_heading=" . $data_hash{$_}->[$self->{_csv_class_column_index} - 1 ] } keys %data_hash;
    my @sample_names = map {"sample_$_"} keys %data_hash;
    my %feature_values_for_samples_hash = map {my $sampleID = $_; "sample_" . $sampleID  =>  [map {my $fname = $all_feature_names[$_]; $fname . "=" . eval{$data_hash{$sampleID}->[$_-1] =~ /^\d+$/ ? sprintf("%.1f", $data_hash{$sampleID}->[$_-1] ) : $data_hash{$sampleID}->[$_-1] } } @{$self->{_csv_columns_for_features}} ] }  keys %data_hash;    
    my %features_and_values_hash = map { my $a = $_; {$all_feature_names[$a] => [  map {my $b = $_; $b =~ /^\d+$/ ? sprintf("%.1f",$b) : $b} map {$data_hash{$_}->[$a-1]} keys %data_hash ]} } @{$self->{_csv_columns_for_features}};     
    my %numeric_features_valuerange_hash = ();
    my %feature_values_how_many_uniques_hash = ();
    my %features_and_unique_values_hash = ();
    my $numregex =  '[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?';
    foreach my $feature (keys %features_and_values_hash) {
        my %seen1 = ();
        my @unique_values_for_feature = sort grep {$_ if $_ ne 'NA' && !$seen1{$_}++} 
                                                   @{$features_and_values_hash{$feature}};
        $feature_values_how_many_uniques_hash{$feature} = scalar @unique_values_for_feature;
        my $not_all_values_float = 0;
        map {$not_all_values_float = 1 if $_ !~ /^$numregex$/} @unique_values_for_feature;
        if ($not_all_values_float == 0) {
            my @minmaxvalues = minmax(\@unique_values_for_feature);
            $numeric_features_valuerange_hash{$feature} = \@minmaxvalues; 
        }
        $features_and_unique_values_hash{$feature} = \@unique_values_for_feature;
    }
    if ($self->{_debug1}) {
        print "\nAll class names: @all_class_names\n";
        print "\nEach sample data record:\n";
        foreach my $sample (sort {sample_index($a) <=> sample_index($b)} keys %feature_values_for_samples_hash) {
            print "$sample  =>  @{$feature_values_for_samples_hash{$sample}}\n";
        }
        print "\nclass label for each data sample:\n";
        foreach my $sample (sort {sample_index($a) <=> sample_index($b)}  keys %class_for_sample_hash) {
            print "$sample => $class_for_sample_hash{$sample}\n";
        }
        print "\nFeatures used: @feature_names\n\n";
        print "\nfeatures and the values taken by them:\n";
        foreach my $feature (sort keys %features_and_values_hash) {
            print "$feature => @{$features_and_values_hash{$feature}}\n";
        }
        print "\nnumeric features and their ranges:\n";
        foreach  my $feature (sort keys %numeric_features_valuerange_hash) {
            print "$feature  =>  @{$numeric_features_valuerange_hash{$feature}}\n";
        }
        print "\nnumber of unique values in each feature:\n";
        foreach  my $feature (sort keys %feature_values_how_many_uniques_hash) {
            print "$feature  =>  $feature_values_how_many_uniques_hash{$feature}\n";
        }
    }
    $self->{_class_names} = \@all_class_names;
    $self->{_feature_names} = \@feature_names;
    $self->{_samples_class_label_hash}  =  \%class_for_sample_hash;
    $self->{_training_data_hash}  =  \%feature_values_for_samples_hash;
    $self->{_features_and_values_hash}  = \%features_and_values_hash;
    $self->{_features_and_unique_values_hash}  =  \%features_and_unique_values_hash;
    $self->{_numeric_features_valuerange_hash} = \%numeric_features_valuerange_hash;
    $self->{_feature_values_how_many_uniques_hash} = \%feature_values_how_many_uniques_hash;
}

sub show_training_data {
    my $self = shift;
    my @class_names = @{$self->{_class_names}};
    my %features_and_values_hash = %{$self->{_features_and_values_hash}};
    my %samples_class_label_hash = %{$self->{_samples_class_label_hash}};
    my %training_data_hash = %{$self->{_training_data_hash}};
    print "\n\nClass Names: @class_names\n";
    print "\n\nFeatures and Their Values:\n\n";
    while ( my ($k, $v) = each %features_and_values_hash ) {
        print "$k --->  @{$features_and_values_hash{$k}}\n";
    }
    print "\n\nSamples vs. Class Labels:\n\n";
    foreach my $kee (sort {sample_index($a) <=> sample_index($b)} keys %samples_class_label_hash) {
        print "$kee =>  $samples_class_label_hash{$kee}\n";
    }
    print "\n\nTraining Samples:\n\n";
    foreach my $kee (sort {sample_index($a) <=> sample_index($b)} 
                                      keys %training_data_hash) {
        print "$kee =>  @{$training_data_hash{$kee}}\n";
    }
}    

sub get_class_names {
    my $self = shift;
    return @{$self->{_class_names}}
}

##########################################  Utility Routines  ############################################

sub closest_sampling_point {
    my $value = shift;
    my $arr_ref = shift;
    my @arr = @{$arr_ref};
    my @compare = map {abs($_ - $value)} @arr;
    my ($minval,$index) = minimum(\@compare);
    return $arr[$index];
}

## returns the array index that contains a specified STRING value: (meant only for array of strings)
sub get_index_at_value {
    my $value = shift;
    my @array = @{shift @_};
    foreach my $i (0..@array-1) {
        return $i if $value eq $array[$i];
    }
}

##  When the training data is read from a CSV file, we assume that the first column
##  of each data record contains a unique integer identifier for the record in that
##  row. This training data is stored in a hash whose keys are the prefix 'sample_'
##  followed by the identifying integers.  The purpose of this function is to return
##  the identifying integer associated with a data record.
sub sample_index {
    my $arg = shift;
    $arg =~ /_(.+)$/;
    return $1;
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

# Returns an array of two values, the min and the max, of an array of floats
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

# checks whether an element is in an array:
sub contained_in {
    my $ele = shift;
    my @array = @_;
    my $count = 0;
    map {$count++ if $ele eq $_} @array;
    return $count;
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

sub check_for_illegal_params2 {
    my @params = @_;
    my @legal_params = qw / training_datafile
                            entropy_threshold
                            max_depth_desired
                            csv_class_column_index
                            csv_columns_for_features
                            symbolic_to_numeric_cardinality_threshold
                            number_of_histogram_bins
                            csv_cleanup_needed
                            debug1
                            debug2
                            debug3
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

sub print_array_with_msg {
    my $message = shift;
    my $arr = shift;
    print "\n$message: ";
    print_nested_array( $arr );
}

sub print_nested_array {
    my $arr = shift;
    my @arr = @$arr;
    print "[";
    foreach my $item (@arr) {
        if (ref $item) {
            print_nested_array($item);
        } else {
            print "$item";
        }
    }
    print "]";
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

######################################### Class EvalTrainingData  ########################################

##  This subclass of the DecisionTree class is used to evaluate the quality of your
##  training data by running a 10-fold cross-validation test on it. This test divides
##  all of the training data into ten parts, with nine parts used for training a
##  decision tree and one part used for testing its ability to classify correctly.
##  This selection of nine parts for training and one part for testing is carried out
##  in all of the ten different possible ways.  This testing functionality can also
##  be used to find the best values to use for the constructor parameters
##  entropy_threshold, max_depth_desired, and
##  symbolic_to_numeric_cardinality_threshold.

##  Only the CSV training files can be evaluated in this manner (because only CSV
##  training are allowed to have numeric features --- which is the more interesting
##  case for evaluation analytics.

package EvalTrainingData;

@EvalTrainingData::ISA = ('Algorithm::DecisionTree');

sub new {
    my $class = shift;
    my $instance = Algorithm::DecisionTree->new(@_);
    bless $instance, $class;
}

sub evaluate_training_data {
    my $self = shift;
    my $evaldebug = 0;
    die "The data evaluation function in the module can only be used when your " .
        "training data is in a CSV file" unless $self->{_training_datafile} =~ /\.csv$/;
    print "\nWill run a 10-fold cross-validation test on your training data to test its " .
          "class-discriminatory power:\n";
    my %all_training_data = %{$self->{_training_data_hash}};
    my @all_sample_names = sort {Algorithm::DecisionTree::sample_index($a) <=> 
                                     Algorithm::DecisionTree::sample_index($b)}  keys %all_training_data;
    my $fold_size = int(0.1 * (scalar keys %all_training_data));
    print "fold size: $fold_size\n";
    my %confusion_matrix = ();
    foreach my $class_name (@{$self->{_class_names}}) {
        foreach my $inner_class_name (@{$self->{_class_names}}) {
            $confusion_matrix{$class_name}->{$inner_class_name} = 0;
        }
    }
    foreach my $fold_index (0..9) {
        print "\nStarting the iteration indexed $fold_index of the 10-fold cross-validation test\n"; 
        my @testing_samples = @all_sample_names[$fold_size * $fold_index .. $fold_size * ($fold_index+1) - 1];
        my @training_samples = (@all_sample_names[0 .. $fold_size * $fold_index-1],  
                     @all_sample_names[$fold_size * ($fold_index+1) .. (scalar keys %all_training_data) - 1]);
        my %testing_data = ();
        foreach my $x (@testing_samples) {
            $testing_data{$x} = $all_training_data{$x};
        }
        my %training_data = ();
        foreach my $x (@training_samples) {
            $training_data{$x} = $all_training_data{$x};
        }
        my $trainingDT = Algorithm::DecisionTree->new('evalmode');
        $trainingDT->{_training_data_hash} = \%training_data;
        $trainingDT->{_class_names} = $self->{_class_names};
        $trainingDT->{_feature_names} = $self->{_feature_names};
        $trainingDT->{_entropy_threshold} = $self->{_entropy_threshold};
        $trainingDT->{_max_depth_desired} = $self->{_max_depth_desired};
        $trainingDT->{_symbolic_to_numeric_cardinality_threshold} = 
                                                $self->{_symbolic_to_numeric_cardinality_threshold};
        foreach my $sample_name (@training_samples) {
            $trainingDT->{_samples_class_label_hash}->{$sample_name} = 
                                                $self->{_samples_class_label_hash}->{$sample_name};
        }
        foreach my $feature (keys %{$self->{_features_and_values_hash}}) {
            $trainingDT->{_features_and_values_hash}->{$feature} = ();
        }
        my $pattern = '(\S+)\s*=\s*(\S+)';
        foreach my $item (sort {Algorithm::DecisionTree::sample_index($a) <=> 
                                Algorithm::DecisionTree::sample_index($b)}  
                          keys %{$trainingDT->{_training_data_hash}}) {
            foreach my $feature_and_value (@{$trainingDT->{_training_data_hash}->{$item}}) {
                $feature_and_value =~ /$pattern/;
                my ($feature,$value) = ($1,$2);
                push @{$trainingDT->{_features_and_values_hash}->{$feature}}, $value if $value ne 'NA';
            }
        }
        foreach my $feature (keys %{$trainingDT->{_features_and_values_hash}}) {
            my %seen = ();
            my @unique_values_for_feature = grep {$_ if $_ ne 'NA' && !$seen{$_}++} 
                                                @{$trainingDT->{_features_and_values_hash}->{$feature}}; 
            if (Algorithm::DecisionTree::contained_in($feature, 
                                                keys %{$self->{_numeric_features_valuerange_hash}})) {
                @unique_values_for_feature = sort {$a <=> $b} @unique_values_for_feature;
            } else {
                @unique_values_for_feature = sort @unique_values_for_feature;
            }
            $trainingDT->{_features_and_unique_values_hash}->{$feature} = \@unique_values_for_feature;
        }
        foreach my $feature (keys %{$self->{_numeric_features_valuerange_hash}}) {
            my @minmaxvalues = Algorithm::DecisionTree::minmax(
                                         \@{$trainingDT->{_features_and_unique_values_hash}->{$feature}});
            $trainingDT->{_numeric_features_valuerange_hash}->{$feature} = \@minmaxvalues;
        }
        if ($evaldebug) {
            print "\n\nprinting samples in the testing set: @testing_samples\n";
            print "\n\nPrinting features and their values in the training set:\n";
            foreach my $item (sort keys %{$trainingDT->{_features_and_values_hash}}) {
                print "$item  => @{$trainingDT->{_features_and_values_hash}->{$item}}\n";
            }
            print "\n\nPrinting unique values for features:\n";
            foreach my $item (sort keys %{$trainingDT->{_features_and_unique_values_hash}}) {
                print "$item  => @{$trainingDT->{_features_and_unique_values_hash}->{$item}}\n";
            }
            print "\n\nPrinting unique value ranges for features:\n";
            foreach my $item (sort keys %{$trainingDT->{_numeric_features_valuerange_hash}}) {
                print "$item  => @{$trainingDT->{_numeric_features_valuerange_hash}->{$item}}\n";
            }
        }
        foreach my $feature (keys %{$self->{_features_and_unique_values_hash}}) {
            $trainingDT->{_feature_values_how_many_uniques_hash}->{$feature} = 
                scalar @{$trainingDT->{_features_and_unique_values_hash}->{$feature}};
        }
        $trainingDT->{_debug2} = 1 if $evaldebug;
        $trainingDT->calculate_first_order_probabilities();
        $trainingDT->calculate_class_priors();
        my $root_node = $trainingDT->construct_decision_tree_classifier();
        $root_node->display_decision_tree("     ") if $evaldebug;
        foreach my $test_sample_name (@testing_samples) {
            my @test_sample_data = @{$all_training_data{$test_sample_name}};
            print "original data in test sample: @test_sample_data\n" if $evaldebug;
            @test_sample_data = grep {$_ if $_ && $_ !~ /=NA$/} @test_sample_data;
            print "filtered data in test sample: @test_sample_data\n" if $evaldebug;
            my %classification = %{$trainingDT->classify($root_node, \@test_sample_data)};
            my @solution_path = @{$classification{'solution_path'}};
            delete $classification{'solution_path'};
            my @which_classes = keys %classification;
            @which_classes = sort {$classification{$b} <=> $classification{$a}} @which_classes;
            my $most_likely_class_label = $which_classes[0];
            if ($evaldebug) {
                print "\nClassification:\n\n";
                print "     class                         probability\n";
                print "     ----------                    -----------\n";
                foreach my $which_class (@which_classes) {
                    my $classstring = sprintf("%-30s", $which_class);
                    my $valuestring = sprintf("%-30s", $classification{$which_class});
                    print "     $classstring $valuestring\n";
                }
                print "\nSolution path in the decision tree: @solution_path\n";
                print "\nNumber of nodes created: " . $root_node->how_many_nodes() . "\n";
            }
            my $true_class_label_for_sample = $self->{_samples_class_label_hash}->{$test_sample_name};
            print "$test_sample_name:    true_class: $true_class_label_for_sample    " .
                     "estimated_class: $most_likely_class_label\n"  if $evaldebug;
            $confusion_matrix{$true_class_label_for_sample}->{$most_likely_class_label} += 1;
        }
    }
    print "\n\n       DISPLAYING THE CONFUSION MATRIX FOR THE 10-FOLD CROSS-VALIDATION TEST:\n\n\n";
    my $matrix_header = " " x 30;
    foreach my $class_name (@{$self->{_class_names}}) {  
        $matrix_header .= sprintf("%-30s", $class_name);
    }
    print "\n" . $matrix_header . "\n\n";
    foreach my $row_class_name (sort keys %confusion_matrix) {
        my $row_display = sprintf("%-30s", $row_class_name);
        foreach my $col_class_name (sort keys %{$confusion_matrix{$row_class_name}}) {
            $row_display .= sprintf( "%-30u",  $confusion_matrix{$row_class_name}->{$col_class_name} );
        }
        print "$row_display\n\n";
    }
    print "\n\n";
    my ($diagonal_sum, $off_diagonal_sum) = (0,0);
    foreach my $row_class_name (sort keys %confusion_matrix) {
        foreach my $col_class_name (sort keys %{$confusion_matrix{$row_class_name}}) {
            if ($row_class_name eq $col_class_name) {
                $diagonal_sum += $confusion_matrix{$row_class_name}->{$col_class_name};
            } else {
                $off_diagonal_sum += $confusion_matrix{$row_class_name}->{$col_class_name};
            }
        }
    }
    my $data_quality_index = 100.0 * $diagonal_sum / ($diagonal_sum + $off_diagonal_sum);
    print "\nTraining Data Quality Index: $data_quality_index    (out of a possible maximum of 100)\n";
    if ($data_quality_index <= 80) {
        print "\nYour training data does not possess much class discriminatory " .
              "information.  It could be that the classes are inherently not well " .
              "separable or that your constructor parameter choices are not appropriate.\n";
    } elsif ($data_quality_index > 80 && $data_quality_index <= 90) {
        print "\nYour training data possesses some class discriminatory information " .
              "but it may not be sufficient for real-world applications.  You might " .
              "try tweaking the constructor parameters to see if that improves the " .
              "class discriminations.\n";
    } elsif ($data_quality_index > 90 && $data_quality_index <= 95) {
        print  "\nYour training data appears to possess good class discriminatory " .
               "information.  Whether or not it is acceptable would depend on your " .
               "application.\n";
    } elsif ($data_quality_index > 95 && $data_quality_index <= 98) {
        print "\nYour training data is of excellent quality.\n";
    } else {
        print "\nYour training data is perfect.\n";
    }

}


#############################################  Class DTNode  #############################################

# The nodes of the decision tree are instances of this class:

package DTNode;

use strict; 
use Carp;

# $feature is the feature test at the current node.  $branch_features_and_values is
# an anonymous array holding the feature names and corresponding values on the path
# from the root to the current node:
sub new {                                                           
    my ($class, $feature, $entropy, $class_probabilities, 
                                       $branch_features_and_values_or_thresholds, $dt, $root_or_not) = @_; 
    $root_or_not = '' if !defined $root_or_not;
    if ($root_or_not eq 'root') {
        $dt->{nodes_created} = -1;
        $dt->{class_names} = undef;
    }
    my $self = {                                                         
            _dt                      => $dt,
            _feature                 => $feature,                                       
            _node_creation_entropy   => $entropy,
            _class_probabilities     => $class_probabilities,
            _branch_features_and_values_or_thresholds => $branch_features_and_values_or_thresholds,
            _linked_to => [],                                          
    };
    bless $self, $class;
    $self->{_serial_number} =  $self->get_next_serial_num();
    return $self;
}

sub how_many_nodes {
    my $self = shift;
    return $self->{_dt}->{nodes_created} + 1;
}

sub set_class_names {
    my $self = shift;
    my $class_names_list = shift;
    $self->{_dt}->{class_names} = $class_names_list;
}

sub get_class_names {
    my $self = shift;
    return $self->{_dt}->{class_names};
}

sub get_next_serial_num {
    my $self = shift;
    $self->{_dt}->{nodes_created} += 1;
    return $self->{_dt}->{nodes_created};
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

sub get_node_entropy {
    my $self = shift;                              
    return $self->{_node_creation_entropy};
}

sub get_class_probabilities {                                  
    my $self = shift;                              
    return $self->{ _class_probabilities};                    
}

sub get_branch_features_and_values_or_thresholds {
    my $self = shift; 
    return $self->{_branch_features_and_values_or_thresholds};
}

sub add_to_branch_features_and_values {
    my $self = shift;                   
    my $feature_and_value = shift;
    push @{$self->{ _branch_features_and_values }}, $feature_and_value;
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
    my $node_creation_entropy_at_node = $self->get_node_entropy();
    my $print_node_creation_entropy_at_node = sprintf("%.3f", $node_creation_entropy_at_node);
    my @class_probabilities = @{$self->get_class_probabilities()};
    my @class_probabilities_for_display = map {sprintf("%0.3f", $_)} @class_probabilities;
    my $serial_num = $self->get_serial_num();
    my @branch_features_and_values_or_thresholds = @{$self->get_branch_features_and_values_or_thresholds()};
    print "\n\nNODE $serial_num" .
          ":\n   Branch features and values to this node: @branch_features_and_values_or_thresholds" .
          "\n   Class probabilities at current node: @class_probabilities_for_display" .
          "\n   Entropy at current node: $print_node_creation_entropy_at_node" .
          "\n   Best feature test at current node: $feature_at_node\n\n";
}

sub display_decision_tree {
    my $self = shift;
    my $offset = shift;
    my $serial_num = $self->get_serial_num();
    if (@{$self->get_children()} > 0) {
        my $feature_at_node = $self->get_feature() || " ";
        my $node_creation_entropy_at_node = $self->get_node_entropy();
        my $print_node_creation_entropy_at_node = sprintf("%.3f", $node_creation_entropy_at_node);
        my @branch_features_and_values_or_thresholds = @{$self->get_branch_features_and_values_or_thresholds()};
        my @class_probabilities = @{$self->get_class_probabilities()};
        my @print_class_probabilities = map {sprintf("%0.3f", $_)} @class_probabilities;
        my @class_names = @{$self->get_class_names()};
        my @print_class_probabilities_with_class =
            map {"$class_names[$_]" . '=>' . $print_class_probabilities[$_]} 0..@class_names-1;
        print "NODE $serial_num: $offset BRANCH TESTS TO NODE: @branch_features_and_values_or_thresholds\n";
        my $second_line_offset = "$offset" . " " x (8 + length("$serial_num"));
        print "$second_line_offset" . "Decision Feature: $feature_at_node    Node Creation Entropy: " ,
              "$print_node_creation_entropy_at_node   Class Probs: @print_class_probabilities_with_class\n\n";
        $offset .= "   ";
        foreach my $child (@{$self->get_children()}) {
            $child->display_decision_tree($offset);
        }
    } else {
        my $node_creation_entropy_at_node = $self->get_node_entropy();
        my $print_node_creation_entropy_at_node = sprintf("%.3f", $node_creation_entropy_at_node);
        my @branch_features_and_values_or_thresholds = @{$self->get_branch_features_and_values_or_thresholds()};
        my @class_probabilities = @{$self->get_class_probabilities()};
        my @print_class_probabilities = map {sprintf("%0.3f", $_)} @class_probabilities;
        my @class_names = @{$self->get_class_names()};
        my @print_class_probabilities_with_class =
            map {"$class_names[$_]" . '=>' . $print_class_probabilities[$_]} 0..@class_names-1;
        print "NODE $serial_num: $offset BRANCH TESTS TO LEAF NODE: @branch_features_and_values_or_thresholds\n";
        my $second_line_offset = "$offset" . " " x (8 + length("$serial_num"));
        print "$second_line_offset" . "Node Creation Entropy: $print_node_creation_entropy_at_node   " .
              "Class Probs: @print_class_probabilities_with_class\n\n";
    }
}


##############################  Generate Your Own Numeric Training Data  #################################
#############################      Class TrainingDataGeneratorNumeric     ################################

##  See the script generate_training_data_numeric.pl in the examples
##  directory on how to use this class for generating your own numeric training and
##  test data.  The training and test data are generated in accordance with the
##  specifications you place in the parameter file that is supplied as an argument to
##  the constructor of this class.

package TrainingDataGeneratorNumeric;

use strict;                                                         
use Carp;

sub new {                                                           
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if check_for_illegal_params3(@params) == 0;   
    bless {
        _output_training_csv_file          =>   $args{'output_training_csv_file'} 
                                                   || croak("name for output_training_csv_file required"),
        _output_test_csv_file              =>   $args{'output_test_csv_file'} 
                                                   || croak("name for output_test_csv_file required"),
        _parameter_file                    =>   $args{'parameter_file'}
                                                         || croak("parameter_file required"),
        _number_of_samples_for_training    =>   $args{'number_of_samples_for_training'} 
                                                         || croak("number_of_samples_for_training"),
        _number_of_samples_for_testing     =>   $args{'number_of_samples_for_testing'} 
                                                         || croak("number_of_samples_for_testing"),
        _debug                             =>    $args{debug} || 0,
        _class_names                       =>    [],
        _class_names_and_priors            =>    {},
        _features_with_value_range         =>    {},
        _features_ordered                  =>    [],
        _classes_and_their_param_values    =>    {},
    }, $class;
}

sub check_for_illegal_params3 {
    my @params = @_;
    my @legal_params = qw / output_training_csv_file
                            output_test_csv_file
                            parameter_file
                            number_of_samples_for_training
                            number_of_samples_for_testing
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

##  The training data generated by an instance of the class
##  TrainingDataGeneratorNumeric is based on the specs you place in a parameter that
##  you supply to the class constructor through a constructor variable called
##  `parameter_file'.  This method is for parsing the parameter file in order to
##  order to determine the names to be used for the different data classes, their
##  means, and their variances.
sub read_parameter_file_numeric {
    my $self = shift;
    my @class_names = ();
    my %class_names_and_priors = ();
    my %features_with_value_range = ();
    my %classes_and_their_param_values = ();
#   my $regex8 =  '[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?';
    open FILE, $self->{_parameter_file} || die "unable to open parameter file: $!";
    my @params = <FILE>;
    my $params = join "", @params;
    my $regex = 'class names: ([\w ]+)\W*class priors: ([\d. ]+)';
    $params =~ /$regex/si;
    my ($class_names, $class_priors) = ($1, $2);
    @class_names = split ' ', $class_names; 
    my @class_priors = split ' ', $class_priors;
    foreach my $i (0..@class_names-1) {
        $class_names_and_priors{$class_names[$i]} = $class_priors[$i];
    }
    if ($self->{_debug}) {
        foreach my $cname (keys %class_names_and_priors) {
            print "$cname  =>   $class_names_and_priors{$cname}\n";
        }
    }
    $regex = 'feature name: \w*.*?value range: [\d\. -]+';
    my @features = $params =~ /$regex/gsi;
    my @features_ordered;
    $regex = 'feature name: (\w+)\W*?value range:\s*([\d. -]+)';
    foreach my $feature (@features) {
        $feature =~ /$regex/i;
        my $feature_name = $1;
        push @features_ordered, $feature_name;
        my @value_range = split ' ', $2;
        $features_with_value_range{$feature_name} = \@value_range;
    }
    if ($self->{_debug}) {
        foreach my $fname (keys %features_with_value_range) {
            print "$fname  =>   @{$features_with_value_range{$fname}}\n";
        }
    }
    foreach my $i (0..@class_names-1) {
        $classes_and_their_param_values{$class_names[$i]} = {};
    }
    $regex = 'params for class: \w*?\W+?mean:[\d\. ]+\W*?covariance:\W+?(?:[ \d.]+\W+?)+';
    my @class_params = $params =~ /$regex/gsi;
    $regex = 'params for class: (\w+)\W*?mean:\s*([\d. -]+)\W*covariance:\s*([\s\d.]+)';
    foreach my $class_param (@class_params) {
        $class_param =~ /$regex/gsi;
        my $class_name = $1;
        my @class_mean = split ' ', $2;
        $classes_and_their_param_values{$class_name}->{'mean'} =  \@class_mean;
        my $class_param_string = $3;
        my @covar_rows = split '\n', $class_param_string;
        my @covar_matrix;
        foreach my $row (@covar_rows) {
            my @row = split ' ', $row;
            push @covar_matrix, \@row;
        }
        $classes_and_their_param_values{$class_name}->{'covariance'} =  \@covar_matrix;
    }
    if ($self->{_debug}) {
        print "\nThe class parameters are:\n\n";
        foreach my $cname (keys %classes_and_their_param_values) {
            print "\nFor class name $cname:\n";
            my %params_hash = %{$classes_and_their_param_values{$cname}};
            foreach my $x (keys %params_hash) {
                if ($x eq 'mean') {
                    print "    $x   =>   @{$params_hash{$x}}\n";
                } else {
                    if ($x eq 'covariance') {
                        print "    The covariance matrix:\n";
                        my @matrix = @{$params_hash{'covariance'}};
                        foreach my $row (@matrix) {
                            print "        @$row\n";
                        }
                    }
                }
            }
        }
    }
    $self->{_class_names}        =   \@class_names;
    $self->{_class_names_and_priors}   = \%class_names_and_priors;
    $self->{_features_with_value_range}   = \%features_with_value_range;
    $self->{_classes_and_their_param_values} = \%classes_and_their_param_values;
    $self->{_features_ordered} = \@features_ordered;
}

##  After the parameter file is parsed by the previous method, this method calls on
##  Math::Random::random_multivariate_normal() to generate the training and test data
##  samples. Your training and test data can be of any number of of dimensions, can
##  have any mean, and any covariance.  The training and test data must obviously be
##  drawn from the same distribution.
sub gen_numeric_training_and_test_data_and_write_to_csv {
    use Math::Random;
    my $self = shift;
    my %training_samples_for_class;
    my %test_samples_for_class;
    foreach my $class_name (@{$self->{_class_names}}) {
        $training_samples_for_class{$class_name} = [];
        $test_samples_for_class{$class_name} = [];
    }
    foreach my $class_name (keys %{$self->{_classes_and_their_param_values}}) {
        my @mean = @{$self->{_classes_and_their_param_values}->{$class_name}->{'mean'}};
        my @covariance = @{$self->{_classes_and_their_param_values}->{$class_name}->{'covariance'}};
        my @new_training_data = Math::Random::random_multivariate_normal(
              $self->{_number_of_samples_for_training} * $self->{_class_names_and_priors}->{$class_name},
              @mean, @covariance );
        my @new_test_data = Math::Random::random_multivariate_normal(
              $self->{_number_of_samples_for_testing} * $self->{_class_names_and_priors}->{$class_name},
              @mean, @covariance );
        if ($self->{_debug}) {
            print "training data for class $class_name:\n";
            foreach my $x (@new_training_data) {print "@$x\n";}
            print "\n\ntest data for class $class_name:\n";
            foreach my $x (@new_test_data) {print "@$x\n";}
        }
        $training_samples_for_class{$class_name} = \@new_training_data;
        $test_samples_for_class{$class_name} = \@new_test_data;
    }
    my @training_data_records = ();
    my @test_data_records = ();
    foreach my $class_name (keys %training_samples_for_class) {
        my $num_of_samples_for_training = $self->{_number_of_samples_for_training} * 
                                         $self->{_class_names_and_priors}->{$class_name};
        my $num_of_samples_for_testing = $self->{_number_of_samples_for_testing} * 
                                         $self->{_class_names_and_priors}->{$class_name};
        foreach my $sample_index (0..$num_of_samples_for_training-1) {
            my @training_vector = @{$training_samples_for_class{$class_name}->[$sample_index]};
            @training_vector = map {sprintf("%.3f", $_)} @training_vector;
            my $training_data_record = "$class_name," . join(",", @training_vector) . "\n";
            push @training_data_records, $training_data_record;
        }
        foreach my $sample_index (0..$num_of_samples_for_testing-1) {
            my @test_vector = @{$test_samples_for_class{$class_name}->[$sample_index]};
            @test_vector = map {sprintf("%.3f", $_)} @test_vector;
            my $test_data_record = "$class_name," . join(",", @test_vector) . "\n";
            push @test_data_records, $test_data_record;
        }
    }
    fisher_yates_shuffle(\@training_data_records);
    fisher_yates_shuffle(\@test_data_records);
    if ($self->{_debug}) {
        foreach my $record (@training_data_records) {
            print "$record";
        }
        foreach my $record (@test_data_records) {
            print "$record";
        }
    }
    open OUTPUT, ">$self->{_output_training_csv_file}";
    my @feature_names_training = @{$self->{_features_ordered}};
    my @quoted_feature_names_training = map {"\"$_\""} @feature_names_training;
    my $first_row_training = '"",' . "\"class_name\"," . join ",", @quoted_feature_names_training;
    print OUTPUT "$first_row_training\n";
    foreach my $i (0..@training_data_records-1) {
        my $i1 = $i+1;
        my $sample_record = "\"$i1\",$training_data_records[$i]";
        print OUTPUT "$sample_record";
    }
    close OUTPUT;
    open OUTPUT, ">$self->{_output_test_csv_file}";
    my @feature_names_testing = keys %{$self->{_features_with_value_range}};
    my @quoted_feature_names_testing = map {"\"$_\""} @feature_names_testing;
    my $first_row_testing = '"",' . "\"class_name\"," . join ",", @quoted_feature_names_testing;
    print OUTPUT "$first_row_testing\n";
    foreach my $i (0..@test_data_records-1) {
        my $i1 = $i+1;
        my $sample_record = "\"$i1\",$test_data_records[$i]";
        print OUTPUT "$sample_record";
    }
    close OUTPUT;
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

###########################  Generate Your Own Symbolic Training Data  ###############################
###########################     Class TrainingDataGeneratorSymbolic      #############################

##  See the sample script generate_training_and_test_data_symbolic.pl for how to use
##  this class for generating purely symbolic training and test data.  The data is
##  generated according to the specifications you place in a parameter file whose
##  name you supply as one of constructor arguments.
package TrainingDataGeneratorSymbolic;

use strict;                                                         
use Carp;

sub new {                                                           
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if check_for_illegal_params4(@params) == 0;   
    bless {
        _output_training_datafile          =>   $args{'output_training_datafile'} 
                                                   || die("name for output_training_datafile required"),
        _parameter_file                    =>   $args{'parameter_file'}
                                                   || die("parameter_file required"),
        _number_of_samples_for_training    =>   $args{'number_of_samples_for_training'} 
                                                   || die("number_of_samples_for_training required"),
        _debug                             =>    $args{debug} || 0,
        _class_names                       =>    [],
        _class_priors                      =>    [],
        _features_and_values_hash          =>    {},
        _bias_hash                         =>    {},
        _training_sample_records           =>    {},
    }, $class;
}

sub check_for_illegal_params4 {
    my @params = @_;
    my @legal_params = qw / output_training_datafile
                            parameter_file
                            number_of_samples_for_training
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

##  Read a parameter file for generating symbolic training data. See the script
##  generate_symbolic_training_data_symbolic.pl in the Examples directory for how to
##  pass the name of the parameter file to the constructor of the
##  TrainingDataGeneratorSymbolic class.
sub read_parameter_file_symbolic {
    my $self = shift;
    my $debug = $self->{_debug};
    my $number_of_training_samples = $self->{_number_of_samples_for_training};
    my $input_parameter_file = $self->{_parameter_file};
    croak "Forgot to supply parameter file" if ! defined $input_parameter_file;
    my $output_file_training = $self->{_output_training_datafile};
    my $output_file_testing = $self->{_output_test_datafile};
    my @all_params;
    my $param_string;
    open INPUT, $input_parameter_file || "unable to open parameter file: $!";
    @all_params = <INPUT>;
    @all_params = grep { $_ !~ /^[ ]*#/ } @all_params;
    @all_params = grep { $_ =~ s/\r?\n?$//} @all_params;
    $param_string = join ' ', @all_params;
    my ($class_names, $class_priors, $rest_param) = 
              $param_string =~ /^\s*class names:(.*?)\s*class priors:(.*?)(feature: .*)/;
    my @class_names = grep {defined($_) && length($_) > 0} split /\s+/, $1;
    push @{$self->{_class_names}}, @class_names;
    my @class_priors =   grep {defined($_) && length($_) > 0} split /\s+/, $2;
    push @{$self->{_class_priors}}, @class_priors;    
    my ($feature_string, $bias_string) = $rest_param =~ /(feature:.*?) (bias:.*)/;
    my %features_and_values_hash;
    my @features = split /(feature[:])/, $feature_string;
    @features = grep {defined($_) && length($_) > 0} @features;
    foreach my $item (@features) {
        next if $item =~ /feature/;
        my @splits = split / /, $item;
        @splits = grep {defined($_) && length($_) > 0} @splits;
        foreach my $i (0..@splits-1) {
            if ($i == 0) {
                $features_and_values_hash{$splits[0]} = [];
            } else {
                next if $splits[$i] =~ /values/;
                push @{$features_and_values_hash{$splits[0]}}, $splits[$i];
            }
        }
    }
    $self->{_features_and_values_hash} = \%features_and_values_hash;
    my %bias_hash = %{$self->{_bias_hash}};
    my @biases = split /(bias[:]\s*class[:])/, $bias_string;
    @biases = grep {defined($_) && length($_) > 0} @biases;
    foreach my $item (@biases) {
        next if $item =~ /bias/;
        my @splits = split /\s+/, $item;
        @splits = grep {defined($_) && length($_) > 0} @splits;
        my $feature_name;
        foreach my $i (0..@splits-1) {
            if ($i == 0) {
                $bias_hash{$splits[0]} = {};
            } elsif ($splits[$i] =~ /(^.+)[:]$/) {
                $feature_name = $1;
                $bias_hash{$splits[0]}->{$feature_name} = [];
            } else {
                next if !defined $feature_name;
                push @{$bias_hash{$splits[0]}->{$feature_name}}, $splits[$i]
                        if defined $feature_name;
            }
        }
    }
    $self->{_bias_hash} = \%bias_hash;
    if ($debug) {
        print "\n\nClass names: @class_names\n";
        my $num_of_classes = @class_names;
        print "Class priors: @class_priors\n";
        print "Number of classes: $num_of_classes\n";
        print "\nHere are the features and their possible values:\n";
        while ( my ($k, $v) = each %features_and_values_hash ) {
            print "$k ===>  @$v\n";
        }
        print "\nHere is the biasing for each class:\n";
        while ( my ($k, $v) = each %bias_hash ) {
            print "$k:\n";
            while ( my ($k1, $v1) = each %$v ) {
                print "       $k1 ===>  @$v1\n";
            }
        }
    }
}

##  This method generates training data according to the specifications placed in a
##  parameter file that is read by the previous method.
sub gen_symbolic_training_data {
    my $self = shift;
    my @class_names = @{$self->{_class_names}};
    my @class_priors = @{$self->{_class_priors}};
    my %training_sample_records;
    my %features_and_values_hash = %{$self->{_features_and_values_hash}};
    my %bias_hash  = %{$self->{_bias_hash}};
    my $how_many_training_samples = $self->{_number_of_samples_for_training};
    my $how_many_test_samples = $self->{_number_of_samples_for_testing};
    my %class_priors_to_unit_interval_map;
    my $accumulated_interval = 0;
    foreach my $i (0..@class_names-1) {
        $class_priors_to_unit_interval_map{$class_names[$i]} 
         = [$accumulated_interval, $accumulated_interval + $class_priors[$i]];
        $accumulated_interval += $class_priors[$i];
    }
    if ($self->{_debug}) {
        print "Mapping of class priors to unit interval: \n";
        while ( my ($k, $v) = each %class_priors_to_unit_interval_map ) {
            print "$k =>  @$v\n";
        }
        print "\n\n";
    }
    my $ele_index = 0;
    while ($ele_index < $how_many_training_samples) {
        my $sample_name = "sample" . "_$ele_index";
        $training_sample_records{$sample_name} = [];
        # Generate class label for this training sample:                
        my $roll_the_dice = rand(1.0);
        my $class_label;
        foreach my $class_name (keys %class_priors_to_unit_interval_map ) {
            my $v = $class_priors_to_unit_interval_map{$class_name};
            if ( ($roll_the_dice >= $v->[0]) && ($roll_the_dice <= $v->[1]) ) {
                push @{$training_sample_records{$sample_name}}, 
                                    "class=" . $class_name;
                $class_label = $class_name;
                last;
            }
        }
        foreach my $feature (keys %features_and_values_hash) {
            my @values = @{$features_and_values_hash{$feature}};
            my $bias_string = $bias_hash{$class_label}->{$feature}->[0];
            my $no_bias = 1.0 / @values;
            $bias_string = "$values[0]" . "=$no_bias" if !defined $bias_string;
            my %value_priors_to_unit_interval_map;
            my @splits = split /\s*=\s*/, $bias_string;
            my $chosen_for_bias_value = $splits[0];
            my $chosen_bias = $splits[1];
            my $remaining_bias = 1 - $chosen_bias;
            my $remaining_portion_bias = $remaining_bias / (@values -1);
            @splits = grep {defined($_) && length($_) > 0} @splits;
            my $accumulated = 0;
            foreach my $i (0..@values-1) {
                if ($values[$i] eq $chosen_for_bias_value) {
                    $value_priors_to_unit_interval_map{$values[$i]} 
                        = [$accumulated, $accumulated + $chosen_bias];
                    $accumulated += $chosen_bias;
                } else {
                    $value_priors_to_unit_interval_map{$values[$i]} 
                      = [$accumulated, $accumulated + $remaining_portion_bias];
                    $accumulated += $remaining_portion_bias;           
                }
            }
            my $roll_the_dice = rand(1.0);
            my $value_label;
            foreach my $value_name (keys %value_priors_to_unit_interval_map ) {
                my $v = $value_priors_to_unit_interval_map{$value_name};
                if ( ($roll_the_dice >= $v->[0]) 
                             && ($roll_the_dice <= $v->[1]) ) {
                    push @{$training_sample_records{$sample_name}}, 
                                            $feature . "=" . $value_name;
                    $value_label = $value_name;
                    last;
                }
            }
            if ($self->{_debug}) {
                print "mapping feature value priors for '$feature' " .
                                          "to unit interval: \n";
                while ( my ($k, $v) = 
                        each %value_priors_to_unit_interval_map ) {
                    print "$k =>  @$v\n";
                }
                print "\n\n";
            }
        }
        $ele_index++;
    }
    $self->{_training_sample_records} = \%training_sample_records;
    if ($self->{_debug}) {
        print "\n\nPRINTING TRAINING RECORDS:\n\n";
        foreach my $kee (sort {sample_index($a) <=> sample_index($b)} keys %training_sample_records) {
            print "$kee =>  @{$training_sample_records{$kee}}\n\n";
        }
    }
    my $output_training_file = $self->{_output_training_datafile};
    print "\n\nDISPLAYING TRAINING RECORDS:\n\n" if $self->{_debug};
    open FILEHANDLE, ">$output_training_file";
    my @features = sort keys %features_and_values_hash;
    my $title_string = ',class';
    foreach my $feature_name (@features) {
        $title_string .= ',' . $feature_name;
    }
    print FILEHANDLE "$title_string\n";
    my @sample_names = sort {$a <=> $b}  map { $_ =~ s/^sample_//; $_ } sort keys %training_sample_records;
    my $record_string = '';
    foreach my $sample_name (@sample_names) {
        $record_string .= "$sample_name,";
        my @record = @{$training_sample_records{"sample_$sample_name"}};
        my %item_parts_hash;
        foreach my $item (@record) {
            my @splits = grep $_, split /=/, $item;
            $item_parts_hash{$splits[0]} = $splits[1];
        }
        $record_string .= $item_parts_hash{"class"};
        delete $item_parts_hash{"class"};
        my @kees = sort keys %item_parts_hash;
        foreach my $kee (@kees) {
            $record_string .= ",$item_parts_hash{$kee}";
        }
        print FILEHANDLE "$record_string\n";
        $record_string = '';
    }
    close FILEHANDLE;
}    

sub sample_index {
    my $arg = shift;
    $arg =~ /_(.+)$/;
    return $1;
}    

#################################   Decision Tree Introspection   #######################################
#################################      Class DTIntrospection      #######################################

package DTIntrospection;

##  Instances constructed from this class can provide explanations for the
##  classification decisions at the nodes of a decision tree.  
##  
##  When used in the interactive mode, the decision-tree introspection made possible
##  by this class provides answers to the following three questions: (1) List of the
##  training samples that fall in the portion of the feature space that corresponds
##  to a node of the decision tree; (2) The probabilities associated with the last
##  feature test that led to the node; and (3) The class probabilities predicated on
##  just the last feature test on the path to that node.
##  
##  CAVEAT: It is possible for a node to exist even when there are no training
##  samples in the portion of the feature space that corresponds to the node.  That
##  is because a decision tree is based on the probability densities estimated from
##  the training data. When training data is non-uniformly distributed, it is
##  possible for the probability associated with a point in the feature space to be
##  non-zero even when there are no training samples at or in the vicinity of that
##  point.
##  
##  For a node to exist even where there are no training samples in the portion of
##  the feature space that belongs to the node is an indication of the generalization
##  ability of decision-tree based classification.
##  
##  When used in a non-interactive mode, an instance of this class can be used to
##  create a tabular display that shows what training samples belong directly to the
##  portion of the feature space that corresponds to each node of the decision tree.
##  An instance of this class can also construct a tabular display that shows how the
##  influence of each training sample propagates in the decision tree.  For each
##  training sample, this display first shows the list of nodes that came into
##  existence through feature test(s) that used the data provided by that sample.
##  This list for each training sample is followed by a subtree of the nodes that owe
##  their existence indirectly to the training sample. A training sample influences a
##  node indirectly if the node is a descendant of another node that is affected
##  directly by the training sample.

use strict; 
use Carp;

sub new {                                                           
    my ($class, $dt) = @_; 
    croak "The argument supplied to the DTIntrospection constructor must be of type DecisionTree"
        unless ref($dt) eq "Algorithm::DecisionTree";
    bless {                                                         
        _dt                                 => $dt,
        _root_dtnode                        => $dt->{_root_node},
        _samples_at_nodes_hash              => {},
        _branch_features_to_nodes_hash      => {},
        _sample_to_node_mapping_direct_hash => {},
        _node_serial_num_to_node_hash       => {}, 
        _awareness_raising_msg_shown        => 0,
        _debug                              => 0,
    }, $class;                                                     
}

sub initialize {
    my $self = shift;
    croak "You must first construct the decision tree before using the DTIntrospection class"
        unless $self->{_root_dtnode};
    $self->recursive_descent($self->{_root_dtnode});
}

sub recursive_descent {
    my $self = shift;
    my $node = shift;
    my $node_serial_number = $node->get_serial_num();
    my $branch_features_and_values_or_thresholds = $node->get_branch_features_and_values_or_thresholds();
    print "\nAt node $node_serial_number:  the branch features and values are: @{$branch_features_and_values_or_thresholds}\n" if $self->{_debug};
    $self->{_node_serial_num_to_node_hash}->{$node_serial_number} = $node;
    $self->{_branch_features_to_nodes_hash}->{$node_serial_number} = $branch_features_and_values_or_thresholds;
    my @samples_at_node = ();
    foreach my $item (@$branch_features_and_values_or_thresholds) {
        my $samples_for_feature_value_combo = $self->get_samples_for_feature_value_combo($item);
        unless (@samples_at_node) {
            @samples_at_node =  @$samples_for_feature_value_combo;
        } else {
            my @accum;
            foreach my $sample (@samples_at_node) {
                push @accum, $sample if Algorithm::DecisionTree::contained_in($sample, @$samples_for_feature_value_combo);  
            }
            @samples_at_node =  @accum;
        }
        last unless @samples_at_node;
    }
    @samples_at_node = sort {Algorithm::DecisionTree::sample_index($a) <=> Algorithm::DecisionTree::sample_index($b)} @samples_at_node; 
    print "Node: $node_serial_number    the samples are: [@samples_at_node]\n"  if ($self->{_debug});
    $self->{_samples_at_nodes_hash}->{$node_serial_number} = \@samples_at_node;
    if (@samples_at_node) {
        foreach my $sample (@samples_at_node) {
            if (! exists $self->{_sample_to_node_mapping_direct_hash}->{$sample}) {
                $self->{_sample_to_node_mapping_direct_hash}->{$sample} = [$node_serial_number]; 
            } else {
                push @{$self->{_sample_to_node_mapping_direct_hash}->{$sample}}, $node_serial_number;
            }
        }
    }
    my $children = $node->get_children();
    foreach my $child (@$children) {
        $self->recursive_descent($child);
    }
}

sub display_training_samples_at_all_nodes_direct_influence_only {
    my $self = shift;
    croak "You must first construct the decision tree before using the DT Introspection class." 
        unless $self->{_root_dtnode};
    $self->recursive_descent_for_showing_samples_at_a_node($self->{_root_dtnode});
}

sub recursive_descent_for_showing_samples_at_a_node{
    my $self = shift;
    my $node = shift;
    my $node_serial_number = $node->get_serial_num();
    my $branch_features_and_values_or_thresholds = $node->get_branch_features_and_values_or_thresholds();
    if (exists $self->{_samples_at_nodes_hash}->{$node_serial_number}) {
        print "\nAt node $node_serial_number:  the branch features and values are: [@{$branch_features_and_values_or_thresholds}]\n"  if $self->{_debug};
        print "Node $node_serial_number: the samples are: [@{$self->{_samples_at_nodes_hash}->{$node_serial_number}}]\n";
    }
    map $self->recursive_descent_for_showing_samples_at_a_node($_), @{$node->get_children()};            
}

sub display_training_samples_to_nodes_influence_propagation {
    my $self = shift;
    foreach my $sample (sort {Algorithm::DecisionTree::sample_index($a) <=> Algorithm::DecisionTree::sample_index($b)}  keys %{$self->{_dt}->{_training_data_hash}}) {
        if (exists $self->{_sample_to_node_mapping_direct_hash}->{$sample}) {
            my $nodes_directly_affected = $self->{_sample_to_node_mapping_direct_hash}->{$sample};
            print "\n$sample:\n    nodes affected directly: [@{$nodes_directly_affected}]\n";
            print "    nodes affected through probabilistic generalization:\n";
            map  $self->recursive_descent_for_sample_to_node_influence($_, $nodes_directly_affected, "    "), @$nodes_directly_affected;
        }
    }
}

sub recursive_descent_for_sample_to_node_influence {
    my $self = shift;
    my $node_serial_num = shift;
    my $nodes_already_accounted_for = shift;
    my $offset = shift;
    $offset .= "    ";
    my $node = $self->{_node_serial_num_to_node_hash}->{$node_serial_num};
    my @children =  map $_->get_serial_num(), @{$node->get_children()};
    my @children_affected = grep {!Algorithm::DecisionTree::contained_in($_, @{$nodes_already_accounted_for})} @children;
    if (@children_affected) {
        print "$offset $node_serial_num => [@children_affected]\n";
    }
    map $self->recursive_descent_for_sample_to_node_influence($_, \@children_affected, $offset), @children_affected;
}

sub get_samples_for_feature_value_combo {
    my $self = shift;
    my $feature_value_combo = shift;
    my ($feature,$op,$value) = $self->extract_feature_op_val($feature_value_combo);
    my @samples = ();
    if ($op eq '=') {
        @samples = grep Algorithm::DecisionTree::contained_in($feature_value_combo, @{$self->{_dt}->{_training_data_hash}->{$_}}), keys %{$self->{_dt}->{_training_data_hash}};
    } elsif ($op eq '<') {
        foreach my $sample (keys %{$self->{_dt}->{_training_data_hash}}) {
            my @features_and_values = @{$self->{_dt}->{_training_data_hash}->{$sample}};
            foreach my $item (@features_and_values) {
                my ($feature_data,$op_data,$val_data) = $self->extract_feature_op_val($item);
                if (($val_data ne 'NA') && ($feature eq $feature_data) && ($val_data <= $value)) {
                    push @samples, $sample;
                    last;
                }
            }
        }
    } elsif ($op eq '>') {
        foreach my $sample (keys %{$self->{_dt}->{_training_data_hash}}) {
            my @features_and_values = @{$self->{_dt}->{_training_data_hash}->{$sample}};
            foreach my $item (@features_and_values) {
                my ($feature_data,$op_data,$val_data) = $self->extract_feature_op_val($item);
                if (($val_data ne 'NA') && ($feature eq $feature_data) && ($val_data > $value)) {
                    push @samples, $sample;
                    last;
                }
            }
        }
    } else {
        die "Something strange is going on";
    }
    return \@samples;
}

sub extract_feature_op_val {
    my $self = shift;
    my $feature_value_combo = shift;
    my $pattern1 = '(.+)=(.+)';
    my $pattern2 = '(.+)<(.+)';
    my $pattern3 = '(.+)>(.+)';
    my ($feature,$value,$op);
    if ($feature_value_combo =~ /$pattern2/) {
        ($feature,$op,$value) = ($1,'<',$2);
    } elsif ($feature_value_combo =~ /$pattern3/) {
        ($feature,$op,$value) = ($1,'>',$2);
    } elsif ($feature_value_combo =~ /$pattern1/) {
        ($feature,$op,$value) = ($1,'=',$2);
    }
    return ($feature,$op,$value);
} 

sub explain_classifications_at_multiple_nodes_interactively {
    my $self = shift;
    croak "You called explain_classification_at_multiple_nodes_interactively() without " .
        "first initializing the DTIntrospection instance in your code. Aborting." 
               unless $self->{_samples_at_nodes_hash};
    print "\n\nIn order for the decision tree to introspect\n\n";
    print "  DO YOU ACCEPT the fact that, in general, a region of the feature space\n" .
          "  that corresponds to a DT node may have NON-ZERO probabilities associated\n" .
          "  with it even when there are NO training data points in that region?\n" .
          "\nEnter 'y' for yes or any other character for no:  ";
    my $ans = <STDIN>;
    $ans =~ s/^\s*|\s*$//g;
    die "\n  Since you answered 'no' to a very real theoretical possibility, no explanations possible for the classification decisions in the decision tree. Aborting!\n" if $ans !~ /^ye?s?$/;
    $self->{_awareness_raising_msg_shown} = 1;
    while (1) { 
        my $node_id;
        my $ans;
        while (1) {
            print "\nEnter the integer ID of a node: ";
            $ans = <STDIN>;
            $ans =~ s/^\s*|\s*$//g;
            return if $ans =~ /^exit$/;
            last if Algorithm::DecisionTree::contained_in($ans, keys %{$self->{_samples_at_nodes_hash}});
            print "\nYour answer must be an integer ID of a node. Try again or enter 'exit'.\n";
        }
        $node_id = $ans;        
        $self->explain_classification_at_one_node($node_id)   
    }
}

sub explain_classification_at_one_node {
    my $self = shift;
    my $node_id = shift;
    croak "You called explain_classification_at_one_node() without first initializing " .
        "the DTIntrospection instance in your code. Aborting." unless $self->{_samples_at_nodes_hash};
    unless (exists $self->{_samples_at_nodes_hash}->{$node_id}) { 
        print "Node $node_id is not a node in the tree\n";
        return;
    }
    unless ($self->{_awareness_raising_msg_shown}) {
        print "\n\nIn order for the decision tree to introspect at Node $node_id: \n\n";
        print "  DO YOU ACCEPT the fact that, in general, a region of the feature space\n" .
              "  that corresponds to a DT node may have NON-ZERO probabilities associated\n" .
              "  with it even when there are NO training data points in that region?\n" .
              "\nEnter 'y' for yes or any other character for no:  ";
        my $ans = <STDIN>;
        $ans =~ s/^\s*|\s*$//g;
        die "\n  Since you answered 'no' to a very real theoretical possibility, no explanations possible for the classification decision at node $node_id\n" if $ans !~ /^ye?s?$/;
    }
    my @samples_at_node = @{$self->{_samples_at_nodes_hash}->{$node_id}};
    my @branch_features_to_node = @{$self->{_branch_features_to_nodes_hash}->{$node_id}};
#    my @class_names = @{$self->get_class_names()};
    my @class_names = $self->{_dt}->get_class_names();
    my $class_probabilities = $self->{_root_dtnode}->get_class_probabilities();
    my ($feature,$op,$value) = $self->extract_feature_op_val( $branch_features_to_node[-1] );
    my $msg = @samples_at_node == 0 
              ? "\n\n    There are NO training data samples directly in the region of the feature space assigned to node $node_id: @samples_at_node\n\n"
              : "\n    Samples in the portion of the feature space assigned to Node $node_id: @samples_at_node\n";
    $msg .= "\n    Features tests on the branch to node $node_id: [@branch_features_to_node]\n\n";
    $msg .= "\n    Would you like to see the probability associated with the last feature test on the branch leading to Node $node_id?\n";
    $msg .= "\n    Enter 'y' if yes and any other character for 'no': ";
    print $msg;
    my $ans = <STDIN>;
    $ans =~ s/^\s*|\s*$//g;
    if ($ans =~ /^ye?s?$/) {
        my $sequence = [$branch_features_to_node[-1]];
        my $prob = $self->{_dt}->probability_of_a_sequence_of_features_and_values_or_thresholds($sequence); 
        print "\n    probability of @{$sequence} is: $prob\n";
    }
    $msg = "\n    Using Bayes rule, would you like to see the class probabilities predicated on just the last feature test on the branch leading to Node $node_id?\n";
    $msg .= "\n    Enter 'y' for yes and any other character for no:  ";
    print $msg;
    $ans = <STDIN>;
    $ans =~ s/^\s*|\s*$//g;
    if ($ans =~ /^ye?s?$/) {
        my $sequence = [$branch_features_to_node[-1]];
        foreach my $cls (@class_names) {
            my $prob = $self->{_dt}->probability_of_a_class_given_sequence_of_features_and_values_or_thresholds($cls, $sequence);
            print "\n    probability of class $cls given just the feature test @{$sequence} is: $prob\n";
        }
    } else {
        print "goodbye\n";
    }
    print "\n    Finished supplying information on Node $node_id\n\n";
}

1;

=pod

=head1 NAME

Algorithm::DecisionTree - A Perl module for decision-tree based classification of
multidimensional data.


=head1 SYNOPSIS

  # FOR CONSTRUCTING A DECISION TREE AND FOR CLASSIFYING A SAMPLE:

  # In general, your call for constructing an instance of the DecisionTree class 
  # will look like:

      my $training_datafile = "stage3cancer.csv";
      my $dt = Algorithm::DecisionTree->new( 
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              csv_cleanup_needed => 1,
               );

  # The constructor option `csv_class_column_index' informs the module as to which
  # column of your CSV file contains the class label.  THE COLUMN INDEXING IS ZERO
  # BASED.  The constructor option `csv_columns_for_features' specifies which columns
  # are to be used for feature values.  The first row of the CSV file must specify
  # the names of the features.  See examples of CSV files in the `Examples'
  # subdirectory.

  # The option `symbolic_to_numeric_cardinality_threshold' is also important.  For
  # the example shown above, if an ostensibly numeric feature takes on only 10 or
  # fewer different values in your training datafile, it will be treated like a
  # symbolic features.  The option `entropy_threshold' determines the granularity
  # with which the entropies are sampled for the purpose of calculating entropy gain
  # with a particular choice of decision threshold for a numeric feature or a feature
  # value for a symbolic feature.

  # The option 'csv_cleanup_needed' is by default set to 0.  If you set it
  # to 1, that would cause all line records in your CSV file to be "sanitized" before
  # they are used for constructing a decision tree.  You need this option if your CSV
  # file uses double-quoted field names and field values in the line records and if
  # such double-quoted strings are allowed to include commas for, presumably, better
  # readability.

  # After you have constructed an instance of the DecisionTree class as shown above,
  # you read in the training data file and initialize the probability cache by
  # calling:

      $dt->get_training_data();
      $dt->calculate_first_order_probabilities();
      $dt->calculate_class_priors();

  # Next you construct a decision tree for your training data by calling:

      $root_node = $dt->construct_decision_tree_classifier();

  # where $root_node is an instance of the DTNode class that is also defined in the
  # module file.  Now you are ready to classify a new data record.  Let's say that
  # your data record looks like:

      my @test_sample  = qw /  g2=4.2
                               grade=2.3
                               gleason=4
                               eet=1.7
                               age=55.0
                               ploidy=diploid /;

  # You can classify it by calling:

      my $classification = $dt->classify($root_node, \@test_sample);

  # The call to `classify()' returns a reference to a hash whose keys are the class
  # names and the values the associated classification probabilities.  This hash also
  # includes another key-value pair for the solution path from the root node to the
  # leaf node at which the final classification was carried out.


=head1 CHANGES

B<Version 3.42:> This version reintroduces C<csv_cleanup_needed> as an optional
parameter in the module constructor.  This was done in response to several requests
received from the user community. (Previously, all line records from a CSV file were
processed by the C<cleanup_csv()> function no matter what.)  The main point made by
the users was that invoking C<cleanup_csv()> when there was no need for CSV clean-up
extracted a performance penalty when ingesting large database files with tens of
thousands of line records.  In addition to making C<csv_cleanup_needed> optional, I
have also tweaked up the code in the C<cleanup_csv()> function in order to extract
data from a larger range of messy CSV files.

B<Version 3.41:> All the changes made in this version relate to the construction of
regression trees.  I have fixed a couple of bugs in the calculation of the regression
coefficients. Additionally, the C<RegressionTree> class now comes with a new
constructor parameter named C<jacobian_choice>.  For most cases, you'd set this
parameter to 0, which causes the regression coefficients to be estimated through
linear least-squares minimization.

B<Version 3.40:> In addition to constructing decision trees, this version of the
module also allows you to construct regression trees. The regression tree capability
has been packed into a separate subclass, named C<RegressionTree>, of the main
C<DecisionTree> class.  The subdirectory C<ExamplesRegression> in the main
installation directory illustrates how you can use this new functionality of the
module.

B<Version 3.30:> This version incorporates four very significant upgrades/changes to
the C<DecisionTree> module: B<(1)> The CSV cleanup is now the default. So you do not
have to set any special parameters in the constructor calls to initiate CSV
cleanup. B<(2)> In the form of a new Perl class named C<RandomizedTreesForBigData>,
this module provides you with an easy-to-use programming interface for attempting
needle-in-a-haystack solutions for the case when your training data is overwhelmingly
dominated by a single class.  You need to set the constructor parameter
C<looking_for_needles_in_haystack> to invoke the logic that constructs multiple
decision trees, each using the minority class samples along with samples drawn
randomly from the majority class.  The final classification is made through a
majority vote from all the decision trees.  B<(3)> Assuming you are faced with a
big-data problem --- in the sense that you have been given a training database with a
very large number of training records --- the class C<RandomizedTreesForBigData> will
also let you construct multiple decision trees by pulling training data randomly from
your training database (without paying attention to the relative populations of the
classes).  The final classification decision for a test sample is based on a majority
vote from all the decision trees thus constructed.  See the C<ExamplesRandomizedTrees>
directory for how to use these new features of the module. And, finally, B<(4)>
Support for the old-style '.dat' training files has been dropped in this version.

B<Version 3.21:> This version makes it easier to use a CSV training file that
violates the assumption that a comma be used only to separate the different field
values in a line record.  Some large econometrics databases use double-quoted values
for fields, and these values may contain commas (presumably for better readability).
This version also allows you to specify the leftmost entry in the first CSV record
that names all the fields. Previously, this entry was required to be an empty
double-quoted string.  I have also made some minor changes to the
'C<get_training_data_from_csv()>' method to make it more user friendly for large
training files that may contain tens of thousands of records.  When pulling training
data from such files, this method prints out a dot on the terminal screen for every
10000 records it has processed. 

B<Version 3.20:> This version brings the boosting capability to the C<DecisionTree>
module.

B<Version 3.0:> This version adds bagging to the C<DecisionTree> module. If your
training dataset is large enough, you can ask the module to construct multiple
decision trees using data bags extracted from your dataset.  The module can show you
the results returned by the individual decision trees and also the results obtained
by taking a majority vote of the classification decisions made by the individual
trees.  You can specify any arbitrary extent of overlap between the data bags.

B<Version 2.31:> The introspection capability in this version packs more of a punch.
For each training data sample, you can now figure out not only the decision-tree
nodes that are affected directly by that sample, but also those nodes that are
affected indirectly through the generalization achieved by the probabilistic modeling
of the data.  The 'examples' directory of this version includes additional scripts
that illustrate these enhancements to the introspection capability.  See the section
"The Introspection API" for a declaration of the introspection related methods, old
and new.

B<Version 2.30:> In response to requests from several users, this version includes a new
capability: You can now ask the module to introspect about the classification
decisions returned by the decision tree.  Toward that end, the module includes a new
class named C<DTIntrospection>.  Perhaps the most important bit of information you
are likely to seek through DT introspection is the list of the training samples that
fall directly in the portion of the feature space that is assigned to a node.
B<CAVEAT:> When training samples are non-uniformly distributed in the underlying
feature space, IT IS POSSIBLE FOR A NODE TO EXIST EVEN WHEN NO TRAINING SAMPLES FALL
IN THE PORTION OF THE FEATURE SPACE ASSIGNED TO THE NODE.  B<(This is an important
part of the generalization achieved by probabilistic modeling of the training data.)>
For additional information related to DT introspection, see the section titled
"DECISION TREE INTROSPECTION" in this documentation page.

B<Version 2.27> makes the logic of tree construction from the old-style '.dat' training
files more consistent with how trees are constructed from the data in `.csv' files.
The inconsistency in the past was with respect to the naming convention for the class
labels associated with the different data records.

B<Version 2.26> fixes a bug in the part of the module that some folks use for generating
synthetic data for experimenting with decision tree construction and classification.
In the class C<TrainingDataGeneratorNumeric> that is a part of the module, there
was a problem with the order in which the features were recorded from the
user-supplied parameter file.  The basic code for decision tree construction and
classification remains unchanged.

B<Version 2.25> further downshifts the required version of Perl for this module.  This
was a result of testing the module with Version 5.10.1 of Perl.  Only one statement
in the module code needed to be changed for the module to work with the older version
of Perl.

B<Version 2.24> fixes the C<Makefile.PL> restriction on the required Perl version.  This
version should work with Perl versions 5.14.0 and higher.

B<Version 2.23> changes the required version of Perl from 5.18.0 to 5.14.0.  Everything
else remains the same.

B<Version 2.22> should prove more robust when the probability distribution for the
values of a feature is expected to be heavy-tailed; that is, when the supposedly rare
observations can occur with significant probabilities.  A new option in the
DecisionTree constructor lets the user specify the precision with which the
probability distributions are estimated for such features.

B<Version 2.21> fixes a bug that was caused by the explicitly set zero values for
numerical features being misconstrued as "false" in the conditional statements in
some of the method definitions.

B<Version 2.2> makes it easier to write code for classifying in one go all of your test
data samples in a CSV file.  The bulk classifications obtained can be written out to
either a CSV file or to a regular text file.  See the script
C<classify_test_data_in_a_file_numeric.pl> in the C<Examples> directory for how to
classify all of your test data records in a CSV file.  This version also includes
improved code for generating synthetic numeric/symbolic training and test data
records for experimenting with the decision tree classifier.

B<Version 2.1> allows you to test the quality of your training data by running a 10-fold
cross-validation test on the data.  This test divides all of the training data into
ten parts, with nine parts used for training a decision tree and one part used for
testing its ability to classify correctly. This selection of nine parts for training
and one part for testing is carried out in all of the ten different ways that are
possible.  This testing functionality in Version 2.1 can also be used to find the
best values to use for the constructor parameters C<entropy_threshold>,
C<max_depth_desired>, and C<symbolic_to_numeric_cardinality_threshold>.

B<Version 2.0 is a major rewrite of this module.> Now you can use both numeric and
symbolic features for constructing a decision tree. A feature is numeric if it can
take any floating-point value over an interval.

B<Version 1.71> fixes a bug in the code that was triggered by 0 being declared as one of
the features values in the training datafile. Version 1.71 also include an additional
safety feature that is useful for training datafiles that contain a very large number
of features.  The new version makes sure that the number of values you declare for
each sample record matches the number of features declared at the beginning of the
training datafile.

B<Version 1.7> includes safety checks on the consistency of the data you place in your
training datafile. When a training file contains thousands of samples, it is
difficult to manually check that you used the same class names in your sample records
that you declared at top of your training file or that the values you have for your
features are legal vis-a-vis the earlier declarations of the values in the training
file.  Another safety feature incorporated in this version is the non-consideration
of classes that are declared at the top of the training file but that have no sample
records in the file.

B<Version 1.6> uses probability caching much more extensively compared to the previous
versions.  This should result in faster construction of large decision trees.
Another new feature in Version 1.6 is the use of a decision tree for interactive
classification. In this mode, after you have constructed a decision tree from the
training data, the user is prompted for answers to the questions pertaining to the
feature tests at the nodes of the tree.

Some key elements of the documentation were cleaned up and made more readable in
B<Version 1.41>.  The implementation code remains unchanged from Version 1.4.

B<Version 1.4> should make things faster (and easier) for folks who want to use this
module with training data that creates very large decision trees (that is, trees with
tens of thousands or more decision nodes).  The speedup in Version 1.4 has been
achieved by eliminating duplicate calculation of probabilities as the tree grows.  In
addition, this version provides an additional constructor parameter,
C<max_depth_desired> for controlling the size of the decision tree.  This is in
addition to the tree size control achieved by the parameter C<entropy_threshold> that
was introduced in Version 1.3.  Since large decision trees can take a long time to
create, you may find yourself wishing you could store the tree you just created in a
disk file and that, subsequently, you could use the stored tree for classification
work.  The C<Examples> directory contains two scripts, C<store_dt_on_disk.pl> and
C<classify_from_disk_stored_dt.pl>, that show how you can do exactly that with the
help of Perl's C<Storable> module.

B<Version 1.3> addresses the issue that arises when the header of a training datafile
declares a certain possible value for a feature but that (feature,value) pair does
NOT show up anywhere in the training data.  Version 1.3 also makes it possible for a
user to control the size of the decision tree by changing the value of the parameter
C<entropy_threshold.> Additionally, Version 1.3 includes a method called
C<determine_data_condition()> that displays useful information regarding the size and
some other attributes of the training data.  It also warns the user if the training
data might result in a decision tree that would simply be much too large --- unless
the user controls the size with the entropy_threshold parameter.

In addition to the removal of a couple of serious bugs, B<version 1.2> incorporates a
number of enhancements: (1) Version 1.2 includes checks on the names of the features
and values used in test data --- this is the data you want to classify with the
decision tree classifier constructed by this module.  (2) Version 1.2 includes a
separate constructor for generating test data.  To make it easier to generate test
data whose probabilistic parameters may not be identical to that used for the
training data, I have used separate routines for generating the test data.  (3)
Version 1.2 also includes in its examples directory a script that classifies the test
data in a file and outputs the class labels into another file.  This is for folks who
do not wish to write their own scripts using this module. (4) Version 1.2 also
includes addition to the documentation regarding the issue of numeric values for
features.

=head1 DESCRIPTION

B<Algorithm::DecisionTree> is a I<perl5> module for constructing a decision tree from
a training datafile containing multidimensional data.  In one form or another,
decision trees have been around for about fifty years.  From a statistical
perspective, they are closely related to classification and regression by recursive
partitioning of multidimensional data.  Early work that demonstrated the usefulness
of such partitioning of data for classification and regression can be traced to the
work of Terry Therneau in the early 1980's in the statistics community, and to the
work of Ross Quinlan in the mid 1990's in the machine learning community.

For those not familiar with decision tree ideas, the traditional way to classify
multidimensional data is to start with a feature space whose dimensionality is the
same as that of the data.  Each feature in this space corresponds to the attribute
that each dimension of the data measures.  You then use the training data to carve up
the feature space into different regions, each corresponding to a different class.
Subsequently, when you try to classify a new data sample, you locate it in the
feature space and find the class label of the region to which it belongs.  One can
also give the new data point the same class label as that of the nearest training
sample. This is referred to as the nearest neighbor classification.  There exist
hundreds of variations of varying power on these two basic approaches to the
classification of multidimensional data.

A decision tree classifier works differently.  When you construct a decision tree,
you select for the root node a feature test that partitions the training data in a
way that causes maximal disambiguation of the class labels associated with the data.
In terms of information content as measured by entropy, such a feature test would
cause maximum reduction in class entropy in going from all of the training data taken
together to the data as partitioned by the feature test.  You then drop from the root
node a set of child nodes, one for each partition of the training data created by the
feature test at the root node. When your features are purely symbolic, you'll have
one child node for each value of the feature chosen for the feature test at the root.
When the test at the root involves a numeric feature, you find the decision threshold
for the feature that best bipartitions the data and you drop from the root node two
child nodes, one for each partition.  Now at each child node you pose the same
question that you posed when you found the best feature to use at the root: Which
feature at the child node in question would maximally disambiguate the class labels
associated with the training data corresponding to that child node?

As the reader would expect, the two key steps in any approach to decision-tree based
classification are the construction of the decision tree itself from a file
containing the training data, and then using the decision tree thus obtained for
classifying new data.

What is cool about decision tree classification is that it gives you soft
classification, meaning it may associate more than one class label with a given data
vector.  When this happens, it may mean that your classes are indeed overlapping in
the underlying feature space.  It could also mean that you simply have not supplied
sufficient training data to the decision tree classifier.  For a tutorial
introduction to how a decision tree is constructed and used, visit
L<https://engineering.purdue.edu/kak/Tutorials/DecisionTreeClassifiers.pdf>

This module also allows you to generate your own synthetic training and test
data. Generating your own training data, using it for constructing a decision-tree
classifier, and subsequently testing the classifier on a synthetically generated
test set of data is a good way to develop greater proficiency with decision trees.


=head1 WHAT PRACTICAL PROBLEM IS SOLVED BY THIS MODULE

If you are new to the concept of a decision tree, their practical utility is best
understood with an example that only involves symbolic features. However, as
mentioned earlier, versions of the module higher than 2.0 allow you to use both
symbolic and numeric features.

Consider the following scenario: Let's say you are running a small investment company
that employs a team of stockbrokers who make buy/sell decisions for the customers of
your company.  Assume that your company has asked the traders to make each investment
decision on the basis of the following four criteria:

  price_to_earnings_ratio   (P_to_E)

  price_to_sales_ratio      (P_to_S)

  return_on_equity          (R_on_E)

  market_share              (MS)

Since you are the boss, you keep track of the buy/sell decisions made by the
individual traders.  But one unfortunate day, all of your traders decide to quit
because you did not pay them enough.  So what do you do?  If you had a module like
the one here, you could still run your company and do so in such a way that, on the
average, would do better than any of the individual traders who worked for your
company.  This is what you do: You pool together the individual trader buy/sell
decisions you have accumulated during the last one year.  This pooled information is
likely to look like:


  example      buy/sell     P_to_E     P_to_S     R_on_E      MS
  ============================================================+=

  example_1     buy          high       low        medium    low
  example_2     buy          medium     medium     low       low
  example_3     sell         low        medium     low       high
  ....
  ....

This data, when formatted according to CSV, would constitute your training file. You
could feed this file into the module by calling:

    my $dt = Algorithm::DecisionTree->new( 
                     training_datafile => $training_datafile,
                     csv_class_column_index => 1,
                     csv_columns_for_features => [2,3,4,5],
             );
    $dt->get_training_data(); 
    $dt->calculate_first_order_probabilities();
    $dt->calculate_class_priors();

Subsequently, you would construct a decision tree by calling:

    my $root_node = $dt->construct_decision_tree_classifier();

Now you and your company (with practically no employees) are ready to service the
customers again. Suppose your computer needs to make a buy/sell decision about an
investment prospect that is best described by:

    price_to_earnings_ratio  =  low
    price_to_sales_ratio     =  very_low
    return_on_equity         =  none
    market_share             =  medium    

All that your computer would need to do would be to construct a data vector like

   my @data =   qw / P_to_E=low
                     P_to_S=very_low
                     R_on_E=none
                     MS=medium /;

and call the decision tree classifier you just constructed by

    $dt->classify($root_node, \@data); 

The answer returned will be 'buy' and 'sell', along with the associated
probabilities.  So if the probability of 'buy' is considerably greater than the
probability of 'sell', that's what you should instruct your computer to do.

The chances are that, on the average, this approach would beat the performance of any
of your individual traders who worked for you previously since the buy/sell decisions
made by the computer would be based on the collective wisdom of all your previous
traders.  B<DISCLAIMER: There is obviously a lot more to good investing than what is
captured by the silly little example here. However, it does nicely the convey the
sense in which the current module could be used.>

=head1 SYMBOLIC FEATURES VERSUS NUMERIC FEATURES

A feature is symbolic when its values are compared using string comparison operators.
By the same token, a feature is numeric when its values are compared using numeric
comparison operators.  Having said that, features that take only a small number of
numeric values in the training data can be treated symbolically provided you are
careful about handling their values in the test data.  At the least, you have to set
the test data value for such a feature to its closest value in the training data.
The module does that automatically for you for those numeric features for which the
number different numeric values is less than a user-specified threshold.  For those
numeric features that the module is allowed to treat symbolically, this snapping of
the values of the features in the test data to the small set of values in the training
data is carried out automatically by the module.  That is, after a user has told the
module which numeric features to treat symbolically, the user need not worry about
how the feature values appear in the test data.

The constructor parameter C<symbolic_to_numeric_cardinality_threshold> let's you tell
the module when to consider an otherwise numeric feature symbolically. Suppose you
set this parameter to 10, that means that all numeric looking features that take 10
or fewer different values in the training datafile will be considered to be symbolic
features by the module.  See the tutorial at
L<https://engineering.purdue.edu/kak/Tutorials/DecisionTreeClassifiers.pdf> for
further information on the implementation issues related to the symbolic and numeric
features.

=head1 FEATURES WITH NOT SO "NICE" STATISTICAL PROPERTIES

For the purpose of estimating the probabilities, it is necessary to sample the range
of values taken on by a numerical feature. For features with "nice" statistical
properties, this sampling interval is set to the median of the differences between
the successive feature values in the training data.  (Obviously, as you would expect,
you first sort all the values for a feature before computing the successive
differences.)  This logic will not work for the sort of a feature described below.

Consider a feature whose values are heavy-tailed, and, at the same time, the values
span a million to one range.  What I mean by heavy-tailed is that rare values can
occur with significant probabilities.  It could happen that most of the values for
such a feature are clustered at one of the two ends of the range. At the same time,
there may exist a significant number of values near the end of the range that is less
populated.  (Typically, features related to human economic activities --- such as
wealth, incomes, etc. --- are of this type.)  With the logic described in the
previous paragraph, you could end up with a sampling interval that is much too small,
which could result in millions of sampling points for the feature if you are not
careful.

Beginning with Version 2.22, you have two options in dealing with such features.  You
can choose to go with the default behavior of the module, which is to sample the
value range for such a feature over a maximum of 500 points.  Or, you can supply an
additional option to the constructor that sets a user-defined value for the number of
points to use.  The name of the option is C<number_of_histogram_bins>.  The following
script 

    construct_dt_for_heavytailed.pl 

in the C<Examples> directory shows an example of how to call the constructor of the
module with the C<number_of_histogram_bins> option.


=head1 TESTING THE QUALITY OF YOUR TRAINING DATA

Versions 2.1 and higher include a new class named C<EvalTrainingData>, derived from
the main class C<DecisionTree>, that runs a 10-fold cross-validation test on your
training data to test its ability to discriminate between the classes mentioned in
the training file.

The 10-fold cross-validation test divides all of the training data into ten parts,
with nine parts used for training a decision tree and one part used for testing its
ability to classify correctly. This selection of nine parts for training and one part
for testing is carried out in all of the ten different possible ways.

The following code fragment illustrates how you invoke the testing function of the
EvalTrainingData class:

    my $training_datafile = "training.csv";                                         
    my $eval_data = EvalTrainingData->new(
                                  training_datafile => $training_datafile,
                                  csv_class_column_index => 1,
                                  csv_columns_for_features => [2,3],
                                  entropy_threshold => 0.01,
                                  max_depth_desired => 3,
                                  symbolic_to_numeric_cardinality_threshold => 10,
                                  csv_cleanup_needed => 1,
                    );
    $eval_data->get_training_data();
    $eval_data->evaluate_training_data()

The last statement above prints out a Confusion Matrix and the value of Training Data
Quality Index on a scale of 0 to 100, with 100 designating perfect training data.
The Confusion Matrix shows how the different classes were mislabeled in the 10-fold
cross-validation test.

This testing functionality can also be used to find the best values to use for the
constructor parameters C<entropy_threshold>, C<max_depth_desired>, and
C<symbolic_to_numeric_cardinality_threshold>.

The following two scripts in the C<Examples> directory illustrate the use of the
C<EvalTrainingData> class for testing the quality of your data:

    evaluate_training_data1.pl
    evaluate_training_data2.pl


=head1 HOW TO MAKE THE BEST CHOICES FOR THE CONSTRUCTOR PARAMETERS

Assuming your training data is good, the quality of the results you get from a
decision tree would depend on the choices you make for the constructor parameters
C<entropy_threshold>, C<max_depth_desired>, and
C<symbolic_to_numeric_cardinality_threshold>.  You can optimize your choices for
these parameters by running the 10-fold cross-validation test that is made available
in Versions 2.2 and higher through the new class C<EvalTrainingData> that is included
in the module file.  A description of how to run this test is in the previous section
of this document.


=head1 DECISION TREE INTROSPECTION

Starting with Version 2.30, you can ask the C<DTIntrospection> class of the module to
explain the classification decisions made at the different nodes of the decision
tree.

Perhaps the most important bit of information you are likely to seek through DT
introspection is the list of the training samples that fall directly in the portion
of the feature space that is assigned to a node.

However, note that, when training samples are non-uniformly distributed in the
underlying feature space, it is possible for a node to exist even when there are no
training samples in the portion of the feature space assigned to the node.  That is
because the decision tree is constructed from the probability densities estimated
from the training data.  When the training samples are non-uniformly distributed, it
is entirely possible for the estimated probability densities to be non-zero in a
small region around a point even when there are no training samples specifically in
that region.  (After you have created a statistical model for, say, the height
distribution of people in a community, the model may return a non-zero probability
for the height values in a small interval even if the community does not include a
single individual whose height falls in that interval.)

That a decision-tree node can exist even when there are no training samples in that
portion of the feature space that belongs to the node is an important indication of
the generalization ability of a decision-tree-based classifier.

In light of the explanation provided above, before the DTIntrospection class supplies
any answers at all, it asks you to accept the fact that features can take on non-zero
probabilities at a point in the feature space even though there are zero training
samples at that point (or in a small region around that point).  If you do not accept
this rudimentary fact, the introspection class will not yield any answers (since you
are not going to believe the answers anyway).

The point made above implies that the path leading to a node in the decision tree may
test a feature for a certain value or threshold despite the fact that the portion of
the feature space assigned to that node is devoid of any training data.

See the following three scripts in the Examples directory for how to carry out DT
introspection:

    introspection_in_a_loop_interactive.pl

    introspection_show_training_samples_at_all_nodes_direct_influence.pl

    introspection_show_training_samples_to_nodes_influence_propagation.pl

The first script places you in an interactive session in which you will first be
asked for the node number you are interested in.  Subsequently, you will be asked for
whether or not you are interested in specific questions that the introspection can
provide answers for. The second script descends down the decision tree and shows for
each node the training samples that fall directly in the portion of the feature space
assigned to that node.  The third script shows for each training sample how it
affects the decision-tree nodes either directly or indirectly through the
generalization achieved by the probabilistic modeling of the data.

The output of the script
C<introspection_show_training_samples_at_all_nodes_direct_influence.pl> looks like:

    Node 0: the samples are: None
    Node 1: the samples are: [sample_46 sample_58]
    Node 2: the samples are: [sample_1 sample_4 sample_7 .....]
    Node 3: the samples are: []
    Node 4: the samples are: []
    ...
    ...            

The nodes for which no samples are listed come into existence through
the generalization achieved by the probabilistic modeling of the data.

The output produced by the script
C<introspection_show_training_samples_to_nodes_influence_propagation.pl> looks like

    sample_1:                                                                 
       nodes affected directly: [2 5 19 23]                                
       nodes affected through probabilistic generalization:                   
            2=> [3 4 25]                                                    
                25=> [26]                                                     
            5=> [6]                                                           
                6=> [7 13]                                                   
                    7=> [8 11]                                               
                        8=> [9 10]                                           
                        11=> [12]                                             
                    13=> [14 18]                                             
                        14=> [15 16]                                         
                            16=> [17]                                         
            19=> [20]                                                         
                20=> [21 22]                                                 
            23=> [24]                                                         
                             
    sample_4:                                                                 
       nodes affected directly: [2 5 6 7 11]                              
       nodes affected through probabilistic generalization:                   
            2=> [3 4 25]                                                    
                25=> [26]                                                     
            5=> [19]                                                          
                19=> [20 23]                                                 
                    20=> [21 22]                                             
                    23=> [24]                                                 
            6=> [13]                                                          
                13=> [14 18]                                                 
                    14=> [15 16]                                             
                        16=> [17]                                             
            7=> [8]                                                           
                8=> [9 10]                                                   
            11=> [12]                                                         
                                                                              
    ...                                                                       
    ...  
    ...

For each training sample, the display shown above first presents the list of nodes
that are directly affected by the sample.  A node is affected directly by a sample if
the latter falls in the portion of the feature space that belongs to the former.
Subsequently, for each training sample, the display shows a subtree of the nodes that
are affected indirectly by the sample through the generalization achieved by the
probabilistic modeling of the data.  In general, a node is affected indirectly by a
sample if it is a descendant of another node that is affected directly.

Also see the section titled B<The Introspection API> regarding how to invoke the
introspection capabilities of the module in your own code.

=head1 METHODS

The module provides the following methods for constructing a decision tree from
training data in a disk file and for classifying new data records with the decision
tree thus constructed:

=over 4

=item B<new():>

    my $dt = Algorithm::DecisionTree->new( 
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              csv_cleanup_needed => 1,
            );

A call to C<new()> constructs a new instance of the C<Algorithm::DecisionTree> class.
For this call to make sense, the training data in the training datafile must be
in the CSV format.  

=back

=head2 The Constructor Parameters

=over 8

=item C<training_datafile>:

This parameter supplies the name of the file that contains the training data.

=item C<csv_class_column_index>:

When using a CSV file for your training data, this parameter supplies the zero-based
column index for the column that contains the class label for each data record in the
training file.


=item C<csv_cleanup_needed>:

You need to set this parameter to 1 if your CSV file has double quoted strings (which
may include commas) as values for the fields and if such values are allowed to
include commas for, presumably, better readability.

=item C<csv_columns_for_features>:

When using a CSV file for your training data, this parameter supplies a list of
columns corresponding to the features you wish to use for decision tree construction.
Each column is specified by its zero-based index.

=item C<entropy_threshold>:

This parameter sets the granularity with which the entropies are sampled by the
module.  For example, a feature test at a node in the decision tree is acceptable if
the entropy gain achieved by the test exceeds this threshold.  The larger the value
you choose for this parameter, the smaller the tree.  Its default value is 0.001.

=item C<max_depth_desired>:

This parameter sets the maximum depth of the decision tree.  For obvious reasons, the
smaller the value you choose for this parameter, the smaller the tree.

=item C<symbolic_to_numeric_cardinality_threshold>:

This parameter allows the module to treat an otherwise numeric feature symbolically
if the number of different values the feature takes in the training data file does
not exceed the value of this parameter.

=item C<number_of_histogram_bins>:

This parameter gives the user the option to set the number of points at which the
value range for a feature should be sampled for estimating the probabilities.  This
parameter is effective only for those features that occupy a large value range and
whose probability distributions are heavy tailed.  B<This parameter is also important
when you have a very large training dataset:> In general, the larger the dataset, the
smaller the smallest difference between any two values for a numeric feature in
relation to the overall range of values for that feature. In such cases, the module
may use too large a number of bins for estimating the probabilities and that may slow
down the calculation of the decision tree.  You can get around this difficulty by
explicitly giving a value to the 'C<number_of_histogram_bins>' parameter.

=back


You can choose the best values to use for the last three constructor parameters by
running a 10-fold cross-validation test on your training data through the class
C<EvalTrainingData> that comes with Versions 2.1 and higher of this module.  See the
section "TESTING THE QUALITY OF YOUR TRAINING DATA" of this document page.

=over

=item B<get_training_data():>

After you have constructed a new instance of the C<Algorithm::DecisionTree> class,
you must now read in the training data that is the file named in the call to the
constructor.  This you do by:

    $dt->get_training_data(); 


=item B<show_training_data():>

If you wish to see the training data that was just digested by the module,
call 

    $dt->show_training_data(); 

=item B<calculate_first_order_probabilities():>

=item B<calculate_class_priors():>

After the module has read the training data file, it needs to initialize the
probability cache.  This you do by invoking:

    $dt->calculate_first_order_probabilities()
    $dt->calculate_class_priors() 

=item B<construct_decision_tree_classifier():>

With the probability cache initialized, it is time to construct a decision tree
classifier.  This you do by

    my $root_node = $dt->construct_decision_tree_classifier();

This call returns an instance of type C<DTNode>.  The C<DTNode> class is defined
within the main package file.  So, don't forget, that C<$root_node> in the above
example call will be instantiated to an object of type C<DTNode>.

=item B<$root_nodeC<< -> >>display_decision_tree(" "):>

    $root_node->display_decision_tree("   ");

This will display the decision tree in your terminal window by using a recursively
determined offset for each node as the display routine descends down the tree.

I have intentionally left the syntax fragment C<$root_node> in the above call to
remind the reader that C<display_decision_tree()> is NOT called on the instance of
the C<DecisionTree> we constructed earlier, but on the C<DTNode> instance returned by
the call to C<construct_decision_tree_classifier()>.

=item B<classify($root_node, \@test_sample):>

Let's say you want to classify the following data record:

    my @test_sample  = qw /  g2=4.2
                             grade=2.3
                             gleason=4
                             eet=1.7
                             age=55.0
                             ploidy=diploid /;

you'd make the following call:

    my $classification = $dt->classify($root_node, \@test_sample);

where, again, C<$root_node> is an instance of type C<DTNode> returned by the call to
C<construct_decision_tree_classifier()>.  The variable C<$classification> holds a
reference to a hash whose keys are the class names and whose values the associated
probabilities.  The hash that is returned by the above call also includes a special
key-value pair for a key named C<solution_path>.  The value associated with this key
is an anonymous array that holds the path, in the form of a list of nodes, from the
root node to the leaf node in the decision tree where the final classification was
made.


=item B<classify_by_asking_questions($root_node):>

This method allows you to use a decision-tree based classifier in an interactive
mode.  In this mode, a user is prompted for answers to the questions pertaining to
the feature tests at the nodes of the tree.  The syntax for invoking this method is:

    my $classification = $dt->classify_by_asking_questions($root_node);

where C<$dt> is an instance of the C<Algorithm::DecisionTree> class returned by a
call to C<new()> and C<$root_node> the root node of the decision tree returned by a
call to C<construct_decision_tree_classifier()>.

=back


=head1 THE INTROSPECTION API

To construct an instance of C<DTIntrospection>, you call

    my $introspector = DTIntrospection->new($dt);

where you supply the instance of the C<DecisionTree> class you used for constructing
the decision tree through the parameter C<$dt>.  After you have constructed an
instance of the introspection class, you must initialize it by

    $introspector->initialize();

Subsequently, you can invoke either of the following methods:

    $introspector->explain_classification_at_one_node($node);

    $introspector->explain_classifications_at_multiple_nodes_interactively();

depending on whether you want introspection at a single specified node or inside an
infinite loop for an arbitrary number of nodes.

If you want to output a tabular display that shows for each node in the decision tree
all the training samples that fall in the portion of the feature space that belongs
to that node, call

    $introspector->display_training_samples_at_all_nodes_direct_influence_only();

If you want to output a tabular display that shows for each training sample a list of
all the nodes that are affected directly AND indirectly by that sample, call

    $introspector->display_training_training_samples_to_nodes_influence_propagation();

A training sample affects a node directly if the sample falls in the portion of the
features space assigned to that node. On the other hand, a training sample is
considered to affect a node indirectly if the node is a descendant of a node that is
affected directly by the sample.


=head1 BULK CLASSIFICATION OF DATA RECORDS

For large test datasets, you would obviously want to process an entire file of test
data at a time. The following scripts in the C<Examples> directory illustrate how you
can do that:

      classify_test_data_in_a_file.pl

This script requires three command-line arguments, the first argument names the
training datafile, the second the test datafile, and the third the file in which the
classification results are to be deposited.  

The other examples directories, C<ExamplesBagging>, C<ExamplesBoosting>, and
C<ExamplesRandomizedTrees>, also contain scripts that illustrate how to carry out
bulk classification of data records when you wish to take advantage of bagging,
boosting, or tree randomization.  In their respective directories, these scripts are
named:

    bagging_for_bulk_classification.pl
    boosting_for_bulk_classification.pl
    classify_database_records.pl


=head1 HOW THE CLASSIFICATION RESULTS ARE DISPLAYED

It depends on whether you apply the classifier at once to all the data samples in a
file, or whether you feed one data sample at a time into the classifier.

In general, the classifier returns soft classification for a test data vector.  What
that means is that, in general, the classifier will list all the classes to which a
given data vector could belong and the probability of each such class label for the
data vector. Run the examples scripts in the Examples directory to see how the output
of classification can be displayed.

With regard to the soft classifications returned by this classifier, if the
probability distributions for the different classes overlap in the underlying feature
space, you would want the classifier to return all of the applicable class labels for
a data vector along with the corresponding class probabilities.  Another reason for
why the decision tree classifier may associate significant probabilities with
multiple class labels is that you used inadequate number of training samples to
induce the decision tree.  The good thing is that the classifier does not lie to you
(unlike, say, a hard classification rule that would return a single class label
corresponding to the partitioning of the underlying feature space).  The decision
tree classifier give you the best classification that can be made given the training
data you fed into it.


=head1 USING BAGGING

Starting with Version 3.0, you can use the class C<DecisionTreeWithBagging> that
comes with the module to incorporate bagging in your decision tree based
classification.  Bagging means constructing multiple decision trees for different
(possibly overlapping) segments of the data extracted from your training dataset and
then aggregating the decisions made by the individual decision trees for the final
classification.  The aggregation of the classification decisions can average out the
noise and bias that may otherwise affect the classification decision obtained from
just one tree.

=over 4

=item B<Calling the bagging constructor::>

A typical call to the constructor for the C<DecisionTreeWithBagging> class looks
like:

    use Algorithm::DecisionTreeWithBagging;
    
    my $training_datafile = "stage3cancer.csv";
    
    my $dtbag = Algorithm::DecisionTreeWithBagging->new(
                                  training_datafile => $training_datafile,
                                  csv_class_column_index => 2,
                                  csv_columns_for_features => [3,4,5,6,7,8],
                                  entropy_threshold => 0.01,
                                  max_depth_desired => 8,
                                  symbolic_to_numeric_cardinality_threshold => 10,
                                  how_many_bags => 4,
                                  bag_overlap_fraction => 0.2,
                                  csv_cleanup_needed => 1,
                 );
    
Note in particular the following two constructor parameters:
                                                                                               
    how_many_bags

    bag_overlap_fraction

where, as the name implies, the parameter C<how_many_bags> controls how many bags
(and, therefore, how many decision trees) will be constructed from your training
dataset; and where the parameter C<bag_overlap_fraction> controls the degree of
overlap between the bags.  To understand what exactly is achieved by setting the
parameter C<bag_overlap_fraction> to 0.2 in the above example, let's say that the
non-overlapping partitioning of the training data between the bags results in 100
training samples per bag. With bag_overlap_fraction set to 0.2, additional 20 samples
drawn randomly from the other bags will be added to the data in each bag.

=back

=head2 B<Methods defined for C<DecisionTreeWithBagging> class>

=over 8

=item B<get_training_data_for_bagging():>

This method reads your training datafile, randomizes it, and then partitions it into
the specified number of bags.  Subsequently, if the constructor parameter
C<bag_overlap_fraction> is non-zero, it adds to each bag additional samples drawn at
random from the other bags.  The number of these additional samples added to each bag
is controlled by the constructor parameter C<bag_overlap_fraction>.  If this
parameter is set to, say, 0.2, the size of each bag will grow by 20% with the samples
drawn from the other bags.

=item B<show_training_data_in_bags():>

Shows for each bag the names of the training data samples in that bag.

=item B<calculate_first_order_probabilities():>

Calls on the appropriate methods of the main C<DecisionTree> class to estimate the
first-order probabilities from the data samples in each bag.

=item B<calculate_class_priors():>

Calls on the appropriate method of the main C<DecisionTree> class to estimate the
class priors for the data samples in each bag.

=item B<construct_decision_trees_for_bags():>

Calls on the appropriate method of the main C<DecisionTree> class to construct a
decision tree from the training data in each bag.

=item B<display_decision_trees_for_bags():>

Display separately the decision tree for each bag..

=item B<classify_with_bagging( test_sample ):>

Calls on the appropriate methods of the main C<DecisionTree> class to classify the
argument test sample.

=item B<display_classification_results_for_each_bag():>

Displays separately the classification decision made by each the decision tree
constructed for each bag.

=item B<get_majority_vote_classification():>

Using majority voting, this method aggregates the classification decisions made by
the individual decision trees into a single decision.

=back

See the example scripts in the directory C<bagging_examples> for how to call these
methods for classifying individual samples and for bulk classification when you place
all your test samples in a single file.

=head1 USING BOOSTING

Starting with Version 3.20, you can use the class C<BoostedDecisionTree> for
constructing a boosted decision-tree classifier.  Boosting results in a cascade of
decision trees in which each decision tree is constructed with samples that are
mostly those that are misclassified by the previous decision tree.  To be precise,
you create a probability distribution over the training samples for the selection of
samples for training each decision tree in the cascade.  To start out, the
distribution is uniform over all of the samples. Subsequently, this probability
distribution changes according to the misclassifications by each tree in the cascade:
if a sample is misclassified by a given tree in the cascade, the probability of its
being selected for training the next tree is increased significantly.  You also
associate a trust factor with each decision tree depending on its power to classify
correctly all of the training data samples.  After a cascade of decision trees is
constructed in this manner, you construct a final classifier that calculates the
class label for a test data sample by taking into account the classification
decisions made by each individual tree in the cascade, the decisions being weighted
by the trust factors associated with the individual classifiers.  These boosting
notions --- generally referred to as the AdaBoost algorithm --- are based on a now
celebrated paper "A Decision-Theoretic Generalization of On-Line Learning and an
Application to Boosting" by Yoav Freund and Robert Schapire that appeared in 1995 in
the Proceedings of the 2nd European Conf. on Computational Learning Theory.  For a
tutorial introduction to AdaBoost, see L<https://engineering.purdue.edu/kak/Tutorials/AdaBoost.pdf>

Keep in mind the fact that, ordinarily, the theoretical guarantees provided by
boosting apply only to the case of binary classification.  Additionally, your
training dataset must capture all of the significant statistical variations in the
classes represented therein.

=over 4

=item B<Calling the BoostedDecisionTree constructor:>

If you'd like to experiment with boosting, a typical call to the constructor for the
C<BoostedDecisionTree> class looks like: 

    use Algorithm::BoostedDecisionTree;
    my $training_datafile = "training6.csv";
    my $boosted = Algorithm::BoostedDecisionTree->new(
                              training_datafile => $training_datafile,
                              csv_class_column_index => 1,
                              csv_columns_for_features => [2,3],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_stages => 4,
                              csv_cleanup_needed => 1,
                  );

Note in particular the constructor parameter:
    
    how_many_stages

As its name implies, this parameter controls how many stages will be used in the
boosted decision tree classifier.  As mentioned above, a separate decision tree is
constructed for each stage of boosting using a set of training samples that are drawn
through a probability distribution maintained over the entire training dataset.

=back

=head2 B<Methods defined for C<BoostedDecisionTree> class>

=over 8

=item B<get_training_data_for_base_tree():>

This method reads your training datafile, creates the data structures from the data
ingested for constructing the base decision tree.

=item B<show_training_data_for_base_tree():>

Writes to the standard output the training data samples and also some relevant
properties of the features used in the training dataset.

=item B<calculate_first_order_probabilities_and_class_priors():>

Calls on the appropriate methods of the main C<DecisionTree> class to estimate the
first-order probabilities and the class priors.

=item B<construct_base_decision_tree():>

Calls on the appropriate method of the main C<DecisionTree> class to construct the
base decision tree.

=item B<display_base_decision_tree():>

Displays the base decision tree in your terminal window. (The textual form of the
decision tree is written out to the standard output.)

=item B<construct_cascade_of_trees():>

Uses the AdaBoost algorithm to construct a cascade of decision trees.  As mentioned
earlier, the training samples for each tree in the cascade are drawn using a
probability distribution over the entire training dataset. This probability
distribution for any given tree in the cascade is heavily influenced by which
training samples are misclassified by the previous tree.

=item B<display_decision_trees_for_different_stages():>

Displays separately in your terminal window the decision tree constructed for each
stage of the cascade. (The textual form of the trees is written out to the standard
output.)

=item B<classify_with_boosting( $test_sample ):>

Calls on each decision tree in the cascade to classify the argument C<$test_sample>.

=item B<display_classification_results_for_each_stage():>

You can call this method to display in your terminal window the classification
decision made by each decision tree in the cascade.  The method also prints out the
trust factor associated with each decision tree.  It is important to look
simultaneously at the classification decision and the trust factor for each tree ---
since a classification decision made by a specific tree may appear bizarre for a
given test sample.  This method is useful primarily for debugging purposes.

=item B<show_class_labels_for_misclassified_samples_in_stage( $stage_index ):>

As with the previous method, this method is useful mostly for debugging. It returns
class labels for the samples misclassified by the stage whose integer index is
supplied as an argument to the method.  Say you have 10 stages in your cascade.  The
value of the argument C<stage_index> would go from 0 to 9, with 0 corresponding to
the base tree.

=item B<trust_weighted_majority_vote_classifier():>

Uses the "final classifier" formula of the AdaBoost algorithm to pool together the
classification decisions made by the individual trees while taking into account the
trust factors associated with the trees.  As mentioned earlier, we associate with
each tree of the cascade a trust factor that depends on the overall misclassification
rate associated with that tree.

=back

See the example scripts in the C<ExamplesBoosting> subdirectory for how to call the
methods listed above for classifying individual data samples with boosting and for
bulk classification when you place all your test samples in a single file.


=head1 USING RANDOMIZED DECISION TREES

As mentioned earlier, the new C<RandomizedTreesForBigData> class allows you to solve
the following two problems: (1) Data classification using the needle-in-a-haystack
metaphor, that is, when a vast majority of your training samples belong to just one
class.  And (2) You have access to a very large database of training samples and you
wish to construct an ensemble of decision trees for classification.

=over 4

=item B<Calling the RandomizedTreesForBigData constructor:>

Here is how you'd call the C<RandomizedTreesForBigData> constructor for
needle-in-a-haystack classification:

    use Algorithm::RandomizedTreesForBigData;
    my $training_datafile = "your_database.csv";
    my $rt = Algorithm::RandomizedTreesForBigData->new(
                              training_datafile => $training_datafile,
                              csv_class_column_index => 48,
                              csv_columns_for_features => [24,32,33,34,41],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_trees => 5,
                              looking_for_needles_in_haystack => 1,
                              csv_cleanup_needed => 1,
             );

Note in particular the constructor parameters:

    looking_for_needles_in_haystack
    how_many_trees

The first of these parameters, C<looking_for_needles_in_haystack>, invokes the logic for
constructing an ensemble of decision trees, each based on a training dataset that
uses all of the minority class samples, and a random drawing from the majority class
samples.

Here is how you'd call the C<RandomizedTreesForBigData> constructor for a more
general attempt at constructing an ensemble of decision trees, with each tree trained
with randomly drawn samples from a large database of training data (without paying
attention to the differences in the sizes of the populations for the different
classes):

    use Algorithm::RandomizedTreesForBigData;
    my $training_datafile = "your_database.csv";
    my $rt = Algorithm::RandomizedTreesForBigData->new(
                              training_datafile => $training_datafile,
                              csv_class_column_index => 2,
                              csv_columns_for_features => [3,4,5,6,7,8],
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_trees => 3,
                              how_many_training_samples_per_tree => 50,
                              csv_cleanup_needed => 1,
             );

Note in particular the constructor parameters:

    how_many_training_samples_per_tree
    how_many_trees

When you set the C<how_many_training_samples_per_tree> parameter, you are not allowed
to also set the C<looking_for_needles_in_haystack> parameter, and vice versa.

=back

=head2 B<Methods defined for C<RandomizedTreesForBigData> class>

=over 8

=item B<get_training_data_for_N_trees():>

What this method does depends on which of the two constructor parameters ---
C<looking_for_needles_in_haystack> or C<how_many_training_samples_per_tree> --- is
set.  When the former is set, it creates a collection of training datasets for
C<how_many_trees> number of decision trees, with each dataset being a mixture of the
minority class and sample drawn randomly from the majority class.  However, when the
latter option is set, all the datasets are drawn randomly from the training database
with no particular attention given to the relative populations of the two classes.

=item B<show_training_data_for_all_trees():>

As the name implies, this method shows the training data being used for all the
decision trees.  This method is useful for debugging purposes using small datasets.

=item B<calculate_first_order_probabilities():>

Calls on the appropriate method of the main C<DecisionTree class> to estimate the
first-order probabilities for the training dataset to be used for each decision tree.

=item B<calculate_class_priors():>

Calls on the appropriate method of the main C<DecisionTree> class to estimate the
class priors for the training dataset to be used for each decision tree.

=item B<construct_all_decision_trees():>

Calls on the appropriate method of the main C<DecisionTree> class to construct the
decision trees.

=item B<display_all_decision_trees():>

Displays all the decision trees in your terminal window. (The textual form of the
decision trees is written out to the standard output.)

=item B<classify_with_all_trees( $test_sample ):>

The test_sample is sent to each decision tree for classification.

=item B<display_classification_results_for_all_trees():>

The classification decisions returned by the individual decision trees are written
out to the standard output.

=item B<get_majority_vote_classification()>

This method aggregates the classification results returned by the individual decision
trees and returns the majority decision.

=back

=head1 CONSTRUCTING REGRESSION TREES:

Decision tree based modeling requires that the class labels be distinct.  That is,
the training dataset must contain a relatively small number of discrete class labels
for all of your data records if you want to model the data with one or more decision
trees.  However, when one is trying to understand all of the associational
relationships that exist in a large database, one often runs into situations where,
instead of discrete class labels, you have a continuously valued variable as a
dependent variable whose values are predicated on a set of feature values.  It is for
such situations that you will find useful the new class C<RegressionTree> that is now
a part of the C<DecisionTree> module.  The C<RegressionTree> class has been
programmed as a subclass of the main C<DecisionTree> class.

You can think of regression with a regression tree as a powerful generalization of
the very commonly used Linear Regression algorithms.  Although you can certainly
carry out polynomial regression with run-of-the-mill Linear Regression algorithms for
modeling nonlinearities between the predictor variables and the dependent variable,
specifying the degree of the polynomial is often tricky. Additionally, a polynomial
can inject continuities between the predictor and the predicted variables that may
not really exist in the real data.  Regression trees, on the other hand, give you a
piecewise linear relationship between the predictor and the predicted variables that
is freed from the constraints of superimposed continuities at the joins between the
different segments.  See the following tutorial for further information regarding the
standard linear regression approach and the regression that can be achieved with the
RegressionTree class in this module:
L<https://engineering.purdue.edu/kak/Tutorials/RegressionTree.pdf>

The RegressionTree class in the current version of the module assumes that all of
your data is numerical.  That is, unlike what is possible with the DecisionTree class
(and the other more closely related classes in this module) that allow your training
file to contain a mixture of numerical and symbolic data, the RegressionTree class
requires that ALL of your data be numerical.  I hope to relax this constraint in
future versions of this module.  Obviously, the dependent variable will always be
numerical for regression.

See the example scripts in the directory C<ExamplesRegression> if you wish to become
more familiar with the regression capabilities of the module.

=over 4

=item B<Calling the RegressionTree constructor:>

    my $training_datafile = "gendata5.csv";
    my $rt = Algorithm::RegressionTree->new(
                              training_datafile => $training_datafile,
                              dependent_variable_column => 2,
                              predictor_columns => [1],
                              mse_threshold => 0.01,
                              max_depth_desired => 2,
                              jacobian_choice => 0,
                              csv_cleanup_needed => 1,
             );

Note in particular the constructor parameters:

    dependent_variable
    predictor_columns
    mse_threshold
    jacobian_choice

The first of these parameters, C<dependent_variable>, is set to the column index in
the CSV file for the dependent variable.  The second constructor parameter,
C<predictor_columns>, tells the system as to which columns contain values for the
predictor variables.  The third parameter, C<mse_threshold>, is for deciding when to
partition the data at a node into two child nodes as a regression tree is being
constructed.  If the minmax of MSE (Mean Squared Error) that can be achieved by
partitioning any of the features at a node is smaller than C<mse_threshold>, that
node becomes a leaf node of the regression tree.

The last parameter, C<jacobian_choice>, must be set to either 0 or 1 or 2.  Its
default value is 0. When this parameter equals 0, the regression coefficients are
calculated using the linear least-squares method and no further "refinement" of the
coefficients is carried out using gradient descent.  This is the fastest way to
calculate the regression coefficients.  When C<jacobian_choice> is set to 1, you get
a weak version of gradient descent in which the Jacobian is set to the "design
matrix" itself. Choosing 2 for C<jacobian_choice> results in a more reasonable
approximation to the Jacobian.  That, however, is at a cost of much longer
computation time.  B<NOTE:> For most cases, using 0 for C<jacobian_choice> is the
best choice.  See my tutorial "I<Linear Regression and Regression Trees>" for why
that is the case.

=back

=head2 B<Methods defined for C<RegressionTree> class>

=over 8

=item B<get_training_data_for_regression():>

Only CSV training datafiles are allowed. Additionally, the first record in the file
must list the names of the fields, and the first column must contain an integer ID
for each record.

=item B<construct_regression_tree():>

As the name implies, this is the method that construct a regression tree.

=item B<display_regression_tree("     "):>

Displays the regression tree, as the name implies.  The white-space string argument
specifies the offset to use in displaying the child nodes in relation to a parent
node.

=item B<prediction_for_single_data_point( $root_node, $test_sample ):>

You call this method after you have constructed a regression tree if you want to
calculate the prediction for one sample.  The parameter C<$root_node> is what is
returned by the call C<construct_regression_tree()>.  The formatting of the argument
bound to the C<$test_sample> parameter is important.  To elaborate, let's say you are
using two variables named C<$xvar1> and C<$xvar2> as your predictor variables. In
this case, the C<$test_sample> parameter will be bound to a list that will look like

    ['xvar1 = 23.4', 'xvar2 = 12.9'] 

Arbitrary amount of white space, including none, on the two sides of the equality
symbol is allowed in the construct shown above.  A call to this method returns a
dictionary with two key-value pairs.  One of the keys is called C<solution_path> and
the other C<prediction>.  The value associated with key C<solution_path> is the path
in the regression tree to the leaf node that yielded the prediction.  And the value
associated with the key C<prediction> is the answer you are looking for.

=item B<predictions_for_all_data_used_for_regression_estimation( $root_node ):>

This call calculates the predictions for all of the predictor variables data in your
training file.  The parameter C<$root_node> is what is returned by the call to
C<construct_regression_tree()>.  The values for the dependent variable thus predicted
can be seen by calling C<display_all_plots()>, which is the method mentioned below.

=item B<display_all_plots():>

This method displays the results obtained by calling the prediction method of the
previous entry.  This method also creates a hardcopy of the plots and saves it as a
C<.png> disk file. The name of this output file is always C<regression_plots.png>.

=item B<mse_for_tree_regression_for_all_training_samples( $root_node ):>

This method carries out an error analysis of the predictions for the samples in your
training datafile.  It shows you the overall MSE (Mean Squared Error) with tree-based
regression, the MSE for the data samples at each of the leaf nodes of the regression
tree, and the MSE for the plain old Linear Regression as applied to all of the data.
The parameter C<$root_node> in the call syntax is what is returned by the call to
C<construct_regression_tree()>.

=item B<bulk_predictions_for_data_in_a_csv_file( $root_node, $filename, $columns ):>

Call this method if you want to apply the regression tree to all your test data in a
disk file.  The predictions for all of the test samples in the disk file are written
out to another file whose name is the same as that of the test file except for the
addition of C<_output> in the name of the file.  The parameter C<$filename> is the
name of the disk file that contains the test data. And the parameter C<$columns> is a
list of the column indices for the predictor variables in the test file.

=back

=head1 GENERATING SYNTHETIC TRAINING DATA

The module file contains the following additional classes: (1)
C<TrainingDataGeneratorNumeric>, and (2) C<TrainingDataGeneratorSymbolic> for
generating synthetic training data.

The class C<TrainingDataGeneratorNumeric> outputs one CSV file for the
training data and another one for the test data for experimenting with numeric
features.  The numeric values are generated using a multivariate Gaussian
distribution whose mean and covariance are specified in a parameter file. See the
file C<param_numeric.txt> in the C<Examples> directory for an example of such a
parameter file.  Note that the dimensionality of the data is inferred from the
information you place in the parameter file.

The class C<TrainingDataGeneratorSymbolic> generates synthetic training for the
purely symbolic case.  The relative frequencies of the different possible values for
the features is controlled by the biasing information you place in a parameter file.
See C<param_symbolic.txt> for an example of such a file.


=head1 THE C<Examples> DIRECTORY

See the C<Examples> directory in the distribution for how to construct a decision
tree, and how to then classify new data using the decision tree.  To become more
familiar with the module, run the scripts

    construct_dt_and_classify_one_sample_case1.pl
    construct_dt_and_classify_one_sample_case2.pl
    construct_dt_and_classify_one_sample_case3.pl
    construct_dt_and_classify_one_sample_case4.pl

The first script is for the purely symbolic case, the second for the case that
involves both numeric and symbolic features, the third for the case of purely numeric
features, and the last for the case when the training data is synthetically generated
by the script C<generate_training_data_numeric.pl>.

Next run the following script as it is for bulk classification of data records placed
in a CSV file:

    classify_test_data_in_a_file.pl   training4.csv   test4.csv   out4.csv

The script first constructs a decision tree using the training data in the training
file supplied by the first argument file C<training4.csv>.  The script then
calculates the class label for each data record in the test data file supplied
through the second argument file, C<test4.csv>.  The estimated class labels are
written out to the output file which in the call shown above is C<out4.csv>.  An
important thing to note here is that your test file --- in this case C<test4.csv> ---
must have a column for class labels.  Obviously, in real-life situations, there will
be no class labels in this column.  What that is the case, you can place an empty
string C<""> there for each data record. This is demonstrated by the following call:

    classify_test_data_in_a_file.pl   training4.csv   test4_no_class_labels.csv   out4.csv

The following script in the C<Examples> directory

    classify_by_asking_questions.pl

shows how you can use a decision-tree classifier interactively.  In this mode, you
first construct the decision tree from the training data and then the user is
prompted for answers to the feature tests at the nodes of the tree.

If your training data has a feature whose values span a large range and, at the same
time, are characterized by a heavy-tail distribution, you should look at the script

    construct_dt_for_heavytailed.pl                                                     

to see how to use the option C<number_of_histogram_bins> in the call to the
constructor.  This option was introduced in Version 2.22 for dealing with such
features.  If you do not set this option, the module will use the default value of
500 for the number of points at which to sample the value range for such a feature.

The C<Examples> directory also contains the following scripts:

    generate_training_data_numeric.pl
    generate_training_data_symbolic.pl

that show how you can use the module to generate synthetic training.  Synthetic
training is generated according to the specifications laid out in a parameter file.
There are constraints on how the information is laid out in a parameter file.  See
the files C<param_numeric.txt> and C<param_symbolic.txt> in the C<Examples> directory
for how to structure these files.

The C<Examples> directory of Versions 2.1 and higher of the module also contains the
following two scripts:

    evaluate_training_data1.pl
    evaluate_training_data2.pl

that illustrate how the Perl class C<EvalTrainingData> can be used to evaluate the
quality of your training data (as long as it resides in a `C<.csv>' file.)  This new
class is a subclass of the C<DecisionTree> class in the module file.  See the README
in the C<Examples> directory for further information regarding these two scripts.

The C<Examples> directory of Versions 2.31 and higher of the module contains the
following three scripts:

    introspection_in_a_loop_interactive.pl

    introspection_show_training_samples_at_all_nodes_direct_influence.pl

    introspection_show_training_samples_to_nodes_influence_propagation.pl

The first script illustrates how to use the C<DTIntrospection> class of the module
interactively for generating explanations for the classification decisions made at
the nodes of the decision tree.  In the interactive session you are first asked for
the node number you are interested in.  Subsequently, you are asked for whether or
not you are interested in specific questions that the introspector can provide
answers for. The second script generates a tabular display that shows for each node
of the decision tree a list of the training samples that fall directly in the portion
of the feature space assigned that node.  (As mentioned elsewhere in this
documentation, when this list is empty for a node, that means the node is a result of
the generalization achieved by probabilistic modeling of the data.  Note that this
module constructs a decision tree NOT by partitioning the set of training samples,
BUT by partitioning the domains of the probability density functions.)  The third
script listed above also generates a tabular display, but one that shows how the
influence of each training sample propagates in the tree.  This display first shows
the list of nodes that are affected directly by the data in a training sample. This
list is followed by an indented display of the nodes that are affected indirectly by
the training sample.  A training sample affects a node indirectly if the node is a
descendant of one of the nodes affected directly.

The latest addition to the Examples directory is the script:

    get_indexes_associated_with_fields.py

As to why you may find this script useful, note that large database files may have
hundreds of fields and it is not always easy to figure out what numerical index is
associated with a given field.  At the same time, the constructor of the DecisionTree
module requires that the field that holds the class label and the fields that contain
the feature values be specified by their numerical zero-based indexes.  If you have a
large database and you are faced with this problem, you can run this script to see
the zero-based numerical index values associated with the different columns of your
CSV file.


=head1 THE C<ExamplesBagging> DIRECTORY

The C<ExamplesBagging> directory contains the following scripts:

    bagging_for_classifying_one_test_sample.pl
                                                                                               
    bagging_for_bulk_classification.pl

As the names of the scripts imply, the first shows how to call the different methods
of the C<DecisionTreeWithBagging> class for classifying a single test sample.  When
you are classifying a single test sample, you can also see how each bag is
classifying the test sample.  You can, for example, display the training data used in
each bag, the decision tree constructed for each bag, etc.

The second script is for the case when you place all of the test samples in a single
file.  The demonstration script displays for each test sample a single aggregate
classification decision that is obtained through majority voting by all the decision
trees.


=head1 THE C<ExamplesBoosting> DIRECTORY

The C<ExamplesBoosting> subdirectory in the main installation directory contains the
following three scripts:

    boosting_for_classifying_one_test_sample_1.pl

    boosting_for_classifying_one_test_sample_2.pl

    boosting_for_bulk_classification.pl

As the names of the first two scripts imply, these show how to call the different
methods of the C<BoostedDecisionTree> class for classifying a single test sample.
When you are classifying a single test sample, you can see how each stage of the
cascade of decision trees is classifying the test sample.  You can also view each
decision tree separately and also see the trust factor associated with the tree.

The third script is for the case when you place all of the test samples in a single
file.  The demonstration script outputs for each test sample a single aggregate
classification decision that is obtained through trust-factor weighted majority
voting by all the decision trees.

=head1 THE C<ExamplesRandomizedTrees> DIRECTORY

The C<ExamplesRandomizedTrees> directory shows example scripts that you can use to
become more familiar with the C<RandomizedTreesForBigData> class for solving
needle-in-a-haystack and big-data data classification problems. These scripts are:

    randomized_trees_for_classifying_one_test_sample_1.pl

    randomized_trees_for_classifying_one_test_sample_2.pl

    classify_database_records.pl

The first script shows the constructor options to use for solving a
needle-in-a-haystack problem --- that is, a problem in which a vast majority of the
training data belongs to just one class.  The second script shows the constructor
options for using randomized decision trees for the case when you have access to a
very large database of training samples and you'd like to construct an ensemble of
decision trees using training samples pulled randomly from the training database.
The last script illustrates how you can evaluate the classification power of an
ensemble of decision trees as constructed by C<RandomizedTreesForBigData> by classifying
a large number of test samples extracted randomly from the training database.


=head1 THE C<ExamplesRegression> DIRECTORY

The C<ExamplesRegression> subdirectory in the main installation directory shows
example scripts that you can use to become familiar with regression trees and how
they can be used for nonlinear regression.  If you are new to the concept of
regression trees, start by executing the following scripts without changing them and
see what sort of output is produced by them:

    regression4.pl

    regression5.pl

    regression6.pl

    regression8.pl

The C<regression4.pl> script involves only one predictor variable and one dependent
variable. The training data for this exercise is drawn from the file C<gendata4.csv>.
This data file contains strongly nonlinear data.  When you run the script
C<regression4.pl>, you will see how much better the result from tree regression is
compared to what you can get with linear regression.

The C<regression5.pl> script is essentially the same as the previous script except
for the fact that the training datafile used in this case, C<gendata5.csv>, consists
of three noisy segments, as opposed to just two in the previous case.

The script C<regression6.pl> deals with the case when we have two predictor variables
and one dependent variable.  You can think of the data as consisting of noisy height
values over an C<(x1,x2)> plane.  The data used in this script is drawn from the csv
file C<gen3Ddata1.csv>.

Finally, the script C<regression8.pl> shows how you can carry out bulk prediction for
all your test data records in a disk file.  The script writes all the calculated
predictions into another disk file whose name is derived from the name of the test
data file.


=head1 EXPORT

None by design.

=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'DecisionTree' in the subject line.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-DecisionTree-3.42.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-DecisionTree-3.42>.  Enter this directory and execute the following
commands for a standard install of the module if you have root privileges:

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

I wish to thank many users of this module for their feedback.  Many of the
improvements I have made to the module over the years are a result of the feedback
received.

I thank Slaven Rezic for pointing out that the module worked with Perl 5.14.x.  For
Version 2.22, I had set the required version of Perl to 5.18.0 since that's what I
used for testing the module. Slaven's feedback in the form of the Bug report
C<#96547> resulted in Version 2.23 of the module.  Version 2.25 further downshifts
the required version of Perl to 5.10.

On the basis of the report posted by Slaven at C<rt.cpan.org> regarding Version 2.27,
I am removing the Perl version restriction altogether from Version 2.30.  Thanks
Slaven!


=head1 AUTHOR

The author, Avinash Kak, recently finished a 17-year long "Objects Trilogy Project"
with the publication of the book I<Designing with Objects> by John-Wiley. If
interested, visit his web page at Purdue to find out what this project was all
about. You might like I<Designing with Objects> especially if you enjoyed reading
Harry Potter as a kid (or even as an adult, for that matter).

If you send email regarding this module, please place the string "DecisionTree" in
your subject line to get past my spam filter.  Avi Kak's email address is
C<kak@purdue.edu>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2016 Avinash Kak

=cut

