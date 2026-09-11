package Business::ES::CodigoPostal;

# ABSTRACT: Validación de códigos postales españoles: provincia, comunidad, región y localidades

use strict;
use warnings;

## Los literales de este fichero (nombres de provincia y de comunidad autonoma,
## y los mensajes de error) llevan acentos. Sin 'use utf8' salian como bytes
## UTF-8 crudos y quien los guardaba en una base de datos con la conexion en
## utf8mb4 acababa con doble encoding. Desde 0.03 el modulo devuelve
## CARACTERES en todas sus salidas de texto.
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(validate_cp municipios asignado);

use Class::XSAccessor {
  accessors => [qw(codigo ca error iso_3166_2 strict provincia prov_code region valid)]
};

our $VERSION = '0.03';


use constant PROVINCIAS =>
  {
   '01' => 'Álava',     '02' => 'Albacete',  '03' => 'Alicante',      '04' => 'Almería',    '05' => 'Ávila',
   '06' => 'Badajoz',   '07' => 'Islas Baleares', '08' => 'Barcelona','09' => 'Burgos',     '10' => 'Cáceres',
   '11' => 'Cádiz',     '12' => 'Castellón', '13' => 'Ciudad Real',   '14' => 'Córdoba',    '15' => 'La Coruña',
   '16' => 'Cuenca',    '17' => 'Gerona',    '18' => 'Granada',       '19' => 'Guadalajara','20' => 'Guipúzcoa',
   '21' => 'Huelva',    '22' => 'Huesca',    '23' => 'Jaén',          '24' => 'León',       '25' => 'Lérida',
   '26' => 'La Rioja',  '27' => 'Lugo',      '28' => 'Madrid',        '29' => 'Málaga',     '30' => 'Murcia',
   '31' => 'Navarra',   '32' => 'Orense',    '33' => 'Asturias',      '34' => 'Palencia',
   '35' => 'Las Palmas','36' => 'Pontevedra','37' => 'Salamanca',     '38' => 'Santa Cruz de Tenerife',
   '39' => 'Cantabria', '40' => 'Segovia',   '41' => 'Sevilla',       '42' => 'Soria',     '43' => 'Tarragona',
   '44' => 'Teruel',    '45' => 'Toledo',    '46' => 'Valencia',      '47' => 'Valladolid','48' => 'Vizcaya',
   '49' => 'Zamora',    '50' => 'Zaragoza',  '51' => 'Ceuta',         '52' => 'Melilla'
};

use constant ISO_3166_2 =>
  {
   '01' => 'ES-VI', '02' => 'ES-AB', '03' => 'ES-A',  '04' => 'ES-AL', '05' => 'ES-AV',
   '06' => 'ES-BA', '07' => 'ES-PM', '08' => 'ES-B',  '09' => 'ES-BU', '10' => 'ES-CC',
   '11' => 'ES-CA', '12' => 'ES-CS', '13' => 'ES-CR', '14' => 'ES-CO', '15' => 'ES-C',
   '16' => 'ES-CU', '17' => 'ES-GI', '18' => 'ES-GR', '19' => 'ES-GU', '20' => 'ES-SS',
   '21' => 'ES-H',  '22' => 'ES-HU', '23' => 'ES-J',  '24' => 'ES-LE', '25' => 'ES-L',
   '26' => 'ES-LO', '27' => 'ES-LU', '28' => 'ES-M',  '29' => 'ES-MA', '30' => 'ES-MU',
   '31' => 'ES-NA', '32' => 'ES-OR', '33' => 'ES-O',  '34' => 'ES-P',  '35' => 'ES-GC',
   '36' => 'ES-PO', '37' => 'ES-SA', '38' => 'ES-TF', '39' => 'ES-S',  '40' => 'ES-SG',
   '41' => 'ES-SE', '42' => 'ES-SO', '43' => 'ES-T',  '44' => 'ES-TE', '45' => 'ES-TO',
   '46' => 'ES-V',  '47' => 'ES-VA', '48' => 'ES-BI', '49' => 'ES-ZA', '50' => 'ES-Z',
   '51' => 'ES-CE', '52' => 'ES-ML'
  };

