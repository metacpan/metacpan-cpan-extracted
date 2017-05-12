use strict;
use CGI::Wiki::TestLib;
use Test::More;
use Time::Piece;

if ( scalar @CGI::Wiki::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 10 * scalar @CGI::Wiki::TestLib::wiki_info );
}

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in.
    $wiki->write_node( "Home", "This is the home node." )
      or die "Couldn't write node";

    # Test writing to existing nodes.
    my %node_data = $wiki->retrieve_node("Home");
    my $slept = sleep(2);
    warn "Slept for less than a second, 'lastmod' test may fail"
      unless $slept >= 1;

    ok( $wiki->write_node("Home", "xx", $node_data{checksum}),
        "write_node succeeds when node matches checksum" );
    ok( ! $wiki->write_node("Home", "foo", $node_data{checksum}),
        "...and flags when it doesn't" );
    my %new_node_data = $wiki->retrieve_node("Home");
    print "# version now: [$new_node_data{version}]\n";
    is( $new_node_data{version}, $node_data{version} + 1,
        "...and the version number is updated on successful writing" );
    my $lastmod = Time::Piece->strptime($new_node_data{last_modified},
                                   $CGI::Wiki::Store::Database::timestamp_fmt);
    my $prev_lastmod = Time::Piece->strptime($node_data{last_modified},
                                   $CGI::Wiki::Store::Database::timestamp_fmt);
    print "# [$lastmod] [$prev_lastmod]\n";
    ok( $lastmod > $prev_lastmod, "...as is last_modified" );
    my $old_content = $wiki->retrieve_node( name    => "Home",
                                            version => 2 );
    is( $old_content, "xx", "...and old versions are still available" );

    # Test retrieving with checksums.
    %node_data = $wiki->retrieve_node("Home");
    ok( $node_data{checksum}, "retrieve_node does return a checksum" );
    is( $node_data{content}, $wiki->retrieve_node("Home"),
        "...and the same content as when called in scalar context" );
    ok( $wiki->verify_checksum("Home", $node_data{checksum}),
        "...and verify_checksum is happy with the checksum" );

    $wiki->write_node( "Home", $node_data{content}, $node_data{checksum} )
      or die "Couldn't write node";
    ok( $wiki->verify_checksum("Home", $node_data{checksum}),
         "...still happy when we write node again with exact same content" );
    $wiki->write_node("Home", "foo bar wibble", $node_data{checksum} )
      or die "Couldn't write node";
    ok( ! $wiki->verify_checksum("Home", $node_data{checksum}),
        "...but not once we've changed the node content" );

}
