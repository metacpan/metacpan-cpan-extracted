package Algorithm::DecisionTreeWithBagging;

#--------------------------------------------------------------------------------------
# Copyright (c) 2017 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::DecisionTreeWithBagging is a Perl module for incorporating bagging in
# decision tree construction and in classification using decision trees.
# -------------------------------------------------------------------------------------

#use lib 'blib/lib', 'blib/arch';

#use 5.10.0;
use strict;
use warnings;
use Carp;
use Algorithm::DecisionTree 3.43;

our $VERSION = '3.43';

############################################   Constructor  ##############################################
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    my %dtargs = %args;
    delete $dtargs{how_many_bags};
    delete $dtargs{bag_overlap_fraction};    
    croak "\nYou have used a wrong name for a keyword argument --- perhaps a misspelling\n" 
                           if check_for_illegal_params(@params) == 0;
    bless {
        _training_datafile            =>  $args{training_datafile}, 
        _csv_class_column_index       =>  $args{csv_class_column_index} || undef,
        _csv_columns_for_features     =>  $args{csv_columns_for_features} || undef,
        _how_many_bags                =>  $args{how_many_bags} || croak("you must specify how_many_bags"),
        _bag_overlap_fraction         =>  $args{bag_overlap_fraction} || 0.20, 
        _csv_cleanup_needed           =>  $args{csv_cleanup_needed} || 0,
        _debug1                       =>  $args{debug1} || 0,
        _number_of_training_samples   =>  undef,
        _segmented_training_data      =>  {},
        _all_trees                    =>  {map {$_ => Algorithm::DecisionTree->new(%dtargs)} 0..$args{how_many_bags} - 1},
        _root_nodes                   =>  [],
        _bag_sizes                    =>  [],
        _classifications              =>  undef,
    }, $class;
}

