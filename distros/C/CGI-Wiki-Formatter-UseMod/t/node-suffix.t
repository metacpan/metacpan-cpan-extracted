use strict;
use Test::More tests => 2;
use CGI::Wiki::Formatter::UseMod;
use Test::MockObject;

my $wikitext = <<WIKITEXT;

ExistingNode

NonExistentNode

WIKITEXT

my $wiki = Test::MockObject->new;
$wiki->mock( "node_exists",
             sub {
                 my ($self, $node) = @_;
                 return $node eq "ExistingNode" ? 1 : 0;
             } );

my $formatter = CGI::Wiki::Formatter::UseMod->new(
    node_prefix => "/wiki/",
    node_suffix => ".html",
    edit_prefix => "/wiki/edit/",
    edit_suffix => ".html",
);

my $html = $formatter->format( $wikitext, $wiki );

like( $html, qr|<a href="/wiki/ExistingNode.html">ExistingNode</a>|,
      "node_suffix works" );
like( $html, qr|<a href="/wiki/edit/NonExistentNode.html">|,
      "edit_suffix works" );
