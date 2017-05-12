use Test::More tests => 15;

use_ok( "CGI::Wiki" );
use_ok( "CGI::Wiki::Formatter::Default" );
use_ok( "CGI::Wiki::Plugin" );
use_ok( "CGI::Wiki::Search::Base" );

eval { require DBIx::FullTextSearch; };
SKIP: {
        skip "DBIx::FullTextSearch not installed", 1 if $@;
        use_ok( "CGI::Wiki::Search::DBIxFTS" );
}

eval { require Search::InvertedIndex; };
SKIP: {
        skip "Search::InvertedIndex not installed", 2 if $@;
        use_ok( "CGI::Wiki::Search::SII" );
        use_ok( "CGI::Wiki::Setup::SII" );
}

eval { require Plucene; };
SKIP: {
        skip "Plucene not installed", 1 if $@;
        use_ok( "CGI::Wiki::Search::Plucene" );
}

use_ok( "CGI::Wiki::Setup::MySQL" );
use_ok( "CGI::Wiki::Setup::Pg" );
use_ok( "CGI::Wiki::Setup::SQLite" );
use_ok( "CGI::Wiki::Store::Database" );
use_ok( "CGI::Wiki::Store::MySQL" );
use_ok( "CGI::Wiki::Store::Pg" );
use_ok( "CGI::Wiki::Store::SQLite" );
