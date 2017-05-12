
use Test::More tests => 5;
BEGIN { use_ok('Business::BR::CPF', 'canon_cpf') };

is(canon_cpf(99), '00000000099', 'amenable to ints');
is(canon_cpf('999.999.999-99'), '99999999999', 'discards formatting');

is(canon_cpf(111_222_333_444), '111222333444', 'too long ints pass through');
is(canon_cpf('111_222_333_444'), '111222333444', 'as well as other too long inputs');

