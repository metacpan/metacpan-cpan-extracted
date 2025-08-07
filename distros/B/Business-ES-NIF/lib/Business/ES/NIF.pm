package Business::ES::NIF;

# ABSTRACT: Validate Spanish NIF, NIE and CIF numbers


our $VERSION = '0.13';

use strict;
use warnings;

use Class::XSAccessor { accessors => [qw(error extra nif status type provincia vies_check vies_error)] };


use constant {
	      NIF_LETRAS => 'TRWAGMYFPDXBNJZSQVHLCKE',
	      CIF_LETRAS => 'JABCDEFGHI',
	      RE_CIF     => qr/^([ABCDEFGHJPQRUVNW])([0-9]{7})([0-9])$/,
	      RE_CIFe    => qr/^([SQPK])([0-9]{7})([A-J])$/,
	      RE_NIF     => qr/^([0-9]{8})([A-Z])$/,
	      RE_NIFe    => qr/^([KLM])([0-9]{7})([A-Z])$/,
	      RE_NIE     => qr/^([XYZ])([0-9]{7})([A-Z])$/
	     };

use constant NIE_PREFIX => { X => '0', Y => '1', Z => '2' };

use constant CIF_EXTRA => {
			   'A' => 'Sociedad Anonima - S.A',
			   'B' => 'Sociedad Limitada - S.L',
			   'C' => 'Sociedad Colectiva - S.C',
			   'D' => 'Sociedades comanditarias',
			   'E' => 'Comunidad de bienes y herencias',
			   'F' => 'Sociedades cooperativas',
			   'G' => 'Asociaciones',
			   'H' => 'Comunidaddes de propietarios',
			   'J' => 'Sociedades civiles',
			   'P' => 'Corporaciones locales',
			   'Q' => 'Organismos publicos',
			   'N' => 'Entidades extranjeras',
			   'R' => 'Congregaciones e instituciones religiosas',
			   'U' => 'Uniones temporales de epresas',
			   'V' => 'Otros tipos de sociedades',
			   'W' => 'Establecimientos permanentes de entidades no residentes en España'
			  };

use constant CIFe_EXTRA => {
			    'S' => 'Órganos de la Administración del Estado',
			    'Q' => 'Organismos autónomos o instituciones religiosas',
			    'P' => 'Corporaciones locales',
			    'K' => 'Formato antiguo (DNI sin letra de control)'
			   };

use constant PROVINCIAS => {
			    '00' => 'No Residente',
			    '01' => 'Álava',
			    '02' => 'Albacete', 
			    '03' => 'Alicante',
			    '04' => 'Almería',
			    '05' => 'Ávila',
			    '06' => 'Badajoz',
			    '07' => 'Islas Baleares',
			    '08' => 'Barcelona',
			    '09' => 'Burgos',
			    '10' => 'Cáceres',
			    '11' => 'Cádiz',
			    '12' => 'Castellón',
			    '13' => 'Ciudad Real',
			    '14' => 'Córdoba',
			    '15' => 'La Coruña',
			    '16' => 'Cuenca',
			    '17' => 'Gerona',
			    '18' => 'Granada',
			    '19' => 'Guadalajara',
			    '20' => 'Guipúzcoa',
			    '21' => 'Huelva',
			    '22' => 'Huesca',
			    '23' => 'Jaén',
			    '24' => 'León',
			    '25' => 'Lérida',
			    '26' => 'La Rioja',
			    '27' => 'Lugo',
			    '28' => 'Madrid',
			    '29' => 'Málaga',
			    '30' => 'Murcia',
			    '31' => 'Navarra',
			    '32' => 'Orense',
			    '33' => 'Asturias',
			    '34' => 'Palencia',
			    '35' => 'Las Palmas',
			    '36' => 'Pontevedra',
			    '37' => 'Salamanca',
			    '38' => 'Santa Cruz de Tenerife',
			    '39' => 'Cantabria',
			    '40' => 'Segovia',
			    '41' => 'Sevilla',
			    '42' => 'Soria',
			    '43' => 'Tarragona',
			    '44' => 'Teruel',
			    '45' => 'Toledo',
			    '46' => 'Valencia',
			    '47' => 'Valladolid',
			    '48' => 'Vizcaya',
			    '49' => 'Zamora',
			    '50' => 'Zaragoza',
			    '51' => 'Ceuta',
			    '52' => 'Melilla',
			    '53' => 'Alicante',         
			    '54' => 'Alicante',         
			    '55' => 'Gerona',           
			    '56' => 'Córdoba',          
			    '57' => 'Islas Baleares',   
			    '58' => 'Barcelona',        
			    '59' => 'Barcelona',
			    '60' => 'Barcelona',
			    '61' => 'Barcelona',
			    '62' => 'Barcelona',
			    '63' => 'Barcelona',
			    '64' => 'Barcelona',
			    '65' => 'Barcelona',
			    '66' => 'Barcelona',
			    '67' => 'Gerona',           
			    '68' => 'Barcelona',        
			    '70' => 'La Coruña',        
			    '71' => 'Guipúzcoa',        
			    '72' => 'Cádiz',            
			    '73' => 'Murcia',           
			    '74' => 'Asturias',         
			    '75' => 'Las Palmas',       
			    '76' => 'Santa Cruz de Tenerife',
			    '77' => 'Tarragona',        
			    '78' => 'Madrid',           
			    '79' => 'Madrid',
			    '80' => 'Madrid',
			    '81' => 'Madrid',
			    '82' => 'Madrid',
			    '83' => 'Madrid',
			    '84' => 'Madrid',
			    '85' => 'Madrid',
			    '86' => 'Madrid',
			    '87' => 'Madrid',
			    '88' => 'Madrid',
			    '90' => 'Sevilla',          
			    '91' => 'Sevilla',          
			    '92' => 'Málaga',           
			    '93' => 'Málaga',           
			    '94' => 'Pontevedra',       
			    '95' => 'Vizcaya',          
			    '96' => 'Valencia',         
			    '97' => 'Valencia',
			    '98' => 'Valencia',
			    '99' => 'Zaragoza'
			   };



