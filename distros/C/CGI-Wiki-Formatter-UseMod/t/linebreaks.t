use strict;
use Test::More tests => 1;

use CGI::Wiki::Formatter::UseMod;

my $formatter = CGI::Wiki::Formatter::UseMod->new(
    allowed_tags => [ qw( table tr td ) ],
);

my $wikitext = <<WIKI;

<table>
  <tr>
    <td>A table cell</td>
  </tr>
</table>

WIKI

my $html = $formatter->format( $wikitext );
unlike( $html, qr|<br />|, "no bogus <br />s" );
