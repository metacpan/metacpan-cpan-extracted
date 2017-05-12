package Acme::MetaSyntactic::colours;
use strict;
use Acme::MetaSyntactic::Locale;
our @ISA = qw( Acme::MetaSyntactic::Locale );
our $VERSION = '1.003';
__PACKAGE__->init();
1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::colours - The colours theme

=head1 DESCRIPTION

This theme list several colour names.

Note: this theme is aliased by C<Acme::MetaSyntactic::colors>.

=head1 CONTRIBUTORS

José Castro, Abigail, Philippe Bruhat (BooK).

=head1 CHANGES

=over 4

=item *

2012-06-04 - v1.003

Abigail added the color codes for resistors in English, Catalan, Danish,
Dutch, Estonian, Spanish and French
in Acme-MetaSyntactic-Themes version 1.004.

=item *

2012-05-21 - v1.002

Abigail added the seven colours of the rainbow in English, Dutch, German,
French, Spanish, Esperanto, Latin, Italian, Polish, Tagalog, Swedish,
Portuguese, Danish, and Interlingua
in Acme-MetaSyntactic-Themes version 1.002.

=item *

2012-05-14 - v1.001

Updated with an C<=encoding> pod command
in Acme-MetaSyntactic-Themes version 1.001.

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-06-05

Made multilingual in Acme-MetaSyntactic version 0.77,
with the large list of colours submitted by Abigail,
several translations by José Castro,
and the X11 colors lying in F</usr/X11R6/lib/X11/rgb.txt>
by Philippe Bruhat (BooK).

=item *

2006-05-29

Introduced in Acme-MetaSyntactic version 0.76,
with the twelve colours proposed by José Castro.

=item *

2005-10-20

Theme I<colours> submitted by Abigail,
based on L<http://en.wikipedia.org/wiki/List_of_colors>.

=item *

2005-10-13

Theme I<colors> submitted by José Castro.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::Locale>.

=cut

