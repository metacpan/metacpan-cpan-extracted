package Clay::UI::Test::Grid;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Grid;

our $VERSION = '0.01';

class Clay::UI::Test::Grid :strict(params) :does(Clay::UI::Grid) {}

1;
