use strict;
use warnings;

use FindBin qw($Bin);
use File::Temp qw();

use Test::Deep qw(cmp_deeply);
use Test::More tests => 33;

BEGIN { use_ok('Data::Radius::Dictionary') };

my $dict = Data::Radius::Dictionary->load_file('./radius/dictionary');
ok($dict, 'RADIUS dictionary loaded');

my $username = $dict->attribute('User-Name');
ok($username, 'found attribute User-Name');
is($username->{id}, 1, 'User-Name has id 1');
is($username->{type}, 'string', 'User-Name has type string');
ok(!$username->{has_tag}, 'User-Name has no tags');
ok(!$username->{encrypt}, 'User-Name not encrypted');

my $acct_time = $dict->attribute('Acct-Session-Time');
ok($acct_time, 'found Acct-Session-Time');
is($acct_time->{id}, 46, 'Acct-Session-Time has id 46');
is($acct_time->{type}, 'integer', 'Acct-Session-Time has type integer');

my $vendor_attr = $dict->attribute('Huawei-Priority');
ok($vendor_attr, 'found vendor attribute Huawei-Priority');
is($vendor_attr->{id}, 22, 'Huawei-Priority has id 22');
is($vendor_attr->{type}, 'integer', 'Huawei-Priority has type integer');
is($vendor_attr->{vendor}, 'Huawei', 'Huawei-Priority is from vendor Huawei');

my $tlv_attr = $dict->attribute('WiMAX-Media-Flow-Type');
ok($tlv_attr, 'found WiMAX-Media-Flow-Type');
is($tlv_attr->{id}, 12, 'WiMAX-Media-Flow-Type has id 12');
is($tlv_attr->{type}, 'byte', 'WiMAX-Media-Flow-Type has type byte');
is($tlv_attr->{vendor}, 'WiMAX', 'WiMAX-Media-Flow-Type is from vendor WiMAX');
is($tlv_attr->{parent}, 'WiMAX-QoS-Descriptor', 'WiMAX-Media-Flow-Type is sub-attribute of WiMAX-QoS-Descriptor');

my $tag_attr = $dict->attribute('Tunnel-Type');
ok($tag_attr, 'found Tunnel-Type');
ok($tag_attr->{has_tag}, 'Tunnel-Type has tag');
ok(!$tag_attr->{encrypt}, 'Tunnel-Type not encrypted');

$tag_attr = $dict->attribute('Tunnel-Password');
ok($tag_attr, 'found Tunnel-Password');
ok($tag_attr->{has_tag}, 'Tunnel-Password has tag');
is($tag_attr->{encrypt}, 2, 'Tunnel-Password is encrypted');

# testing multiple dicts loaded simultaneously in single instance

my $multi_dict = Data::Radius::Dictionary->from_multiple_files(
    sprintf('%s/../%s', $Bin, 'radius/rfc4372'),
    sprintf('%s/../%s', $Bin, 'radius/mera'),
);
ok($multi_dict, 'Multiple RADIUS dictionaries loaded into single instance');

# attribute from rfc4372 dict
my $ch_user_ident = $multi_dict->attribute('Chargeable-User-Identity');
ok($ch_user_ident, 'found attribute Chargeable-User-Identity');
is($ch_user_ident->{id}, 89, 'Chargeable-User-Identity has id 89');
is($ch_user_ident->{type}, 'string', 'Chargeable-User-Identity has type string');

# attribute from mera dict
my $xpkg_xrout_user = $multi_dict->attribute('xpgk-xrouting-username');
ok($xpkg_xrout_user, 'found attribute xpgk-xrouting-username');
is($xpkg_xrout_user->{id}, 251, 'xpgk-xrouting-username has id 1');
is($xpkg_xrout_user->{type}, 'string', 'xpgk-xrouting-username has type string');

my $tmp_file = File::Temp->new( UNLINK => 0, SUFFIX => '.dict' );
$tmp_file->autoflush(1);
$tmp_file->unlink_on_destroy(1);

foreach my $d ('radius/rfc4372', 'radius/mera') {
    $tmp_file->say( sprintf('$INCLUDE %s/../%s', $Bin, $d) );
}

my $multi_dict_from_single_tmp_file = Data::Radius::Dictionary->load_file(
    $tmp_file->filename
);

cmp_deeply(
    $multi_dict,
    $multi_dict_from_single_tmp_file,
      'RADIUS dict loaded from multiple files simultaneously is equal to'
    . ' single-file dict with same dicts $INCLUDEd',
);
