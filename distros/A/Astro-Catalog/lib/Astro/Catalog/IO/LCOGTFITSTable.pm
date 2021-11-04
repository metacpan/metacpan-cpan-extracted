package Astro::Catalog::IO::LCOGTFITSTable;

=head1 NAME

Astro::Catalog::IO::LCOGTFITSTable - Binary LCOGT FITS table I/O for Astro::Catalog

=head1 SYNOPSIS

    $cat = Astro::Catalog::IO::LCOGTFITSTable->_read_catalog($whatever);

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

use POSIX qw/log10/;
use base qw/Astro::Catalog::IO::Binary/;

our $VERSION = '4.36';
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

    $input_format = Astro::Catalog::IO::LCOGTFITSTable->input_format;

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
containing the catalogue entries.

    $cat = Astro::Catalog::IO::LCOGTFITSTable->_read_catalog($whatever);

The current translations from FITS table column names to
C<Astro::Catalog::Item> properties are:

=over 4

=item No. - ID

=item X_coordinate - X

=item Y_coordinate - Y

=item RA & DEC - Coords

=item Isophotal_flux, Total_flux, Total_flux_err, Core_flux, Core1_flux, Core2_flux,
 Core3_flux, Core4_flux - C<Astro::Flux> objects pushed into
 the C<Astro::Catalog::Item> fluxes accessor.

=item Isoarea, Ellipticity & Position_angle - Morphology

=item Flags - Quality

=back

RA and Dec are assumed to be in J2000 coordinates, and are in units
of degrees. The total flux is assumed to be in units of counts,
and is converted into a magnitude through the formula -2.5 * log10( flux ).
The position angle is assumed to be the angle measured counter-
clockwise from the positive x axis, in degrees.

An attempt to read in the DATE-OBS header is made so that flux measurements
can be timestamped. If the DATE-OBS header does not exist, then the current
date and time will be used for the flux timestamps.

There are optional named parameters. These are case-sensitive, and are:

