
use Test::More tests => 4;
BEGIN { use_ok('Data::VString', 'format_vstring') };

is(format_vstring("\x{0}"), "0", "'\\x{0}' formats right");
is(format_vstring("\x{90}\x{2}\x{89}"), "144.2.137");

TODO: {
  local $TODO = 'should work issues with Unicode';
  is(format_vstring("\x{800}\x{FFFE}\x{5}"), "2048.65534.5");
}



