# -*- perl -*-

use strict;
use warnings;
use Test::More;

use_ok('CSS::Scopifier');

ok( 
  my $CSS = CSS::Scopifier->read('t/var/example.css'),
  'New CSS::Scopifier object'
);

is($CSS->write_string,
q~h2 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.4em;
	letter-spacing: .1em;
}
h1 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.5em;
	letter-spacing: .1em;
}
body {
	font-family: "Palatino Linotype", Freeserif, serif;
	letter-spacing: .05em;
}
~,
'Expected pre-scopify CSS');

ok(
  $CSS->scopify('div.foo'),
  'Call scopify()'
);

is($CSS->write_string,
q~div.foo h2 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.4em;
	letter-spacing: .1em;
}
div.foo h1 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.5em;
	letter-spacing: .1em;
}
div.foo body {
	font-family: "Palatino Linotype", Freeserif, serif;
	letter-spacing: .05em;
}
~,
'Expected post-scopify CSS');

ok( 
  my $CSS2 = CSS::Scopifier->read('t/var/example.css'),
  'Another new CSS::Scopifier object'
);

ok(
  $CSS2->scopify('#myid', merge => ['html','body']),
  'Call scopify() with options: merge => [\'html\',\'body\']'
);

is($CSS2->write_string,
q~#myid h2 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.4em;
	letter-spacing: .1em;
}
#myid h1 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.5em;
	letter-spacing: .1em;
}
#myid {
	font-family: "Palatino Linotype", Freeserif, serif;
	letter-spacing: .05em;
}
~,
'Expected post-scopify CSS with merge option supplied');

done_testing;
