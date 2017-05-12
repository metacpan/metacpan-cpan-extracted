use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('CommonMark');
}

my $parser = CommonMark::Parser->new;
isa_ok($parser, 'CommonMark::Parser', 'Parser->new');

$parser->feed("normal *em");
$parser->feed("ph*\n\n**strong**\n\n> blo");
$parser->feed("ck\n> quote\n");

my $doc = $parser->finish;
isa_ok($doc, 'CommonMark::Node', 'finish');

my $expected_html = <<'EOF';
<p>normal <em>emph</em></p>
<p><strong>strong</strong></p>
<blockquote>
<p>block
quote</p>
</blockquote>
EOF
is($doc->render_html, $expected_html, 'parser works');

