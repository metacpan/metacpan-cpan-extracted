
use Test::More;

my (@valid_cpf, @invalid_cpf);

BEGIN {

     @valid_cpf = (
        '56451416010',
	'78625488250',
	'390.533.447-05',
	'88427734336',
	'16595458977',
	'100.000.000-19', 
	' 263. 946. 533 - 3 0    ',
	'#333%444*2.3+2-23',
	'099.998.112-99',
	99_998_112_99,

     );
     @invalid_cpf = (
        '',
	'1',
	'888111999000',
	'231.002.999-00', 
        '271.222.111-11', 
        '999.221.222-00', 
	'00001100017',
	'999.444.333-55',
	'72000088855',
	'  779.288.222-55  ', 
	'#333%444*2a3s2z~23',
    );
}

BEGIN { plan tests => 1 + @valid_cpf + @invalid_cpf; }

BEGIN { use_ok('Business::BR::CPF') };

for (@valid_cpf) {
  ok(test_cpf($_), "'$_' is correct");
}

for (@invalid_cpf) {
  ok(!test_cpf($_), "'$_' is incorrect");
}

