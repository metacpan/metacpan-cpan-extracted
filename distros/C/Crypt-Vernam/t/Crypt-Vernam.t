# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-Vernam.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Crypt::Vernam') };

#########################

#--------------- Private methods ----------------#

# _get_key_mod26
ok(length(Crypt::Vernam::_get_key_mod26(12)) == 12,
        'length(Crypt::Vernam::_get_key_mod26(12)) == 12');

my $key1 = Crypt::Vernam::_get_key_mod26(5);
my $key2 = Crypt::Vernam::_get_key_mod26(5);
ok($key1 ne $key2, "$key1 and $key2 are identical");

# _shift_char
my $i = Crypt::Vernam::_shift_char('j', 't', 'encrypt');
my $c = Crypt::Vernam::_shift_char($i,  't', 'decrypt');
ok($i eq 'c', 
        "Crypt::Vernam::_shift_char('j', 't', 'encrypt') must return c");
ok($c eq 'j', 
        "Crypt::Vernam::_shift_char('c', 't', 'decrypt') must return j");

my $a = Crypt::Vernam::_shift_char('a', 'a', 'encrypt');
ok($a eq 'a', 
        "Crypt::Vernam::_shift_char('a', 'a', 'encrypt') must return a");

my $p = Crypt::Vernam::_shift_char(':', 't', 'encrypt');
ok($p eq ':', 
        "Crypt::Vernam::_shift_char(':', 't', 'encrypt') must return :");

# _vernam_mod26
my $plaintext  = 'plain';
my $key        = $key1;
my $action     = 'encrypt';

my $ciphertext = Crypt::Vernam::_vernam_mod26($plaintext, $key, $action);

$action = 'decrypt';
$plaintext  = Crypt::Vernam::_vernam_mod26($ciphertext, $key, $action);
ok($plaintext eq 'plain', 
        "Crypt::Vernam::_vernam_mod26($ciphertext, $key, $action) "
      . "must return plain");

# _get_key_xor
ok(length(Crypt::Vernam::_get_key_xor(12)) == 12,
        'length(Crypt::Vernam::_get_key_xor(12)) == 12');

$key1 = Crypt::Vernam::_get_key_xor(5);
$key2 = Crypt::Vernam::_get_key_xor(5);
ok($key1 ne $key2, "$key1 and $key2 are identical");

# _vernam_xor
$plaintext  = 'plain';
$key        = $key1;
$action     = 'encrypt';

$ciphertext = Crypt::Vernam::_vernam_xor($plaintext, $key);

$action = 'decrypt';
$plaintext  = Crypt::Vernam::_vernam_xor($ciphertext, $key);
ok($plaintext eq 'plain', 
        "Crypt::Vernam::_vernam_xor($ciphertext, $key) "
      . "must return plain");

# _check_args

#---------------- Public methods ----------------#
($ciphertext, $key) = vernam_encrypt('mod26', "plain\n");
$plaintext = vernam_decrypt('mod26', $ciphertext, $key);
ok ($plaintext eq "plain\n", 
        "vernam_decrypt('mod26', $ciphertext, $key) "
      . "must return plain\\n");

($ciphertext, $key) = vernam_encrypt('xor', $plaintext);
$plaintext = vernam_decrypt('xor', $ciphertext, $key);
ok ($plaintext eq "plain\n", 
        "vernam_decrypt('xor', $ciphertext, $key) "
      . "must return plain\\n");

