#!perl -w

use strict;
use Data::Microformat::adr;

use Test::More tests => 9;

#Basic adr taken from the microformats wiki: http://microformats.org/wiki/adr
my $simple = << 'EOF';
<div class="adr">
 <div class="street-address">665 3rd St.</div>
 <div class="extended-address">Suite 207</div>
 <span class="locality">San Francisco</span>,
 <span class="region">CA</span>
 <span class="postal-code">94107</span>
 <div class="country-name">U.S.A.</div>
</div>
EOF

ok(my $adr = Data::Microformat::adr->parse($simple));

is($adr->street_address, "665 3rd St.");
is($adr->extended_address, "Suite 207");
is($adr->locality, "San Francisco");
is($adr->region, "CA");
is($adr->postal_code, "94107");
is($adr->country_name, "U.S.A.");

my $comparison = << 'EOF';
<div class="adr">
	<div class="street-address">665 3rd St.</div>
	<div class="extended-address">Suite 207</div>
	<div class="locality">San Francisco</div>
	<div class="region">CA</div>
	<div class="postal-code">94107</div>
	<div class="country-name">U.S.A.</div>
</div>
EOF

is($adr->to_hcard, $comparison);

my $text_comparison = << 'EOF';
adr: 
	street-address: 665 3rd St.
	extended-address: Suite 207
	locality: San Francisco
	region: CA
	postal-code: 94107
	country-name: U.S.A.
EOF
is($adr->to_text, $text_comparison);