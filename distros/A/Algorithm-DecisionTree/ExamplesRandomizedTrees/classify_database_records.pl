#!/usr/bin/env perl

###   classify_database_records.pl

###   This script demonstrates how you can carry out an evaluation of the predictive
###   power of the set of decision trees constructed by RandomizedTreesForBigData.

###   Note that RandomizedTreesForBigData constructs decision trees using training
###   samples drawn randomly from the training database.  For evaluation, the script
###   shown here draws yet another random set of samples from the training database
###   and checks whether the majority vote classification returned by all the
###   decision trees agrees with the true labels for the data samples used for
###   evaluation.

###   The script shown below has the following outputs:
###
###   --- It shows for each test sample the class label as calculated by
###        RandomizedTreesForBigData and the class label as present in the training
###        database.
###
###   ---  It presents the overall classification error.
###
###   --- It presents the confusion matrix that is obtaining by aggregating the
###        calculated-class-labels versus the true-class-labels


###  IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
###
###     It is relatively common for real-life databases to have no values at all for
###     for some the fields.  When a test record extracted randomly from the database
###     does NOT contain a value for one of the fields that went into the construction
###     of the decision trees, it is skipped over.
###
###     Therefore, do not be surprised if the actual number of records in the confusion
###     matrix is smaller than the number you specified for the variable
###     "$number_of_records_to_classify".

###  FINALLY:
###
###     If you want to run this script on your own database, you'd need to at least customize
###     the information supplied in the lines labeled
###
###                A   B  C  D  E  F  G  H
###
###     In lines (G) and (H), you would need to change the strings "known to be NOT at risk"
###     "known to be a risk" so that they make sense for your database.


use strict;
use warnings;
use Algorithm::RandomizedTreesForBigData;
use List::Util qw(pairmap);

my $interaction_needed = (@ARGV == 1) && ($ARGV[0] eq 'with_interaction') ? 1 : 0;

# Number of records extracted randomly from the training set to classify:
#my $number_of_records_to_classify = 1000;
my $number_of_records_to_classify = 1000;                                                 #(A)

###  IMPORTANT:  The database file mentioned below is proprietary and is NOT
###              included in the module package:
#my $database_file = "/home/kak/DecisionTree_data/AtRisk/AtRiskModel_File_modified.csv";   #(B)
my $database_file = "try_rand_150.csv";

###  Make sure that the entries in this array correspond to the class labels in
###  your database:
my @class_names_used_in_database = ('YES', 'NO');                                         #(C)

my $csv_class_column_index = 48;                                                          #(D)

my $csv_columns_for_features = [41,49,50];                                                #(E)

my $how_many_trees = 7;                                                                   #(F)

################## construct list of record indexes to classify  #########################


my $all_record_labels = all_record_labels_in_database($database_file);
my @records_to_classify = map { $all_record_labels->[rand @{$all_record_labels}] } 0 .. $number_of_records_to_classify - 1;

################################## construct randomized trees ############################

my $rt = Algorithm::RandomizedTreesForBigData->new(
                              training_datafile => $database_file,
                              csv_class_column_index => $csv_class_column_index,
                              csv_columns_for_features => $csv_columns_for_features,
                              entropy_threshold => 0.01,
                              max_depth_desired => 8,
                              symbolic_to_numeric_cardinality_threshold => 10,
                              how_many_trees => 5,
                              looking_for_needles_in_haystack => 1,
                              csv_cleanup_needed => 1,
         );

print "\nReading the training data ...\n";
$rt->get_training_data_for_N_trees();

##   UNCOMMENT the following statement if you want to see the training data used for each tree::
$rt->show_training_data_for_all_trees();


print "\nCalculating first order probabilities...\n";
$rt->calculate_first_order_probabilities();

print "\nCalculating class priors...\n";
$rt->calculate_class_priors();

print "\nConstructing all decision trees ....\n";
$rt->construct_all_decision_trees();

##   UNCOMMENT the following statement if you want to see all decision trees individually:
$rt->display_all_decision_trees();

####################  Extract test samples from the database file  ######################

my @records_to_classify_local = @records_to_classify;

