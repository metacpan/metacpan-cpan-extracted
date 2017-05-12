
use Test::More tests => 3;
BEGIN { use_ok('Business::BR::CNPJ') };

ok(test_cnpj('90.117.749/7654-80'), "works for good ones");
ok(!test_cnpj('88.222.111/0001-10'), "works for bad ones");
