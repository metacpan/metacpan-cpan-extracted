use strict;
use CGI::Wiki::TestLib;
use Test::More;

if ( scalar @CGI::Wiki::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 7 * scalar @CGI::Wiki::TestLib::wiki_info );
}

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    eval {
        $wiki->write_node( "Test 1", undef, undef );
    };
    ok( $@, "->write_node dies if undef content and metadata supplied" );

    eval {
        $wiki->write_node( "Test 2", "", undef );
    };
    is( $@, "", "...but not if blank content and undef metadata supplied");

    eval {
        $wiki->write_node( "Test 3", "foo", undef );
    };
    is( $@, "", "...and not if just content defined" );

    eval {
        $wiki->write_node( "Test 4", "", undef, { category => "Foo" });
    };
    is( $@, "", "...and not if just metadata defined" );

    # Test deleting nodes with blank data.
    eval {
        $wiki->delete_node( "Test 2");
    };
    is( $@, "", "->delete_node doesn't die when called on node with blank content and undef metadata" );
    eval {
        $wiki->delete_node( "Test 3");
    };
    is( $@, "", "...nor on node with only content defined" );
    eval {
        $wiki->delete_node( "Test 4");
    };
    is( $@, "", "...nor on node with only metadata defined" );
}
