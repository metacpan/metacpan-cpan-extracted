package Astro::Corlate;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::Corlate

#  Purposes:
#    Object orientated interface to Astro::Corlate::Wrapper module

#  Language:
#    Perl module

#  Description:
#    This module is an object-orientated interface to the 
#    Astro::Corlate::Wrapper module, which in turn wraps the
#    Fortran 95 CORLATE sub-routine

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Corlate.pm,v 1.6 2002/03/31 21:58:20 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Corlate - Object a catalog corelation

=head1 SYNOPSIS

  use Astro::Corlate;
  
  $corlate = new Astro::Corlate( Reference   =>  $catalogue,
                                 Observation =>  $observation );

  # run the corelation routine
  $corlate->run_corrlate();
  
  # get the log file
  my $log = $corlate->logfile();
  
  # get the variable star catalogue
  my $variables = $corlate->variables();
  
  # fitted colour data catalogue
  my $data = $corlate->data();
  
  # fit to the colour data
  my $fit = $corlate->fit();
  
  # get probability histogram file
  my $histogram = $corlate->histogram();
  
  # get the useful information file
  my $information = $corlate->information();

=head1 DESCRIPTION

This module is an object-orientated interface to the Astro::Corlate::Wrapper
module, which in turn wraps the Fortran 95 CORLATE sub-routine. It will save
returned files into the ESTAR_DATA directory or to TMP if the ESTAR_DATA
environment variable is not defined.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::Corlate::Wrapper qw / corlate /;
use File::Spec;
use Carp;

'$Revision: 1.6 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Corlate.pm,v 1.6 2002/03/31 21:58:20 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::Corlate( Reference   =>  $catalogue,
                               Observation =>  $observation );

returns a reference to an Corlate object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { DATADIR => undef,
                      FILES   => {} }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# R U N  M E T H O D --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<run_corlate>

Runs the catalog corelation subroutine

   $corlate->run_corlate();

=cut

sub run_corlate {
  my $self = shift;

  # Check that the reference catalogue files has been supplied
  unless ( defined ${$self->{FILES}}{"reference"} ) {
     croak( "Error: No reference catalogue supplied" );
  }
  
  # Check that the observation catalogue files has been supplied
  unless ( defined ${$self->{FILES}}{"observation"} ) { 
     croak( "Error: No observation catalogue supplied" );
  }
   
  # declare status
  my $status;
                     
  # call the corlate sub-routine
  eval {
    $status = corlate( ${$self->{FILES}}{reference},
                       ${$self->{FILES}}{observation}, 
                       ${$self->{FILES}}{logfile}, 
                       ${$self->{FILES}}{variables}, 
                       ${$self->{FILES}}{data}, 
                       ${$self->{FILES}}{fit}, 
                       ${$self->{FILES}}{histogram}, 
                       ${$self->{FILES}}{information} );
  };
  
  # check for errors                   
  if($@) {
     print "$@\n";
     croak ( "Error: Unknown error running catalogue corelation" );
  }
  
  # Run through possible status values                      
  if ( $status == -1 ) {
     croak ( "Error: Failed to open reference catalogue file" );
  } elsif ( $status == -2 ) {
     croak ( "Error: Failed to open observation catalogue file" );
  } elsif ( $status == -3 ) {
     croak ( "Error: Too few stars paired between catalogues" );
  }  
   
  # Should have good status? 
  return $status;                      
}

# O T H E R   M E T H O D S ------------------------------------------------

=item B<Reference>

Sets (or returns) the file name of the reference catalogue

   $file_name = $corlate->reference( );
   $corlate->reference( $file_name );

this catalogue file should be in CLUSTER format.

=cut

sub reference {
  my $self = shift;

  if (@_) { 
    ${$self->{FILES}}{"reference"} = shift;
  }
  
  return ${$self->{FILES}}{"reference"};
}

=item B<Observation>

Sets (or returns) the file name of the new observation catalogue

   $file_name = $corlate->observation( );
   $corlate->observation( $file_name );

this catalogue file should be in CLUSTER format.