=item Filter - An Astro::WaveBand object denoting the waveband that
the catalogue values were measured in.

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

    if ((defined $args{'Filter'}) &&
            ! UNIVERSAL::isa($args{'Filter'}, "Astro::WaveBand")) {
        croak "Filter as passed to LCOGTFITSTable->_read_catalog must be an Astro::WaveBand object";
    }

    my $filter;
    if (defined $args{'Filter'}) {
        print "Filter defined\n" if $DEBUG;
        $filter = $args{'Filter'}->natural;
    }
    else {
        $filter = 'unknown';
    }
    print "Input Filter=$filter\n" if $DEBUG;
    # A lookup table for column name mappings.
    my %column_name = (
        'ID' => 'NUMBER',
        'X' => 'X_IMAGE',
        'Y' => 'Y_IMAGE',
        'RA' => 'ALPHA_J2000',
        'Dec' => 'DELTA_J2000',
        'isophotal_flux' => 'FLUX_ISO',
        'total_flux' => 'FLUX_AUTO',
        'total_flux_err' => 'FLUXERR_AUTO',
        'core_flux' => 'FLUX_APER',
        'core1_flux' => 'FLUX_APER1',
        'core2_flux' => 'FLUX_APER2',
        'core3_flux' => 'FLUX_APER3',
        'core4_flux' => 'FLUX_APER4',
        'isoarea' => 'ISOAREA_IMAGE',
        'ellipticity' => 'ELLIPTICITY',
        'position_angle' => 'THETA_IMAGE',
        'flags' => 'FLAGS',
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

    my $datetime;
    my $waveband;
    while ($hdu_pos <= $num_hdus) {
        # Get the type of HDU for the one we're at.
        $fptr->get_hdu_type(my $hdutype, $status);
        if ($status != 0) {
            Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
            croak "Error retrieving HDU type from FITS file: $status $text";
        }
        print "hdutype=$hdutype\n" if $DEBUG;
        if ($hdutype == IMAGE_HDU) {
            # Try to retrieve the DATE-OBS header. This will be used
            # to give each flux measurement a datetime stamp. If DATE-OBS
            # cannot be determined, then set the datetime to the current
            # time.

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
            print "DATE-OBS=$datetime\n" if $DEBUG;

            unless (defined $filter) {
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
                print "Filter from header=$filter\n" if $DEBUG;
            }
            $waveband = new Astro::WaveBand(Filter => $filter);
            print "FILTER, waveband=$filter\n" if $DEBUG;

        }
        elsif ($hdutype == BINARY_TBL) {
            print "2 Wavelength= " . $waveband->wavelength . ", Frequency=" . $waveband->frequency . "\n" if $DEBUG;
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
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding total flux column: $status $text";
            }
            if ($total_flux_column == 0) {
                $total_flux_column = -1;
            }
            print "Total flux column: $total_flux_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'total_flux_err'}, my $total_flux_err_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $total_flux_err_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding total flux err column: $status $text";
            }
            if ($total_flux_err_column == 0) {
                $total_flux_err_column = -1;
            }
            print "Total flux err column: $total_flux_err_column\n" if $DEBUG;

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

            $fptr->get_colnum(CASEINSEN, $column_name{'isoarea'}, my $isoarea_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $isoarea_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding isoarea column: $status $text";
            }
            if ($isoarea_column == 0) {
                $isoarea_column = -1;
            }
            print "Isoarea column: $isoarea_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'ellipticity'}, my $ell_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $ell_column = -1;
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
                $posang_column = -1;
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
                $x_column = -1;
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
                $y_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding y-coordinate column: $status $text";
            }
            if ($y_column == 0) {
                $y_column = -1;
            }
            print "Y-coordinate column: $y_column\n" if $DEBUG;

            $fptr->get_colnum(CASEINSEN, $column_name{'flags'}, my $flag_column, $status);
            if ($status == COL_NOT_FOUND) {
                $status = 0;
                $flag_column = -1;
            }
            elsif ($status != 0) {
                Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                croak "Error in finding flags column: $status $text";
            }
            if ($flag_column == 0) {
                $flag_column = -1;
            }
            print "Flags column: $flag_column\n" if $DEBUG;

            # Now that we've got all the columns defined, we need to grab each column
            # in one big array, then take those arrays and stuff the information into
            # Astro::Catalog::Item objects
            my $id;
            my $ra;
            my $dec;
            my ($iso_flux, $total_flux, $total_flux_err, $core_flux, $core1_flux, $core2_flux);
            my ($core3_flux, $core4_flux);
            my $isoarea;
            my $ell;
            my $posang;
            my $x_pos;
            my $y_pos;
            my $flags;
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
                    croak "Error in retrieving data for total flux column: $status $text";
                }
            }
            if ($total_flux_err_column != -1) {
                $fptr->read_col(TFLOAT, $total_flux_err_column, 1, 1, $nrows, undef, $total_flux_err, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for total flux err column: $status $text";
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
            if ($isoarea_column != -1) {
                $fptr->read_col(TINT, $isoarea_column, 1, 1, $nrows, undef, $isoarea, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for isoarea column: $status $text";
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
            if ($flag_column != -1) {
                $fptr->read_col(TINT, $flag_column, 1, 1, $nrows, undef, $flags, undef, $status);
                if ($status != 0) {
                    Astro::FITS::CFITSIO::fits_get_errstatus($status, my $text);
                    croak "Error in retrieving data for flags column: $status $text";
                }
            }

            # Go through each array, grabbing the information and creating a
            # new Astro::Catalog::Item object each time through.
            for (my $i = 0; $i < $nrows; $i++) {
                my $id_value;
                if ($id_column != -1) {
                    $id_value = $id->[$i];
                }
                my $ra_value;
                if ($ra_column != -1) {
                    $ra_value = $ra->[$i];
                }
                my $dec_value;
                if ($dec_column != -1) {
                    $dec_value = $dec->[$i];
                }
                my $iso_flux_value;
                if ($iso_flux_column != -1) {
                    $iso_flux_value = $iso_flux->[$i];
                }
                my $total_flux_value;
                if ($total_flux_column != -1) {
                    $total_flux_value = $total_flux->[$i];
                }
                my $total_flux_err_value;
                if ($total_flux_err_column != -1) {
                    $total_flux_err_value = $total_flux_err->[$i];
                }
                my $core_flux_value;
                if ($core_flux_column != -1) {
                    $core_flux_value = $core_flux->[$i];
                }
                my $core1_flux_value;
                if ($core1_flux_column != -1) {
                    $core1_flux_value = $core1_flux->[$i];
                }
                my $core2_flux_value;
                if ($core2_flux_column != -1) {
                    $core2_flux_value = $core2_flux->[$i];
                }
                my $core3_flux_value;
                if ($core3_flux_column != -1) {
                    $core3_flux_value = $core3_flux->[$i];
                }
                my $core4_flux_value;
                if ($core4_flux_column != -1) {
                    $core4_flux_value = $core4_flux->[$i];
                }
                my $isoarea_value;
                if ($isoarea_column != -1) {
                    $isoarea_value = $isoarea->[$i];
                }
                my $ell_value;
                if ($ell_column != -1) {
                    $ell_value = $ell->[$i];
                }
                my $posang_value;
                if ($posang_column != -1) {
                    $posang_value = $posang->[$i];
                }
                my $x_pos_value;
                if ($x_column != -1) {
                    $x_pos_value = $x_pos->[$i];
                }
                my $y_pos_value;
                if ($y_column != -1) {
                    $y_pos_value = $y_pos->[$i];
                }
                my $flags_value = 0;
                if ($flag_column != -1) {
                    $flags_value = $flags->[$i];
                }

                # Create a temporary Astro::Catalog::Item object.
                my $star = new Astro::Catalog::Item();

                # Set up the Astro::Coords object, assuming our RA and Dec are in units
                # of degrees.
                my $coords;
                if (defined($ra_value) && defined($dec_value)) {
                    $coords = new Astro::Coords(
                        ra => $ra_value,
                        dec => $dec_value,
                        units => 'degrees',
                        type => 'J2000',
                    );
                    $star->coords($coords);
                }

                if ($flag_column != -1) {
                    $star->quality($flags_value);
                }
                else {
                    $star->quality(0);
                }

                if ($id_column != -1) {
                    $star->id($id_value);
                }

                if ($x_column != -1) {
                    $star->x($x_pos_value);
                }
                if ($y_column != -1) {
                    $star->y($y_pos_value);
                }

                # Set up the Astro::Flux objects.
                if ($iso_flux_column != -1) {
                    my $num;
                    $num = new Number::Uncertainty(Value => $iso_flux_value);
                    my $flux_iso = new Astro::Flux($num, 'isophotal_flux', $waveband,
                            datetime => $datetime, obsid => $obsid);
                    $star->fluxes(new Astro::Fluxes($flux_iso));
                }

                if ($total_flux_column != -1) {
                    my $num;
                    $num = new Number::Uncertainty(Value => $total_flux_value);
                    my $flux_total = new Astro::Flux($num, 'total_flux', $waveband,
                            datetime => $datetime, obsid => $obsid );
                    $star->fluxes(new Astro::Fluxes($flux_total));
                }

                if ($core_flux_column != -1) {
                    my $num;
                    $num = new Number::Uncertainty(Value => $core_flux_value);
                    my $core_flux_obj = new Astro::Flux($num, 'core_flux', $waveband,
                            datetime => $datetime, obsid => $obsid );
                    $star->fluxes(new Astro::Fluxes($core_flux_obj));
                }

                if ($core1_flux_column != -1) {
                    my $num;
                    $num = new Number::Uncertainty(Value => $core1_flux_value);
                    my $core1_flux_obj = new Astro::Flux($num, 'core1_flux', $waveband,
                            datetime => $datetime, obsid => $obsid );
                    $star->fluxes(new Astro::Fluxes($core1_flux_obj));
                }

                if ($core2_flux_column != -1) {
                    my $num;
                    $num = new Number::Uncertainty(Value => $core2_flux_value);
                    my $core2_flux_obj = new Astro::Flux($num, 'core2_flux', $waveband,
                            datetime => $datetime, obsid => $obsid );
                    $star->fluxes(new Astro::Fluxes($core2_flux_obj));
                }

                if ($core3_flux_column != -1) {
                    my $num;
                    $num = new Number::Uncertainty(Value => $core3_flux_value);
                    my $core3_flux_obj = new Astro::Flux($num, 'core3_flux', $waveband,
                            datetime => $datetime, obsid => $obsid );
                    $star->fluxes(new Astro::Fluxes($core3_flux_obj));
                }

                if ($core4_flux_column != -1) {
                    my $num;
                    $num = new Number::Uncertainty(Value => $core4_flux_value);
                    my $core4_flux_obj = new Astro::Flux($num, 'core4_flux', $waveband,
                        datetime => $datetime, obsid => $obsid);
                    $star->fluxes(new Astro::Fluxes($core4_flux_obj));
                }

                # Compute a magnitude and mag. error from the total flux value and total
                # flux error (if available).
                if ($total_flux_value > 0.0 and $total_flux_err_value > 0.0) {
                    my $mag = -2.5 * log10($total_flux_value);
                    my $num;
                    if ($total_flux_err_column != -1) {
                        my $magerr = 2.5 / log(10) * $total_flux_err_value / $total_flux_value;
                        $num = new Number::Uncertainty(
                            Value => $mag,
                            Error => 2.0 * $magerr);
                    }
                    else {
                        $num = new Number::Uncertainty(Value => $mag);
                    }
                    my $mag_obj = new Astro::Flux($num, 'MAG',  $waveband,
                        datetime => $datetime, obsid => $obsid);
                    $star->fluxes(new Astro::Fluxes($mag_obj));
                }
                # And set up the Astro::Catalog::Item::Morphology object.
                my $morphology = new Astro::Catalog::Item::Morphology(
                    area => $isoarea_value,
                    ellipticity => $ell_value,
                    position_angle_pixel => $posang_value,
                );
                $star->morphology($morphology);


                # Push it onto the Astro::Catalog object.
                $catalog->pushstar($star);
            }

        }
        $status = 0;

        # Move to the next one.
        $fptr->movrel_hdu(1, $hdutype, $status);
        last if ($status == END_OF_FILE);

        # And set $hdu_pos.
        $fptr->get_hdu_num($hdu_pos);
    }

    # Set the origin.
    $catalog->origin('IO::LCOGTFITSTable');

    # And return.
    return $catalog;
}

=item B<_write_catalog>

Create an output catalog as a binary FITS table.

    $ref = Astro::Catalog::IO::LCOGTFITSTable->_write_catalog($catalog);

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

Copyright (C) 2012 Las Cumbres Observatory Global Telescope Network.
All Rights Reserved.

This module is free software;
you can redistribute it and/or modify it under the terms of the GNU
Public License.

=head1 AUTHORS

Tim Lister E<lt>tlister@lcogt.netE<gt>

=cut
