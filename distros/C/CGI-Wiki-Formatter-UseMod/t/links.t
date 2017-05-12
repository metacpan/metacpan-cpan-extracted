use strict;
use Test::MockObject;
use Test::More tests => 4;

my $wikitext = <<WIKITEXT;

ExistingNode

NonExistentNode

http://external.example.com/

[http://external2.example.com/ foo]

WIKITEXT

my $wiki = Test::MockObject->new;
$wiki->mock( "node_exists",
             sub {
                 my ($self, $node) = @_;
                 return $node eq "ExistingNode" ? 1 : 0;
             } );

my $formatter = CGI::Wiki::Formatter::Kake->new(
    node_prefix => "/wiki/",
    node_suffix => ".html",
    edit_prefix => "/wiki/edit/",
    edit_suffix => ".html",
);

my $html = $formatter->format( $wikitext, $wiki );

like( $html, qr|\[NonExistentNode\]<a href="/wiki/edit/NonExistentNode.html" title="create">\?</a>|,
      "can override ->make_edit_link" );

like( $html,
      qr|<a href="/wiki/ExistingNode.html" class="internal">ExistingNode</a>|,
      "can override ->make_internal_link" );

like( $html,
      qr'<a href="http://external.example.com/">http://external.example.com/</a> <img src="external.gif">',
      "can override ->make_external_link" );

like( $html,
      qr'<a href="http://external2.example.com/">foo</a> <img src="external.gif">',
      "...works for external links with titles too" );

package CGI::Wiki::Formatter::Kake;
use base "CGI::Wiki::Formatter::UseMod";

sub make_edit_link {
    my ($self, %args) = @_;
    my $title = $args{title};
    my $url = $args{url};
    return qq|[$title]<a href="$url" title="create">?</a>|;
}

sub make_internal_link {
    my ($self, %args) = @_;
    my $title = $args{title};
    my $url = $args{url};
    return qq|<a href="$url" class="internal">$title</a>|;
}

sub make_external_link {
    my ($self, %args) = @_;
    my $title = $args{title};
    my $url = $args{url};
    return qq|<a href="$url">$title</a> <img src="external.gif">|;
}
