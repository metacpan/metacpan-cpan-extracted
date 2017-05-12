#! perl -w

use strict;
use Data::Microformat::hCard;

use Test::More tests => 8;

my $simple = << 'EOF';
<div class="vcard nestification">
	<div class="fn">Alice Adams</div>
	<div class="vcard agent">
		<div class="fn">Bob Barker</div>
		<div class="nickname">Yuppie</div>
	</div>
	<div class="nickname">Needs an Agent</div>
</div>
EOF


ok(my $card = Data::Microformat::hCard->parse($simple));
is($card->fn, "Alice Adams");
is($card->nickname, "Needs an Agent");
ok(my $nest = $card->agent);
is($nest->fn, "Bob Barker");
is($nest->nickname, "Yuppie");

my $comparison = << 'EOF';
<div class="vcard">
	<div class="fn">Alice Adams</div>
	<div class="n">
		<div class="given-name">Alice</div>
		<div class="family-name">Adams</div>
	</div>
	<div class="agent vcard">
		<div class="fn">Bob Barker</div>
		<div class="n">
			<div class="given-name">Bob</div>
			<div class="family-name">Barker</div>
		</div>
		<div class="nickname">Yuppie</div>
	</div>
	<div class="nickname">Needs an Agent</div>
</div>
EOF

is($card->to_hcard, $comparison);

my $text_comparison = << 'EOF';
vcard: 
	fn: Alice Adams
	n: 
		given-name: Alice
		family-name: Adams
	agent vcard: 
		fn: Bob Barker
		n: 
			given-name: Bob
			family-name: Barker
		nickname: Yuppie
	nickname: Needs an Agent
EOF
is($card->to_text, $text_comparison);