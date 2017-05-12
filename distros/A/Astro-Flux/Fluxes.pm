package Astro::Fluxes;

=head1 NAME

Astro::Fluxes - Class for handling a collection of astronomical flux
quantities.

=head1 SYNOPSIS

  use Astro::Fluxes;

  $fluxes = new Astro::Fluxes( $flux1, $flux2, $color1 );

  my $flux = $fluxes->flux( waveband => $waveband );

=head1 DESCRIPTION

Class for handling a collection of astronomical flux quantities.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use Astro::Flux;
use Astro::FluxColor;
use Astro::WaveBand;
use Misc::Quality;
use Storable qw/ dclone /;

our $VERSION = '0.01';



=head1 METHODS

=head2 CONSTRUCTOR

=over 4

=item B<new>

Create a new instance of an C<Astro::Fluxes> object.

  $fluxes = new Astro::Fluxes( $flux1, $flux2, $color1 );

Any number of C<Astro::Flux> or C<Astro::FluxColor> objects can
be passed as arguments.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $block = bless { FLUXES => {},
                      FLUX   => [],
		      COLOR  => [] }, $class;
		      

  $block = $block->pushfluxes( @_ ) if @_;
  return $block;

}

=back

=head2 Accessor Methods

=over 4

=item B<flux>

Returns the flux for a requested waveband.

  my $flux = $fluxes->flux( waveband => 'J' );

Arguments are passed as key-value pairs. The sole mandatory named
argument is 'waveband'; its value can either be an C<Astro::WaveBand>
object or a string that can be used to create a new C<Astro::WaveBand>
via its Filter parameter.

Optional arguments are:

  derived - Whether or not to return fluxes that have been derived
    from colors. Defaults to false, so that derived fluxes will not
    be returned.

  datetime - whether we should return a flux from a specified object,
    should be passed as a C<DateTime> object.

  type - which type of flux to return. If this is not given this method
    will default to 'mag'. If you supply a type that is not
    'mag' or 'magnitudes' and are attempting to return a derived flux,
    this method will return undef.

This method returns an C<Astro::Flux> object.

=cut

sub flux {
  my $self = shift;
  my %args = @_;

  my $result;

  if( ! defined( $args{'waveband'} ) ) {
    croak "waveband argument must be passed to &Astro::Fluxes::flux";
  }

  my $waveband = $args{'waveband'};
  my $derived = defined( $args{'derived'} ) ? $args{'derived'} : 0;

  if( ! UNIVERSAL::isa( $waveband, "Astro::WaveBand" ) ) {
    # Upgrade to a proper Astro::WaveBand object.
    $waveband = new Astro::WaveBand( Filter => $waveband );
  }

  my $datetime = $args{'datetime'};
  if ( defined $datetime ) {
     unless ( UNIVERSAL::isa( $datetime, "DateTime" ) ) {
        croak( "Astro::Fluxes::flux() - Time must be a DateTime object\n" );
     }
  }

  my $type = $args{'type'};
  if( ! defined( $args{'type'} ) ) {
    $type = 'mag';
  }

  # The key is the first character in the waveband.
  my $key = $waveband->natural;

  # Check to see if we have a measured magnitude for this waveband.
  foreach my $flux ( @{${$self->{FLUXES}}{$key}} ) {
    if( ! defined( $flux->reference_waveband ) ) {
      if( defined $datetime && defined $flux->datetime ) {
        if( ($datetime <=> $flux->datetime()) == 0 ) {
          if( lc( $type ) eq lc( $flux->type ) ) {
            $result = $flux;
            last;
          }
        }
      } else {
        if( lc( $type ) eq lc( $flux->type ) ) {
          $result = $flux;
          last;
        }
      }
    }
  }

  return $result if defined $result;

  # Return right here with undef if $derived is false.
  return if ( ! $derived );

  # Return right here if we are not looking for a 'mag' or 'magnitude'.
  return if ( $type !~ /^mag/i );

  # Get the reference waveband for the current flux such that the
  # reference waveband doesn't have only a pointer back to the current
  # one.

  my ($ref_flux, $ref_datetime);
  my $running_total = undef;
  my $running_error = undef;
  foreach my $flux ( @{${$self->{FLUXES}}{$key}} ) {
    if( defined( $flux->reference_waveband ) &&
        ( scalar( @{${$self->{FLUXES}}{$flux->reference_waveband->natural}} > 1 ) ||
          ${${$self->{FLUXES}}->{$flux->reference_waveband->natural}}[0]->reference_waveband != $waveband ) ) {
      if ( defined $args{'datetime'} ) {
         if ( defined $flux->datetime ) {
            $running_total += $flux->quantity('mag');
            $running_error += $flux->error('mag')*$flux->error('mag');
            $ref_flux = ${${$self->{FLUXES}}->{$flux->reference_waveband->natural}}[0];
	    $ref_datetime = $flux->datetime();
            last;
	 }   
      } else {
         $running_total += $flux->quantity('mag');
         $running_error += $flux->error('mag')*$flux->error('mag');
         $ref_flux = ${${$self->{FLUXES}}{$flux->reference_waveband->natural}}[0];
         last;
      }	          
    }
  }

  # If we have a reference flux, get the magnitude from that waveband and add
  # it to the running total.
  if( defined( $ref_flux ) ) {
    my $mag = $self->flux( waveband => $ref_flux->waveband, derived => 1 )->quantity('mag');
    my $err = $self->flux( waveband => $ref_flux->waveband, derived => 1 )->error('mag');
    if ( defined $args{'datetime'} ) {
       if ( defined $ref_datetime ) {
          $running_total += $mag;
          $running_error += $err if defined $err;
       }
    } else {
       $running_total += $mag;
       $running_error += $err if defined $err;  
    }   	       
  }

  $running_error = sqrt( $running_error ) if defined $running_error;
  
  # Form a flux object with the running total and the input waveband,
  # and return that.
  if( ! defined( $running_total ) ) {
    return undef;
  } else {
    my $number;
    if ( defined $running_error ) {
       $number = new Number::Uncertainty( Value => $running_total,
                                          Error => $running_error );
    } else {
       $number = $running_total;
    }
       					  
    if ( defined $args{'datetime'} ) {
       my $returned_flux = new Astro::Flux( $number, 'mag', $waveband, 
                            quality => new Misc::Quality( derived => 1 ),
			    datetime => $ref_datetime );
       return $returned_flux;			    
    } else {
       my $returned_flux = new Astro::Flux( $number, 'mag', $waveband, 
                            quality => new Misc::Quality( derived => 1 ) );			    
       return $returned_flux;
    } 			    
  }
  
}

