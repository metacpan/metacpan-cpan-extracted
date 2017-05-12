use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

plan(tests => 5);

use_ok('CSS::Inliner');

my $html = <<END;
<html>
  <head>
    <title>Test Document</title>
    <style type="text/css">
    h1 { color: red; font-size: 20px }
    \@media screen and (max-width: 705px) {
      h2 { color: blue; font-size: 17px; }
    }
    </style>
  </head>
  <body>
    <h1 class="one">Howdy!</h1>
    <h2 class="two">Let's Play</h2>
    <p>Got any games?</p>
  </body>
</html>
END

my $inliner = CSS::Inliner->new({ leave_style => 1 });
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok($inlined =~ m/<h1 class="one" style="color: red; font-size: 20px;">Howdy!<\/h1>/, 'h1 rule inlined');
ok($inlined =~ m/<h2 class="two">Let's Play<\/h2>/, 'h2 rule inlined');
ok($inlined =~ m/<p>Got any games\?<\/p>/, 'p not styled');
ok($inlined =~ m/<style/, 'style tag remaining blocks left');
