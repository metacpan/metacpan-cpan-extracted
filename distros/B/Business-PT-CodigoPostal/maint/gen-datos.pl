#!/usr/bin/env perl
# Regenera las tablas de Business::PT::CodigoPostal desde el volcado de
# codigos postales de GeoNames (CC BY 4.0).
#
#   curl -sLO https://download.geonames.org/export/zip/PT.zip
#   unzip -o PT.zip PT.txt
#   perl maint/gen-datos.pl PT.txt
#
# Escribe dos ficheros:
#
#   lib/Business/PT/CodigoPostal/Datos.pm       distrito por codigo postal
#   lib/Business/PT/CodigoPostal/Localidades.pm localidad y concelho
#
# Por que dos tablas para el distrito, y no una regla como en Espana: alli los
# dos primeros digitos SON el numero de provincia, por definicion. En Portugal
# el codigo postal es una division de reparto y no respeta las fronteras de
# distrito: el prefijo de dos digitos es ambiguo en 25 de 79 casos. Con cuatro
# digitos quedan 13 prefijos ambiguos de 750, y esos se resuelven mirando el
# codigo entero, que ya no falla ninguno.

use strict;
use warnings;

## Este fichero tiene literales acentuados ('Açores'). Sin 'use utf8' serian
## bytes y al escribirlos por una capa :encoding(UTF-8) saldrian codificados
## dos veces.
use utf8;
use open ':std', ':encoding(UTF-8)';

my $src = shift or die "uso: $0 PT.txt\n";

## La version sale del modulo principal, para que las tablas no se queden
## atras cuando se sube la del dist.
my $main = do {
    open my $m, '<:encoding(UTF-8)', 'lib/Business/PT/CodigoPostal.pm' or die $!;
    local $/; <$m>;
};
my ($VERSION) = $main =~ /our \s+ \$VERSION \s* = \s* '([^']+)'/x
    or die "no se pudo leer el VERSION del modulo principal\n";

