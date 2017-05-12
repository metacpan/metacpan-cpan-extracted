#! perl -w

use strict;
use Data::Microformat::hCard;

use Test::More tests => 14;

my $simple = << 'EOF';
<div class="vcard">
	<div class="fn">Alice Adams</div>
		<div class="tel">
		    <span class="type">Fax</span><span class="type">Preferred</span>415-344-0829
		</div>
	<div class="adr">
	    <span class="type">San Francisco</span>
		<span class="type">Headquarters</span>
	    <div class="street-address">548 4th St.</div>
	    <span class="locality">San Francisco</span>,  
	    <span class="region">CA</abbr>  
	    <span class="postal-code">94107</span>
	    <div class="country-name">USA</div>
	</div>
	</div>
EOF


ok(my $card = Data::Microformat::hCard->parse($simple));
is($card->fn, "Alice Adams");
ok(my @arr = $card->tel->type);
is(scalar @arr, 2);
is($arr[0], $card->tel->type);
is($arr[0], "Fax");
is($arr[1], "Preferred");
ok(@arr = $card->adr->type);
is(scalar @arr, 2);
is($arr[0], $card->adr->type);
is($arr[0], "San Francisco");
is($arr[1], "Headquarters");

my $comparison_of_type = << 'EOF';
<div class="tel">
	<div class="value">415-344-0829</div>
	<div class="type">Fax</div>
	<div class="type">Preferred</div>
</div>
EOF

my $comparison_of_adr = << 'EOF';
<div class="adr">
	<div class="street-address">548 4th St.</div>
	<div class="locality">San Francisco</div>
	<div class="region">CA</div>
	<div class="postal-code">94107</div>
	<div class="country-name">USA</div>
	<div class="type">San Francisco</div>
	<div class="type">Headquarters</div>
</div>
EOF

is($card->tel->to_hcard, $comparison_of_type);
is($card->adr->to_hcard, $comparison_of_adr);