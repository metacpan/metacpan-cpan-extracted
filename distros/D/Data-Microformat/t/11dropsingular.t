#!perl -w

use strict;
use Data::Microformat::hCard;

use Test::More tests => 11;

my $simple = << 'EOF';
<div class="vcard">
	<div class="fn">Type A</div>
	<div class="fn">Type B</div>
	<div class="n">
		<span class="given-name">Fred</span>
		<span class="family-name">Flinstone</span>
	</div>
	<div class="n">
		<span class="given-name">Barney</span>
		<span class="family-name">Rubble</span>
	</div>
	<span class="bday">1985-10-02</span>
	<span class="bday">1986-09-04</span>
	<span class="tz">-5:00</span>
	<span class="tz">+0:00</span>
	<div class="geo">
		<span class="latitude">37.386013</span>, 
    	<span class="longitude">-122.082932</span>
	</div>
	<div class="geo">
		<span class="latitude">0</span>, 
    	<span class="longitude">0</span>
	</div>
	<span class="sort-string">Flinstone</span>
	<span class="sort-string">Rubble</span>
	<span class="uid">http://ussjoin.com</span>
	<span class="uid">http://www.davidrecordon.com</span>
	<span class="class">Public</span>
	<span class="class">Private</span>
</div>
EOF

ok(my $card = Data::Microformat::hCard->parse($simple));
is($card->fn, "Type A");
is($card->n->given_name, "Fred");
is($card->n->family_name, "Flinstone");
is($card->bday, "1985-10-02");
is($card->tz, "-5:00");
is($card->geo->latitude, "37.386013");
is($card->geo->longitude, "-122.082932");
is($card->sort_string, "Flinstone");
is($card->uid, "http://ussjoin.com");
is($card->class, "Public");
