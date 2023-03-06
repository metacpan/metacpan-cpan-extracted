use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

plan(tests => 21);

# moderately complicated rules with elements and classes
my $html = <<'END';
<html>
  <head>
    <title>Moderate Document</title>
    <style type="text/css">
    h1 { font-size: 20px }
    h1.alert { color: red }
    h1.cool { color: blue }
    .intro { color: #555555; font-size: 10px; }
    div p { color: #123123; font-size: 8px }
    p:hover { color: yellow }
    p.poor { font-weight: lighter }
    p.rich { font-weight: bold }
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
    <p class="poor rich">Luctus scelerisque accumsan nunc porta</p>
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
ok($inlined =~ m/<p class="poor rich" style="font-weight: bold;">Luctus/, 'rich before the poor');
ok($inlined !~ m/<style/, 'no style blocks left');
ok($inlined !~ m/yellow/, ':hover pseudo-attribute was ignored');

# a more complicated example with ids, class, attribute selectors
# in a cascading layout
$html = <<'END';
<html>
  <head>
    <title>Complicated Document</title>
    <style type="text/css">
    h1 { font-size: 20px; }
    #title { font-size: 25px; }
    h1.cool { color: blue; }
    h1.alert { color: red; }
    h1.cool.alert { font-size: 30px; font-weight: 800; }
    h1.alert.cool { font-size: 30px; font-weight: 900; }
    .intro { color: #555555; font-size: 10px; }
    div p { color: #123123; font-size: 8px; }
    p { font-weight: 200; font-size: 9px; }
    p:hover { color: yellow; }
    p.poor { font-weight: 300; color: black; }
    p.rich { font-weight: 400; color: black; }
    div[align=right] p { color: gray; }
    </style>
  </head>
  <body>
    <h1 class="alert cool" id="title">Lorem ipsum dolor sit amet</h1>
    <h1 class="cool">Consectetur adipiscing elit</h1>
    <p class="intro">Aliquam ornare luctus egestas.</p>
    <p>Nulla vulputate tellus vitae justo luctus scelerisque accumsan nunc porta.</p>
    <div align="left">
      <p>Phasellus pharetra viverra sollicitudin. <strong>Vivamus ac enim ante.</strong></p>
      <p>Nunc augue massa, <em>dictum id eleifend non</em> posuere nec purus.</p>
    </div>
    <div align="right">
      <p>Vivamus ac enim ante.</p>
      <p class="rich">Dictum id eleifend non.</p>
    </div>
    <p class="poor rich">Luctus scelerisque accumsan nunc porta</p>
  </body>
</html>
END

$inliner = CSS::Inliner->new();
$inliner->read({ html => $html });
$inlined = $inliner->inlinify();
ok($inlined =~ m/<h1 class="alert cool" id="title" style="color: red; font-weight: 900; font-size: 25px;">Lorem ipsum/, 'cascading rules for h1.alert.cool inlined');
ok($inlined =~ m/<h1 class="cool" style="font-size: 20px; color: blue;">Consectetur/, 'h1.cool rule inlined');
ok($inlined =~ m/<p class="intro" style="font-weight: 200; color: #555555; font-size: 10px;">Aliquam/, '.intro rule inlined');
ok($inlined =~ m/<p style="font-weight: 200; font-size: 9px;">Nulla/, 'just the "p" rule');
ok($inlined =~ m/<p style="font-weight: 200; color: #123123; font-size: 8px;">Phasellus/, 'div p rule inlined');
ok($inlined =~ m/<p style="font-weight: 200; color: #123123; font-size: 8px;">Nunc augue/, 'div p rule inlined again');
ok($inlined =~ m/<p style="font-weight: 200; font-size: 8px; color: gray;">Vivamus/, '"div[align=right] p" + "div p" + "p"');
ok($inlined =~ m/<p class="rich" style="font-size: 8px; font-weight: 400; color: gray;">Dictum/, '"div[align=right] p" + "div p" + "p" + "p.rich"');
ok($inlined =~ m/<p class="poor rich" style="font-size: 9px; font-weight: 400; color: black;">Luctus/, 'rich before the poor');
ok($inlined !~ m/<style/, 'no style blocks left');
ok($inlined !~ m/yellow/, ':hover pseudo-attribute was ignored');
ok($inlined !~ m/30px/, 'h1.cool.alert font-size ignored');

