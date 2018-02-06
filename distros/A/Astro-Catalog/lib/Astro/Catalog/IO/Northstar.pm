package Astro::Catalog::IO::Northstar;

=head1 NAME

Astro::Catalog::IO::Northstar - NorthStar format catalogue parser

=head1 SYNOPSIS

  $cat = Astro::Catalog::IO::Northstar->_read_catalog( \@lines );
  $arrref = Astro::Catalog::IO::Northstar->_write_catalog( $cat, %options );
  $filename = Astro::Catalog::IO::Northstar->_default_file();

=head1 DESCRIPTION

This class provides read and write methods for catalogues in the
format used by the NorthStar proposal submission system.  The methods
are not public and should, in general, only be called from the
C<Astro::Catalog> C<write_catalog> and C<read_catalog> methods.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use Astro::Telescope;
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Star;

use base qw/ Astro::Catalog::IO::ASCII /;

use vars qw/$VERSION $DEBUG /;

$VERSION = '4.32';
$DEBUG   = 0;

=head1 METHODS

=over 4

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog>
object containing the catalog entries.

 $cat = Astro::Catalog::IO::Northstar->_read_catalog( \@lines, %options );

Supported options (with defaults) are:

  telescope => Name of telescope to associate with each coordinate entry
               (defaults to JCMT). If the telescope option is specified
               but is undef or empty string, no telescope is used.

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;

  # Default options
  my %defaults = ( telescope => 'JCMT',
                   incplanets => 1);

  my %options = (%defaults, @_);

  croak "Must supply catalogue contents as a reference to an array"
    unless ref($lines) eq 'ARRAY';

  # Create a new telescope to associate with this
  my $tel;
  $tel = new Astro::Telescope( $options{telescope} )
    if $options{telescope};

  # Go through each line and parse it
  my @stars;
  for my $line (@$lines) {
    $line =~ s/^\s*//;
    $line =~ s/\s*$//;
    next unless $line =~ /\w/;
    my ($name, $c1, $c2, $system, $comment) = split (/\s+/,$line,5);
    next unless (defined $c1 && defined $c2 && defined $system);

    # skip "OTHER" since we do not know what to do with it
    next if $system =~ /other/i;

    my ($ctype1, $ctype2);
    if ($system =~ /gal/i) {
      $ctype1 = "long";
      $ctype2 = "lat";
    } else {
      $ctype1 = "ra";
      $ctype2 = "dec";
    }

    my $c = new Astro::Coords( $ctype1 => $c1,
                               $ctype2 => $c2,
                               type => $system,
                               name => $name,
                             );
    $c->telescope($tel) if defined $tel;
    $c->comment($comment) if (defined $comment && $comment =~ /\w/);

    # Field name should simply be linked to the telescope
    my $field = (defined $tel ? $tel->name : '<UNKNOWN>' );

    # now need the Item
    my $item = new Astro::Catalog::Item( id => $name,
                                         field => $field,
                                         coords => $c,
                                         comment => $comment );
    push(@stars, $item);

  }

  return Astro::Catalog->new( Stars => \@stars, Origin => 'NorthStar' );

}

=back

=head1 NOTES

The NorthStar (http://proposal.astron.nl) catalogue format is:

  TargetName  hh:mm:ss  dd:mm:ss system  misc

TargetName can not include spaces. The "system" should be "J2000",
"B1950", "Jxxxx", "Bxxxx" or "GALACTIC".

The misc field will be stored as a comment.


=head1 GLOBAL VARIABLES

The following global variables can be modified to control the state of the
module:

=over 4

=item $DEBUG

Controls debugging messages. Default state is false.

=back

=head1 COPYRIGHT

Copyright (C) 2007 Particle Physics and Astronomy Research Council.
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

=head1 AUTHORS

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut

1;