##############################################  Methods  #################################################
sub get_training_data_for_bagging {
    my $self = shift;
    die("Aborted. get_training_data_csv() is only for CSV files") unless $self->{_training_datafile} =~ /\.csv$/;
    my %class_names = ();
    my %all_record_ids_with_class_labels;
    my $firstline;
    my %data_hash;
    $|++;
    open FILEIN, $self->{_training_datafile} or die "Unable to open $self->{_training_datafile} $!";
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
#    my @all_class_names = sort map {"$class_column_heading=$_"} keys %class_names;
    my @feature_names = map {$all_feature_names[$_]} @{$self->{_csv_columns_for_features}};
    my %class_for_sample_hash = map {"sample_" . $_  =>  "$class_column_heading=" . $data_hash{$_}->[$self->{_csv_class_column_index} - 1 ] } keys %data_hash;
    my @sample_names = map {"sample_$_"} keys %data_hash;
    my %feature_values_for_samples_hash = map {my $sampleID = $_; "sample_" . $sampleID  =>  [map {my $fname = $all_feature_names[$_]; $fname . "=" . eval{$data_hash{$sampleID}->[$_-1] =~ /^\d+$/ ? sprintf("%.1f", $data_hash{$sampleID}->[$_-1] ) : $data_hash{$sampleID}->[$_-1] } } @{$self->{_csv_columns_for_features}} ] }  keys %data_hash;    
    $self->{_number_of_training_samples} = scalar @sample_names;
    fisher_yates_shuffle(\@sample_names);
    print "\nsample names for all samples: @sample_names\n" if $self->{_debug2};
    my $bag_size = int(@sample_names / $self->{_how_many_bags});
    my @data_sample_bags;
    push @data_sample_bags, [splice @sample_names, 0, $bag_size] while @sample_names;
    if (@{$data_sample_bags[-1]} < $bag_size) {
        push @{$data_sample_bags[-2]}, @{$data_sample_bags[-1]}; 
        $#data_sample_bags = @data_sample_bags - 2;
    }
    $self->{_bag_sizes} = [map scalar(@$_), @data_sample_bags];
    print "bag sizes: @{$self->{_bag_sizes}}\n" if $self->{_debug2};
    my @augmented_data_sample_bags = ();
    if ($self->{_bag_overlap_fraction}) {
        my $number_of_samples_needed_from_other_bags = int(@{$data_sample_bags[0]} * $self->{_bag_overlap_fraction});
        print "number of samples needed from other bags: $number_of_samples_needed_from_other_bags\n" if $self->{_debug2};
        foreach my $i (0..$self->{_how_many_bags}-1) {
            my @samples_in_other_bags = ();
            foreach my $j (0..$self->{_how_many_bags}-1) {
                push @samples_in_other_bags, @{$data_sample_bags[$j]} if $j != $i;
            }
            print "\n\nin other bags for i=$i: @samples_in_other_bags\n" if $self->{_debug2};
            push @{$augmented_data_sample_bags[$i]}, @{$data_sample_bags[$i]};
            push @{$augmented_data_sample_bags[$i]}, map $samples_in_other_bags[rand(@samples_in_other_bags)], 0 .. $number_of_samples_needed_from_other_bags -1;
            print "\naugmented bage $i: @{$augmented_data_sample_bags[$i]}\n" if $self->{_debug2};
        }
    }
    @data_sample_bags = @augmented_data_sample_bags;
    $self->{_bag_sizes} = [map scalar(@$_), @data_sample_bags];
    my %class_for_sample_hash_bags =  map { $_ => { map { $_ => $class_for_sample_hash{$_} } @{$data_sample_bags[$_]} } } 0 .. $self->{_how_many_bags} - 1;
    if ($self->{_debug2}) {
        foreach my $bag_index (keys  %class_for_sample_hash_bags) {    
            my %keyval = %{$class_for_sample_hash_bags{$bag_index}};
            print "\nFor bag $bag_index  =>:\n";
            foreach my $sname (keys %keyval) {
                print "      $sname    =>  $keyval{$sname}\n";
            }
        }
    }
    my %feature_values_for_samples_hash_bags = map { $_ => { map { $_ => $feature_values_for_samples_hash{$_} } @{$data_sample_bags[$_]} } } 0 .. $self->{_how_many_bags} - 1;
    if ($self->{_debug2}) {
        print "\nDisplaying samples and their values in each bag:\n\n";
        foreach my $bag_index (keys  %feature_values_for_samples_hash_bags) {   
            my %keyval = %{$feature_values_for_samples_hash_bags{$bag_index}};
            print "\nFor bag $bag_index  =>:\n";
            foreach my $sname (keys %keyval) {
                print "      $sname    =>  @{$keyval{$sname}}\n";
            }
        }
    }
    my %features_and_values_hash = map { my $a = $_; {$all_feature_names[$a] => [  map {my $b = $_; $b =~ /^\d+$/ ? sprintf("%.1f",$b) : $b} map {$data_hash{$_}->[$a-1]} keys %data_hash ]} } @{$self->{_csv_columns_for_features}};     
    if ($self->{_debug2}) {
        print "\nDisplaying features and their values for entire training data:\n\n";
        foreach my $fname (keys  %features_and_values_hash) {         
            print "        $fname    =>  @{$features_and_values_hash{$fname}}\n";
        }
    }
    my %features_and_values_hash_bags =  map { my $c = $_; { $c =>  { map { my $d = $_; {$all_feature_names[$d] => [ sort {$a cmp $b} map {my $f = $_; $f =~ /^\d+$/ ? sprintf("%.1f",$f) : $f} map {$data_hash{sample_index($_)}->[$d-1]} @{$data_sample_bags[$c]} ] } } @{$self->{_csv_columns_for_features}} } } } 0 .. $self->{_how_many_bags} - 1;         
    if ($self->{_debug2}) {
        print "\nDisplaying features and their values in each bag:\n\n";
        foreach my $bag_index (keys  %features_and_values_hash_bags) {           
            my %keyval = %{$features_and_values_hash_bags{$bag_index}};
            print "\nFor bag $bag_index  =>:\n";
            foreach my $fname (keys %keyval) {
                print "      $fname    =>  @{$keyval{$fname}}\n";
            }
        }
    }
    my @all_class_names =  sort keys %{ {map {$_ => 1} values %class_for_sample_hash } };
    print "all class names: @all_class_names\n" if $self->{_debug2};
    my %numeric_features_valuerange_hash_bags   =   map {$_ => {}} 0 .. $self->{_how_many_bags} - 1;
    my %feature_values_how_many_uniques_hash_bags   =   map {$_ => {}} 0 .. $self->{_how_many_bags} - 1;
    my %features_and_unique_values_hash_bags   =   map {$_ => {}} 0 .. $self->{_how_many_bags} - 1;
    my $numregex =  '[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?';
    foreach my $i (0 .. $self->{_how_many_bags} - 1) {
        foreach my $feature (keys %{$features_and_values_hash_bags{$i}}) {
            my %seen = ();
            my @unique_values_for_feature_in_bag =  grep {$_ if $_ ne 'NA' && !$seen{$_}++} @{$features_and_values_hash_bags{$i}{$feature}};
            $feature_values_how_many_uniques_hash_bags{$i}->{$feature} = scalar @unique_values_for_feature_in_bag;
            my $not_all_values_float = 0;
            map {$not_all_values_float = 1 if $_ !~ /^$numregex$/} @unique_values_for_feature_in_bag;
            if ($not_all_values_float == 0) {
                my @minmaxvalues = minmax(\@unique_values_for_feature_in_bag);
                $numeric_features_valuerange_hash_bags{$i}->{$feature} = \@minmaxvalues; 
            }
            $features_and_unique_values_hash_bags{$i}->{$feature} = \@unique_values_for_feature_in_bag;
        }
    }
    if ($self->{_debug2}) {
        print "\nDisplaying value ranges for numeric features in each bag:\n\n";
        foreach my $bag_index (keys  %numeric_features_valuerange_hash_bags) {        
            my %keyval = %{$numeric_features_valuerange_hash_bags{$bag_index}};
            print "\nFor bag $bag_index  =>:\n";
            foreach my $fname (keys %keyval) {
                print "      $fname    =>  @{$keyval{$fname}}\n";
            }
        }
        print "\nDisplaying number of unique values for each features in each bag:\n\n";
        foreach my $bag_index (keys  %feature_values_how_many_uniques_hash_bags) {    
            my %keyval = %{$feature_values_how_many_uniques_hash_bags{$bag_index}};
            print "\nFor bag $bag_index  =>:\n";
            foreach my $fname (keys %keyval) {
                print "      $fname    =>  $keyval{$fname}\n";
            }
        }
        print "\nDisplaying unique values for all features in each bag:\n\n";
        foreach my $bag_index (keys  %features_and_unique_values_hash_bags) {  
            my %keyval = %{$features_and_unique_values_hash_bags{$bag_index}};
            print "\nFor bag $bag_index  =>:\n";
            foreach my $fname (keys %keyval) {
                print "      $fname    =>  @{$keyval{$fname}}\n";
            }
        }
    }
    foreach my $i (0..$self->{_how_many_bags}-1) {
        $self->{_all_trees}->{$i}->{_class_names} = \@all_class_names;
        $self->{_all_trees}->{$i}->{_feature_names} = \@feature_names;
        $self->{_all_trees}->{$i}->{_samples_class_label_hash} = $class_for_sample_hash_bags{$i};
        $self->{_all_trees}->{$i}->{_training_data_hash}  =  $feature_values_for_samples_hash_bags{$i};
        $self->{_all_trees}->{$i}->{_features_and_values_hash}    =  $features_and_values_hash_bags{$i};
        $self->{_all_trees}->{$i}->{_features_and_unique_values_hash} = $features_and_unique_values_hash_bags{$i};
        $self->{_all_trees}->{$i}->{_numeric_features_valuerange_hash} = $numeric_features_valuerange_hash_bags{$i}; 
        $self->{_all_trees}->{$i}->{_feature_values_how_many_uniques_hash} = $feature_values_how_many_uniques_hash_bags{$i};
    }
    if ($self->{_debug1}) {
        foreach my $i (0..$self->{_how_many_bags}-1) {
            print "\n\n=============================   For bag $i   ==================================\n";
            print "\nAll class names: @{$self->{_all_trees}->{$i}->{_class_names}}\n";
            print "\nSamples and their feature values in each bag:\n";
            foreach my $item (sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_all_trees}->{$i}->{_training_data_hash}}) {
                print "$item  =>  @{$self->{_all_trees}->{$i}->{_training_data_hash}->{$item}}\n";
            }
            print "\nclass label for each data sample in each bag:\n";
            foreach my $item (sort {sample_index($a) <=> sample_index($b)} keys %{$self->{_all_trees}->{$i}->{_samples_class_label_hash}} ) {
                print "$item  =>  $self->{_all_trees}->{$i}->{_samples_class_label_hash}->{$item}\n";
            }
            print "\nfeatures and the values taken by them:\n";
            foreach my $item (sort keys %{$self->{_all_trees}->{$i}->{_features_and_values_hash}}) {
                print "$item  =>  @{$self->{_all_trees}->{$i}->{_features_and_values_hash}->{$item}}\n";
            }
            print "\nnumeric features and their ranges:\n";            
            foreach my $item (sort keys %{$self->{_all_trees}->{$i}->{_numeric_features_valuerange_hash}}) {
                print "$item  =>  @{$self->{_all_trees}->{$i}->{_numeric_features_valuerange_hash}->{$item}}\n";
            }
            print "\nnumber of unique values in each feature:\n";
            foreach my $item (sort keys %{$self->{_all_trees}->{$i}->{_feature_values_how_many_uniques_hash}}) {
                print "$item  =>  $self->{_all_trees}->{$i}->{_feature_values_how_many_uniques_hash}->{$item}\n";
            }
        }
    }
}

