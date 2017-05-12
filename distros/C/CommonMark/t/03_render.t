use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('CommonMark', 'OPT_DEFAULT');
}

my $md = <<EOF;
# Header

Paragraph *emph*, **strong**
EOF

my $expected_html = <<EOF;
<h1>Header</h1>
<p>Paragraph <em>emph</em>, <strong>strong</strong></p>
EOF

is(CommonMark->markdown_to_html($md), $expected_html, 'markdown_to_html');

my $doc = CommonMark->parse_document($md);
isa_ok($doc, 'CommonMark::Node', 'parse_document');

is($doc->render_html, $expected_html, 'parse_document works');

like($doc->render_xml, qr/^<\?xml /, 'render_xml');
like($doc->render_man, qr/^\.SH\n/, 'render_man');
like($doc->render_latex, qr/^\\section\{Header\}/, 'render_latex');

my $rendered_md = $doc->render_commonmark(OPT_DEFAULT, 20);
my $expected_md = <<'EOF';
# Header

Paragraph *emph*,
**strong**
EOF
is($rendered_md, $expected_md, 'render_commonmark');

is(CommonMark->markdown_to_html("\x{263A}"), "<p>\x{263A}</p>\n",
   'render functions return encoded utf8');

is(CommonMark->markdown_to_html("\xC2\xA9"), "<p>\xC2\xA9</p>\n",
   'render functions expect decoded utf8');

