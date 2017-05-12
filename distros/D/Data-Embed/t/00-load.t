use Test::More tests => 5;

BEGIN {
   use_ok('Data::Embed');
   use_ok('Data::Embed::Reader');
   use_ok('Data::Embed::Writer');
   use_ok('Data::Embed::File');
   use_ok('Data::Embed::Util');
}

diag("Testing Data::Embed $Data::Embed::VERSION");
