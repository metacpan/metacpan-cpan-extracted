#! perl -w

use strict;
use Data::Microformat::hCard;

use Test::More tests => 95;

my $simple = << 'EOF';
<div class="vcard">
  <div class="adr">
    <span class="type">San Francisco</span>:
    <div class="street-address">548 4th St.</div>
    <span class="locality">San Francisco</span>,  
    <span class="region">CA</abbr>  
    <span class="postal-code">94107</span>
    <div class="country-name">USA</div>
  </div>
  <div class="adr">
    <span class="type">Paris</span>:
    <div class="street-address">48 rue de la Bienfaisance</div>
    <span class="locality">Paris</span>
    <span class="postal-code">75008</span>
    <div class="country-name">France</div>
  </div>
  <div class="agent">Ben Trott</div>
  <div class="agent">Mena Trott</div>
  <div class="category">blogging</div>
  <div class="category">openness</div>
  <span class="email">jobs@sixapart.com</span>
  <span class="email">advertise@sixapart.com</span>
  <div class="key">0x26F9298E</div>
  <div class="key">0xBD21C225</div>
  <div class="label">Awesome</div>
  <div class="label">Cool</div>
  <a class="logo" href="http://www.sixapart.com/about/press/about/press/Six_Apart_Logos.zip">Logos!</a>
  <a class="logo" href="http://www.sixapart.com/images/six-apart-logo.png">One Logo!</a>
  <div class="mailer">Mail.App</div>
  <div class="mailer">Thunderbird</div>
  <div class="nickname">Greatest Place to Work Ever</div>
  <div class="nickname">Super Happy Fun Factory</div>
  <div class="note">This is a very long set of tests.</div>
  <div class="note">But everything needs to be tested.</div>
  <div class="org">
   <span class="organization-name">Six Apart</span>
   <span class="organization-unit">Open Platforms</span>
  </div>
  <div class="org">
   <span class="organization-name">Six Apart New York</span>
   <span class="organization-unit">Excitement and Really Wild Things</span>
  </div>
  <a class="photo" href="http://www.officesnapshots.com/wp-content/galleries/sixaparttour/sixapart02.jpg">The Front Door</a>
  <a class="photo" href="http://www.officesnapshots.com/wp-content/galleries/sixaparttour/sixapart23.jpg">Sofas</a>
  <div class="rev">2008-07-30</div>
  <div class="rev">2008-07-31</div>
  <div class="role">Engineer</div>
  <div class="role">Innovator</div>
  <a class="sound" href="http://podcast.thebasementventures.com/mp3/0/353177/IA9688_7_9_2008_1091972.mp3">July 9 MT Podcast</a>
  <a class="sound" href="http://podcast.thebasementventures.com/mp3/0/353177/IA9688_6_25_2008_1091337.mp3">June 25 MT Podcast</a>
  <div class="tel">
   <span class="type">Work</span>415-344-0056
  </div>
  <div class="tel">
    <span class="type">Fax</span>415-344-0829
  </div>
  <div class="title">Manager</div>
  <div class="title">Programmer</div>
  <a class="url" href="http://www.sixapart.com">Six Apart</a>
  <a class="url" href="http://www.movabletype.org">Movable Type Open Source</a>
</div>
<div class="vcard">
  <a class="url" href="http://www.movabletype.org">Movable Type Open Source</a>
</div>
EOF

ok(my @cards = Data::Microformat::hCard->parse($simple));
is(scalar @cards, 2);
ok(my $card = Data::Microformat::hCard->parse($simple));
is_deeply($card, $cards[0]);
isnt($cards[0], $cards[1]);
#For each item, check that if I read it into an array I get two, if I read it into a scalar I get one which == arr[0].
ok(my @arr = $card->adr);
ok(my $one = $card->adr);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->agent);
ok($one = $card->agent);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->category);
ok($one = $card->category);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->email);
ok($one = $card->email);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->key);
ok($one = $card->key);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->label);
ok($one = $card->label);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->logo);
ok($one = $card->logo);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->mailer);
ok($one = $card->mailer);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->nickname);
ok($one = $card->nickname);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->note);
ok($one = $card->note);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->org);
ok($one = $card->org);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->photo);
ok($one = $card->photo);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->rev);
ok($one = $card->rev);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->role);
ok($one = $card->role);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->sound);
ok($one = $card->sound);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->tel);
ok($one = $card->tel);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->title);
ok($one = $card->title);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
ok(@arr = $card->url);
ok($one = $card->url);
is(scalar @arr, 2);
is($one, $arr[0]);
isnt($one,$arr[1]);
