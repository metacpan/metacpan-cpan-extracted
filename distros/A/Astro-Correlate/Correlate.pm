package Astro::Correlate;

=head1 NAME

Astro::Correlate - Class for cross-correlating astronomical catalogues.

=head1 SYNOPSIS

  use Astro::Correlate;

  my $corr = new Astro::Correlate( catalog1 => $cat1,
                                   catalog2 => $cat2,
                                   method => 'FINDOFF' );

  $result = $corr->correlate;

=head1 DESCRIPTION

Class for cross-correlating astronomical catalogues.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;
use File::Temp qw/ tempdir /;

our $VERSION = '1.0';

=head1 METHODS

=head2 CONSTRUCTOR

=over 4

=item B<new>

Create a new instance of an C<Astro::Correlate> object.

  $corr = new Astro::Correlate( catalog1 => $cat1,
                                catalog2 => $cat2 );

The two mandatory named arguments must be defined and must be
C<Astro::Catalog> objects. Both catalogs must be comparable --
the C<Astro::Catalog::Star> objects in those catalogs must have
x/y or RA/Dec defined, or be able to calculate one from the other
using a C<Starlink::AST> FrameSet.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my %args = @_;

  if( ! defined( $args{'catalog1'} ) ||
      ! UNIVERSAL::isa( $args{'catalog1'}, "Astro::Catalog" ) ||
      ! defined( $args{'catalog2'} ) ||
      ! UNIVERSAL::isa( $args{'catalog2'}, "Astro::Catalog" ) ) {
    croak "Must supply two Astro::Catalog objects to Astro::Correlate constructor.\n";
  }

  # Create the object.
  my $corr = {};
  bless( $corr, $class );

  # Configure the object.
  $corr->_configure( \%args );

  # Set up default options.
  $corr->keeptemps( 0 ) if ( ! defined( $corr->keeptemps ) );
  $corr->messages( 0 ) if ( ! defined( $corr->messages ) );
  $corr->timeout( 60 ) if ( ! defined( $corr->timeout ) );
  $corr->temp( tempdir( CLEANUP => ( ! $corr->keeptemps ) ) ) if ( ! defined( $corr->temp ) );

  # And return the object.
  return $corr;
}

=back

=head2 Accessor Methods

=over 4

=item B<catalog1>

Return or set the first catalogue used for correlation.

  my $catalog = $corr->catalog1;
  $corr->catalog1( $catalog );

Returns an C<Astro::Catalog> object.

=cut

sub catalog1 {
  my $self = shift;
  if( @_ ) {
    my $cat = shift;
    if( UNIVERSAL::isa( $cat, "Astro::Catalog" ) ) {
      $self->{CATALOG1} = $cat;
    }
  }
  return $self->{CATALOG1};
}

=item B<catalog2>

Return or set the second catalogue used for correlation.

  my $catalog = $corr->catalog2;
  $corr->catalog2( $catalog );

Returns an C<Astro::Catalog> object.

=cut

sub catalog2 {
  my $self = shift;
  if( @_ ) {
    my $cat = shift;
    if( UNIVERSAL::isa( $cat, "Astro::Catalog" ) ) {
      $self->{CATALOG2} = $cat;
    }
  }
  return $self->{CATALOG2};
}

=item B<cat1magtype>

The magnitude type to use for the first catalogue.

  my $magtype = $corr->cat1magtype;
  $corr->cat1magtype( 'mag_iso' );

This is used for Astro::Catalog::Item objects that have Astro::Flux
measurements that are not standard magnitudes, and for correlation
methods that require a measure of object brightness for optimizations
like the RITMatch method. If this is not defined, it will default to
'mag'.

=cut

sub cat1magtype {
  my $self = shift;
  if( @_ ) {
    my $magtype = shift;
    $self->{CAT1MAGTYPE} = $magtype;
  }
  return $self->{CAT1MAGTYPE};
}

=item B<cat2magtype>

The magnitude type to use for the second catalogue.

  my $magtype = $corr->cat2magtype;
  $corr->cat2magtype( 'mag_iso' );

As for cat1magtype(), but for the second catalogue.

=cut

sub cat2magtype {
  my $self = shift;
  if( @_ ) {
    my $magtype = shift;
    $self->{CAT2MAGTYPE} = $magtype;
  }
  return $self->{CAT2MAGTYPE};
}

=item B<keeptemps>

Whether or not to keep temporary files after processing is completed.

  my $keeptemps = $corr->keeptemps;
  $corr->keeptemps( 1 );

Temporary files are created in a temporary directory that is reported
during execution. The location of this temporary directory can be
controlled using the C<tempdir> method.

This parameter defaults to false, so all temporary files are deleted
after processing.

=cut

sub keeptemps {
  my $self = shift;
  if( @_ ) {
    my $keeptemps = shift;
    $self->{KEEPTEMPS} = $keeptemps;
  }
  return $self->{KEEPTEMPS};
}

