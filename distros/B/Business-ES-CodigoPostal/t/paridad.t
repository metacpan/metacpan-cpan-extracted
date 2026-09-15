#!perl
# Paridad con Business::PT::CodigoPostal.
#
# Los dos modulos son hermanos y quien usa uno espera encontrarse el otro
# parecido. No son iguales ni deben serlo -- Espana tiene comunidad autonoma y
# Portugal no, y cada uno llama a las cosas por su nombre (provincia/distrito,
# municipios/localidades) -- pero el contrato tiene que coincidir: los mismos
# metodos, el mismo comportamiento ante la entrada absurda, y texto
# decodificado en ambos.
#
# Se salta si el modulo portugues no esta instalado: es una comprobacion de
# coherencia entre distribuciones, no una dependencia.

use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

use_ok('Business::ES::CodigoPostal');

SKIP: {
    eval { require Business::PT::CodigoPostal; 1 }
        or skip 'Business::PT::CodigoPostal no instalado', 3;

    my $ES = 'Business::ES::CodigoPostal';
    my $PT = 'Business::PT::CodigoPostal';

    subtest 'los mismos metodos de objeto' => sub {
        for my $m (qw(new set valid codigo error strict region insular iso_3166_2)) {
            ok($ES->can($m), "ES->can($m)");
            ok($PT->can($m), "PT->can($m)");
        }
    };

    subtest 'las mismas funciones' => sub {
        ok($ES->can('validate_cp') && $PT->can('validate_cp'), 'validate_cp');
        ok($ES->can('asignado')    && $PT->can('asignado'),    'asignado');
        ok($ES->can('provincias'), 'ES lista las provincias');
        ok($PT->can('distritos'),  'PT lista los distritos');
    };

    subtest 'ninguno acepta el formato del otro' => sub {
        is($ES->can('validate_cp')->('1000-001')->{valid}, 0, 'ES rechaza NNNN-NNN');
        is($PT->can('validate_cp')->('28001')->{valid},    0, 'PT rechaza NNNNN');

        # y con strict => 0 tampoco, que es donde seria facil colar uno por otro
        is($ES->can('validate_cp')->('1000-001', { strict => 0 })->{valid}, 0,
           'ES no normaliza un CP portugues a uno espanol');
        is($PT->can('validate_cp')->('28001', { strict => 0 })->{valid}, 0,
           'PT no normaliza un CP espanol a uno portugues');
    };
}

done_testing;
