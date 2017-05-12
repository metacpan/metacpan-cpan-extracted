#!/usr/bin/perl -w

###  retrieve_similar_tickets.pl

###  After the tickets stored in an Excel spreadsheet have been subject to the
###  preprocessing steps listed in the script `ticket_preprocessor_doc_modeler.pl',
###  you use the script shown here to retrieve the tickets that are most similar
###  to a given query ticket.

###  For obvious reasons, you would want the names of the database files
###  mentioned in this script to match the names in the ticket
###  preprocessing script.

###  IMPORTANT  IMPORTANT  IMPORTANT  IMPORTANT  IMPORTANT:
###
###  The parameter
###
###                 min_idf_threshold 
###
###
###  depends on the number of tickets in your Excel spreadsheet.  If the
###  number of tickets is in the low hundreds, this parameter is likely to
###  require a value of 1.5 to 1.8.  If the number of tickets is in the
###  thousands, the value of this parameter is likely to be between 2 and
###  3.  See the writeup on this parameter in the API description in the
###  main documentation.


#use lib '../blib/lib', '../blib/arch';

use strict;
use Algorithm::TicketClusterer;

my $fieldname_for_clustering = "Description";
my $unique_id_fieldname = "Request No";
my $raw_tickets_db = "raw_tickets.db";
my $processed_tickets_db = "processed_tickets.db";
my $stemmed_tickets_db = "stemmed_tickets.db";
my $inverted_index_db = "inverted_index.db";
my $tickets_vocab_db = "tickets_vocab.db";
my $idf_db = "idf.db";
my $tkt_doc_vecs_db = "tkt_doc_vecs.db";
my $tkt_doc_vecs_normed_db = "tkt_doc_vecs_normed.db";

my $clusterer = Algorithm::TicketClusterer->new( 

                     clustering_fieldname      => $fieldname_for_clustering,
                     unique_id_fieldname       => $unique_id_fieldname,
                     raw_tickets_db            => $raw_tickets_db,
                     processed_tickets_db      => $processed_tickets_db,
                     stemmed_tickets_db        => $stemmed_tickets_db,
                     inverted_index_db         => $inverted_index_db,
                     tickets_vocab_db          => $tickets_vocab_db,
                     idf_db                    => $idf_db,
                     tkt_doc_vecs_db           => $tkt_doc_vecs_db,
                     tkt_doc_vecs_normed_db    => $tkt_doc_vecs_normed_db,
                     min_idf_threshold         => 1.3,
                     how_many_retrievals       => 5,
                );

#my $ticket_num = 1377224;

my $ticket_num = 1377212;

$clusterer->restore_ticket_vectors_and_inverted_index();

my $retrieved_hash_ref = $clusterer->retrieve_similar_tickets_with_vsm( $ticket_num );

print "\nDisplaying the tickets considered most similar to the query ticket $ticket_num\n\n";

my %retrieved_hash = %{$retrieved_hash_ref};
my $rank = 1;
foreach my $ticket_id (sort { $retrieved_hash{$b} <=> $retrieved_hash{$a} } 
                                                          keys %retrieved_hash) {
    my $similarity_score = $retrieved_hash{$ticket_id};
    print "\n\n\n --------- Retrieved ticket at similarity rank $rank   (simlarity score: $similarity_score) ---------\n";
    $clusterer->show_processed_ticket_clustering_data_for_given_id( $ticket_id );    
    $clusterer->show_original_ticket_for_given_id( $ticket_id );
    $rank++;
}

