use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

plan(tests => 2);

use_ok('CSS::Inliner');

my $html = <<END;
<html>
  <head>
    <title>Test Document</title>
    <style type="text/css">
    h1 { color: red !important; font-size: 20px }
    .green { color: green }
    </style>
  </head>
  <body>
    <h1 class="green">Howdy!</h1>
  </body>
</html>
END

my $inliner = CSS::Inliner->new();
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok($inlined =~ m/<h1 class="green" style="color: red !important; font-size: 20px;">Howdy!<\/h1>/, '!important applied correctly');

