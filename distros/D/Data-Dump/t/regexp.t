#!perl -w

use Test;

my @modern = ();
push @modern, 'p'          if $] >= 5.010;
push @modern, qw(a aa l u) if $] >= 5.014;
push @modern, 'n'          if $] >= 5.022;
push @modern, 'xx'         if $] >= 5.026;

plan tests => 1 + @modern;

use Data::Dump;

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

ok(Data::Dump::dump($a) . "\n", <<'EOT');
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

for my $mod (@modern) {
    ok(Data::Dump::dump(eval 'qr/Foo/' . $mod), "qr/Foo/$mod");
}
