#!perl -w

use Data::Dump::Ruby;
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

ok(Data::Dump::Ruby::dump_ruby($a) . "\n", <<'EOT');
{
  "a" => %r/Foo/,
  "b" => %r|abc/|mi,
  "c" => %r/ foo /x,
  "d" => %r/foo/mix,
  "e" => %r//,
  "g" => %r|///////|,
  "h" => %r#/|,:#,
  "i" => %r/\/|,:#/,
}
EOT

#print Data::Dump::Ruby::dump_ruby($a), "\n";
