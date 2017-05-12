package Algorithm::RandomizedTreesForBigData;

#--------------------------------------------------------------------------------------
# Copyright (c) 2016 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::RandomizedTreesForBigData is a Perl module for inducing multiple decision
# trees using randomized selection of samples from a large training data file.
# -------------------------------------------------------------------------------------

use lib 'blib/lib', 'blib/arch';

#use 5.10.0;
use strict;
use warnings;
use Carp;
use List::Util qw(pairmap);
use Algorithm::DecisionTree 3.42;

our $VERSION = '3.42';

############################################   Constructor  ##############################################
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    my %dtargs = %args;
    delete $dtargs{how_many_trees};
    delete $dtargs{how_many_training_samples_per_tree} if exists $dtargs{how_many_training_samples_per_tree};
    delete $dtargs{looking_for_needles_in_haystack} if exists $dtargs{looking_for_needles_in_haystack};
    croak "\nYou have used a wrong name for a keyword argument --- perhaps a misspelling\n" 
                           if check_for_illegal_params(@params) == 0;
    bless {
        _all_trees              =>  {map {$_ => Algorithm::DecisionTree->new(%dtargs)} 0..$args{how_many_trees}-1},
        _csv_cleanup_needed                    =>  $args{csv_cleanup_needed} || 0,
        _looking_for_needles_in_haystack       =>  $args{looking_for_needles_in_haystack}, 
        _how_many_training_samples_per_tree    =>  $args{how_many_training_samples_per_tree},
        _training_datafile                     =>  $args{training_datafile}, 
        _csv_class_column_index                =>  $args{csv_class_column_index} || undef,
        _csv_columns_for_features              =>  $args{csv_columns_for_features} || undef,
        _how_many_trees                        =>  $args{how_many_trees} || die "must specify number of trees",
        _root_nodes                            =>  [],
        _training_data_for_trees               =>  {map {$_ => []} 0..$args{how_many_trees} - 1},
        _all_record_ids                        =>  [],
        _training_data_record_indexes          =>  {},
        _classifications                       =>  undef,
        _debug1                                =>  $args{debug1},
    }, $class;
}

##############################################   Methods  ################################################
sub get_training_data_for_N_trees {
    my $self = shift;
    die("Aborted. get_training_data_csv() is only for CSV files") unless $self->{_training_datafile} =~ /\.csv$/;
    my @all_record_ids;
    open FILEIN, $self->{_training_datafile} or die "Unable to open $self->{_training_datafile} $!";
    my $record_index = 0;
    while (<FILEIN>) {
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        my $record = $self->{_csv_cleanup_needed} ? cleanup_csv($_) : $_;
        push @{$self->{_all_record_ids}}, substr($record, 0, index($record, ','));
        $record_index++;
    }
    close FILEIN;
    $self->{_how_many_total_training_samples} = $record_index - 1;
    print "\n\nTotal number of training samples: $self->{_how_many_total_training_samples}\n" if $self->{_debug1};
    print "\n\nAll record labels: @{$self->{_all_record_ids}}\n" if $self->{_debug1};
    if ($self->{_looking_for_needles_in_haystack}) {
        $self->get_training_data_for_N_trees_balanced();
    } else {
        $self->get_training_data_for_N_trees_regular();
    }
}
    
