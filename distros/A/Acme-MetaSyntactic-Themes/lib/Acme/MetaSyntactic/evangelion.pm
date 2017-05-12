package Acme::MetaSyntactic::evangelion;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.001';
__PACKAGE__->init();
1;

=encoding utf-8

=head1 NAME

Acme::MetaSyntactic::evangelion - The Neon Genesis Evangelion theme

=head1 DESCRIPTION

This theme provides the English names of the characters from the
Japanese animated series I<Neon Genesis Evangelion>, and also other
terms used in the series. It also contains names from the I<Rebuild
of Evangelion> tetralogy and from 新世紀エヴァンゲリオン 碇シンジ育成計画
(I<Shin Seiki Evangelion: Ikari Shinji Ikusei Keikaku>).

L<http://en.wikipedia.org/wiki/Neon_Genesis_Evangelion> is a good
start to read about about I<Evangelion>.

=head2 Categories

This theme contains the following categories:

=over

=item * pilots/original

names of the Evangelion pilots

=item * pilots/Rebuild

names of the additional pilots in I<Rebuild of Evangelion>

=item * staff/nerv/original

names of the people working for the Nerv organisation

=item * staff/nerv/dead

names of the people who worked for the Nerv organisation,
but are dead before the beginning of the show

=item * staff/nerv/IkuseiKeikaku

names of the additional people working for the Nerv organisation
in I<Shin Seiki Evangelion: Ikari Shinji Ikusei Keikaku>

=item * staff/seele

names of the people working for the Seele organisation

=item * magi

names of the MAGI super-computer

=item * evas

Japanese names of the Evangelions

=item * angels

names of the Angels (Shito)

=item * students/original

names of other students

=item * students/IkuseiKeikaku

names of other students
in I<Shin Seiki Evangelion: Ikari Shinji Ikusei Keikaku>

=item * animals

names of the animals

=item * glossary/common

miscellaneous names

=item * glossary/Rebuild

additionnal names from I<Rebuild of Evangelion>

=back


=head1 CONTRIBUTOR

Sébastien Aperghis-Tramoni.

=head1 CHANGES

=over 4

=item *

2013-10-14 - v1.001

Fixed a typo in Sébastien's last name and now load the proper parent module,
in Acme-MetaSyntactic-Themes version 1.037.

=item *

2012-09-03 - v1.000

Published in Acme-MetaSyntactic-Themes version 1.017.

Reviewed to fix a few mistakes, and improve the tags.
Added names from the I<Rebuild of Evangelion> tetralogy and from
新世紀エヴァンゲリオン 碇シンジ育成計画 (I<Shin Seiki Evangelion:
Ikari Shinji Ikusei Keikaku>).
Documented the categories.

=item *

2006-01-05

Submitted by Sébastien Aperghis-Tramoni (Maddingue).

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names pilots original
First_Children Ayanami_Rei
Second_Children Soryu_Asuka_Langley
Third_Children Ikari_Shinji
Fourth_Children Suzuhara_Toji
Fifth_Children Nagisa_Kaworu
# names pilots Rebuild
Shikinami_Asuka_Langley
Makinami_Illustrious_Mari

# names staff nerv original
Ikari_Gendoo
Fuyutsuki_Kozo
Akagi_Ritsuko
Katsuragi_Misato
Ryouji_Kaji
Ibuki_Maya
Hyuga_Makoto
Shigeru_Aoba
# names staff nerv dead
Ikari_Yui
Soryu_Zeppelin_Kyoko
Akagi_Naoko
# names staff nerv IkuseiKeikaku
Agano_Kaede
Ooi_Satsuki
Mogami_Aoi

# names staff seele
Keel_Lorenz

# names magi
MAGI Melchior Balthasar Casper

# names evas
Zerogoki Shogoki Nigoki Sangoki Yongoki Ryousanki

# names angels
Adam Lilith Sachiel Shamshel Ramiel Gaghiel Israfel Sandalphon Matarael
Sahaqiel Ireul Leliel Bardiel Zeruel Arael Armisael Tabris Lilin

# names students original
Aida_Kensuke
Horaki_Hikari
# names students IkuseiKeikaku
Kirishima_Mana

# names animals
Pen_Pen

# names glossary common
Seele Gehirn Nerv Marduk_Institute
Sephiroth Dead_Sea_Scrolls Human_Instrumentality_Project
Henflick_limit
Eva Evangelion Shito Angel
B_type D_Type F_type
entry_plug dummy_system dummy_plug LCL
progressive_knife lance_of_Longinus 
AT_Field S2_Engine beast_mode berserk_mode
N2_bomb Jet_Alone
Tokyo_3 GeoFront Central_Dogma Terminal_Dogma
First_Impact Second_Impact Third_Impact
# names glossary Rebuild
Bethany_Base Limbo_area Cocytus Malebolge_system Styx_shaft Acheron
Tabgha_Base
