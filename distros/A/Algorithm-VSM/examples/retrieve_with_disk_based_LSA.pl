#!/usr/bin/perl -w

### retrieve_with_disk_based_LSA.pl


##  This scripts shows how you can carry out LSA-based retrieval using the
##  disk-based database files created by first running the script:

##      retrieve_with_VSM_and_also_create_disk_based_model.pl

##  You must therefore run the above-named script before executing the current
##  script. 


use strict;
use Algorithm::VSM;

print "\nIMPORTANT:  We assume that you have previously called\n\n" .
      "    retrieve_with_VSM_and_also_create_disk_based_model.pl \n\n" .
      "on the same corpus with the following constructor options:\n\n" .
      "           use_idf_filter  => 1,                 \n" .
      "           save_model_on_disk  => 1,           \n\n" .

      "The call to the above script generates the disk-based hashtables\n" .
      "needed by the current script\n";


my @query = qw/ string getAllChars throw IOException distinct TreeMap histogram map /;

#     The three databases mentioned in the next three statements are
#     created by calling the script
#     retrieve_with_VSM_and_also_create_disk_based_model.pl.  The first of
#     the databases stores the corpus vocabulary and term frequencies for
#     the vocabulary words.  The second database stores the term frequency
#     vectors for the individual documents in the corpus. The third
#     database stores the normalized document vectors.  As to what is meant
#     by document normalization, see the script retrieve_with_VSM.pl

my $corpus_vocab_db = "corpus_vocab_db";
my $doc_vectors_db  = "doc_vectors_db";
my $normalized_doc_vecs_db = "normalized_doc_vecs_db";

my $lsa = Algorithm::VSM->new( 
                   corpus_vocab_db          => $corpus_vocab_db,
                   doc_vectors_db           => $doc_vectors_db,
                   normalized_doc_vecs_db   => $normalized_doc_vecs_db,
                   max_number_retrievals    => 10,
          );

$lsa->upload_normalized_vsm_model_from_disk();

#   Uncomment the following if you would like to see the corpus vocabulary:
#$lsa->display_corpus_vocab();

#   Uncomment the following if you would like to see the doc vectors for
#   each of the documents in the corpus:
#$lsa->display_doc_vectors();


$lsa->construct_lsa_model();

my $retrievals = $lsa->retrieve_with_lsa( \@query );

$lsa->display_retrievals( $retrievals );

