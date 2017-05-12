use Test::More tests => 2;

use_ok ('Convert::TAP::Archive');

can_ok ('Convert::TAP::Archive', 'convert_from_taparchive');

