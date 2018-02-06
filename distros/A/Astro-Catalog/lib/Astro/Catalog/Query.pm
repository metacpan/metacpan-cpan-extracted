package Astro::Catalog::Query;

=head1 NAME

Astro::Catalog::Query - Base class for Astro::Catalog query objects

=head1 SYNOPSIS

  use base qw/ Astro::Catalog::Query /;

=head1 DESCRIPTION

This class forms a base class for all the query classes provided
in the C<Astro::Catalog> distribution (eg C<Astro::Catalog::GSC::Query>).

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

# generic catalog objects
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;
$VERSION = "4.32";

# C O N S T R U C T O R ----------------------------------------------------

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $q = new Astro::Catalog::Query( Coords    => new Astro::Coords(),
                                  Radius    => $radius,
                                  Bright    => $magbright,
                                  Faint     => $magfaint,
                                  Sort      => $sort_type,
                                  Number    => $number_out );

returns a reference to an query object. Must only called from
sub-classed constructors.

RA and Dec are also allowed but are deprecated (since with only
RA/Dec the coordinates must always be supplied as J2000 space-separated
sexagesimal format).

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { OPTIONS   => {},
                      BUFFER    => undef }, $class;

  # Configure the object [even if there are no args]
  $block->configure( @_ );

  return $block;

}

=back

=head2 Accessor Methods

=over 4

=item B<query_options>

Hash representing the query options to be used to query the catalog
server. This keys in this hash are restricted by the subclass. Some
keys are not usable by all catalogues.

Returns a copy of the options hash when.

  %options = $q->query_options();

Note that the hash keys included here are not necessarily the keys
used to form a remote query.

If an argument is supplied, the value for that option is returned
I<if> the option is supported.

  $ra = $q->query_options( "ra" );

Values can not  be set directly. Please use the provided accessor methods.

=cut

sub query_options {
  my $self = shift;
  if (@_) {
    my $opt = lc(shift);
    my %allow = $self->_get_allowed_options;

    if (!exists $allow{$opt}) {
      warnings::warnif("Option $opt not supported by this cataloge");
      return;
    }
    return $self->{OPTIONS}->{$opt};
  }
  return %{ $self->{OPTIONS} };
}


=item B<RA>

Return (or set) the current target R.A. defined for the query

   $ra = $usno->ra();
   $usno->ra( $ra );

where $ra should be a string of the form "HH MM SS.SS", e.g. 21 42 42.66

=cut

sub ra {
  my $self = shift;

  # SETTING R.A.
  if (@_) {
    # grab the new R.A.
    my $ra = shift;
    $self->_set_query_options( ra => $ra );
  }
  # Return it
  return $self->query_options("ra");
}

=item B<Dec>

Return (or set) the current target Declination defined for the query

   $dec = $q->dec();
   $q->dec( $dec );

where $dec should be a string of the form "+-HH MM SS.SS", e.g. +43 35 09.5
or -40 25 67.89

=cut

sub dec {
  my $self = shift;

  # SETTING DEC
  if (@_) {
    # grab the new Dec
    my $dec = shift;
    $self->_set_query_options( dec => $dec );
  }

  return $self->query_options("dec");
}


=item B<Target>

Instead of querying by R.A. and Dec., you may also query it
by object name. Return (or set) the current target object defined for
the USNO-A2.0 query, will query SIMBAD for object name resolution.

   $ident = $usno->target();
   $usno->target( "HT Cas" );

using an object name will override the current R.A. and Dec settings for the
Query object (if currently set) and the next querydb() method call will query
using this identifier rather than any currently set co-ordinates.

=cut

sub target {
  my $self = shift;

  # SETTING IDENTIFIER
  if (@_) {

    # grab the new object name
    my $ident = shift;

    # Need to clear RA and Dec iff they are allowed options
    my %allow = $self->_get_allowed_options();

    my %clear;
    $clear{ra} = undef if exists $allow{ra};
    $clear{dec} = undef if exists $allow{dec};

    # Store it in the options table
    $self->_set_query_options(
                              object => $ident,
                              %clear
                             );
  }
  return $self->query_options("object");
}

=item B<Radius>

The radius to be searched for objects around the target R.A. and Dec in
arc minutes, the radius defaults to 5 arc minutes.

   $radius = $query->radius();
   $query->radius( 20 );

=cut

sub radius {
  my $self = shift;

  if (@_) {
    $self->_set_query_options( radmax => shift );
  }

  return $self->query_options("radmax");
}

=item B<Faint>

Set (or query) the faint magnitude limit for inclusion on the results

   $faint = $query->faint();
   $query->faint( 50 );

=cut

sub faint {
  my $self = shift;

  if (@_) {
    $self->_set_query_options( magfaint => shift );
  }

  return $self->query_options("magfaint");
}

=item B<Bright>

