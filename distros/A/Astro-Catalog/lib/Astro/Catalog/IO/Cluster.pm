package Astro::Catalog::IO::Cluster;

=head1 NAME

Astro::Catalog::IO::Cluster - Input/Output in ARK Cluster format

=head1 SYNOPSIS

    $catalog = Astro::Catalog::IO::Cluster->_read_catalog(\@lines);
    $lines = Astro::Catalog::IO::Cluster->_write_catalog($catalog, %opts);
    Astro::Catalog::IO::Cluster->_default_file();

=head1 DESCRIPTION

Performs ARK Cluster specific tasks for input/output of ARK Cluster format
files.

=cut

use strict;
use warnings;
use warnings::register;
use Scalar::Util;
use Carp;

use Astro::Catalog;
use Astro::Catalog::Item;
use Astro::Coords;

use Astro::FluxColor;
use Astro::Flux;
use Astro::Fluxes;

use Number::Uncertainty;

use base qw/Astro::Catalog::IO::ASCII/;

use Data::Dumper;

our $VERSION = '4.37';

=begin __PRIVATE_METHODS__

=head1 Private methods

These methods are for internal use only and are called from the
Astro::Catalog module. Its not expected that anyone would want to
call them from utside that module.

=over 4

=item B<_read_cluster>

Parses a reference to an array containing an ARK Cluster format
catalog, returns an Astro::Catalog object.

    $catalog = Astro::Catalog::IO::Cluster->_read_catalog(\@lines);

=cut

sub _read_catalog {
    croak('Usage: _read_catalog(\@lines)') unless scalar(@_) >= 1;
    my $class = shift;
    my $arg = shift;
    my @lines = @{$arg};

    # create am Astro::Catalog object;
    my $catalog = new Astro::Catalog();

    # loop through lines
    foreach my $i (3 .. $#lines) {
        # remove leading spaces
        $lines[$i] =~ s/^\s+//;

        # split each line
        my @separated = split(/\s+/, $lines[$i]);

        # temporary star object
        my $star = new Astro::Catalog::Item();

        # field
        $star->field($separated[0]);

        # id
        $star->id($separated[1]);

        # ra
        my $objra = "$separated[2] $separated[3] $separated[4]";

        # dec
        my $objdec = "$separated[5] $separated[6] $separated[7]";

        # Assume J2000 and create an Astro::Coords object
        my $coords = new Astro::Coords(
            type  => 'J2000',
            units => 'sex',
            ra    => $objra,
            dec   => $objdec,
            name  => $star->id());

        # and push it into the Astro::Catalog::Item object
        $star->coords($coords);

        # x & y
        if ($separated[8] ne '0.000') {
            $star->x($separated[8]);
        }
        if ($separated[9] ne '0.000') {
            $star->y($separated[9]);
        }

        # number of magnitudes and colours
        $lines[1] =~ s/^\s+//;
        my @colours = split(/\s+/, $lines[1]);

        my @quality;
        my (@colors, @fluxes);
        foreach my $j (0 .. $#colours) {
            # colours have minus signs
            if (lc($colours[$j]) =~ "-") {
                # build a colour object and push it into the @colors array
                my @filters = split "-", $colours[$j];
                my $color = new Astro::FluxColor(
                        upper => new Astro::WaveBand(Filter => $filters[0]),
                        lower => new Astro::WaveBand(Filter => $filters[1]),
                        quantity => new Number::Uncertainty(
                            Value => $separated[3*$j+10],
                            Error => $separated[3*$j+11]));
                push @colors, $color;

                # quality flags
                $quality[$j] = $separated[3*$j+12];
            }
            else {
                my $mag = new Astro::Flux(
                        new Number::Uncertainty(
                            Value => $separated[3*$j+10],
                            Error => $separated[3*$j+11]),
                        'mag', $colours[$j]);
                push @fluxes, $mag;

                # quality flags
                $quality[$j] = $separated[3*$j+12];

                # increment counter
                $j = $j + 2;
            }
        }

        $star->fluxes(new Astro::Fluxes(@fluxes, @colors));

        # set default "good" quality
        $star->quality(0);

        # check and set quality flag
        foreach my $k (0 .. $#colours) {
            # if quality not good then set bad flag
            if (Scalar::Util::looks_like_number($quality[$k])) {
                if (defined $quality[$k] && $quality[$k] != 0) {
                    $star->quality(1);
                }
            }
            else {
                if (defined $quality[$k] && $quality[$k] ne "OO") {
                    $star->quality(1);
                }
            }
        }

        # push it onto the stack
        $catalog->pushstar($star);
    }

    $catalog->origin('IO::Cluster');
    return $catalog;

}

