use strict;
use Test::More tests => 3;
use CGI::Wiki::Formatter::UseMod;

eval { require CGI::Wiki; require DBD::SQLite; };
my $test_wiki_available = $@ ? 0 : 1;

SKIP: {
    skip "Either CGI::Wiki or DBD::SQLite not installed", 2
      unless $test_wiki_available;

    my $dbname = "./t/sqlite.db";
    require CGI::Wiki::Setup::SQLite; require CGI::Wiki::Store::SQLite;
    CGI::Wiki::Setup::SQLite::cleardb( $dbname );
    CGI::Wiki::Setup::SQLite::setup( $dbname );
    my $store = CGI::Wiki::Store::SQLite->new( dbname => $dbname );
    my $wiki = CGI::Wiki->new( store => $store );
    $wiki->write_node( "A state51 Node That Exists", "foo" )
      or die "Can't write test node";

    my $wikitext = <<WIKITEXT;

[[A state51 node that exists]]

[[A nonexistent state51 node]]

WIKITEXT

    my $formatter = CGI::Wiki::Formatter::UseMod->new(
        extended_links  => 1,
        munge_urls      => 1,
        munge_node_name => sub {
                               my $node_name = shift;
                               $node_name =~ s/State51/state51/g;
                               return $node_name;
                           },
    );
    
    my $html = $formatter->format( $wikitext, $wiki );

    like( $html, qr|<a href="wiki.pl\?A_state51_Node_That_Exists">A state51 node that exists</a>|, "->format works with munge_node_name and existing links" );
    
    like( $html, qr|<a href="wiki.pl\?action=edit;id=A_Nonexistent_state51_Node">\?</a>|, "->format works with munge_node_name and nonexistent links" );

}

my $wikitext = "[[A state51 node]]";


my $formatter = CGI::Wiki::Formatter::UseMod->new(
    extended_links  => 1,
    munge_urls      => 1,
    munge_node_name => sub {
                           my $node_name = shift;
                           $node_name =~ s/State51/state51/g;
                           return $node_name;
                       },
);

my @nodes = $formatter->find_internal_links( $wikitext );
is_deeply( \@nodes, [ "A state51 Node" ],
           "->find_internal_links works with munge_node_name" );
