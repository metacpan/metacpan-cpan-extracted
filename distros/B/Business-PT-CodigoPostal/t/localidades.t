#!perl
# Localidades por código postal e carga preguiçosa dos dados.

use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

use_ok('Business::PT::CodigoPostal');
Business::PT::CodigoPostal->import(qw(validate_cp localidades asignado));

subtest 'localidades' => sub {
    my @l = localidades('2100-049');
    ok(scalar @l, '2100-049 tem localidade');
    is_deeply([localidades('9999-999')], [], 'prefixo inexistente: lista vazia');
    is_deeply([localidades('abc')],      [], 'não numérico');
    is_deeply([localidades('')],         [], 'vazio');
    is_deeply([localidades(undef)],      [], 'undef sem avisos');
    is_deeply([localidades('2100049')],  [localidades('2100-049')], 'aceita sem hífen');
};

# asignado é mais estreito do que valid: um código pode ter prefixo real e um
# sufixo que nunca foi atribuído.
subtest 'asignado' => sub {
    is(asignado('1000-001'), 1, 'código atribuído');
    is(asignado('9999-999'), 0, 'prefixo inexistente');
    is(asignado(''),         0, 'vazio');
    is(asignado(undef),      0, 'undef sem avisos');
};

subtest 'interface OO' => sub {
    my $cp = Business::PT::CodigoPostal->new(codigo => '9000-001');
    is($cp->valid,    1,         'válido');
    is($cp->distrito, 'Madeira', 'distrito');
    is($cp->region,   'Madeira', 'região');
    is($cp->insular,  1,         'insular');

    is($cp->set('1000-001'), 1, 'set devolve 1');
    is($cp->distrito, 'Lisboa', 'muda o distrito');
    is($cp->insular,  0,        'Lisboa não é insular');

    is($cp->set('nada'), 0, 'set devolve 0 com um código mau');
    is($cp->valid,    0,     'deixa de ser válido');
    is($cp->distrito, undef, 'limpa o distrito');
    ok(length $cp->error,    'guarda o erro');

    my $laxo = Business::PT::CodigoPostal->new({ codigo => '1000001', strict => 0 });
    is($laxo->distrito, 'Lisboa', 'normaliza no construtor');
};

# Os dados de localidades são vários MB. Quem só valida um código ou pergunta
# pelo distrito -- que é o uso corrente -- não os deve pagar.
subtest 'os dados de localidades não se carregam sem os pedir' => sub {
    my $key = 'Business/PT/CodigoPostal/Localidades.pm';
    my $out = `$^X -Ilib -e 'use Business::PT::CodigoPostal qw(validate_cp); validate_cp("1000-001"); print \$INC{"$key"} ? "SIM" : "NAO"' 2>&1`;
    is($out, 'NAO', 'validar não carrega as localidades');

    $out = `$^X -Ilib -e 'use Business::PT::CodigoPostal qw(localidades); localidades("1000-001"); print \$INC{"$key"} ? "SIM" : "NAO"' 2>&1`;
    is($out, 'SIM', 'pedir localidades carrega-as');
};

done_testing;
