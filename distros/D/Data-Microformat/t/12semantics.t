#!perl -w

use strict;
use Data::Microformat::hCard;

use Test::More tests => 32;

my $simple = << 'EOF';
<div class="vcard">
  <abbr class="nickname" title="Foo">FooBar</abbr>
  <a href="http://ussjoin.com" class="photo">Test</a>
  <a href="http://ussjoin.com" class="note">Test</a>
  <object data="http://ussjoin.com" class="sound">Test</object>
  <object data="http://ussjoin.com" class="title">Test</object>
  <img src="http://ussjoin.com" alt="Test" class="logo"/>
  <img src="http://ussjoin.com" alt="Test" class="role"/>
  <span class="tel">
	<span class="type">Home</span>
	<a class="value" href="tel:+1.415.555.1212">My Phone</span>
  </span>
  <span class="email">
	<span class="type">Work</span>
	<area class="value" href="mailto:jobs@sixapart.com">Jobs Email</area>
</span>
</div>
EOF

ok(my $card = Data::Microformat::hCard->parse($simple));
is($card->nickname, "Foo");
is($card->photo, "http://ussjoin.com");
is($card->note, "Test");
is($card->sound, "http://ussjoin.com");
is($card->title, "Test");
is($card->logo, "http://ussjoin.com");
is($card->role, "Test");
is($card->tel->value, "+1.415.555.1212");
is($card->email->value, 'jobs@sixapart.com');

$simple = << 'EOF';
<span class="org">
	<abbr class="organization-name" title="Zaphod for President">Bad</abbr>
	<abbr class="organization-unit" title="Dirty Tricks">Bad</abbr>
</span>
EOF

ok(my $org = Data::Microformat::hCard::organization->parse($simple));

is($org->organization_name, "Zaphod for President");
is($org->organization_unit, "Dirty Tricks");


$simple = << 'EOF';
<span class="n">
	<abbr class="family-name" title="Pag">Bad</abbr>
	<abbr class="given-name" title="Zipo">Bad</abbr>
	<abbr class="additional-name" title="Judiciary">Bad</abbr>
	<abbr class="honorific-prefix" title="His High Judgmental Supremacy">Bad</abbr>
	<abbr class="honorific-suffix" title="Learned, Impartial, and Very Relaxed">Bad</abbr>
</span>
EOF

ok(my $name = Data::Microformat::hCard::name->parse($simple));

is($name->family_name, "Pag");
is($name->given_name, "Zipo");
is($name->additional_name, "Judiciary");
is($name->honorific_prefix, "His High Judgmental Supremacy");
is($name->honorific_suffix, "Learned, Impartial, and Very Relaxed");

$simple = << 'EOF';
<span class="tel">
	<abbr class="type" title="Home">Bad</abbr>
	<abbr class="value" title="+1.415.555.1212">Bad</abbr>
</span>
EOF

ok(my $type = Data::Microformat::hCard::type->parse($simple));

is($type->type, "Home");
is($type->value, "+1.415.555.1212");

$simple = << 'EOF';
<div class="geo">GEO: 
 <abbr class="latitude" title="37.386013">Bad</abbr>, 
 <abbr class="longitude" title="-122.082932">Bad</abbr>
</div>
EOF

ok(my $geo = Data::Microformat::geo->parse($simple));

is($geo->latitude, "37.386013");
is($geo->longitude, "-122.082932");

$simple = << 'EOF';
<div class="adr">
 <abbr class="street-address" title="665 3rd St.">Bad</abbr>
 <abbr class="extended-address" title="Suite 207">Bad</abbr>
 <abbr class="locality" title="San Francisco">Bad</abbr>,
 <abbr class="region" title="CA">Bad</abbr>
 <abbr class="postal-code" title="94107">Bad</abbr>
 <abbr class="country-name" title="U.S.A.">Bad</abbr>
</div>
EOF

ok(my $adr = Data::Microformat::adr->parse($simple));

is($adr->street_address, "665 3rd St.");
is($adr->extended_address, "Suite 207");
is($adr->locality, "San Francisco");
is($adr->region, "CA");
is($adr->postal_code, "94107");
is($adr->country_name, "U.S.A.");
