use Test::Most;
die_on_fail;

use Crypt::Cryptoki::Constant qw(:all);

is(CKR_OK, 0, 'CKR_OK');

done_testing;
