#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

use_ok( 'Acme::LOLCAT' );

my $p;

my $YOUR = qr/Y?(?:O|U)?(?:A|R)(?:E|R)?/;
my $Z    = qr/(?:S|Z)/;

like( $p = translate( "can i please have a cheeseburger?" ),
      qr/(?:I CAN|CAN I) HA$Z CHEEZBURGR\?/,
      "translates cheeseburger phrase: $p" );

like( $p = translate( "you're right, i want more pickles." ),
      qr/$YOUR RITE, I WANT$Z MOAR PICKLE$Z/,
      "translates pickle phrase: $p" );

like( $p = translate( "I'm in your bathroom, reading your magazine" ),
      qr/IM IN $YOUR BATHRO(?:O|U)M, READI?NG?$Z? $YOUR MAGAZINE/,
      "translated magazine phrase: $p" );

like( $p = translate( "i'm in your world, planning your domination" ),
      qr/IM IN $YOUR WH?(?:U|I)?RR?LD, PLANNI?NG?$Z? $YOUR DOMINASHUN/,
      "translated domination phrase: $p" );

like( $p = translate( "i think that is a nice bucket" ),
      qr/I THINK THAT (?:AR|I$Z) (?:TEH )?NICE BUKK/,
      "translated bucket phrase: $p" );

like( $p = translate( "hello, i want to ask you a question" ),
      qr/O(?:H$Z?)? HAI, I WANT$Z (?:TO?|2) ASK Y?(?:U|OO|OU$Z) (?:Q|K)(?:W|U)ES?(?:J|SH)UN/,
      "translated question phrase: $p" );

like( $p = translate( "I'm in your bed and breakfast, eating your sausages" ),
      qr/IM IN $YOUR BED AN BREKKFAST, EATI?NG?$Z? $YOUR SAUSUJ$Z?/,
      "translated sausage phrase: $p" );

like( $p = translate( "free parties, events & more! what's happening?  who's going?" ),
      qr/FREE PARTIE$Z?, EVENT$Z? & MOAR! WH?UT$Z HAPPENI?NG?$Z?\? HOO$Z GOI?NG?$Z?\?/,
      "translated party ad text: $p" );

like( $p = translate( "I have a bucket." ),
      qr/I HA[SVZ] ?A? BUKK/, "translated bucket having phrase: $p" );

like( $p = translate( "Thank god I've updated this module." ),
      qr/(?:THN?X|(?:T|F)ANK) CEILING CAT IVE UPDATED THIS MODULE/,
      "translated diety phrase: $p" );
