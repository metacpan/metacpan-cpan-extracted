#!perl -w

use strict;
use Data::Microformat::hCard;

use Test::More tests => 26;

#Basic card taken from the microformats wiki: http://microformats.org/wiki/hcard
#CSS nonsense taken from http://thegestalt.org/simon, see 0.04 changelog
my $simple = << 'EOF';
<style type="text/css">
body { background-color: #ddd; color: #222;             }
h1   { font-size: 160%; font-weight: normal; margin: 0; }
h2   { font-size: 110%; font-weight: normal; margin: 0; }
</style>
<div class="vcard">
  <a class="fn org url" href="http://www.commerce.net/">CommerceNet</a>
  <div class="adr">
    <span class="type">Work</span>:
    <div class="street-address">169 University Avenue</div>
    <span class="locality">Palo Alto</span>,  
    <span class="region" title="California">CA</span>  
    <span class="postal-code">94301</span>
    <div class="country-name">USA</div>
  </div>
  <div class="tel">
   <span class="type">Work</span> +1-650-289-4040
  </div>
  <div class="tel">
    <span class="type">Fax</span> +1-650-289-4041
  </div>
  <div>Email: 
   <span class="email">info@commerce.net</span>
  </div>
  <div class="geo">GEO: 
    <span class="latitude">37.386013</span>, 
    <span class="longitude">-122.082932</span>
  </div>
</div>
EOF

ok(my $card = Data::Microformat::hCard->parse($simple));
is($card->fn, "CommerceNet");
is($card->url, "http://www.commerce.net/");
is($card->org->organization_name, "CommerceNet");
is($card->n->given_name, undef);
ok(my @adrs = $card->adr);
is(scalar @adrs, 1);
ok(my $adr = $adrs[0]);
is($adr->type, "Work");
is($adr->street_address, "169 University Avenue");
is($adr->extended_address, undef);
is($adr->locality, "Palo Alto");
is($adr->region, "CA");
is($adr->postal_code, "94301");
is($adr->country_name, "USA");
ok(my $geo = $card->geo);
is($geo->latitude, "37.386013");
is($geo->longitude, "-122.082932");
ok(my @tel = $card->tel);
is(scalar @tel, 2);
ok(my $t = $tel[0]);
is($t->type, "Work");
is($t->value, "+1-650-289-4040");
ok($t = $tel[1]);
is($t->type, "Fax");
is($t->value, "+1-650-289-4041");
