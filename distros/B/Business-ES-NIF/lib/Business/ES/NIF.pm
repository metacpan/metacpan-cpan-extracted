package Business::ES::NIF;

=head1 NAME

 Business::ES::NIF - Validate Spanish NIF, NIE and CIF numbers

=cut

our $VERSION = '0.09';

use strict;
use warnings;

=head1 SYNOPSIS

    use Business::ES::NIF;

    my $NIF = Business::ES::NIF->new( nif => '01234567L' , vies => 0);

    $NIF->set('B01234567');
    $NIF->set('B01234567',1); <= Check VIES ( Business::Tax::VAT::Validation )

 Dump:

    $VAR1 = bless( {
                 'status' => 1,
                 'nif' => '01234567L',
                 'vies' => 0,
                 'extra' => 'NIF',
                 'type' => 'NIF',
               }, 'NIF' );

    $VAR1 = bless( {
                 'status' => 0,
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

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=cut 

use constant {
	      NIF_LETRAS => 'TRWAGMYFPDXBNJZSQVHLCKE',
	      CIF_LETRAS => 'JABCDEFGHI'
	     };

my %PROVINCIA_CODES = (
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
		       '99' => 'Zaragoza',
		      );

my $Types = {
	     CIF => {
                     re => qr/^[ABCDEFGHJPQRUVNW][0-9]{8}$/,
                     val => sub {
                       shift =~ /^([ABCDEFGHJPQRUVNW])([0-9]{7})([0-9])$/x;
                       return _validate_cif($1,$2,$3);
                     },
                     extra => sub {
                       my $cif = shift;
                       my $Tipos = {
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
                                    'W' => 'Establecimientos permanentes de entidades no residentes en España',
                                   };
		       
                       $cif =~ /^([ABCDEFGHJPQRUVNW])[0-9]{7}[0-9]$/x;
                       
                       return $Tipos->{$1};
                     }
                    },
	     CIFe => {
		      re  => qr/^[SQPK][0-9]{7}[A-J]$/,
		      val => sub {
			shift =~ /^([SQPK])([0-9]{7})([A-J])$/x;
			return _validate_cif($1,$2,$3);
		      },
		      extra => sub {
			my $cif = shift;
			my $Tipos = {
				     'S' => 'Organos de administracion del estado',
				     'Q' => 'Organismos autónomos, estatales o no, y asimilados, y congregaciones e instituciones religiosas',
				     'P' => 'Corporaciones locales.',
				     'K' => 'Formato antiguo orden EHA/451/2008',
				    };
			
			$cif =~ /^([SQPK])[0-9]{7}[A-J]$/x;
			
			return $Tipos->{$1};
		      }
		     },
	     NIF => {
                     re    => qr/^[0-9]{8}[A-Z]$/,
                     val   => sub { return _validate_nif(shift); },
                     extra => sub { return 'NIF'; }
                    },
	     NIE => {
		     re    => qr/^[XYZ][0-9]{7}[A-Z]$/,
		     val   => sub { return _validate_nie(shift); },
		     extra => sub { return 'NIE'; }
		    }
};

sub _cif_provincia {
  my $cif = shift;
    
  # Validar entrada
  return unless defined $cif;
    
  # Extraer código de provincia (posiciones 1-2, base 0)
  my $provincia = substr($cif, 1, 2);
    
  # Validar que son dígitos
  return unless $provincia =~ /^[0-9]{2}$/;
    
  # Buscar provincia
  return $PROVINCIA_CODES{$provincia};
}

sub _validate_cif {
  my ($sociedad, $inscripcion, $control) = (shift,shift,shift);

  my @n = split //, $inscripcion;
  my $pares = $n[1] + $n[3] + $n[5];
  my $nones;

  for (0, 2, 4, 6) {
    my $d   = $n[$_] * 2;
    $nones += $d < 10 ? $d : $d - 9;
  }

  my $c = (10 - substr($pares + $nones, -1)) % 10;
  my $l = substr(CIF_LETRAS, $c, 1);
  
  for ($sociedad) {
    if (/[KPQS]/i) {
      return 0 if $l ne uc($control);
    }else {
      return 0 if $c != $control and $l ne uc($control);
    }
  }
  
  return 1;
}

sub _validate_nif {
  shift =~ /^([0-9]{8})([A-Z])$/x;

  my ($NIF,$DC) = ($1,$2);
  my $L = substr( NIF_LETRAS , $NIF % 23, 1);

  return $L eq $DC ? 1 : 0;
}

sub _validate_nie {
  shift =~ /^([XYZ])([0-9]{7})([A-Z])$/x;
                       
  my ($NIE,$NIF,$DC) = ($1,$2,$3);
                       
  for ($NIE) {
    $NIF = '0'.$NIF if /X/;
    $NIF = '1'.$NIF if /Y/;
    $NIF = '2'.$NIF if /Z/;
  }
  
  my $L = substr( NIF_LETRAS , $NIF % 23, 1);

  return $L eq $DC ? 1 : 0;
}

=head2 new

    new method

=cut

sub new {
  my ($class, %args) = @_;

  my $self = {
	      nif => '',
	      status => 0,
	      vies => $args{vies} // 0,
	     };
  
  $self = bless $self, $class;

  $self->set($args{nif}) if defined $args{nif};
  
  return $self;
}

=head2 set

    Set NIF
    $vies = 1 || 0

=cut

sub set {
  my $self = shift;
  my $nif  = shift;
  my $vies = shift // 0;

  $self->{vies} = $vies if $vies;

  unless (defined $nif) {
    $self->{status} = 0;
    $self->{error} = "NIF vacío";
    return;
  }

  $nif =~ s/[-\.\s]//g;
  $self->{nif} = uc $nif;
  
  delete $self->{nif_check} if $self->{nif_check};

  $self->check();
}

=head2 is_valid

=cut

sub is_valid { return shift->{status} ? 1 : 0; }

=head2 check

=cut

sub check {
  my $self = shift;
  
  for my $type (keys %{ $Types }) {
    if ( $self->{nif} =~ $Types->{$type}->{re} ) {
      
      $self->{type}   = $type;
      $self->{status} = $Types->{$type}->{val}->($self->{nif});
      $self->{extra}  = $Types->{$type}->{extra}->($self->{nif});
      
      $self->{nif_check} = $Types->{NIF}->{val}->($self->{nif},1)
	if $self->{status} == 0 && $self->{type} eq 'NIF';

      $self->{provincia} = _cif_provincia($self->{nif}) if $self->{type} eq 'CIF';

      $self->vies() if $self->{vies};

      return;
    }
  }
  
  $self->{error} = "Error formato de NIF/CIF/NIE";
  $self->{type}  = 'ERROR';
}

=head2 vies

=cut

sub vies {
  my $self = shift;
  
  unless ($self->{status}) {
    $self->{vies_error} = "No se puede validar VIES: NIF no es válido";
    $self->{vies_check} = 0;
    return 0;
  }
  
  unless (defined $self->{nif} && length($self->{nif}) > 0) {
    $self->{vies_error} = "No hay NIF para validar en VIES";
    $self->{vies_check} = 0;
    return 0;
  }
  
  eval {
    require Business::Tax::VAT::Validation;
    
    my $vat = Business::Tax::VAT::Validation->new();
    
    unless ($vat) {
      die "Error Business::Tax::VAT::Validation";
    }
    
    $self->{vies_check} = $vat->check('ES' . $self->{nif});
    
    unless ($self->{vies_check}) {
      $self->{vies_error} = $vat->get_last_error() // 'Error desconocido en VIES';
    }
  };
  
  if ($@) {
    $self->{vies_error} = "Error cargando validación VIES: $@";
    $self->{vies_check} = 0;
  }
  
  return $self->{vies_check} // 0;
}

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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-ES-NIF>

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


=cut

1;