sub get_training_data_for_N_trees_balanced {
    my $self = shift;    
    die "You cannot use the contructor option 'how_many_training_samples_per_tree' if you " .
        "have set the option 'looking_for_needles_in_haystack' " if $self->{_how_many_training_samples_per_tree};
    my @class_names;
    my %unique_class_names;
    my %all_record_ids_with_class_labels;
    $|++;
    open FILEIN, $self->{_training_datafile} or die "Unable to open $self->{_training_datafile} $!";
    my $i = 0;
    while (<FILEIN>) {
        next if /^[ ]*\r?\n?$/;
        $_ =~ s/\r?\n?$//;
        if ($i == 0) {
            $i++;
            next;
        }
        my $record = $self->{_csv_cleanup_needed} ? cleanup_csv($_) : $_;
        my @parts = split /,/, $record;
        my $classname = $parts[$self->{_csv_class_column_index}];
        push @class_names, $classname;
        $unique_class_names{$classname} = 1;
        my $record_label = shift @parts;
        $record_label  =~ s/^\s*\"|\"\s*$//g;
        $all_record_ids_with_class_labels{$record_label} = $classname;
        print "." if $i % 10000 == 0;
        $i++;
    }
    close FILEIN;
    $|--;
    my @unique_class_names = sort keys %unique_class_names;
    my $num_unique_classnames = @unique_class_names;
    die "\n\n'looking_for_needles_in_haystack' option has only been tested for the case of " .
        "two data classes.  You appear to have $num_unique_classnames data classes. If you know " .
        "that you have specified only two classes, perhaps you need to use the constructor option " .
        "'csv_cleanup_needed'. Aborting." if @unique_class_names > 2;
    print "\n\nunique class names: @unique_class_names\n" if $self->{_debug1};
    my %hist = map {$_ => 0} @unique_class_names;
    foreach my $item (@class_names) {
        foreach my $unique_val (@unique_class_names) {
            if ($item eq $unique_val) {
                $hist{$unique_val}++;
                last;
            }
        }
    }
    if ($self->{_debug1}) {
        print "\nhistogram of the values for the field : ";
        foreach my $key (sort keys %hist) {
            print "$key => $hist{$key}   ";
        }
    }
    my @histvals = values %hist;
    my @hist_minmax = minmax( \@histvals );
    my $ max_number_of_trees_possible = int($hist_minmax[1] / $hist_minmax[0]);
    if ($self->{_debug1}) {      
        print "\n\nmaximum number of trees possible: $max_number_of_trees_possible\n";
    }
    die "\n\nYou have asked for more trees than can be supported by the training data. " .
        "Maxinum number of trees that can be constructed from the training file is: $max_number_of_trees_possible\n"
        if $self->{_how_many_trees} > $ max_number_of_trees_possible;
    
    my %class1 = map {$_->[0] => $_->[1]} grep {@$_ > 0} map {  $_->[1] eq $unique_class_names[0] ? [$_->[0], $_->[1]] : [] } pairmap {[$a,$b]} %all_record_ids_with_class_labels;    

    my %class2 = map {$_->[0] => $_->[1]} grep {@$_ > 0} map {  $_->[1] eq $unique_class_names[1] ? [$_->[0], $_->[1]] : [] } pairmap {[$a,$b]} %all_record_ids_with_class_labels;        
    my %minority_class = scalar(keys %class1) >= scalar(keys %class2) ? %class2 : %class1;
    my %majority_class = scalar(keys %class1) >= scalar(keys %class2) ? %class1 : %class2;
    my @minority_records = sort keys %minority_class;
    my @majority_records = sort keys %majority_class;
    print "\n\nminority records: @minority_records\n" if $self->{_debug1};
    $self->{_how_many_training_samples_per_tree} = 2 * @minority_records;
    $self->{_training_data_record_indexes}  = {map {my $t = $_; $t => [map { $majority_records[rand @majority_records] } 0 .. @minority_records - 1]}   0 .. $self->{_how_many_trees} - 1};  
    map {my $t = $_; push @{$self->{_training_data_record_indexes}->{$t}}, @minority_records} 0 .. $self->{_how_many_trees} - 1;      
    if ($self->{_debug1}) {
        print "\n Displaying records in the different training sets:\n";
        foreach my $t (sort {$a <=> $b} keys %{$self->{_training_data_record_indexes}}) {
            print "\n\n$t   =>   @{$self->{_training_data_record_indexes}->{$t}}\n";
        }
    }
    $self->_digest_training_data_all_trees();
}

