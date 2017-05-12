#!/usr/bin/env perl

use Test::More;
use Math::BigInt try => 'GMP,Pari';
use strict;
use warnings;
no strict 'refs';

use lib '../lib';

our $module;
BEGIN {
    our $module = 'Crypt::MagicSignatures::Key';
    use_ok($module, qw/b64url_encode b64url_decode/);   # 1
};

my $test_msg = 'This is a small message test.';


# Check for broken Math::BigInt by
# https://salmon-protocol.googlecode.com/svn/trunk/
#   lib/python/magicsig_hjfreyer/magicsigalg_test.py
my $n = Math::BigInt->new(2)->bpow(2048)->badd(42);
my $test_n = Math::BigInt->new(<<'BIGN');
32317006071311007300714876688669951960444102669715484032130345427524655138867890893197201411522913463688717960921898019494119559150490921095088152386448283120630877367300996091750197750389652106796057638384067568276792218642619756161838094338476170470581645852036305042887575891541065808607552399123930385521914333389668342420684974786564569494856176035326322058077805659331026192708460314150258592864177116725943603718461857357598351152301645904403697613233287231227125684710820209725157101726931323469678542580656697935045997268352998638215525166389437335543602135433229604645318478604952148193555853611059596230698
BIGN

ok($n->is_even($test_n), 'Math::BigInt');

my $b64_n = b64url_encode($n);
is(b64url_decode($b64_n), $n, 'b64url for big numbers');

# https://salmon-protocol.googlecode.com/
#   svn/trunk/lib/python/magicsig_hjfreyer/magicsig_example.py
my $test_key =
    'RSA.'.
    'mVgY8RN6URBTstndvmUUPb4UZTdwvw'.
    'mddSKE5z_jvKUEK6yk1u3rrC9yN8k6'.
    'FilGj9K0eeUPe2hf4Pj-5CmHww==.'.
    'AQAB.'.
    'Lgy_yL3hsLBngkFdDw1Jy9TmSRMiH6'.
    'yihYetQ8jy-jZXdsZXd8V5ub3kuBHH'.
    'k4M39i3TduIkcrjcsiWQb77D8Q==';

my $mkey = Crypt::MagicSignatures::Key->new($test_key);

ok($mkey, 'Magic-Key parsed');                     # 8

my $n_test =
  '80312837890751965650228915'.
  '46563591368344944062154100'.
  '50964539889229343337085989'.
  '19433064399074548837475344'.
  '93461257620351548796452092'.
  '307094036643522661681091';

my $d_test =
  '24118237980497878083558223'.
  '37426462024816467706597110'.
  '82488260212703094530069868'.
  '86574485408953662105923805'.
  '76050280953899102635751538'.
  '748696981555132000814065';

my $e_test = 65537;
my $emLen_test = 64;

is($mkey->n, $n_test, 'M-Key modulus correct');           # 9
is($mkey->d, $d_test, 'M-Key private exponent');          # 10
is($mkey->e, $e_test,   'M-Key exponent');                # 11
is($mkey->_emLen, $emLen_test,  'M-Key length correct');  # 12

my $test_public_key = $test_key;
$test_public_key =~ s{\.[^\.]+$}{};

is($mkey->to_string, $test_public_key, 'M-Key string correct'); # 13

my $num = '3799324609234979';
my $b64 = *{"${module}::_hex_to_b64url"}->($num);
is($b64, 'DX93MbhIIw==', '_hex_to_b64url');

my $num2 = *{"${module}::_b64url_to_hex"}->($b64);
is($num, $num2, '_b64url_to_hex');

my $b642 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'.
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'.
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'.
  'AAAAAAAAAAAAAAH_____________ADAxMA0GCWC'.
  'GSAFlAwQCAQUABCDVV5xG38x_GCBwE-ZbROTLTi'.
  'wimPSsRXuo-CdD8x6TCw==';
$num2 = *{"${module}::_b64url_to_hex"}->($b642);
my $b643 = *{"${module}::_hex_to_b64url"}->($num2);
my $num3 = *{"${module}::_b64url_to_hex"}->($b643);

is($num2, $num3, '_hex_to_b64url');

$test_msg =    'test string';

my $emsa = *{"${module}::_emsa_encode"}->($test_msg,
					  $mkey->_emLen,
					  'sha-256');

is (b64url_encode($emsa),
    'AAH_____________AD'.
    'AxMA0GCWCGSAFlAwQC'.
    'AQUABCDVV5xG38x_GC'.
    'BwE-ZbROTLTiwimPSs'.
    'RXuo-CdD8x6TCw==',
    'EMSA encode');

my $EM = *{"${module}::_os2ip"}->($emsa);

is($EM, '40917382598701'.
     '77337516485429975'.
     '66029938148046617'.
     '39298138975140811'.
     '97400100914340291'.
     '73326755103708333'.
     '01650201932192494'.
     '82769682303342846'.
     '01470436616606475',
   'EMSA encode os2ip');

my $s  = *{"${module}::_rsasp1"}->($mkey, $EM);

is ($s, '80055379592861'.
      '9970997680410400'.
      '5668460713624089'.
      '8187708914240169'.
      '4631449865271349'.
      '1469283703805848'.
      '8599193791587766'.
      '9585376226384018'.
      '9524960279363800'.
      '402058130813', 'rsasp1 sign');

is(length($mkey->n), 154, 'n length');

my $string = *{"${module}::_i2osp"}->($s, length($mkey->n));

# i2osp error - Integer is to short at t/04-magicsig-hjfreyer.t line 131.
#   Failed test '_i2osp for Win32 test'
#   at t/04-magicsig-hjfreyer.t line 133.
#          got: undef
#     expected: '154'
#   Failed test 'SIG i2osp b64url_encode'
#   at t/04-magicsig-hjfreyer.t line 137.
#          got: ''
#     expected: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'.
#               'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'.
#               'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'.
#               'AAAAAAAAAAAAmNpBIpTUOESnuQMlS8aWZ4hw'.
#               'dSwWnMstrn0F3L9GHDXa238fN3Bx3Rl0yvVE'.
#               'SM_eZuocLsp9ubUrYDu83821fQ=='

is(length($string), length($mkey->n), '_i2osp for Win32 test');

my $S = b64url_encode($string);

is ($S, 'AAAAAAAAAAAAAAAAAAAAAAAAA'.
        'AAAAAAAAAAAAAAAAAAAAAAAAA'.
	'AAAAAAAAAAAAAAAAAAAAAAAAA'.
	'AAAAAAAAAAAAAAAAAAAAAAAAA'.
	'AAAAAAAAAAAAAAAAAAAA'.
	'mNpBIpTUOESnuQMlS8aWZ4hwd'.
	'SwWnMstrn0F3L9GHDXa238fN3'.
	'Bx3Rl0yvVESM_eZuocLsp9ubU'.
	'rYDu83821fQ==',
    'SIG i2osp b64url_encode');

done_testing;
