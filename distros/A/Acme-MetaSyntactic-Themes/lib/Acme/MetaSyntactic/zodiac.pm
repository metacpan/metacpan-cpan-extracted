package Acme::MetaSyntactic::zodiac;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::zodiac - The zodiac theme

=head1 DESCRIPTION

Zodiacal signs from various parts of the world.

In Western and Vedic astonomy (and astrology), zodiacal signs are
constellations in front of which the sun passes, as seen from earth.
Traditional Western zodiac signs are based on the Babylonian observations,
and contain 12 signs. However, these observations are three millenia
out of date, and in reality, the sun passes in front of thirteen
constellation.

This theme has four categories:

=over 4

=item Western/Tradional

Contains the twelve signs most people are familiar with.
This is the default category.

=item Western/Real

The thirteen constellations the sun actually passes in front of.

=item Vedic

The names of the constellations as they are known in India.

=item Chinese

The signs of the Chines zodiac. They have no relation with constellations.

=back

Default category is I<Western/Traditional>.

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Included with its own version number
in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-05-13

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=cut

__DATA__
# default 
Western/Traditional
# names Western Traditional
Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio
Sagittarius Capricornus Aquarius Pisces
# names Western Real
Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Ophiuchus
Sagittarius Capricornus Aquarius Pisces
# names Vedic
Mesha Vrishabha Mithuna Karka Simha Kanya Tula Vrishchika Dhanus
Makara Kumbha Meena
# names Chinese
Rat Ox Tiger Rabbit Dragon Snake Horse Goat Monkey Rooster Dog Boar
