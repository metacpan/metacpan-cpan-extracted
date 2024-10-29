package Astro::Catalog::IO::JCMT_OT_SC;

=head1 NAME

Astro::Catalog::IO::JCMT_OT_SC - JCMT OT Survey Container format catalog parser

=cut

use strict;
use warnings;
use warnings::register;

use Carp;

use Astro::Telescope;
use Astro::Coords;
use Astro::Catalog;
use Astro::Catalog::Item;

use parent qw/Astro::Catalog::IO::ASCII/;

our $VERSION = '4.38';

our $BASE_TAG = 'SCIENCE';

=head1 METHODS

=over 4

=item B<_read_catalog>

Parses the catalog lines and returns a new C<Astro::Catalog> object.

    $cat = Astro::Catalog::IO::JCMT_OT_SC->_read_catalog(\@lines, %options);

Options:

=over 4

=item telescope

Name of telescope to associate with each entry. [Default: JCMT]

=item tag

Only read targets with the given tag, e.g. SCIENCE.  [Default: read all tags]

=back

=cut

sub _read_catalog {
    my $class = shift;
    my $lines = shift;

    my %default = (
        telescope => 'JCMT',
    );

    my %options = (%default, @_);

    croak "_read_catalog: catalog lines must be an array reference"
        unless 'ARRAY' eq ref $lines;

    my $tel = undef;
    $tel = new Astro::Telescope($options{'telescope'})
        if defined $options{'telescope'};

    my $selected_tag = undef;
    if (exists $options{'tag'} and defined $options{'tag'}) {
        $selected_tag = $options{'tag'};
    }

    my @items;
    my %cat_misc = ();

    foreach my $line (@$lines) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless $line;

        if ($line =~ /^SURVEY_?ID/) {
            my (undef, $survey_id) = split /[:=]/, $line, 2;
            $survey_id =~ s/^\s+//;

            $cat_misc{'survey_id'} = $survey_id if $survey_id;

            next;
        }

        my ($tag, $name, $x, $y, $coord_sys, $pos_in_tile,
            $remaining, $priority, @extra) = split /[ ,;]+/, $line;

        my %opt = (
            name => $name,
        );
        my %misc = (
            tag => $tag,
        );

        my @dec_units;
        if ($coord_sys eq 'FK5' or $coord_sys eq 'J2000') {
            $opt{'type'} = 'J2000';
            $opt{'ra'} = $x;
            $opt{'dec'} = $y;
            @dec_units = ('hours', 'degrees');
        }
        elsif ($coord_sys eq 'FK4' or $coord_sys eq 'B1950') {
            $opt{'type'} = 'B1950';
            $opt{'ra'} = $x;
            $opt{'dec'} = $y;
            @dec_units = ('hours', 'degrees');
        }
        elsif ($coord_sys =~ /^GAL/) {
            $opt{'type'} = 'galactic';
            $opt{'long'} = $x;
            $opt{'lat'} = $y;
            @dec_units = ('degrees', 'degrees');
        }
        else {
            die "Did not recognize coordinate system '$coord_sys'";
        }

        $opt{'units'} = [
            (($x =~ /:/) ? 'sexagesimal' : $dec_units[0]),
            (($y =~ /:/) ? 'sexagesimal' : $dec_units[1])];

        my $c = new Astro::Coords(%opt);

        $c->telescope($tel) if defined $tel;

        # The OT only processes the extra columns for base positions.
        if ($tag eq $BASE_TAG) {
            if (defined $pos_in_tile) {
                $misc{'position_in_tile'} = 0 + $pos_in_tile;
            }
            if (defined $priority) {
                $misc{'priority'} = 0 + $priority;
            }
            if (defined $remaining) {
                $misc{'remaining'} = 0 + $remaining;
            }
        }

        if ((not defined $selected_tag) or ($tag eq $selected_tag)) {
            push @items, new Astro::Catalog::Item(
                id => $name,
                coords => $c,
                misc => \%misc,
            );
        }
    }

    return new Astro::Catalog(Stars => \@items, Misc => \%cat_misc);
}

=item B<_write_catalog>

Write the catalog to an array of lines.

    $lines = Astro::Catalog::IO::JCMT_OT_SC->_write_catalog($cat);

=cut

sub _write_catalog {
    my $class = shift;
    my $cat = shift;

    my @lines;

    my $cat_misc = $cat->misc;
    if (defined $cat_misc) {
        if (exists $cat_misc->{'survey_id'} and defined $cat_misc->{'survey_id'}) {
            push @lines, sprintf 'SURVEYID = %s', $cat_misc->{'survey_id'};
        }
    }

    for my $item ($cat->stars) {
        my $coords = $item->coords;
        my $name = $coords->name;
        my $type = $coords->type;
        my $misc = $item->misc;
        $misc = {} unless defined $misc;

        if ($type eq 'RADEC') {
            my ($x, $y, $type);
            unless ('glonglat' eq $coords->native) {
                $type = 'FK5';
                $x = $coords->ra(format => 'sexagesimal');
                $y = $coords->dec(format => 'sexagesimal');
            }
            else {
                $type = 'GAL';
                my ($lon, $lat) = $coords->glonglat();
                $x = $lon->in_format('sexagesimal');
                $y = $lat->in_format('sexagesimal');
            }

            $x =~ s/^\s//;
            $y =~ s/^\s//;

            my $tag = (exists $misc->{'tag'} and defined $misc->{'tag'})
                ? $misc->{'tag'} : 'SCIENCE';

            # Fill in extra columns right to left, so that we can set defaults
            # for any undefined values in columns to the left of defined ones.
            my @extra = ();
            if (exists $misc->{'priority'} and defined $misc->{'priority'}) {
                unshift @extra, $misc->{'priority'};
            }
            if (exists $misc->{'remaining'} and defined $misc->{'remaining'}) {
                unshift @extra, $misc->{'remaining'};
            }
            elsif (@extra) {
                unshift @extra, 1;
            }
            if (exists $misc->{'position_in_tile'} and defined $misc->{'position_in_tile'}) {
                unshift @extra, $misc->{'position_in_tile'};
            }
            elsif (@extra) {
                unshift @extra, -1;
            }

            # Remove separators ( ,;) and other possibly problematic characters from name.
            $name =~ s/[^-()+.0-9:=A-Z_a-z]/_/g;

            push @lines, join ' ', $tag, $name, $x, $y, $type, @extra;
        }
        else {
            warnings::warnif "Coordinate of type '$type' for target '$name' not currently supported\n";
        }
    }

    return \@lines;
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
