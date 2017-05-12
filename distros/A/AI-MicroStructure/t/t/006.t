#!/usr/bin/perl -w

use Search::ContextGraph;
use Test::More  'no_plan';
use Data::Dumper;
use Env qw(PWD);
#use blib;


my %docs = (
  'First Document' => { 'elephant' => 2, 'snake' => 1 },
  'Second Document' => { 'camel' => 1, 'pony' => 1 },
  'Third Document' => { 'snake' => 2, 'constrictor' => 1 },
);

for my $XS ( 0..1 ) {

  last if $XS; # XS IS BROKEN IN THIS VERSION!

  my $cg = Search::ContextGraph->new( xs => $XS);
  ok($cg, "have Search::ContextGraph object");
  $cg->add_documents( %docs );

  my ($docs, $words ) = $cg->search('snake');

  is(scalar(keys(%$docs)), 2, "only two matches");


  ok($docs->{"First Document"}, "contains first document");
  ok($docs->{"Third Document"}, "contains third document");

  is(sprintf("%2.2f", $docs->{"First Document"}), 18.86, 'correct relevance on search doc #1');
  is(sprintf("%2.2f", $docs->{"Third Document"}), 35.35, 'correct relevance on search doc #3');


  ( $docs, $words ) = $cg->search('snake');
  is(sprintf("%2.2f", $docs->{"Third Document"}), 35.35, "repeating search does not change results" );

  ( $docs, $words ) = $cg->search('pony');

  #Test search starting at singleton node
  #is(sprintf("%2.2f", $docs->{"Second Document"}), '50.00', "search starting at singleton");

  # Try adding a duplicate title
  eval{ $cg->add_documents( %docs ); };
  ok(  $@ =~ /^Tried to add document with duplicate identifier:/,
     "complained about duplicate title");

  my %new_docs = (
    'Fourth Document' => { 'elephant' => 1, 'fox' => 2, 'boa' => 1 },
    'Fifth Document' => { 'bull' => 1, 'eagle' => 1 }
    );

  eval{ $cg->add_documents( %new_docs ) };
  ok( !length $@, "able to add more documents" );
  is ( $cg->doc_count(), 5, "document count is correct" );


  # Check that the word count is right
  my @words = $cg->term_list();
  is ( scalar @words, 9, "word count is correct" );
  my $flat = join '', sort @words;
  is ( $flat, 'boabullcamelconstrictoreagleelephantfoxponysnake', "word list is correct" );

  ( $docs, $words ) = $cg->search('pony');
  is(sprintf("%2.2f", $docs->{"Second Document"}), '50.00', "singleton search did not change");

  my $raw = $cg->raw_search('T:pony');
  is(sprintf("%2.2f", $raw->{"D:Second Document"}), '50.00', "raw search gives same result");


  ( $docs, $words ) = $cg->search('snake');
  is(sprintf("%2.2f", $docs->{"First Document"}), 28.36, 'result changed for non-singleton search');

  ( $docs, $words ) = $cg->find_similar('First Document');
  is(sprintf("%2.2f", $docs->{"First Document"}), 122.34, 'find similar search correct');
  is(sprintf("%2.2f", $docs->{"Fourth Document"}), 5.57, 'find similar search correct');


  # Try storing the sucker
  if ( !$XS ) {
    my $path = "Search::ContextGraph::Test::Stored";
    eval { $cg->store( $path ) };
    ok( !length $@, "able to store object to file" );

    my $x = Search::ContextGraph->retrieve( $path );
    ok( UNIVERSAL::isa( $x, 'Search::ContextGraph'), "reload object from stored file" );

    #cleanup
    eval { unlink $path; };
    ok( !length $@, "remove stored file" );


    ($docs, $words ) = $cg->find_similar('First Document');
    is(sprintf("%2.2f", $docs->{"First Document"}), 122.34, 'reloaded search object works fine');
  }

  my $y = Search::ContextGraph->new( debug => 1, xs => $XS );
  $path = sprintf("$PWD/t/canned/sample.tdm");
  $y->load_from_tdm( $path );
  ok( !length $@, "able to load TDM file $@" );
  is( $y->doc_count(), 177, "correct document count" );
  is( $y->term_count(), 2036, "correct term count" );


  ($docs, $words) = $y->mixed_search( { terms => [ 111, 109, 23 ], docs => [33,21,12] });
  is( scalar keys %$words,141, "Got right number of results");
  is(sprintf("%2.2f", $docs->{163}), 1.09, "mixed search got right doc value");
  is(sprintf("%2.2f", $words->{248}), 0.52, "mixed search got right term value");





}
