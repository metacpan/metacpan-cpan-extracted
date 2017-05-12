package Algorithm::BoostedDecisionTree;

#--------------------------------------------------------------------------------------
# Copyright (c) 2016 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::BoostedDecisionTree is a Perl module for boosted decision-tree based
# classification of multidimensional data.
# -------------------------------------------------------------------------------------

use lib 'blib/lib', 'blib/arch';

#use 5.10.0;
use strict;
use warnings;
use Carp;
use Algorithm::DecisionTree 3.42;
use List::Util qw(reduce min max);

our $VERSION = '3.42';

@Algorithm::BoostedDecisionTree::ISA = ('Algorithm::DecisionTree');

############################################   Constructor  ##############################################
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument --- perhaps a misspelling\n" 
                           if check_for_illegal_params(@params) == 0;
    my %dtargs = %args;
    delete $dtargs{how_many_stages};
    my $instance = Algorithm::DecisionTree->new(%dtargs);
    bless $instance, $class;
    $instance->{_how_many_stages}              =  $args{how_many_stages} || undef;
    $instance->{_stagedebug}                   =  $args{stagedebug} || 0;
    $instance->{_training_samples}             =  {map {$_ => []} 0..$args{how_many_stages}};
    $instance->{_all_trees}                    =  {map {$_ => Algorithm::DecisionTree->new(%dtargs)} 0..$args{how_many_stages}};
    $instance->{_root_nodes}                   =  {map {$_ => undef} 0..$args{how_many_stages}};
    $instance->{_sample_selection_probs}       =  {map {$_ => {}} 0..$args{how_many_stages}};
    $instance->{_trust_factors}                =  {map {$_ => undef} 0..$args{how_many_stages}};
    $instance->{_misclassified_samples}        =  {map {$_ => []} 0..$args{how_many_stages}};
    $instance->{_classifications}              =  undef;
    $instance->{_trust_weighted_decision_classes}  =  undef;
    bless $instance, $class;
}

