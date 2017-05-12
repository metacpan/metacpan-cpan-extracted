# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::Number::Delta relative => 1e-6;
use Test::More tests => 22;

BEGIN { use_ok( 'Data::Convert::MicrochipTechnology::Float' ); }

my $object = Data::Convert::MicrochipTechnology::Float->new ();
isa_ok ($object, 'Data::Convert::MicrochipTechnology::Float');

is($object->convert("\0\0\0\0"),              0, "Zero");
is($object->convert("\0\x80\0\0"),           -0, "Negative Zero");
is($object->convert("\x7f\0\0\0"),            1, "One");
is($object->convert([127,0,0,0]),            1, "One");
is($object->convert("\x7f\x80\0\0"),         -1, "Negative One");
delta_ok($object->convert("\x82\x20\0\0"),         10, "Ten");
delta_ok($object->convert("\x85\x48\0\0"),        100, "One Hundred");
delta_ok($object->convert("\x85\x76\xE6\x66"), 123.45, "123.45");
delta_ok($object->convert("\xc8\x27\x4e\x53"), 123.45e20, "123.45e20");
delta_ok($object->convert("\x43\x36\x2e\x17"), 123.45e-20, "123.45e-20");
my ($zero, $one) = $object->convert("\0\0\0\0", "\x7f\0\0\0");
is($zero, 0, "Zero array context");
is($one, 1, "One array context");
($zero, $one) = $object->convert([0,0,0,0], [127, 0, 0, 0]);
is($zero, 0, "Zero array context");
is($one, 1, "One array context");
($zero, $one) = $object->convert("\0\0\0\0", [127, 0, 0, 0]);
is($zero, 0, "Zero array context");
is($one, 1, "One array context");
my $aref = $object->convert("\0\0\0\0", "\x7f\0\0\0");
is($aref->[0], 0, "Zero scalar context");
is($aref->[1], 1, "One scalar context");

is($object->float_from_string("\0\0\0\0"),     0, "float_from_string");
is($object->float_from_array(127, 128, 0, 0), -1, "float_from_array");