=cut

sub observation {
  my $self = shift;

  if (@_) { 
    ${$self->{FILES}}{"observation"} = shift;
  }
  
  return ${$self->{FILES}}{"observation"};
}

=item B<Logfile>

Returns the full path to the Corlate log file

   $file_name = $corlate->logfile( );

=cut

sub logfile { 
  my $self = shift; 

  if (@_) { 
    ${$self->{FILES}}{"logfile"} = shift;
  }
    
  return ${$self->{FILES}}{"logfile"}; 
}

=item B<Variables>

Returns the full path to the variable star catalogue file

   $file_name = $corlate->variables( );

=cut

sub variables { 
   my $self = shift; 

  if (@_) { 
    ${$self->{FILES}}{"variables"} = shift;
  }   
   
   return ${$self->{FILES}}{"variables"}; 
 }

=item B<Data>

Returns the full path to the catalogue file containing the fitted colour data

   $file_name = $corlate->data( );

=cut

sub data { 
   my $self = shift; 

  if (@_) { 
    ${$self->{FILES}}{"data"} = shift;
  }     
   return ${$self->{FILES}}{"data"}; 
}

=item B<Fit>

Returns the full path to the X-Y file defining the fit to the colour data

   $file_name = $corlate->fit( );

=cut

sub fit { 
   my $self = shift; 
 
  if (@_) { 
    ${$self->{FILES}}{"fit"} = shift;
  }   
   
   return ${$self->{FILES}}{"fit"}; 
}

=item B<Histogram>

Returns the full path to the X-Y data file of the probability histogram

   $file_name = $corlate->histogram( );

=cut

sub histogram { 
   my $self = shift; 
  
  if (@_) { 
    ${$self->{FILES}}{"histogram"} = shift;
  }     
   
   return ${$self->{FILES}}{"histogram"}; 
}

=item B<Information>

Returns the full path to the Corlate useful information file

   $file_name = $corlate->information( );

=cut

sub information { 
   my $self = shift; 
  
  if (@_) { 
    ${$self->{FILES}}{"information"} = shift;
  }     
    
   return ${$self->{FILES}}{"information"}; 
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $corlate->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # CONFIGURE DEFAULTS
  # ------------------
  
  # Grab something for DATA directory
  if ( defined $ENV{"ESTAR_DATA"} ) {
     if ( opendir (DIR, File::Spec->catdir($ENV{"ESTAR_DATA"}) ) ) {
        # default to the ESTAR_DATA directory
        $self->{DATADIR} = File::Spec->catdir($ENV{"ESTAR_DATA"});
        closedir DIR;
     } else {
        # Shouldn't happen?
       croak("Cannot open $ENV{ESTAR_DATA} for incoming files.");
     }        
  } elsif ( opendir(TMP, File::Spec->tmpdir() ) ) {
        # fall back on the /tmp directory
        $self->{DATADIR} = File::Spec->tmpdir();
        closedir TMP;
  } else {
     # Shouldn't happen?
     croak("Cannot open any directory for incoming files.");
  }     
  
  # DEFAULT FILENAMES
  ${$self->{FILES}}{"reference"} = 
             File::Spec->catfile( $self->{DATADIR}, 'reference.cat' );
  ${$self->{FILES}}{"observation"} = 
             File::Spec->catfile( $self->{DATADIR}, 'observation.cat' );
  ${$self->{FILES}}{"logfile"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate_log.log' ); 
  ${$self->{FILES}}{"variables"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate_var.cat' ); 
  ${$self->{FILES}}{"data"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate_fit.cat' );
  ${$self->{FILES}}{"fit"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate_fit.fit' );
  ${$self->{FILES}}{"histogram"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate_hist.dat' ); 
  ${$self->{FILES}}{"information"} = 
             File::Spec->catfile( $self->{DATADIR}, 'corlate_info.dat' );       

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Reference Observation / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# L A S T  O R D E R S ------------------------------------------------------

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# T I M E   A T   T H E   B A R  --------------------------------------------

1;                                                                  

__END__
