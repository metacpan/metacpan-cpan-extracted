#!/usr/bin/env perl

### bagging_for_bulk_classificaiton.pl

##  Call syntax example:

##         bagging_for_bulk_classification.pl  training5.csv  test5.csv  out5.csv

##  This script demonstrates how you can use bagging to carry out bulk classification
##  of data records in an input csv file.  

use strict;
use warnings;
use Algorithm::DecisionTreeWithBagging;

die "This script must be called with exactly three command-line arguments:\n" .
    "     1st arg: name of the training datafile\n" .
    "     2nd arg: name of the test data file\n" .     
    "     3rd arg: the name of the output file to which class labels will be written\n" 
    unless @ARGV == 3;

my $debug = 0;

my ($training_datafile, $test_datafile, $outputfile) = @ARGV;

my $training_file_class_name_in_column       = 1;
my $training_file_columns_for_feature_values = [2,3];
my $how_many_bags                            = 4;
my $bag_overlap_fraction                     = 0.2;

my (@all_class_names, @feature_names, %class_for_sample_hash, %feature_values_for_samples_hash,
    %features_and_values_hash, %features_and_unique_values_hash,
    %numeric_features_valuerange_hash, %feature_values_how_many_uniques_hash);


########################################################################################
###############  Read the Input Test Datafile and Classify Each Record  ################

### First construct an instance of the DecisionTree class:

my $dtbag = Algorithm::DecisionTreeWithBagging->new( 
                          training_datafile =>  $training_datafile,
                          csv_class_column_index => $training_file_class_name_in_column,
                          csv_columns_for_features => $training_file_columns_for_feature_values,
                          entropy_threshold => 0.01,
                          max_depth_desired => 5,
                          symbolic_to_numeric_cardinality_threshold => 10,
                          how_many_bags => $how_many_bags,
                          bag_overlap_fraction => $bag_overlap_fraction,
                          csv_cleanup_needed => 1,
            );

$dtbag->get_training_data_for_bagging();

##  UNCOMMENT the following statement if you want to see the training data used for individual bags
#$dtbag->show_training_data_in_bags();

my $how_many_samples = $dtbag->get_number_of_training_samples();
if ($how_many_samples > 1000) {
    print "\nYou have $how_many_samples training samples and $how_many_bags bags. Be patient!\n";
}

$dtbag->calculate_first_order_probabilities();

$dtbag->calculate_class_priors();

$dtbag->construct_decision_trees_for_bags();

##  UNCOMMENT the following statement if you want to see the decision trees constructed for each bag
$dtbag->display_decision_trees_for_bags();

### NOW YOU ARE READY TO CLASSIFY THE FILE-BASED TEST DATA:
get_test_data_from_csv();

open FILEOUT, ">$outputfile"
    or die "Unable to open file $outputfile for writing out classification results: $!";

my $class_names = join ",", sort @{$dtbag->get_all_class_names()};

my $output_string = "sample_index,$class_names\n";

print FILEOUT $output_string;

foreach my $item (sort {sample_index($a) <=> sample_index($b)} keys %feature_values_for_samples_hash) {
    my $test_sample =  $feature_values_for_samples_hash{$item};
    $dtbag->classify_with_bagging($test_sample);
    my $classification = $dtbag->get_majority_vote_classification();
    my $output_string = sample_index($item);
#    $output_string .=  "," + $classification[11:]    
    $output_string .=  ",$classification";
    print FILEOUT "$output_string\n";
}

print "Majority vote classifications from the bags written out to $outputfile\n";

########################################################################################
###############################    Support Routines     ################################

sub get_test_data_from_csv {
    open FILEIN, $test_datafile or die "Unable to open $test_datafile: $!";
    die("Aborted. get_test_data_csv() is only for CSV files") 
                                           unless $test_datafile =~ /\.csv$/;
    my $class_name_in_column = $training_file_class_name_in_column - 1;
    my @all_data =  <FILEIN>;
    my %data_hash = ();
    foreach my $record (@all_data) {
        my @fields =  map {$_ =~ s/^\s*|\s*$//; $_} split /,/, $record;
        my @fields_after_first = @fields[1..$#fields]; 
        $data_hash{$fields[0]} = \@fields_after_first;
    }
    die 'Aborted. The first row of CSV file must begin with "" and then list the feature names and class names'  unless exists $data_hash{'""'};
    my @field_names = map {$_ =~ s/^\s*\"|\"\s*$//g;$_} @{$data_hash{'""'}};
    my $class_column_heading = $field_names[$class_name_in_column];
    @feature_names = map {$field_names[$_-1]} @{$training_file_columns_for_feature_values};
    $class_column_heading =~ s/^\s*\"|\"\s*$//g;
    %class_for_sample_hash = ();
    %feature_values_for_samples_hash = ();
    foreach my $key (keys %data_hash) {
        next if $key =~ /^\"\"$/;
        my $cleanedup = $key;
        $cleanedup =~ s/^\s*\"|\"\s*$//g;
        my $which_class = $data_hash{$key}[$class_name_in_column];
        $which_class  =~ s/^\s*\"|\"\s*$//g;
        $class_for_sample_hash{"sample_$cleanedup"} = "$class_column_heading=$which_class";
        my @features_and_values_list = ();
        foreach my $i (@{$training_file_columns_for_feature_values}) {
            my $feature_column_header = $field_names[$i-1];
            my $feature_val = $data_hash{$key}->[$i-1];
            $feature_val  =~ s/^\s*\"|\"\s*$//g;
            $feature_val = sprintf("%.1f",$feature_val) if $feature_val =~ /^\d+$/;
            push @features_and_values_list,  "$feature_column_header=$feature_val";
        }
        $feature_values_for_samples_hash{"sample_" . $cleanedup} = \@features_and_values_list;
    }
    %features_and_values_hash = ();
    foreach my $i (@{$training_file_columns_for_feature_values}) {
        my $feature = $data_hash{'""'}[$i-1];
        $feature =~ s/^\s*\"|\"\s*$//g;
        my @feature_values = ();
        foreach my $key (keys %data_hash) {     
            next if $key =~ /^\"\"$/;
            my $feature_val = $data_hash{$key}[$i-1];
            $feature_val =~ s/^\s*\"|\"\s*$//g;
            $feature_val = sprintf("%.1f",$feature_val) if $feature_val =~ /^\d+$/;
            push @feature_values, $feature_val;
        }
        $features_and_values_hash{$feature} = \@feature_values;
    }
    my %seen = ();
    @all_class_names = grep {$_ if !$seen{$_}++}  values %class_for_sample_hash;
    print "\n All class names: @all_class_names\n" if $debug;
    %numeric_features_valuerange_hash = ();
    my %feature_values_how_many_uniques_hash = ();
    %features_and_unique_values_hash = ();
    foreach my $feature (keys %features_and_values_hash) {
        my %seen1 = ();
        my @unique_values_for_feature = sort grep {$_ if $_ ne 'NA' && !$seen1{$_}++} 
                                                   @{$features_and_values_hash{$feature}};
        $feature_values_how_many_uniques_hash{$feature} = scalar @unique_values_for_feature;
        my $not_all_values_float = 0;
        map {$not_all_values_float = 1 if $_ !~ /^\d*\.\d+$/} @unique_values_for_feature;
        if ($not_all_values_float == 0) {
            my @minmaxvalues = minmax(\@unique_values_for_feature);
            $numeric_features_valuerange_hash{$feature} = \@minmaxvalues; 
        }
        $features_and_unique_values_hash{$feature} = \@unique_values_for_feature;
    }
    if ($debug) {
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

