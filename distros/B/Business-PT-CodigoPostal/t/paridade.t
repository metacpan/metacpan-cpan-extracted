#!perl
# Paridade com Business::ES::CodigoPostal.
#
# Os dois módulos são irmãos e quem usa um espera encontrar o outro parecido.
# Não são iguais nem devem ser -- Espanha tem comunidade autónoma e Portugal
# não, e cada um chama às coisas pelo seu nome (provincia/distrito,
# municipios/localidades) -- mas o contrato tem de coincidir: os mesmos
# métodos, o mesmo comportamento perante o disparate, e texto descodificado
# em ambos.
#
# Salta-se se o módulo espanhol não estiver instalado: é uma verificação de
# coerência entre distribuições, não uma dependência.

use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

use_ok('Business::PT::CodigoPostal');

SKIP: {
    eval { require Business::ES::CodigoPostal; 1 }
        or skip 'Business::ES::CodigoPostal não instalado', 4;

    my $ES = 'Business::ES::CodigoPostal';
    my $PT = 'Business::PT::CodigoPostal';

    subtest 'os mesmos métodos de objecto' => sub {
        for my $m (qw(new set valid codigo error strict region insular)) {
            ok($ES->can($m), "ES->can($m)");
            ok($PT->can($m), "PT->can($m)");
        }
        ok($ES->can('iso_3166_2'), 'ES tem iso_3166_2');
        ok($PT->can('iso_3166_2'), 'PT também -- faz falta para mapear num ERP');
    };

    subtest 'as mesmas funções' => sub {
        ok($ES->can('validate_cp') && $PT->can('validate_cp'), 'validate_cp');
        ok($ES->can('asignado')   && $PT->can('asignado'),     'asignado');
        ok($ES->can('provincias'), 'ES lista as províncias');
        ok($PT->can('distritos'),  'PT lista os distritos');
        ok($ES->can('municipios'), 'ES: municipios');
        ok($PT->can('localidades'),'PT: localidades (cada um no seu idioma)');
    };

    subtest 'o mesmo comportamento perante o disparate' => sub {
        for my $mau (undef, '', 'abc', '!!!') {
            my $e = $ES->can('validate_cp')->($mau);
            my $p = $PT->can('validate_cp')->($mau);
            my $q = defined $mau ? "'$mau'" : 'undef';
            is($e->{valid}, 0, "ES rejeita $q");
            is($p->{valid}, 0, "PT rejeita $q");
            ok(length($e->{error}), "ES traz erro para $q");
            ok(length($p->{error}), "PT traz erro para $q");
            ok(!exists $e->{region}, "ES não traz region para $q");
            ok(!exists $p->{region}, "PT não traz region para $q");
        }

        # nenhum dos dois deve aceitar o formato do outro
        is($ES->can('validate_cp')->('1000-001')->{valid}, 0, 'ES rejeita o formato PT');
        is($PT->can('validate_cp')->('28001')->{valid},    0, 'PT rejeita o formato ES');
    };

    # Foi o erro que deixou uma linha 'A CoruA a' na base de dados: os módulos
    # devolviam bytes e a ligação esperava caracteres.
    subtest 'ambos devolvem caracteres, não bytes' => sub {
        my $e = $ES->can('validate_cp')->('01001');
        my $p = $PT->can('validate_cp')->('5300-001');
        ok(utf8::is_utf8($e->{provincia}), 'ES: província descodificada');
        ok(utf8::is_utf8($p->{distrito}),  'PT: distrito descodificado');
        is(length($e->{provincia}), 5, 'Álava são 5 caracteres');
        is(length($p->{distrito}),  8, 'Bragança são 8 caracteres');
        ok(utf8::is_utf8($e->{error} // $ES->can('validate_cp')->('abc')->{error}), 'ES: erro descodificado');
        ok(utf8::is_utf8($PT->can('validate_cp')->('abc')->{error}), 'PT: erro descodificado');
    };
}

done_testing;