sub get_training_data_for_N_trees_regular {
    my $self = shift;        
    die "You cannot use the contructor option 'looking_for_needles_in_haystack' if you " .
        "have set the option 'how_many_training_samples_per_tree' " if $self->{_looking_for_needles_in_haystack};
    $self->{_training_data_record_indexes}  = {map {my $t = $_; $t => [map { $self->{_all_record_ids}->[rand @{$self->{_all_record_ids}}] } 0 .. $self->{_how_many_training_samples_per_tree} ] } 0 .. $self->{_how_many_trees} - 1};
    $self->_digest_training_data_all_trees();
}

sub _digest_training_data_all_trees {
    my $self = shift;        
    my $firstline;
    open FILEIN, $self->{_training_datafile} || die "unable to open $self->{_training_datafile}: $!";
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
        foreach my $t (keys %{$self->{_training_data_record_indexes}}) {
            push @{$self->{_training_data_for_trees}->{$t}}, $record
                if (contained_in(substr($record, 0, index($record, ',')), 
                                 @{$self->{_training_data_record_indexes}->{$t}}));
        }
        $record_index++;
    }
    close FILEIN;    
    my $splitup_data_for_trees = {map {my $t = $_; $t => [map {my $record = $_; [split /,/, $record]} @{$self->{_training_data_for_trees}->{$t}}]} 0 .. $self->{_how_many_trees} - 1};
    my $data_hash_for_all_trees = {map {my $t = $_; $t => {map {my $record = $_; my $record_lbl = shift @{$record}; $record_lbl =~ s/^\s*\"|\"\s*$//g; $record_lbl => $record} @{$splitup_data_for_trees->{$t}}}} 0 .. $self->{_how_many_trees} - 1};
    if ($self->{_debug1}) {
        foreach my $t (0 .. $self->{_how_many_trees} - 1) {
            my @record_labels = keys %{$data_hash_for_all_trees->{$t}};
            print "\n\nFor tree $t: record labels: @record_labels\n";
            for my $kee (sort keys %{$data_hash_for_all_trees->{$t}}) {
                print "$kee   ----->   @{$data_hash_for_all_trees->{$t}->{$kee}}\n";
            }
        }
    }
    my @all_feature_names = split /,/, $firstline;
    my $class_column_heading = $all_feature_names[$self->{_csv_class_column_index}];
    my @feature_names = map {$all_feature_names[$_]} @{$self->{_csv_columns_for_features}};
    print "\n\nclass column heading: $class_column_heading\n";
    print "feature names: @feature_names\n";
    my $class_for_sample_all_trees = {map {my $t = $_; $t => {map {my $lbl = $_; "sample_$lbl" => "$class_column_heading=$data_hash_for_all_trees->{$t}->{$lbl}->[$self->{_csv_class_column_index} - 1]" } keys %{$data_hash_for_all_trees->{$t}} } }  0 .. $self->{_how_many_trees} - 1};
    if ($self->{_debug1}) {
        foreach my $t (0 .. $self->{_how_many_trees} - 1) {
            my @sample_labels = keys %{$class_for_sample_all_trees->{$t}};
            print "\n\nFor tree $t: sample labels: @sample_labels\n";    
            for my $kee (sort keys %{$class_for_sample_all_trees->{$t}}) {
                print "$kee   ----->   $class_for_sample_all_trees->{$t}->{$kee}\n";
            }
        }
    }
    my $sample_names_in_all_trees = {map {my $t = $_; $t => [map {"sample_$_"} keys %{$data_hash_for_all_trees->{$t}}]}  0 .. $self->{_how_many_trees} - 1};
    my $feature_values_for_samples_all_trees = {map {my $t = $_; $t => {map {my $key = $_; "sample_$key" => [map {my $feature_name = $all_feature_names[$_]; "$feature_name=$data_hash_for_all_trees->{$t}->{$key}->[$_-1]"} @{$self->{_csv_columns_for_features}} ] } keys %{$data_hash_for_all_trees->{$t}} } }  0 .. $self->{_how_many_trees} - 1};
    if ($self->{_debug1}) {
        foreach my $t (0 .. $self->{_how_many_trees} - 1) {
            my @sample_labels = keys %{$feature_values_for_samples_all_trees->{$t}};
            print "\n\nFor tree $t: sample labels: @sample_labels\n";    
            for my $kee (sort keys %{$feature_values_for_samples_all_trees->{$t}}) {
                print "$kee   ----->   @{$feature_values_for_samples_all_trees->{$t}->{$kee}}\n";
            }
        }
    }
    my $features_and_values_all_trees = {map {my $t = $_; $t => {map {my $i = $_; $all_feature_names[$i] => [map {my $key = $_; $data_hash_for_all_trees->{$t}->{$key}->[$i-1]} keys %{$data_hash_for_all_trees->{$t}}]} @{$self->{_csv_columns_for_features} } } } 0 .. $self->{_how_many_trees} - 1};
    if ($self->{_debug1}) {
        foreach my $t (0 .. $self->{_how_many_trees} - 1) {
            my @feature_labels = keys %{$features_and_values_all_trees->{$t}};
            print "\n\nFor tree $t: feature labels: @feature_labels\n";    
            for my $kee (sort keys %{$features_and_values_all_trees->{$t}}) {
                print "$kee   ----->   @{$features_and_values_all_trees->{$t}->{$kee}}\n";
            }
        }
    }
    my $all_class_names_all_trees = {map {my $t = $_; my %all_class_labels_in_tree = map {$_ => 1} values %{$class_for_sample_all_trees->{$t}}; my @uniques = keys %all_class_labels_in_tree; $t => \@uniques } 0 .. $self->{_how_many_trees} - 1};
    if ($self->{_debug1}) {
        foreach my $t (0 .. $self->{_how_many_trees} - 1) {
            my @unique_class_names_for_tree = @{$all_class_names_all_trees->{$t}};
            print "\n\nFor tree $t: all unique class names: @unique_class_names_for_tree\n";    
        }
    }
    my $numeric_features_valuerange_all_trees = {map {my $t = $_; $t => {}} 0 .. $self->{_how_many_trees} - 1};
    my $feature_values_how_many_uniques_all_trees = {map {my $t = $_; $t => {}} 0 .. $self->{_how_many_trees} - 1};
    my $features_and_unique_values_all_trees = {map {my $t = $_; $t => {}} 0 .. $self->{_how_many_trees} - 1};
    my $numregex =  '[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?';
    foreach my $t (0 .. $self->{_how_many_trees} - 1) {    
        foreach my $feature (sort keys %{$features_and_values_all_trees->{$t}}) {
            my %all_values_for_feature =  map {$_ => 1} @{$features_and_values_all_trees->{$t}->{$feature}};
            my @unique_values_for_feature = grep {$_ ne 'NA'} keys %all_values_for_feature;
            $feature_values_how_many_uniques_all_trees->{$t}->{$feature} = scalar @unique_values_for_feature;
            my $not_all_values_float = 0;
            map {$not_all_values_float = 1 if $_ !~ /^$numregex$/} @unique_values_for_feature;
            if ($not_all_values_float == 0) {
                my @minmaxvalues = minmax(\@unique_values_for_feature);
                $numeric_features_valuerange_all_trees->{$t}->{$feature} = \@minmaxvalues; 
            }
            $features_and_unique_values_all_trees->{$t}->{$feature} = \@unique_values_for_feature;            
        }
    }
    if ($self->{_debug1}) {
        print "\nDisplaying value ranges for numeric features for all trees:\n\n";
        foreach my $tree_index (keys  %{$numeric_features_valuerange_all_trees}) {        
            my %keyval = %{$numeric_features_valuerange_all_trees->{$tree_index}};
            print "\nFor tree $tree_index  =>:\n";
            foreach my $fname (keys %keyval) {
                print "      $fname    =>  @{$keyval{$fname}}\n";
            }
        }
        print "\nDisplaying number of unique values for each features for each tree:\n\n";
        foreach my $tree_index (keys  %{$feature_values_how_many_uniques_all_trees}) {    
            my %keyval = %{$feature_values_how_many_uniques_all_trees->{$tree_index}};
            print "\nFor tree $tree_index  =>:\n";
            foreach my $fname (keys %keyval) {
                print "      $fname    =>  $keyval{$fname}\n";
            }
        }
        print "\nDisplaying unique values for all features for all trees:\n\n";
        foreach my $tree_index (keys  %{$features_and_unique_values_all_trees}) {  
            my %keyval = %{$features_and_unique_values_all_trees->{$tree_index}};
            print "\nFor tree $tree_index  =>:\n";
            foreach my $fname (keys %keyval) {
                print "      $fname    =>  @{$keyval{$fname}}\n";
            }
        }
    }
    foreach my $t (0..$self->{_how_many_trees}-1) {
        $self->{_all_trees}->{$t}->{_class_names} = $all_class_names_all_trees->{$t};
        $self->{_all_trees}->{$t}->{_feature_names} = \@feature_names;
        $self->{_all_trees}->{$t}->{_samples_class_label_hash} = $class_for_sample_all_trees->{$t};
        $self->{_all_trees}->{$t}->{_training_data_hash}  =  $feature_values_for_samples_all_trees->{$t};
        $self->{_all_trees}->{$t}->{_features_and_values_hash}    =  $features_and_values_all_trees->{$t};
        $self->{_all_trees}->{$t}->{_features_and_unique_values_hash} = $features_and_unique_values_all_trees->{$t};
        $self->{_all_trees}->{$t}->{_numeric_features_valuerange_hash} = $numeric_features_valuerange_all_trees->{$t}; 
        $self->{_all_trees}->{$t}->{_feature_values_how_many_uniques_hash} = $feature_values_how_many_uniques_all_trees->{$t};
    }
    if ($self->{_debug1}) {
        foreach my $t (0..$self->{_how_many_trees}-1) {
            print "\n\n=============================   For Tree $t   ==================================\n";
            print "\nAll class names: @{$self->{_all_trees}->{$t}->{_class_names}}\n";
            print "\nSamples and their feature values for each tree:\n";
            foreach my $item (sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_all_trees}->{$t}->{_training_data_hash}}) {
                print "$item  =>  @{$self->{_all_trees}->{$t}->{_training_data_hash}->{$item}}\n";
            }
            print "\nclass label for each data sample for each tree:\n";
            foreach my $item (sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_all_trees}->{$t}->{_samples_class_label_hash}} ) {
                print "$item  =>  $self->{_all_trees}->{$t}->{_samples_class_label_hash}->{$item}\n";
            }
            print "\nfeatures and the values taken by them:\n";
            foreach my $item (sort keys %{$self->{_all_trees}->{$t}->{_features_and_values_hash}}) {
                print "$item  =>  @{$self->{_all_trees}->{$t}->{_features_and_values_hash}->{$item}}\n";
            }
            print "\nnumeric features and their ranges:\n";            
            foreach my $item (sort keys %{$self->{_all_trees}->{$t}->{_numeric_features_valuerange_hash}}) {
                print "$item  =>  @{$self->{_all_trees}->{$t}->{_numeric_features_valuerange_hash}->{$item}}\n";
            }
            print "\nnumber of unique values in each feature:\n";
            foreach my $item (sort keys %{$self->{_all_trees}->{$t}->{_feature_values_how_many_uniques_hash}}) {
                print "$item  =>  $self->{_all_trees}->{$t}->{_feature_values_how_many_uniques_hash}->{$item}\n";
            }
        }
    }
}    

