package Astro::Catalog::IO::VOTable;

=head1 NAME

Astro::Catalog::IO::VOTable - VOTable Input/Output format

=head1 SYNOPSIS

    $catalog = Astro::Catalog::IO::VOTable->_read_catalog(\@lines);
    \@lines = Astro::Catalog::IO::VOTable->_write_catalog($catalog);
    Astro::Catalog::IO::VOTable->_default_file();

=head1 DESCRIPTION

Performs simple IO, reading or writing a VOTable.

=cut

use strict;
use warnings;
use warnings::register;
use Carp;

use Astro::Catalog;
use Astro::Catalog::Item;
use Astro::Coords;
use Astro::Flux;
use Astro::FluxColor;
use Astro::Fluxes;

use Astro::VO::VOTable::Document;

use base qw/Astro::Catalog::IO::ASCII/;

use Data::Dumper;

our $VERSION = '4.38';

=begin __PRIVATE_METHODS__

=head1 Private methods

These methods are for internal use only and are called from the
Astro::Catalog module. It is not expected that anyone would want to
call them from outside that module.

=over 4

=item B<_read_catalog>

Parses a reference to an array containing a simply formatted catalog

    $catalog = Astro::Catalog::IO::VOTable->_read_catalog(\@lines);

=cut

sub _read_catalog {
    croak('Usage: _read_catalog(\@lines)') unless scalar(@_) >= 1;
    my $class = shift;
    my $arg = shift;
    my @lines = @{$arg};

    # create an Astro::Catalog object;
    my $catalog = new Astro::Catalog();

    # make the array a string
    my $string = "";
    foreach my $i (0 ... $#lines) {
        $string = $string . $lines[$i] . "\n";
    }

    # create a VOTable object from the string.
    my $doc = Astro::VO::VOTable::Document->new_from_string($string);

    # Get the VOTABLE element.
    my $votable = ($doc->get_VOTABLE())[0];

    # Get the RESOURCE element.
    my $resource = ($votable->get_RESOURCE())[0];

    # Get the DESCRIPTION element and its contents.
    my $description = ($resource->get_DESCRIPTION())[0];

    # Get the DEFINITIONS element and its contents.
    my $definitions = ( $votable->get_DEFINITIONS())[0];

    my ($equinox, $epoch);
    if (defined $definitions) {
        # Get the coordinate system (COOSYS) and its contents.
        my $coosys = ( $definitions->get_COOSYS())[0];

        # ...and the equinox and epoch and system. I LOVE VOTABLE.
        $equinox = $coosys->get_equinox();
        $epoch = $coosys->get_epoch();
        my $system = $coosys->get_system();
        if( $system =~ /fk4/i ) {
            $equinox = "B" . $equinox;
        }
        else {
            $equinox = "J" . $equinox;
        }
    }
    else {
        # Assume J2000 by default?
        $equinox = 'J2000';
        $epoch = '2000.0';
    }

    # Get the TABLE element.
    my $table = ($resource->get_TABLE())[0];

    # Get the FIELD elements.
    my (@field_names, @field_ucds, @field_datatypes, @field_units, @field_sizes);

    foreach my $field ($table->get_FIELD()) {
        push @field_names, $field->get_name();
        push @field_ucds, $field->get_ucd();
        push @field_datatypes, $field->get_datatype();
        push @field_units, $field->get_unit();
        push @field_sizes, $field->get_arraysize();
    }

    # Get the DATA element.
    my $data = ($table->get_DATA())[0];

    # Get the TABLEDATA element.
    my $tabledata = ($data->get_TABLEDATA())[0];

    # loop round UCDs and try and figure out what everthing is so
    # we can stuff the table contents into the relevant places
    my %contents;
    my $units = ['sexagesimal', 'sexagesimal'];
    foreach my $i (0 ... $#field_ucds) {
        $contents{"id"} = $i if $field_ucds[$i] =~ "ID_MAIN"
                             or $field_ucds[$i] =~ /META.ID.*MAIN/i;
        if ($field_ucds[$i] =~ /POS.EQ.RA.*MAIN/i) {
            $contents{"ra"} = $i;
            $units->[0] = 'degrees' if $field_units[$i] =~ /^deg/i;
        }
        if ($field_ucds[$i] =~ /POS.EQ.DEC.*MAIN/i) {
            $contents{"dec"} = $i;
            $units->[1] = 'degrees' if $field_units[$i] =~ /^deg/i;
        }
        $contents{"quality"} = $i if $field_ucds[$i] =~ "CODE_QUALITY";
        if ($field_ucds[$i] =~ "PHOT_") {
            $contents{$field_ucds[$i]} = $i;
        }
        $contents{"parallax"} = $i if $field_ucds[$i] =~ "POS_EQ_PLX_FACTOR";
        $contents{"pm_dec"} = $i if $field_ucds[$i] =~ "POS_EQ_PMDEC";
        $contents{"pm_ra"} = $i if $field_ucds[$i] =~ "POS_EQ_PMRA";
    }

    # loop over each row in the TABLEDATA (ie each star)
    foreach my $j (0 ... $tabledata->get_num_rows()-1) {
        # grab a row
        my @row = $tabledata->get_row($j);

        # loop around the contents and grab the magnitudes and colours
        my (@fluxes, @colours);
        foreach my $key (keys %contents) {
            # drop through unless we have a magntiude
            next unless $key =~ "PHOT";

            my $identifier = $key;
            $identifier =~ s/^PHOT_[A-Z]+_//;

            # okay we either have a magnitude or a colour, why did I ever
            # make these two different things? Maybe I should re-engineer
            # the Astro::Catalog::Item so that it hides the difference in
            # some sort of meta API for both? Oh God this is so yuck...

            # colours
            if ($identifier =~ /^(\w+)-(\w+)$/) { # non-greedy
                # we might have a colour, who knows?
                my $color = new Astro::FluxColor(
                        upper => new Astro::WaveBand(Filter => $1),
                        lower => new Astro::WaveBand(Filter => $2),
                        quantity => $row[$contents{$key}]);
                unshift @colours, $color;   # I don't understand why I have
                                            # to unshift here rather than
                                            # push, this is oddly disturbing
            }
            else {
                # we might have a magnitude, who knows?
                my $flux = new Astro::Flux(
                    $row[$contents{$key}], 'mag', $identifier);
                push @fluxes, $flux;
            }
        }
        my $fluxes = new Astro::Fluxes(@fluxes, @colours);

        # Set defaults for the proper motions and parallax.
        my $pm_dec = ((exists $contents{"pm_dec"}) && (defined $contents{"pm_dec"})
            ? $row[$contents{"pm_dec"}]
            : undef);
        my $pm_ra = ((exists $contents{"pm_ra"}) && (defined $contents{"pm_ra"})
            ? $row[$contents{"pm_ra"}]
            : undef);
        my @pm;
        if (! defined($pm_dec) && ! defined($pm_ra)) {
            @pm = ();
        }
        else {
            @pm = ($pm_ra, $pm_dec);
        }
        my $parallax = ((exists $contents{"parallax"}) && (defined $contents{"parallax"})
            ? $row[$contents{"parallax"}]
            : undef);

        # Create an Astro::Coords object for the star.
        my $coords = new Astro::Coords(
            ra => $row[$contents{"ra"}],
            dec => $row[$contents{"dec"}],
            type => $equinox,
            epoch => $epoch,
            pm => \@pm,
            parallax => $parallax,
            units => $units,
        );

        # create a star
        my $star = new Astro::Catalog::Item(
            id  => $row[$contents{"id"}],
            coords => $coords,
            #magnitudes => \%mags,
            #colours => \%colours,
            fluxes => $fluxes,
            quality => $row[$contents{"quality"}]);

        # push the star onto the catalog
        $catalog->pushstar( $star );
    }

    # return the catalog
    $catalog->origin( 'IO::VOTable' );
    return $catalog;

}

