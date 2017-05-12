#!/usr/bin/perl -w

##  calculate_precision_and_recall_from_file_based_relevancies_for_VSM.pl

##  This script looks for human-supplied relevancy judgments in a file called
##  `relevancy.txt' for the queries in the file `test_queries.txt'

##  See Item 9 of the README of the `examples' directory for further information.

use strict;
use Algorithm::VSM;

my $corpus_dir = "corpus";                     # This is the directory containing
                                               # the corpus

my $stop_words_file = "stop_words.txt";        # Will typically include the 
                                               # keywords of the programming
                                               # language(s) used in the software.

my $query_file      = "test_queries.txt";      # This file contains the queries
                                               # to be used for precision vs.
                                               # recall analysis.  Its format
                                               # must be as shown in test_queries.txt

my $relevancy_file   = "relevancy.txt";        # The humans-supplied relevancies
                                               # will be read from this file.

my $vsm = Algorithm::VSM->new( 
                   break_camelcased_and_underscored  => 1,  # default: 1
                   case_sensitive      => 0,                # default: 0 
                   corpus_directory    => $corpus_dir,
                   file_types          => ['.txt', '.java'],
                   min_word_length     => 4,
                   query_file          => $query_file,
                   relevancy_file      => $relevancy_file,
                   stop_words_file     => $stop_words_file,
                   want_stemming       => 1,                # default: 0
          );

$vsm->get_corpus_vocabulary_and_word_counts();

$vsm->generate_document_vectors();

#    Uncomment the following statement if you want to see the corpus
#    vocabulary:
#$vsm->display_corpus_vocab();

#    Uncomment the following statement if you want to see the individual
#    document vectors:
#$vsm->display_doc_vectors();

#$vsm->construct_lsa_model();

$vsm->upload_document_relevancies_from_file();  # The format of the relevancy
                                                # file must be as shown in 
                                                # relevance.txt

#    Uncomment the following statement if you wish to see the list of all
#    the documents relevant to each of the queries:
#$vsm->display_doc_relevancies();

#    Use only one of the following statements.  If you wish to carry out
#    precision vs. recall analysis for LSA, comment out the first and
#    uncomment the second.
$vsm->precision_and_recall_calculator('vsm');

$vsm->display_precision_vs_recall_for_queries();

$vsm->display_average_precision_for_queries_and_map();

