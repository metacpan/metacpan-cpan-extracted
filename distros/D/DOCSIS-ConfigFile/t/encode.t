use warnings;
use strict;
use DOCSIS::ConfigFile::Encode;
use Test::More;

our $AUTOLOAD;
my @uchar;

plan tests => 16;

# local $" = ','; used for failing tests

eval {
  @uchar = snmp_object({value => {oid => '1.2.3', type => 'INTEGER', value => 1234567890},});
  is_deeply(\@uchar, [48, 10, 6, 2, 42, 3, 2, 4, 73, 150, 2, 210], 'snmp_object() encoded') or diag "@uchar";

  @uchar = bigint({value => '123456789123456789'});
  is_deeply(\@uchar, [1, 182, 155, 75, 172, 208, 95, 21], 'bigint() encoded') or diag "@uchar";

  @uchar = main::int({value => -1234567890});
  is_deeply(\@uchar, [201, 150, 2, 209], 'int() encoded negative integer') or diag "@uchar";

  @uchar = main::int({value => 1234567890});
  is_deeply(\@uchar, [73, 150, 2, 210], 'int() encoded positive integer') or diag "@uchar";

  @uchar = uint({value => 1234567890});
  is_deeply(\@uchar, [73, 150, 2, 210], 'uint() encoded') or diag "@uchar";

  @uchar = ushort({value => 12345});
  is_deeply(\@uchar, [48, 57], 'ushort() encoded') or diag "@uchar";

  @uchar = uchar({value => 123});
  is_deeply(\@uchar, [123], 'uchar() encoded') or diag "@uchar";

  @uchar = vendorspec({value => '0x001337', nested => [{type => 24, value => 42}],});
  is_deeply(\@uchar, [8, 3, 0, 19, 55, 24, 1, 66], 'vendorspec() encoded') or diag "@uchar";

  @uchar = ip({value => '1.2.3.4'});
  is_deeply(\@uchar, [1, 2, 3, 4], 'ip() encoded') or diag "@uchar";

  @uchar = ether({value => '0x0123456789abcdef'});
  is_deeply(\@uchar, [1, 35, 69, 103, 137, 171, 205, 239], 'ether() encoded') or diag "@uchar";

  @uchar = ether({value => 1234567});
  is_deeply(\@uchar, [1, 35, 69, 103], 'ether() encoded') or diag "@uchar";

  @uchar = string({value => '0x0123456789abcdef'});
  is_deeply(\@uchar, [1, 35, 69, 103, 137, 171, 205, 239], 'string() encoded') or diag "@uchar";

  @uchar = string({value => 'string containing percent: %25'});
  is_deeply(
    \@uchar,
    [
      115, 116, 114, 105, 110, 103, 32,  99, 111, 110, 116, 97, 105, 110,
      105, 110, 103, 32,  112, 101, 114, 99, 101, 110, 116, 58, 32,  37
    ],
    'string() encoded'
  ) or diag "@uchar";

  @uchar = hexstr({value => '0x0123456789abcdef'});
  is_deeply(\@uchar, [1, 35, 69, 103, 137, 171, 205, 239], 'hexstr() encoded') or diag "@uchar";

  @uchar = mic({value => 'foo'});
  is_deeply(\@uchar, [], 'mic() encoded') or diag "@uchar";

  is_deeply([no_value({value => 'foo'})], [], 'no value decoded as empty list');
} or diag $@;

# evil hack to simplify things...
sub AUTOLOAD {
  my $sub = DOCSIS::ConfigFile::Encode->can($AUTOLOAD =~ /(\w+)$/);
  $sub->(@_);
}