sub show_training_data_for_all_trees {
    my $self = shift;
    foreach my $t (0..$self->{_how_many_trees}-1) {
        print "\n\n=============================   For Tree $t   ==================================\n";
        $self->{_all_trees}->{$t}->show_training_data();
    }
}

sub calculate_first_order_probabilities {
    my $self = shift;
    map $self->{_all_trees}->{$_}->calculate_first_order_probabilities(), 0 .. $self->{_how_many_trees}-1;
} 

sub calculate_class_priors {
    my $self = shift;
    map $self->{_all_trees}->{$_}->calculate_class_priors(), 0 .. $self->{_how_many_trees}-1;
}    

sub construct_all_decision_trees {
    my $self = shift;
    $self->{_root_nodes} = 
        [map $self->{_all_trees}->{$_}->construct_decision_tree_classifier(), 0 .. $self->{_how_many_trees}-1];
}

sub display_all_decision_trees {
    my $self = shift;    
    foreach my $t (0 .. $self->{_how_many_trees}-1) {
        print "\n\n=============================   For Tree $t   ==================================\n"; 
        $self->{_root_nodes}->[$t]->display_decision_tree("     ");
    }
}

sub classify_with_all_trees {
    my $self = shift;        
    my $test_sample = shift;
    $self->{_classifications} = [ map $self->{_all_trees}->{$_}->classify($self->{_root_nodes}->[$_], $test_sample), 0 .. $self->{_how_many_trees}-1 ];
}

