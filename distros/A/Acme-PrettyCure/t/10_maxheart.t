use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my ($nagi, $hono, $hikari) = Acme::PrettyCure->members('MaxHeart');

isa_ok $nagi,   'Acme::PrettyCure::CureBlack';
isa_ok $hono,   'Acme::PrettyCure::CureWhite';
isa_ok $hikari, 'Acme::PrettyCure::ShinyLuminous';

done_testing;

