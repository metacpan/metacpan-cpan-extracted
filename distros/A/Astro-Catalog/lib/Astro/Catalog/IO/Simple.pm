package Astro::Catalog::IO::Simple;

=head1 NAME

Astro::Catalog::IO::Simple - Simple Input/Output format

=head1 SYNOPSIS

    $catalog = Astro::Catalog::IO::Simple->_read_catalog(\@lines);
    $lines = Astro::Catalog::IO::Simple->_write_catalog($catalog);
    Astro::Catalog::IO::Simple->_default_file();

=head1 DESCRIPTION

Performs simple IO, reading or writing "id_string hh mm ss.s +dd mm ss.s"
formated strings for each Astro::Catalog::Item object in the catalog.

=cut

use strict;
use warnings;
use warnings::register;
use Carp;

use Astro::Catalog;
use Astro::Catalog::Item;
use Astro::Coords;

use base qw/Astro::Catalog::IO::ASCII/;

use Data::Dumper;

our $VERSION = '4.36';

=begin __PRIVATE_METHODS__

=head1 Private methods

These methods are for internal use only and are called from the
Astro::Catalog module. It is not expected that anyone would want to
call them from outside that module.

=over 4

=item B<_read_catalog>

Parses a reference to an array containing a simply formatted catalogue

    $catalog = Astro::Catalog::IO::Simple->_read_catalog(\@lines);

=cut

sub _read_catalog {
    croak('Usage: _read_catalog(\@lines)') unless scalar(@_) >= 1;
    my $class = shift;
    my $arg = shift;
    my @lines = @{$arg};

    # create an Astro::Catalog object;
    my $catalog = new Astro::Catalog();

    # loop through lines
  MAINLOOP:
    foreach my $i ( 0 .. $#lines ) {

        # Skip commented and blank lines
        next if ($lines[$i] =~ /^\s*[\#\*\%]/);
        next if ($lines[$i] =~ /^\s*$/);

        # temporary star object
        my $star = new Astro::Catalog::Item();

        # Use a pattern match parser
        my @match = ( $lines[$i] =~ m/
            ^(.*?)  # Target name (non greedy)
            \s*   # optional trailing space
            (\d{1,2}) # 1 or 2 digits [RA:h] [greedy]
            [:\s]+       # separator
            (\d{1,2}) # 1 or 2 digits [RA:m]
            [:\s]+       # separator
            (\d{1,2}(?:\.\d*)?) # 1|2 digits opt .fraction [RA:s]
# no capture on fraction
            [:\s]+
            ([+-]?\s*\d{1,2}) # 1|2 digit [dec:d] inc sign
            [:\s]+
            (\d{1,2}) # 1|2 digit [dec:m]
            [:\s]+
            (\d{1,2}(?:\.\d*)?) # arcsecond (optional fraction)
# no capture on fraction
            \s*
            (RB|RJ|AZ|GA|AZEL|J2000|B1950|Galactic)? # coordinate type

# most everything else is optional
            \s*
            (?:\#\s*(.*))?$                    # comment [8]
        /xi);

        # Abort if we do not have matches for the first 8 fields
        # type is optional
        for (0 ... 6) {
            next MAINLOOP unless defined $match[$_];
        }

        # Read the values
        my $target = $match[0];
        my $ra = join(":", @match[1..3]);
        my $dec = join(":", @match[4..6]);
        $dec =~ s/\s//g; # remove  space between the sign and number

        # Type defaults to J2000
        my $type = $match[7] || "J2000";
        $type = uc($type);

        # Comment can be undefined
        my $comment = $match[8];

        # push the target id
        $star->id($target);

        # push the comment
        $star->comment($comment) if defined $comment;

        # Allow simple mapping of TYPE from JCMT abbreviations.
        # This does not hurt things or break simplicity of the format.
        # The form of the hash depends on the type
        my %c;
        if ($type =~ /(RB|RJ|J2000|B1950)/) {
            # Standard RADEC
            $c{ra} = $ra;
            $c{dec} = $dec;

            if ($type =~ /B/) {
                $c{type} = "B1950";
            }
            else {
                $c{type} = "J2000";
            }
        }
        elsif ($type =~ /^(GA|SUPERGAL)/) {
            $c{long} = $ra;
            $c{lat} = $dec;
            if ($type =~ /S/) {
                $c{type} = "SUPERGALACTIC";
            }
            else {
                $c{type} = "GALACTIC";
            }
        }
        elsif ($type =~ /^AZ/) {
            $c{az} = $ra;
            $c{el} = $dec;
        }
        else {
            croak "Unexpected coordinate type: $type\n";
        }

        # Assume J2000 and create an Astro::Coords object
        my $coords = new Astro::Coords(
            units => 'sex',
            name  => $star->id(),
            %c);

        croak "Error creating coordinate object from $ra / $dec "
            unless defined $coords;

        # and push it into the Astro::Catalog::Item object
        $star->coords($coords);

        # push it onto the stack
        $catalog->pushstar($star);
    }

    $catalog->origin('IO::Simple');
    return $catalog;
}

=item B<_write_catalog>

Will write the catalogue object to an simple output format

    $lines = Astro::Catalog::IO::Simple->_write_catalog($catalog);

where $catalog is an Astro::Catalog object.

=cut

sub _write_catalog {
    croak ( 'Usage: _write_catalog( $catalog )') unless scalar(@_) >= 1;
    my $class = shift;
    my $catalog = shift;

    # write header
    my @output;
    my $output_line;

    push (@output, "# Catalog written automatically by class ". __PACKAGE__ ."\n");
    push (@output, "# on date " . gmtime . "UT\n" );
    push (@output, "# Origin of catalogue: ". $catalog->origin ."\n");

    # write body

    # Keep track of star count for unnamed stars
    my $starcnt = 0;

    # loop through all the stars in the catalogue
    foreach my $star ($catalog->stars) {
        # Extract the information into an array for later formatting
        my @chunks;
        my $comment; # in case we need to create a whole comment line

        # Star ID
        push(@chunks, (defined $star->id() ? $star->id : $starcnt));

        # Get the coordinate information
        my $c = $star->coords;

        if (defined $c) {
            my $type = $c->type;

            if ($type eq 'RADEC') {
                # Standard J2000
                push(@chunks, $c->ra(format => 's'), $c->dec(format => 's'), "J2000");
            }
            elsif ($type eq 'FIXED') {
                push(@chunks, $c->az(format => 's'), $c->el(format => 's'), "AZEL");
            }
            else {
                $comment = "Can not represent star $chunks[0] in catalogue since it is of type $type";
            }

        }
        else {
            $comment = "Star $chunks[0] has no coordinates.";
        }

        # now the line. If we have comment set this is just a comment line
        if (defined $comment) {
            push(@output, "# $comment");
        }
        else {
            my $cmt = '';
            $cmt = " # " .$star->comment()
                if $star->comment();

            push(@output, sprintf("%-15s %s %s %s", @chunks) . $cmt);
        }
    }

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

The Simple format is defined as follows: Any line that looks like

    ID  HH MM SS.SS +/-DD MM SS.SS TYPE # Comment

will be matched. A space is allowed between the sign and the
declination. The type is optional (as is the comment) and
can be one of J2000, B1950, GALACTIC, AZEL or SUPERGALACTIC
or the JCMT abbreviations (RJ, RB, GA or AZ). If TYPE is not
present J2000 is assumed.

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
Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=cut
