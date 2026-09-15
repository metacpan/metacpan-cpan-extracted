#!perl
# Validação de códigos postais portugueses: formato, distrito e região.

use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

use_ok('Business::PT::CodigoPostal');
Business::PT::CodigoPostal->import(qw(validate_cp localidades asignado));

subtest 'códigos válidos' => sub {
    my %casos = (
        '1000-001' => 'Lisboa',
        '4000-001' => 'Porto',
        '3000-001' => 'Coimbra',
        '8000-001' => 'Faro',
        '5300-001' => 'Bragança',
        '2900-001' => 'Setúbal',
        '7000-001' => 'Évora',
        '4900-001' => 'Viana do Castelo',
        '9000-001' => 'Madeira',
        '9500-001' => 'Açores',
    );
    for my $cp (sort keys %casos) {
        my $r = validate_cp($cp);
        is($r->{valid}, 1, "$cp válido");
        is($r->{distrito}, $casos{$cp}, "$cp -> $casos{$cp}");
        is($r->{codigo}, $cp, "$cp devolve o código");
    }
};

subtest 'região: o arquipélago paga porte à parte' => sub {
    is(validate_cp('1000-001')->{region}, 'Continente', 'Lisboa');
    is(validate_cp('8000-001')->{region}, 'Continente', 'Faro');
    is(validate_cp('9000-001')->{region}, 'Madeira',    'Madeira');
    is(validate_cp('9500-001')->{region}, 'Açores',     'Açores');
};

# Em Espanha os dois primeiros dígitos SÃO o número da província. Em Portugal
# não: o prefixo de dois dígitos é ambíguo em 25 de 79 casos, e com quatro
# dígitos restam 13 prefixos que ficam entre dois distritos. Esses resolvem-se
# com o código completo.
subtest 'prefixos que ficam entre dois distritos' => sub {
    is(validate_cp('2100-049')->{distrito}, 'Santarém', '2100-049 é Santarém');
    is(validate_cp('4905-500')->{distrito}, 'Viana do Castelo', '4905-500');
    is(validate_cp('5040-999')->{distrito}, 'Vila Real', '5040-999');

    # o mesmo prefixo, distritos diferentes conforme o sufixo
    my %d;
    for my $suf ('001' .. '999') {
        my $r = validate_cp("4905-$suf");
        $d{ $r->{distrito} }++ if $r->{valid};
    }
    ok(scalar(keys %d) > 1, '4905 reparte-se por mais de um distrito');
};

subtest 'códigos inválidos' => sub {
    is(validate_cp('28001')->{valid},     0, 'código espanhol');
    is(validate_cp('1000001')->{valid},   0, 'sem hífen em modo estrito');
    is(validate_cp('1000-0011')->{valid}, 0, 'sufixo comprido demais');
    is(validate_cp('abc')->{valid},       0, 'não numérico');
    is(validate_cp('')->{valid},          0, 'vazio');
    is(validate_cp(undef)->{valid},       0, 'undef sem avisos');
    is(validate_cp('9999-999')->{valid},  0, 'prefixo inexistente');

    ok(length validate_cp('abc')->{error}, 'traz mensagem de erro');
    ok(!exists validate_cp('abc')->{distrito}, 'sem distrito quando falha');
};

subtest 'normalização com strict a 0' => sub {
    is(validate_cp('1000001', { strict => 0 })->{distrito}, 'Lisboa', 'sem hífen');
    is(validate_cp('1000 001', { strict => 0 })->{distrito}, 'Lisboa', 'com espaço');
    is(validate_cp(' 1000-001 ', { strict => 0 })->{distrito}, 'Lisboa', 'com espaços à volta');
    is(validate_cp('1000001', { strict => 0 })->{codigo}, '1000-001', 'repõe o hífen');
    is(validate_cp('100001', { strict => 0 })->{valid}, 0, 'seis dígitos não chegam');
};

# Sem 'use utf8' os literais sairiam como bytes UTF-8 e quem os guardasse numa
# base de dados com a ligação em UTF-8 acabaria com dupla codificação.
subtest 'as saídas de texto são caracteres' => sub {
    my $r = validate_cp('5300-001');
    ok(utf8::is_utf8($r->{distrito}), 'o distrito vem descodificado');
    is(length($r->{distrito}), 8, 'Bragança são 8 caracteres, não 9 bytes');
    is(validate_cp('7000-001')->{distrito}, 'Évora', 'Évora');
    is(validate_cp('9500-001')->{distrito}, 'Açores', 'Açores, não Azores');
    ok(utf8::is_utf8(validate_cp('abc')->{error}), 'a mensagem de erro também');
};

done_testing;
