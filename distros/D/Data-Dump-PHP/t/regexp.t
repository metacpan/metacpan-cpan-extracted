#!perl -w

use Data::Dump::PHP;
use Test;
plan tests => 1;

$a = {
   a => qr/Foo/,
   b => qr,abc/,is,
   c => qr/ foo /x,
   d => qr/foo/msix,
   e => qr//,
   g => qr,///////,,
   h => qr*/|,:*,
   i => qr*/|,:#*,
};

ok(Data::Dump::PHP::dump_php($a) . "\n", <<'EOT');
array(
  "a" => "/Foo/",
  "b" => "|abc/|si",
  "c" => "/ foo /x",
  "d" => "/foo/msix",
  "e" => "//",
  "g" => "|///////|",
  "h" => "#/|,:#",
  "i" => "/\\/|,:#/",
)
EOT

#print Data::Dump::PHP::dump_php($a), "\n";
