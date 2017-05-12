#!/usr/bin/perl -w

### retrieve_with_VSM.pl

##  This is the basic script for VSM based retrieval. 

##  If you want to run VSM retrieval repeatedly for multiple queries in an
##  interactive mode, you might with to experiment with the script:

##          continuously_running_VSM_retrieval_engine.pl

##  See Item 1 of the README of the `examples' directory for furthre information.

use strict;
use Algorithm::VSM;

my $corpus_dir = "corpus";

my @query = qw/ string getAllChars throw IOException distinct TreeMap histogram map /;

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

#    Uncomment the following statement if you would like to see the corpus
#    vocabulary:
#$vsm->display_corpus_vocab();

#    Uncomment the following statement if you would like to see the corpus
#    vocabulary size:
$vsm->display_corpus_vocab_size();

#    Uncomment the following statement if you would like to dump the corpus
#    vocabulary into a disk file that you supply as an argument in the
#    following call:
$vsm->write_corpus_vocab_to_file("vocabulary_dump.txt");

#    Uncomment the following statement if you would like to see the inverse
#    document frequencies:
#$vsm->display_inverse_document_frequencies();

$vsm->generate_document_vectors();

#    Uncomment the folloiwng statement if you would like to the individual
#    document vectors:
#$vsm->display_doc_vectors();


#    Uncomment the folloiwng statement if you would like to the individual
#    normalized document vectors:
#$vsm->display_normalized_doc_vectors();

my $retrievals = $vsm->retrieve_with_vsm( \@query );

$vsm->display_retrievals( $retrievals );