use constant {
              'ERROR_DIGITS5' => "Código postal no son 5 dígitos",
              'ERROR_DEFINED' => "Código postal no definido",
              'ERROR_ASSIGN'  => "Código postal no asignado",
             };


sub insular {
  my $self = shift;

  return unless $self->valid;

  my $prov = $self->prov_code;

  # Baleares, Las Palmas, Santa Cruz de Tenerife
  return 1 if $prov eq '07' || $prov eq '35' || $prov eq '38';

  return 0;
}


sub _comunidad_autonoma {
  my $prov_code = shift;

  return 'Illes Balears'              if $prov_code eq '07';
  return 'La Rioja'                   if $prov_code eq '26';
  return 'Comunidad de Madrid'        if $prov_code eq '28';
  return 'Región de Murcia'           if $prov_code eq '30';
  return 'Comunidad Foral de Navarra' if $prov_code eq '31';
  return 'Principado de Asturias'     if $prov_code eq '33';
  return 'Cantabria'                  if $prov_code eq '39';
  return 'Ceuta'                      if $prov_code eq '51';
  return 'Melilla'                    if $prov_code eq '52';

  return 'Castilla-La Mancha'   if $prov_code =~ /^(02|13|16|19|45)$/;
  return 'Castilla y León'      if $prov_code =~ /^(05|09|24|34|37|40|42|47|49)$/;
  return 'Comunitat Valenciana' if $prov_code =~ /^(03|12|46)$/;

  return 'País Vasco'  if $prov_code =~ /^(01|20|48)$/;
  return 'Andalucía'   if $prov_code =~ /^(04|11|14|18|21|23|29|41)$/;
  return 'Extremadura' if $prov_code =~ /^(06|10)$/;
  return 'Cataluña'    if $prov_code =~ /^(08|17|25|43)$/;
  return 'Galicia'     if $prov_code =~ /^(15|27|32|36)$/;
  return 'Aragón'      if $prov_code =~ /^(22|44|50)$/;
  return 'Canarias'    if $prov_code =~ /^(35|38)$/;

  return;
}

# Devuelve : Peninsula Baleares Canarias Ceuta  Melilla
sub _region {
  my $pv = shift;

  return 'Baleares' if $pv eq '07';
  return 'Canarias' if $pv eq '35' || $pv eq '38';
  return 'Ceuta'    if $pv eq '51';
  return 'Melilla'  if $pv eq '52';

  return 'Peninsula';
}


sub _normalize {
  my $cp = shift;

  return unless defined $cp;

  $cp =~ s/\s+//g;
  $cp =~ s/\D//g;

  return unless length($cp);

  return sprintf('%05d', $cp);
}


sub validate_cp {
  my ($cp, $opts) = @_;
  $opts ||= {};

  $cp = _normalize($cp) unless $opts->{strict} // 1;

  return { valid => 0, error => ERROR_DEFINED } unless $cp;

  return { valid => 0, error => ERROR_DIGITS5, codigo => $cp } unless $cp =~ /\A[0-9]{5}\z/;
  return { valid => 0, error => ERROR_ASSIGN , codigo => $cp } unless $cp >= 1000 && $cp <= 52999;

  my $prov_code = substr($cp, 0, 2);

  # Valid
  return {
          valid      => 1,
          codigo     => $cp,
          ca         => _comunidad_autonoma($prov_code),
          prov_code  => $prov_code,
          region     => _region($prov_code),
          provincia  => PROVINCIAS->{ $prov_code },
          iso_3166_2 => ISO_3166_2->{ $prov_code }
         };
}


sub new {
  my $class = shift;
  my %args  = @_ == 1 && ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
  my $self  = bless {}, $class;

  $self->strict(defined $args{strict} ? $args{strict} : 1);

  $self->set($args{codigo}) if defined $args{codigo};

  return $self;
}


