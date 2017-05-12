use strict;
use warnings;

use Test::More tests => 8;

use_ok('Convert::Color::ScaleModels');

my $color = Convert::Color::ScaleModels->new();

isa_ok($color, "Convert::Color::ScaleModels");

is($color->convert('61', 'humbrol', 'revell'), '35', 'got 35');
is($color->convert('35', 'revell', 'humbrol'), '61', 'got 61');
is($color->convert('61', 'humbrol', 'tamiya'), 'xf15', 'got xf15');
is($color->convert('xf15', 'tamiya', 'humbrol'), '61', 'got 61');
is($color->convert('67', 'revell', 'tamiya'), 'xf27', 'got xf27');
is($color->convert('xf27', 'tamiya', 'revell'), '67', 'got 67');

