use Test::Most;
die_on_fail;

use Crypt::Cryptoki::Raw;
use Crypt::Cryptoki::Constant qw(:all);

ok my $raw = Crypt::Cryptoki::Raw->new('/usr/lib64/softhsm/libsofthsm.so');
explain $raw;

is($raw->C_Initialize(), CKR_OK, 'C_Initialize');

my $info = {};
is $raw->C_GetInfo($info), CKR_OK, 'C_GetInfo';
diag explain $info;

done_testing;
