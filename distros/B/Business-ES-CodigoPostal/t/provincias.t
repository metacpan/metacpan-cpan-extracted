#!perl
# La lista de provincias y su orden. Hermano de t/distritos.t en
# Business-PT-CodigoPostal: las dos APIs tienen que parecerse.

use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

use_ok('Business::ES::CodigoPostal');
Business::ES::CodigoPostal->import(qw(validate_cp provincias));

subtest 'las 52' => sub {
    my @p = provincias();
    is(scalar @p, 52, 'son 52');

    my %p = map { $_ => 1 } @p;
    ok($p{'Madrid'},          'Madrid');
    ok($p{'Álava'},           'Álava con tilde');
    ok($p{'Islas Baleares'},  'Islas Baleares');
    ok($p{'Santa Cruz de Tenerife'}, 'Santa Cruz de Tenerife');
    ok($p{'Ceuta'} && $p{'Melilla'}, 'Ceuta y Melilla');
};

# Un sort a secas compara por punto de codigo y manda 'Álava' y 'Ávila' detras
# de 'Zaragoza', porque 'Á' es U+00C1. En un desplegable eso canta.
subtest 'orden alfabetico ignorando los acentos' => sub {
    my @p = provincias();
    is($p[0],  'Álava',     'Álava primera, no ultima');
    is($p[-1], 'Zaragoza',  'Zaragoza ultima');

    my %pos; $pos{$p[$_]} = $_ for 0 .. $#p;
    ok($pos{'Álava'}   < $pos{'Albacete'},  'Álava antes que Albacete');
    ok($pos{'Ávila'}   < $pos{'Badajoz'},   'Ávila antes que Badajoz');
    ok($pos{'Almería'} < $pos{'Asturias'},  'Almería antes que Asturias');
    ok($pos{'León'}    < $pos{'Lérida'},    'León antes que Lérida');
};

# La lista sale de la misma tabla que provincia(). Si se mantuviera aparte,
# acabaria diciendo una cosa distinta de lo que rellena el codigo postal.
subtest 'la lista concuerda con lo que devuelve validate_cp' => sub {
    my %p = map { $_ => 1 } provincias();
    my @falta;
    for my $n (0 .. 99) {
        my $r = validate_cp(sprintf('%02d001', $n));
        next unless $r->{valid};
        push @falta, "$n:$r->{provincia}" unless $p{ $r->{provincia} };
    }
    is_deeply(\@falta, [], 'toda provincia devuelta esta en la lista');
};

done_testing;
