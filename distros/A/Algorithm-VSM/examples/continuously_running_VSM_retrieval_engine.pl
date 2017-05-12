#!/usr/bin/perl -w

##  continuously_running_VSM_retrieval_engine.pl 

##  This script puts the VSM-bsaed retrieval in an infinite loop so that
##  a user can repeatedly ask for retrievals for different query strings.

##  See Item 2 of the README of the `examples' directory for further info

use strict;
use Algorithm::VSM;

my $corpus_dir = "corpus";

my $stop_words_file = "stop_words.txt";    # This file will typically include the
                                           # keywords of the programming 
                                           # language(s) used in the software.
my $vsm = Algorithm::VSM->new( 
                   break_camelcased_and_underscored  => 1,  # default: 1
                   case_sensitive           => 0,           # default: 0
                   corpus_directory         => $corpus_dir,
                   file_types               => ['.txt', '.java'],
                   max_number_retrievals    => 10,
                   min_word_length          => 4,
                   stop_words_file          => $stop_words_file,
                   use_idf_filter           => 1,
                   want_stemming            => 1,           # default: 0
          );

$vsm->get_corpus_vocabulary_and_word_counts();
$vsm->generate_document_vectors();

while (1) {
    print "\nEnter your query in the next line (or just press `Enter' to exit):\n\n";
    my $query_string = <STDIN>;
    $query_string =~ s/\r?\n?$//;
    $query_string =~ s/(^\s*)|(\s*$)//g;
    die "... exiting: $!" if length($query_string) == 0;
    my @query = grep $_, split /\s+/, $query_string;
    my $retrievals = eval {
        $vsm->retrieve_with_vsm( \@query );
    };
    if ($@) {
        print "$@\n";
    } else {
        $vsm->display_retrievals( $retrievals );
    }
}
