#!perl -w

BEGIN {
    print "1..0 # Skipped: can't handle regular expressions, yet.\n";
    exit;
}

use Test;
plan tests => 1;

use Data::Dump::Perl6 qw(dump_perl6);

$a = {
   a => qr/Foo/,
   b => qr,abc/,is,
   c => qr/ foo /x,
   d => qr/foo/msix,
   e => qr//,
   f => qr/
     # hi there
     how do this look
   /x,
   g => qr,///////,,
   h => qr*/|,:*,
   i => qr*/|,:#*,
};

ok(dump_perl6($a) . "\n", <<'EOT');
{
  a => qr/Foo/,
  b => qr|abc/|si,
  c => qr/ foo /x,
  d => qr/foo/msix,
  e => qr//,
  f => qr/
            # hi there
            how do this look
          /x,
  g => qr|///////|,
  h => qr#/|,:#,
  i => qr/\/|,:#/,
}
EOT
