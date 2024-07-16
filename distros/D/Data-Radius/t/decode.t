use strict;
use warnings;
use Test::More tests => 22 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Data::Radius::Decode', qw(decode)) };
BEGIN { use_ok('Data::Radius::Dictionary') };

my $dict = Data::Radius::Dictionary->load_file('./radius/dictionary');
ok($dict, 'dictionary loaded');

is(decode({type => 'integer'}, "\x00\x00\x02\x17"), 535, 'int');
is(decode({type => 'string'}, 'test it'), 'test it', 'string');
is(decode({type => 'byte'}, "\x0a"), 10, 'byte');
is(decode({type => 'short'}, "\x00\x0a"), 10, 'short');
is(decode({type => 'signed'}, "\xff\xff\xff\xf6"), -10, 'signed');
is(decode({type => 'ipaddr'}, "\x0a\x14\x1e\x28"), '10.20.30.40', "IPv4");
is(decode({type => 'ipv6addr'}, "\xfe\x80\x00\x00\x00\x00\x00\x00\x5c\xee\xa6\xff\xfe\x1c\xf2\x04"), 'fe80::5cee:a6ff:fe1c:f204', 'IPv6');
is(decode({type => 'octets'}, "\xc3\x9c\xc3\xa4\x7a\xd0\xa4"), "0xc39cc3a47ad0a4", 'octects');
is(decode({type => 'combo-ip'}, "\x0a\x14\x1e\x28"), '10.20.30.40', 'combo-ip IPv4');
is(decode({type => 'combo-ip'}, "\xfe\x80\x00\x00\x00\x00\x00\x00\x16\xda\xe9\xff\xfe\xef\xae\x06"), 'fe80::16da:e9ff:feef:ae06',  'combo-ip IPv6');
my $attr = $dict->attribute('h323-remote-id');
is($attr->{vendor}, 'Cisco', 'Vendor Cisco');
is($attr->{id}, 1, 'VSA Cisco-AVPair');
is(decode($attr, 'h323-remote-id=777', $dict), 'h323-remote-id=777', 'avpair with VSA 1');
$attr = $dict->attribute('h323-billing-model');
is($attr->{vendor}, 'Cisco', 'Vendor Cisco');
is($attr->{id}, 109, 'VSA h323-billing-model');
is(decode($attr, 'AAA=BBB', $dict), 'AAA=BBB', 'avpair value do not match attribute name');
is(decode($attr, 'h323-billing-model=BBB', $dict), 'BBB', 'avpair - cut duplicated attribute name');

$attr = $dict->attribute('WiMAX-Capability');
my $v = decode($attr, "\x01\x05\x35\x2E\x30", $dict);
is_deeply($v, [{ Name => 'WiMAX-Release', Value => '5.0', Type => 'string'}], 'TLV with 1 sub-attribute');

$v = decode($attr, "\x01\x05\x35\x2E\x30\x03\x03\x08", $dict);
is_deeply($v, [
    { Name => 'WiMAX-Release', Value => '5.0', Type => 'string'},
    { Name => 'WiMAX-Hotlining-Capabilities', Value => 'IP-Redirection', Type => 'byte'},
],"TLV with 2 sub-attributes");

