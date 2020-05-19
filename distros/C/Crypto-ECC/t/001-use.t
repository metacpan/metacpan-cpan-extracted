use strict;
use warnings;
use Test::More;

use_ok 'Crypto::ECC';

use Crypto::ECC;

is $CurveFp ,   'Crypto::ECC::CurveFp';
is $Point ,     'Crypto::ECC::Point';
is $PublicKey , 'Crypto::ECC::PublicKey';
is $Signature , 'Crypto::ECC::Signature';

done_testing;
