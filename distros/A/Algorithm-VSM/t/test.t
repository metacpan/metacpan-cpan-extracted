use Test::Simple tests => 2;

use lib '../blib/lib','../blib/arch';

use Algorithm::VSM;

# Test 1 (Test VSM:)

my $corpus_dir = "examples/minicorpus";

my @query = qw/ string getallchars throw ioexception distinct treemap histogram map /;
my $corpus_vocab_db = "t/___corpus_vocab_db";
my $doc_vectors_db  = "t/___doc_vectors_db";
my $normalized_doc_vecs_db = "t/___normalized_doc_vecs_db";

my $vsm = Algorithm::VSM->new( 
                   case_sensitive           => 0,     
                   file_types               => ['.txt', '.java'],
                   corpus_directory         => $corpus_dir,
                   corpus_vocab_db          => $corpus_vocab_db,
                   doc_vectors_db           => $doc_vectors_db,
                   normalized_doc_vecs_db   => $normalized_doc_vecs_db,
                   stop_words_file          => $stop_words_file,
                   want_stemming            => 1,      # default is no stemming
          );

$vsm->get_corpus_vocabulary_and_word_counts();
$vsm->generate_document_vectors();
my $retrievals = $vsm->retrieve_with_vsm( \@query );

my $tempzzz = keys %$retrievals;
print "\ntempzzz = $tempzzz\n\n";

ok( scalar(keys %$retrievals) == 8,  'VSM tested successfully' );

# Test 2 (Test LSA:)

my $lsa = Algorithm::VSM->new( 
                   case_sensitive           => 0,     
                   file_types               => ['.txt', '.java'],
                   corpus_directory         => $corpus_dir,
                   corpus_vocab_db          => $corpus_vocab_db,
                   doc_vectors_db           => $doc_vectors_db,
                   normalized_doc_vecs_db   => $normalized_doc_vecs_db,
                   stop_words_file          => $stop_words_file,
                   want_stemming            => 1,  
                   lsa_svd_threshold        => 0.01,
          );

$lsa->get_corpus_vocabulary_and_word_counts();
$lsa->generate_document_vectors();
$lsa->construct_lsa_model();
my $retrievals_lsa = $lsa->retrieve_with_lsa( \@query );
ok( scalar(keys %$retrievals_lsa) == 5,  'LSA tested successfully' );

unlink "t/___corpus_vocab_db.dir";
unlink "t/___corpus_vocab_db.pag";
unlink "t/___doc_vectors_db";
unlink "t/___normalized_doc_vecs_db";

