use Test::More;

use Business::BR::CEP qw(test_cep tipo_cep regiao_cep);

my $base = int rand 100_000;
my $suffix = int rand 1_000;
my $valid_cep = sprintf '%05d-%03d', $base, $suffix;
my $invalid_cep = $base . $suffix;

ok  test_cep( $valid_cep   ) => "$valid_cep is a valid CEP";
ok !test_cep( $invalid_cep ) => "$invalid_cep is NOT a valid CEP";

is tipo_cep( '21094-000' ), 'logradouro', 'logradouro type (lower limit)';
is tipo_cep( '21094-030' ), 'logradouro', 'logradouro type';
is tipo_cep( '21094-899' ), 'logradouro', 'logradouro type (upper limit)';

is tipo_cep( '21094-900' ), 'especial', 'especial type (lower limit)';
is tipo_cep( '21094-954' ), 'especial', 'especial type';
is tipo_cep( '21094-959' ), 'especial', 'especial type (upper limit)';

is tipo_cep( '21094-960' ), 'promocionais', 'promocionais type (lower limit)';
is tipo_cep( '21094-964' ), 'promocionais', 'promocionais type';
is tipo_cep( '21094-969' ), 'promocionais', 'promocionais type (upper limit)';

is tipo_cep( '21094-970' ), 'correios', 'correios type (lower limit)';
is tipo_cep( '21094-984' ), 'correios', 'correios type';
is tipo_cep( '21094-989' ), 'correios', 'correios type (upper limit)';

is tipo_cep( '21094-990' ), 'caixapostal', 'caixapostal type (lower limit)';
is tipo_cep( '21094-994' ), 'caixapostal', 'caixapostal type';
is tipo_cep( '21094-998' ), 'caixapostal', 'caixapostal type (upper limit)';

is tipo_cep( '21094-999' ), 'correios', 'correios type (extra)';


my ( $estado ) =  regiao_cep( '10349-333' );
is $estado, 'sp', 'regiao_cep works for single state';

my @estados = regiao_cep( '22091-932' );
is_deeply \@estados, [ 'rj', 'es' ], 'regiao_cep works for multiple states';

done_testing;
