package Acme::MetaSyntactic::nethack;

use 5.006001;
use utf8;
use strict;
use warnings;

use version; our $VERSION = qv('v1.0.1');

use base 'Acme::MetaSyntactic::MultiList';
__PACKAGE__->init();

1; # Magic true value required at end of module

=encoding utf8

=for stopwords mmm mmmm NetHack something's ummm

=head1 NAME

Acme::MetaSyntactic::nethack - The largest time waster in the world of *nix.


=head1 VERSION

This document describes Acme::MetaSyntactic::nethack version 1.0.1.


=head1 DESCRIPTION

This theme lists NetHack artifacts, objects (both unknown and known
descriptions), roles, names, sayings, etc.

=head2 List of categories

This module was created by copying strings from the NetHack 3.4.3
source.  Categories are thus, for the most part, those of the NetHack
developers.

This theme currently includes the following high-level categories:

=over

=item *

C<artifacts>: special, unique items.  No subcategories.

=item *

C<monsters>: the various entities with which you interact.
(B<slash!>, B<smash!>, B<kill!>)

Monsters are subdivided into
C<ants>,
C<blobs>,
C<cockatrice>,
C<canines>,
C<eyes>,
C<felines>,
C<gremlins_and_gargoyles>,
C<humanoids>,
C<imps_and_demons>,
C<jellies>,
C<kobolds>,
C<leprechauns>,
C<nymphs>,
C<orcs>,
C<piercers>,
C<quadrupeds>,
C<rodents>,
C<spiders_and_scorpions>,
C<trapper_and_lurker>,
C<unicorns_and_horses>,
C<vortices>,
C<worms>,
C<xans>,
C<lights>,
C<zruty>,
C<angels>,
C<bats>,
C<centaurs>,
C<dragons>,
C<elementals>,
C<fungi>,
C<gnomes>,
C<giant_humanoids>,
C<kops>,
C<liches>,
C<mummies>,
C<nagas>,
C<ogres>,
C<puddings>,
C<quantum_mechanic>,
C<rust_monster_and_disenchanter>,
C<snakes>,
C<trolls>,
C<umber_hulk>,
C<vampires>,
C<wraiths>,
C<xorn>,
C<apelike_beasts>,
C<zombies>,
C<humans_and_elves>,
C<ghosts>,
C<major_demons>,
C<sea_monsters>,
C<lizards>,
C<character_classes>,
C<quests> (which are further subdivided into C<leaders>, C<nemeses>, and C<guardians>),
and C<bogus> (which includes things like smurfs and mothers-in-law.).

=item *

C<objects>: the things you will need in your journey.

This contains two immediate subcategories: C<unknown> and C<known>.
These differentiate the descriptions you will get when you have no
special information about an item and when you can properly recognize
an item.  For example, requesting a name from C<objects/unknown/rings>
will return something like "coral_ring", while C<objects/known/rings>
will return something like "ring_of_increase_damage".

Both of these have the following sub-sub-categories:

=over

=item *

C<amulets>: the fetishes that may or may not influence you.  Includes
the objective of the game.

=item *

C<armor>: the (hopefully) protective bits of raiment.  Subdivided into
C<boots>,
C<cloaks>,
C<gloves>,
C<helmets>,
C<shields>,
C<shirts> (worn by tourists),
and C<suits>, which is further subdivided into C<dragon> and C<regular>.

=item *

C<food>: comestibles broken down by C<fruits_and_veggies> (B<Yuk!>),
C<meat>, and C<people_food> (mmmm... candy bars).

=item *

C<gems>: shiny bits.

=item *

C<potions>: mmm... tastes like a caramel latte.

=item *

C<rings>: pretty things for your fingers.

=item *

C<rocks>: ummm, these are, like, really rocks.

=item *

C<scrolls>: bits of paper with weird, indecipherable scrawls on them.

=item *

C<spellbooks>: just a bunch of words.

=item *

