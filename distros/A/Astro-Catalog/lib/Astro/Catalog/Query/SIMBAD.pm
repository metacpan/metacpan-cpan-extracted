package Astro::Catalog::Query::SIMBAD;

=head1 NAME

Astro::Catalog::Query::SIMBAD - A query request to the SIMBAD database

=head1 SYNOPSIS

  $sim = new Astro::Catalog::Query::SIMBAD( RA        => $ra,
                                            Dec       => $dec,
                                            Radius    => $radius,
                                            Target    => $target,
                                           );

  my $catalog = $sim->querydb();

=head1 DESCRIPTION

The module is an object orientated interface to the online SIMBAD
database. Designed to return information on a single object.

Target name overrides RA/Dec.

The object will by default pick up the proxy information from the
HTTP_PROXY and NO_PROXY environment variables, see the LWP::UserAgent
documentation for details.

See L<Astro::Catalog::Query> for the catalog-independent methods.

=cut

use 5.006;
use strict;
use warnings;
use base qw/ Astro::Catalog::Transport::REST /;
use vars qw/ $VERSION /;

use Carp;

# generic catalog objects
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;

$VERSION = '4.32';


=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_default_remote_host>

=cut

sub _default_remote_host {
  return "simbad.u-strasbg.fr";
}

=item B<_default_url_path>

=cut

sub _default_url_path {
  return "sim-id.pl?";
}

=item B<_get_allowed_options>

Returns a hash with keys, being the internal options supported
by this subclass, and values being the key name actually required
by the remote system (and to be included in the query).

=cut

sub _get_allowed_options {
  my $self = shift;
  return (
          ra => 'ra',
          dec => 'dec',
          object => 'Ident',
          radmax => 'Radius',
          nout => "output.max",
          bibyear1 => "Bibyear1",
          bibyear2 => "Bibyear2",
          _protocol => "protocol",
          _nbident => "NbIdent",
          _catall => "o.catall",
          _mesdisp => "output.mesdisp",

          radunits => "Radius.unit", # arcsec, arcmin or deg

          # These should not be published
          # Since we need to switch to Astro::Coords
          _coordframe => "CooFrame",  # FK5 or FK4
          _coordepoch => "CooEpoch",  # 2000
          _coordequi  => "CooEqui",   # 2000

          _frame1 => "Frame1",
          _equi1 => "Equi1",
          _epoch1 => "Epoch1",

          _frame2 => "Frame2",
          _equi2 => "Equi2",
          _epoch2 => "Epoch2",

          _frame3 => "Frame3",
          _equi3 => "Equi3",
          _epoch3 => "Epoch3",

          );
}

=item B<_get_default_options>

Get the default query state.

=cut

sub _get_default_options {
  return  (
           # Target information
           ra => undef,
           dec => undef,
           object => undef,
           radmax => 0.1,
           radunits => "arcmin", # For consistency
           nout => "all",

           _protocol => "html",
           _coordepoch => "2000",
           _coordequi  => "2000",
           _coordframe => "FK5",
           _nbident    => "around",
           _nbident    => "around",
           _catall     => "on",
           _mesdisp    => "A",

           bibyear1    => 1983,
           bibyear2    => 2003,

           # Frame 1, 2 and 3
           # Frame 1 FK5 2000/2000
           _frame1      => "FK5",
           _equi1       => "2000.0",
           _epoch1      => "2000.0",

           # Frame 2 FK4 1950/1950
           _frame2      => "FK4",
           _equi2       => "1950.0",
           _epoch2      => "1950.0",

           # Frame 3 Galactic
           _frame3      => "G",
           _equi3       => "2000.0",
           _epoch3      => "2000.0",

          );
}

=item B<_parse_query>

Private function used to parse the results returned in a SIMBAD query.
Should not be called directly. Instead use the querydb() assessor
method to make and parse the results.

 $cat = $q->_parse_query();

Returns an Astro::Catalog object.

=cut

