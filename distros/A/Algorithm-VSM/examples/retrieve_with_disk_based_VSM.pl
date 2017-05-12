#!/usr/bin/perl -w

##  retrieve_with_disk_based_VSM.pl

use strict;
use Algorithm::VSM;

##  You must first run the script:

##      retrieve_with_VSM_and_also_create_disk_based_model.pl

##  before executing the current script.  The script named above results in
##  the creation of a disk-based VSM model that can be used by the
##  current script for retrieval.

##  See Item 4 of the README of the `examples' directory


print "\nIMPORTANT:  We assume that you have previously called\n\n" .
      "   retrieve_with_VSM_and_also_create_disk_based_model.pl\n\n" .
      "on the same corpus with the following constructor options:\n\n" .
      "   use_idf_filter  => 1,                 \n" .
      "   save_model_on_disk  => 1,           \n\n";

my @query = qw/ string getAllChars throw IOException distinct TreeMap histogram map /;

#     The three databases mentioned in the next two statements are created
#     by calling the script
#     retrieve_with_VSM_and_also_create_disk_based_model.pl .  The first of
#     the databases stores the corpus vocabulary, the second term
#     frequencies for the vocabulary words, and the third the normalized
#     document vectors.  As to what is meant by normalization, see the
#     comments in the script retrieve_with_VSM.pl.
my $corpus_vocab_db = "corpus_vocab_db";
my $doc_vectors_db  = "doc_vectors_db";
my $normalized_doc_vecs_db  = "normalized_doc_vecs_db";

my $vsm = Algorithm::VSM->new( 
                   corpus_vocab_db           => $corpus_vocab_db, 
                   doc_vectors_db            => $doc_vectors_db,
                   normalized_doc_vecs_db    => $normalized_doc_vecs_db,
                   max_number_retrievals     => 10,
          );

#  Use the following call ONLY if you are setting the use_idf_filter option to
#  0 in the above constructor.
#$vsm->upload_vsm_model_from_disk();

$vsm->upload_normalized_vsm_model_from_disk();

#    Uncomment the following statement if you would like to see the corpus
#    vocabulary:
#$vsm->display_corpus_vocab();

#  Use the following call ONLY if you are setting the use_idf_filter option to
#  0 in the above constructor.
#$vsm->display_doc_vectors();

#    Uncomment the following statement if you would like to the individual
#    document vectors:
#$vsm->display_normalized_doc_vectors();

my $retrievals = $vsm->retrieve_with_vsm( \@query );

$vsm->display_retrievals( $retrievals );

