#!/usr/bin/env perl

use Test::More tests => 24;
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


# Test-Data from
# https://github.com/sporkmonger/magicsig/blob/master/spec/magicsig_spec.rb
is(b64url_encode('2`?33>]', 0), 'MmA_MzM-XQ', 'MagicSig encode 1');
is(b64url_encode(' ', 0), 'IA', 'MagicSig encode 2');
is(b64url_encode("  ", 0), 'ICA', 'MagicSig encode 3');

is(b64url_decode('MmA_MzM-XQ'), '2`?33>]', 'MagicSig decode 1');
is(b64url_decode('ICA'), '  ', 'MagicSig decode 2');

is(b64url_decode(" MmA_M\n\t zM-XQ "), '2`?33>]', 'MagicSig decode 3');
is(b64url_decode(" IC\nA\t "), '  ', 'MagicSig decode 4');

is(*{"${module}::_os2ip"}->(b64url_decode('AQAB')), 65537, 'MagicSig os2ip 1');
is(*{"${module}::_os2ip"}->(
  b64url_decode('mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKU' .
		  'EK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww')
    ),
   '803128378907519656502289154656359136834494406215410' .
     '050964539889229343337085989194330643990745488374753' .
       '4493461257620351548796452092307094036643522661681091',
  'MagicSig os2ip 2'
);

is(*{"${module}::_os2ip"}->(
  b64url_decode('AJlYGPETelEQU7LZ3b5lFD2-FGU3cL8JnXUihOc_47' .
		  'ylBCuspNbt66wvcjfJOhYpRo_StHnlD3toX-D4_uQph8M')
    ),
   '803128378907519656502289154656359136834494406215410' .
     '050964539889229343337085989194330643990745488374753' .
       '4493461257620351548796452092307094036643522661681091',
  'MagicSig os2ip 3'
);


is(b64url_encode(*{"${module}::_i2osp"}->(65537)),
   'AQAB',
   'MagicSig i2osp 1');

is(
  b64url_encode(
    *{"${module}::_i2osp"}->(
      '803128378907519656502289154656359136834494406215410' .
	'050964539889229343337085989194330643990745488374753' .
	  '4493461257620351548796452092307094036643522661681091'
	), 0),
    'mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKU' .
      'EK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww',
   'MagicSig i2osp 2');

is(
  b64url_encode(
    *{"${module}::_i2osp"}->(
      *{"${module}::_os2ip"}->(
	b64url_decode('AQAB'),
      )), 0), 'AQAB',
  'MagicSig os2ip(i2osp) 1');

my $encoded_data = 'mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKU' .
  'EK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww';

is(
  b64url_encode(
    *{"${module}::_i2osp"}->(
      *{"${module}::_os2ip"}->(
	b64url_decode($encoded_data),
      )), 0), $encoded_data,
  'MagicSig os2ip(i2osp())');

my $n = Math::BigInt->new(2)->bpow(1000);
my $test = 0;
foreach (1 .. 10) {
  $n->badd(1);
  if(*{"${module}::_os2ip"}->(
    b64url_decode(
      b64url_encode(
	*{"${module}::_i2osp"}->($n), 1))) eq $n) {
    $test++;
  };
};

is ($test, 10, 'MagicSig i2osp(os2ip()) 1');

$n = Math::BigInt->new(2)->bpow(1000);
$test = 0;
foreach (1 .. 10) {
  $n->badd(1);
  if(*{"${module}::_os2ip"}->(
    *{"${module}::_i2osp"}->($n)) eq $n) {
    $test++;
  };
};

is ($test, 10, 'MagicSig i2osp(os2ip()) 2');


# Without zeros
my $k = Crypt::MagicSignatures::Key->new(
  'RSA.mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKU' .
    'EK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww.AQAB');

is($k->n, '803128378907519656502289154656359136834494406215410' .
      '050964539889229343337085989194330643990745488374753' .
      '4493461257620351548796452092307094036643522661681091', 'MagicSig n');
is($k->e, '65537', 'MagicSig e');

is($k->size, 512, 'Correct key size');

# With zeros
$k = Crypt::MagicSignatures::Key->new(
  'RSA.AJlYGPETelEQU7LZ3b5lFD2-FGU3cL8JnXUihOc_47' .
    'ylBCuspNbt66wvcjfJOhYpRo_StHnlD3toX-D4_uQph8M.AQAB');

is($k->size, 512, 'Correct key size');

is($k->n, '803128378907519656502289154656359136834494406215410' .
      '050964539889229343337085989194330643990745488374753' .
      '4493461257620351548796452092307094036643522661681091', 'MagicSig n');
is($k->e, '65537', 'MagicSig e');

# Normally without padding
is($k->to_string, 'RSA.mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKU' .
     'EK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww==.AQAB', 'MagicSig to_string');
