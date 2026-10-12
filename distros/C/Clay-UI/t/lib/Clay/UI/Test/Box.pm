package Clay::UI::Test::Box;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Box;

our $VERSION = '0.01';

class Clay::UI::Test::Box :strict(params) :does(Clay::UI::Box) {}

1;
