use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my ( $tsubomi, $erika, $itsuki, $yuri )
    = Acme::PrettyCure->members('HeartCatch');

isa_ok $tsubomi, 'Acme::PrettyCure::CureBlossom';
isa_ok $erika,   'Acme::PrettyCure::CureMarine';
isa_ok $itsuki,  'Acme::PrettyCure::CureSunshine';
isa_ok $yuri,    'Acme::PrettyCure::CureMoonlight';

done_testing;

