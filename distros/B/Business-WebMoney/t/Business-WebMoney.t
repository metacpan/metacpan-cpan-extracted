# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-WebMoney.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Business::WebMoney') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $wm = Business::WebMoney->new(
	p12_file => '',
	p12_pass => '',
);

ok($wm, 'constructor');

my $ops = $wm->get_operations(
	reqn => 1,
	purse => 'R000000000000',
	datestart => '20081001 00:00:00',
	datefinish => '20090101 00:00:00',
	debug_response => '<?xml version="1.0"?><w3s.response><reqn>1</reqn><operations cnt="8" cntA="8"><operation id="150977211" ts="150977211"><pursesrc>R000000000000</pursesrc><pursedest>R000000000000</pursedest><amount>18000.00</amount><comiss>0.00</comiss><opertype>0</opertype><wminvid>0</wminvid><orderid>0</orderid><tranid>0</tranid><period>0</period><desc>Camel</desc><datecrt>20081103 08:26:20</datecrt><dateupd>20081103 08:26:20</dateupd><corrwm>000000000000</corrwm><rest>18000.00</rest></operation></operations></w3s.response>',
) or die $wm->errstr;

ok($ops, 'get_operations');

cmp_ok(scalar(@$ops), '==', 1, 'get_operations.1');
cmp_ok($ops->[0]->{id}, '==', 150977211, 'get_operations.2');
cmp_ok($ops->[0]->{dateupd}, 'eq', '20081103 08:26:20');
