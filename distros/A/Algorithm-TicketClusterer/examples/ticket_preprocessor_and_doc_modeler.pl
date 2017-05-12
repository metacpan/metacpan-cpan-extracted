#!/usr/bin/perl -w

### ticket_preprocessor.pl

###  This is the script you must run on a new Excel spreadsheet before you
###  can retrieve similar tickets from the tickets stored in the
###  spreadsheet.

###  This script calls on a user to specify names for the nine databases
###  that are created for the tickets.  This is to avoid having to process
###  all the tickets every time you need to make a retrieval for a new
###  ticket.


#use lib '../blib/lib', '../blib/arch';

use strict;
use Algorithm::TicketClusterer;

my $excel_filename = "ExampleExcelFile.xls";
#my $excel_filename = "SampleTest.xlsx";
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
my $synset_cache_db = "synset_cache.db";
my $stop_words_file = "stop_words.txt";
my $misspelled_words_file = "misspelled_words.txt";

my $clusterer = Algorithm::TicketClusterer->new( 

                     excel_filename            => $excel_filename,
                     which_worksheet           => 1,
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
                     synset_cache_db           => $synset_cache_db,
                     stop_words_file           => $stop_words_file,
                     misspelled_words_file     => $misspelled_words_file,
                     add_synsets_to_tickets    => 1,
                     want_synset_caching       => 1,
                     max_num_syn_words         => 3,
                     min_word_length           => 4,
                     want_stemming             => 1,
                );

## Extract information from Excel spreadsheets:
$clusterer->get_tickets_from_excel();

## Apply cleanup filters and add synonyms:
$clusterer->delete_markup_from_all_tickets();
$clusterer->apply_filter_to_all_tickets();
$clusterer->expand_all_tickets_with_synonyms();
$clusterer->store_processed_tickets_on_disk();

## Construct the VSM doc model for the tickets:
$clusterer->get_ticket_vocabulary_and_construct_inverted_index();
$clusterer->construct_doc_vectors_for_all_tickets();
$clusterer->store_stemmed_tickets_and_inverted_index_on_disk();
$clusterer->store_ticket_vectors();
