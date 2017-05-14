use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my ($nozomi, $rin, $urara, $komachi, $karen) = Acme::PrettyCure->members('Five');

isa_ok $nozomi,  'Acme::PrettyCure::CureDream';
isa_ok $rin,     'Acme::PrettyCure::CureRouge';
isa_ok $urara,   'Acme::PrettyCure::CureLemonade';
isa_ok $komachi, 'Acme::PrettyCure::CureMint';
isa_ok $karen,   'Acme::PrettyCure::CureAqua';

done_testing;