my %record_ids_with_class_labels;
my %record_ids_with_features_and_vals;
my @all_fields;
my $record_index = 0;
open FILEIN, $database_file || die "unable to open $database_file: $!";        
while (<FILEIN>) {
    next if /^[ ]*\r?\n?$/;
    $_ =~ s/\r?\n?$//;
    my $record = cleanup_csv($_);
    if ($record_index == 0) {
        @all_fields = split /,/, $record;
        $record_index++;
        next;
    }
    my @parts = split /,/, $record;
    my $record_lbl = $parts[0];
    $record_lbl  =~ s/^\s*\"|\"\s*$//g;
    if (contained_in($record_lbl, @records_to_classify_local)) {
        @records_to_classify_local = grep {$_ ne $record_lbl} @records_to_classify_local;
        $record_ids_with_class_labels{$record_lbl} = $parts[$csv_class_column_index];
        my @fields_of_interest = map {$all_fields[$_]} @{$csv_columns_for_features};
        my @feature_vals_of_interest = map {$parts[$_]} @{$csv_columns_for_features};
        my @interleaved = ( @fields_of_interest, @feature_vals_of_interest )[ map { $_, $_ + @fields_of_interest } ( 0 .. $#fields_of_interest ) ];
        my @features_and_vals = pairmap { "$a=$b" } @interleaved;
        $record_ids_with_features_and_vals{$record_lbl} = \@features_and_vals;
    }
    last if @records_to_classify_local == 0;
    $record_index++; 
}
close FILEIN;

# Now classify all the records extracted from the database file:    
my %original_classifications;
my %calculated_classifications;
foreach my $record_index (sort {$a <=> $b} keys %record_ids_with_features_and_vals) {
    my @test_sample = @{$record_ids_with_features_and_vals{$record_index}};
    # Let's now get rid of those feature=value combos when value is 'NA'    
    my $unknown_value_for_a_feature_flag;
    map {$unknown_value_for_a_feature_flag = 1 if $_ =~ /=NA$/} @test_sample;
    next if $unknown_value_for_a_feature_flag;
    $rt->classify_with_all_trees( \@test_sample );
    my $classification = $rt->get_majority_vote_classification();
    printf("\nclassification for %5d: %10s       original classification: %s", $record_index, $classification, $record_ids_with_class_labels{$record_index});
    $original_classifications{$record_index} = $record_ids_with_class_labels{$record_index};
    $classification =~ /=(.+)$/;
    $calculated_classifications{$record_index} = $1;
}

my $total_errors = 0;
my @confusion_matrix_row1 = (0,0);
my @confusion_matrix_row2 = (0,0);

print "\n\nCalculating the error rate and the confusion matrix:\n";
foreach my $record_index (sort keys %calculated_classifications) {
    $total_errors += 1 if $original_classifications{$record_index} ne $calculated_classifications{$record_index};    
    if ($original_classifications{$record_index} eq $class_names_used_in_database[1]) {
        if ($calculated_classifications{$record_index} eq $class_names_used_in_database[1]) {
            $confusion_matrix_row1[0] += 1;
        } else {
            $confusion_matrix_row1[1] += 1;
        }
    }
    if ($original_classifications{$record_index} eq $class_names_used_in_database[0]) {
        if ($calculated_classifications{$record_index} eq $class_names_used_in_database[1]) {
            $confusion_matrix_row2[0] += 1;
        } else {
            $confusion_matrix_row2[1] += 1;
        }
    }
}

my $percentage_errors =  ($total_errors * 100.0) / scalar keys %calculated_classifications;
print "\n\nClassification error rate: $percentage_errors\n";
print "\nConfusion Matrix:\n\n";
printf("%50s          %25s\n", "classified as NOT at risk", "classified as at risk");
printf("Known to be NOT at risk: %10d  %35d\n\n", @confusion_matrix_row1);                       #(G)
printf("Known to be at risk:%15d  %35d\n\n", @confusion_matrix_row2);                            #(H)


#============== Now interact with the user for classifying additional records  ==========

if ($interaction_needed) {
    while (1) {
        print "\n\nWould you like to see classification for a particular record: ";
        my $input = <STDIN>;
        if ($input =~ /^\s*n/) {
            die "goodbye";
        } elsif ($input =~ /^\s*y/) {
            print "\nEnter record numbers whose classifications you want to see (multiple entries allowed): ";
            $input = <STDIN>;        
            my @records_to_classify = map {int($_)} split /\s+/, $input;
            my @records_to_classify_local =  @records_to_classify;
            my %record_ids_with_class_labels;
            my %record_ids_with_features_and_vals;
            my @all_fields;
            open FILEIN, $database_file || die "unable to open $database_file: $!";        
            my $record_index = 0;
            while (<FILEIN>) {
                next if /^[ ]*\r?\n?$/;
                $_ =~ s/\r?\n?$//;
                my $record = cleanup_csv($_);
                if ($record_index == 0) {
                    @all_fields = split /,/, $record;
                    $record_index++;
                    next;
                }
                my @parts = split /,/, $record;
                my $record_lbl = int($parts[0]);
                $record_lbl  =~ s/^\s*\"|\"\s*$//g;
                if (contained_in($record_lbl, @records_to_classify_local)) {
                    @records_to_classify_local = grep {$_ ne $record_lbl} @records_to_classify_local;
                    $record_ids_with_class_labels{$record_lbl} = $parts[$csv_class_column_index];
                    my @fields_of_interest = map {$all_fields[$_]} @{$csv_columns_for_features};
                    my @feature_vals_of_interest = map {$parts[$_]} @{$csv_columns_for_features};
                    my @interleaved = ( @fields_of_interest, @feature_vals_of_interest )[ map { $_, $_ + @fields_of_interest } ( 0 .. $#fields_of_interest ) ];
                    my @features_and_vals = pairmap { "$a=$b" } @interleaved;
                    $record_ids_with_features_and_vals{$record_lbl} = \@features_and_vals;
                }
                last if @records_to_classify_local == 0;
                $record_index++; 
            }
            close FILEIN;
            # Now classify all the records extracted from the database file:    
            foreach my $record_index (keys %record_ids_with_features_and_vals) {
                my $test_sample = $record_ids_with_features_and_vals{$record_index};
                $rt->classify_with_all_trees( $test_sample );
                my $classification = $rt->get_majority_vote_classification();
                printf("\nclassification for %5d: %10s       original classification: %s", $record_index, $classification, $record_ids_with_class_labels{$record_index});
            }
        } else {
            print "\nYou are allowed to enter only 'y' or 'n'.  Try again.";
        }
    }
}

####################################### support functions #################################

sub all_record_labels_in_database {
    my $filename = shift;
    my @record_labels;
    open FILEIN, $filename || die "unable to open $filename: $!";        
    while (<FILEIN>) {
        next if /^[ ]*\r?\n?$/;
        my $label = substr($_, 0, index($_, ','));
        $label  =~ s/^\s*\"|\"\s*$//g;
        push @record_labels, $label
    }
    shift @record_labels;     # the label in the head record not needed
    return \@record_labels;
}

##  Introduced in Version 3.21, I wrote this function in response to a need to
##  create a decision tree for a very large national econometric database.  The
##  fields in the CSV file for this database are allowed to be double quoted and such
##  fields may contain commas inside them.  This function also replaces empty fields
##  with the generic string 'NA' as a shorthand for "Not Available".  IMPORTANT: This
##  function skips over the first field in each record.  It is assumed that the first
##  field in the first record that defines the feature names is the empty string ("")
##  and the same field in all other records is an ID number for the record.
sub cleanup_csv {
    my $line = shift;
    $line =~ tr/()[]{}/      /;
    my @double_quoted = substr($line, index($line,',')) =~ /\"[^\"]+\"/g;
    for (@double_quoted) {
        my $item = $_;
        $item = substr($item, 1, -1);
        $item =~ s/^s+|,|\s+$//g;
        $item = join '_',  split /\s+/, $item;
        substr($line, index($line, $_), length($_)) = $item;
    }
    my @white_spaced = $line =~ /,\s*[^,]+\s+[^,]+\s*,/g;
    for (@white_spaced) {
        my $item = $_;
        $item = substr($item, 0, -1);
        $item = join '_',  split /\s+/, $item unless $item =~ /,\s+$/;
        substr($line, index($line, $_), length($_)) = "$item,";
    }
    $line =~ s/,\s*(?=,)/,NA/g;
    return $line;
}

# checks whether an element is in an array:
sub contained_in {
    my $ele = shift;
    my @array = @_;
    my $count = 0;
    map {$count++ if $ele eq $_} @array;
    return $count;
}