sub get_number_of_training_samples {
    my $self = shift;
    return $self->{_number_of_training_samples};
}

sub calculate_first_order_probabilities {
    my $self = shift;
    map $self->{_all_trees}->{$_}->calculate_first_order_probabilities(), 0 .. $self->{_how_many_bags}-1;
} 

sub show_training_data_in_bags {
    my $self = shift;
    foreach my $i (0..$self->{_how_many_bags}-1) {
        print "\n\n=============================   For bag $i   ==================================\n";
        $self->{_all_trees}->{$i}->show_training_data()            
    }
}

sub calculate_class_priors {
    my $self = shift;
    map $self->{_all_trees}->{$_}->calculate_class_priors(), 0 .. $self->{_how_many_bags}-1;
}    

sub construct_decision_trees_for_bags {
    my $self = shift;
    $self->{_root_nodes} = 
        [map $self->{_all_trees}->{$_}->construct_decision_tree_classifier(), 0 .. $self->{_how_many_bags}-1];
}

sub display_decision_trees_for_bags {
    my $self = shift;    
    foreach my $i (0 .. $self->{_how_many_bags}-1) {
        print "\n\n=============================   For bag $i   ==================================\n"; 
        $self->{_root_nodes}->[$i]->display_decision_tree("     ");
    }
}

