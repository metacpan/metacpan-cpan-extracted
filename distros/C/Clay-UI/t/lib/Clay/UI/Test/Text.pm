package Clay::UI::Test::Text;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Text;

our $VERSION = '0.01';

class Clay::UI::Test::Text :strict(params) :does(Clay::UI::Text) {}

1;
