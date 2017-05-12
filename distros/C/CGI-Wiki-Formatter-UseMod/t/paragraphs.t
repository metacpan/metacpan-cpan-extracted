use strict;
use Test::More tests => 2;

use CGI::Wiki::Formatter::UseMod;

my $formatter = CGI::Wiki::Formatter::UseMod->new;

# The CGI linebreak is \r\n, not \n.
my $wikitext = "\r\nThis is paragraph 1.\r\n\r\nThis is paragraph 2.\r\n";
my $html = $formatter->format( $wikitext );
like( $html, qr/<p>\s*This is paragraph 1./, "first paragraph detected" );
like( $html, qr/<p>\s*This is paragraph 2./,
      "second paragraph, separated from first by blank line, detected" );
