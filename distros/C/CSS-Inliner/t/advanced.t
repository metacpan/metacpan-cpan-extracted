use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

plan(tests => 8);

my $html = <<'END';
<html>
  <head>
    <title>Test Document</title>
    <style type="text/css">
    h1 { font-size: 20px }
    h1.alert { color: red }
    h1.cool { color: blue }
    .intro { color: #555555; font-size: 10px; }
    div p { color: #123123; font-size: 8px }
    p:hover { color: yellow }
    </style>
  </head>
  <body>
    <h1 class="alert">Lorem ipsum dolor sit amet</h1>
    <h1 class="cool">Consectetur adipiscing elit</h1>
    <p class="intro">Aliquam ornare luctus egestas.</p>
    <p>Nulla vulputate tellus vitae justo luctus scelerisque accumsan nunc porta.</p>
    <div>
      <p>Phasellus pharetra viverra sollicitudin. <strong>Vivamus ac enim ante.</strong></p>
      <p>Nunc augue massa, <em>dictum id eleifend non</em> posuere nec purus.</p>
    </div>
  </body>
</html>
END

my $inliner = CSS::Inliner->new();
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok($inlined =~ m/<h1 class="alert" style="font-size: 20px; color: red;">Lorem ipsum/, 'h1.alert rule inlined');
ok($inlined =~ m/<h1 class="cool" style="font-size: 20px; color: blue;">Consectetur/, 'h1.cool rule inlined');
ok($inlined =~ m/<p class="intro" style="color: #555555; font-size: 10px;">Aliquam/, '.intro rule inlined');
ok($inlined =~ m/<p style="color: #123123; font-size: 8px;">Phasellus/, 'div p rule inlined');
ok($inlined =~ m/<p style="color: #123123; font-size: 8px;">Nunc augue/, 'div p rule inlined again');
ok($inlined =~ m/<p>Nulla/, 'no rule for just "p"');
ok($inlined !~ m/<style/, 'no style blocks left');
ok($inlined !~ m/yellow/, ':hover pseudo-attribute was ignored');
