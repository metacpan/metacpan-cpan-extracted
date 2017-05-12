#!/usr/bin/perl -w

##  retrieve_with_LSA.pl

##  This is a demonstration of retrieval using the LSA model

use strict;
use Algorithm::VSM;

my $corpus_dir = "corpus";

my @query = qw/ string getAllChars throw IOException distinct TreeMap histogram map /;

my $stop_words_file = "stop_words.txt";    # This file will typically include the
                                           # keywords of the programming 
                                           # language(s) used in the software.

my $lsa = Algorithm::VSM->new( 
                   break_camelcased_and_underscored  => 1,  # default: 1
                   case_sensitive           => 0,           # default: 0 
                   corpus_directory         => $corpus_dir,
                   file_types               => ['.txt', '.java'],
                   lsa_svd_threshold        => 0.01,# Used for rejecting singular
                                                    # values that are smaller than
                                                    # this threshold fraction of
                                                    # the largest singular value.
                   max_number_retrievals    => 10,
                   min_word_length          => 4,
                   stop_words_file          => $stop_words_file,
                   use_idf_filter           => 1,
                   want_stemming            => 1,           # Default: 0
          );

$lsa->get_corpus_vocabulary_and_word_counts();

#    Uncomment the following statement if you would like to see the corpus
#    vocabulary:
#$lsa->display_corpus_vocab();

#    Uncomment the following statement if you would like to see the corpus
#    vocabulary size:
$lsa->display_corpus_vocab_size();

#    Uncomment the following statement if you would like to dump the corpus
#    vocabulary in a file that you supply as an argument in the following call:
$lsa->write_corpus_vocab_to_file("vocabulary_dump.txt");

#    Uncomment the following statement if you would like to see the inverse
#    document frequencies:
#$lsa->display_inverse_document_frequencies();

$lsa->generate_document_vectors();

#   Uncomment the following if you would like to see the doc vectors for
#   each of the documents in the corpus:
#$lsa->display_doc_vectors();

#    Uncomment the folloiwng statement if you would like to the individual
#    normalized document vectors:
#$lsa->display_normalized_doc_vectors();

$lsa->construct_lsa_model();

my $retrievals = $lsa->retrieve_with_lsa( \@query );

$lsa->display_retrievals( $retrievals );

