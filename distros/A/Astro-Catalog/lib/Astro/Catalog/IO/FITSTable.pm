package Astro::Catalog::IO::FITSTable;

=head1 NAME

Astro::Catalog::IO::FITSTable - Binary FITS table I/O for Astro::Catalog

=head1 SYNOPSIS

    $cat = Astro::Catalog::IO::FITSTable->_read_catalog($whatever);

=cut

use warnings;
use warnings::register;
use Carp;
use strict;

use Astro::Catalog;
use Astro::Catalog::Item;
use Astro::Catalog::Item::Morphology;
use Astro::Coords;
use Astro::FITS::CFITSIO qw/:longnames :constants/;
use File::Temp qw/tempfile/;

use Astro::Flux;
use Astro::FluxColor;
use Astro::Fluxes;

use DateTime;
use DateTime::Format::ISO8601;

use base qw/Astro::Catalog::IO::Binary/;

our $VERSION = '4.37';
our $DEBUG = 0;

=begin __PUBLIC_METHODS__

=head1 PUBLIC METHODS

These methods are usually called automatically from the C<Astro::Catalog>
constructor, but are available for public use.

=over 4

=item B<input_format>

Returns the requested input format for the FITSTable class, which is
'name', meaning the name of the file to be turned into an C<Astro::Catalog>
object.

    $input_format = Astro::Catalog::IO::FITSTable->input_format;

=cut

sub input_format {
    return "name";
}

=back

=begin __PRIVATE_METHODS__

=head1 PRIVATE METHODS

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=item B<_read_catalog>

Parses the binary FITS table and returns a new C<Astro::Catalog> object
containing the catalog entries.

    $cat = Astro::Catalog::IO::FITSTable->_read_catalog($whatever);

The current translations from FITS table column names to
C<Astro::Catalog::Item> properties are:

=over 4

=item No. - ID

=item X_coordinate - X

=item Y_coordinate - Y

=item RA & DEC - Coords

=item Isophotal_flux, Total_flux, Core_flux, Core1_flux, Core2_flux,
 Core3_flux, Core4_flux, Core5_flux - C<Astro::Flux> objects pushed into
 the C<Astro::Catalog::Item> fluxes accessor.

=item Ellipticity & Position_angle - Morphology

=back

RA and Dec are assumed to be in J2000 coordinates, and are in units
of radians. The isophotal flux is assumed to be in units of counts,
and is converted into a magnitude through the formula -2.5 * log10(flux).
The position angle is assumed to be the angle measured counter-
clockwise from the positive x axis, in degrees.

An attempt to read in the DATE-OBS header is made so that flux measurements
can be timestamped. If the DATE-OBS header does not exist, then the current
date and time will be used for the flux timestamps.

=cut

