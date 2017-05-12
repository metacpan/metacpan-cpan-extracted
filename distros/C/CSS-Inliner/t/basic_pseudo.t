use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

plan(tests => 3);

use_ok('CSS::Inliner');

local $SIG{__WARN__} = sub {
  my $message = shift;
  die $message; # map any warnings here to a fatal
};

my $html1 = <<END;
<html>
  <head>
    <title>Test Document</title>
    <style type="text/css">
      :focus { }
    </style>
  </head>
  <body>
    <h1>Howdy!</h1>
    <h2>Let's Play</h2>
    <p>Got any games?</p>
  </body>
</html>
END

my $inliner = CSS::Inliner->new();
$inliner->read({ html => $html1 });
my $inlined1 = $inliner->inlinify();

ok($inlined1, 'Leading whitespace psuedo rule processed correctly');

my $html2 = <<END;
<html>
  <head>
    <title>Test Document</title>
    <style type="text/css">:focus {}</style>
  </head>
  <body>
    <h1>Howdy!</h1>
    <h2>Let's Play</h2>
    <p>Got any games?</p>
  </body>
</html>
END

$inliner->read({ html => $html2 });
my $inlined2 = $inliner->inlinify();

ok($inlined2, 'No whitespace psuedo rule processed correctly');
