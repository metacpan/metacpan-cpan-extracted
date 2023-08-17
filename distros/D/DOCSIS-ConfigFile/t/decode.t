BEGIN { $ENV{DOCSIS_CAN_TRANSLATE_OID} = 0; }
use warnings;
use strict;
use DOCSIS::ConfigFile;
use Test::More;

our $AUTOLOAD;

is_deeply(
  snmp_object(48, 10, 6, 2, 42, 3, 2, 3, 255, 0, 1),
  {oid => '1.2.3', type => 'INTEGER', value => -65535},
  'snmp_object() decoded'
);
is_deeply(
  snmp_object(48, 10, 6, 2, 42, 3, 2, 4, 127, 255, 255, 255),
  {oid => '1.2.3', type => 'INTEGER', value => 2147483647},
  'snmp_object() decoded'
);

is(bigint(1, 182, 155, 75, 172, 208, 95, 21), '123456789123456789',
  'bigint() = 123456789123456789');
is(bigint(255, 0, 1), -65535, 'bigint() = -65535');

is(main::int(0, 2, 0),            512,         'int() = 512');
is(main::int(127, 255, 255, 255), 2147483647,  'int() = 2147483647');
is(main::int(0, 255, 255),        65535,       'int() = 65535');
is(main::int(255, 255),           -1,          'int() = -1');
is(main::int(255, 0, 1),          -65535,      'int() = -65535');
is(main::int(128, 0, 0, 0),       -2147483648, 'int() = -2147483648');
is(uint(73, 150, 2, 210),         1234567890,  'uint() = 1234567890');
is(ushort(48, 57),                12345,       'ushort() = 12345');
is(uchar(123),                    123,         'uchar() = 123');

is_deeply(
  [vendorspec(8, 3, 0, 19, 55, 24, 1, 66)],
  ['0x001337' => [{type => 24, length => 1, value => '0x42'}]],
  'vendorspec() decoded',
);

is_deeply(
  [vendorspec(8, 3, 0, 0, 12, 4, 8, 0, 0, 255, 255, 0, 0, 0, 10)],
  ['0x00000c' => [{type => 4, length => 8, value => '0x0000ffff0000000a'}]],
  'vendorspec() decoded',
);

is(ip(1, 2, 3, 4),                  '1.2.3.4',      'ip() = 1.2.3.4');
is(ether(1, 35, 69, 103, 137, 171), '0123456789ab', 'ether() = 0123456789ab');

#is(ether(1,35,69,103), 1234567, 'ether() = 1234567');
is(string(1, 35, 69, 103, 137, 171, 205, 239),
  '0x0123456789abcdef', 'string() = 0x0123456789abcdef');

is(
  string(
    115, 116, 114, 105, 110, 103, 32,  99, 111, 110, 116, 97, 105, 110,
    105, 110, 103, 32,  112, 101, 114, 99, 101, 110, 116, 58, 32,  37
  ),
  'string containing percent: %25',
  'string() = string containing percent: %25',
);

is(hexstr(1, 35, 69, 103, 137, 171, 205, 239),
  '0x0123456789abcdef', 'hexstr() = 0x0123456789abcdef');

is(
  mic(102, 68, 55, 160, 241, 15, 242, 18, 129, 161, 47, 155, 128, 106, 239, 7),
  '0x664437a0f10ff21281a12f9b806aef07',
  'mic(102,68,55,160,241,15,242,18,129,161,47,155,128,106,239,7)',
);

is(no_value(), '', 'no value decoded as empty string');

done_testing;

# evil hack to simplify things...
sub AUTOLOAD {
  my $sub = DOCSIS::ConfigFile::Decode->can($AUTOLOAD =~ /(\w+)$/);
  $sub->(pack 'C*', @_);
}