=item B<_write_catalog>

Will write the catalog object to an simple output format

    $lines = Astro::Catalog::IO::VOTable->_write_catalog($catalog);

where $catalog is an Astro::Catalog object.

=cut

sub _write_catalog {
    croak('Usage: _write_catalog($catalog)') unless scalar(@_) >= 1;
    my $class = shift;
    my $catalog = shift;

    # real list of filters and colours in the catalog
    my @mags = $catalog->starbyindex(0)->what_filters();
    my @cols = $catalog->starbyindex(0)->what_colours();

    # number of stars in catalog
    my $number = $catalog->sizeof();

    # number of filters & colours
    my $num_mags = $catalog->starbyindex(0)->what_filters();
    my $num_cols = $catalog->starbyindex(0)->what_colours();

    # reference to the $self->{STARS} array in Astro::Catalog
    my $stars = $catalog->stars();

    # generate the field headers
    my (@field_names, @field_ucds, @field_datatypes, @field_units, @field_sizes);

    # field names
    push @field_names, "Identifier";
    push @field_names, "RA";
    push @field_names, "Dec";
    foreach my $i (0 .. $#mags) {
        push @field_names, $mags[$i] . " Magnitude";
        push @field_names, $mags[$i] . " Error";
    }
    foreach my $i (0 .. $#cols) {
        push @field_names, $cols[$i] . " Colour";
        push @field_names, $cols[$i] . " Error";
    }
    push @field_names, "Quality";


    # field ucds
    push @field_ucds, "ID_MAIN";
    push @field_ucds, "POS_EQ_RA_MAIN";
    push @field_ucds, "POS_EQ_DEC_MAIN";
    foreach my $i (0 .. $#mags) {
        push @field_ucds, "PHOT_MAG_" . $mags[$i];
        push @field_ucds, "CODE_ERROR";
    }
    foreach my $i (0 .. $#cols) {
        push @field_ucds, "PHOT_CI_" . $cols[$i];
        push @field_ucds, "CODE_ERROR";
    }
    push @field_ucds, "CODE_QUALITY";


    # field datatypes
    push @field_datatypes, "char";
    push @field_datatypes, "char";
    push @field_datatypes, "char";
    foreach my $i (0 .. $#mags) {
        push @field_datatypes, "double";
        push @field_datatypes, "double";
    }
    foreach my $i (0 .. $#cols) {
        push @field_datatypes, "double";
        push @field_datatypes, "double";
    }
    push @field_datatypes, "int";


    # field units
    push @field_units, "";
    push @field_units, '"h:m:s.ss"';
    push @field_units, '"d:m:s.ss"';
    foreach my $i (0 .. $#mags) {
        push @field_units, "mag";
        push @field_units, "mag";
    }
    foreach my $i (0 .. $#cols) {
        push @field_units, "mag";
        push @field_units, "mag";
    }
    push @field_units, "";


    # array size
    push @field_sizes, "*";
    push @field_sizes, "*";
    push @field_sizes, "*";

    # generate the data table
    my @data;

    foreach my $star (0 .. $#$stars) {
        my @row;

        # Check to see if we should be writing out the proper motions
        # and parallax.
        my $coords = ${$stars}[$star]->coords;

        my $name = $coords->name;
        my $type = $coords->type;
        unless ($coords->type eq 'RADEC') {
            warnings::warnif "Coordinate of type '$type' for target '$name' not currently supported\n";
            next;
        }

        if (scalar $coords->pm) {
            push @field_names, "RA Proper Motion";
            push @field_names, "Dec Proper Motion";
            push @field_ucds, "POS_EQ_PMRA";
            push @field_ucds, "POS_EQ_PMDEC";
            push @field_datatypes, "double";
            push @field_datatypes, "double";
            push @field_units, "arcsec/yr";
            push @field_units, "arcsec/yr";
        }
        if (defined $coords->parallax) {
            push @field_names, "Parallax";
            push @field_ucds, "POS_EQ_PLX_FACTOR";
            push @field_datatypes, "double";
            push @field_units, "arcsec";
        }

        # id
        if ( defined ${$stars}[$star]->id() ) {
            push @row, ${$stars}[$star]->id();
        }
        else {
            push @row, $star;
        }

        # ra & dec -- we want these in J2000.
        push @row, $coords->ra2000(format => 's');
        push @row, $coords->dec2000(format => 's');

        # magnitudes
        foreach my $i (0 .. $#mags) {
            if (defined ${$stars}[$star]->get_magnitude($mags[$i])) {
                push @row, ${$stars}[$star]->get_magnitude($mags[$i]);
            }
            else {
                push @row, "0.000";
            }
            if (defined ${$stars}[$star]->get_errors($mags[$i])) {
                push @row, ${$stars}[$star]->get_errors($mags[$i]);
            }
            else {
                push @row, "0.000";
            }
        }

        # colours
        foreach my $i (0 .. $#cols) {
            if (defined ${$stars}[$star]->get_colour($cols[$i])) {
                push @row, ${$stars}[$star]->get_colour($cols[$i]);
            }
            else {
                push @row, "0.000";
            }
            if (defined ${$stars}[$star]->get_colourerr($cols[$i])) {
                push @row, ${$stars}[$star]->get_colourerr($cols[$i]);
            }
            else {
                push @row, "0.000";
            }
        }

        # quality
        if (defined ${$stars}[$star]->quality()) {
            push @row, ${$stars}[$star]->quality();
        }
        else {
            push @row, "0";
        }

        # Proper motions and parallax
        if (defined ${$stars}[$star]->coords) {
            my $coords = ${$stars}[$star]->coords;
            my @pm = $coords->pm;
            push @row, $pm[0];
            push @row, $pm[1];
            push @row, $coords->parallax;
        }

        # push a reference to the row into the data
        push @data, \@row;
    }

    # Create the VOTABLE document.
    my $doc = new Astro::VO::VOTable::Document();

    # Get the VOTABLE element.
    my $votable = ($doc->get_VOTABLE)[0];

    # Create the DESCRIPTION element and its contents, and add it to the VOTABLE
    my $description = new Astro::VO::VOTable::DESCRIPTION();
    $description->set('Created using Astro::Catalog::IO::VOTable');
    $votable->set_DESCRIPTION($description);

    # Create a DEFINITION element and its contents and add it to the VOTABLE
    my $definitions = new Astro::VO::VOTable::DEFINITIONS();
    my $coosys = new Astro::VO::VOTable::COOSYS();
    $coosys->set_ID("J2000");
    $coosys->set_equinox(2000.0);
    $coosys->set_epoch(2000.0);
    $coosys->set_system('eq_FK5');
    $definitions->set_COOSYS( $coosys );
    $votable->set_DEFINITIONS( $definitions );

    # Create the RESOURCE element and add it to the VOTABLE.
    my $resource = new Astro::VO::VOTable::RESOURCE();
    $votable->set_RESOURCE($resource);

    # Create the LINK element and its contents, and add it to the VOTABLE
    my $link = new Astro::VO::VOTable::LINK();
    $link->set_title('eSTAR Project');
    $link->set_href('http://www.estar.org.uk/');
    $link->set_content_role('doc');
    $resource->set_LINK($link);

    # Create the TABLE element and add it to the RESOURCE.
    my $table = new Astro::VO::VOTable::TABLE();
    $resource->set_TABLE($table);

    # Create and add the FIELD elements to the TABLE.
    my ($i);
    my ($field);
    for ($i = 0; $i < @field_names; $i++) {
        $field = new Astro::VO::VOTable::FIELD();
        $field->set_name($field_names[$i]);
        $field->set_ucd($field_ucds[$i]);
        $field->set_datatype($field_datatypes[$i]);
        $field->set_unit($field_units[$i]);
        $field->set_arraysize($field_sizes[$i]) if defined $field_sizes[$i];
        $table->append_FIELD($field);
    }

    # Create and append the DATA element.
    my $data = new Astro::VO::VOTable::DATA();
    $table->set_DATA($data);

    # Create and append the TABLEDATA element.
    my $tabledata = new Astro::VO::VOTable::TABLEDATA();
    $data->set_TABLEDATA($tabledata);

    # Create and append each TR element, and each TD element.
    my ($tr, $td);
    my ($j);
    for ($i = 0; $i < @data; $i++) {
        $tr = new Astro::VO::VOTable::TR();
        for ($j = 0; $j < @field_names; $j++) {
            $td = new Astro::VO::VOTable::TD();
            $td->set($data[$i][$j]);
            $tr->append_TD($td);
        }
        $tabledata->append_TR($tr);
    }

    # Print the finished document.
    my $output_string = $doc->toString(1);
    my @output = split "\n", $output_string;

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

=end __PRIVATE_METHODS__

=head1 FORMAT

This class implements an interface to VOTable documents. This uses the
GSFC VOTable classes which inherits from XML::LibXML::Document class.

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.
Some modificiations Copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This module was written as part of the eSTAR project in collaboration
with the Joint Astronomy Centre (JAC) in Hawaii and is free software;
you can redistribute it and/or modify it under the terms of the GNU
Public License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=cut