##############################################  Methods  #################################################
sub get_training_data_for_base_tree {
    my $self = shift;
    die("Aborted. get_training_data_csv() is only for CSV files") unless $self->{_training_datafile} =~ /\.csv$/;
    my %class_names = ();
    my %all_record_ids_with_class_labels;
    my $firstline;
    my %data_hash;
    $|++;
    open FILEIN, $self->{_training_datafile};
    my $record_index = 0;
    my $firsetline;
    while (<FILEIN>) {
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        my $record =  $self->{_csv_cleanup_needed} ? cleanup_csv($_) : $_;
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
    my @feature_names = map {$all_feature_names[$_]} @{$self->{_csv_columns_for_features}};
    my %class_for_sample_hash = map {"sample_" . $_  =>  "$class_column_heading=" . $data_hash{$_}->[$self->{_csv_class_column_index} - 1 ] } keys %data_hash;
    my @sample_names = map {"sample_$_"} keys %data_hash;
    my %feature_values_for_samples_hash = map {my $sampleID = $_; "sample_" . $sampleID  =>  [map {my $fname = $all_feature_names[$_]; $fname . "=" . eval{$data_hash{$sampleID}->[$_-1] =~ /^\d+$/ ? sprintf("%.1f", $data_hash{$sampleID}->[$_-1] ) : $data_hash{$sampleID}->[$_-1] } } @{$self->{_csv_columns_for_features}} ] }  keys %data_hash;    
    my %features_and_values_hash = map { my $a = $_; {$all_feature_names[$a] => [  map {my $b = $_; $b =~ /^\d+$/ ? sprintf("%.1f",$b) : $b} map {$data_hash{$_}->[$a-1]} keys %data_hash ]} } @{$self->{_csv_columns_for_features}};     
    my @all_class_names =  sort keys %{ {map {$_ => 1} values %class_for_sample_hash } };
    $self->{_number_of_training_samples} = scalar @sample_names;
    if ($self->{_debug2}) {
        print "\nDisplaying features and their values for entire training data:\n\n";
        foreach my $fname (keys  %features_and_values_hash) {         
            print "        $fname    =>  @{$features_and_values_hash{$fname}}\n";
        }
    }
    my %features_and_unique_values_hash = ();
    my %feature_values_how_many_uniques_hash  =  ();
    my %numeric_features_valuerange_hash   =   ();
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
    $self->{_all_trees}->{0}->{_class_names} = \@all_class_names;
    $self->{_all_trees}->{0}->{_feature_names} = \@feature_names;
    $self->{_all_trees}->{0}->{_samples_class_label_hash} = \%class_for_sample_hash;
    $self->{_all_trees}->{0}->{_training_data_hash}  =  \%feature_values_for_samples_hash;
    $self->{_all_trees}->{0}->{_features_and_values_hash}    =  \%features_and_values_hash;
    $self->{_all_trees}->{0}->{_features_and_unique_values_hash}    =  \%features_and_unique_values_hash;
    $self->{_all_trees}->{0}->{_numeric_features_valuerange_hash} = \%numeric_features_valuerange_hash;
    $self->{_all_trees}->{0}->{_feature_values_how_many_uniques_hash} = \%feature_values_how_many_uniques_hash;
    $self->{_all_training_data} = \%feature_values_for_samples_hash;    
    $self->{_all_sample_names} = [sort {sample_index($a) cmp sample_index($b)} keys %feature_values_for_samples_hash];
    if ($self->{_debug1}) {
        print "\n\n===========================  data ingested for the base tree   ==================================\n\n";
        print "\nAll class names: @{$self->{_all_trees}->{0}->{_class_names}}\n";
        print "\nEach sample data record:\n";
        foreach my $kee (sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_all_trees}->{0}->{_training_data_hash}}) {
            print "$kee    =>   @{$self->{_all_trees}->{0}->{_training_data_hash}->{$kee}}\n";
        }
        print "\nclass label for each data sample:\n";        
        foreach my $kee (sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_all_trees}->{0}->{_samples_class_label_hash}}) {
            print "$kee    =>   $self->{_all_trees}->{0}->{_samples_class_label_hash}->{$kee}\n";            
        }
        print "\nfeatures and the values taken by them:\n";
        for my $kee  (sort keys %{$self->{_all_trees}->{0}->{_features_and_values_hash}}) {
            print "$kee    =>   @{$self->{_all_trees}->{0}->{_features_and_values_hash}->{$kee}}\n";                        
        }
        print "\nnumeric features and their ranges:\n";
        for my $kee  (sort keys %{$self->{_all_trees}->{0}->{_numeric_features_valuerange_hash}}) {
            print "$kee    =>   @{$self->{_all_trees}->{0}->{_numeric_features_valuerange_hash}->{$kee}}\n";
        }
        print "\nunique values for the features:\n";
        for my $kee  (sort keys %{$self->{_all_trees}->{0}->{_features_and_unique_values_hash}}) {
            print "$kee    =>   @{$self->{_all_trees}->{0}->{_features_and_unique_values_hash}->{$kee}}\n";  
        }
        print "\nnumber of unique values in each feature:\n";        
        for my $kee  (sort keys %{$self->{_all_trees}->{0}->{_feature_values_how_many_uniques_hash}}) {
            print "$kee    =>   $self->{_all_trees}->{0}->{_feature_values_how_many_uniques_hash}->{$kee}\n";
        }
    }
}

sub show_training_data_for_base_tree {
    my $self = shift;
    $self->{_all_trees}->{0}->show_training_data();
}

sub calculate_first_order_probabilities_and_class_priors {
    my $self = shift;
    $self->{_all_trees}->{0}->calculate_first_order_probabilities();
    $self->{_all_trees}->{0}->calculate_class_priors();
    $self->{_sample_selection_probs}->{0} =  {map { $_ => 1.0/@{$self->{_all_sample_names}} } @{$self->{_all_sample_names}}};
}

sub construct_base_decision_tree {
    my $self = shift;
    $self->{_root_nodes}->{0} = $self->{_all_trees}->{0}->construct_decision_tree_classifier();
}

sub display_base_decision_tree {
    my $self = shift;
    $self->{_root_nodes}->{0}->display_decision_tree("     ");
}

