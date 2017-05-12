#!/usr/bin/perl -w

##  retrieve_with_VSM_and_also_create_disk_based_model.pl

use strict;
use Algorithm::VSM;

##  This script makes a retrieval for one query and, at the same time,
##  creates a disk-based VSM model for your corpus.  Subsequently, you
##  you can make faster retrievals from the model stored on the disk,
##  as shown by the following script:

##  See Item 3 of the README of the `examples' directory

my $corpus_dir = "corpus";

my @query = qw/ string getAllChars throw IOException distinct TreeMap histogram map /;

my $stop_words_file = "stop_words.txt";    # This file will typically include the
                                           # keywords of the programming 
                                           # language(s) used in the software.

my ($corpus_vocab_db, $doc_vectors_db, $normalized_doc_vecs_db);

#     The three variables defined below store the database model created in
#     three disk-based hash tables.  The three databases named below store
#     (1) the corpus vocabulary word frequency histogram; (2) the doc
#     vectors for the files in the corpus, and (3) the normalized doc
#     vectors.  Normalized document vectors are caculated by first
#     converting the word frequencies into proportions and then multiplying
#     the proportions by idf(t), which stands for "Inverse Document
#     Frequency" at the word t.  This product is frequently displayed as
#     tf(t)xidf(t) in the IR literature.  Using the occurrence proportions
#     for tf(t) normalizes the document vector with respect to its size and
#     multiplying by idf(t) reduces the effect of the words that occur in
#     all the documents.  After these databases are created, you can do VSM
#     retrieval directly from the databases by running the script
#     retrieve_with_disk_based_VSM.pl.  Doing retrieval using a pre-stored
#     model of a corpus will, in general, be much faster since you will be
#     spared the bother of having to create the model repeatedly.
$corpus_vocab_db = "corpus_vocab_db";
$doc_vectors_db  = "doc_vectors_db";
$normalized_doc_vecs_db  = "normalized_doc_vecs_db";

my $vsm = Algorithm::VSM->new( 
                   break_camelcased_and_underscored  => 1,  # default: is 1
                   case_sensitive           => 0,           # default: 0 
                   corpus_directory         => $corpus_dir,
                   corpus_vocab_db          => $corpus_vocab_db,
                   doc_vectors_db           => $doc_vectors_db,
                   file_types               => ['.txt', '.java'],
                   max_number_retrievals    => 10,
                   min_word_length          => 4,
                   normalized_doc_vecs_db   => $normalized_doc_vecs_db,
                   save_model_on_disk       => 1,  
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
