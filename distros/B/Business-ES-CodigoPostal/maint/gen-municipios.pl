#!/usr/bin/env perl
# Regenera lib/Business/ES/CodigoPostal/Municipios.pm desde el volcado de
# codigos postales de GeoNames (CC BY 4.0).
#
#   curl -sLO https://download.geonames.org/export/zip/ES.zip
#   unzip -o ES.zip ES.txt
#   perl maint/gen-municipios.pl ES.txt
#
# El fichero de GeoNames es TSV: pais, cp, lugar, CA, cod_CA, provincia,
# cod_prov, ... Solo se usan las columnas 2 (cp) y 3 (lugar): la provincia ya
# la resuelve el modulo principal por el prefijo, y duplicarla aqui abriria la
# puerta a que las dos fuentes se contradigan.

use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

my $src = shift or die "uso: $0 ES.txt\n";
my $out = 'lib/Business/ES/CodigoPostal/Municipios.pm';

open my $fh, '<:encoding(UTF-8)', $src or die "$src: $!";
my %cp;
while (my $l = <$fh>) {
    chomp $l;
    my @f = split /\t/, $l;
    next unless @f > 2;
    my ($codigo, $lugar) = @f[1, 2];
    next unless $codigo =~ /\A[0-9]{5}\z/;
    $lugar =~ s/\A\s+|\s+\z//g;
    next unless length $lugar;
    ## '|' es el separador del formato; si algun dia aparece en un toponimo
    ## el fichero quedaria corrupto en silencio, asi que se corta aqui.
    die "separador '|' en el toponimo: $codigo $lugar\n" if $lugar =~ /\|/;
    $cp{$codigo}{$lugar} = 1;
}
close $fh;

my $pares = 0;
$pares += scalar keys %{ $cp{$_} } for keys %cp;

open my $o, '>:encoding(UTF-8)', $out or die "$out: $!";
print {$o} <<"HEAD";
package Business::ES::CodigoPostal::Municipios;

# ABSTRACT: Localidades por codigo postal espanol (datos de GeoNames)

use strict;
use warnings;

our \$VERSION = '0.03';

=encoding utf8

=head1 NAME

Business::ES::CodigoPostal::Municipios - Localidades por codigo postal

=head1 DESCRIPTION

Tabla de localidades indexada por codigo postal. GENERADO AUTOMATICAMENTE por
C<maint/gen-municipios.pl>; no editar a mano.

Se carga solo cuando se pide una localidad: el modulo principal no lo toca
para validar un codigo postal ni para resolver la provincia, que es el uso
mayoritario. Los datos viven en C<__DATA__> y no en un hash literal a
proposito -- el compilador de Perl no mira ahi hasta que alguien lee, asi que
cargar el modulo cuesta lo mismo que cargar un fichero vacio.

Las localidades salen como CARACTERES, igual que el resto del modulo desde
la 0.03.

=head1 FUENTE

Datos de L<GeoNames|https://www.geonames.org/>, distribuidos bajo
Creative Commons Attribution 4.0 (L<https://creativecommons.org/licenses/by/4.0/>).
Volcado C<export/zip/ES.zip>. $pares pares codigo/localidad, @{[ scalar keys %cp ]} codigos.

=head1 SUBROUTINES

=head2 municipios(\$cp)

Lista de localidades de ese codigo postal, ordenada. Vacia si no consta.

=head2 asignado(\$cp)

Cierto si el codigo postal figura en los datos. Un codigo dentro del rango
01000-52999 puede no estar asignado a ninguna localidad -- 28107 es real y no
existe -- y eso lo ve esta funcion, no la validacion por rango del modulo
principal. Falso significa "no consta en este volcado de GeoNames", que para
Espana equivale en la practica a no asignado, pero no es lo mismo.

=cut

my %MUNICIPIOS;
my \$CARGADO = 0;

sub _cargar {
    return if \$CARGADO;
    \$CARGADO = 1;
    binmode DATA, ':encoding(UTF-8)';
    while (my \$l = <DATA>) {
        chomp \$l;
        my (\$cp, \$lugares) = split /\\t/, \$l, 2;
        next unless defined \$lugares;
        \$MUNICIPIOS{\$cp} = \$lugares;
    }
    close DATA;
}

sub municipios {
    my \$cp = shift;
    return () unless defined \$cp && \$cp =~ /\\A[0-9]{5}\\z/;
    _cargar();
    my \$l = \$MUNICIPIOS{\$cp} or return ();
    return split /\\|/, \$l;
}

sub asignado {
    my \$cp = shift;
    return 0 unless defined \$cp && \$cp =~ /\\A[0-9]{5}\\z/;
    _cargar();
    return exists \$MUNICIPIOS{\$cp} ? 1 : 0;
}

1;

__DATA__
HEAD

for my $codigo (sort keys %cp) {
    print {$o} $codigo, "\t", join('|', sort keys %{ $cp{$codigo} }), "\n";
}
close $o;

printf "%s: %d codigos, %d pares\n", $out, scalar keys %cp, $pares;
