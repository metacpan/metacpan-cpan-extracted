use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my ($love, $miki, $bukky, $setsu) = Acme::PrettyCure->members('Fresh');

isa_ok $love,  'Acme::PrettyCure::CurePeach';
isa_ok $miki,  'Acme::PrettyCure::CureBerry';
isa_ok $bukky, 'Acme::PrettyCure::CurePine';
isa_ok $setsu, 'Acme::PrettyCure::CurePassion';

done_testing;