=item B<color>

Returns the color for two requested wavebands.

my $color = $fluxes->color( upper => new Astro::WaveBand( Filter => 'H' ),
                            lower => new Astro::WaveBand( Filter => 'J' ) );

my $color = $fluxes->color( upper => new Astro::WaveBand( Filter => 'H' ),
                            lower => new Astro::WaveBand( Filter => 'J' ),
			    datetime => new DateTime );

Arguments are passed as key-value pairs. The two mandatory named arguments are
'upper' and 'lower', denoting the upper (longer wavelength) and lower (shorter
wavelength) wavebands for the color. The value for either can be either an
C<Astro::WaveBand> object or a string that can be used to create a new
C<Astro::WaveBand> object via its Filter parameter.

The above example will return the first H-K color in the Fluxes object. The 
optional datetime arguement allows you to return a colour at a specific datetime
stamp.

=cut

sub color {
  my $self = shift;
  my %args = @_;

  my $result;

  if( ! defined( $args{'upper'} ) ) {
    croak "upper waveband argument must be passed to &Astro::Fluxes::color";
  }
  if( ! defined( $args{'lower'} ) ) {
    croak "lower waveband argument must be passed to &Astro::Fluxes::color";
  }

  my $upper = $args{'upper'};
  my $lower = $args{'lower'};

  # Upgrade the wavebands to proper Astro::WaveBand objects if necessary.
  if( ! UNIVERSAL::isa( $upper, "Astro::WaveBand" ) ) {
    $upper = new Astro::WaveBand( Filter => $upper );
  }
  if( ! UNIVERSAL::isa( $lower, "Astro::WaveBand" ) ) {
    $lower = new Astro::WaveBand( Filter => $lower );
  }

  # First, find out if we have an easy job. Check if the lower refers to
  # the upper, from which we can get the colour directly.
  my $upper_key = $upper->natural();
  my $lower_key = $lower->natural();
  foreach my $flux ( @{${$self->{FLUXES}}{$lower_key}} ) {
    if( defined( $flux->reference_waveband ) ) {
      
      if ( defined $args{'datetime'} ) {
         next unless defined $flux->datetime;
         if ( ($flux->datetime <=> $args{'datetime'}) != 0 ) {
	    my $datetime = $flux->datetime;
	    next;
         } else {
	   my $datetime = $flux->datetime;
	 }  
      }
      	 
      my $ref_key = $flux->reference_waveband()->natural();
      if( $ref_key eq $upper_key ) {
        
	my $num;
	if ( defined $flux->error('mag') ) {
           $num = new Number::Uncertainty ( Value => $flux->quantity('mag'),
	                                    Error => $flux->error('mag') )
	} else {
           $num = new Number::Uncertainty ( Value => $flux->quantity('mag') );
	}  
	
	if ( defined $flux->datetime() ) { 			    
           my $color = new Astro::FluxColor( lower => $lower,
                                         upper => $upper,
                                         quantity => $num,
				         datetime => $flux->datetime() ); 
	   return $color;				   
	} else {
           my $color = new Astro::FluxColor( lower => $lower,
                                         upper => $upper,
                                         quantity => $num ); 
	   return $color;
	}   									 
      }
    }
  }

  # So we're here. Maybe we can get magnitudes for the upper and lower wavebands.
  my $upper_mag;
  my $lower_mag;
  if ( defined( $args{'datetime'} ) ) {
      $upper_mag = $self->flux( waveband => $upper, derived => 1, 
                                datetime => $args{'datetime'} );
      $lower_mag = $self->flux( waveband => $lower, derived => 1, 
                                datetime => $args{'datetime'} );
  } else {
      $upper_mag = $self->flux( waveband => $upper, derived => 1 );
      $lower_mag = $self->flux( waveband => $lower, derived => 1 );  
  }      
  if( defined( $upper_mag ) && defined( $lower_mag ) ) {
    	       
    my $num;
    my $value = $lower_mag->quantity('mag') - $upper_mag->quantity('mag');
    if ( defined $upper_mag->error('mag') && $lower_mag->error('mag') ) {
       my $error = sqrt( $upper_mag->error('mag')*$upper_mag->error('mag')
                      + $lower_mag->error('mag')*$lower_mag->error('mag') );
       $num = new Number::Uncertainty ( Value => $value,
   				        Error => $error )
    } else {
       $num = new Number::Uncertainty ( Value => $value );
    }  
    if ( defined $lower_mag->datetime() && defined $upper_mag->datetime() ) {			
       my $color = new Astro::FluxColor( lower => $lower,
    				     upper => $upper,
    				     quantity => $num,
    				     datetime => $lower_mag->datetime() ); 
       return $color;				       
    } else {
       my $color = new Astro::FluxColor( lower => $lower,
    				     upper => $upper,
    				     quantity => $num ); 
       return $color;
    }			    
  }

  # At this point I don't really know how to get a colour. If we're here
  # that means we have some kind of colour-colour relation that we might
  # be able to get the desired colour from...

  # Return undef in the meandatetime.
  return undef;

}


