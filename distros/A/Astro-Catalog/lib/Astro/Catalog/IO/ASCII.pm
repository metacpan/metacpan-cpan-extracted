package Astro::Catalog::IO::ASCII;

=head1 NAME

Astro::Catalog::IO::ASCII - base class for ASCII-based catalogs

=head1 SYNOPSIS

    $cat = $ioclass->read_catalog(%args);

=head1 DESCRIPTION

This class provides a wrapper for reading ASCII-based catalogs
into C<Astro::Catalog> objects. The method should, in general, only
be called from the C<Astro::Catalog> C<configure> method.

=cut

use warnings;
use warnings::register;
use Carp;
use strict;

our $VERSION = '4.38';
our $DEBUG = 0;

=head1 METHODS

=over 4

=item B<read_catalog>

Read the catalog.

    $cat = $ioclass->read_catalog(%args);

Takes a hash as argument with the list of keywords. Supported options
are:

    Data => Contents of catalog, either as a scalar variable,
            reference to array of lines or reference to glob (file handle).
            This key is used in preference to 'File' if both are present.

    File => File name for catalog on disk. Not used if 'Data' supplied.
            If a file is specified but is called 'default', the default file
            for the class is used.

    ReadOpt => Reference to hash of options to be forwarded onto the
               format specific catalog reader. See the IO documentation
               for details.

The options are case-insensitive.

=cut

sub read_catalog {
    my $class = shift;

    my %args = @_;
    %args = Astro::Catalog::_normalize_hash(%args);

    # Lines for the content
    my @lines;

    # Now need to either look for some data or read a file
    if (defined $args{data}) {
        # Need to extract the data from this and convert to array
        if (not ref($args{data})) {
            # must be a scalar
            @lines = split /\n/, $args{data};
        }
        else {
            if (ref($args{data}) eq 'GLOB' || UNIVERSAL::isa($args{data},"IO::Handle")) {
                # A file handle
                local $/ = "\n";
                # For some reason <$args{data}> does not do the right thing
                my $fh = $args{data};
                @lines = <$fh>;
            }
            elsif (ref($args{data}) eq 'ARRAY') {
                # An array of lines
                @lines = @{ $args{data} };
            }
            else {
                # Who knows
                croak "Can not extract catalog information from scalar of type " . ref($args{data}) ."\n";
            }
        }
    }
    else {
        # Look for a filename or the default file
        my $file;
        if (defined $args{file} && $args{file} ne 'default') {
            $file = $args{file};
        }
        else {
            # Need to ask for the default file
            $file = $class->_default_file() if $class->can('_default_file');
            croak "Unable to read catalog since no file specified and no default known."
                unless defined $file;
        }

        # Open the file
        my $CAT;
        croak("Astro::Catalog - Cannot open catalog file $file: $!")
            unless open($CAT, "< $file");

        # read from file
        local $/ = "\n";
        @lines = <$CAT>;
        close($CAT);
    }

    # remove new lines
    chomp @lines;

    # Read Catalog options passed in from caller
    my $readopt = (defined $args{readopt} ? $args{readopt} : {});

    my $catalog = $class->_read_catalog(\@lines, %$readopt);

    return $catalog;
}

=item B<write_catalog>

Write the catalog.

    $ioclass->write_catalog($catalog, %args);

Takes a hash as argument with the list of keywords. Supported options
are:

    File => File name for catalog on disk.

The options are case-insensitive.  Other options are forwarded
to the format-specific catalog writer.

=cut

sub write_catalog {
    my $class = shift;
    my $catalog = shift;

    my %args = @_;
    %args = Astro::Catalog::_normalize_hash(%args);

    my $file = $args{file};
    delete $args{file};

    my $lines = $class->_write_catalog($catalog, %args);

    # Play it defensively - make sure we add the newlines
    chomp @$lines;

    # If we have a reference then we do not need to open or close
    # files - simpler to deal with each case in turn. This has the
    # side effect of repeating the join() in 3 separate places.
    # Probably better than creating a large scalar for the one time
    # when we do not need it.

    my $retval = 1;
    if (ref($file)) {
        # If we are storing in a reference to a scalar or reference
        # to an array, just do the copy and return early. We do not
        if (ref($file) eq 'SCALAR') {
            # Copy single string to scalar
            $$file = join("\n", @$lines) ."\n";
        }
        elsif (ref($file) eq 'ARRAY') {
            # Just copy the lines into the output array
            @$file = @$lines;
        }
        elsif (ref($file) eq 'GLOB' || $file->can("print") ) {
            # GLOB - so print the full string to the file handle and flush
            $retval = print $file join("\n", @$lines) ."\n";
            autoflush $file 1; # We need to make sure we write the lines
        }
        else {
            croak "Can not write catalog to reference of type ".
                ref($file)."\n";
        }
    }
    else {
        # A file name
        my $status = open my $fh, ">$file";
        unless ($status) {
            $catalog->errstr(__PACKAGE__ .": Error creating catalog file $file: $!" );
            return;
        }

        # write to file
        $retval = print $fh join("\n", @$lines) ."\n";

        # close file
        $status = close($fh);
        unless ($status) {
            $catalog->errstr(__PACKAGE__.": Error closing catalog file $file: $!");
            return;
        }
    }

    # everything okay
    return $retval;
}

1;

__END__

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