__DATA__
# default
x-11
# names en
white black orange blue red yellow pink purple gray green magenta brown
amber amethyst asparagus aqua aquamarine azure beige bistre black blue
blaze_orange bondi_blue bright_green bright_turquoise bright_violet brown
buff burnt_orange burnt_sienna burnt_umber cadet_blue camouflage_green
cardinal caribbean_green carmine carrot celadon cerise cerulean
cerulean_blue chartreuse chestnut chocolate cobalt copper coral corn
cornflower_blue cream crimson cyan dark_brown dark_cerulean dark_chestnut
dark_coral dark_goldenrod dark_green dark_indigo dark_khaki dark_olive
dark_pastel_green dark_peach dark_pink dark_salmon dark_scarlet
dark_slate_gray dark_spring_green dark_tan dark_tangerine dark_tea_green
dark_turquoise dark_violet denim dodger_blue emerald eggplant fern_green
flax fuchsia gold goldenrod gray gray_asparagus gray_tea_green green
green_yellow heliotrope hot_pink indigo international_orange jade khaki
klein_blue lavender lavender_blush lemon lemon_cream light_brown lilac
lime linen magenta maroon mauve midnight_blue mint_green moss_green
mountbatten_pink mustard navajo_white navy_blue ochre old_gold
olive olive_drab orange orchid pale_blue pale_bright_green pale_brown
pale_carmine pale_chestnut pale_cornflower_blue pale_denim pale_magenta
pale_mauve pale_mint_green pale_ochre pale_olive pale_olive_drab
pale_orange pale_pink pale_pink_lavender pale_raw_umber pale_red_violet
pale_sandy_brown pale_sea_green pale_turquoise pale_wisteria pale_yellow
papaya_whip pastel_green pastel_pink peach peach_orange peach_yellow pear
periwinkle persian_blue pine_green pink pink_orange plum powder_blue
puce pumpkin purple raw_umber red red_violet robin_egg_blue royal_blue
safety_orange salmon sandy_brown scarlet school_bus_yellow sea_green
seashell sepia silver slate_gray spring_green steel_blue swamp_green
tan tangerine tea_green teal tenne thistle turquoise vermilion violet
violet_eggplant viridian wheat white wisteria yellow zinnwaldite
# names pt
preto azul castanho verde cinzento magenta laranja rosa roxo vermelho
branco amarelo
# names es
negro azul marron verde gris magenta anaranjado rosa purpura rojo blanco
amarillo
# names fr
noir bleu brun vert gris orange magenta rose pourpre rouge blanc jaune
# names x-11
snow ghost_white GhostWhite white_smoke WhiteSmoke gainsboro floral_white
FloralWhite old_lace OldLace linen antique_white AntiqueWhite papaya_whip
PapayaWhip blanched_almond BlanchedAlmond bisque peach_puff PeachPuff
navajo_white NavajoWhite moccasin cornsilk ivory lemon_chiffon
LemonChiffon seashell honeydew mint_cream MintCream azure alice_blue
AliceBlue lavender lavender_blush LavenderBlush misty_rose MistyRose white
black dark_slate_gray DarkSlateGray dark_slate_grey DarkSlateGrey dim_gray
DimGray dim_grey DimGrey slate_gray SlateGray slate_grey SlateGrey
light_slate_gray LightSlateGray light_slate_grey LightSlateGrey gray grey
light_grey LightGrey light_gray LightGray midnight_blue MidnightBlue
navy navy_blue NavyBlue cornflower_blue CornflowerBlue dark_slate_blue
DarkSlateBlue slate_blue SlateBlue medium_slate_blue MediumSlateBlue
light_slate_blue LightSlateBlue medium_blue MediumBlue royal_blue
RoyalBlue blue dodger_blue DodgerBlue deep_sky_blue DeepSkyBlue sky_blue
SkyBlue light_sky_blue LightSkyBlue steel_blue SteelBlue light_steel_blue
LightSteelBlue light_blue LightBlue powder_blue PowderBlue
pale_turquoise PaleTurquoise dark_turquoise DarkTurquoise medium_turquoise
MediumTurquoise turquoise cyan light_cyan LightCyan cadet_blue CadetBlue
medium_aquamarine MediumAquamarine aquamarine dark_green DarkGreen
dark_olive_green DarkOliveGreen dark_sea_green DarkSeaGreen sea_green
SeaGreen medium_sea_green MediumSeaGreen light_sea_green LightSeaGreen
pale_green PaleGreen spring_green SpringGreen lawn_green LawnGreen
green chartreuse medium_spring_green MediumSpringGreen green_yellow
GreenYellow lime_green LimeGreen yellow_green YellowGreen forest_green
ForestGreen olive_drab OliveDrab dark_khaki DarkKhaki khaki pale_goldenrod
PaleGoldenrod light_goldenrod_yellow LightGoldenrodYellow light_yellow
LightYellow yellow gold light_goldenrod LightGoldenrod goldenrod
dark_goldenrod DarkGoldenrod rosy_brown RosyBrown indian_red IndianRed
saddle_brown SaddleBrown sienna peru burlywood beige wheat sandy_brown
SandyBrown tan chocolate firebrick brown dark_salmon DarkSalmon salmon
light_salmon LightSalmon orange dark_orange DarkOrange coral light_coral
LightCoral tomato orange_red OrangeRed red hot_pink HotPink deep_pink
DeepPink pink light_pink LightPink pale_violet_red PaleVioletRed maroon
medium_violet_red MediumVioletRed violet_red VioletRed magenta violet
plum orchid medium_orchid MediumOrchid dark_orchid DarkOrchid dark_violet
DarkViolet blue_violet BlueViolet purple medium_purple MediumPurple
thistle snow1 snow2 snow3 snow4 seashell1 seashell2 seashell3 seashell4
AntiqueWhite1 AntiqueWhite2 AntiqueWhite3 AntiqueWhite4 bisque1 bisque2
bisque3 bisque4 PeachPuff1 PeachPuff2 PeachPuff3 PeachPuff4 NavajoWhite1
NavajoWhite2 NavajoWhite3 NavajoWhite4 LemonChiffon1 LemonChiffon2
LemonChiffon3 LemonChiffon4 cornsilk1 cornsilk2 cornsilk3 cornsilk4
ivory1 ivory2 ivory3 ivory4 honeydew1 honeydew2 honeydew3 honeydew4
LavenderBlush1 LavenderBlush2 LavenderBlush3 LavenderBlush4 MistyRose1
MistyRose2 MistyRose3 MistyRose4 azure1 azure2 azure3 azure4 SlateBlue1
SlateBlue2 SlateBlue3 SlateBlue4 RoyalBlue1 RoyalBlue2 RoyalBlue3
RoyalBlue4 blue1 blue2 blue3 blue4 DodgerBlue1 DodgerBlue2 DodgerBlue3
DodgerBlue4 SteelBlue1 SteelBlue2 SteelBlue3 SteelBlue4 DeepSkyBlue1
DeepSkyBlue2 DeepSkyBlue3 DeepSkyBlue4 SkyBlue1 SkyBlue2 SkyBlue3 SkyBlue4
LightSkyBlue1 LightSkyBlue2 LightSkyBlue3 LightSkyBlue4 SlateGray1
SlateGray2 SlateGray3 SlateGray4 LightSteelBlue1 LightSteelBlue2
LightSteelBlue3 LightSteelBlue4 LightBlue1 LightBlue2 LightBlue3
LightBlue4 LightCyan1 LightCyan2 LightCyan3 LightCyan4 PaleTurquoise1
PaleTurquoise2 PaleTurquoise3 PaleTurquoise4 CadetBlue1 CadetBlue2
CadetBlue3 CadetBlue4 turquoise1 turquoise2 turquoise3 turquoise4
cyan1 cyan2 cyan3 cyan4 DarkSlateGray1 DarkSlateGray2 DarkSlateGray3
DarkSlateGray4 aquamarine1 aquamarine2 aquamarine3 aquamarine4
DarkSeaGreen1 DarkSeaGreen2 DarkSeaGreen3 DarkSeaGreen4 SeaGreen1
SeaGreen2 SeaGreen3 SeaGreen4 PaleGreen1 PaleGreen2 PaleGreen3
PaleGreen4 SpringGreen1 SpringGreen2 SpringGreen3 SpringGreen4
green1 green2 green3 green4 chartreuse1 chartreuse2 chartreuse3
chartreuse4 OliveDrab1 OliveDrab2 OliveDrab3 OliveDrab4 DarkOliveGreen1
DarkOliveGreen2 DarkOliveGreen3 DarkOliveGreen4 khaki1 khaki2 khaki3
khaki4 LightGoldenrod1 LightGoldenrod2 LightGoldenrod3 LightGoldenrod4
LightYellow1 LightYellow2 LightYellow3 LightYellow4 yellow1 yellow2
yellow3 yellow4 gold1 gold2 gold3 gold4 goldenrod1 goldenrod2 goldenrod3
goldenrod4 DarkGoldenrod1 DarkGoldenrod2 DarkGoldenrod3 DarkGoldenrod4
RosyBrown1 RosyBrown2 RosyBrown3 RosyBrown4 IndianRed1 IndianRed2
IndianRed3 IndianRed4 sienna1 sienna2 sienna3 sienna4 burlywood1
burlywood2 burlywood3 burlywood4 wheat1 wheat2 wheat3 wheat4 tan1
tan2 tan3 tan4 chocolate1 chocolate2 chocolate3 chocolate4 firebrick1
firebrick2 firebrick3 firebrick4 brown1 brown2 brown3 brown4 salmon1
salmon2 salmon3 salmon4 LightSalmon1 LightSalmon2 LightSalmon3
LightSalmon4 orange1 orange2 orange3 orange4 DarkOrange1 DarkOrange2
DarkOrange3 DarkOrange4 coral1 coral2 coral3 coral4 tomato1 tomato2
tomato3 tomato4 OrangeRed1 OrangeRed2 OrangeRed3 OrangeRed4 red1 red2
red3 red4 DeepPink1 DeepPink2 DeepPink3 DeepPink4 HotPink1 HotPink2
HotPink3 HotPink4 pink1 pink2 pink3 pink4 LightPink1 LightPink2
LightPink3 LightPink4 PaleVioletRed1 PaleVioletRed2 PaleVioletRed3
PaleVioletRed4 maroon1 maroon2 maroon3 maroon4 VioletRed1 VioletRed2
VioletRed3 VioletRed4 magenta1 magenta2 magenta3 magenta4 orchid1 orchid2
orchid3 orchid4 plum1 plum2 plum3 plum4 MediumOrchid1 MediumOrchid2
MediumOrchid3 MediumOrchid4 DarkOrchid1 DarkOrchid2 DarkOrchid3
DarkOrchid4 purple1 purple2 purple3 purple4 MediumPurple1 MediumPurple2
MediumPurple3 MediumPurple4 thistle1 thistle2 thistle3 thistle4 gray0
grey0 gray1 grey1 gray2 grey2 gray3 grey3 gray4 grey4 gray5 grey5 gray6
grey6 gray7 grey7 gray8 grey8 gray9 grey9 gray10 grey10 gray11 grey11
gray12 grey12 gray13 grey13 gray14 grey14 gray15 grey15 gray16 grey16
gray17 grey17 gray18 grey18 gray19 grey19 gray20 grey20 gray21 grey21
gray22 grey22 gray23 grey23 gray24 grey24 gray25 grey25 gray26 grey26
gray27 grey27 gray28 grey28 gray29 grey29 gray30 grey30 gray31 grey31
gray32 grey32 gray33 grey33 gray34 grey34 gray35 grey35 gray36 grey36
gray37 grey37 gray38 grey38 gray39 grey39 gray40 grey40 gray41 grey41
gray42 grey42 gray43 grey43 gray44 grey44 gray45 grey45 gray46 grey46
gray47 grey47 gray48 grey48 gray49 grey49 gray50 grey50 gray51 grey51
gray52 grey52 gray53 grey53 gray54 grey54 gray55 grey55 gray56 grey56
gray57 grey57 gray58 grey58 gray59 grey59 gray60 grey60 gray61 grey61
gray62 grey62 gray63 grey63 gray64 grey64 gray65 grey65 gray66 grey66
gray67 grey67 gray68 grey68 gray69 grey69 gray70 grey70 gray71 grey71
gray72 grey72 gray73 grey73 gray74 grey74 gray75 grey75 gray76 grey76
gray77 grey77 gray78 grey78 gray79 grey79 gray80 grey80 gray81 grey81
gray82 grey82 gray83 grey83 gray84 grey84 gray85 grey85 gray86 grey86
gray87 grey87 gray88 grey88 gray89 grey89 gray90 grey90 gray91 grey91
gray92 grey92 gray93 grey93 gray94 grey94 gray95 grey95 gray96 grey96
gray97 grey97 gray98 grey98 gray99 grey99 gray100 grey100 dark_grey
DarkGrey dark_gray DarkGray dark_blue DarkBlue dark_cyan DarkCyan
dark_magenta DarkMagenta dark_red DarkRed light_green LightGreen
# names rainbow en
red orange yellow green blue indigo violet
# names rainbow nl
rood oranje geel groen blauw indigo violet
# names rainbow de
rot orange gelb grun blau indigo violett
# names rainbow fr
rouge orange jaune vert bleu indigo violet
# names rainbow es
rojo naranja amarillo verde azul anil violeta
# names rainbow eo
ruga oranga flava verda blua indiga viola
# names rainbow la
ruber aurantius flavus viridus caeruleus indicum violaceus
# names rainbow it
rosso arancione giallo verde azzurro indaco violetto
# names rainbow pl
czerwona pomaranczowa zolta zielona niebieska indygo fioletowa
# names rainbow ia
rubie orange jalne verde blau anil violetto
# names rainbow sv
rod orange gul gron bla indigo violett
# names rainbow pt
vermelho laranja amarelo verde azul anil violeta
# names rainbow dk
rod orange gul gron bla indigo violet
# names rainbow tl
pula kahel dilaw lunti bughaw indigo lila
# names resistor en
black brown red orange yellow green blue violet gray white gold silver
# names resistor ca
negre marro vermell taronja groc vert blau violeta gris blanc daurat argent
# names resistor dk
sort brun rod orange gul gron bla violet gra hvid guld solv
# names resistor nl
zwart bruin rood oranje geel groen blauw violet grijs wit goud zilver
# names resistor et
must pruun punane oranz kollane reheline sinine violetne hall valge
kuldne hobedane
# names resistor es
negro marron rojo naranja amarillo verde azul violeta gris blanco dorado plata
# names resistor fr
noir marron rouge orange jaune vert blue violet gris blanc or argent
