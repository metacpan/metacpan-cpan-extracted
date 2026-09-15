#!perl
# A lista de distritos, a sua ordem e o código ISO 3166-2. Irmão de
# t/provincias.t em Business-ES-CodigoPostal: as duas APIs devem parecer-se.

use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

use_ok('Business::PT::CodigoPostal');
Business::PT::CodigoPostal->import(qw(validate_cp distritos));

subtest 'os 20' => sub {
    my @d = distritos();
    is(scalar @d, 20, '18 distritos mais duas regiões autónomas');

    my %d = map { $_ => 1 } @d;
    ok($d{'Lisboa'} && $d{'Porto'},   'Lisboa e Porto');
    ok($d{'Açores'},                  'Açores com cedilha');
    ok($d{'Bragança'},                'Bragança inteira');
    ok($d{'Viana do Castelo'},        'Viana do Castelo inteiro');
    ok(!$d{'Azores'},                 'não fica o nome inglês do GeoNames');
};

# Um sort simples compara por ponto de código e manda 'Açores' e 'Évora' para
# o fim, porque 'Ç' e 'É' vêm depois do 'Z'.
subtest 'ordem alfabética sem contar os sinais' => sub {
    my @d = distritos();
    is($d[0],  'Açores', 'Açores primeiro, antes de Aveiro');
    is($d[-1], 'Viseu',  'Viseu último');

    my %pos; $pos{$d[$_]} = $_ for 0 .. $#d;
    ok($pos{'Açores'}   < $pos{'Aveiro'},  'Açores antes de Aveiro');
    ok($pos{'Évora'}    > $pos{'Coimbra'}, 'Évora depois de Coimbra');
    ok($pos{'Évora'}    < $pos{'Faro'},    'Évora antes de Faro');
    ok($pos{'Bragança'} < $pos{'Castelo Branco'}, 'Bragança antes de Castelo Branco');
};

# Um ERP costuma escolher o estado ou província por este código: sem ele uma
# morada portuguesa não se consegue mapear.
subtest 'ISO 3166-2' => sub {
    is(validate_cp('1000-001')->{iso_3166_2}, 'PT-11', 'Lisboa');
    is(validate_cp('4000-001')->{iso_3166_2}, 'PT-13', 'Porto');
    is(validate_cp('3000-001')->{iso_3166_2}, 'PT-06', 'Coimbra');

    # as duas regiões autónomas quebram a série dos 18
    is(validate_cp('9500-001')->{iso_3166_2}, 'PT-20', 'Açores é PT-20, não PT-19');
    is(validate_cp('9000-001')->{iso_3166_2}, 'PT-30', 'Madeira é PT-30');

    is(validate_cp('1000-001')->{distrito_code}, '11', 'distrito_code sem o prefixo');
    is(validate_cp('9000-001')->{distrito_code}, '30', 'idem para a Madeira');

    ok(!exists validate_cp('abc')->{iso_3166_2}, 'sem ISO quando falha');
};

subtest 'todos os distritos têm ISO' => sub {
    my %vistos;
    for my $p4 ('1000' .. '9999') {
        my $r = validate_cp("$p4-001");
        next unless $r->{valid};
        $vistos{ $r->{distrito} } = $r->{iso_3166_2};
    }
    my @sem_iso = grep { !defined $vistos{$_} } keys %vistos;
    is_deeply(\@sem_iso, [], 'nenhum distrito devolvido fica sem código ISO');

    my %d = map { $_ => 1 } distritos();
    my @fora = grep { !$d{$_} } keys %vistos;
    is_deeply(\@fora, [], 'todo distrito devolvido está na lista');
};

subtest 'OO' => sub {
    my $cp = Business::PT::CodigoPostal->new(codigo => '1000-001');
    is($cp->iso_3166_2,    'PT-11', 'iso_3166_2 como método');
    is($cp->distrito_code, '11',    'distrito_code como método');

    $cp->set('9000-001');
    is($cp->iso_3166_2, 'PT-30', 'set actualiza o ISO');

    $cp->set('nada');
    is($cp->iso_3166_2,    undef, 'limpa o ISO quando falha');
    is($cp->distrito_code, undef, 'e o código do distrito');
};

done_testing;
