package Clay::UI::Test::GridCell;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Box;
use Clay::UI::Role::Layout::GridCell;

our $VERSION = '0.01';

class Clay::UI::Test::GridCell :strict(params) :does(Clay::UI::Box) :does(Clay::UI::Role::Layout::GridCell) {}

1;
