use strict;
use CGI::Wiki::Formatter::UseMod;
use Test::More tests => 8;

my $wikitext = <<WIKITEXT;

||foo||bar||
||baz||quux||

WIKITEXT

my $formatter = CGI::Wiki::Formatter::UseMod->new;

my $html = $formatter->format( $wikitext );

like( $html, qr'<table', "a table is created" );
like( $html, qr|<tr.*<tr|s, "with two rows" );
like( $html, qr|<td.*<td.*<td.*<td|s, "with four table cells" );
like( $html, qr|foo.*bar.*baz.*quux|s, "textual content is there" );

$wikitext = <<WIKITEXT;

|| foo || bar ||
|| baz || quux ||

WIKITEXT

$html = $formatter->format( $wikitext );

like( $html, qr'<table', "with whitespace... a table is created" );
like( $html, qr|<tr.*<tr|s, "...with two rows" );
like( $html, qr|<td.*<td.*<td.*<td|s, "...with four table cells" );
like( $html, qr|foo.*bar.*baz.*quux|s, "...textual content is there" );
