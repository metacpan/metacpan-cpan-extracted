package Astro::Catalog::IO::XY;

=head1 NAME

Astro::Catalog::IO::XY - X & Y position I/O for Astro::Catalog

=head1 SYNOPSIS

  \@lines = Astro::Catalog::IO::XY->_write_catalog( $catalog );

=head1 DESCRIPTION

Performs simple IO, writing "x y" formatted strings for each
Astro::Catalog::Item object in the catalogue.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use Carp;

use Astro::Catalog;
use Astro::Catalog::Star;

use base qw/ Astro::Catalog::IO::ASCII /;

use vars qw/$VERSION $DEBUG/;

$VERSION = '4.33';
$DEBUG = 0;

=begin __PRIVATE_METHODS__

=head1 Private Methods

These methods are for internal use only and are called from the
Astro::Catalog module. It is not expected that anyone would want to
call them from outside that module.

=over 4

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog> object
containing the catalogue entries.

  $cat = Astro::Catalog::IO::XY->_read_catalog( \@lines );

The catalogue lines must be as described in the FORMAT section, below.

=cut

sub _read_catalog {
  croak( 'Usage: _read_catalog( \@lines )' ) unless scalar(@_) >= 1;
  my $class = shift;
  my $arg = shift;
  my @lines = @{$arg};

  # Create an Astro::Catalog object;
  my $catalog = new Astro::Catalog();

  # Loop through the lines.
  foreach my $i ( 0 .. $#lines ) {

    # Skip commented and blank lines
    next if ( $lines[$i] =~ /^\s*[\#\*\%]/);
    next if ( $lines[$i] =~ /^\s*$/);

    # Create an Astro::Catalog::Item object.
    my $item = new Astro::Catalog::Item;

    # Split up the line.
    my @values = split /\s+/, $lines[$i];

    if( $values[0] eq '' ) {
      next if ( ! defined( $values[2] ) || ! defined( $values[1] ) );
      $item->x( $values[1] );
      $item->y( $values[2] );
    } else {
      next if ( ! defined( $values[1] ) || ! defined( $values[0] ) );
      $item->x( $values[0] );
      $item->y( $values[1] );
    }

    # Push the Item onto the Catalog.
    $catalog->pushstar( $item );

  }

  # Set the catalogue origin and return.
  $catalog->origin( 'IO::XY' );
  return $catalog;

}

=item B<_write_catalog>

Will write the catalogue object to a simple output format of the form
"x y", where x is the x-position and y is the y-position of each
object in the catalogue.

  \@lines = Astro::Catalog::IO::XY->_write_catalog( $catalog );

$catalog is an Astro::Catalog object.

=cut

sub _write_catalog {
  my $class = shift;
  my $catalog = shift;

  my @return;

  my $stars = $catalog->stars();
  foreach my $star ( @$stars ) {
    my $output_string;
    $output_string .= $star->x . " " . $star->y;
    push( @return, $output_string );
  }

  return \@return;

}

=back

=end __PRIVATE_METHODS__

=head1 FORMAT

The XY format is simply:

 X Y

The values are separated by any non-zero amount of whitespace. Postive
and negative values are allowed. Comment lines begin with a hash:

 # This is a comment line.

Any amount of leading or trailing whitespace is allowed.

=head1 COPYRIGHT

Copyright (C) 2006 Particle Physics and Astronomy Research
Council. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of version 2 of the GNU General Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
