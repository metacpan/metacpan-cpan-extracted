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
  <style type="text/css">
    .selector1 {
      color: #ff0000;
    }
    .selector2 {
      color: #1e00ff;
    }
    .selector1 {
      font-weight: bold;
    }
  </style>
 </head>
 <body>
  <div class="selector1 selector2" style="color: #1e00ff;font-weight: bold;">
    Example Text    
  </div>
 </body>
</html>
END

my $correct_result = <<'END';
<html>
 <head>
 </head>
 <body>
  <div style="color: #1e00ff; font-weight: bold;"> Example Text </div>
 </body>
</html>
END

my $inliner = CSS::Inliner->new({ strip_attrs => 1 });
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok($inlined eq $correct_result, 'result was correct');