Set (or query) the bright magnitude limit for inclusion on the results

   $faint = $query->bright();
   $query->bright( 2 );

=cut

sub bright {
  my $self = shift;

  if (@_) {
    $self->_set_query_options( magbright => shift );
  }

  return $self->query_options("magbright");
}

=item B<Sort>

Set or query the order in which the stars are listed in the catalogue

   $sort = $query->sort();
   $query->sort( 'RA' );

valid options are RA, DEC, RMAG, BMAG, DIST (distance to centre of the
requested field) and POS (the position angle to the centre of the field).

=cut

sub sort {
  my $self = shift;

  if (@_) {
    my $sort = shift;
    $self->_set_query_options( sort => $sort );
  }

  # return the sort option
  return $self->query_options("sort");

}

=item B<Number>

The number of objects to return, defaults to 2000 which should hopefully
be sufficent to return all objects of interest. This value should be increased
if a (very) large sample radius is requested.

   $num = $query->number();
   $query->nout( 100 );

=cut

sub number {
  my $self = shift;

  if (@_) {
    $self->_set_query_options( nout => shift );
  }

  return $self->query_options("nout");
}

sub nout {
  my $self = shift;
  warnings::warnif("deprecated","The nout() method is deprecated. Please use number()");
  return $self->number( @_ );
}

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $dss->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # CONFIGURE DEFAULTS
  # ------------------

  # configure the default options
  $self->_set_default_options();


  # CONFIGURE FROM ARGUMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = Astro::Catalog::_normalize_hash(@_);

  # Grab the allowed options
  my %allow = $self->_get_allowed_options();

  # Loop over the supplied arguments. If they correspond to
  # a method, run it, if they correspond to an option, set it
  for my $key (keys %args) {
    my $lckey = lc($key);
    if ($self->can($lckey)) {
      $self->$lckey( $args{$key} );
    } elsif (exists $allow{$lckey}) {
      # set the option explcitly
      $self->_set_query_options( $lckey => $args{$key} );
    } else {
      #warnings::warnif("Unrecognized option: $key. Ignoring it.");
    }
  }

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4


=item B<_set_query_options>

Set the query options.

  $q->_set_query_options( %newopt );

Keys are standardised and are not necessarily those used
in the query. A warning is issued if an attempt is made to
set an option for an option that is not used by the particular
subclass.

=cut

sub _set_query_options {
  my $self = shift;
  my %newopt = @_;

  my %allow = $self->_get_allowed_options();

  for my $newkey (keys %newopt) {

    if (!exists $allow{$newkey}) {
      warnings::warnif("Option $newkey not supported by catalog ".
                       ref($self)."\n");
      next;
    }
    # set the option
    $self->{OPTIONS}->{$newkey} = $newopt{$newkey};
  }
  return;
}

=item B<_get_allowed_options>

Return a hash with keys corresponding to the internal options
supported by the query, and values corresponding to the names
used by the specific query sub-system. Can use the keys
to work out whether an option is supported.

  %allow = $q->_get_allowed_options();

Generally, must be over-ridden in subclass. By default returns all
the internal options, with 1-1 mapping.

=cut

sub _get_allowed_options {
  return (
          ra => 'ra',
          dec => 'dec',
          object => 'object',
          radmax => 'radmax',
          radmin => 'radmin',
          width => 'width',
          height => 'height',
          magbright => 'magbright',
          magfaint => 'magfaint',
          sort => 'sort',
          nout => 'nout',
         );
}

=item B<_get_supported_accessor_options>

Returns a hash with keys corresponding to accessor methods
and values corresponding to the internal option.

 %opt = $q->_get_supported_accessor_options();

This method should be superfluous if the methods had been named
correctly!

Should support object init either via options or methods. This does not cover all
options. In configure, if there is an option available but no corresponding mapping
then we will just set the option directly.

=cut

sub _get_supported_accessor_options {
  return (
          ra => 'ra',
          dec => 'dec',
          faint => 'magfaint',
          bright => 'magbright',
          radius => 'radmax',
          target => 'object',
          sort => 'sort',
          number => 'nout',
          format => 'format',
  );
}

=item B<_get_default_options>

Retrieve the defaults options for this particular catalog query.
Usually called by C<_set_default_options> during object configure.

  %defs = $q->_get_default_options();

=cut

sub _get_default_options {
  croak "get_default_options must be subclassed";
}

=item B<_set_default_options>

Each catalogue requires different default settings for the
URL parameters. They should be specified in a subclass.

=cut

sub _set_default_options {
  my $self = shift;

  # get the defaults
  my %defaults = $self->_get_default_options();

  # set them
  $self->_set_query_options( %defaults );
  return;

}

=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last query made using querydb().

  @lines = $q->_dump_raw();

=cut

