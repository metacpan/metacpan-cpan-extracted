use strict;
use warnings;

use Encode;
use Test::More tests => 11;

BEGIN {
    use_ok('CommonMark', ':opt');
}

my ($md, $expected);

$md = "aaa\n\nbbb";
$expected = <<'EOF';
<p data-sourcepos="1:1-1:3">aaa</p>
<p data-sourcepos="3:1-3:3">bbb</p>
EOF
is(CommonMark->markdown_to_html($md, OPT_SOURCEPOS), $expected, 'SOURCEPOS');

$md = "a\nb";
is(CommonMark->markdown_to_html($md, OPT_HARDBREAKS), "<p>a<br />\nb</p>\n",
   'HARDBREAKS');
SKIP: {
    skip('NOBREAKS not supported by libcmark', 1)
        if CommonMark->version < 0x001A00;
    is(CommonMark->markdown_to_html($md, OPT_NOBREAKS), "<p>a b</p>\n",
       'NOBREAKS');
}
is(CommonMark->markdown_to_html($md), "<p>a\nb</p>\n",
   'without HARDBREAKS or NOBREAKS');

$md = <<'EOF';
<script>alert('XSS')</script>

a <b/> [link](javascript:alert('XSS'))
EOF
$expected = <<'EOF';
<!-- raw HTML omitted -->
<p>a <!-- raw HTML omitted --> <a href="">link</a></p>
EOF
is(CommonMark->markdown_to_html($md), $expected, 'SAFE is default');
is(CommonMark->markdown_to_html($md, OPT_SAFE|OPT_UNSAFE), $expected,
   'SAFE takes precedence over UNSAFE');
$expected = <<'EOF';
<script>alert('XSS')</script>
<p>a <b/> <a href="javascript:alert(&#x27;XSS&#x27;)">link</a></p>
EOF
is(CommonMark->markdown_to_html($md, OPT_UNSAFE), $expected, 'UNSAFE');

$md = "a\xC0b";
Encode::_utf8_on($md);
is(CommonMark->markdown_to_html($md, OPT_VALIDATE_UTF8), "<p>a\x{FFFD}b</p>\n",
   'VALIDATE_UTF8');
my $html = CommonMark->markdown_to_html($md);
Encode::_utf8_off($html);
is($html, "<p>a\xC0b</p>\n", 'without VALIDATE_UTF8');

$md = q{"a" -- 'b' --- c};
$expected = <<"EOF";
<p>\x{201C}a\x{201D} \x{2013} \x{2018}b\x{2019} \x{2014} c</p>
EOF
is(CommonMark->markdown_to_html($md, OPT_SMART), $expected, 'SMART');

