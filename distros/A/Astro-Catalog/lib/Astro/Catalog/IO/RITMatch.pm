package Astro::Catalog::IO::RITMatch;

=head1 NAME

Astro::Catalog::IO::RITMatch - Catalog I/O for Astro::Catalog for
Michael Richmond's 'match' program

=head1 SYNOPSIS

    $cat = Astro::Catalog::IO::RITMatch->_read_catalog(\@lines);
    $arrref = Astro::Catalog::IO::RITMatch->_write_catalog($cat, %options);

=head1 DESCRIPTION

This class provides read and write methods for catalogs in Michael
Richmond's 'match' application's input and output file format. The
methods are not public and should, in general only be called from the
C<Astro::Catalog> C<write_catalog> and C<read_catalog> methods.

=cut

use warnings;
use warnings::register;
use strict;

use Carp;

use Astro::Catalog;
use Astro::Catalog::Item;

use Astro::Flux;
use Astro::Fluxes;
use Number::Uncertainty;

use base qw/Astro::Catalog::IO::ASCII/;

our $VERSION = '4.38';
our $DEBUG = 0;

=head1 METHODS

=head2 Private methods

=over 4

=item B<_read_catalog>

Parses the catalog lines and returns a new C<Astro::Catalog> object
containing the catalog entries.

    $cat = Astro::Catalog::IO::RITMatch->_read_catalog(\@lines, %options);

Currently supported options are:

=over 4

=item filter

Either an Astro::WaveBand object or a string that can
be used by the Filter method of the Astro::WaveBand module when
constructing a new object. This option describes the waveband for the
magnitudes in the catalog. If this is not defined, then the waveband
will default to the near infrared 'J' band.

=back

=cut

sub _read_catalog {
    my $class = shift;
    my $lines = shift;

    if (ref($lines) ne 'ARRAY') {
        croak "Must supply catalog contents as a reference to an array";
    }

    # Retrieve options.
    my %options = @_;

    # Grab the filter.
    my $filter;
    if (defined $options{'filter'}) {
        if (UNIVERSAL::isa($options{'filter'}, "Astro::WaveBand")) {
            $filter = $options{'filter'};
        }
        else {
            $filter = new Astro::WaveBand(Filter => $options{'filter'});
        }
    }
    else {
        $filter = new Astro::WaveBand(Filter => 'J');
    }

    # Create a new Astro::Catalog object.
    my $catalog = new Astro::Catalog();

    # Go through the lines. The first column is going to be the ID, the
    # second X, the third Y, and the fourth magnitude. Any columns after
    # the first will be put into the comments() accessor of the
    # Astro::Catalog::Item object.
    my @lines = @$lines;
    for (@lines) {
        my $line = $_;

        $line =~ s/^\s+//;

        my ($id, $x, $y, $mag) = split /\s+/, $line, 4;

        # Create the Astro::Flux object for this magnitude.
        my $flux = new Astro::Flux(
            new Number::Uncertainty(Value => $mag),
            'mag',
            $filter );
        my @mags;
        push @mags, $flux;
        my $fluxes = new Astro::Fluxes(@mags);

        # Create the Astro::Catalog::Item object.
        my $item = new Astro::Catalog::Item(
            ID      => $id,
            X       => $x,
            Y       => $y,
            Fluxes  => $fluxes,
        );

        # Push it into the catalog.
        $catalog->pushstar($item);
    }

    # Set the origin.
    $catalog->origin('Astro::Catalog::IO::RITMatch');

    return $catalog;
}

=item B<_write_catalog>

Create an output catalog in the 'match' format and return the lines
in an array.

    $ref = Astro::Catalog::IO::RITMatch->_write_catalog($catalog, %options);

The sole mandatory argument is an C<Astro::Catalog> object.

Optional arguments are:

=over 4

=item mag_type

the magnitude type to write out to the file. Defaults
to 'mag'.

=item filter

reference filter to select from catalog. See flux()
method in Astro::Flux. This allows a specific filter to be selected
for output. Argument can be a string or Astro::Waveband object.

=back

The output format has the ID in column 1, X coordinate in column 2, Y
coordinate in column 3, magnitude value in column 4, and any comments
in column 5.

=cut

sub _write_catalog {
    my $class = shift;
    my $catalog = shift;

    if (! UNIVERSAL::isa($catalog, "Astro::Catalog")) {
        croak "Must supply catalog as an Astro::Catalog object";
    }

    # Get options.
    my %options = @_;
    my $mag_type = 'mag';
    if (defined $options{'mag_type'}) {
        $mag_type = $options{'mag_type'};
    }

    my $refwb;
    $refwb = $options{filter}
    if exists $options{filter};

    # Set up variables for output.
    my @output;
    my $output_line;

    my $newid = 1;

    # Astro::Fluxes can not guarantee that the Astro::Flux
    # order will be in a particular order so we can not simply
    # grab the first one. We might get a "J" this time but previously
    # got "R".

    # Loop through the items in the catalog.
    foreach my $item ($catalog->stars) {
        my $x = $item->x;
        my $y = $item->y;
        my $fluxes = $item->fluxes;

        # We need at a bare minimum the X, Y, ID, and a magnitude.
        next if (! defined($newid) ||
                ! defined($x) ||
                ! defined($y) ||
                ! defined($fluxes));

        my $flux;
        unless ($refwb) {
            # If no external selection of waveband and this is first time
            # through loop we select the first waveband as a reference
            my @allflux = $fluxes->allfluxes;
            $flux = $allflux[0];
            $refwb = $flux->waveband->natural;
        }
        else {
            $flux = $fluxes->flux(type => $mag_type, waveband => $refwb);
        }

        next unless defined $flux;
        next if uc($flux->type) ne uc($mag_type);

        my $magval = $flux->quantity($mag_type);

        # Sometimes we get a missing value
        next unless defined $magval;
        next unless length($magval);

        # Create the output string.
        $output_line = join ' ',
            $newid,
            $x,
            $y,
            $magval,
            $item->id;

        # And push this string to the output array.
        push @output, $output_line;

        $newid++;
    }

    return \@output;
}

1;

__END__

=back

=head1 SEE ALSO

L<Astro::Catalog>, L<Astro::Catalog::IO::Simple>

http://spiff.rit.edu/match/

=head1 COPYRIGHT

Copyright (C) 2014 Tim Jenness
Copyright (C) 2006 Particle Physics and Astronomy Research
Council. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut
