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
    # Put some test data in.  All these nodes have some node linking
    # to them except "HomePage".
    $wiki->write_node("HomePage", "the home node")
      or die "Can't write node";
    $wiki->write_node("BacklinkTestOne",
              "This is some text.  It contains a link to BacklinkTestTwo.")
      or die "Can't write node";
    $wiki->write_node("BacklinkTestTwo",
        # don't break this line to pretty-indent it or the formatter will
        # think the second line is code and not pick up the link.
        "This is some text.  It contains a link to BacklinkTestThree and one to BacklinkTestOne.")
      or die "Can't write node";
    $wiki->write_node("BacklinkTestThree",
              "This is some text.  It contains a link to BacklinkTestOne.")
      or die "Can't write node";

    my @links = $wiki->list_backlinks( node => "BacklinkTestTwo" );
    is_deeply( \@links, [ "BacklinkTestOne" ],
               "backlinks work on nodes linked to once" );
    @links = $wiki->list_backlinks( node => "BacklinkTestOne" );
    is_deeply( [ sort @links],
               [ "BacklinkTestThree", "BacklinkTestTwo" ],
               "...and nodes linked to twice" );
    @links = $wiki->list_backlinks( node => "NonexistentNode" );
    is_deeply( \@links, [],
              "...returns empty list for nonexistent node not linked to" );
    @links = $wiki->list_backlinks( node => "HomePage" );
    is_deeply( \@links, [],
              "...returns empty list for existing node not linked to" );

    $wiki->delete_node("BacklinkTestOne") or die "Couldn't delete node";

    @links = $wiki->list_backlinks( node => "BacklinkTestTwo" );
    is_deeply( \@links, [],
               "...returns empty list when the only node linking to this one has been deleted" );

    eval { $wiki->write_node("MultipleBacklinkTest", "This links to NodeOne and again to NodeOne"); };
    is( $@, "",
        "doesn't die when writing a node that links to the same place twice" );

    # Now test that we don't get tripped up by case-sensitivity.
    my $content = "CleanupNode CleanUpNode";
    my @warnings;
    eval {
        local $SIG{__WARN__} = sub { push @warnings, $_[0]; };
        $wiki->write_node( "TestNode", $content );
    };
    is( $@, "", "->write_node doesn't die when content links to nodes differing only in case" );
    print "# ...but it does warn: " . join(" ", @warnings ) . "\n"
        if scalar @warnings;
}