sub construct_cascade_of_trees {
    my $self = shift;
    $self->{_training_samples}->{0} = $self->{_all_sample_names};
    $self->{_misclassified_samples}->{0} = $self->evaluate_one_stage_of_cascade($self->{_all_trees}->{0}, $self->{_root_nodes}->{0});
    if ($self->{_stagedebug}) {
        $self->show_class_labels_for_misclassified_samples_in_stage(0);
        print "\n\nSamples misclassified by base classifier: @{$self->{_misclassified_samples}->{0}}\n";
        my $how_many = @{$self->{_misclassified_samples}->{0}};
        print "\nNumber of misclassified samples: $how_many\n";
    }
    my $misclassification_error_rate = reduce {$a+$b} map {$self->{_sample_selection_probs}->{0}->{$_}} @{$self->{_misclassified_samples}->{0}};
    print "\nMisclassification_error_rate for base classifier: $misclassification_error_rate\n" if $self->{_stagedebug};
    $self->{_trust_factors}->{0} = 0.5 * log((1-$misclassification_error_rate)/$misclassification_error_rate);
    print "\nBase class trust factor: $self->{_trust_factors}->{0}\n"  if $self->{_stagedebug};
    foreach my $stage_index (1 .. $self->{_how_many_stages} - 1) {
        print "\n\n========================== Constructing stage indexed $stage_index =========================\n"
              if $self->{_stagedebug};
        $self->{_sample_selection_probs}->{$stage_index} =  { map {$_ =>  $self->{_sample_selection_probs}->{$stage_index-1}->{$_} *   exp(-1.0 * $self->{_trust_factors}->{$stage_index - 1} *  (contained_in($_, @{$self->{_misclassified_samples}->{$stage_index - 1}}) ? -1.0 : 1.0) )  }  @{$self->{_all_sample_names}} };        
        my $normalizer = reduce {$a + $b} values %{$self->{_sample_selection_probs}->{$stage_index}};
        print "\nThe normalizer is: $normalizer\n"  if $self->{_stagedebug};
        map {$self->{_sample_selection_probs}->{$stage_index}->{$_}  /= $normalizer} keys %{$self->{_sample_selection_probs}->{$stage_index}};
        my @training_samples_this_stage = ();
        my $sum_of_probs = 0.0;
        foreach my $sample (sort {$self->{_sample_selection_probs}->{$stage_index}->{$b} <=> $self->{_sample_selection_probs}->{$stage_index}->{$a}} keys %{$self->{_sample_selection_probs}->{$stage_index}}) {
            $sum_of_probs += $self->{_sample_selection_probs}->{$stage_index}->{$sample};
            push @training_samples_this_stage, $sample if $sum_of_probs < 0.5;
            last if $sum_of_probs > 0.5;
        }
        $self->{_training_samples}->{$stage_index} = [sort {sample_index($a) <=> sample_index($b)} @training_samples_this_stage];
        if ($self->{_stagedebug}) {
            print "\nTraining samples for stage $stage_index: @{$self->{_training_samples}->{$stage_index}}\n\n";
            my $num_of_training_samples = @{$self->{_training_samples}->{$stage_index}};
            print "\nNumber of training samples this stage $num_of_training_samples\n\n";
        }
        # find intersection of two sets:
        my %misclassified_samples = map {$_ => 1} @{$self->{_misclassified_samples}->{$stage_index-1}};
        my @training_samples_selection_check = grep $misclassified_samples{$_}, @{$self->{_training_samples}->{$stage_index}};
        if ($self->{_stagedebug}) {
            my @training_in_misclassified = sort {sample_index($a) <=> sample_index($b)} @training_samples_selection_check;
            print "\nTraining samples in the misclassified set: @training_in_misclassified\n";
            my $how_many = @training_samples_selection_check;
            print "\nNumber_of_miscalssified_samples_in_training_set: $how_many\n";
        }
        my $dt_this_stage = Algorithm::DecisionTree->new('boostingmode');
        $dt_this_stage->{_training_data_hash} = { map {$_ => $self->{_all_training_data}->{$_} } @{$self->{_training_samples}->{$stage_index}} };

        $dt_this_stage->{_class_names} = $self->{_all_trees}->{0}->{_class_names};
        $dt_this_stage->{_feature_names} = $self->{_all_trees}->{0}->{_feature_names};
        $dt_this_stage->{_entropy_threshold} = $self->{_all_trees}->{0}->{_entropy_threshold};
        $dt_this_stage->{_max_depth_desired} = $self->{_all_trees}->{0}->{_max_depth_desired};        
        $dt_this_stage->{_symbolic_to_numeric_cardinality_threshold} = $self->{_all_trees}->{0}->{_symbolic_to_numeric_cardinality_threshold};
        $dt_this_stage->{_samples_class_label_hash} = {map {$_ => $self->{_all_trees}->{0}->{_samples_class_label_hash}->{$_}} keys %{$dt_this_stage->{_training_data_hash}}};
        $dt_this_stage->{_features_and_values_hash} = {map {$_ => []} keys %{$self->{_all_trees}->{0}->{_features_and_values_hash}}};
        my $pattern = '(\S+)\s*=\s*(\S+)';        
        foreach my $sample (sort {sample_index($a) <=> sample_index($b)} keys %{$dt_this_stage->{_training_data_hash}}) { 
            foreach my $feature_and_value (@{$dt_this_stage->{_training_data_hash}->{$sample}}) {
                $feature_and_value =~ /$pattern/;
                my ($feature, $value) = ($1, $2);
                push @{$dt_this_stage->{_features_and_values_hash}->{$feature}}, $value if $value ne 'NA';
            }
        }
        $dt_this_stage->{_features_and_unique_values_hash} = {map {my $feature = $_; $feature => [sort keys %{{map {$_ => 1} @{$dt_this_stage->{_features_and_values_hash}->{$feature}}}}]} keys %{$dt_this_stage->{_features_and_values_hash}}};
        $dt_this_stage->{_numeric_features_valuerange_hash} = {map {$_ => []} keys %{$self->{_all_trees}->{0}->{_numeric_features_valuerange_hash}}};
        $dt_this_stage->{_numeric_features_valuerange_hash} = {map {my $feature = $_; $feature =>  [min(@{$dt_this_stage->{_features_and_unique_values_hash}->{$feature}}), max(@{$dt_this_stage->{_features_and_unique_values_hash}->{$feature}})]} keys %{$self->{_all_trees}->{0}->{_numeric_features_valuerange_hash}}};
        if ($self->{_stagedebug}) {
            print "\n\nPrinting features and their values in the training set:\n\n";
            foreach my $kee (sort keys %{$dt_this_stage->{_features_and_values_hash}}) {
                print "$kee   =>  @{$dt_this_stage->{_features_and_values_hash}->{$kee}}\n";
            }
            print "\n\nPrinting unique values for features:\n\n";
            foreach my $kee (sort keys %{$dt_this_stage->{_features_and_unique_values_hash}}) {
                print "$kee   =>  @{$dt_this_stage->{_features_and_unique_values_hash}->{$kee}}\n";            
            }
            print "\n\nPrinting unique value ranges for features:\n\n";
            foreach my $kee (sort keys %{$dt_this_stage->{_numeric_features_valuerange_hash}}) {
                print "$kee   =>  @{$dt_this_stage->{_numeric_features_valuerange_hash}->{$kee}}\n";            
            }
        }
        $dt_this_stage->{_feature_values_how_many_uniques_hash} = {map {$_ => undef} keys %{$self->{_all_trees}->{0}->{_features_and_unique_values_hash}}};
        $dt_this_stage->{_feature_values_how_many_uniques_hash} = {map {$_ => scalar @{$dt_this_stage->{_features_and_unique_values_hash}->{$_}}} keys %{$self->{_all_trees}->{0}->{_features_and_unique_values_hash}}};
        $dt_this_stage->calculate_first_order_probabilities();
        $dt_this_stage->calculate_class_priors();
        print "\n\n>>>>>>>Done with the initialization of the tree for stage $stage_index<<<<<<<<<<\n" if $self->{_stagedebug};
        my $root_node_this_stage = $dt_this_stage->construct_decision_tree_classifier();
        $root_node_this_stage->display_decision_tree("     ") if $self->{_stagedebug};

        $self->{_all_trees}->{$stage_index} = $dt_this_stage;
        $self->{_root_nodes}->{$stage_index} = $root_node_this_stage;
        $self->{_misclassified_samples}->{$stage_index} = $self->evaluate_one_stage_of_cascade($self->{_all_trees}->{$stage_index}, $self->{_root_nodes}->{$stage_index});
        if ($self->{_stagedebug}) {
            print "\nSamples misclassified by stage $stage_index classifier: @{$self->{_misclassified_samples}->{$stage_index}}\n";
            printf("\nNumber of misclassified samples: %d\n", scalar @{$self->{_misclassified_samples}->{$stage_index}});
            $self->show_class_labels_for_misclassified_samples_in_stage($stage_index);
        }
        my $misclassification_error_rate = reduce {$a+$b} map {$self->{_sample_selection_probs}->{$stage_index}->{$_}} @{$self->{_misclassified_samples}->{$stage_index}};
        print "\nStage $stage_index misclassification_error_rate: $misclassification_error_rate\n" if $self->{_stagedebug};

        $self->{_trust_factors}->{$stage_index} = 0.5 * log((1-$misclassification_error_rate)/$misclassification_error_rate);
        print "\nStage $stage_index trust factor: $self->{_trust_factors}->{$stage_index}\n"  if $self->{_stagedebug};
    }
}

