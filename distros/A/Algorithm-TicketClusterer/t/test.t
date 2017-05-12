use Test::Simple tests => 3;

use lib '../blib/lib','../blib/arch';

use Algorithm::TicketClusterer;

# Test 1 (Read Excel):

my $tclusterer = Algorithm::TicketClusterer->new( 
                     excel_filename            => "t/__SampleTest.xlsx",
                     which_worksheet           => 1,
                     clustering_fieldname      => "Description",
                     unique_id_fieldname       => "Request No",
                     raw_tickets_db            => "t/__test_raw_tickets_db",
                     processed_tickets_db      => "t/__test_processed_tickets_db",
                     stemmed_tickets_db        => "t/__test_stemmed_tickets_db",
                     inverted_index_db         => "t/__test_inverted_index_db",
                     tickets_vocab_db          => "t/__test_tickets_vocab_db",
                     idf_db                    => "t/__test_idf_db",
                     tkt_doc_vecs_db           => "t/__test_tkt_doc_vecs_db",
                     tkt_doc_vecs_normed_db    => "t/__test_tkt_doc_vecs_normed_db",
                     synset_cache_db           => "t/__test_synset_cache_db",
                     add_synsets_to_tickets    => 1,
                     want_synset_caching       => 1,
                     max_num_syn_words         => 3,
                     min_word_length           => 4,
                     want_stemming             => 1,
                 );

my @returned = $tclusterer->_test_excel_for_tickets();
my @should_be = qw/0 4 0 6/;
#ok( @returned ~~ @should_be, 'Able to process Excel' );
my @comparisons = map {$returned[$_] == $should_be[$_] ? 1 : 0} (0..@returned-1);
my $final_compare = 1;
foreach my $i (0..@returned-1) {
    $final_compare *= $comparisons[$i]
}
ok( $final_compare, 'Able to process Excel' );

## Test 2 (Check Clustering Data):

$tclusterer->get_tickets_from_excel();
my $clustering_data = $tclusterer->_raw_ticket_clustering_data_for_given_id(101);

ok( $clustering_data =~ /i am unable/, 'Able to extract the clustering field from Excel' );


## Test 3 (Check Synset Extraction from WordNet):

$tclusterer->expand_all_tickets_with_synonyms();

ok( -s "t/__test_synset_cache_db" > 20, 'Able to extract synsets from WordNet' );

unlink glob "t/__test_*";
