package Astro::Aladin;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::Aladin

#  Purposes:
#    High level Perl class designed to access images and catalogues
#    available using the CDS Aladin Application

#  Language:
#    Perl module

#  Description:
#    This module gives a high level interface to images and catalogues
#    available using the CDS Aladin Application. It sits ontop of the
#    Astro::Aladin::LowLevel module which drives Aladin directly
#    through an anonymous pipe. You should use this module for access 
#    to resources rather than the lower level.


#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Aladin.pm,v 1.3 2003/02/26 19:21:37 aa Exp $

#  Copyright:
#     Copyright (C) 2003 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Aladin - Perl class giving access to images and catalogues

=head1 SYNOPSIS

  my $aladin = new Astro::Aladin();
  
  my $aladin = new Astro::Aladin( RA     => $ra, 
                                  Dec    => $dec, 
                                  Radius => $radius );

An instance my be created using the default constructor, or using 
one that defines an R.A., Dec and Radius for future queries.

=head1 DESCRIPTION

This module gives a high level interface to images and catalogues
available using the CDS Aladin Application. It sits ontop of the
Astro::Aladin::LowLevel module which drives Aladin directly
through an anonymous pipe. You should use this module for access 
to resources rather than the lower level.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use 5.7.3;

use strict;
use vars qw/ $VERSION /;

use File::Spec;
use POSIX qw/sys_wait_h/;
use Errno qw/EAGAIN/;
use Carp;
use threads;
use threads::shared;
use Astro::Aladin::LowLevel;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# Check for threading
#use Config;
#print "Config: useithreads = " . $Config{'useithreads'} . "\n";
#print "Config: threads::shared loaded\n" if($threads::shared::threads_shared);


# A N O N Y M O U S   S U B R O U T I N E S ---------------------------------

my $threaded_supercos_catalog = sub {
    my ( $ra, $dec, $radius, $band, $file ) = @_;
  
    # create a lowlevel object
    my $aladin = new Astro::Aladin::LowLevel( );

    # grab waveband
    my $waveband = undef;
    if( $band eq "UKST Red" ) {
       $waveband = "2";  
    } elsif ( $band eq "UKST Infrared" ) {
       $waveband = "3";  
    } elsif ( $band eq "ESO Red" ) {
       $waveband = "4";  
    } elsif ( $band eq "POSS-I Red" ) {
       $waveband = "5";  
    } else {
       $waveband = "1"; # Go with default, UKST Blue (Bj)  
    }
    
    # grab catalogue
    $aladin->get( "SSS.cat", [$waveband], "$ra $dec", $radius );
    $aladin->sync();
    $aladin->status();
    $aladin->export( 1, $file );
    $aladin->close();

    return $file;
  
};

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Aladin.pm,v 1.3 2003/02/26 19:21:37 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $aladin = new Astro::Aladin( %options );

returns a reference to an Aladin object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { RA     => undef,
                      DEC    => undef,
                      RADIUS => undef,
                      BAND   => undef,
                      FIlE   => undef }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# Q U E R Y  M E T H O D S ------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<RA>

Return (or set) the current target R.A. defined for future Aladin queries

   $ra = $aladin->ra();
   $aladin->ra( $ra );

where $ra should be a string of the form "HH MM SS.SS", e.g. 21 42 42.66

=cut

sub ra {
  my $self = shift;

  # SETTING R.A.
  if (@_) { 
    # grab the new R.A.
    $self->{RA} = shift;
  }
  
  return $self->{RA};
}

=item B<Dec>

Return (or set) the current target Declination defined for future
Aladin queries

   $dec = $aladin->dec();
   $dss->aladin( $dec );

where $dec should be a string of the form "+-HH MM SS.SS", e.g. +43 35 09.5
or -40 25 67.89

=cut

sub dec { 
  my $self = shift;

  # SETTING DEC
  if (@_) { 
    # grab the new Dec
    $self->{DEC} = shift;
  }

  return $self->{DEC};

}

=item B<Radius>

Return (or set) a default radius (in arcminutes) for future Aladin queries

   $radius = $aladin->radius();
   $aladin->radius( 20 );

=cut

sub radius {
  my $self = shift;

  if (@_) { 
    $self->{RADIUS} = shift;
  }
  
  return $self->{RADIUS};

}

=item B<Band>

Return (or set) a default waveband for future Aladin queries

   $waveband = $aladin->band();
   $aladin->band( $waveband );

this is only really useful for repetative queries using the same 
catalogue or image server. Valid choices for the waveband are 
"UKST Blue", "UKST Red", "UKST Infrared", "ESO Red" and "POSS-I Red".

=cut

sub band {
  my $self = shift;

  if (@_) { 
    $self->{BAND} = shift;
  }
  
  return $self->{BAND};

}

=item B<File>

Return (or set) a default file name to save retrieved catalogues or
images to

   $filename = $aladin->file();
   $aladin->file( $filename );

=cut

sub file {
  my $self = shift;

  if (@_) { 
    $self->{FILE} = File::Spec->catfile( shift );
  }
  
  return $self->{FILE};

}

=item B<supercos_catalog>

Retrieves a SuperCOSMOS catalogue from Edinburgh using Aladin.

   $filename = $aladin->supercos_catalog( 
                       RA     => $ra, 
                       Dec    => $dec, 
                       Radius => $radius,
                       File   => $catalog_file,
                       Band   => $waveband );
   
   $filename = $aladin->supercos_catalog();
   
where the RA and Dec are in standard sextuple format and the radius 
is in arc minutes. Valid choices for the waveband are "UKST Blue", 
"UKST Red", "UKST Infrared", "ESO Red" and "POSS-I Red".

The routine returns the filename of the retrieved catalogue, or
undef is there has been an error. It is possiblle that the Aladin
retrevial dies without returning results, leaving a corrupt, empty
or nonexistant results file. Existance and readability of the
returned file should always be checked when calling this method.

=cut

sub supercos_catalog {
  my $self = shift;
  
  # return unless we have arguements
  return undef unless @_;

  my %args = @_;
  
  # Loop over the allowed keys and modify the default query options
  for my $key (qw / RA Dec Radius Band File/ ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }  
  
  # Check query parameters
  my $ra = $self->{RA};
  my $dec = $self->{DEC};
  my $radius = $self->{RADIUS};
  my $band = $self->{BAND};
  my $file = $self->{FILE};

  # return undef if we're missing stuff
  return undef unless ( $ra && $dec && $radius && $band && $file );

  my $status = "bibble";

  share( $ra );
  share( $dec );
  share( $radius );
  share( $band );
  share( $file );
  share( $status );

  my $supercos_thread = threads->create( sub { 
  
     $status = &$threaded_supercos_catalog( $ra, $dec, $radius, $band, $file ); 
  });   
  
  # wait for the supercos thread to join
  $supercos_thread->join();
  
  # return the status, with luck this will be set to $file, however
  # if we get an error (and sucessfully pick up on it) it will be undef
  return $status;
  
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object

Configures the object, takes an options hash as an argument

  $aladin->configure( %options);

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;
  

  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;
  
  # configure the default options
  $self->{RA}     = undef;
  $self->{DEC}    = undef;
  $self->{RADIUS} = 10;
  $self->{BAND}   = undef;
  $self->{FILE}   = undef;
  
  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / RA Dec Radius Band File / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }  

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2003 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
