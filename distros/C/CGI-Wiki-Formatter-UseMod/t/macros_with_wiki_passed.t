use strict;
use CGI::Wiki;
use CGI::Wiki::Formatter::UseMod;
use CGI::Wiki::Setup::SQLite;
use CGI::Wiki::Store::SQLite;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    plan skip_all => "DBD::SQLite not installed - no db to test with.";
    exit 0;
}

eval { require CGI::Wiki; };
if ( $@ ) {
    plan skip_all => "CGI::Wiki not installed";
    exit 0;
}

plan tests => 2;
my $dbname = "t/node.db";

# Clear out the database from any previous runs. 
unlink $dbname;
CGI::Wiki::Setup::SQLite::setup( { dbname => $dbname } );

my $wikitext = "\@INDEX_LINK [[Category Foo]]";
my $formatter = CGI::Wiki::Formatter::UseMod->new(
    extended_links      => 1,
    macros              => {
        qr/\@INDEX_LINK\s+\[\[Category\s+([^\]]+)]]/ =>
             sub {
                   my ($wiki, $category) = @_;
                   my @nodes = $wiki->list_nodes_by_metadata(
                       metadata_type  => "category",
                       metadata_value => $category,
                       ignore_case    => 1,
                   );
                   my $return = "\n";
                   foreach my $node ( @nodes ) {
                       $return .= "* "
                              . $wiki->formatter->format_link(
                                                             wiki => $wiki,
                                                             link => $node,
                                                             )
                              . "\n";
                   }
                   return $return;
                 },
                           },
    pass_wiki_to_macros => 1,
);

isa_ok( $formatter, "CGI::Wiki::Formatter::UseMod" );

my $store = CGI::Wiki::Store::SQLite->new( dbname => $dbname );
my $wiki = CGI::Wiki->new(
                           formatter => $formatter,
                           store     => $store,
                         );
$wiki->write_node( "Wibble", "wibble", undef, { category => "Foo" } )
  or die "Can't write node";

my $html = $formatter->format( $wikitext, $wiki );
like( $html, qr|<a href="wiki.pl\?Wibble">Wibble</a>|,
      "macros with wiki passed work OK" );