sub display_classification_results_for_all_trees {
    my $self = shift;
    die "You must first call 'classify_with_with_all_trees()' before invoking 'display_classification_results_for_all_trees()'" unless $self->{_classifications};
    my @classifications = @{$self->{_classifications}};
    my @solution_paths = map $_->{'solution_path'}, @classifications;
    foreach my $t (0 .. $self->{_how_many_trees}-1) {
        print "\n\n=============================   For Tree $t   ==================================\n"; 
        print "\nnumber of training samples used: $self->{_how_many_training_samples_per_tree}\n";
        my $classification = $classifications[$t];
        delete $classification->{'solution_path'};
        my @which_classes = sort {$classification->{$b} <=> $classification->{$a}} keys %$classification;
        print "\nClassification:\n\n";
        print "     class                         probability\n";
        print "     ----------                    -----------\n";
        foreach my $which_class (@which_classes) {
            my $classstring = sprintf("%-30s", $which_class);
            my $valuestring = sprintf("%-30s", $classification->{$which_class});
            print "     $classstring $valuestring\n";
        }
        print "\nSolution path in the decision tree: @{$solution_paths[$t]}\n";
        print "\nNumber of nodes created: " . $self->{_root_nodes}->[$t]->how_many_nodes() . "\n";

    }
}

