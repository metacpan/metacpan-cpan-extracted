use strict;
use CGI::Wiki::Formatter::UseMod;
use Test::More tests => 2;

my $wikitext = <<WIKITEXT;

http://external.example.com/

[http://external2.example.com foo]

WIKITEXT

my $formatter = CGI::Wiki::Formatter::UseMod->new;

my $html = $formatter->format( $wikitext );

like( $html,
      qr'<a href="http://external.example.com/">http://external.example.com/</a>',
      "external links with no title appear as expected" );

like( $html,
      qr'[<a href="http://external2.example.com/">foo</a>]',
      "external links with title appear as expected" );
