use strict;
local $^W = 1;

use Test::More tests => 25;
use Test::MockObject;

use_ok( "CGI::Wiki::Formatter::UseMod" );

print "#\n#### Testing default configuration\n#\n";
my $wikitext = <<WIKITEXT;

==== Welcome ====

This is some WikiText.

: This should be a
: definition list with data
: but no terms

==== LinkInAHeader ====

 pig
 pig

==== Header with an = in ====

 spaces  are significant

Another WikiWord.

WIKITEXT

my $formatter = CGI::Wiki::Formatter::UseMod->new;
isa_ok( $formatter, "CGI::Wiki::Formatter::UseMod" );
my $html = $formatter->format($wikitext);

like( $html, qr|<a href="wiki.pl\?WikiText">WikiText</a>|,
      "WikiWords made into links" );
like( $html, qr|<h4>Welcome</h4>|, "headings work" );
like( $html,
      qr|<h4><a href="wiki.pl\?LinkInAHeader">LinkInAHeader</a></h4>|,
      "...links work in headers" );
like( $html, qr|<h4>Header with an = in</h4>|, "...headers may contain =" );
like( $html, qr|<dl>\s*<dd>&nbsp;This should be a</dd>\s*<dd>&nbsp;definition list with data</dd>\s*<dd>&nbsp;but no terms</dd>\s*</dl>|,
      "leading : made into <dl>" );
like( $html, qr|<pre>\npig\npig\n</pre>|,
      "leading space makes <pre>" );

my @links = $formatter->find_internal_links($wikitext);
is_deeply( [ sort @links ], [ "LinkInAHeader", "WikiText", "WikiWord" ],
	   "find_internal_links seems to work" );
print "# Found internal links: " . join(", ", sort @links) . "\n";

print "#\n#### Testing HTML escaping\n#\n";
$wikitext = <<WIKITEXT;

&pound;

<i>
<strike>

WIKITEXT

$formatter = CGI::Wiki::Formatter::UseMod->new;
$html = $formatter->format($wikitext);
like( $html, qr|&pound;|, "Entities preserved by default." );
unlike( $html, qr|<strike>|, "HTML tags escaped by default" );

$formatter = CGI::Wiki::Formatter::UseMod->new( allowed_tags => [ "strike" ] );
$html = $formatter->format($wikitext);
like( $html, qr|<strike>|, "...but not when we allow them" );
unlike( $html, qr|<i>|, "...and ones we don't explicitly allow are escaped" );
like( $html, qr|&pound;|, "Entities still preserved." );

print "#\n#### Testing extended links\n#\n";
$wikitext = <<WIKITEXT;

This is an [[Extended Link]].

This is a lower-case [[extended link]].

This is a [[Extended Link|titled extended link]].

This is a [[Extended Link Two | title with leading whitespace]].

This is [[Another Link|another titled link]].

WIKITEXT

my $wiki = Test::MockObject->new;
$wiki->mock( "node_exists",
	    sub { my ($self, $node) = @_;
		  if ( $node eq "Extended Link" or $node eq "Extended Link Two"
		       or $node eq "Another Link" ) {
		      return 1;
		  } else {
		      return 0;
                  }
		}
);

# Test with munged URLs.
$formatter = CGI::Wiki::Formatter::UseMod->new( extended_links => 1,
                                                munge_urls     => 1 );
$html = $formatter->format($wikitext, $wiki);

like( $html, qr|<a href="wiki.pl\?Extended_Link">Extended Link</a>|,
      "extended links work" );
like( $html, qr|<a href="wiki.pl\?Extended_Link">extended link</a>|,
      "...and are forced ucfirst" );
like( $html, qr|<a href="wiki.pl\?Extended_Link">titled extended link</a>|,
      "...and titles work" );
like( $html, qr|[^ ]title with leading whitespace|,
      "...and don't show leading whitespace" );
like( $html, qr|<a href="wiki.pl\?Extended_Link_Two">|,
      "...and titled nodes with trailing whitespace are munged correctly before formatting" );

# Test with unmunged URLs.
$formatter = CGI::Wiki::Formatter::UseMod->new( extended_links => 1 );
$html = $formatter->format($wikitext, $wiki);

like( $html, qr|<a href="wiki.pl\?Extended%20Link">Extended Link</a>|,
      "extended links work with unmunged URLs" );
like( $html, qr|<a href="wiki.pl\?Extended%20Link">extended link</a>|,
      "...and are forced ucfirst" );
like( $html, qr|<a href="wiki.pl\?Extended%20Link">titled extended link</a>|,
      "...and titles work" );

@links = $formatter->find_internal_links($wikitext);
print "# Found links: " . join(", ", @links) . "\n";
my %linkhash = map { $_ => 1 } @links;
ok( ! defined $linkhash{"extended link"},
    "find_internal_links respects ucfirst" );
ok( ! defined $linkhash{"Extended Link "},
    "...and drops trailing whitespace" );
is_deeply( \@links, [ "Extended Link", "Extended Link", "Extended Link", "Extended Link Two", "Another Link" ], "...and gets the right order" );