C<tools>: manipulators, subdivided into
C<artifacts>,
C<containers>,
C<instruments>,
C<light_sources>,
C<lock_opening>,
C<traps>,
C<weapons> (things like pickaxes which can be used for digging I<or> bashing something's skull),
and C<other>.

=item *

C<wands>: sticks that you wave in the air.

=item *

C<weapons>: instruments used solely for self-defense (or not).
Subdivided into
C<blades>,
C<bludgeons>,
C<bows>,
C<missiles>,
C<polearms> (broken down into C<axe_type>, C<curved>, C<spear_type>, and C<other>),
C<spears>,
and C<swords>,

=item *

C<miscellaneous>: the other stuff.

=back

=item *

C<roles>: information about the occupations you may have.  Subdivided
into:

=over

=item *

C<classes>: the occupations themselves.

=item *

C<levels>: the names for the experience levels for each occupation.
Subdivided by occupation:
C<archeologist>,
C<barbarian>,
C<caveman>,
C<healer>,
C<knight>,
C<monk>,
C<priest>,
C<rogue>,
C<ranger>,
C<samurai>,
C<tourist>,
C<valkyrie>,
and C<wizard>.

=item *

C<gods>: the Higher Entities that each occupation grovels before,
bribes, scorns, pleads to, and curses.  Subdivided by occupation:
C<archeologist>,
C<barbarian>,
C<caveman>,
C<healer>,
C<knight>,
C<monk>,
C<priest>,
C<rogue>,
C<ranger>,
C<samurai>,
C<tourist>,
C<valkyrie>,
and C<wizard>.

=back

=item *

C<races>: the five humanoid types you can be.  No subcategories.

=item *

C<genders>: the three sex types you can be.  No subcategories.

=item *

C<alignment>: the view types you can have on the universe.  No
subcategories.

=item *

C<shops>: the kinds of items that an establishment may purvey.  No
subcategories.

=item *

C<tshirts>: the epigrams that may show on a tourist's chest.  No
subcategories.

=item *

C<sounds>: various noises you may hear.  No subcategories.

=item *

C<names>: the proper names that an entity may take.  Subdivided into:

=over

=item *

C<ghosts>: the proper names for the incorporeal presences you may
encounter.

=item *

C<coyotes>: the proper names for certain dog-like creatures.  These
are all mock-Latin.

=item *

C<shopkeepers>: the proper names for the vendors you will be
stea^H^H^H^Hpurchasing items from, subdivided by the type of items
they sell:
C<liquor>,
C<book>,
C<armor>,
C<wand>,
C<ring>,
C<food>,
C<weapon>,
C<tool>,
C<light>,
C<light_in_mine> (light stores in mine levels),
and C<general>.

=back

=item *

C<statements>: various utterances and responses you may hear along
your way.  No subcategories.

=back

=head1 DIAGNOSTICS


None.


=head1 CONFIGURATION AND ENVIRONMENT

Acme::MetaSyntactic::nethack requires no configuration files or
environment variables.


=head1 DEPENDENCIES

L<Acme::MetaSyntactic>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-metasyntactic-nethack@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 SEE ALSO

L<http://www.nethack.org/>.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2007-2008, Elliot Shank C<< <perl@galumph.com> >>. All
rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
__DATA__
# default
monsters
# names artifacts
Excalibur
Stormbringer
Mjollnir
Cleaver
Grimtooth
Orcrist
Sting
Magicbane
Frost_Brand
Fire_Brand
Dragonbane
Demonbane
Werebane
Grayswandir
Giantslayer
Ogresmasher
Trollsbane
Vorpal_Blade
Snickersnee
Sunsword
The_Orb_of_Detection
The_Heart_of_Ahriman
The_Sceptre_of_Might
The_Palantir_of_Westernesse
The_Staff_of_Aesculapius
The_Magic_Mirror_of_Merlin
The_Eyes_of_the_Overworld
The_Mitre_of_Holiness
The_Longbow_of_Diana
The_Master_Key_of_Thievery
The_Tsurugi_of_Muramasa
The_Platinum_Yendorian_Express_Card
The_Orb_of_Fate
The_Eye_of_the_Aethiopica
# names monsters/ants
giant_ant
killer_bee
soldier_ant
fire_ant
giant_beetle
queen_bee
# names monsters/blobs
acid_blob
quivering_blob
gelatinous_cube
# names monsters/cockatrice
chickatrice
cockatrice
pyrolisk
# names monsters/canines
jackal
fox
coyote
werejackal
little_dog
dog
large_dog
dingo
wolf
werewolf
warg
winter_wolf_cub
winter_wolf
hell_hound_pup
hell_hound
Cerberus
# names monsters/eyes
gas_spore
floating_eye
freezing_sphere
flaming_sphere
shocking_sphere
beholder
# names monsters/felines
kitten
housecat
jaguar
lynx
panther
large_cat
tiger
# names monsters/gremlins_and_gargoyles
gremlin
gargoyle
winged_gargoyle
# names monsters/humanoids
hobbit
dwarf
bugbear
dwarf_lord
dwarf_king
mind_flayer
master_mind_flayer
# names monsters/imps_and_demons
manes
homunculus
imp
lemure
quasit
tengu
# names monsters/jellies
blue_jelly
spotted_jelly
ochre_jelly
# names monsters/kobolds
kobold
large_kobold
kobold_lord
kobold_shaman
# names monsters/leprechauns
leprechaun
small_mimic
large_mimic
giant_mimic
# names monsters/nymphs
wood_nymph
water_nymph
mountain_nymph
# names monsters/orcs
goblin
hobgoblin
orc
hill_orc
Mordor_orc
Uruk_hai
orc_shaman
orc_captain
# names monsters/piercers
rock_piercer
iron_piercer
glass_piercer
# names monsters/quadrupeds
rothe
mumak
leocrotta
wumpus
titanothere
baluchitherium
mastodon
# names monsters/rodents
sewer_rat
giant_rat
rabid_rat
wererat
rock_mole
woodchuck
# names monsters/spiders_and_scorpions
cave_spider
centipede
giant_spider
scorpion
# names monsters/trapper_and_lurker
lurker_above
trapper
# names monsters/unicorns_and_horses
white_unicorn
gray_unicorn
black_unicorn
pony
horse
warhorse
# names monsters/vortices
fog_cloud
dust_vortex
ice_vortex
energy_vortex
steam_vortex
fire_vortex
# names monsters/worms
baby_long_worm
baby_purple_worm
long_worm
purple_worm
# names monsters/xans
grid_bug
xan
# names monsters/lights
yellow_light
black_light
# names monsters/zruty
zruty
# names monsters/angels
couatl
Aleax
Angel
ki_rin
Archon
# names monsters/bats
bat
giant_bat
raven
vampire_bat
# names monsters/centaurs
plains_centaur
forest_centaur
mountain_centaur
# names monsters/dragons
baby_gray_dragon
baby_silver_dragon
baby_shimmering_dragon
baby_red_dragon
baby_white_dragon
baby_orange_dragon
baby_black_dragon
baby_blue_dragon
baby_green_dragon
baby_yellow_dragon
gray_dragon
silver_dragon
shimmering_dragon
red_dragon
white_dragon
orange_dragon
black_dragon
blue_dragon
green_dragon
yellow_dragon
# names monsters/elementals
stalker
air_elemental
fire_elemental
earth_elemental
water_elemental
# names monsters/fungi
lichen
brown_mold
yellow_mold
green_mold
red_mold
shrieker
violet_fungus
# names monsters/gnomes
gnome
gnome_lord
gnomish_wizard
gnome_king
# names monsters/giant_humanoids
giant
stone_giant
hill_giant
fire_giant
frost_giant
storm_giant
ettin
titan
minotaur
jabberwock
vorpal_jabberwock
# names monsters/kops
Keystone_Kop
Kop_Sergeant
Kop_Lieutenant
Kop_Kaptain
# names monsters/liches
lich
demilich
master_lich
arch_lich
# names monsters/mummies
kobold_mummy
gnome_mummy
orc_mummy
dwarf_mummy
elf_mummy
human_mummy
ettin_mummy
giant_mummy
# names monsters/nagas
red_naga_hatchling
black_naga_hatchling
golden_naga_hatchling
guardian_naga_hatchling
red_naga
black_naga
golden_naga
guardian_naga
# names monsters/ogres
ogre
ogre_lord
ogre_king
# names monsters/puddings
gray_ooze
brown_pudding
black_pudding
green_slime
# names monsters/quantum_mechanic
quantum_mechanic
# names monsters/rust_monster_and_disenchanter
rust_monster
disenchanter
# names monsters/snakes
garter_snake
snake
water_moccasin
pit_viper
python
cobra
# names monsters/trolls
troll
ice_troll
rock_troll
water_troll
Olog_hai
# names monsters/umber_hulk
umber_hulk
# names monsters/vampires
vampire
vampire_lord
vampire_mage
Vlad_the_Impaler
# names monsters/wraiths
barrow_wight
wraith
Nazgul
# names monsters/xorn
xorn
# names monsters/apelike_beasts
monkey
ape
owlbear
yeti
carnivorous_ape
sasquatch
# names monsters/zombies
kobold_zombie
gnome_zombie
orc_zombie
dwarf_zombie
elf_zombie
human_zombie
ettin_zombie
giant_zombie
ghoul
skeleton
straw_golem
paper_golem
rope_golem
gold_golem
leather_golem
wood_golem
flesh_golem
clay_golem
stone_golem
glass_golem
iron_golem
# names monsters/humans_and_elves
human
wererat
werejackal
werewolf
elf
Woodland_elf
Green_elf
Grey_elf
elf_lord
Elvenking
doppelganger
nurse
shopkeeper
guard
prisoner
Oracle
aligned_priest
high_priest
soldier
sergeant
lieutenant
captain
watchman
watch_captain
Medusa
Wizard_of_Yendor
Croesus
Charon
# names monsters/ghosts
ghost
shade
# names monsters/major_demons
water_demon
horned_devil
succubus
incubus
erinys
barbed_devil
marilith
vrock
hezrou
bone_devil
ice_devil
nalfeshnee
pit_fiend
balrog
Juiblex
Yeenoghu
Orcus
Geryon
Dispater
Baalzebub
Asmodeus
Demogorgon
Death
Pestilence
Famine
mail_daemon
djinni
sandestin
# names monsters/sea_monsters
jellyfish
piranha
shark
giant_eel
electric_eel
kraken
# names monsters/lizards
newt
gecko
iguana
baby_crocodile
lizard
chameleon
crocodile
salamander
# names monsters/character_classes
archeologist
barbarian
caveman
cavewoman
healer
knight
monk
priest
priestess
ranger
rogue
samurai
tourist
valkyrie
wizard
# names monsters/quests/leaders
Lord_Carnarvon
Pelias
Shaman_Karnov
Earendil
Elwing
Hippocrates
King_Arthur
Grand_Master
Arch_Priest
Orion
Master_of_Thieves
Lord_Sato
Twoflower
Norn
Neferet_the_Green
# names monsters/quests/nemeses
Minion_of_Huhetotl
Thoth_Amon
Chromatic_Dragon
Goblin_King
Cyclops
Ixoth
Master_Kaen
Nalzok
Scorpius
Master_Assassin
Ashikaga_Takauji
Lord_Surtur
Dark_One
# names monsters/quests/guardians
student
chieftain
neanderthal
High_elf
attendant
page
abbot
acolyte
hunter
thug
ninja
roshi
guide
warrior
apprentice
# names monsters/bogus
jumbo_shrimp
giant_pigmy
gnu
killer_penguin
giant_cockroach
giant_slug
maggot
pterodactyl
tyrannosaurus_rex
basilisk
beholder
nightmare
efreeti
marid
rot_grub
bookworm
master_lichen
shadow
hologram
jester
attorney
sleazoid
killer_tomato
amazon
robot
battlemech
rhinovirus
harpy
lion_dog
rat_ant
Y2K_bug
grue
Christmas_tree_monster
luck_sucker
paskald
brogmoid
dornbeast
Ancient_Multi_Hued_Dragon
Evil_Iggy
emu
kestrel
xeroc
venus_flytrap
creeping_coins
hydra
siren
killer_bunny
rodent_of_unusual_size
Smokey_the_bear
Luggage
Ent
tangle_tree
nickelpede
wiggle
white_rabbit
snark
pushmi_pullyu
smurf
tribble
Klingon
Borg
Ewok
Totoro
ohmu
youma
nyaasu
Godzilla
King_Kong
earthquake_beast
Invid
Terminator
boomer
Dalek
microscopic_space_fleet
Ravenous_Bugblatter_Beast_of_Traal
teenage_mutant_ninja_turtle
samurai_rabbit
aardvark
Audrey_II
witch_doctor
one_eyed_one_horned_flying_purple_people_eater
Morgoth
Vorlon
questing_beast
Predator
mother_in_law
# names objects/unknown/weapons/missiles
arrow
runed_arrow
crude_arrow
silver_arrow
bamboo_arrow
crossbow_bolt
dart
throwing_star
boomerang
# names objects/unknown/weapons/spears
spear
runed_spear
crude_spear
stout_spear
silver_spear
throwing_spear
trident
# names objects/unknown/weapons/blades
dagger
runed_dagger
crude_dagger
silver_dagger
athame
scalpel
knife
stiletto
worm_tooth
crysknife
axe
double_headed_axe
# names objects/unknown/weapons/swords
short_sword
runed_short_sword
crude_short_sword
broad_short_sword
curved_sword
silver_saber
broadsword
runed_broadsword
long_sword
two_handed_sword
samurai_sword
long_samurai_sword
runed_broadsword
# names objects/unknown/weapons/polearms/spear_type
vulgar_polearm
hilted_polearm
forked_polearm
single_edged_polearm
lance
# names objects/unknown/weapons/polearms/axe_type
angled_poleaxe
long_poleaxe
pole_cleaver
broad_pick
# names objects/unknown/weapons/polearms/curved
pole_sickle
pruning_hook
hooked_polearm
# names objects/unknown/weapons/polearms/other
pronged_polearm
beaked_polearm
# names objects/unknown/weapons/bludgeons
mace
morning_star
war_hammer
club
rubber_hose
staff
thonged_club
flail
bullwhip
# names objects/unknown/weapons/bows
bow
runed_bow
crude_bow
long_bow
sling
crossbow
# names objects/known/weapons/missiles
arrow
elven_arrow
orcish_arrow
silver_arrow
ya
crossbow_bolt
dart
shuriken
boomerang
# names objects/known/weapons/spears
spear
elven_spear
orcish_spear
dwarvish_spear
silver_spear
javelin
trident
# names objects/known/weapons/blades
dagger
elven_dagger
orcish_dagger
silver_dagger
athame
scalpel
knife
stiletto
worm_tooth
crysknife
axe
battle_axe
# names objects/known/weapons/swords
short_sword
elven_short_sword
orcish_short_sword
dwarvish_short_sword
scimitar
silver_saber
broadsword
elven_broadsword
long_sword
two_handed_sword
katana
tsurugi
runesword
# names objects/known/weapons/polearms/spear_type
partisan
ranseur
spetum
glaive
lance
# names objects/known/weapons/polearms/axe_type
halberd
bardiche
voulge
dwarvish_mattock
# names objects/known/weapons/polearms/curved
fauchard
guisarme
bill_guisarme
# names objects/known/weapons/polearms/other
lucern_hammer
bec_de_corbin
# names objects/known/weapons/bludgeons
mace
morning_star
war_hammer
club
rubber_hose
quarterstaff
aklys
flail
bullwhip
# names objects/known/weapons/bows
bow
elven_bow
orcish_bow
yumi
sling
crossbow
# names objects/unknown/armor/helmets
leather_hat
iron_skull_cap
hard_hat
fedora
conical_hat
conical_hat
dented_pot
plumed_helmet
etched_helmet
crested_helmet
visored_helmet
# names objects/unknown/armor/suits/dragon
gray_dragon_scale_mail
silver_dragon_scale_mail
shimmering_dragon_scale_mail
red_dragon_scale_mail
white_dragon_scale_mail
orange_dragon_scale_mail
black_dragon_scale_mail
blue_dragon_scale_mail
green_dragon_scale_mail
yellow_dragon_scale_mail
gray_dragon_scales
silver_dragon_scales
shimmering_dragon_scales
red_dragon_scales
white_dragon_scales
orange_dragon_scales
black_dragon_scales
blue_dragon_scales
green_dragon_scales
yellow_dragon_scales
# names objects/unknown/armor/suits/regular
plate_mail
crystal_plate_mail
bronze_plate_mail
splint_mail
banded_mail
dwarvish_mithril_coat
elven_mithril_coat
chain_mail
crude_chain_mail
scale_mail
studded_leather_armor
ring_mail
crude_ring_mail
leather_armor
leather_jacket
# names objects/unknown/armor/shirts
Hawaiian_shirt
T_shirt
# names objects/unknown/armor/cloaks
mummy_wrapping
faded_pall
coarse_mantelet
hooded_cloak
slippery_cloak
robe
apron
leather_cloak
tattered_cape
opera_cloak
ornamental_cope
piece_of_cloth
# names objects/unknown/armor/shields
small_shield
blue_and_green_shield
white_handed_shield
red_eyed_shield
large_shield
large_round_shield
polished_silver_shield
# names objects/unknown/armor/gloves
old_gloves
padded_gloves
riding_gloves
fencing_gloves
# names objects/unknown/armor/boots
walking_shoes
hard_shoes
jackboots
combat_boots
jungle_boots
hiking_boots
mud_boots
buckled_boots
riding_boots
snow_boots
# names objects/known/armor/helmets
elven_leather_helm
orcish_helm
dwarvish_iron_helm
fedora
cornuthaum
dunce_cap
dented_pot
helmet
helm_of_brilliance
helm_of_opposite_alignment
helm_of_telepathy
# names objects/known/armor/suits/dragon
gray_dragon_scale_mail
silver_dragon_scale_mail
shimmering_dragon_scale_mail
red_dragon_scale_mail
white_dragon_scale_mail
orange_dragon_scale_mail
black_dragon_scale_mail
blue_dragon_scale_mail
green_dragon_scale_mail
yellow_dragon_scale_mail
gray_dragon_scales
silver_dragon_scales
shimmering_dragon_scales
red_dragon_scales
white_dragon_scales
orange_dragon_scales
black_dragon_scales
blue_dragon_scales
green_dragon_scales
yellow_dragon_scales
# names objects/known/armor/suits/regular
plate_mail
crystal_plate_mail
bronze_plate_mail
splint_mail
banded_mail
dwarvish_mithril_coat
elven_mithril_coat
chain_mail
orcish_chain_mail
scale_mail
studded_leather_armor
ring_mail
orcish_ring_mail
leather_armor
leather_jacket
# names objects/known/armor/shirts
Hawaiian_shirt
T_shirt
# names objects/known/armor/cloaks
mummy_wrapping
elven_cloak
orcish_cloak
dwarvish_cloak
oilskin_cloak
robe
alchemy_smock
leather_cloak
cloak_of_protection
cloak_of_invisibility
cloak_of_magic_resistance
cloak_of_displacement
# names objects/known/armor/shields
small_shield
elven_shield
Uruk_hai_shield
orcish_shield
large_shield
dwarvish_roundshield
shield_of_reflection
# names objects/known/armor/gloves
leather_gloves
gauntlets_of_fumbling
gauntlets_of_power
gauntlets_of_dexterity
# names objects/known/armor/boots
low_boots
iron_shoes
high_boots
speed_boots
water_walking_boots
jumping_boots
elven_boots
kicking_boots
fumble_boots
levitation_boots
# names objects/unknown/rings
wooden_ring
granite_ring
opal_ring
clay_ring
coral_ring
black_onyx_ring
moonstone_ring
tiger_eye_ring
jade_ring
bronze_ring
agate_ring
topaz_ring
sapphire_ring
ruby_ring
diamond_ring
pearl_ring
iron_ring
brass_ring
copper_ring
twisted_ring
steel_ring
silver_ring
gold_ring
ivory_ring
emerald_ring
wire_ring
engagement_ring
shiny_ring
# names objects/known/rings
ring_of_adornment
ring_of_gain_strength
ring_of_gain_constitution
ring_of_increase_accuracy
ring_of_increase_damage
ring_of_protection
ring_of_regeneration
ring_of_searching
ring_of_stealth
ring_of_sustain_ability
ring_of_levitation
ring_of_hunger
ring_of_aggravate_monster
ring_of_conflict
ring_of_warning
ring_of_poison_resistance
ring_of_fire_resistance
ring_of_cold_resistance
ring_of_shock_resistance
ring_of_free_action
ring_of_slow_digestion
ring_of_teleportation
ring_of_teleport_control
ring_of_polymorph
ring_of_polymorph_control
ring_of_invisibility
ring_of_see_invisible
ring_of_protection_from_shape_changers
# names objects/unknown/amulets
circular_amulet
spherical_amulet
oval_amulet
triangular_amulet
pyramidal_amulet
square_amulet
concave_amulet
hexagonal_amulet
octagonal_amulet
Amulet_of_Yendor
# names objects/known/amulets
amulet_of_ESP
amulet_of_life_saving
amulet_of_strangulation
amulet_of_restful_sleep
amulet_versus_poison
amulet_of_change
amulet_of_unchanging
amulet_of_reflection
amulet_of_magical_breathing
cheap_plastic_imitation_of_the_Amulet_of_Yendor
Amulet_of_Yendor
# names objects/unknown/tools/containers
large_box
chest
ice_box
bag
# names objects/unknown/tools/lock_opening
key
lock_pick
credit_card
# names objects/unknown/tools/light_sources
candle
brass_lantern
lamp
# names objects/unknown/tools/other
expensive_camera
looking_glass
glass_orb
lenses
blindfold
towel
saddle
leash
stethoscope
tinning_kit
tin_opener
can_of_grease
figurine
magic_marker
# names objects/unknown/tools/traps
land_mine
beartrap
# names objects/unknown/tools/instruments
whistle
flute
horn
harp
bell
bugle
drum
# names objects/unknown/tools/weapons
pick_axe
iron_hook
unicorn_horn
# names objects/unknown/tools/artifacts
candelabrum
silver_bell
# names objects/known/tools/containers
large_box
chest
ice_box
sack
oilskin_sack
bag_of_holding
bag_of_tricks
# names objects/known/tools/lock_opening
skeleton_key
lock_pick
credit_card
# names objects/known/tools/light_sources
tallow_candle
wax_candle
brass_lantern
oil_lamp
magic_lamp
# names objects/known/tools/other
expensive_camera
mirror
crystal_ball
lenses
blindfold
towel
saddle
leash
stethoscope
tinning_kit
tin_opener
can_of_grease
figurine
magic_marker
# names objects/known/tools/traps
land_mine
beartrap
# names objects/known/tools/instruments
tin_whistle
magic_whistle
wooden_flute
magic_flute
tooled_horn
frost_horn
fire_horn
horn_of_plenty
wooden_harp
magic_harp
bell
bugle
leather_drum
drum_of_earthquake
# names objects/known/tools/weapons
pick_axe
grappling_hook
unicorn_horn
# names objects/known/tools/artifacts
Candelabrum_of_Invocation
Bell_of_Opening
# names objects/unknown/food/meat
tripe_ration
corpse
egg
meatball
meat_stick
huge_chunk_of_meat
meat_ring
# names objects/unknown/food/fruits_and_veggies
kelp_frond
eucalyptus_leaf
apple
orange
pear
melon
banana
carrot
sprig_of_wolfsbane
clove_of_garlic
slime_mold
# names objects/unknown/food/people_food
lump_of_royal_jelly
cream_pie
candy_bar
fortune_cookie
pancake
lembas_wafer
cram_ration
food_ration
K_ration
C_ration
tin
# names objects/known/food/meat
tripe_ration
corpse
egg
meatball
meat_stick
huge_chunk_of_meat
meat_ring
# names objects/known/food/fruits_and_veggies
kelp_frond
eucalyptus_leaf
apple
orange
pear
melon
banana
carrot
sprig_of_wolfsbane
clove_of_garlic
slime_mold
# names objects/known/food/people_food
lump_of_royal_jelly
cream_pie
candy_bar
fortune_cookie
pancake
lembas_wafer
cram_ration
food_ration
K_ration
C_ration
tin
# names objects/unknown/potions
ruby_potion
pink_potion
orange_potion
yellow_potion
emerald_potion
dark_green_potion
cyan_potion
sky_blue_potion
brilliant_blue_potion
magenta_potion
purple_red_potion
puce_potion
milky_potion
swirly_potion
bubbly_potion
smoky_potion
cloudy_potion
effervescent_potion
black_potion
golden_potion
brown_potion
fizzy_potion
dark_potion
white_potion
murky_potion
clear_potion
# names objects/known/potions
potion_of_gain_ability
potion_of_restore_ability
potion_of_confusion
potion_of_blindness
potion_of_paralysis
potion_of_speed
potion_of_levitation
potion_of_hallucination
potion_of_invisibility
potion_of_see_invisible
potion_of_healing
potion_of_extra_healing
potion_of_gain_level
potion_of_enlightenment
potion_of_monster_detection
potion_of_object_detection
potion_of_gain_energy
potion_of_sleeping
potion_of_full_healing
potion_of_polymorph
potion_of_booze
potion_of_sickness
potion_of_fruit_juice
potion_of_acid
potion_of_oil
potion_of_water
# names objects/unknown/scrolls
scroll_labeled_ZELGO_MER
scroll_labeled_JUYED_AWK_YACC
scroll_labeled_NR_9
scroll_labeled_XIXAXA_XOXAXA_XUXAXA
scroll_labeled_PRATYAVAYAH
scroll_labeled_DAIYEN_FOOELS
scroll_labeled_LEP_GEX_VEN_ZEA
scroll_labeled_PRIRUTSENIE
scroll_labeled_ELBIB_YLOH
scroll_labeled_VERR_YED_HORRE
scroll_labeled_VENZAR_BORGAVVE
scroll_labeled_THARR
scroll_labeled_YUM_YUM
scroll_labeled_KERNOD_WEL
scroll_labeled_ELAM_EBOW
scroll_labeled_DUAM_XNAHT
scroll_labeled_ANDOVA_BEGARIN
scroll_labeled_KIRJE
scroll_labeled_VE_FORBRYDERNE
scroll_labeled_HACKEM_MUCHE
scroll_labeled_VELOX_NEB
scroll_labeled_FOOBIE_BLETCH
scroll_labeled_TEMOV
scroll_labeled_GARVEN_DEH
scroll_labeled_READ_ME
stamped_scroll
unlabeled_scroll
# names objects/known/scrolls
scroll_of_enchant_armor
scroll_of_destroy_armor
scroll_of_confuse_monster
scroll_of_scare_monster
scroll_of_remove_curse
scroll_of_enchant_weapon
scroll_of_create_monster
scroll_of_taming
scroll_of_genocide
scroll_of_light
scroll_of_teleportation
scroll_of_gold_detection
scroll_of_food_detection
scroll_of_identify
scroll_of_magic_mapping
scroll_of_amnesia
scroll_of_fire
scroll_of_earth
scroll_of_punishment
scroll_of_charging
scroll_of_stinking_cloud
scroll_of_mail
scroll_of_blank_paper
# names objects/unknown/spellbooks
parchment_spellbook
vellum_spellbook
ragged_spellbook
dog_eared_spellbook
mottled_spellbook
stained_spellbook
cloth_spellbook
leather_spellbook
white_spellbook
pink_spellbook
red_spellbook
orange_spellbook
yellow_spellbook
velvet_spellbook
light_green_spellbook
dark_green_spellbook
turquoise_spellbook
cyan_spellbook
light_blue_spellbook
dark_blue_spellbook
indigo_spellbook
magenta_spellbook
purple_spellbook
violet_spellbook
tan_spellbook
plaid_spellbook
light_brown_spellbook
dark_brown_spellbook
gray_spellbook
wrinkled_spellbook
dusty_spellbook
bronze_spellbook
copper_spellbook
silver_spellbook
gold_spellbook
glittering_spellbook
shining_spellbook
dull_spellbook
thin_spellbook
thick_spellbook
canvas_spellbook
hardcover_spellbook
plain_spellbook
papyrus_spellbook
# names objects/known/spellbooks
spellbook_of_dig
spellbook_of_magic_missile
spellbook_of_fireball
spellbook_of_cone_of_cold
spellbook_of_sleep
spellbook_of_finger_of_death
spellbook_of_light
spellbook_of_detect_monsters
spellbook_of_healing
spellbook_of_knock
spellbook_of_force_bolt
spellbook_of_confuse_monster
spellbook_of_cure_blindness
spellbook_of_drain_life
spellbook_of_slow_monster
spellbook_of_wizard_lock
spellbook_of_create_monster
spellbook_of_detect_food
spellbook_of_cause_fear
spellbook_of_clairvoyance
spellbook_of_cure_sickness
spellbook_of_charm_monster
spellbook_of_haste_self
spellbook_of_detect_unseen
spellbook_of_levitation
spellbook_of_extra_healing
spellbook_of_restore_ability
spellbook_of_invisibility
spellbook_of_detect_treasure
spellbook_of_remove_curse
spellbook_of_magic_mapping
spellbook_of_identify
spellbook_of_turn_undead
spellbook_of_polymorph
spellbook_of_teleport_away
spellbook_of_create_familiar
spellbook_of_cancellation
spellbook_of_protection
spellbook_of_jumping
spellbook_of_stone_to_flesh
spellbook_of_flame_sphere
spellbook_of_freeze_sphere
spellbook_of_blank_paper
Book_of_the_Dead
# names objects/unknown/wands
glass_wand
balsa_wand
crystal_wand
maple_wand
pine_wand
oak_wand
ebony_wand
marble_wand
tin_wand
brass_wand
copper_wand
silver_wand
platinum_wand
iridium_wand
zinc_wand
aluminum_wand
uranium_wand
iron_wand
steel_wand
hexagonal_wand
short_wand
runed_wand
long_wand
curved_wand
forked_wand
spiked_wand
jeweled_wand
# names objects/known/wands
wand_of_light
wand_of_secret_door_detection
wand_of_enlightenment
wand_of_create_monster
wand_of_wishing
wand_of_nothing
wand_of_striking
wand_of_make_invisible
wand_of_slow_monster
wand_of_speed_monster
wand_of_undead_turning
wand_of_polymorph
wand_of_cancellation
wand_of_teleportation
wand_of_opening
wand_of_locking
wand_of_probing
wand_of_digging
wand_of_magic_missile
wand_of_fire
wand_of_cold
wand_of_sleep
wand_of_death
wand_of_lightning
# names objects/unknown/gems
black_gem
blue_gem
green_gem
orange_gem
red_gem
violet_gem
white_gem
yellow_gem
yellowish_brown_gem
# names objects/known/gems
dilithium_crystal
diamond
ruby
jacinth_stone
sapphire
black_opal
emerald
turquoise_stone
citrine_stone
aquamarine_stone
amber_stone
topaz_stone
jet_stone
opal
chrysoberyl_stone
garnet_stone
amethyst_stone
jasper_stone
fluorite_stone
obsidian_stone
agate_stone
jade_stone
worthless_piece_of_white_glass
worthless_piece_of_blue_glass
worthless_piece_of_red_glass
worthless_piece_of_yellowish_brown_glass
worthless_piece_of_orange_glass
worthless_piece_of_yellow_glass
worthless_piece_of_black_glass
worthless_piece_of_green_glass
worthless_piece_of_violet_glass
# names objects/unknown/rocks
gray_stone
rock
# names objects/known/rocks
luckstone
loadstone
touchstone
flint_stone
rock
# names objects/unknown/miscellaneous
boulder
statue
heavy_iron_ball
iron_chain
splash_of_venom
# names objects/known/miscellaneous
boulder
statue
heavy_iron_ball
iron_chain
blinding_venom
acid_venom
# names roles/classes
archeologist
barbarian
caveman
healer
knight
monk
priest
rogue
ranger
samurai
tourist
valkyrie
wizard
# names roles/levels/archeologist
Digger
Field_Worker
Investigator
Exhumer
Excavator
Spelunker
Speleologist
Collector
Curator
# names roles/levels/barbarian
Plunderer
Plunderess
Pillager
Bandit
Brigand
Raider
Reaver
Slayer
Chieftain
Chieftainess
Conqueror
Conqueress
# names roles/levels/caveman
Troglodyte
Aborigine
Wanderer
Vagrant
Wayfarer
Roamer
Nomad
Rover
Pioneer
# names roles/levels/healer
Rhizotomist
Empiric
Embalmer
Dresser
Medicus_ossium
Medica_ossium
Herbalist
Magister
Magistra
Physician
Chirurgeon
# names roles/levels/knight
Gallant
Esquire
Bachelor
Sergeant
Knight
Banneret
Chevalier
Chevaliere
Seignieur
Dame
Paladin
# names roles/levels/monk
Candidate
Novice
Initiate
Student_of_Stones
Student_of_Waters
Student_of_Metals
Student_of_Winds
Student_of_Fire
Master
# names roles/levels/priest
Aspirant
Acolyte
Adept
Priest
Priestess
Curate
Canon
Canoness
Lama
Patriarch
Matriarch
High_Priest
High_Priestess
# names roles/levels/rogue
Footpad
Cutpurse
Rogue
Pilferer
Robber
Burglar
Filcher
Magsman
Magswoman
Thief
# names roles/levels/ranger
Tenderfoot
Lookout
Trailblazer
Reconnoiterer
Reconnoiteress
Scout
Arbalester
Archer
Sharpshooter
Marksman
Markswoman
# names roles/levels/samurai
Hatamoto
Ronin
Ninja
Kunoichi
Joshu
Ryoshu
Kokushu
Daimyo
Kuge
Shogun
# names roles/levels/tourist
Rambler
Sightseer
Excursionist
Peregrinator
Peregrinatrix
Traveler
Journeyer
Voyager
Explorer
Adventurer
# names roles/levels/valkyrie
Stripling
Skirmisher
Fighter
Man_at_arms
Woman_at_arms
Warrior
Swashbuckler
Hero
Heroine
Champion
Lord
Lady
# names roles/levels/wizard
Evoker
Conjurer
Thaumaturge
Magician
Enchanter
Enchantress
Sorcerer
Sorceress
Necromancer
Wizard
Mage
# names roles/gods/archeologist
Quetzalcoatl
Camaxtli
Huhetotl
# names roles/gods/barbarian
Mitra
Crom
Set
# names roles/gods/caveman
Anu
Ishtar
Anshar
# names roles/gods/healer
Athena
Hermes
Poseidon
# names roles/gods/knight
Lugh
Brigit
Manannan_Mac_Lir
# names roles/gods/monk
Shan_Lai_Ching
Chih_Sung_tzu
Huan_Ti
# names roles/gods/rogue
Issek
Mog
Kos
# names roles/gods/ranger
Mercury
Venus
Mars
# names roles/gods/samurai
Amaterasu_Omikami
Raijin
# names roles/gods/tourist
Blind_Io
The_Lady
Offler
# names roles/gods/valkyrie
Tyr
Odin
Loki
# names roles/gods/wizard
Ptah
Thoth
Anhur
# names races
human
elf
dwarf
gnome
orc
# names genders
male
female
neuter
# names alignment
lawful
neutral
chaotic
unaligned
# names names/ghosts
Adri
Andries
Andreas
Bert
David
Dirk
Emile
Frans
Fred
Greg
Hether
Jay
John
Jon
Karnov
Kay
Kenny
Kevin
Maud
Michiel
Mike
Peter
Robert
Ron
Tom
Wilmar
Nick_Danger
Phoenix
Jiro
Mizue
Stephan
Lance_Braccus
Shadowhawk
# names names/coyotes
Carnivorous_Vulgaris
Road_Runnerus_Digestus
Eatibus_Anythingus
Famishus_Famishus
Eatibus_Almost_Anythingus
Eatius_Birdius
Famishius_Fantasticus
Eternalii_Famishiis
Famishus_Vulgarus
Famishius_Vulgaris_Ingeniusi
Eatius_Slobbius
Hardheadipus_Oedipus
Carnivorous_Slobbius
Hard_Headipus_Ravenus
Evereadii_Eatibus
Apetitius_Giganticus
Hungrii_Flea_Bagius
Overconfidentii_Vulgaris
Caninus_Nervous_Rex
Grotesques_Appetitus
Nemesis_Riduclii
Canis_latrans
# names shops
general_store
used_armor_dealership
second_hand_bookstore
liquor_emporium
antique_weapons_outlet
delicatessen
jewelers
quality_apparel_and_accessories
hardware_store
rare_books
lighting_store
# names names/shopkeepers/liquor
Njezjin
Tsjernigof
Ossipewsk
Gorlowka
Gomel
Konosja
Weliki_Oestjoeg
Syktywkar
Sablja
Narodnaja
Kyzyl
Walbrzych
Swidnica
Klodzko
Raciborz
Gliwice
Brzeg
Krnov
Hradec_Kralove
Leuk
Brig
Brienz
Thun
Sarnen
Burglen
Elm
Flims
Vals
Schuls
Zum_Loch
# names names/shopkeepers/book
Skibbereen
Kanturk
Rath_Luirc
Ennistymon
Lahinch
Kinnegad
Lugnaquillia
Enniscorthy
Gweebarra
Kittamagh
Nenagh
Sneem
Ballingeary
Kilgarvan
Cahersiveen
Glenbeigh
Kilmihil
Kiltamagh
Droichead_Atha
Inniscrone
Clonegal
Lisnaskea
Culdaff
Dunfanaghy
Inishbofin
Kesh
# names names/shopkeepers/armor
Demirci
Kalecik
Boyabai
Yildizeli
Gaziantep
Siirt
Akhalataki
Tirebolu
Aksaray
Ermenak
Iskenderun
Kadirli
Siverek
Pervari
Malasgirt
Bayburt
Ayancik
Zonguldak
Balya
Tefenni
Artvin
Kars
Makharadze
Malazgirt
Midyat
Birecik
Kirikkale
Alaca
Polatli
Nallihan
# names names/shopkeepers/wand
Yr_Wyddgrug
Trallwng
Mallwyd
Pontarfynach
Rhaeader
Llandrindod
Llanfair_ym_muallt
Y_Fenni
Maesteg
Rhydaman
Beddgelert
Curig
Llanrwst
Llanerchymedd
Caergybi
Nairn
Turriff
Inverurie
Braemar
Lochnagar
Kerloch
Beinn_a_Ghlo
Drumnadrochit
Morven
Uist
Storr
Sgurr_na_Ciche
Cannich
Gairloch
Kyleakin
Dunvegan
# names names/shopkeepers/ring
Feyfer
Flugi
Gheel
Havic
Haynin
Hoboken
Imbyze
Juyn
Kinsky
Massis
Matray
Moy
Olycan
Sadelin
Svaving
Tapper
Terwen
Wirix
Ypey
Rastegaisa
Varjag_Njarga
Kautekeino
Abisko
Enontekis
Rovaniemi
Avasaksa
Haparanda
Lulea
Gellivare
Oeloe
Kajaani
Fauske
# names names/shopkeepers/food
Djasinga
Tjibarusa
Tjiwidej
Pengalengan
Bandjar
Parbalingga
Bojolali
Sarangan
Ngebel
Djombang
Ardjawinangun
Berbek
Papar
Baliga
Tjisolok
Siboga
Banjoewangi
Trenggalek
Karangkobar
Njalindoeng
Pasawahan
Pameunpeuk
Patjitan
Kediri
Pemboeang
Tringanoe
Makin
Tipor
Semai
Berhala
Tegal
Samoe
# names names/shopkeepers/weapon
Voulgezac
Rouffiac
Lerignac
Touverac
Guizengeard
Melac
Neuvicq
Vanzac
Picq
Urignac
Corignac
Fleac
Lonzac
Vergt
Queyssac
Liorac
Echourgnac
Cazelon
Eypau
Carignan
Monbazillac
Jonzac
Pons
Jumilhac
Fenouilledes
Laguiolet
Saujon
Eymoutiers
Eygurande
Eauze
Labouheyre
# names names/shopkeepers/tool
Ymla
Eed_morra
Cubask
Nieb
Bnowr_Falr
Telloc_Cyaj
Sperc
Noskcirdneh
Yawolloh
Hyeghu
Niskal
Trahnil
Htargcm
Enrobwem
Kachzi_Rellim
Regien
Donmyar
Yelpur
Nosnehpets
Stewe
Renrut
_Zlaw
Nosalnef
Rewuorb
Rellenk
Yad
Cire_Htims
Y_crad
Nenilukah
Corsh
Aned
Erreip
Nehpets
Mron
Snivek
Lapu
Kahztiy
Lechaim
Lexa
Niod
Nhoj_lee
Evad_kh
Ettaw_noj
Tsew_mot
Ydna_s
Yao_hang
Tonbar
Kivenhoug
Falo
Nosid_da_r
Ekim_p
Rebrol_nek
Noslo
Yl_rednow
Mured_oog
Ivrajimsal
Nivram
Lez_tneg
Ytnu_haled
Niknar
# names names/shopkeepers/light
Zarnesti
Slanic
Nehoiasu
Ludus
Sighisoara
Nisipitu
Razboieni
Bicaz
Dorohoi
Vaslui
Fetesti
Tirgu_Neamt
Babadag
Zimnicea
Zlatna
Jiu
Eforie
Mamaia
Silistra
Tulovo
Panagyuritshte
Smolyan
Kirklareli
Pernik
Lom
Haskovo
Dobrinishte
Varvara
Oryahovo
Troyan
Lovech
Sliven
# names names/shopkeepers/light_in_mine
Izchak
# names names/shopkeepers/general
Hebiwerie
Possogroenoe
Asidonhopo
Manlobbi
Adjama
Pakka_Pakka
Kabalebo
Wonotobo
Akalapi
Sipaliwini
Annootok
Upernavik
Angmagssalik
Aklavik
Inuvik
Tuktoyaktuk
Chicoutimi
Ouiatchouane
Chibougamau
Matagami
Kipawa
Kinojevis
Abitibi
Maganasipi
Akureyri
Kopasker
Budereyri
Akranes
Bordeyri
Holmavik
# names tshirts
I_explored_the_Dungeons_of_Doom_and_all_I_got_was_this_lousy_T_shirt
Is_that_Mjollnir_in_your_pocket_or_are_you_just_happy_to_see_me
It_s_not_the_size_of_your_sword__it_s_how__enhance_d_you_are_with_it
Madame_Elvira_s_House_O__Succubi_Lifetime_Customer
Madame_Elvira_s_House_O__Succubi_Employee_of_the_Month
Ludios_Vault_Guards_Do_It_In_Small__Dark_Rooms
Yendor_Military_Soldiers_Do_It_In_Large_Groups
I_survived_Yendor_Military_Boot_Camp
Ludios_Accounting_School_Intra_Mural_Lacrosse_Team
Oracle_TM__Fountains_10th_Annual_Wet_T_Shirt_Contest
Hey__black_dragon__Disintegrate_THIS
I_m_With_Stupid
Don_t_blame_me__I_voted_for_Izchak
Don_t_Panic
Furinkan_High_School_Athletic_Dept
Hel_LOOO__Nurse
# names sounds
beep
belche
boing
burbles
buzz
buzzes
chuckles
commotion
cough
creak
drones
eep
giggles
growl
growls
grunts
gurgles
hiss
hisses
howls
jingle
laughs
meows
mews
neigh
neighs
pop
purrs
rattle
roar
roars
screak
scream
screech
shrieks
sing
snarl
snarls
snickers
sniffle
squawks
squeaks
squeal
tinkle
ululate
wail
wails
whickers
whimper
whine
whines
whinnies
yelp
yips
yowl
yowls
# names statements
A_cascade_of_steamy_bubbles_erupts_from_the_chest
A_chill_runs_down_your_spine
A_cloud_of_gas_puts_you_to_sleep
A_cloud_of_noxious_gas_billows_from_the_chest
A_cloud_of_plaid_gas_billows_from_the_chest
A_hail_of_magic_missiles_narrowly_misses_you
A_huge_hole_opens_up___
A_little_dart_shoots_out_at_you
A_potion_explodes
A_shiver_runs_up_and_down_your_spine
A_trap_door_in_the_ceiling_opens__but_nothing_falls_out
A_trap_door_opens_up_under_you
Air_currents_pull_you_down_into_the_spiked_pit
Aloha
An_arrow_shoots_out_at_you
And_just_how_do_you_expect_to_do_that_
Anything_you_say_can_be_used_against_you
At_least_one_of_your_artifacts_is_cursed___
Back_from_the_dead__are_you__I_ll_remedy_that
Batteries_have_not_been_invented_yet
Being_confused_you_have_difficulties_in_controlling_your_actions
Bummer__You_ve_splashed_down
But_in_vain
But_luckily_the_electric_charge_is_grounded
But_luckily_the_explosive_charge_is_a_dud
But_luckily_the_flame_fizzles_out
But_luckily_the_gas_cloud_blows_away
But_luckily_the_poisoned_needle_misses
But_you_aren_t_drowning
Child_of_the_night__I_beg_you__help_me_satisfy_this_growing_craving
Child_of_the_night__I_can_stand_this_craving_no_longer
Child_of_the_night__I_find_myself_growing_a_little_weary
Click__You_trigger_a_rolling_boulder_trap
Death_is_busy_reading_a_copy_of_Sandman_8
Disarm_it_
Doc__I_can_t_help_you_unless_you_cooperate
Don_t_be_ridiculous
Eh_
Even_now_thy_life_force_ebbs__blackguard
For_what_do_you_wish_
Fortunately__you_are_wearing_a_hard_helmet
Fortunately_for_you__no_boulder_was_released
Fortunately_it_has_a_bottom_after_all
Gleep
Good_day_to_you_Master__Why_do_we_not_rest_
Good_evening_to_you_Master
Good_feeding_brother
Good_feeding_sister
Hell_shall_soon_claim_thy_remains__coistrel
Hello__sailor
How_nice_to_hear_you__child_of_the_night
How_pitiful__Isn_t_that_the_pits_
Huh_
I_beg_you__help_me_satisfy_this_growing_craving
I_can_stand_this_craving_no_longer
I_can_t_see
I_chortle_at_thee__thou_pathetic_demon_fodder
I_find_myself_growing_a_little_weary
I_m_free
I_m_hungry
I_m_trapped
I_only_drink____potions
I_see_nobody_there
I_vant_to_suck_your_blood
I_vill_come_after_midnight_without_regret
Idiot__You_ve_shot_yourself
In_desperation__you_drop_your_purse
Instead_of_shattering__the_statue_suddenly_disappears
It_feels_as_though_you_ve_lost_some_weight
It_invokes_nightmarish_images_in_your_mind___
It_s_obscene
It_seems_even_stronger_than_before
Its_flame_dies
Juiblex_is_grateful
Just_the_facts__Sir
KAABLAMM____The_air_currents_set_it_off
KAABLAMM____You_triggered_a_land_mine
Maybe_you_should_find_a_designated_driver
My_feet_hurt__I_ve_been_on_them_all_day
Nevermore
No_mere_dungeon_adventurer_could_write_that
Nothing_fitting_that_description_exists_in_the_game
Oh__yes__of_course__Sorry_to_have_disturbed_you
Oh_my__Your_name_appears_in_the_book
Out_of_my_way__scum
Pheew__That_was_close
Please_drop_that_gold_and_follow_me
Please_follow_me
Please_undress_so_I_can_examine_you
Prepare_to_die__thou_maledict
Put_that_weapon_away_before_you_hurt_someone
Relax__this_won_t_hurt_a_bit
Resistance_is_useless__poltroon
Saddle_yourself__Very_funny___
Savor_thy_breath__caitiff__it_be_thy_last
Shame_on_you
Some_hell_p_has_arrived
Somebody_tries_to_rob_you__but_finds_nothing_to_steal
Someone_shouts__Off_with_his_head__
Sorry__I_m_all_out_of_wishes
Stop_in_the_name_of_the_Law
Suddenly_the_rolling_boulder_disappears
Suddenly_you_are_frozen_in_place
Suddenly_you_wake_up
Surrender_or_die__thou_rattlepate
Take_off_your_shirt__please
Talking_to_yourself_is_a_bad_habit_for_a_dungeoneer
The_Field_Worker_describes_a_recent_article_in__Spelunker_Today__magazine
The_Green_elf_curses_orcs
The_attempted_teleport_spell_fails
The_book_was_coated_with_contact_poison
The_disenchanter_talks_about_spellcraft
The_explosion_awakens_you
The_food_s_not_fit_for_Orcs
The_forest_centaur_discusses_hunting
The_gnome_talks_about_mining
The_golden_haze_around_you_becomes_more_dense
The_hair_on_the_back_of_your_neck_stands_up
The_headstones_in_the_cemetery_begin_to_move
The_hill_giant_complains_about_a_diet_of_mutton
The_hobbit_asks_you_about_the_One_Ring
The_hobbit_complains_about_unpleasant_dungeon_conditions
The_hole_in_the_ceiling_above_you_closes_up
The_jabberwock_boasts_about_her_gem_collection
The_killer_tomato_discusses_dungeon_exploration
The_lava_here_burns_you
The_missiles_bounce
The_opening_under_you_closes_up
The_poison_was_deadly___
The_pressure_on_your_neck_increases
The_runes_appear_scrambled__You_can_t_read_them
The_slime_that_covers_you_is_burned_away
The_stairs_seem_to_ripple_momentarily
The_statue_comes_to_life
The_stone_giant_shouts__Fee_Fie_Foe_Foo___and_guffaws
The_water_around_you_begins_to_shimmer_with_a_golden_haze
The_webbing_sticks_to_you__You_re_caught_too
The_were_rat_throws_back_his_head_and_lets_out_a_blood_curdling_shriek
The_were_rat_whispers_inaudibly__All_you_can_make_out_is___moon__
Their_cries_sound_like__mommy_
There_is_a_boulder_in_your_way
There_is_a_box_here__Check_it_for_traps_
There_is_a_spider_web_here
There_is_the_trigger_of_your_mine_in_a_pile_of_soil_below_you
There_s_a_gaping_hole_under_you
There_shall_be_no_mercy__thou_miscreant
These_runes_were_just_too_much_to_comprehend
They_shriek
They_won_t_hear_you_up_there
This_door_is_broken
This_door_was_not_trapped
This_is_my_hunting_ground_that_you_dare_to_prowl
This_spellbook_is_all_blank
This_will_teach_you_not_to_disturb_me
Thou_art_as_a_flea_to_me__varlet
Thou_art_doomed__villein
Thou_shalt_repent_of_thy_cunning__reprobate
Thy_fate_is_sealed__wittol
Try_filling_the_pit_instead
Unfortunately__digesting_any_of_it_is_fatal
Unfortunately__nothing_happens
Up__up__and_awaaaay__You_re_walking_on_air
Verily__thou_shalt_be_one_dead_chucklehead
Vlad_s_doppelganger_is_amused
Wait__There_s_a_hidden_monster_there
What_a_groovy_feeling
What_lousy_pay_we_re_getting_here
Who_do_you_think_you_are__War_
Whoops___
You_accidentally_tear_the_spellbook_to_pieces
You_are_a_statue
You_are_caught_in_a_magical_explosion
You_are_covered_with_rust
You_are_encased_in_rock
You_are_enveloped_in_a_cloud_of_gas
You_are_feeling_mildly_nauseated
You_are_hit_by_magic_missiles_appearing_from_thin_air
You_are_jerked_back_by_your_pet
You_are_jolted_by_a_surge_of_electricity
You_are_jolted_with_electricity
You_are_momentarily_blinded_by_a_flash_of_light
You_are_no_longer_invisible
You_are_not_disintegrated
You_are_slowing_down
You_are_stuck_here_for_now
You_are_too_hungry_to_cast_that_spell
You_are_turning_into_green_slime
You_attempt_a_teleport_spell
You_bang_into_the_saddle_horn
You_bash_yourself
You_can_move_again
You_can_no_longer_breathe
You_can_no_longer_see_through_yourself
You_can_t_seem_to_think_straight
You_cancel_it__you_pay_for_it
You_destroy_it
You_die
You_die_from_your_illness
You_dishonorably_attack_the_innocent
You_dishonorably_use_a_poisoned_weapon
You_dissolve_a_spider_web
You_don_t_fall_in
You_don_t_feel_hot
You_don_t_feel_sleepy
You_don_t_fit_through
You_don_t_seem_to_be_affected
You_explode_a_fireball_on_top_of_yourself
You_fall_asleep
You_fall_into_the_lava
You_feel_a_change_coming_over_you
You_feel_a_little_chill
You_feel_a_wrenching_sensation
You_feel_embarrassed_for_a_moment
You_feel_guilty_about_damaging_such_a_historic_statue
You_feel_incredibly_sick
You_feel_like_an_evil_coward_for_using_a_poisoned_weapon
You_feel_momentarily_different
You_feel_momentarily_lethargic
You_feel_no_door_there
You_feel_oddly_like_the_prodigal_son
You_feel_rather_itchy_under_your_chain_mail
You_feel_rather_warm
You_feel_slightly_confused
You_feel_that_you_did_the_right_thing
You_feel_the_amulet_draining_your_energy_away
You_feel_threatened
You_feel_your_magical_energy_drain_away
You_feel_yourself_slowing_down_a_bit
You_find_it_hard_to_breathe
You_find_yourself_back_in_an_air_bubble
You_find_yourself_reading_the_first_line_over_and_over_again
You_flounder
You_flow_through_the_spider_web
You_had_better_wait_for_the_sun_to_come_out
You_have_an_uneasy_feeling_about_wielding_cold_iron
You_have_become_green_slime
You_have_hidden_gold
You_have_no_hands
You_have_no_way_to_attack_monsters_physically
You_have_turned_to_stone
You_hear_Doctor_Doolittle
You_hear_Donald_Duck
You_hear_Ebenezer_Scrooge
You_hear_General_MacArthur
You_hear_Neiman_and_Marcus_arguing
You_hear_Queen_Beruthiel_s_cats
You_hear_a_deafening_roar
You_hear_a_gurgling_noise
You_hear_a_loud_ZOT
You_hear_a_loud_click
You_hear_a_loud_crash_as_one_boulder_sets_another_in_motion
You_hear_a_low_buzzing
You_hear_a_sceptre_pounded_in_judgment
You_hear_a_slow_drip
You_hear_a_soda_fountain
You_hear_a_sound_reminiscent_of_a_seal_barking
You_hear_a_sound_reminiscent_of_an_elephant_stepping_on_a_peanut
You_hear_a_strange_wind
You_hear_a_twang_followed_by_a_thud
You_hear_an_angry_drone
You_hear_bees_in_your_bonnet
You_hear_blades_being_honed
You_hear_bubbling_water
You_hear_convulsive_ravings
You_hear_dice_being_thrown
You_hear_dishes_being_washed
You_hear_loud_snoring
You_hear_mosquitoes
You_hear_snoring_snakes
You_hear_someone_bowling
You_hear_someone_counting_money
You_hear_someone_cursing_shoplifters
You_hear_someone_say__No_more_woodchucks__
You_hear_someone_searching
You_hear_the_chime_of_a_cash_register
You_hear_the_footsteps_of_a_guard_on_patrol
You_hear_the_moon_howling_at_you
You_hear_the_quarterback_calling_the_play
You_hear_the_splashing_of_a_naiad
You_hear_the_tones_of_courtly_conversation
You_hear_water_falling_on_coins
You_imitate_a_popsicle
You_irradiate_yourself_with_pure_energy
You_let_go_of_the_reins
You_make_a_lot_of_noise
You_need_hands_to_be_able_to_write
You_notice_a_crease_in_the_linoleum
You_raised_the_dead
You_re_dog_meat
You_re_gasping_for_air
You_re_joking__In_this_weather_
You_re_still_burning
You_re_still_drowning
You_re_too_strained_to_do_that
You_re_turning_blue
You_re_under_arrest
You_repair_the_squeaky_board
You_see_a_burning_potion_of_oil_go_out
You_see_a_lantern_run_out_of_power
You_seem_no_deader_than_before
You_sense_a_pointy_hat_on_top_of_your_head
You_shock_yourself
You_shudder_in_dread
You_sink_into_the_lava__but_it_only_burns_slightly
You_sink_like_the_Titanic
You_slide_to_one_side_of_the_saddle
You_slip_on_a_banana_peel
You_smell_hamburgers
You_smell_marsh_gas
You_smell_paper_burning
You_smell_the_odor_of_meat
You_speed_up
You_step_onto_a_polymorph_trap
You_stumble
You_suck_in_some_slime_and_don_t_feel_very_well
You_suddenly_realize_it_is_unnaturally_quiet
You_suddenly_vomit
You_suddenly_yearn_for_Cleveland
You_suffocate
You_take_a_walk_on_your_web
You_trip_over_your_own_elbow
You_turn_the_pages_of_the_Book_of_the_Dead___
You_ve_been_through_the_dungeon_on_a_wumpus_with_no_name__It_felt_good_to_get_out_of_the_rain
You_ve_been_warned__knave
You_ve_set_yourself_afire
You_wake_up
You_won_t_fit_on_a_saddle
You_zap_yourself__but_seem_unharmed
Young_Fool__Your_silver_sheen_does_not_frighten_me
Your_ancestors_are_annoyed_with_you
Your_blood_is_having_trouble_reaching_your_brain
Your_bloodthirsty_blade_attacks
Your_body_absorbs_some_of_the_magical_energy
Your_candelabrum_s_candles_are_getting_short
Your_candle_s_flame_flickers_low
Your_concentration_falters_while_carrying_so_much_stuff
Your_consciousness_is_fading
Your_feet_slip_out_of_the_stirrups
Your_gloves_seem_unaffected
Your_hands_seem_to_be_too_busy_for_that
Your_lantern_is_getting_dim
Your_limbs_are_getting_oozy
Your_limbs_are_stiffening
Your_limbs_have_turned_to_stone
Your_neck_is_becoming_constricted
Your_potion_of_oil_has_burnt_away
Your_purse_feels_heavier
Your_skin_begins_to_peel_away
Your_skin_feels_warm_for_a_moment
Your_weapon_seems_sharper_now
