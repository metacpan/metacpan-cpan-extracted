use strict;
use warnings;

use Test::More tests => 5;

use_ok('Convert::Color::ScaleModels');

my $color = Convert::Color::ScaleModels->new();

isa_ok($color, "Convert::Color::ScaleModels");

is($color->name('61', 'humbrol'), 'flesh matt', 'got flesh matt');
is($color->name('5', 'revell'), 'white matt', 'got white matt');
is($color->name('xf21', 'tamiya'), 'beige green matt', 'got beige green matt');

