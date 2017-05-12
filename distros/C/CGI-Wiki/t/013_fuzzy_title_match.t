use strict;
use CGI::Wiki::TestLib;
use Test::More;

if ( scalar @CGI::Wiki::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 5 * scalar @CGI::Wiki::TestLib::wiki_info );
}

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    SKIP: {
        my $search = $wiki->search_obj;
        skip "No search backend in this combination", 5 unless $search;
        skip "Search backend doesn't support fuzzy searching", 5
            unless $search->supports_fuzzy_searches;

        # Fuzzy match with differing punctuation.
        $wiki->write_node( "King's Cross St Pancras", "station" )
          or die "Can't write node";

        my %finds = $search->fuzzy_title_match("Kings Cross St. Pancras");
        is_deeply( [ keys %finds ], [ "King's Cross St Pancras" ],
                   "fuzzy_title_match works when punctuation differs" );

        # Fuzzy match when we actually got the string right.
        $wiki->write_node( "Potato", "A delicious vegetable" )
          or die "Can't write node";
        $wiki->write_node( "Patty", "A kind of burger type thing" )
          or die "Can't write node";
        %finds = $search->fuzzy_title_match("Potato");
        is_deeply( [ sort keys %finds ], [ "Patty", "Potato" ],
                   "...returns all things found" );
        ok( $finds{Potato} > $finds{Patty},
            "...and exact match has highest relevance score" );

        # Now try matching indirectly, through the wiki object.
        %finds = eval {
            $wiki->fuzzy_title_match("kings cross st pancras");
        };
        is( $@, "", "fuzzy_title_match works when called on wiki object" ); 
        is_deeply( [ keys %finds ], [ "King's Cross St Pancras" ],
                   "...and returns the right thing" );
    }
}