sub _dump_raw {
   my $self = shift;

   # split the BUFFER into an array
   my @portable = split( /\n/,$self->{BUFFER});
   chomp @portable;

   return @portable;
}

=item B<_set_raw>

Private function to fill the current buffer with a string. This is used
when deealing with the buffer cannot be encapsulated inside a Transport
class and must be deal with by child classese.

   $q->_set_raw( $buffer );

=cut

sub _set_raw {
   my $self = shift;
   $self->{BUFFER} = shift;
}

=item B<_dump_options>

Private function for debugging and other testing purposes. It will return
the current query options as a hash.

=cut

sub _dump_options {
   my $self = shift;

   return $self->query_options;
}

=item B<_parse_query>

Stub. Needs to be subclassed.

=cut

sub _parse_query {
  croak "Query parsing is not generic. Please write one\n";
}

=back

=head2 Translation Methods

The query options stored internally in the object are not necessarily
the form required for a query to a remote server. Methods for converting
from the internal representation to the external query format are
provided in the form of _from_$opt. ie:

  ($outkey, $outvalue) = $q->_from_ra();
  ($outkey, $outvalue) = $q->_from_object();

Items that have a one-to-one mapping can be declared by the query
subclass using the C<_translate_one_to_one> method which returns
a list of options that support the simplest mapping. If an explicit
method exists it is always used.

If an option has no translation method and is not declared as
a one-to-one mapping, the translator will assume one-to-one but
issue a warning.

=item B<_translate_options>

Translates the options from the default interface into the internal
options specific for the sub-class

  %options = _translate_options( );

The keys and values therefore are no longer general.

=cut

sub _translate_options {
  my $self = shift;

  my %outhash;
  my %allow = $self->_get_allowed_options();
  my %one_one = $self->_translate_one_to_one();

  foreach my $key ( keys %allow ) {
    # Need to translate them...
    my $cvtmethod = "_from_" . $key;
    my ($outkey, $outvalue);
    if ($self->can($cvtmethod)) {
      ($outkey, $outvalue) = $self->$cvtmethod();
    } else {
      # This is the one-to-one mapping section
      # issue a warning if the method has not been declared
      # as supporting that simply mapping
      warnings::warnif("Unable to find translation for key $key. Assuming 1 to 1 mapping.\n")
          unless exists $one_one{$key};

      # Translate the key and copy the value
      $outkey = $allow{$key};
      $outvalue = $self->query_options($key);
    }
    $outhash{$outkey} = $outvalue;
  }
  return %outhash;
}

=item B<_translate_one_to_one>

Returns (hash) indicating which of the standard options support
a one-to-one mapping when forming a URL (etc).

=cut

sub _translate_one_to_one {
  # convert to a hash-list
  return map { $_, undef }(qw/
                           object radmax radmin magfaint magbright
                           nout format
                           /);
}


# RA and Dec replace spaces with pluses and + sign with special code

sub _from_ra {
  my $self = shift;
  my $ra = $self->query_options("ra");
  my %allow = $self->_get_allowed_options();

  # Must replace spaces with +
  $ra =~ s/\s/\+/g if defined $ra;

  return ($allow{ra},$ra);
}

sub _from_dec {
  my $self = shift;
  my $dec = $self->query_options("dec");
  my %allow = $self->_get_allowed_options();

  if (defined $dec) {
    # Must replace + with %2B
    $dec =~ s/\+/%2B/g;

    # Must replace spaces with +
    $dec =~ s/\s/\+/g;
  }

  return ($allow{dec},$dec);
}

sub _from_sort {
  my $self = shift;
  my $key = "sort";
  # case insensitive conversion
  my $value = uc($self->query_options($key));

  my $sort;
  # pick an option
  if( $value eq "RA" ) {
    # sort by RA
    $sort = "ra";
  } elsif ( $value eq "DEC" ) {
    # sort by Dec
    $sort = "dec";
  } elsif ( $value eq "RMAG" ) {
    # sort by R magnitude
    $sort = "mr";
  } elsif ( $value eq "BMAG" ) {
    # sort by B magnitude
    $sort = "mb";
  } elsif ( $value eq "DIST" ) {
    # sort by distance from field centre
    $sort = "d";
  } elsif ( $value eq "POS" ) {
    # sort by position angle to field centre
    $sort = "pos";
  } else {
    # in case there are no valid options sort by RA
    warnings::warnif("Unknown sort type [$value]: using ra");
    $sort = "ra";
  }
  my %allow = $self->_get_allowed_options();
  return ($allow{$key}, $sort);
}

# This is a template methdo that can be extended. This one
# implements a one to one mapping

#sub _from_XXX {
#  my $self = shift;
#  my $key = "XXX";
#  my $value = $self->query_options($key);
#  my %allow = $self->_get_allowed_options();
#  return ($allow{$key}, $value);
#}


=end __PRIVATE_METHODS__

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.
Some modifications copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
