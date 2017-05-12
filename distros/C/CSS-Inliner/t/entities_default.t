use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

plan(tests => 4);

use_ok('CSS::Inliner');

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
    <h1><>Howdy!<></h1>
    <h2>"Let's Play"</h2>
    <p>&&Got any games?&&</p>
  </body>
</html>
END

my $inliner = CSS::Inliner->new();
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok($inlined =~ m/<h1 style="color: red; font-size: 20px;"><>Howdy!<><\/h1>/, 'raw brackets present');
ok($inlined =~ m/<h2 style="color: blue; font-size: 17px;">"Let's Play"<\/h2>/, 'raw double quotes present, along with unescaped single quote');
ok($inlined =~ m/<p>&&Got any games\?&&<\/p>/, 'raw ampersands present');
