
use Test::More tests => 4;
BEGIN { use_ok('Business::BR::CPF', 'parse_cpf') };

($base, $dv) = parse_cpf('000.111.222-00');
is($base, '000111222', "at list context: base ok");
is($dv, '00', "at list context: dv ok");

$hashref = parse_cpf('999.222.111-00'); 
is_deeply($hashref, { base => '999222111', dv => '00' }, "scalar context works ok");

# do I need tests for extended short ints?
# do I need tests for pruned CPF candidates?
# what about long inputs?

