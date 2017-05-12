#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::SearchEngine::Solr' );
}

diag( "Testing Data::SearchEngine::Solr $Data::SearchEngine::Solr::VERSION, Perl $], $^X" );
