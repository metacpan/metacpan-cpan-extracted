package Class::Measure::Length;
{
  $Class::Measure::Length::VERSION = '0.05';
}

=head1 NAME

Class::Measure::Length - Calculate measurements of length.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base qw( Class::Measure );

use Sub::Exporter -setup => {
    exports => [qw( length )]
};

=head1 METHODS

This module inherits all the methods made available by 
L<Class::Measure>.

=head2 length

  $m = length( 2, 'metres' );

Creates a new measurement object.

=cut

sub length { return __PACKAGE__->new(@_); }

=head1 UNITS

=head2 International System of Units

Also known as SI and "metric", this unit of measure 
includes the following.

  kilometre
  metre
  centimetre
  millimetre
  decimetre
  micrometre
  nanometre

And all veriations are aliased, such as "m", "meter", 
"meters", "metres".

=cut

__PACKAGE__->reg_units(
    qw( kilometre centimetre millimetre decimetre micrometre nanometre metre )
);
__PACKAGE__->reg_aliases(
    ['kilometer','km','kilometers','kilometres','klick','klicks'] => 'kilometre',
    ['meter','m','meters','metres'] => 'metre',
    ['centimeter','cm','centimeters','centimetres'] => 'centimetre',
    ['millimeter','mm','millimeters','millimetres'] => 'millimetre',
    ['decimeter','decimeters','decimetres'] => 'decimetre',
    ['micrometer','micrometers','micron','microns','micrometres'] => 'micrometre',
    ['nanometer','nanometers','nanometres'] => 'nanometre',
);
__PACKAGE__->reg_convs(
    'km' => 1000, 'm',
    100, 'cm' => 'm',
    10, 'mm' => 'cm',
    'decimetre' => 10, 'cm',
    1000, 'microns' => 'mm',
    1000, 'nanometers' => 'micron',
);

=head2 Shared

These units are shared by with the US and Imperial 
unit systems.

  inch
  foot
  yard
  rod
  mile
  chain
  furlong

All relevant aliases included.

=cut

__PACKAGE__->reg_units(
    qw( inch foot yard rod mile chain furlong )
);
__PACKAGE__->reg_aliases(
    ['in','inches'] => 'inch',
    ['feet','ft'] => 'foot',
    'yards' => 'yard',
    ['pole','poles','perch','perches','rods'] => 'rod',
    'miles' => 'mile',
    'chains' => 'chain',
    'furlongs' => 'furlong',
);
__PACKAGE__->reg_convs(
    'inch' => 25.4, 'mm',
    'foot' => 12, 'inches',
    'yard' => 3, 'feet',
    'yard' => 91.44, 'cm',
    'rod' => 16.5, 'feet',
    'mile' => 1.609344, 'km',
    'mile' => 5280, 'feet',
    'chain' => 66, 'feet',
    'furlong' => 10, 'chains',
);

=head2 United Stats

Units specific to the United States.

  survey_mile
  link
  fathom
  cable_length

Aliases included.

=cut

__PACKAGE__->reg_units(
    qw( survey_mile link fathom cable_length )
);
__PACKAGE__->reg_aliases(
    'survey_miles' => 'survey_mile',
    'links' => 'link',
    'fathoms' => 'fathom',
    'cable_lengths' => 'cable_length',
);
__PACKAGE__->reg_convs(
    'survey_mile' => 8, 'furlongs',
    'link' => 0.001, 'furlongs',
    'fathom' => 6, 'feet',
    'cable_length' => 123, 'fathoms',
);

=head2 Imperial

Imperial (english) units.  The only unit included 
in this set is "league".

=cut

__PACKAGE__->reg_units(
    qw( league )
);
__PACKAGE__->reg_aliases(
    'leagues' => 'league',
);
__PACKAGE__->reg_convs(
    'league' => 3, 'miles',
);

=head2 Other

  light_second
  nautical_mile

=cut

__PACKAGE__->reg_units(
    qw( light_second nautical_mile )
);
__PACKAGE__->reg_aliases(
    'light_seconds'  => 'light_second',
    'nautical_miles' => 'nautical_mile',
);
__PACKAGE__->reg_convs(
    'light_second'  => 299792458, 'm',
    'nautical_mile' => 1852, 'm',
);

1;

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

