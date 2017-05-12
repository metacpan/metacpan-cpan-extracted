use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;
use HTML::TreeBuilder;

plan(tests => 6);

my $html = <<END;
<html>
  <head>
    <title>Test Document</title>
    <style type="text/css">
    h1 { color: red; font-size: 20px }
    h2 { color: blue; font-size: 17px; }
    </style>
  </head>
  <body>
    <!-- Some comment -->
    <h1>Howdy!</h1>
    <h2>Let's Play</h2>
    <p>Got any games?</p>
    <foo>Bar</foo>
  </body>
</html>
END

my $html_tree = HTML::TreeBuilder->new();
$html_tree->ignore_unknown(1);
my $inliner = CSS::Inliner->new({ html_tree => $html_tree });
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok($inlined =~ m/<h1 style="color: red; font-size: 20px;">Howdy!<\/h1>/, 'h1 rule inlined');
ok($inlined !~ m/<style/, 'no style blocks left');
ok($inlined !~ m/<foo>/, 'ignoring unknown elements');

$html_tree->ignore_unknown(0);
$inliner = CSS::Inliner->new({ html_tree => $html_tree });
$inliner->read({ html => $html });
$inlined = $inliner->inlinify();

ok($inlined =~ m/<h1 style="color: red; font-size: 20px;">Howdy!<\/h1>/, 'custom html_tree: h1 rule inlined');
ok($inlined !~ m/<style/, 'no style blocks left');
ok($inlined =~ m/<foo>/, 'ignoring unknown elements');

