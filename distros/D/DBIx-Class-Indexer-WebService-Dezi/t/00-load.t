use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Indexer::WebService::Dezi' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Indexer::WebService::Dezi $DBIx::Class::Indexer::WebService::Dezi::VERSION, Perl $], $^X" );
