package Color::Brewer;

use strict;
use warnings;
use utf8;

use JSON;
use File::ShareDir;
use Params::Validate qw(:all);
use Path::Tiny;

our $VERSION = 0.001;

=encoding utf-8

=head1 NAME

Color::Brewer - Color schemes from Cynthis Brewer's ColorBrewer L<http://colorbrewer2.org/>

=head1 SYNOPSYS

	use Color::Brewer;

	my @color_scheme = Color::Brewer::named_color_scheme(name => 'RdBu', number_of_data_classes => 4);
	my @color_schemes = Color::Brewer::color_schemes(data_nature => 'sequential', number_of_data_classes => 5);

=head1 DESCRIPTION

Provides color schemes for maps designed by Cynthia Brewer. The color schemes are also suitable for data visualizations.

Choosing the best color scheme is easy. Just visit Cynthia Brewer's ColorBrewer L<http://colorbrewer2.org>.

Also adding a citation in your map, chart, ... would be nice. Something like:
    
    Colors from colorbrewer2.org, by Cynthia A. Brewer, Geography, Pennsylvania State University

This is suggested in L<http://www.personal.psu.edu/cab38/ColorBrewer/ColorBrewer_updates.html>

=cut

my $colors;

=head1 METHODS

=cut

sub _color_brewer {
    if ( !defined $colors ) {
        $colors = from_json( path( File::ShareDir::dist_file( 'Color-Brewer', 'colorbrewer.json' ) )->slurp_utf8() );
    }
    return $colors;
}

=head2 named_color_scheme

Get a named color scheme

=head3 Parameters

=over

=item * name:

Name of the color scheme: RdBu

=item * number_of_data_classes:

Number of data classes. Valid range goes from 3 to 12 depending on the scheme.

=back

=head3 Returns

Array with the color scheme or an empty list if there is no such scheme

=cut

sub named_color_scheme {
    my %params = validate( @_,
                           {  name                   => { type => SCALAR },
                              number_of_data_classes => { type => SCALAR }
                           }
    );
    my ( $name, $number_of_data_classes ) = @params{qw(name number_of_data_classes)};

    my $colors = _color_brewer();
    if ( defined $colors->{$name} && defined $colors->{$name}{$number_of_data_classes} ) {
        return @{ $colors->{$name}{$number_of_data_classes} };
    }

    return ();
}

=head2 color_schemes

Get the color schemes available

=head3 Parameters

=over

=item * data_nature: 

Nature of the data: qualitative, sequential or diverging

=item * number_of_data_classes:

Number of data classes. Valid range goes from 3 to 12 depending on the scheme.

=back

=head3 Returns

Array with all the color schemes matching the options. Every color scheme is an array 
which elements are html rgb colors like: "rgb(252,141,89)"

Array can be empty if none of the color schemes match the options.

=cut

sub color_schemes {
    my %params = validate( @_,
                           {  data_nature            => { type => SCALAR },
                              number_of_data_classes => { type => SCALAR }
                           }
    );

    my ( $data_nature, $number_of_data_classes ) = @params{qw(data_nature number_of_data_classes)};
    $data_nature = substr( $data_nature, 0, 3 );

    return map { $_->{$number_of_data_classes} }
      grep { $_->{type} =~ /$data_nature/ && defined $_->{$number_of_data_classes} } values %{ _color_brewer() };
}

=head1 CREDIT

Color Brewer website and color schemes are copyrighted by Cynthia Brewer. With this module is bundled a json file with the color schemes. 

This product includes color specifications and designs developed by Cynthia Brewer (http://colorbrewer2.org/).

	Apache-Style Software License for ColorBrewer software and ColorBrewer Color Schemes

	Copyright (c) 2002 Cynthia Brewer, Mark Harrower, and The Pennsylvania State University.

	Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software distributed
	under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
	CONDITIONS OF ANY KIND, either express or implied. See the License for the
	specific language governing permissions and limitations under the License.

=head1 SEE ALSO

L<Color::Scheme> Perl implementation of Color Schemes 2 

L<Color::Palette> Set of named colors

L<Color::Library> Named-color library

L<Graphics::Color> Simple creation and manipulation of colors

L<Graphics::ColorObject> Conversion between color spaces

=head1 AUTHOR

Pablo Rodríguez González

=head1 LICENSE

This work is licensed under the Apache License, Version 2.0.

=cut

1;
