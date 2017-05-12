use strict;
use warnings;
use utf8;
use Test::Exception tests => 1;
use Time::Piece;

use Acme::PrettyCure::Girl::CureFlower;

my $kaoru = Acme::PrettyCure::Girl::CureFlower->new;

my $now = localtime;

if ( $now->mon == 12 && $now->mday == 24 ) {
    lives_ok { $kaoru->transform } "cure flower transform ok";
} else {
    throws_ok { $kaoru->transform; } qr/CureFlower can transform only holy night/, "cure flower transform ng";
}

