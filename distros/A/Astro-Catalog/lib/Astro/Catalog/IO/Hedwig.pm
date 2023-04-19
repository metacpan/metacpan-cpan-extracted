package Astro::Catalog::IO::Hedwig;

=head1 NAME

Astro::Catalog::IO::Hedwig - Hedwig format catalog parser

=cut

use warnings;
use warnings::register;
use Carp;
use strict;

use Text::CSV;
use Astro::Telescope;
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Item;

use parent qw/Astro::Catalog::IO::ASCII/;

our $VERSION = '4.37';

=head1 METHODS

=over 4

=item B<_read_catalog>

Parses the catalog lines and returns a new C<Astro::Catalog> object.

    $cat = Astro::Catalog::IO::Hedwig->_read_catalog(\@lines, %options);

Options:

=over 4

=item telescope

Name of telescope to associate with each entry.

=back

=cut

sub _read_catalog {
    my $class = shift;
    my $lines = shift;

    my %options = @_;

    croak "_read_catalog: catalog lines must be an array reference"
        unless 'ARRAY' eq ref $lines;

    my $tel = undef;
    $tel = new Astro::Telescope($options{'telescope'})
        if defined $options{'telescope'};

    my $pattern_decimal = qr/^[-+]?\d*(?:\.\d*)?$/;
    my $pattern_sexagesimal = qr/^[-+]?[\d.:]+$/;

    # Ideally would sniff the CSV format from the first line, allowing ' \t,;'
    # delimiters but for now use default settings.
    my $csv = _get_csv_parser();

    my @items;
    foreach my $line (@$lines) {
        $line =~ s/^\s*//;
        $line =~ s/\s*$//;
        next unless $line;

        $csv->parse($line)
            or croak "Unable to parse CSV line '$line'";

        my ($name, $x, $y, $system, $time, $priority, $comment)
            = $csv->fields();

        my %opt = (
            name => $name,
        );

        my %misc = ();

        # Detect units: decimal or sexagesimal.

        my $x_dec = 0;
        if ($x =~ $pattern_decimal) {
            $x_dec = 1;
        }
        elsif ($x !~ $pattern_sexagesimal) {
            die "Did not recognize format of number '$x'";
        }

        my $y_dec = 0;
        if ($y =~ $pattern_decimal) {
            $y_dec = 1;
        }
        elsif ($y !~ $pattern_sexagesimal) {
            die "Did not recognize format of number '$y'";
        }

        if ($x_dec xor $y_dec) {
            die "Coordinates seem to have inconsistent number formats: '$x' '$y'";
        }

        # Hedwig assumes decimals are degrees, otherwise (hour angle, degree)
        # for ICRS, (degree, degree) for Galactic -- Astro::Coords should do
        # this automatically when specifying 'sexagesimal'.
        $opt{'units'} = $x_dec ? 'degrees' : 'sexagesimal';

        if ('ICRS' eq uc $system) {
            $opt{'type'} = 'J2000';
            $opt{'ra'} = $x;
            $opt{'dec'} = $y;
        }
        elsif ('GALACTIC' eq uc $system) {
            $opt{'type'} = 'galactic';
            $opt{'long'} = $x;
            $opt{'lat'} = $y;
        }
        else {
            die "Did not recognize coordinate system '$system'";
        }

        if (defined $priority) {
            $misc{'priority'} = 0 + $priority;
        }
        if (defined $time) {
            $misc{'time_hours'} = 0.0 + $time;
        }

        my $c = new Astro::Coords(%opt);

        $c->telescope($tel) if defined $tel;

        push @items, new Astro::Catalog::Item(
            id => $name,
            coords => $c,
            misc => \%misc,
            comment => $comment,
        );
    }

    return new Astro::Catalog(Stars => \@items);
}

=item B<_write_catalog>

Write the catalog to an array of lines.

    $lines = Astro::Catalog::IO::Hedwig->_write_catalog($cat);

=cut

sub _write_catalog {
    my $class = shift;
    my $cat = shift;

    my $csv = _get_csv_parser();

    my @lines;
    for my $item ($cat->stars) {
        my $coords = $item->coords;
        my $name = $coords->name;
        my $type = $coords->type;

        if ($type eq 'RADEC') {
            my ($x, $y, $type);
            unless ('glonglat' eq $coords->native) {
                $type = 'ICRS';
                $x = $coords->ra(format => 'sexagesimal');
                $y = $coords->dec(format => 'sexagesimal');
            }
            else {
                $type = 'Galactic';
                my ($lon, $lat) = $coords->glonglat();
                $x = sprintf('%.6f', $lon->degrees());
                $y = sprintf('%.6f', $lat->degrees());
                # After formatting to 6 DP to avoid rounding errors, trim
                # trailing zeros and decimal place.
                $x =~ s/0+$// if $x =~ /\./; $x =~ s/\.$//;
                $y =~ s/0+$// if $y =~ /\./; $y =~ s/\.$//;
            }

            my @extra = ();
            my $comment = $item->comment();
            if (defined $comment) {
                unshift @extra, $comment;
            }

            my $misc = $item->misc();
            if (defined $misc) {
                if (exists $misc->{'priority'} and defined $misc->{'priority'}) {
                    unshift @extra, $misc->{'priority'};
                }
                elsif (@extra) {
                    unshift @extra, undef;
                }
                if (exists $misc->{'time_hours'} and defined $misc->{'time_hours'}) {
                    unshift @extra, $misc->{'time_hours'};
                }
                elsif (@extra) {
                    unshift @extra, undef;
                }
            }

            # Remove excess spaces because Hedwig format (CSV-based)
            # forbids duplicated separators.
            $x =~ s/^\s//;
            $y =~ s/^\s//;

            # Remove problematic characters from name.
            $name =~ s/[^- !#$%&'()*+.\/0-9:;<=>?\@A-Z[\]^_`a-z{|}~]/_/g;

            $csv->combine($name, $x, $y, $type, @extra)
                or croak "Unable to prepare CSV line for '$name'";

            push @lines, $csv->string();
        }
        else {
            warnings::warnif "Coordinate of type '$type' for target '$name' not currently supported\n";
        }
    }

    return \@lines;
}

=item B<_get_csv_parser>

Constructs an instance of the Text::CSV class.

=cut

sub _get_csv_parser {
    return new Text::CSV({
        sep_char => ' ',
        quote_char => '"',
        blank_is_undef => 1,
        empty_is_undef => 1,
    });
}

1;

__END__

=back

=head1 COPYRIGHT

Copyright (C) 2021 East Asian Observatory
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc.,51 Franklin
Street, Fifth Floor, Boston, MA  02110-1301, USA

=cut