=item B<_write_catalog>

Will write the catalog object to an standard ARK Cluster format file

    $lines = Astro::Catalog::IO::Cluster->_write_catalog($catalog, %opts);

where $catalog is an Astro::Catalog object and allowable options are
currently C<Colours> and C<Mags>, e.g.

    $lines = Astro::Catalog::IO::Cluster->_write_catalog(
        $catalog, Magnitudes => \@mags, Colours => \@colours );

where magnitudes and colours passed in the array will be used in the catalog
despite the presence of other

    my @mags = ('R');
    my @colour = ('B-R', 'B-V');
    \@lines = Astro::Catalog::IO::Cluster->write_catalog(
        $catalog, Magnitudes => \@mags, Colours => \@colours);

will write a catalog with R, B-R and B-V.

=cut

sub _write_catalog {
    croak('Usage: _write_catalog($catalog, [%opts])') unless scalar(@_) >= 1;
    my $class = shift;
    my $catalog = shift;

    # real list of filters and colours in the catalog
    my @filters = $catalog->starbyindex(0)->what_filters();
    my @colours = $catalog->starbyindex(0)->what_colours();

    # number of stars in catalog
    my $number = $catalog->sizeof();

    # number of filters & colours
    my $num_mags = $catalog->starbyindex(0)->what_filters();
    my $num_cols = $catalog->starbyindex(0)->what_colours();

    # reference to the $self->{STARS} array in Astro::Catalog
    my $stars = $catalog->stars();

    # figure out what magnitudes and colours we're going to output
    my ($mags, $cols);
    if (@_) {
        my %args = @_;

        if (defined $args{colours}) {
            $cols = $args{colours};
        }
        if (defined $args{magnitudes}) {
            $mags = $args{magnitudes};
        }
    }
    else {
        $mags = \@filters;
        $cols = \@colours;
    }

    # define varaibles for output filters and colours
    my (@out_mags, @out_cols);

    # Filter the output magnitudes and colours for uniqueness.

    # if we want fewer magnitudes than we have in the object
    # to be written to the cluster file
    my %seen_mag;
    foreach my $m (0 .. $#{$mags}) {
        next if $seen_mag{$mags->[$m]} ++;
        foreach my $n (0 .. $num_mags-1) {
            if (${$mags}[$m] eq $filters[$n]) {
                push @out_mags, ${$mags}[$m];
                last;
            }
        }
    }

    # same for colours
    my %seen_col;
    foreach my $k (0 .. $#{$cols}) {
        next if $seen_col{$cols->[$k]} ++;
        foreach my $l (0 .. $num_cols-1) {
            if (${$cols}[$k] eq $colours[$l]) {
                push @out_cols, ${$cols}[$k];
                last;
            }
        }
    }

    # write header
    my @output;
    my $output_line;

    # check to see if we're outputing all the filters and colours
    my $total = scalar(@out_mags) + scalar(@out_cols);

    push @output, "$total colours were created";
    push @output, "@out_mags @out_cols";

    # wierd and odd
    $output_line = "Origin: " . $catalog->origin() . " "
        if defined $catalog->origin();

    if (defined $catalog->get_ra() && defined $catalog->get_dec()) {
        $output_line = $output_line .
            "  Field Centre: RA " . $catalog->get_ra() .
            ", Dec " . $catalog->get_dec() . " ";
    }

    $output_line = $output_line .
        "  Catalogue Radius: " . $catalog->get_radius() .  " arcmin"
        if defined $catalog->get_radius();

    $output_line = $output_line;
    push @output, $output_line;

    # write body

    # loop through all the stars in the catalog
    foreach my $star (0 .. $#$stars) {
        $output_line = undef;

        # field, number, ra, dec and x&y position
        my $field = ${$stars}[$star]->field;
        if (defined $field) {
            $output_line = $field . "  ";
        }
        else {
            $output_line = "0 ";
        }

        my $id = ${$stars}[$star]->id;
        if (defined $id &&
                Scalar::Util::looks_like_number($id)) {
            $output_line = $output_line . $id . "  ";
        }
        else {
            $output_line = $output_line . $star . " ";
        }

        # fiddle with the dec, olv versions of the Fortran Cluster
        # parser don't like + signs for northern hemisphere dec's
        my $dec = ${$stars}[$star]->dec();
        $dec =~ s/\+//;

        $output_line = $output_line . ${$stars}[$star]->ra() . "  ";
        $output_line = $output_line . $dec . "  ";

        my $x = ${$stars}[$star]->x;
        my $y = ${$stars}[$star]->y;

        if (defined $x && defined $y) {
            $output_line = $output_line . $x . " " . $y . " ";
        }
        else {
            $output_line = $output_line . "0.000  0.000  ";
        }

        # magnitudes
        foreach my $out_mag (@out_mags) {
            # Grab each magnitude listed in the @out_mags array and append
            # it to the output line.
            my $out_mag_value = ${$stars}[$star]->get_magnitude($out_mag);
            if (defined $out_mag_value) {
                $output_line .= $out_mag_value . "  ";
            }
            else {
                $output_line .= "0.000 ";
            }

            # And get the error, if it exists.
            my $out_mag_error = ${$stars}[$star]->get_errors($out_mag);
            if (defined $out_mag_error) {
                $output_line .= $out_mag_error . "  ";
            }
            else {
                $output_line .= "0.000 ";
            }

            # And the quality.
            my $quality = ${$stars}[$star]->quality;
            if (defined $quality) {
                $output_line .= $quality . "  ";
            }
            else {
                $output_line .= "0 ";
            }
        }

        # Now for the colours.
        foreach my $out_col (@out_cols) {
            # Grab each colour listed in the @out_cols array and append it
            # to the output line.
            my $out_col_value = ${$stars}[$star]->get_colour($out_col);
            if (defined $out_col_value) {
                $output_line .= $out_col_value . "  ";
            }
            else {
                $output_line .= "0.000 ";
            }

            # And get the error, if it exists.
            my $out_col_error = ${$stars}[$star]->get_colourerr($out_col);
            if (defined $out_col_error) {
                $output_line .= $out_col_error . "  ";
            }
            else {
                $output_line .= "0.000 ";
            }

            # And the quality.
            my $quality = ${$stars}[$star]->quality;
            if (defined $quality) {
                $output_line .= $quality . "  ";
            }
            else {
                $output_line .= "0 ";
            }
        }

        # next star
        $output_line = $output_line;
        push (@output, $output_line );

    }

    # clean up
    return \@output;
}

=item B<_default_file>

If Astro::Catalog is created with a Format but no Filename or other data
source it checked this routine to see whether there is a default file
that should be read. This is mainly for Astro::Catalo::IO::JCMT and the
JAC, but might prive useful elsewhere.

=cut

sub _default_file {
   # returns an empty list
   return;
}

1;

__END__

=back

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.
Some modificiations Copyright (C) 2003-2005 Particle Physics and
Astronomy Research Council.
Some modifications Copyright (C) 2013 Science & Technology Facilities Council.
All Rights Reserved.

This module was written as part of the eSTAR project in collaboration
with the Joint Astronomy Centre (JAC) in Hawaii and is free software;
you can redistribute it and/or modify it under the terms of the GNU
Public License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut
