use strict;
use CGI::Wiki::TestLib;
use Test::More;

if ( scalar @CGI::Wiki::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 39 * scalar @CGI::Wiki::TestLib::wiki_info );
}

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    print "# Store: " . (ref $wiki->store) . "\n";
    # Test deletion of the first version of a node.
    $wiki->write_node( "A Node", "Node content.", undef, { one => 1 } )
      or die "Can't write node";
    my %data = $wiki->retrieve_node( "A Node" );
    $wiki->write_node( "A Node", "foo", $data{checksum}, { one => 2 } )
      or die "Can't write node";
    %data = $wiki->retrieve_node( "A Node" );
    $wiki->write_node( "A Node", "bar", $data{checksum}, { one => 3 } )
      or die "Can't write node";

    eval { $wiki->delete_node( name => "A Node", version => 1 ); };
    is( $@, "", "delete_node doesn't die when deleting the first version" );
    ok( $wiki->node_exists( "A Node" ), "...and the node still exists" );
    is( $wiki->retrieve_node( "A Node" ), "bar",
        "...latest version returned by retrieve_node" );
    SKIP: {
        skip "No search configured for this combination", 1
          unless $wiki->search_obj;
        my %results = $wiki->search_nodes("bar");
        is_deeply( [ keys %results ], [ "A Node" ],
                   "...and returned in search too." );
    }
    my @nodes;
    my %nodehash;
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_was => { one => 1 } );
    is_deeply( \@nodes, [],
               "...deleted version doesn't show up in metadata_was search" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_wasnt => { one => 1 } );
    %nodehash = map { $_->{name} => 1 } @nodes;
    ok($nodehash{"A Node"},
       "...node does show up in metadata_wasnt search" );

    # Test deletion of the latest version of a node.
    $wiki->write_node( "Two Node", "Node content.", undef, { two => 1 } )
      or die "Can't write node";
    %data = $wiki->retrieve_node( "Two Node" );
    $wiki->write_node( "Two Node", "baz HmPg", $data{checksum}, { two => 2 } )
      or die "Can't write node";
    %data = $wiki->retrieve_node( "Two Node" );
    $wiki->write_node( "Two Node", "quux RcCh", $data{checksum}, { two => 3 } )
      or die "Can't write node";

    eval { $wiki->delete_node( name => "Two Node", version => 3 ); };
    is( $@, "", "delete_node doesn't die when deleting the latest version" );
    ok( $wiki->node_exists( "Two Node" ), "...and the node still exists" );
    is( $wiki->retrieve_node( "Two Node" ), "baz HmPg",
        "...latest but one version returned by retrieve_node" );
    SKIP: {
        skip "No search configured for this combination", 2
          unless $wiki->search_obj;
        my %results = $wiki->search_nodes("baz");
        is_deeply( [ keys %results ], [ "Two Node" ],
                   "...and returned in search too." );
        %results = $wiki->search_nodes("quux");
        is_deeply( \%results, {},
                   "...and deleted version removed from search indexes" );
    }
    @nodes = $wiki->list_backlinks( node => "RcCh" );
    is( scalar @nodes, 0, "...backlinks in deleted version ignored" );
    @nodes = $wiki->list_backlinks( node => "HmPg" );
    is_deeply( \@nodes, [ "Two Node" ],
               "...backlinks in previous version show up" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_was => { two => 3 } );
    is_deeply( \@nodes, [],
               "...deleted version doesn't show up in metadata_was search" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_wasnt => { two => 3 } );
    %nodehash = map { $_->{name} => 1 } @nodes;
    ok($nodehash{"Two Node"},
       "...node does show up in metadata_wasnt search" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_isnt => { two => 3 } );
    %nodehash = map { $_->{name} => 1 } @nodes;
    ok($nodehash{"Two Node"},
       "...node does show up in metadata_isnt search" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_is => { two => 2 } );
    %nodehash = map { $_->{name} => 1 } @nodes;
    ok($nodehash{"Two Node"},
       "...previous version does show up in metadata_is search" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_is => { two => 3 } );
    is_deeply( \@nodes, [],
       "...deleted version doesn't show up in metadata_is search" );

    # Test deletion of an intermediate version of a node.
    $wiki->write_node( "Three Node", "plate", undef, { three => 1 } )
      or die "Can't write node";
    %data = $wiki->retrieve_node( "Three Node" );
    $wiki->write_node( "Three Node", "cup", $data{checksum}, { three => 2 } )
      or die "Can't write node.";
    %data = $wiki->retrieve_node( "Three Node" );
    $wiki->write_node("Three Node", "saucer", $data{checksum}, { three => 3 } )
      or die "Can't write node";

    print "# Deleting version 2\n";
    eval { $wiki->delete_node( name => "Three Node", version => 2 ); };
    is( $@, "", "delete_node doesn't die when deleting intermediate version" );
    ok( $wiki->node_exists( "Three Node" ), "...and the node still exists" );
    is( $wiki->retrieve_node( "Three Node" ), "saucer",
        "...latest version returned by retrieve_node" );
    SKIP: {
        skip "No search configured for this combination", 2
          unless $wiki->search_obj;
        my %results = $wiki->search_nodes("saucer");
        is_deeply( [ keys %results ], [ "Three Node" ],
                   "...and returned in search too." );
        %results = $wiki->search_nodes("cup");
        is_deeply( \%results, {},
                   "...and deleted version removed from search indexes" );
    }
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_was => { three => 2 } );
    is_deeply( \@nodes, [], "...doesn't show up in metadata_was search" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_wasnt => { three => 2 } );
    %nodehash = map { $_->{name} => 1 } @nodes;
    ok($nodehash{"Three Node"}, "...does show up in metadata_wasnt search" );

    print "# Deleting version 3\n";
    eval { $wiki->delete_node( name => "Three Node", version => 3 ); };
    is( $@, "", "delete_node doesn't die when we now try to delete the latest version" );
    %data = $wiki->retrieve_node( "Three Node" );
    is( $data{version}, 1, "...and the current version is 1" );
    is( $data{content}, "plate", "...and has correct content" );
    ok( $data{last_modified}, "...and has non-blank timestamp" );

    # Test deletion of the only version of a node.
    $wiki->write_node( "Four Node", "television", undef, { four => 1 } )
      or die "Can't write node";
    eval { $wiki->delete_node( name => "Four Node", version => 1 ); };
    is( $@, "",
         "delete_node doesn't die when deleting the only version of a node" );
    is( $wiki->retrieve_node("Four Node"), "",
	"...and retrieving that deleted node returns the empty string" );
    ok( ! $wiki->node_exists("Four Node"),
	    "...and ->node_exists now returns false" );
    SKIP: {
        skip "No search configured for this combination", 1
          unless $wiki->search_obj;
        my %results = $wiki->search_nodes("television");
        is_deeply( \%results, { }, "...and a search does not find the node" );
    }
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_was => { four => 1 } );
    is_deeply( \@nodes, [], "...doesn't show up in metadata_was search" );
    @nodes = $wiki->list_recent_changes(
                                         days => 7,
                                         metadata_is => { four => 1 } );
    is_deeply( \@nodes, [], "...doesn't show up in metadata_is search" );

    # Test deletion of a nonexistent node.
    eval { $wiki->delete_node( name => "idonotexist", version => 2 ); };
    is( $@, "",
	"delete_node doesn't die when deleting a non-existent node" );

    # Test deletion of a nonexistent version.
    $wiki->write_node( "Five Node", "elephant", undef, { five => 1 } )
      or die "Can't write node";
    eval { $wiki->delete_node( name => "Five Node", version => 2 ); };
    is( $@, "",
	"delete_node doesn't die when deleting a non-existent version" );
    ok( $wiki->node_exists("Five Node"),
        "...and ->node_exists still returns true" );
    is( $wiki->retrieve_node("Five Node"), "elephant",
	"...and retrieving the node returns the correct thing" );
}
