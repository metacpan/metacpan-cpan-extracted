#!perl -w

use strict;
use Data::Microformat::hCard;

use Test::More tests => 11;

my $simple = << 'EOF';
	<div class="vcard">
		<a href="http://www.example.com/" class="url uid">A website</a>
	</div>
EOF

ok(my $one_card = Data::Microformat::hCard->parse($simple, "http://www.example.com"));
is($one_card->is_representative, 1);

$simple = << 'EOF';
	<div class="vcard">
		<a href="http://www.example.com/" class="url uid">http://www.example.com/</a>
	</div>
	<div class="vcard">
		<a href="http://www.example.org/" class="url uid">A website</a>
	</div>
EOF

ok(my @cards = Data::Microformat::hCard->parse($simple, "http://www.example.com"));
is($cards[0]->is_representative, 1);
is($cards[1]->is_representative, 0);


$simple = << 'EOF';

	<div class="vcard">
		<a href="http://www.example.org/" class="url uid">A website</a>
	</div>
	<div class="vcard">
		<a href="http://www.example.net/" class="url" rel="me">A website</a>
	</div>
EOF

ok(@cards = Data::Microformat::hCard->parse($simple, "http://www.example.com"));
is($cards[0]->is_representative, 0);
is($cards[1]->is_representative, 1);

$simple = << 'EOF';

	<div class="vcard">
		<a href="http://www.example.org/" class="url uid">A website</a>
	</div>
	<div class="vcard">
		<a href="http://www.example.net/" class="url" >A website</a>
	</div>
EOF

ok(@cards = Data::Microformat::hCard->parse($simple, "http://www.example.com"));
is($cards[0]->is_representative, 0);
is($cards[1]->is_representative, 0);
