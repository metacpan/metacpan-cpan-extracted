#!perl
# Localidades por codigo postal (0.03) y el contrato de encoding del modulo.

use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

use_ok('Business::ES::CodigoPostal');
Business::ES::CodigoPostal->import(qw(validate_cp municipios asignado));

subtest 'municipios: funcional' => sub {
    is_deeply([municipios('28017')], ['Madrid'],          'Madrid');
    is_deeply([municipios('01001')], ['Vitoria-Gasteiz'], 'Vitoria-Gasteiz');
    is_deeply([municipios('19139')], ['Ciudad Valdeluz'], 'Valdeluz, urbanizacion reciente');
    is_deeply([municipios('24402')], ['Ponferrada'],      'Ponferrada, idem');

    my @m = municipios('07813');
    ok(scalar @m > 1, 'un CP puede tener varias localidades');
    is_deeply([sort @m], [sort @m], 'vienen ordenadas');

    is_deeply([municipios('99999')], [], 'fuera de rango: lista vacia');
    is_deeply([municipios('abc')],   [], 'no numerico: lista vacia');
    is_deeply([municipios('')],      [], 'vacio: lista vacia');
    is_deeply([municipios(undef)],   [], 'undef sin warnings');
};

# El motivo de existir de asignado(): valid() solo mira el rango 01000-52999,
# asi que da por bueno cualquier numero con prefijo de provincia real. 28107
# tiene prefijo 28 y no existe -- Alcobendas es 28100/28108/28109. Una
# transposicion de digitos dentro de la misma provincia no se ve de otra forma,
# y es un error corriente en direcciones tecleadas a mano.
subtest 'asignado: distingue el CP inexistente dentro de rango' => sub {
    my $r = validate_cp('28107');
    is($r->{valid},     1,        '28107 pasa la validacion por rango');
    is($r->{provincia}, 'Madrid', 'y resuelve provincia Madrid');
    is(asignado('28107'), 0,      'pero NO esta asignado a ninguna localidad');

    is(asignado('28017'), 1, '28017 si (Madrid)');
    is(asignado('28100'), 1, 'Alcobendas real');
    is(asignado('28108'), 1, 'Alcobendas real');
    is(asignado('99999'), 0, 'fuera de rango');
    is(asignado(''),      0, 'vacio');
    is(asignado(undef),   0, 'undef sin warnings');
};

subtest 'OO' => sub {
    my $o = Business::ES::CodigoPostal->new(codigo => '28017');
    is_deeply([$o->municipios], ['Madrid'], 'metodo municipios');
    is($o->asignado, 1, 'metodo asignado');

    $o->set('28107');
    is($o->valid,    1, 'valid sigue mirando solo el rango');
    is($o->asignado, 0, 'asignado ve que no existe');
};

# Contrato de encoding desde 0.03: TODAS las salidas de texto son caracteres.
# Antes provincia/ca/error salian como bytes UTF-8 crudos, y guardarlos en una
# base de datos con la conexion en UTF-8 producia doble codificacion.
subtest 'encoding: todo son caracteres, no bytes' => sub {
    my $r = validate_cp('01001');
    is($r->{provincia}, 'Álava', 'provincia con acento');
    is(length($r->{provincia}), 5, 'Álava son 5 caracteres, no 6 bytes');
    is($r->{ca}, 'País Vasco', 'comunidad autonoma');
    is(length($r->{ca}), 10, 'País Vasco son 10 caracteres');

    my $e = validate_cp('99999');
    is($e->{error}, 'Código postal no asignado', 'el error tambien');

    my ($m) = municipios('15001');
    is($m, 'A Coruña', 'la localidad');
    is(length($m), 8, 'A Coruña son 8 caracteres');

    my $p = validate_cp('15001');
    is($p->{provincia}, 'La Coruña', 'provincia de la misma');
    is(length($p->{provincia}), 9, 'y son 9 caracteres');
};

# Los datos pesan ~650 KB. Quien solo valida un CP o pide la provincia -- que
# es el uso mayoritario -- no debe pagarlos.
subtest 'los datos no se cargan si no se piden' => sub {
    my $key = 'Business/ES/CodigoPostal/Municipios.pm';
    my $out = `$^X -Ilib -e 'use Business::ES::CodigoPostal qw(validate_cp); validate_cp("08001"); print \$INC{"$key"} ? "SI" : "NO"' 2>&1`;
    is($out, 'NO', 'validar un CP no carga la tabla de localidades');

    $out = `$^X -Ilib -e 'use Business::ES::CodigoPostal qw(municipios); municipios("08001"); print \$INC{"$key"} ? "SI" : "NO"' 2>&1`;
    is($out, 'SI', 'pedir localidades si la carga');
};

done_testing;