sub classify_with_bagging {
    my $self = shift;        
    my $test_sample = shift;
    $self->{_classifications} = [ map $self->{_all_trees}->{$_}->classify($self->{_root_nodes}->[$_], $test_sample), 0 .. $self->{_how_many_bags}-1 ];
}

sub display_classification_results_for_each_bag {
    my $self = shift;
    die "You must first call 'classify_with_bagging()' before invoking 'display_classification_results_for_each_bag()'" unless $self->{_classifications};
    my @classifications = @{$self->{_classifications}};
    my @solution_paths = map $_->{'solution_path'}, @classifications;
    foreach my $i (0 .. $self->{_how_many_bags}-1) {
        print "\n\n=============================   For bag $i   ==================================\n"; 
        print "\nbag size: $self->{_bag_sizes}->[$i]\n";
        my $classification = $classifications[$i];
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
        print "\nSolution path in the decision tree: @{$solution_paths[$i]}\n";
        print "\nNumber of nodes created: " . $self->{_root_nodes}->[$i]->how_many_nodes() . "\n";

    }
}

sub get_majority_vote_classification {
    my $self = shift;    
    die "You must first call 'classify_with_bagging()' before invoking 'get_majority_vote_classifiction()'" unless $self->{_classifications};
    my @classifications = @{$self->{_classifications}};
    my %decision_classes = map { $_ => 0 } @{$self->{_all_trees}->{0}->{_class_names}};
    foreach my $i (0 .. $self->{_how_many_bags}-1) {
        my $classification = $classifications[$i];
        delete $classification->{'solution_path'} if exists $classification->{'solution_path'};
        my @sorted_classes =  sort {$classification->{$b} <=> $classification->{$a}} keys %$classification; 
        $decision_classes{$sorted_classes[0]}++;
    }
    my @sorted_by_votes_decision_classes = sort {$decision_classes{$b} <=> $decision_classes{$a}} keys %decision_classes;
    return $sorted_by_votes_decision_classes[0];
}

sub get_all_class_names {
    my $self = shift;    
    return $self->{_all_trees}->{0}->{_class_names};
}

#########################################  Utility Routimes  #############################################
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

sub sample_index {
    my $arg = shift;
    $arg =~ /_(.+)$/;
    return $1;
}    

sub bags {
    my ($l,$n) = @_;
    my @bags;
    my $i;
    for ($i=0;  $i < int(@$l/$n); $i++) {
        push @bags, [@{$l}[$i*$n..($i+1)*$n-1]];
    }
    push @{$bags[-1]}, @{$l}[$i*$n..@{$l}-1];
    return \@bags;
}

sub check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / how_many_bags
                            bag_overlap_fraction
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

# from perl docs:                                                                         
sub fisher_yates_shuffle {
    my $arr =  shift;
    my $i = @$arr;
    while (--$i) {
        my $j = int rand( $i + 1 );
        @$arr[$i, $j] = @$arr[$j, $i];
    }
}

sub cleanup_csv {
    my $line = shift;
    $line =~ tr/\/:?()[]{}'/          /;
#    my @double_quoted = substr($line, index($line,',')) =~ /\"[^\"]+\"/g;
    my @double_quoted = substr($line, index($line,',')) =~ /\"[^\"]*\"/g;
    for (@double_quoted) {
        my $item = $_;
        $item = substr($item, 1, -1);
        $item =~ s/^\s+|,|\s+$//g;
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