sub _parse_query {
  my $self = shift;

  # get a local copy of the current BUFFER
  my @buffer = split( /\n/,$self->{BUFFER});
  chomp @buffer;

  #open my $fh, ">xxx.html";
  #print $fh $self->{BUFFER}. "\n";
  #close($fh);

  # create an Astro::Catalog object to hold the search results
  my $catalog = new Astro::Catalog();

  # loop round the returned buffer
  my @target;       # raw HTML lines, one per object
  foreach my $line ( 0 ... $#buffer ) {

    # NUMBER OF OBJECTS FOUND IN ERROR CIRCLE
    if ($buffer[$line] =~ /(\d+)\s+objects: <\/b><pre>/i) {
      # Number of objects found
      my $number = $1;

      # GRAB EACH OBJECT - starting from 2 lines after the
      # current position (since that is the table header and
      # table separator
      @target = map { $buffer[$_] } ($line+2 ... $line+$number+1);

      # DROP OUT OF FIRST LOOP
      last;
    }
  }

  # ...and stuff the contents into Object objects
  foreach my $line ( @target ) {

    # create a temporary place holder object
    my $star = new Astro::Catalog::Star();

    # split each line using the "pipe" symbol separating
    # the table columns
    my @separated = split( /\|/, $line );

    # FRAME
    # -----

    # grab the current co-ordinate frame from the query object itself
    # Assume J2000 for now.

    # URL
    # ---

    # grab the url based on quotes around the string
    my $start_index = index( $separated[0], q/"/ );
    my $last_index = rindex( $separated[0], q/"/ );
    my $url = substr( $separated[0], $start_index+1,
                      $last_index-$start_index-1);

    # push it into the object
    $star->moreinfo( $url );

    # NAME
    # ----

    # get the object name from the same section
    my $final_index = rindex( $separated[0], "A" );
    my $name = substr($separated[0],$last_index+2,$final_index-$last_index-4);

    # push it into the object
    $star->id( $name );

    # TYPE
    # ----
    my $type = $separated[1];

    # dump leading spaces
    $type =~ s/^\s+//g;

    # push it into the object
    $star->startype( $type );

    # RA
    # --

    # remove leading spaces
    my $coords = $separated[2];
    $coords =~ s/^\s+//g;

    # split the RA and Dec line into an array elements
    my @radec = split( /\s+/, $coords );

    # ...and then rebuild it
    my $ra;
    unless( $radec[2] =~ '\+' || $radec[2] =~ '-' ) {
      $ra = "$radec[0] $radec[1] $radec[2]";
    } else {
      $ra = "$radec[0] $radec[1] 00.0";
    }

    # DEC
    # ---

    # ...and rebuild the Dec
    my $dec;
    unless ( $radec[2] =~ '\+' || $radec[2] =~ '-' ) {
      $dec = "$radec[3] $radec[4] $radec[5]";
    } else {
      $dec = "$radec[2] $radec[3] 00.0";
    }

    # Store the coordinates
    $star->coords( new Astro::Coords( name => $name,
                                      ra => $ra,
                                      dec => $dec,
                                      type => "J2000",
                                      units => "s",
                                    ));

    # SPECTRAL TYPE
    # -------------
    my $spectral = $separated[4];

    # remove leading and trailing spaces
    $spectral =~ s/^\s+//g;
    $spectral =~ s/\s+$//g;

    # push it into the object
    $star->spectype($spectral);

    # Add the target object to the Astro::Catalog::Star object
    # ---------------------------------------------------------
    $catalog->pushstar( $star );
  }

  # Field centre?

  # return the catalog
  return $catalog;

}

=item B<_translate_one_to_one>

Return a list of internal options (as defined in C<_get_allowed_options>)
that are known to support a one-to-one mapping of the internal value
to the external value.

  %one = $q->_translate_one_to_one();

Returns a hash with keys and no values (this makes it easy to
check for the option).

This method also returns, the values from the parent class.

=cut

sub _translate_one_to_one {
  my $self = shift;
  # convert to a hash-list
  return ($self->SUPER::_translate_one_to_one,
          map { $_, undef }(qw/
                            bibyear1 bibyear2 radunits
                            _protocol _catall _mesdisp _nbident
                            _coordepoch _coordequi _coordframe
                            _epoch1 _frame1 _equi1
                            _epoch2 _frame2 _equi2
                            _epoch3 _frame3 _equi3
                            /)
         );
}


=end __PRIVATE_METHODS__

=head1 SEE ALSO

  L<Astro::Catalog>, L<Astro::Catalog::Star>, L<Astro::Catalog::Query>.

Derived from L<Astro::SIMBAD> on CPAN.

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.
Some modifications copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

1;