=item B<pushfluxes>

Push C<Astro::Flux> and C<Astro::FluxColor> object into the C<Astro::Fluxes>
object,

  $fluxes->pushfluxes( $flux1, $flux2, $color1 );

Any number of C<Astro::Flux> or C<Astro::FluxColor> objects can
be passed as arguments.

=cut

sub pushfluxes {
  my $self = shift;

  foreach my $arg ( @_ ) {
    if( UNIVERSAL::isa( $arg, "Astro::Flux" ) ) {
      my $key = $arg->waveband()->natural();
      push @{${$self->{FLUXES}}{$key}}, $arg;
      push @{$self->{FLUX}}, $arg->waveband();
    } elsif( UNIVERSAL::isa( $arg, "Astro::FluxColor" ) ) {

      # Create an Misc::Quality object saying that these are derived
      # magnitudes.
      my $quality = new Misc::Quality( 'derived' => 1 );

      # Create two flux objects, one for the lower and one for the upper.
      my $num = new Number::Uncertainty( Value => $arg->quantity,
                                         Error => $arg->error );			     
	
      my ( $lower_flux, $upper_flux );					 
      if ( defined $arg->datetime() ) {
         $lower_flux = new Astro::Flux( $num , 'mag', $arg->lower,
        			     quality => $quality,
        			     reference_waveband => $arg->upper,
				     datetime => $arg->datetime );
         $upper_flux = new Astro::Flux( -1.0 * $num, 'mag', $arg->upper,
                                        quality => $quality,
                                        reference_waveband => $arg->lower,
				       datetime => $arg->datetime );
      } else {
         $lower_flux = new Astro::Flux( $num , 'mag', $arg->lower,
        			     quality => $quality,
        			     reference_waveband => $arg->upper );
         $upper_flux = new Astro::Flux( -1.0 * $num, 'mag', $arg->upper,
                                        quality => $quality,
                                        reference_waveband => $arg->lower );      
      }
      my $lower_key = $lower_flux->waveband->natural;
      my $upper_key = $upper_flux->waveband->natural;
      push @{${$self->{FLUXES}}{$lower_key}}, $lower_flux;
      push @{${$self->{FLUXES}}{$upper_key}}, $upper_flux;

      my $color = $arg->upper() . "-" . $arg->lower();
      push @{$self->{COLOR}}, $color;

    }
  }

  return $self;

}

