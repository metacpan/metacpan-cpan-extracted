#!/usr/bin/env perl

##  classify_test_data_in_a_file.pl

##  Call syntax:  classify_test_data_in_a_file.pl   training4.csv   test4.csv   out4.csv

##  See the README in the Examples directory for further information.

use strict;
use warnings;
use Algorithm::DecisionTree;

die "This script must be called with exactly three command-line arguments:\n" .
    "     1st arg: name of the training datafile\n" .
    "     2nd arg: name of the test data file\n" .     
    "     3rd arg: the name of the output file to which class labels will be written\n" 
    unless @ARGV == 3;

my $debug = 0;

### When the following variable is set to 1, only the most probable class for each
### data record is written out to the output file.  This works only for the case
### when the output is sent to a `.txt' file.  If the output is sent to a `.csv' 
### file, you'll see all the class names and their probabilities for each data sample
### in your test datafile.
my $show_hard_classifications = 1;

my ($training_datafile, $test_datafile, $outputfile) = @ARGV;

my $dt = Algorithm::DecisionTree->new( 
                 training_datafile => $training_datafile,
                 csv_class_column_index => 1,        # col indexing is 0 based
                 csv_columns_for_features => [2,3],
                 entropy_threshold => 0.01,
                 max_depth_desired => 3,
                 symbolic_to_numeric_cardinality_threshold => 10,
                 csv_cleanup_needed => 1,
        );

$dt->get_training_data();
$dt->calculate_first_order_probabilities();
$dt->calculate_class_priors();

### UNCOMMENT THE NEXT STATEMENT if you would like to see
### the training data that was read from the disk file:
#$dt->show_training_data();

my $root_node = $dt->construct_decision_tree_classifier();


### UNCOMMENT THE NEXT STATEMENT if you would like to see
### the decision tree displayed in your terminal window:
#$root_node->display_decision_tree("   ");

# NOW YOU ARE READY TO CLASSIFY THE FILE BASED TEST DATA:
my (@all_class_names, @feature_names, %class_for_sample_hash, %feature_values_for_samples_hash,
    %features_and_values_hash, %features_and_unique_values_hash, 
    %numeric_features_valuerange_hash, %feature_values_how_many_uniques_hash);

get_test_data_from_csv();
open OUTPUTHANDLE, ">$outputfile"
    or die "Unable to open the file $outputfile for writing out the classification results: $!";
if ($show_hard_classifications && ($outputfile !~ /\.csv$/i)) {
    print OUTPUTHANDLE "\nOnly the most probable class shown for each test sample\n\n";
} elsif (!$show_hard_classifications && ($outputfile !~ /\.csv$/i)) {
    print OUTPUTHANDLE "\nThe classification result for each sample ordered in decreasing order of probability\n\n";
}
if ($outputfile =~ /\.csv$/i) {
    my $class_names_csv = join ',', sort @{$dt->{_class_names}};
    my $output_string = "sample_index,$class_names_csv\n";
    print OUTPUTHANDLE "$output_string";
    foreach my $sample (sort {sample_index($a) <=> sample_index($b)} 
                                       keys %feature_values_for_samples_hash) {
        my @test_sample =  @{$feature_values_for_samples_hash{$sample}};
        my %classification = %{$dt->classify($root_node, \@test_sample)};
        my $sample_index = sample_index($sample);
        my @solution_path = @{$classification{'solution_path'}};
        delete $classification{'solution_path'};
        my @which_classes = sort keys %classification;
        $output_string = "$sample_index";
        foreach my $which_class (@which_classes) {
            $which_class =~ /=(.*)/;
            my $class_name = $1;
            my $valuestring = $classification{$which_class};
            $output_string .= ",$valuestring";
        }
        print OUTPUTHANDLE "$output_string\n";
    }
} else {
    foreach my $sample (sort {sample_index($a) <=> sample_index($b)} 
                                       keys %feature_values_for_samples_hash) {
        my @test_sample =  @{$feature_values_for_samples_hash{$sample}};
        my %classification = %{$dt->classify($root_node, \@test_sample)};
        my @solution_path = @{$classification{'solution_path'}};
        delete $classification{'solution_path'};
        my @which_classes = keys %classification;
        @which_classes = sort {$classification{$b} <=> $classification{$a}} @which_classes;
        my $result_string = "$sample:   ";
        if ($show_hard_classifications) {
            my $which_class = $which_classes[0];
            $which_class =~ /=(.*)/;
            my $class_name = $1;
            my $valuestring = sprintf("%-20s", $classification{$which_class});
            $result_string .= "$class_name => $valuestring    ";
            print OUTPUTHANDLE "$result_string\n";
        } else {
            foreach my $which_class (@which_classes) {
                $which_class =~ /=(.*)/;
                my $class_name = $1;
                my $valuestring = sprintf("%-20s", $classification{$which_class});
                $result_string .= "$class_name => $valuestring    ";
            }
            print OUTPUTHANDLE "$result_string\n";
        }
    }
}

sub get_test_data_from_csv {
    open FILEIN, $test_datafile or die "Unable to open $test_datafile: $!";
    die("Aborted. get_test_data_csv() is only for CSV files") 
                                           unless $test_datafile =~ /\.csv$/;
    my $class_name_in_column = $dt->{_csv_class_column_index} - 1; 
    my @all_data =  <FILEIN>;
    my %data_hash = ();
    foreach my $record (@all_data) {
#        my @fields =  map {$_ =~ s/^\s*|\s*$//; $_} split /,/, $record;
        my @fields =  map {$_ =~ s/^\s*|\s*$//g; $_} split /,/, $record;
        my @fields_after_first = @fields[1..$#fields]; 
        $data_hash{$fields[0]} = \@fields_after_first;
    }
    die 'Aborted. The first row of CSV file must begin with "" and then list the feature names and class names'  unless exists $data_hash{'""'};
    my @field_names = map {$_ =~ s/^\s*\"|\"\s*$//g;$_} @{$data_hash{'""'}};
    my $class_column_heading = $field_names[$class_name_in_column];
    @feature_names = map {$field_names[$_-1]} @{$dt->{_csv_columns_for_features}};
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
        foreach my $i (@{$dt->{_csv_columns_for_features}}) {
            my $feature_column_header = $field_names[$i-1];
            my $feature_val = $data_hash{$key}->[$i-1];
            $feature_val  =~ s/^\s*\"|\"\s*$//g;
            $feature_val = sprintf("%.1f",$feature_val) if $feature_val =~ /^\d+$/;
            push @features_and_values_list,  "$feature_column_header=$feature_val";
        }
        $feature_values_for_samples_hash{"sample_" . $cleanedup} = \@features_and_values_list;
    }
    %features_and_values_hash = ();
    foreach my $i (@{$dt->{_csv_columns_for_features}}) {
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