sub _set_error {
  my $self = shift;
  $self->error(shift);

  $self->codigo(undef);
  $self->ca(undef);
  $self->provincia(undef);
  $self->prov_code(undef);
  $self->region(undef);
  $self->iso_3166_2(undef);

  $self->valid(0);
}


sub set {
  my ($self,$cp) = @_;
  my $res;

  # Normalize
  unless ( $self->strict ) {
    $cp  = _normalize($cp);
    $res = validate_cp($cp, { strict => 0 });
  } else {
    $res = validate_cp($cp);
  }

  ## OK
  if ( $res->{valid} ) {
    $self->codigo($res->{codigo});
    $self->ca($res->{ca});
    $self->provincia($res->{provincia});
    $self->prov_code($res->{prov_code});
    $self->region($res->{region});
    $self->iso_3166_2($res->{iso_3166_2});
    $self->valid(1);
    $self->error(undef);

    return 1;
  }

  ## KO
  $self->_set_error($res->{error});

  return 0;
}


sub municipios {
  my $cp = ref($_[0]) ? $_[0]->codigo : $_[0];

  return () unless defined $cp;

  require Business::ES::CodigoPostal::Municipios;

  return Business::ES::CodigoPostal::Municipios::municipios($cp);
}


sub asignado {
  my $cp = ref($_[0]) ? $_[0]->codigo : $_[0];

  return 0 unless defined $cp;

  require Business::ES::CodigoPostal::Municipios;

  return Business::ES::CodigoPostal::Municipios::asignado($cp);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ES::CodigoPostal - Validación de códigos postales españoles: provincia, comunidad, región y localidades

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Business::ES::CodigoPostal 'validate_cp';

  # OO
  $cp = Business::ES::CodigoPostal->new( codigo => '28001' );
  $cp = Business::ES::CodigoPostal->new({ codigo => '28001' );

  # function
  $cp = validate_cp('18001');
  $cp = validate_cp('18001', { strict => 0 }); # _normalize()

  if ($cp->{valid}) {
      print $cp->{provincia}; # Granada
      print $cp->{region};    # Peninsula
      print $cp->{ca};        # Andalucia
  } else {
      print $cp->{error};
  }

  # localidades (carga los datos solo al pedirlas)
  my @m = Business::ES::CodigoPostal::municipios('28017');  # ('Madrid')
  Business::ES::CodigoPostal::asignado('28107');            # 0 -- no existe

=head1 DESCRIPTION

Este módulo permite validar códigos postales de España y obtener su provincia asociada. El rango válido de códigos es de 01000 a 52999.

Por defecto devuelve código ISO 3166-2

=head1 NAME

Business::ES::CodigoPostal - Validación de códigos postales españoles: provincia, comunidad, región y localidades

=head1 SUBROUTINES/METHODS

=head2 codigo

Devuelve el código postal almacenado en el objeto.

  my $codigo = $cp->codigo;

=head2 error

Devuelve el mensaje de error si el código postal no es válido.

  my $error = $cp->error;
  print "Error: $error" if defined $error;

=head2 iso_3166_2

Devuelve el código ISO 3166-2 de la provincia.

  my $iso = $cp->iso_3166_2;

=head2 insular

Devuelve 1 si el código postal corresponde a territorio insular (Baleares o Canarias).

  if ($cp->insular) {
      print "Este CP está en una isla";
  }

=head2 strict

Controla el modo de validación, modo strict por defecto, no se normaliza la entrada.

  $cp->strict(0);  # Permitir normalización
  my $is_strict = $cp->strict;

=head2 provincia

Devuelve el nombre de la provincia correspondiente al código postal.

  my $provincia = $cp->provincia;
  print "Provincia: $provincia" if $cp->valid;

=head2 prov_code

Código de provincia los primeros 2 digitos

=head2 region

Región: Baleares, Las Palmas, Santa Cruz de Tenerife

  my $region = $cp->region;

=head2 valid

Indica si el código postal es válido (1) o no (0).

  my $es_valido = $cp->valid;

=head2 ca

Devuelve la comunidad autónoma correspondiente al código postal.

  my $ccaa = $cp->ca;

=head2 _normalize

Limpia y agrupa el código postal, cuando se fija strict a 0

=head2 validate_cp

Función que valida un código postal y devuelve un hash con el resultado.

  my $resultado = validate_cp('28001');

  if ($resultado->{valid}) {
      print "Código:     " . $resultado->{codigo};
      print "Provincia:  " . $resultado->{provincia};
      print "ISO 3166-2: " . $resultado->{iso_3166_2};
  } else {
      print "Error:      " . $resultado->{error};
  }

Retorna un hash con las claves:
- C<valid>      : 1 si es válido, 0 si no
- C<codigo>     : código postal
- C<provincia>  : nombre de la provincia (si es válido)
- C<iso_3166_2> : código ISO 3166-2 de la provincia (si es válido)
- C<error>      : mensaje de error (si no es válido)

=head2 new

Crea un nuevo objeto de código postal.

  my $cp = Business::ES::CodigoPostal->new();
  my $cp = Business::ES::CodigoPostal->new(codigo => '28001');
  my $cp = Business::ES::CodigoPostal->new({ codigo => '28001', strict => 0, iso_3166_2 => 0 });

Parámetros:
- C<codigo>    : Código postal a validar
- C<strict>    : Modo strict (Por defecto), a 0 para normalizar la entrada
- C<iso_3166_2>: Incluir código ISO 3166-2 (Por defecto)

=head2 _set_error

Fija el error como argumento el texto a guardar

=head2 set

Fija nuevo código postal

  my $res = $cp->set('08001');

  unless ($res) {
      print "Error: " . $cp->error;
  }

Retorna 1 si el código posta es válido o 0 si no.

=head2 municipios

Localidades de un código postal, ordenadas. Lista vacía si no consta.

  my @m = $cp->municipios;                                 # OO
  my @m = Business::ES::CodigoPostal::municipios('28017'); # función

Los datos viven en L<Business::ES::CodigoPostal::Municipios> y se cargan
B<solo al llamar aquí>: validar un código postal o resolver su provincia no
los toca. Cargarlos cuesta unos 20 ms y unos 4 MB, una sola vez por proceso.

Las localidades salen decodificadas (caracteres, no bytes), a diferencia de
C<provincia> y C<ca>, que devuelven los literales del módulo tal cual.

=head2 asignado

Cierto si el código postal está asignado a alguna localidad.

  Business::ES::CodigoPostal::asignado('28017');  # 1 -- Madrid
  Business::ES::CodigoPostal::asignado('28107');  # 0 -- no existe

Es una comprobación B<distinta> de C<valid>, y más estrecha: C<valid> mira que
el código esté en el rango 01000-52999, así que da por bueno cualquier número
con un prefijo de provincia real. 28107 pasa esa validación --prefijo 28,
Madrid-- y sin embargo no existe: Alcobendas es 28100, 28108 y 28109. Un error
de transposición dentro de la misma provincia solo se ve preguntando por la
localidad.

Falso significa "no consta en los datos". Para España el volcado está
prácticamente completo, pero no es lo mismo que "no existe".

=head1 AUTHOR

HDELGADO E<lt>hdelgado@cpan.orgE<gt>

=head1 FUENTE DE LOS DATOS

Los nombres de provincia, comunidad autónoma y región son tablas propias del
módulo.

Las localidades de L<Business::ES::CodigoPostal::Municipios> proceden de
L<GeoNames|https://www.geonames.org/> (volcado C<export/zip/ES.zip>), bajo
licencia Creative Commons Attribution 4.0:
L<https://creativecommons.org/licenses/by/4.0/>.

=head1 LICENCIA

Copyright 2025-2026 HDELGADO.

Este módulo es software libre; puede redistribuirse y modificarse bajo los
mismos términos que Perl mismo. Los datos de localidades conservan su licencia
propia (CC BY 4.0), indicada arriba.

=head1 AUTHOR

HDELGADO <hdelgado@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by HDELGADO.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