sub is_nie  { return shift->type eq 'NIE'  }
sub is_nif  { return shift->type eq 'NIF'  }
sub is_nife { return shift->type eq 'NIFe' }
sub is_cif  { return shift->type eq 'CIF'  }
sub is_cife { return shift->type eq 'CIFe' }

sub _provincia {
  my $codigo = shift;

  return PROVINCIAS->{$codigo} if $codigo =~ /^[0-9]{2}$/;
  return undef;
}

sub _check_cif {
  my ($sociedad,$inscripcion,$control) = @_;
  
  my @n = split //, $inscripcion;
  my $pares = $n[1] + $n[3] + $n[5];
  my $nones;

  for (0, 2, 4, 6) {
    my $d   = $n[$_] * 2;
    $nones += $d < 10 ? $d : $d - 9;
  }

  my $c = (10 - substr($pares + $nones, -1)) % 10;
  my $l = substr(CIF_LETRAS, $c, 1);
  
  if ( $sociedad =~ /[KPQS]/i) {
    return 0 if $l ne uc($control);
  } else {
    return 0 if $c != $control and $l ne uc($control);
  }
    
  return 1;
}

sub _validate_cif {
  my ($self,$sociedad, $inscripcion, $control) = @_;

  $self->status(_check_cif($sociedad, $inscripcion, $control));
  $self->provincia(_provincia(substr($inscripcion,0,2)));

  $self->type('CIF');
  $self->extra( CIF_EXTRA->{ $sociedad } );
}

sub _validate_cife {
  my ($self,$sociedad, $inscripcion, $control) = @_;

  $self->status(_check_cif($sociedad, $inscripcion, $control));

  $self->type('CIFe');
  $self->extra( CIFe_EXTRA->{ $sociedad } );
}

sub _check_nif {
  my ($NIF,$DC) = @_;

  return substr( NIF_LETRAS , $NIF % 23, 1) eq $DC ? 1 : 0;
}

sub _validate_nif {
  my $self = shift;

  $self->status(_check_nif(shift,shift));

  $self->type('NIF');
  $self->extra('NIF');
}

sub _validate_nife {
  my $self = shift; 

  $self->status(_check_nif(shift,shift));

  $self->type('NIFe'); 
  $self->extra('NIF Especial (KLM)');
}

sub _validate_nie {
  my ($self,$NIE,$NIF,$DC) = @_;

  $NIF = NIE_PREFIX->{$NIE} . $NIF;

  $self->status(_check_nif($NIF,$DC));

  $self->type('NIE');
  $self->extra('NIE');
}


