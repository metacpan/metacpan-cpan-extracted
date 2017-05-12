use strict;
use warnings;

use Crypt::ScryptKDF;
use Test::More;

ok(!Crypt::ScryptKDF::_slow_eq(undef,''), 'undef vs. empty');
ok(!Crypt::ScryptKDF::_slow_eq(undef,'a'), 'undef vs. non-empty');
ok(!Crypt::ScryptKDF::_slow_eq('',undef), 'empty vs. undef');
ok(!Crypt::ScryptKDF::_slow_eq('a',undef), 'non-empty vs. undef');
ok(!Crypt::ScryptKDF::_slow_eq(undef,undef), 'undef vs. undef');
ok( Crypt::ScryptKDF::_slow_eq('',''), 'empty vs. empty');
ok(!Crypt::ScryptKDF::_slow_eq('a',''), 'non-empty vs. empty');
ok(!Crypt::ScryptKDF::_slow_eq('','a'), 'empty vs. non-empty');
ok( Crypt::ScryptKDF::_slow_eq('a','a'), 'one char');
ok( Crypt::ScryptKDF::_slow_eq('alsdfjasldfkh','alsdfjasldfkh'), 'more chars');
ok(!Crypt::ScryptKDF::_slow_eq('alsdfjasldfkh','alsdfjasldfk'),  'long vs. short');
ok(!Crypt::ScryptKDF::_slow_eq('alsdfjasldfk', 'alsdfjasldfkh'), 'short vs. long');

ok( Crypt::ScryptKDF::_slow_eq(pack("H*", "00"),pack("H*", "00")), 'binary zero');
ok( Crypt::ScryptKDF::_slow_eq(pack("H*", "001122334455667788990011"),pack("H*", "001122334455667788990011")), 'binary');
ok(!Crypt::ScryptKDF::_slow_eq(pack("H*", "001122334455667788990011"),pack("H*", "0011223344556677889900")), 'binary long vs. short');
ok(!Crypt::ScryptKDF::_slow_eq(pack("H*", "0011223344556677889900"),  pack("H*", "001122334455667788990011")), 'binary short vs. long');
ok(!Crypt::ScryptKDF::_slow_eq(pack("H*", "0011223344556677889900"),  pack("H*", "00112233445566778899")), 'binary long vs. short');
ok(!Crypt::ScryptKDF::_slow_eq(pack("H*", "00112233445566778899"),    pack("H*", "0011223344556677889900")), 'binary short vs. long');

done_testing;