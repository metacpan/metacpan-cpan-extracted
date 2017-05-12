
use Test::More tests => 5;
BEGIN { use_ok('Business::BR::CPF', 'format_cpf') };

is(format_cpf('00000000000'), '000.000.000-00', 'works ok');
is(format_cpf(6688822200), '066.888.222-00', 'works even for short ints');

is(format_cpf('000 000#000@00'), '000.000.000-00', 'argument is flattened before formatting');

is(format_cpf('000000000000'), '000.000.000-00', 'only 1st 11 digits matter for long inputs');


