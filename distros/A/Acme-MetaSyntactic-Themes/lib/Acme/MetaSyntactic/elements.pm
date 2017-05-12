package Acme::MetaSyntactic::elements;
use strict;
use Acme::MetaSyntactic::Locale;
our @ISA = qw( Acme::MetaSyntactic::Locale );
our $VERSION = '1.002';
__PACKAGE__->init();
1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::elements - The chemical elements theme

=head1 DESCRIPTION

This theme provides the names of the chemical elements, 
as given in the standard periodic table, up to the 118th element. 

The default list is the list of chemical symbols. The language code
for this list is C<x-elements> (an extension to RFC 3066).

=head1 CONTRIBUTORS

Sébastien Aperghis-Tramoni, Abigail.

=head1 CHANGES

=over 4

=item *

2012-06-04 - v1.002

Updated with Copernicium, Flerovium, and Livermorium by Abigail
in Acme-MetaSyntactic-Themes version 1.004.

=item *

2012-05-14 - v1.001

Updated with an C<=encoding> pod command
in Acme-MetaSyntactic-Themes version 1.001.

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-04-11

Introduced in Acme-MetaSyntactic version 0.17.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::Locale>.

=cut

__DATA__
# default
x-elements
# names x-elements
H  He Li Be B C N O  F  Ne Na Mg Al Si P  S  Cl Ar K  Ca Sc Ti Vn Cr Mn
Fe Co Ni Cu Zn Ga Ge As Se Br Ky Rb Sr Y  Zr Nb Mo Tc Ru Rh Pd Ag Cd In
Sn Sb Te I  Xe Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Hf Ta
W  Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn Fr Ra Ac Th Pa U  Np Pu Am Cm Bk
Cf Es Fm Md Bo Lr Rf Db Sg Bh Hs Mt Ds Rg
Cn Uut Fl Uup Lv Uus Uuo
# names en
hydrogen helium lithium beryllium boron carbon nitrogen oxygen fluorine
neon sodium magnesium aluminum silicon phosphorus sulfur chlorine argon
potassium calcium scandium titanium vanadium chromium manganese iron
cobalt nickel copper zinc gallium germanium arsenic selenium bromine
krypton rubidium strontium yttrium zirconium niobium molybdenum technetium
ruthenium rhodium palladium silver cadmium indium tin antimony tellerium
iodine xenon cesium barium lanthanum cerium praseodynium neodymium
promethium samarium europium gadolinium terbium dysprosium holmium
erbium thulium ytterbium lutetium hafnium tantalum tungsten rhenium
osmium iridium platinum gold mercury thallium lead bismuth polonium
astatine radon francium radium actinium thorium protactinium uranium
neptunium plutonium americium curium berkelium californium einsteinium
fermium mendelevium nobelium lawrencium rutherfordium dubnium seaborgium
bohrium hassium meitnerium darmstadtium roentgenium copernicium ununtrium
flerovium ununpentium livermorium ununseptium ununoctium
# names fr
hydrogene helium lithium beryllium bore carbone azote oxygene fluor
neon sodium magnesium aluminium silicium phosphore soufre chlore argon
potassium calcium scandium titane vanadium chrome manganese fer cobalt
nickel cuivre zinc gallium germanium arsenic selenium brome krypton
rubidium strontium yttrium zircon niobium molybdene technetium ruthenium
rhodium palladium argent cadmium indium etain antimoine tellure iode
xenon cesium baryum lanthane cerium praseodyme neodyme prometheum samarium
europium gadolinium terbium dysprosium holmium erbium thulium ytterbium
lutecium hafnium tantale tungstene rhenium osmium iridium platine or
mercure thallium plomb bismuth polonium astate radon francium radium
actinium thorium protactinium uranium neptunium plutonium americium
curium berkelium californium einsteinium fermium mendelevium nobelium
lawrencium rutherfordium dubnium seaborgium bohrium hassium meitnerium
darmstadtium roentgenium copernicium ununtrium flerovium ununpentium
livermorium ununseptium ununoctium