open my $fh, '<:encoding(UTF-8)', $src or die "$src: $!";
my (%dist4, %conc4, %full, %loc);
while (my $l = <$fh>) {
    chomp $l;
    my @f = split /\t/, $l;
    next unless @f > 6;
    my ($cp, $lugar, $distrito, $concelho) = @f[1, 2, 3, 5];
    next unless $cp =~ /\A([0-9]{4})-([0-9]{3})\z/;

    ## GeoNames trae este en ingles; el resto ya vienen en portugues.
    $distrito = 'Açores' if $distrito eq 'Azores';
    my ($p4, $suf) = ($1, $2);

    $dist4{$p4}{$distrito}++;
    $conc4{$p4}{$concelho}++;
    $full{"$p4$suf"} = $distrito;

    for ($lugar, $concelho) { s/\A\s+|\s+\z//g }
    die "separador '|' en el toponimo: $cp $lugar\n" if $lugar =~ /\|/;
    $loc{"$p4$suf"}{$lugar} = 1 if length $lugar;
}
close $fh;

## Prefijos con un solo distrito -> tabla de 4 digitos.
## Prefijos con varios -> hay que mirar el codigo entero.
my (%p4, %excepciones);
for my $p4 (sort keys %dist4) {
    my @d = keys %{ $dist4{$p4} };
    if (@d == 1) { $p4{$p4} = $d[0]; next }
    $excepciones{$_} = $full{$_} for grep { /\A\Q$p4\E/ } keys %full;
}

my $n_p4  = scalar keys %p4;
my $n_exc = scalar keys %excepciones;
my $n_amb = (scalar keys %dist4) - $n_p4;

## Region logistica: el archipielago paga porte aparte, igual que Baleares o
## Canarias en Espana.
my %REGION = ('Açores' => 'Açores', 'Madeira' => 'Madeira');

open my $o, '>:encoding(UTF-8)', 'lib/Business/PT/CodigoPostal/Datos.pm' or die $!;
print {$o} <<"HEAD";
package Business::PT::CodigoPostal::Datos;

# ABSTRACT: Tablas de distrito por codigo postal (datos de GeoNames)

use strict;
use warnings;
use utf8;

our \$VERSION = '$VERSION';

=encoding utf8

=head1 NAME

Business::PT::CodigoPostal::Datos - Distrito por código postal

=head1 DESCRIPTION

GENERADO AUTOMÁTICAMENTE por C<maint/gen-datos.pl>; no editar a mano.

Dos tablas. C<PREFIJOS> lleva $n_p4 prefijos de cuatro dígitos cuyo distrito
es inequívoco. C<EXCEPCIONES> lleva los $n_exc códigos completos de los $n_amb
prefijos que caen a caballo de dos distritos; con el código entero no queda
ninguno ambiguo.

Datos de L<GeoNames|https://www.geonames.org/> (CC BY 4.0).

=cut

our %PREFIJOS = (
HEAD
printf {$o} "  '%s' => '%s',\n", $_, $p4{$_} for sort keys %p4;
print {$o} ");\n\nour %EXCEPCIONES = (\n";
printf {$o} "  '%s' => '%s',\n", $_, $excepciones{$_} for sort keys %excepciones;
print {$o} ");\n\n1;\n";
close $o;

my $n_loc  = scalar keys %loc;
my $pares  = 0;
$pares += scalar keys %{ $loc{$_} } for keys %loc;

open my $l, '>:encoding(UTF-8)', 'lib/Business/PT/CodigoPostal/Localidades.pm' or die $!;
print {$l} <<"HEAD2";
package Business::PT::CodigoPostal::Localidades;

# ABSTRACT: Localidades por codigo postal portugues (datos de GeoNames)

use strict;
use warnings;

our \$VERSION = '$VERSION';

=encoding utf8

=head1 NAME

Business::PT::CodigoPostal::Localidades - Localidades por código postal

=head1 DESCRIPTION

GENERADO AUTOMÁTICAMENTE por C<maint/gen-datos.pl>; no editar a mano.

$pares pares código/localidad sobre $n_loc códigos postales. Se carga sólo
cuando se piden localidades: validar un código o resolver su distrito no lo
toca. Los datos viven en C<__DATA__> y no en un hash literal a propósito -- el
compilador de Perl no mira ahí hasta que alguien lee.

Las localidades salen como caracteres.

Datos de L<GeoNames|https://www.geonames.org/> (CC BY 4.0).

=head1 SUBROUTINES

=head2 localidades(\$cp)

Lista de localidades del código postal (formato NNNNNNN, sin guión), ordenada.

=head2 asignado(\$cp)

Cierto si el código postal figura en los datos.

=cut

my %LOC;
my \$CARGADO = 0;

sub _cargar {
    return if \$CARGADO;
    \$CARGADO = 1;
    binmode DATA, ':encoding(UTF-8)';
    while (my \$l = <DATA>) {
        chomp \$l;
        my (\$cp, \$lugares) = split /\\t/, \$l, 2;
        next unless defined \$lugares;
        \$LOC{\$cp} = \$lugares;
    }
    close DATA;
}

sub localidades {
    my \$cp = shift;
    return () unless defined \$cp && \$cp =~ /\\A[0-9]{7}\\z/;
    _cargar();
    my \$l = \$LOC{\$cp} or return ();
    return split /\\|/, \$l;
}

sub asignado {
    my \$cp = shift;
    return 0 unless defined \$cp && \$cp =~ /\\A[0-9]{7}\\z/;
    _cargar();
    return exists \$LOC{\$cp} ? 1 : 0;
}

1;

__DATA__
HEAD2
for my $cp (sort keys %loc) {
    print {$l} $cp, "\t", join('|', sort keys %{ $loc{$cp} }), "\n";
}
close $l;

printf "Datos.pm       : %d prefijos, %d excepciones (de %d prefijos ambiguos)\n",
    $n_p4, $n_exc, $n_amb;
printf "Localidades.pm : %d codigos, %d pares\n", $n_loc, $pares;
