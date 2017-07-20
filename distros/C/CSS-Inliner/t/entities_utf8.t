use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;
use charnames ':full';

plan(tests => 3);

use_ok('CSS::Inliner');

my $html = <<END;
<html>
  <head>
    <title>Test Document</title>
    <style type="text/css">
    h1 { color: red; font-size: 20px; }
    </style>
  </head>
  <body>
    <h1>Howdy!</h1>
    <h2>Let's Play</h2>
    <p>Got any games\N{INTERROBANG}&#8253;</p>
  </body>
</html>
END

my $inliner = CSS::Inliner->new();
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok($inlined =~ m/<h1 style="color: red; font-size: 20px;">Howdy!<\/h1>/, 'basic inlining correct');
ok($inlined =~ m/<p>Got any games\N{INTERROBANG}&#8253;<\/p>/, 'UTF8 characters remain in same format');
