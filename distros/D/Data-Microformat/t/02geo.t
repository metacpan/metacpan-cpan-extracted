#!perl -w

use strict;
use Data::Microformat::geo;

use Test::More tests => 5;

my $simple = << 'EOF';
<div class="geo">GEO: 
 <span class="latitude">37.779598</span>, 
 <span class="longitude">-122.398453</span>
</div>
EOF

ok(my $geo = Data::Microformat::geo->parse($simple));

is($geo->latitude, "37.779598");
is($geo->longitude, "-122.398453");

my $comparison = << 'EOF';
<div class="geo">
	<div class="latitude">37.779598</div>
	<div class="longitude">-122.398453</div>
</div>
EOF

is($geo->to_hcard, $comparison);

my $text_comparison = << 'EOF';
geo: 
	latitude: 37.779598
	longitude: -122.398453
EOF
is($geo->to_text, $text_comparison);