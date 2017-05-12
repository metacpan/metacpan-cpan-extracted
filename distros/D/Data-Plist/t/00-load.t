use Test::More tests => 4;

use strict;
use warnings;

BEGIN {
    use_ok('Data::Plist');
    use_ok('Data::Plist::BinaryReader');
    use_ok('Data::Plist::XMLWriter');
    use_ok('Data::Plist::BinaryWriter');
}

diag("Testing Data::Plist $Data::Plist::VERSION");