sub _read_catalog {
    my $class = shift;
    my %args = @_;

    unless (defined $args{'filename'}) {
        croak "Must supply a filename to read";
    }
    my $filename = $args{'filename'};

    my $obsid;
    if (defined $args{'obsid'}) {
        $obsid = $args{'obsid'};
    }
    else {
        $obsid = [];
    }

    # A lookup table for column name mappings.
    my %column_name = (
        'ID' => 'No.',
        'X' => 'X_coordinate',
        'Y' => 'Y_coordinate',
        'RA' => 'RA',
        'Dec' => 'DEC',
        'isophotal_flux' => 'Isophotal_flux',
        'total_flux' => 'Total_flux',
        'core_flux' => 'Core_flux',
        'core1_flux' => 'Core1_flux',
        'core2_flux' => 'Core2_flux',
        'core3_flux' => 'Core3_flux',
        'core4_flux' => 'Core4_flux',
        'core5_flux' => 'Core5_flux',
        'ellipticity' => 'Ellipticity',
        'position_angle' => 'Position_angle',
    );

    # The new Astro::Catalog object.
    my $catalog = new Astro::Catalog;

    # CFITSIO status variable.
    my $status = 0;

    # Open the file using CFITSIO.
    my $fptr = Astro::FITS::CFITSIO::open_file($filename,
            Astro::FITS::CFITSIO::READONLY(),
            $status);
    if ($status != 0) {
        Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
        croak "Error opening FITS file: $status $text";
    }

    # Get the number of HDUs in the FITS file.
    $fptr->get_num_hdus(my $num_hdus, $status);
    if ($status != 0) {
        Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
        croak "Error retrieving number of HDUs from FITS file: $status $text";
    }

    $fptr->get_hdu_num(my $hdu_pos);

    while ($hdu_pos <= $num_hdus) {
        # Get the type of HDU for the one we're at.
        $fptr->get_hdu_type(my $hdutype, $status);
        if ($status != 0) {
            Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
            croak "Error retrieving HDU type from FITS file: $status $text";
        }

        if ($hdutype == BINARY_TBL) {
            # Try to retrieve the DATE-OBS header. This will be used
            # to give each flux measurement a datetime stamp. If DATE-OBS
            # cannot be determined, then set the datetime to the current
            # time.
            my $datetime;
            $fptr->read_keyword('DATE-OBS', my $dateobs, my $comment, $status);
            if ($status != 0) {
                if ($status == KEY_NO_EXIST) {
                    # We can deal with this, just take the current time and set
                    # the status back to 0 (good).
                    $datetime = DateTime->now;
                    $status = 0;
                }
                else {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error retrieving DATE-OBS header from FITS file: $status $text";
                }
            }
            else {
                # Strip out any characters that aren't meant to be there.
                # read_keyword() puts single quotes around strings, so we need
                # to get rid of those, along with any trailing Zs.
                $dateobs =~ s/['Z]//g;
                $datetime = DateTime::Format::ISO8601->parse_datetime($dateobs);
            }

            my $waveband;
            $fptr->read_keyword('FILTER', my $filter, my $filtercomment, $status);
            if ($status != 0) {
                if ($status == KEY_NO_EXIST) {
                    # We can deal with this, just set the filter to be 'unknown'.
                    $filter = 'unknown';
                    $status = 0;
                }
                else {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error retrieving FILTER header from FITS file: $status $text";
                }
            }
            else {
                # Strip out any characters that aren't meant to be there.
                $filter =~ s/'//g;
                $filter =~ s/^\s+//;
                $filter =~ s/\s+$//;
            }
            $waveband = new Astro::WaveBand(Filter => $filter);

            # Get the number of rows in this table.
            $fptr->get_num_rows(my $nrows, $status);
            if ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error retrieving number of rows from HDU $hdu_pos from FITS file: $status $text";
            }

            # Grab all the information we can from this HDU.
            # First, get the column numbers for the ID, RA, Dec, flux,
            # ellipticity, position angle, and x and y position.
            $fptr->get_colnum(CASEINSEN, $column_name{'ID'}, my $id_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $id_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding ID column: $status $text";
            }
            if ($id_column == 0) {
                $id_column = -1;
            }
            print "ID column: $id_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'RA'}, my $ra_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $ra_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding RA column: $status $text";
            }
            if ($ra_column == 0) {
                $ra_column = -1;
            }
            print "RA column: $ra_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'Dec'}, my $dec_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $dec_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding Dec column: $status $text";
            }
            if ($dec_column == 0) {
                $dec_column = -1;
            }
            print "Dec column: $dec_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'isophotal_flux'}, my $iso_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $iso_flux_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding isophotal flux column: $status $text";
            }
            if ($iso_flux_column == 0) {
                $iso_flux_column = -1;
            }
            print "Isophotal flux column: $iso_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'total_flux'}, my $total_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $total_flux_column = -1;
            }
            elsif ($status != 0 ) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding total flux column: $status $text";
            }
            if ($total_flux_column == 0) {
                $total_flux_column = -1;
            }
            print "Total flux column: $total_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'core_flux'}, my $core_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $core_flux_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding core flux column: $status $text";
            }
            if ($core_flux_column == 0) {
                $core_flux_column = -1;
            }
            print "Core flux column: $core_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'core1_flux'}, my $core1_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $core1_flux_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding core1 flux column: $status $text";
            }
            if ($core1_flux_column == 0) {
                $core1_flux_column = -1;
            }
            print "Core1 flux column: $core1_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'core2_flux'}, my $core2_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $core2_flux_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding core2 flux column: $status $text";
            }
            if ($core2_flux_column == 0) {
                $core2_flux_column = -1;
            }
            print "Core2 flux column: $core2_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'core3_flux'}, my $core3_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $core3_flux_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding core3 flux column: $status $text";
            }
            if ($core3_flux_column == 0) {
                $core3_flux_column = -1;
            }
            print "Core3 flux column: $core3_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'core4_flux'}, my $core4_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $core4_flux_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding core4 flux column: $status $text";
            }
            if ($core4_flux_column == 0) {
                $core4_flux_column = -1;
            }
            print "Core4 flux column: $core4_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'core5_flux'}, my $core5_flux_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $core5_flux_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding core5 flux column: $status $text";
            }
            if ($core5_flux_column == 0) {
                $core5_flux_column = -1;
            }
            print "Core5 flux column: $core5_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'ellipticity'}, my $ell_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $id_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding ellipticity column: $status $text";
            }
            if ($ell_column == 0) {
                $ell_column = -1;
            }
            print "Ellipticity column: $ell_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'position_angle'}, my $posang_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $id_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding position angle column: $status $text";
            }
            if ($posang_column == 0) {
                $posang_column = -1;
            }
            print "Position angle column: $posang_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'X'}, my $x_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $id_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding x-coordinate column: $status $text";
            }
            if ($x_column == 0) {
                $x_column = -1;
            }
            print "X-coordinate column: $x_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'Y'}, my $y_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $id_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding y-coordinate column: $status $text";
            }
            if ($y_column == 0) {
                $y_column = -1;
            }
            print "Y-coordinate column: $y_column\n" if $DEBUG;

            # Now that we've got all the columns defined, we need to grab each column
            # in one big array, then take those arrays and stuff the information into
            # Astro::Catalog::Item objects
            my $id;
            my $ra;
            my $dec;
            my ($iso_flux, $total_flux, $core_flux, $core1_flux, $core2_flux, $core3_flux);
            my ($core4_flux, $core5_flux);
            my $ell;
            my $posang;
            my $x_pos;
            my $y_pos;
            if ($id_column != -1) {
                $fptr->read_col(TFLOAT, $id_column, 1, 1, $nrows, undef, $id, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for ID column: $status $text";
                }
            }
            if ($ra_column != -1) {
                $fptr->read_col(TFLOAT, $ra_column, 1, 1, $nrows, undef, $ra, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for RA column: $status $text";
                }
            }
            if ($dec_column != -1) {
                $fptr->read_col(TFLOAT, $dec_column, 1, 1, $nrows, undef, $dec, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for Dec column: $status $text";
                }
            }
            if ($iso_flux_column != -1) {
                $fptr->read_col(TFLOAT, $iso_flux_column, 1, 1, $nrows, undef, $iso_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for isophotal flux column: $status $text";
                }
            }
            if ($total_flux_column != -1) {
                $fptr->read_col(TFLOAT, $total_flux_column, 1, 1, $nrows, undef, $total_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for tottal flux column: $status $text";
                }
            }
            if ($core_flux_column != -1) {
                $fptr->read_col(TFLOAT, $core_flux_column, 1, 1, $nrows, undef, $core_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for core flux column: $status $text";
                }
            }
            if ($core1_flux_column != -1) {
                $fptr->read_col(TFLOAT, $core1_flux_column, 1, 1, $nrows, undef, $core1_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for core1 flux column: $status $text";
                }
            }
            if ($core2_flux_column != -1) {
                $fptr->read_col(TFLOAT, $core2_flux_column, 1, 1, $nrows, undef, $core2_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for core2 flux column: $status $text";
                }
            }
            if ($core3_flux_column != -1) {
                $fptr->read_col(TFLOAT, $core3_flux_column, 1, 1, $nrows, undef, $core3_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for core3 flux column: $status $text";
                }
            }
            if ($core4_flux_column != -1) {
                $fptr->read_col(TFLOAT, $core4_flux_column, 1, 1, $nrows, undef, $core4_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for core4 flux column: $status $text";
                }
            }
            if ($core5_flux_column != -1) {
                $fptr->read_col(TFLOAT, $core5_flux_column, 1, 1, $nrows, undef, $core5_flux, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for core5 flux column: $status $text";
                }
            }
            if ($ell_column != -1) {
                $fptr->read_col(TFLOAT, $ell_column, 1, 1, $nrows, undef, $ell, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for ellipticity column: $status $text";
                }
            }
            if ($posang_column != -1) {
                $fptr->read_col(TFLOAT, $posang_column, 1, 1, $nrows, undef, $posang, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for position angle column: $status $text";
                }
            }
            if ($x_column != -1) {
                $fptr->read_col(TFLOAT, $x_column, 1, 1, $nrows, undef, $x_pos, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for x-coordinate column: $status $text";
                }
            }
            if ($y_column != -1) {
                $fptr->read_col(TFLOAT, $y_column, 1, 1, $nrows, undef, $y_pos, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for y-coordinate column: $status $text";
                }
            }

            # Go through each array, grabbing the information and creating a
            # new Astro::Catalog::Item object each time through.
            for (my $i = 0; $i < $nrows; $i ++) {
                my $id_value;
                if (defined $id) {
                    $id_value = $id->[$i];
                }
                my $ra_value;
                if (defined $ra) {
                    $ra_value = $ra->[$i];
                }
                my $dec_value;
                if (defined $dec) {
                    $dec_value = $dec->[$i];
                }
                my $iso_flux_value;
                if (defined $iso_flux) {
                    $iso_flux_value = $iso_flux->[$i];
                }
                my $total_flux_value;
                if (defined $total_flux) {
                    $total_flux_value = $total_flux->[$i];
                }
                my $core_flux_value;
                if (defined $core_flux) {
                    $core_flux_value = $core_flux->[$i];
                }
                my $core1_flux_value;
                if (defined $core1_flux) {
                    $core1_flux_value = $core1_flux->[$i];
                }
                my $core2_flux_value;
                if (defined $core2_flux) {
                    $core2_flux_value = $core2_flux->[$i];
                }
                my $core3_flux_value;
                if (defined $core3_flux) {
                    $core3_flux_value = $core3_flux->[$i];
                }
                my $core4_flux_value;
                if (defined $core4_flux) {
                    $core4_flux_value = $core4_flux->[$i];
                }
                my $core5_flux_value;
                if (defined $core5_flux) {
                    $core5_flux_value = $core5_flux->[$i];
                }
                my $ell_value;
                if (defined $ell) {
                    $ell_value = $ell->[$i];
                }
                my $posang_value;
                if (defined $posang) {
                    $posang_value = $posang->[$i];
                }
                my $x_pos_value;
                if (defined $x_pos) {
                    $x_pos_value = $x_pos->[$i];
                }
                my $y_pos_value;
                if (defined $y_pos) {
                    $y_pos_value = $y_pos->[$i];
                }

                # Set up the Astro::Coords object, assuming our RA and Dec are in units
                # of radians.
                my $coords;
                if (defined($ra_value) && defined($dec_value)) {
                    $coords = new Astro::Coords(
                        ra => $ra_value,
                        dec => $dec_value,
                        units => 'radians',
                        type => 'J2000',
                    );
                }

                # Set up the Astro::Flux objects.
                my $iso_flux_obj = new Astro::Flux(
                    $iso_flux_value, 'isophotal_flux', $waveband, datetime => $datetime, obsid => $obsid);
                my $total_flux_obj = new Astro::Flux(
                    $total_flux_value, 'total_flux', $waveband, datetime => $datetime, obsid => $obsid);
                my $core_flux_obj = new Astro::Flux(
                    $core_flux_value, 'core_flux', $waveband, datetime => $datetime, obsid => $obsid);
                my $core1_flux_obj = new Astro::Flux(
                    $core1_flux_value, 'core1_flux', $waveband, datetime => $datetime, obsid => $obsid);
                my $core2_flux_obj = new Astro::Flux(
                    $core2_flux_value, 'core2_flux', $waveband, datetime => $datetime, obsid => $obsid);
                my $core3_flux_obj = new Astro::Flux(
                    $core3_flux_value, 'core3_flux', $waveband, datetime => $datetime, obsid => $obsid);
                my $core4_flux_obj = new Astro::Flux(
                    $core4_flux_value, 'core4_flux', $waveband, datetime => $datetime, obsid => $obsid);
                my $core5_flux_obj = new Astro::Flux(
                    $core5_flux_value, 'core5_flux', $waveband, datetime => $datetime, obsid => $obsid);

                # And set up the Astro::Catalog::Item::Morphology object.
                my $morphology = new Astro::Catalog::Item::Morphology(
                    ellipticity => $ell_value,
                    position_angle_pixel => $posang_value,
                );

                # And create the Astro::Catalog::Item object from this conglomoration of data.
                my $star = new Astro::Catalog::Item(ID => $id_value,
                        Fluxes => new Astro::Fluxes($iso_flux_obj,
                            $total_flux_obj,
                            $core_flux_obj,
                            $core1_flux_obj,
                            $core2_flux_obj,
                            $core3_flux_obj,
                            $core4_flux_obj,
                            $core5_flux_obj),
                        Coords => $coords,
                        X => $x_pos_value,
                        Y => $y_pos_value,
                        Morphology => $morphology);

                # Push it onto the Astro::Catalog object.
                $catalog->pushstar($star);
            }

        }
        $status = 0;

        # Move to the next one.
        $fptr->movrel_hdu(1, $hdutype, $status);
        last if $status == END_OF_FILE;

        # And set $hdu_pos.
        $fptr->get_hdu_num($hdu_pos);
    }

    # Set the origin.
    $catalog->origin('IO::FITSTable');

    # And return.
    return $catalog;
}

=item B<_write_catalog>

Create an output catalog as a binary FITS table.

    $ref = Astro::Catalog::IO::FITSTable->_write_catalog($catalog);

Argument is an C<Astro::Catalog> object.

This method is not yet implemented.

=cut

sub _write_catalog {
    croak "Not yet implemented.";
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