=item B<messages>

Whether or not to display messages from the correlation task while
processing.

  my $messages = $corr->messages;
  $corr->messages( 1 );

If set to true, then messages from the correlation task will be
printed.

Defaults to false.

=cut

sub messages {
  my $self = shift;
  if( @_ ) {
    my $messages = shift;
    $self->{MESSAGES} = $messages;
  }
  return $self->{MESSAGES};
}

=item B<method>

Retrieve or set the method to be used for correlation.

  my $method = $corr->method;
  $corr->method( 'FINDOFF' );

The method is case-sensitive.

=cut

sub method {
  my $self = shift;
  if( @_ ) {
    my $method = shift;
    $self->{METHOD} = $method;
  }
  return $self->{METHOD};
}

=item B<temp>

Retrieve or set the directory to be used for temporary files.

  my $temp = $corr->temp;
  $corr->temp( '/tmp' );

If undef (which is the default), a temporary directory will be
created using C<File::Temp>.

=cut

sub temp {
  my $self = shift;
  if( @_ ) {
    my $temp = shift;
    $self->{TEMP} = $temp;
  }
  if( ! defined( $self->{TEMP} ) ) {
    $self->{TEMP} = tempdir( CLEANUP => ( defined( $self->keeptemps )
                                          ? ! $self->keeptemps
                                          : 1 ) );
  }
  return $self->{TEMP};
}

=item B<timeout>

Retrieve or set the timeout.

  my $timeout = $corr->timeout;
  $corr->timeout( 120 );

Time is in seconds and defaults to 60.

=cut

sub timeout {
  my $self = shift;
  if( @_ ) {
    my $timeout = shift;
    $self->{TIMEOUT} = $timeout;
  }
  return $self->{TIMEOUT};
}

=item B<verbose>

Retrieve or set the verbosity level.

  my $verbose = $corr->verbose;
  $corr->verbose( 1 );

If set to true, then much output will be output to STD_ERR. Defaults to false.

=cut

sub verbose {
  my $self = shift;
  if( @_ ) {
    my $verbose = shift;
    $self->{VERBOSE} = $verbose;
  }
  return $self->{VERBOSE};
}

=back

=head2 General Methods

=over 4

=item B<correlate>

Cross-correlates two catalogues using the supplied method.

  ( $corrcat1, $corrcat2 ) = $corr->correlate;

This method returns two catalogues, both containing stars that matched
in the two catalogues passed to the constructor. The returned catalogues
are C<Astro::Catalog> objects, and each matched C<Astro::Catalog::Star>
object has the same ID number in either catalogue.

=cut

sub correlate {
  my $self = shift;

  if( ! defined( $self->method ) ) {
    croak "Must supply cross-correlation method";
  }

  # Find out what the cross-correlation class is called.
  my $corrclass = _load_corr_plugin( $self->method );
  if( ! defined( $corrclass ) ) {
    croak "Could not load cross-correlation method class for " . $self->method . " method";
  }

  # Set up the correlated catalogues.
  my $corrcat1;
  my $corrcat2;

  # And do the correlation.
  ( $corrcat1, $corrcat2 ) = $corrclass->correlate( catalog1 => $self->catalog1,
                                                    catalog2 => $self->catalog2,
                                                    cat1magtype => $self->cat1magtype,
                                                    cat2magtype => $self->cat2magtype,
                                                    keeptemps => $self->keeptemps,
                                                    messages => $self->messages,
                                                    temp => $self->temp,
                                                    timeout => $self->timeout,
                                                    verbose => $self->verbose );

  # Return the correlated catalogues;
  return( $corrcat1, $corrcat2 );
}

=back

=begin __PRIVATE_METHODS__

=head2 Private Methods

The following methods are private to the module.

=over 4

=item B<_configure>

Configures the object.

  $auto->_configure( $args );

Takes one argument, a hash reference. The hash contains key/value pairs
that correspond to the various accessor methods of this module.

=cut

sub _configure {
  my $self = shift;
  my $args = shift;

  foreach my $key ( keys %$args ) {
    if( $self->can( $key ) ) {
      $self->$key( $args->{$key} );
    }
  }
}

=item B<_load_corr_plugin>

Loads a correlation plugin module.

  $class = _load_corr_plugin( $method );

Returns the class name on successful load. If the class cannot be
found or loaded, issues a warning and returns undef.

=cut

sub _load_corr_plugin {
  my $method = shift;

  # Set the class name.
  my $class = "Astro::Correlate::Method::$method";

  # Eval the class to see if it loads, issuing a warning
  # if it fails.
  eval "use $class;";
  if( $@ ) {
    warnings::warnif( "Error loading correlation plugin module $class: $@" );
    return undef;
  }

  return $class;
}

=back

=end __PRIVATE_METHODS__

=head1 REVISION

$Id$

=head1 AUTHORS

Brad Cavanagh <brad.cavanagh@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