=item B<allfluxes>

Returns an array of all the C<Astro::Flux> objects contained in the
C<Astro::Fluxes> object,

  @fluxes_not_dervied = $fluxes->allfluxes();
  @fluxes_including_dervied = $fluxes->allfluxes( 'derived' );
  
by default this will not return the derived fluxes, however the method
takes an optional arguement of 'derived', in which case it will do.

=cut

sub allfluxes {
  my $self = shift;
  
  my $flag;
  if ( @_ ) {
     my $arg = shift;
     if( $arg eq 'derived' ) {
        $flag = 1;
     }	
  }
     
  my %fluxes = %{$self->{FLUXES}};
  
  my @allfluxes;  
  foreach my $key ( keys %fluxes ) {
      #print "\n KEY = $key \n";
      my $value = $fluxes{$key};
      
      foreach my $i ( 0 ... $#{$value} ) {
 	 my $flux = ${$value}[$i];
     
         # push derived fluxes only if we were asked to...
         my $quality = $flux->quality();
	 my $derived = $quality->query('derived') if defined $quality;
	 #print "  $i, $derived\n";
         if ( defined $derived ) {
	    push @allfluxes, $flux if defined $flag;
	 } else {
	    push @allfluxes, $flux;	
	 }
	 $quality = undef;
	 $derived = undef;     
      }
  }
  return @allfluxes;     
}

=item B<fluxesbywaveband>

Returns an hash of all the C<Astro::Flux> objects contained in the
C<Astro::Fluxes> object,

  @fluxes = $fluxes->fluxesbywaveband(  waveband => 'J' );

=cut

sub fluxesbywaveband {
  my $self = shift;
  my %args = @_;

  my $result;

  if( ! defined( $args{'waveband'} ) ) {
    croak "waveband argument must be passed to &Astro::Fluxes::flux";
  }

  my $waveband = $args{'waveband'};
  my $derived = defined( $args{'derived'} ) ? $args{'derived'} : 0;

  if( ! UNIVERSAL::isa( $waveband, "Astro::WaveBand" ) ) {
    # Upgrade to a proper Astro::WaveBand object.
    $waveband = new Astro::WaveBand( Filter => $waveband );
  }

  # The key is the first character in the waveband.
  my $key = $waveband->natural();
  return @{${$self->{FLUXES}}{$key}};
}


=item B<original_colors>

Returns an array of the original (not derived) colors contained in the object

  @colors = $fluxes->original_colors( );

=cut

sub original_colors {
  my $self = shift;
  return @{$self->{COLOR}};
}

=item B<original_wavebands>

Returns an array of the original (not derived) filters contained in the object

  @wavebands = $fluxes->original_wavebands( );
  @filters = $fluxes->original_wavebands( 'filters' );
  
optional arguement 'filters' returns an actual filter list rather than a list
of C<Astro::WaveBand> objects.

=cut

sub original_wavebands {
  my $self = shift;
  
  return @{$self->{FLUX}} unless @_;
  
  my $arg = shift;
  return undef unless lc($arg) eq 'filters';
  
  my @filters;
  foreach my $band ( @{$self->{FLUX}} ) {
     push @filters, $band->filter();
  }   
  return @filters;   
  
}

=item B<merge>

Merges another C<Astro::Fluxes> object with this object

  $fluxes1->merge( $fluxes2 );

=cut

sub merge {
  my $self = shift;
  my $other = shift;

  croak "Astro::Fluxes::merge() - Not an Astro::Fluxes object\n"
                      unless UNIVERSAL::isa( $other, "Astro::Fluxes" );

  my @fluxes = $other->allfluxes( 'derived' );
  $self->pushfluxes( @fluxes );
}



=item B<datestamp>

Applies a datestamp to all C<Astro::Flux> object with this object

  $fluxes->datestamp( new DateTime );

=cut

sub datestamp {
  my $self = shift;
  my $timestamp = shift;
  
  croak "Astro::Fluxes::datestamp() - Not an DateTime object\n"
                      unless UNIVERSAL::isa( $timestamp, "DateTime" );
  
  
  foreach my $key ( keys %{$self->{FLUXES}} ) {
      foreach my $j ( 0 ... $#{${$self->{FLUXES}}{$key}} ) {
         my $date = dclone( $timestamp );
         ${${$self->{FLUXES}}{$key}}[$j]->datetime( $date );
      }
  }    	 
      
  return %{$self};

}

=back

=head1 REVISION

 $Id: Fluxes.pm,v 1.19 2005/11/15 23:50:32 bradc Exp $

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 - 2005 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
