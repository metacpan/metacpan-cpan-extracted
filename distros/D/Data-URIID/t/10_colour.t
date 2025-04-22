#!/usr/bin/perl -w
    
use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More;

use_ok('Data::URIID::Colour');

my $colour = Data::URIID::Colour->new(rgb => '#000000');

isa_ok($colour, 'Data::URIID::Colour');
is($colour->rgb, '#000000');
is($colour->ise, '6a1338b8-517f-5b45-9c17-37cda5d7146d');
isa_ok($colour->ise(as => 'Data::Identifier'), 'Data::Identifier');

$colour = Data::URIID::Colour->new(rgb => '#fFfFfF');
isa_ok($colour, 'Data::URIID::Colour');
is($colour->rgb, '#FFFFFF');
is($colour->ise, 'feb62789-9ad6-5302-9a17-9de4f2f44d5c');
isa_ok($colour->ise(as => 'Data::Identifier'), 'Data::Identifier');

done_testing();

exit 0;