sub get_majority_vote_classification {
    my $self = shift;    
    die "You must first call 'classify_with_all_trees()' before invoking 'get_majority_vote_classifiction()'" unless $self->{_classifications};
    my @classifications = @{$self->{_classifications}};
    my %decision_classes = map { $_ => 0 } @{$self->{_all_trees}->{0}->{_class_names}};
    foreach my $t (0 .. $self->{_how_many_trees}-1) {
        my $classification = $classifications[$t];
        delete $classification->{'solution_path'} if exists $classification->{'solution_path'};
        my @sorted_classes =  sort {$classification->{$b} <=> $classification->{$a}} keys %$classification; 
        $decision_classes{$sorted_classes[0]}++;
    }
    my @sorted_by_votes_decision_classes = sort {$decision_classes{$b} <=> $decision_classes{$a}} keys %decision_classes;
    return $sorted_by_votes_decision_classes[0];
}

########################################  Utility Routines  ##############################################
sub sample_index {
    my $arg = shift;
    $arg =~ /_(.+)$/;
    return $1;
}    

# checks whether an element is in an array:
sub contained_in {
    my $ele = shift;
    my @array = @_;
    my $count = 0;
    map {$count++ if $ele eq $_} @array;
    return $count;
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

sub check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / training_datafile
                            entropy_threshold
                            max_depth_desired
                            csv_class_column_index
                            csv_columns_for_features
                            symbolic_to_numeric_cardinality_threshold
                            number_of_histogram_bins
                            how_many_trees
                            how_many_training_samples_per_tree
                            looking_for_needles_in_haystack
                            csv_cleanup_needed
                            debug1
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
