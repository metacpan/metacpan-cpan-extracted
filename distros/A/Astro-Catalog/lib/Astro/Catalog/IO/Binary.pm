package Astro::Catalog::IO::Binary;

=head1 NAME

Astro::Catalog::IO::Binary - base class for binary catalogues.

=head1 SYNOPSIS

  $cat = $ioclass->read_catalog( %args );

=head1 DESCRIPTION

This class provides a wrapper for reading binary catalogues
into C<Astro::Catalog> objects. The method should, in general, only
be called from the C<Astro::Catalog> C<configure> method.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '4.32';
$DEBUG = 0;

=head1 METHODS

=over 4

=item B<read_catalog>

Read the catalog.

  $cat = $ioclass->read_catalog( %args );

Takes a hash as argument with the list of keywords. Supported options
are:

  Data => Contents of catalogue, as a reference to glob (file handle)
          or a scalar containing data to be turned into a catalog.
          This key is used in preference to 'File' if both are present.
  File => File name for catalog on disk. Not used if 'Data' supplied.
  ReadOpt => Reference to hash of options to be forwarded onto the
             format specific catalogue reader. See the IO documentation
             for details.

The options are case-insensitive.

=cut

sub read_catalog {
  my $class = shift;

  my $catalog;

  # Retrieve and normalize arguments.
  my %args = @_;
  %args = Astro::Catalog::_normalize_hash( %args );

  my $readopt = (defined $args{readopt} ? $args{readopt} : {} );

  # Find out if the class would rather have a file handle or
  # a file name.
  my $input_format = $class->input_format;

  # Now need to either look for some data or read a file
  if ( defined $args{data}) {

    if (ref($args{data}) eq 'GLOB') {
      # A file handle. If the requested input format is a file handle,
      # then we're good. If the requested input format is a file name,
      # then copy the file pointed to by the file handle to a temporary
      # file, then pass that file name to the IO class.
      if( $input_format eq 'handle' ) {

        $catalog = $class->_read_catalog( filehandle => $args{data},
                                          %$readopt );

      } elsif( $input_format eq 'name' ) {

        ( my $fh, my $filename ) = tempfile( UNLINK => 1 );
        binmode $args{data};
        while( read $args{data}, my $buffer, 1024 ) {
          print $fh $buffer;
        }
        close $fh;
        $catalog = $class->_read_catalog( filename => $filename,
                                          %$readopt );
      } else {

        # We got back something we can't use.
        croak "Unknown input format $input_format";

      }
    } elsif( not ref( $args{data} ) ) {

      ( my $fh, my $filename ) = tempfile( UNLINK => 1 );
      print $fh $args{data};
      close $fh;

      if( $input_format eq 'handle' ) {
        open( $fh, $filename ) or croak "Could not open file $filename for reading: $!";
        $catalog = $class->_read_catalog( filehandle => $fh,
                                          %$readopt );
        close $fh;
      } elsif( $input_format eq 'name' ) {

        $catalog = $class->_read_catalog( filename => $filename,
                                            %$readopt );
      }
    } else {
      # Who knows
      croak "Can not extract catalog information from scalar of type " . ref($args{data}) ."\n";
    }

  } else {
    # Look for a filename or the default file
    my $file;
    if ( defined $args{file} ) {
      $file = $args{file};
    } else {
      # Need to ask for the default file
      $file = $class->_default_file() if $class->can( '_default_file' );
      croak "Unable to read catalogue since no file specified and no default known." unless defined $file;
    }

    # Pass along the desired input format.
    if( $input_format eq 'handle' ) {

      open( my $fh, $file ) or croak "Could not open file $file: $!";
      $catalog = $class->_read_catalog( filehandle => $fh,
                                        %$readopt );

    } elsif( $input_format eq 'name' ) {

      $catalog = $class->_read_catalog( filename => $file,
                                        %$readopt );

    } else {

      croak "Unknown input format $input_format";
    }

  }

  return $catalog;
}

=back

=head1 SEE ALSO

L<Astro::Catalog>

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research Council.
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

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
