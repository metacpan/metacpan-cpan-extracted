use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':sign';

# randomly generated. DO NOT USE.
# bad_* have first or last nybble changed
my $pk = pack('H*', '4b28511d5a5851282d331fa86b51d665de838d1ce5f73fcd948a191af8627df5');
my $bad_pk = pack('H*', '0b28511d5a5851282d331fa86b51d665de838d1ce5f73fcd948a191af8627df5');
my $sk = pack('H*', 'f61ea5a0eb8e64c7cba879852a0c21c408761fbc9d0f904ce50a5cf765ff0ade4b28511d5a5851282d331fa86b51d665de838d1ce5f73fcd948a191af8627df5');
my $bad_sk = pack('H*', 'f61ea5a0eb8e64c7cba879852a0c21c408761fbc9d0f904ce50a5cf765ff0ade4b28511d5a5851282d331fa86b51d665de838d1ce5f73fcd948a191af8627dff');

my $str = "oh, well hello there!\x01\x02\x03";

my $signed = sign($str, $sk);
ok($signed, "sign generated signed text");
is(length($signed), length($str) + sign_BYTES, "sign generated correct length output");

my $opened = sign_open($signed, $pk);
ok($opened, "sign_open generated output");
is($opened, $str, "sign_open returned correct signed data");

my $bad_opened = sign_open($signed, $bad_pk);
ok(!defined($bad_opened), "sign_open fails with bad pk");
my $bad_signed = sign($str, $bad_sk);
$bad_opened = sign_open($bad_signed, $pk);
ok(!defined($bad_opened), "sign_open fails on data signed with bad sk");

done_testing();
