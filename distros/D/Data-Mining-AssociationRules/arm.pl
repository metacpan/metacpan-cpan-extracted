#!/usr/local/bin/perl -w

use strict;

use Data::Mining::AssociationRules;

use Getopt::Long;
my @options;

my $opt_transaction_file;
push(@options, "transaction-file=s", \$opt_transaction_file);

my $opt_support_threshold = 1;
push(@options, "support-threshold=i", \$opt_support_threshold);

my $opt_confidence_threshold = 0;
push(@options, "confidence-threshold=f", \$opt_confidence_threshold);

my $opt_max_set_size;
push(@options, "max-set-size=i", \$opt_max_set_size);

die "Couldn't parse options" if ! GetOptions(@options);

die "Must give -transaction-file\n" if !defined($opt_transaction_file);

my %transaction_map;
read_transaction_file(\%transaction_map, $opt_transaction_file);

set_debug(1);

generate_frequent_sets(\%transaction_map, $opt_transaction_file,
                       $opt_support_threshold, $opt_max_set_size);

generate_rules($opt_transaction_file, $opt_support_threshold,
               $opt_confidence_threshold, $opt_max_set_size);