sub evaluate_one_stage_of_cascade {
    my $self = shift;
    my $trainingDT = shift;
    my $root_node = shift;
    my @misclassified_samples = ();
    foreach my $test_sample_name (@{$self->{_all_sample_names}}) {
        my @test_sample_data = @{$self->{_all_trees}->{0}->{_training_data_hash}->{$test_sample_name}};
        print "original data in $test_sample_name:@test_sample_data\n" if $self->{_stagedebug};
        @test_sample_data = map {$_ if $_ !~ /=NA$/} @test_sample_data;
        print "$test_sample_name: @test_sample_data\n" if $self->{_stagedebug}; 
        my %classification = %{$trainingDT->classify($root_node, \@test_sample_data)};
        my @solution_path = @{$classification{'solution_path'}};                                  
        delete $classification{'solution_path'};                                              
        my @which_classes = keys %classification;
        @which_classes = sort {$classification{$b} <=> $classification{$a}} @which_classes;
        my $most_likely_class_label = $which_classes[0];
        if ($self->{_stagedebug}) {
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
        my $true_class_label_for_test_sample = $self->{_all_trees}->{0}->{_samples_class_label_hash}->{$test_sample_name};
        printf("%s:   true_class: %s    estimated_class: %s\n", $test_sample_name, $true_class_label_for_test_sample, $most_likely_class_label) if $self->{_stagedebug};
        push @misclassified_samples, $test_sample_name if $true_class_label_for_test_sample ne $most_likely_class_label;
    }
    return [sort {sample_index($a) <=> sample_index($b)} @misclassified_samples];
}

sub show_class_labels_for_misclassified_samples_in_stage {
    my $self = shift;
    my $stage_index = shift;
    die "\nYou must first call 'construct_cascade_of_trees()' before invoking 'show_class_labels_for_misclassified_samples_in_stage()'" unless @{$self->{_misclassified_samples}->{0}} > 0;
    my @classes_for_misclassified_samples = ();
    my @just_class_labels = ();

    for my $sample (@{$self->{_misclassified_samples}->{$stage_index}}) {    
        my $true_class_label_for_sample = $self->{_all_trees}->{0}->{_samples_class_label_hash}->{$sample};            
        push @classes_for_misclassified_samples, sprintf("%s => %s", $sample, $true_class_label_for_sample);
        push @just_class_labels, $true_class_label_for_sample; 
    }
    print "\nSamples misclassified by the classifier for Stage $stage_index: @{$self->{_misclassified_samples}->{$stage_index}}\n";
    my $how_many = @{$self->{_misclassified_samples}->{$stage_index}};
    print "\nNumber of misclassified samples: $how_many\n";
    print "\nShowing class labels for samples misclassified by stage $stage_index: ";
    print "\nClass labels for samples: @classes_for_misclassified_samples\n";
    my @class_names_unique =  sort keys %{{map {$_ => 1} @just_class_labels}};
    print "\nClass names (unique) for misclassified samples: @class_names_unique\n";
    print "\nFinished displaying class labels for samples misclassified by stage $stage_index\n\n";
}

sub display_decision_trees_for_different_stages {
    my $self = shift;
    print "\nDisplaying the decisions trees for all stages:\n\n";
    foreach my $i (0..$self->{_how_many_stages}-1) {
        print "\n\n=============================   For stage $i   ==================================\n\n";
        $self->{_root_nodes}->{$i}->display_decision_tree("     ");
    }
    print "\n==================================================================================\n\n\n";
}

sub classify_with_boosting {
    my $self = shift;    
    my $test_sample = shift;
    $self->{_classifications} = [map $self->{_all_trees}->{$_}->classify($self->{_root_nodes}->{$_}, $test_sample), 0..$self->{_how_many_stages}-1];
}

sub display_classification_results_for_each_stage {
    my $self = shift;        
    my @classifications = @{$self->{_classifications}};
    die "You must first call 'classify_with_boosting()' before invoking 'display_classification_results_for_each_stage()'\n"
        unless @classifications; 
    my @solution_paths = map $_->{'solution_path'}, @classifications;
    foreach my $i (0..$self->{_how_many_stages}-1) {
        print "\n\n=============================   For stage $i   ==================================\n\n";
        my %classification = %{$classifications[$i]};
        delete $classification{'solution_path'};
        my @which_classes = keys %classification;
        @which_classes = sort {$classification{$b} <=> $classification{$a}} @which_classes;
        print "\nClassification:\n\n";
        print "Classifier trust: $self->{_trust_factors}->{$i}\n\n";
        print "     class                         probability\n";
        print "     ----------                    -----------\n";
        foreach my $which_class (@which_classes) {
            my $classstring = sprintf("%-30s", $which_class);
            my $valuestring = sprintf("%-30s", $classification{$which_class});
            print "     $classstring $valuestring\n";
        }

        print "\nSolution path in the decision tree: @{$solution_paths[$i]}\n";
        printf("\nNumber of nodes created: %d\n", $self->{_root_nodes}->{$i}->how_many_nodes());
    }
    print "\n=================================================================================\n\n";
}

sub trust_weighted_majority_vote_classifier {
    my $self = shift;     
    my @classifications = @{$self->{_classifications}};
    die "You must first call 'classify_with_boosting()' before invoking 'trust_weighted_majority_vote_classifier()'\n"
        unless @classifications; 
    my %decision_classes = map {$_ => 0} @{$self->{_all_trees}->{0}->{_class_names}};
    foreach my $i (0..$self->{_how_many_stages}-1) {
        my %classification = %{$classifications[$i]};                            
        delete $classification{'solution_path'} if exists $classification{'solution_path'};
        my @sorted_classes = sort {$classification{$b} <=> $classification{$a}} keys %classification;
        $decision_classes{$sorted_classes[0]} += $self->{_trust_factors}->{$i};        
    }
    my @sorted_by_weighted_votes_decision_classes = sort {$decision_classes{$b} <=> $decision_classes{$a}} keys %decision_classes;
    my @sorted_class_and_weight_pairs;
    foreach my $class_name (sort {$decision_classes{$b} <=> $decision_classes{$a}} keys %decision_classes) {
        push @sorted_class_and_weight_pairs, [$class_name, $decision_classes{$class_name}];
    }
    $self->{_trust_weighted_decision_classes} = \@sorted_class_and_weight_pairs;
    return $sorted_by_weighted_votes_decision_classes[0];
}

sub display_trust_weighted_decision_for_test_sample {
    my $self = shift;         
    die "You must first call 'trust_weighted_majority_vote_classifier() before invoking display_trust_weighted_decision_for_test_sample()'\n"
        unless $self->{_trust_weighted_decision_classes};
    print "\nClassifier labels for test sample sorted by trust weights (The greater the trust weight, the greater the confidence we have in the classification label):\n\n";
    foreach my $item (@{$self->{_trust_weighted_decision_classes}}) {
        print "$item->[0]   =>    $item->[1]\n";
    }
}

sub classify_with_base_decision_tree {
    my $self = shift; 
    my $test_sample = shift;
    return $self->{_all_trees}->{0}->classify($self->{_root_nodes}->{0}, $test_sample);
}

sub get_all_class_names {
    my $self = shift;     
    return $self->{_all_trees}->{0}->{_class_names};
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
    my @legal_params = qw / how_many_stages
                            training_datafile
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

1;
