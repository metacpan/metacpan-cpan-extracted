use Test::More tests => 2;

use_ok ('Archive::TAP::Convert');

can_ok ('Archive::TAP::Convert', 'convert_from_taparchive');

