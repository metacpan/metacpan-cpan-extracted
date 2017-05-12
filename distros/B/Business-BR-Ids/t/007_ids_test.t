
use Test::More tests => 7;
BEGIN { use_ok('Business::BR::Ids') };

ok(test_id('cpf', '56451416010'), "works for good CPF");
ok(!test_id('cpf', '231.002.999-00'), "works for bad CPF");

ok(test_id('cnpj', '90.117.749/7654-80'), "works for good CNPJ");
ok(!test_id('cnpj', '88.222.111/0001-10'), "works for bad CNPJ");

ok(test_id('ie', 'pr', '123.45678-50'), "works for good IE");

ok(test_id('pis', '121.51144.13-7'), "works for good PIS");