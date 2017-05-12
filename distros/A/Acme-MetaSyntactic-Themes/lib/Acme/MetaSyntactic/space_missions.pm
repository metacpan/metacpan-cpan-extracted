package Acme::MetaSyntactic::space_missions;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.000';
__PACKAGE__->init();

# And the magic true value to end the module
# is the year of the first manned space mission
1961;

=head1 NAME

Acme::MetaSyntactic::space_missions - The space missions theme

=head1 DESCRIPTION

This theme lists the names of various space missions flights.

=over 4

=item *

C<apollo>

As from Apollo 9, the command and lunar modules of Project Apollo were
given radio call signs. This list document them.

Source: I<A Man on the Moon>, by Andrew Chaikin.

=item *

C<mercury>

This list gives the names of the six Mercury spacecraft,
plus the name of the flight cancelled when Deke Slayton
was grounded for health reasons.

Source: I<The Right Stuff>, by Tom Wolfe.

=item *

C<manned_spacecraft>

This list gives the names of the manned spacecraft,
all nations and all agencies or firms combined.

=item *

C<launch_vehicles>

This list gives the names of launch vehicles type. For vehicles with
several numbered subtypes, only the main type has been given, without
the subtype number (which gives one-letter names for Japanese launch
vehicles).

Source: The list of launch vehicles is taken from the colour
photos from I<Rocket Science>, Alfred J. Zaehringer, Apogee
(ISBN 1-894959-09-4).
To this book, I have added
L<http://en.wikipedia.org/wiki/List_of_launch_vehicles> and
L<http://en.wikipedia.org/wiki/Scaled_Composites_White_Knight>.

=item *

C<victims>

This list gives the names of the humans who were killed in a
spacecraft accident.

Source: L<http://en.wikipedia.org/wiki/Category:Space_program_fatalities>
L<http://en.wikipedia.org/wiki/Space_disaster>.

=back

=head1 CONTRIBUTOR

Jean Forget

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-08-21

Updated with themes C<manned_spacecraft>, C<launch_vehicles> and C<victims>
in Acme-MetaSyntactic version 0.88.

=item *

2006-08-07

Augmented with other space missions and renamed C<space_missions> in
version 0.86, published on August 7, 2006.

=item *

2006-06-14 - 2006-06-26

Jean Forget proposed a new C<mercury> theme.
I suggested grouping both lists under a single theme
(C<space_missions>? C<nasa>?).

Jean selected the name C<space_missions> for the theme,
as he already had plans for other lists that were not related to the NASA.

=item *

2005-09-26

Introduced in Acme-MetaSyntactic version 0.41 as theme C<apollo>.

=item *

2005-09-12

Jean Forget proposed the list of Apollo command and lunar modules
radio call signs.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=cut

__DATA__
# default
:all
# names apollo
Gumdrop Spider
Charlie_Brown Snoopy
Columbia Eagle
Yankee_Clipper Intrepid
Odyssey Aquarius
Kitty_Hawk Antares
Endeavour Falcon
Casper Orion
America Challenger
# names mercury
Freedom7
Liberty_Bell7
Friendship7
Delta7
Aurora7
Sigma7
Faith7
# names manned_spacecraft
Vostok Mercury X_15 Voskhod Gemini Soyuz
Apollo Salyut Skylab Space_Shuttle
Mir ISS Shenzhou SpaceShipOne
# names launch_vehicles
Vanguard Jupiter Thor Juno Redstone Atlas Centaur Agena Titan Delta Saturn Scout Pegasus Minotaur
R_7 Cosmos N_1 Semyorka Proton Dnepr Energia Start
Diamant Veronique
Ariane
Long_March
Shavit
N H J
White_Knight
# names victims
Gus_Grissom Ed_White Roger_Chaffee
Vladimir_Komarov
Mike_Adams
Georgi_Dobrovolski Viktor_Patsayev Vladislav_Volkov
Greg_Jarvis Christa_McAuliffe Ronald_McNair Ellison_Onizuka Judith_Resnik Michael_J_Smith Dick_Scobee
Rick_D_Husband William_McCool Michael_P_Anderson David_M_Brown
Kalpana_Chawla Laurel_B_Clark Ilan_Ramon