sub new {
  my ($class, %args) = @_;

  my $self = { vies => $args{vies} // 0 };
  
  $self = bless $self, $class;

  $self->set($args{nif}) if defined $args{nif};
  
  return $self;
}


sub set {
  my $self = shift;
  my $nif  = shift;
  my $vies = shift // 0;

  $self->{vies} = 1 if $vies;

  unless (defined $nif) {
    $self->status(0);
    $self->error("NIF vacío");
    return;
  }

  $nif =~ tr/-. //d;

  $self->nif(uc($nif));
  $self->check;
}


sub is_valid { !!shift->status }


sub check {
  my $self = shift;
  my $nif  = $self->nif;

  if    ($nif =~ RE_NIF)  { $self->_validate_nif ($1, $2);     }
  elsif ($nif =~ RE_CIF)  { $self->_validate_cif ($1, $2, $3); }
  elsif ($nif =~ RE_NIE)  { $self->_validate_nie ($1, $2, $3); }
  elsif ($nif =~ RE_NIFe) { $self->_validate_nife($2, $3);     }
  elsif ($nif =~ RE_CIFe) { $self->_validate_cife($1, $2, $3); }

  if ( $self->status ) {
    $self->vies() if $self->{vies};
    return;
  }
  
  $self->error("Error formato de NIF/CIF/NIE");
  $self->status(0);
  
  return;
}


sub vies {
  my $self = shift;
  my $nif  = $self->nif;
  
  unless ($self->status) {
    $self->vies_error("No se puede validar VIES: NIF no es válido");
    $self->vies_check(0);
    return;
  }
  
  unless (defined $nif && length($nif) > 0) {
    $self->vies_error("No hay NIF para validar en VIES");
    $self->vies_check(0);
    return;
  }
  
  eval {
    require Business::Tax::VAT::Validation;
    
    my $vat = Business::Tax::VAT::Validation->new();
    
    unless ($vat) {
      die "Error Business::Tax::VAT::Validation";
    }
    
    $self->vies_check($vat->check('ES' . $nif));
    
    unless ($self->vies_check) {
      $self->vies_error( $vat->get_last_error() // 'Error desconocido en VIES');
    }
  };
  
  if ($@) {
    $self->vies_error("Error cargando validación VIES: $@");
    $self->vies_check(0);
  }

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ES::NIF - Validate Spanish NIF, NIE and CIF numbers

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use Business::ES::NIF;

    my $NIF = Business::ES::NIF->new( nif => '01234567L' , vies => 0);

    $NIF->set('B01234567');
    $NIF->set('B01234567',1); <= Check VIES ( Business::Tax::VAT::Validation )

    $NIF->status();

 Dump:

    bless( {
           'nif' => '01234567L',
           'vies' => 0,
           'extra' => 'NIF',
           'type' => 'NIF',
           }, 'NIF' );

    bless( {
           'nif' => 'B01234567',
           'vies' => 1,
           'vies_check' => 0,
           'extra' => 'Sociedad Limitada - S.L',
           'type' => 'CIF',
           'vies_error' => 'Invalid VAT Number (false)'
           }, 'NIF' );

=head1 DESCRIPTION

Validate a Spanish NIF / CIF / NIE

Referencias: http://es.wikipedia.org/wiki/Numero_de_identificacion_fiscal  

Se puede activar la comprobacion sobre el VIES ( Business::Tax::VAT::Validation )

=head1 NAME

 Business::ES::NIF - Validate Spanish NIF, NIE and CIF numbers

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 nif

=head2 status

=head2 provincia

my $city = $obj->provincia;

=head2 vies_check

=head2 vies_error

=head2 type

Devuelve el tipo (NIF, NIE, CIF, CIFe, NIFe)

    my $tipo = $obj->type;

=head2 extra

Devuelve una descripcion extra del tipo, por ejemplo:

"Sociedad Anonima - S.A", "NIE", "NIF Especial (KLM)" ...

    my $desc = $obj->extra;

=head2 error

Devuelve el mensaje de error (si existe) cuando el NIF no es valido

    warn $obj->error unless $obj->is_valid;

=head2 is_nif

  $obj->is_nif

Devuelve verdadero si el tipo detectado es un NIF (Número de Identificación Fiscal para personas físicas españolas).

=head2 is_nife

  $obj->is_nife

Devuelve verdadero si el tipo detectado es un NIF especial (K, L o M), utilizado por menores de edad, residentes o asimilados.

=head2 is_nie

  $obj->is_nie

Devuelve verdadero si el tipo detectado es un NIE (Número de Identificación de Extranjeros).

=head2 is_cif

  $obj->is_cif

Devuelve verdadero si el tipo detectado es un CIF (Código de Identificación Fiscal para entidades jurídicas).

=head2 is_cife

  $obj->is_cife

Devuelve verdadero si el tipo detectado es un CIF especial (entidades del estado, corporaciones, etc.).

=head2 new

    new method

=head2 set

    Set NIF

    $vies = 1 | 0

=head2 is_valid

=head2 check

=head2 vies

Valida el NIF contra el sistema europeo VIES. Devuelve 1 si es correcto, 0 si no lo es.

=head1 AUTHOR

Harun Delgado, C<< <hdp at djmania.es> >> L<https://djmania.es>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-es-nif at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-ES-NIF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::ES::NIF

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-ES-NIF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-ES-NIF>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-ES-NIF/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

H <>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by H.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
