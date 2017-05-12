use strict;
use warnings;

use Test::More qw(no_plan);
use lib qw (lib);

use_ok('Crypt::Smithy');

my $s = Crypt::Smithy->new();
isa_ok($s, q{Crypt::Smithy}, q{isa_ok Crypt::Smithy});

ok($s->_is_uppercase('A'), 'A is upper');
ok($s->_is_uppercase('Z'), 'Z is upper');
ok($s->_is_uppercase('J'), 'J is upper');
ok($s->_is_uppercase('K'), 'K is upper');

ok(!$s->_is_uppercase('a'), 'a is lower');
ok(!$s->_is_uppercase('z'), 'z is lower');
ok(!$s->_is_uppercase('j'), 'j is lower');
ok(!$s->_is_uppercase('k'), 'k is lower');

cmp_ok($s->_get_base('A'), q{==}, 65, 'A-Z -> ord(A) == 65');
cmp_ok($s->_get_base('C'), q{==}, 65, 'A-Z -> ord(A) == 65');
cmp_ok($s->_get_base('F'), q{==}, 65, 'A-Z -> ord(A) == 65');
cmp_ok($s->_get_base('Z'), q{==}, 65, 'A-Z -> ord(A) == 65');
cmp_ok($s->_get_base('a'), q{==}, 97, 'a-z -> ord(a) == 97');
cmp_ok($s->_get_base('c'), q{==}, 97, 'a-z -> ord(a) == 97');
cmp_ok($s->_get_base('f'), q{==}, 97, 'a-z -> ord(a) == 97');
cmp_ok($s->_get_base('z'), q{==}, 97, 'a-z -> ord(a) == 97');

is($s->_decrypt_char(0, 'j'), 'j', 'decrypt 0,j -> j');
is($s->_decrypt_char(1, 'a'), 'a', 'decrypt 1,a -> a');
is($s->_decrypt_char(2, 'e'), 'c', 'decrypt 2,e -> c');
is($s->_decrypt_char(3, 'i'), 'k', 'decrypt 3,i -> k');

is($s->_decrypt_char(0, 'J'), 'J', 'decrypt 0,J -> J');
is($s->_decrypt_char(1, 'A'), 'A', 'decrypt 1,A -> A');
is($s->_decrypt_char(2, 'E'), 'C', 'decrypt 2,E -> C');
is($s->_decrypt_char(3, 'I'), 'K', 'decrypt 3,I -> K');

is($s->_encrypt_char(0, 'j'), 'j', 'encrypt 0,j -> j');
is($s->_encrypt_char(1, 'a'), 'a', 'encrypt 1,a -> a');
is($s->_encrypt_char(2, 'c'), 'e', 'encrypt 2,c -> e');
is($s->_encrypt_char(3, 'k'), 'i', 'encrypt 3,k -> i');

is($s->_encrypt_char(0, 'J'), 'J', 'encrypt 0,J -> J');
is($s->_encrypt_char(1, 'A'), 'A', 'encrypt 1,A -> A');
is($s->_encrypt_char(2, 'C'), 'E', 'encrypt 2,C -> E');
is($s->_encrypt_char(3, 'K'), 'I', 'encrypt 3,K -> I');

is($s->decrypt_string('jaeiextostgpsacgreamqwfkadpmqzv'), 
	'jackiefisterwhoareyoudreadnough', 
	'decrypt_string jaei.. -> jack..');

is($s->decrypt_string('JAEIEXTOSTGPSACGREAMQWFKADPMQZV'), 
	'JACKIEFISTERWHOAREYOUDREADNOUGH', 
	'decrypt_string JAEI.. -> JACK..');

is($s->encrypt_string('jackiefisterwhoareyoudreadnough'),
	'jaeiextostgpsacgreamqwfkadpmqzv',
	 'encrypt_string jack.. -> jaei..');

is($s->encrypt_string('JACKIEFISTERWHOAREYOUDREADNOUGH'),
	'JAEIEXTOSTGPSACGREAMQWFKADPMQZV',
	 'encrypt_string JACK.. -> JAEI..');


__END__


