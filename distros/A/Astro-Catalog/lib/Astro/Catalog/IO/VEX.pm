package Astro::Catalog::IO::VEX;

=head1 NAME

Astro::Catalog::IO::VEX - Module to read/write sources in VEX format

=cut

use strict;
use warnings;
use warnings::register;

use Carp;

use Astro::Coords;
use Astro::Telescope;
use Astro::VEX;
use Astro::VEX::Block;
use Astro::VEX::Def;
use Astro::VEX::Param;
use Astro::VEX::Param::String;

use Astro::Catalog;
use Astro::Catalog::Item;

use parent qw/Astro::Catalog::IO::ASCII/;

our $VERSION = '4.37';

=head1 METHODS

=over 4

=item B<_read_catalog>

Parses the catalog lines and returns a new C<Astro::Catalog> object.

    $cat = Astro::Catalog::IO::VEX->_read_catalog(\@lines, %options);

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

    my $vex = new Astro::VEX(text => join "\n", @$lines);

    my @items;
    foreach my $source ($vex->block('SOURCE')->items) {
        my $key_name = $source->name;
        my $name = eval {$source->param('source_name')->value;};
        if (defined $name) {
            warnings::warnif 'WARNING: source_name ' . $name. ' does not match keyword ' . $key_name . "\n"
                unless $name eq $source->name;
        }
        else {
            $name = $key_name;
            warnings::warnif 'WARNING: source_name missing, using keyword ' . $key_name . "\n"
        }

        my $ra_str = $source->param('ra')->value;
        die "Did not understand RA '$ra_str' for '$name'" unless $ra_str =~ /^(\d+)h(\d+)m(\d+\.\d+)s$/;
        my $ra = "$1:$2:$3";
        my $dec_str = $source->param('dec')->value;
        die "Did not understand Dec '$dec_str' for '$name'" unless $dec_str =~ /^(-?\d+)d(\d+)'(\d+.\d+)"$/;
        my $dec = "$1:$2:$3";
        die 'Coordinate system not J2000' unless $source->param('ref_coord_frame')->value eq 'J2000';

        my $coords = new Astro::Coords(
            name => $name,
            ra => $ra,
            dec => $dec,
            type => 'J2000',
            units => 'sexagesimal');

        $coords->telescope($tel) if defined $tel;

        push @items, new Astro::Catalog::Item(
            id => $name,
            coords => $coords,
        );
    }

    return new Astro::Catalog(Stars => \@items);
}

=item B<_write_catalog>

Write the catalog to an array of lines.

    $lines = Astro::Catalog::IO::VEX->_write_catalog($cat);

=cut

sub _write_catalog {
    my $class = shift;
    my $cat = shift;

    my @sources;
    for my $item ($cat->stars) {
        my $coords = $item->coords;
        my $name = $coords->name;
        my $type = $coords->type;

        # Remove problematic characters from name.
        $name =~ s/[^-!#%'()+,\.\/0-9<>?\@A-Z\[\\\]^_`a-z{|}~]/_/g;

        if ($type eq 'RADEC') {
            my $ra = $coords->ra->components(7);
            die 'RA array not in expected format' unless $ra->[0] eq '+' && 4 == scalar @$ra;
            shift @$ra;
            my $dec = $coords->dec->components(6);
            die 'Dec array not in expected format' unless $dec->[0] =~ /^[-+]$/ && 4 == scalar @$dec;
            $dec->[0] = '' if $dec->[0] eq '+';

            push @sources, new Astro::VEX::Def($name, [
                new Astro::VEX::Param('source_name', [new Astro::VEX::Param::String($name)]),
                new Astro::VEX::Param('ra', [new Astro::VEX::Param::String(sprintf('%02dh%02dm%010.7fs', @$ra))]),
                new Astro::VEX::Param('dec', [new Astro::VEX::Param::String(sprintf('%s%02dd%02d\'%09.6f"', @$dec))]),
                new Astro::VEX::Param('ref_coord_frame', [new Astro::VEX::Param::String('J2000')]),
            ]);
        }
        else {
            warnings::warnif "Coordinate of type '$type' for target '$name' not currently supported\n";
        }
    }

    my $vex = new Astro::VEX(version => '1.5', content => [
        new Astro::VEX::Block('SOURCE', \@sources),
    ]);

    return [split "\n", "$vex"];
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
