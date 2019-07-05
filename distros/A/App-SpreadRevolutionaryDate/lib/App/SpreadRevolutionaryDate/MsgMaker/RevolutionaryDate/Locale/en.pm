#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en;
$App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en::VERSION = '0.27';
# ABSTRACT: English localization of (part of) L<DateTime::Calendar::FrenchRevolutionary::Locale::en>

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale';

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;


has '+months' => (
  default => sub {[
    'Vintagearious', 'Fogarious', 'Frostarious',
    'Snowous',       'Rainous',   'Windous',
    'Buddal',        'Floweral',  'Meadowal',
    'Reapidor',      'Heatidor',  'Fruitidor',
    'additional day',
  ]},
);

has '+decade_days' => (
  default => sub {[
    'Firsday',
    'Seconday',
    'Thirday',
    'Fourday',
    'Fifday',
    'Sixday',
    'Sevenday',
    'Eightday',
    'Nineday',
    'Tenday',
  ]},
);

has '+feast' => (
  default => sub {[
    # Vendémiaire
    qw(
      0grape                0saffron       0chestnut       0crocus      0horse
      0balsam               0carrot        0amaranth       0parsnip     0vat
      0potato               0everlasting   0winter_squash  0mignonette  0donkey
      0four_o'clock_flower  0pumpkin       0buckwheat      0sunflower   0wine-press
      0hemp                 0peach         0turnip         0amaryllis   0ox
      0eggplant             0chili_pepper  0tomato         0barley      0barrel
    ),
    # Brumaire
    qw(
      0apple       0celery          0pear                 0beetroot      0goose
      0heliotrope  0fig             0black_salsify        0chequer_tree  0plow
      0salsify     0water_chestnut  0jerusalem_artichoke  0endive        0turkey
      0skirret     0cress           0leadworts            0pomegranate   0harrow
      0baccharis   0azarole         0madder               0orange        0pheasant
      0pistachio   0tuberous_pea    0quince               0service_tree  0roller
    ),
    # Frimaire
    qw(
      0rampion     0turnip        0chicory     0medlar         0pig
      0corn_salad  0cauliflower   0honey       0juniper        0pickaxe
      0wax         0horseradish   0cedar_tree  0fir_tree       0roe_deer
      0gorse       0cypress_tree  0ivy         0savin_juniper  0grub-hoe
      0maple_tree  0heather       0reed        0sorrel         0cricket
      0pine_nut    0cork          0truffle     0olive          0shovel
    ),
    # Nivôse
    qw(
      0peat     0coal     0bitumen    0sulphur    0dog
      0lava     0topsoil  0manure     0saltpeter  0flail
      0granite  0clay     0slate      0sandstone  0rabbit
      0flint    0marl     0limestone  0marble     0winnowing_basket
      0gypsum   0salt     0iron       0copper     0cat
      0tin      0lead     0zinc       0mercury    0sieve
    ),
    # Pluviôse
    qw(
      0spurge_laurel  0moss             0butcher's_broom  0snowdrop          0bull
      0laurustinus    0tinder_polypore  0mezereon         0poplar_tree       0axe
      0hellebore      0broccoli         0laurel           0common_hazel      0cow
      0box_tree       0lichen           0yew_tree         0lungwort          0billhook
      0penny-cress    0daphne           0couch_grass      0common_knotgrass  0hare
      0woad           0hazel_tree       0cyclamen         0celandine         0sleigh
    ),
    # Ventôse
    qw(
      0coltsfoot    0dogwood                  0matthiola        0privet         0billygoat
      0wild_ginger  0mediterranean_buckthorn  0violet           0goat_willow    0spade
      0narcissus    0elm_tree                 0fumitory         0hedge_mustard  0goat
      0spinach      0leopard's_bane           0pimpernel        0chervil        0line
      0mandrake     0parsley                  0scurvy-grass     0daisy          0tuna_fish
      0dandelion    0windflower               0maidenhair_fern  0ash_tree       0dibble
    ),
    # Germinal
    qw(
      0primula     0plane_tree     0asparagus      0tulip       0hen
      0chard       0birch_tree     0daffodil       0alder       0hatchery
      0periwinkle  0hornbeam       0morel          0beech_tree  0bee
      0lettuce     0larch          0hemlock        0radish      0hive
      0judas_tree  0roman_lettuce  0chestnut_tree  0rocket      0pigeon
      0lilac       0anemone        0pansy          0blueberry   0dibber
    ),
    # Floréal
    qw(
      0rose         0oak_tree            0fern            0hawthorn       0nightingale
      0columbine    0lily_of_the_valley  0mushroom        0hyacinth       0rake
      0rhubarb      0sainfoin            0wallflower      0fan_palm_tree  0silkworm
      0comfrey      0burnet              0basket_of_gold  0orache         0hoe
      0thrift       0fritillary          0borage          0valerian       0carp
      0spindletree  0chive               0bugloss         0wild_mustard   0shepherd_staff
    ),
    # Prairial
    qw(
      0alfalfa     0day-lily    0clover       0angelica    0duck
      0lemon_balm  0oat_grass   0martagon     0wild_thyme  0scythe
      0strawberry  0betony      0pea          0acacia      0quail
      0carnation   0elder_tree  0poppy        0lime        0pitchfork
      0barbel      0camomile    0honeysuckle  0bedstraw    0tench
      0jasmine     0vervain     0thyme        0peony       0carriage
    ),
    # Messidor
    qw(
      0rye        0oats       0onion      0speedwell  0mule
      0rosemary   0cucumber   0shallot    0wormwood   0sickle
      0coriander  0artichoke  0clove      0lavender   0chamois
      0tobacco    0currant    0vetchling  0cherry     0park
      0mint       0cumin      0bean       0alkanet    0guinea_hen
      0sage       0garlic     0tare       0corn       0shawm
    ),
    # Thermidor
    qw(
      0spelt            0mullein        0melon      0ryegrass    0ram
      0horsetail        0mugwort        0safflower  0blackberry  0watering_can
      0switchgrass      0glasswort      0apricot    0basil       0ewe
      0marshmallow      0flax           0almond     0gentian     0waterlock
      0carline_thistle  0caper          0lentil     0horseheal   0otter
      0myrtle           0oil-seed_rape  0lupin      0cotton      0mill
    ),
    # Fructidor
    qw(
      0plum           0millet     0lycoperdon  0barley     0salmon
      0tuberose       0bere       0dogbane     0liquorice  0stepladder
      0watermelon     0fennel     0barberry    0walnut     0trout
      0lemon          0teasel     0buckthorn   0marigold   0harvesting_basket
      0wild_rose      0hazelnut   0hops        0sorghum    0crayfish
      0bitter_orange  0goldenrod  0corn        0chestnut   0basket
    ),
    # Jours complémentaires
    qw(
      0virtue      0engineering  0labour  0opinion  0rewards
      0revolution
    ),
  ]},
);

has '+prefixes' => (
  default => sub {['']},
);

has '+suffix' => (
  default => ' day',
);

has '+wikipedia_entries' => (
  default => sub {{
    1 => {
      'sweet chestnut'      => 'Chestnut',
      'colchic'             => 'Colchicum_autumnale',
      'crocus'              => 'Colchicum_autumnale',
      'balsam'              => 'Impatiens',
      'everlasting'         => 'Helichrysum_arenarium',
      'strawflower'         => 'Helichrysum_arenarium',
      'squash'              => 'Winter_squash',
      'mignonette'          => 'Reseda_(plant)',
      "four o'clock flower" => 'Mirabilis_jalapa',
      'sunflower'           => 'Helianthus',
      'sunflower'           => 'Helianthus',
      'wine-press'          => 'Fruit_press',
      'ox'                  => 'Cattle',
      'barrel'              => 'Barrel#Beverage_maturing',
    },
    2 => {
      'heliotrope'     => 'Heliotropium',
      'fig'            => 'Common_fig',
      'black salsify'  => 'Scorzonera_hispanica',
      'whitebeam'      => 'Sorbus_torminalis',
      'chequer tree'   => 'Sorbus_torminalis',
      'plow'           => 'Plough',
      'salsify'        => 'Tragopogon_porrifolius',
      'water chestnut' => 'Water_caltrop',
      'turkey'         => 'Turkey_(bird)',
      'skirret'        => 'Sium_sisarum',
      'cress'          => 'Watercress',
      'plumbago'       => 'Plumbaginaceae',
      'leadworts'      => 'Plumbaginaceae',
      'harrow'         => 'Harrow_(tool)',
      'bacchante'      => 'Baccharis_halimifolia',
      'baccharis'      => 'Baccharis_halimifolia',
      'azarole'        => 'Crataegus_azarolus',
      'madder'         => 'Rubia',
      'orange'         => 'Orange_(fruit)',
      'tuberous pea'   => 'Lathyrus_tuberosus',
      'service tree'   => 'Sorbus_domestica',
      'roller'         => 'Roller_(agricultural_tool)',
    },
    3 => {
      'rampion'        => 'Phyteuma',
      'medlar'         => 'Mespilus_germanica',
      'corn salad'     => 'Valerianella_locusta',
      "lamb's lettuce" => 'Valerianella_locusta',
      'juniper'        => 'Juniperus_communis',
      'cedar tree'     => 'Cedrus',
      'fir tree'       => 'Fir',
      'gorse'          => 'Ulex',
      'cypress tree'   => 'Cupressus_sempervirens',
      'ivy'            => 'Hedera',
      'savin juniper'  => 'Juniperus_sabina',
      'grub-hoe'       => 'Hoe_(tool)',
      'maple tree'     => 'Acer_saccharum',
      'sugar maple'    => 'Acer_saccharum',
      'heather'        => 'Calluna',
      'reed'           => 'Phragmites',
      'reed plant'     => 'Phragmites',
      'cricket'        => 'Cricket_(insect)',
    },
    4 => {
      'saltpeter'        => 'Potassium_nitrate',
      'flail'            => 'Flail_(agriculture)',
      'winnowing basket' => 'Winnowing',
      'iron'             => 'Iron_(material)',
      'mercury'          => 'Mercury_(element)',
    },
    5 => {
      'spurge laurel'     => 'Daphne_laureola',
      "butcher's broom"   => 'Ruscus_aculeatus',
      'laurustinus'       => 'Viburnum_tinus',
      'tinder polypore'   => 'Fomes_fomentarius',
      'mezereon'          => 'Daphne_mezereum',
      'poplar tree'       => 'Populus',
      'poplar'            => 'Populus',
      'laurel'            => 'Bay_laurel',
      'common hazel'      => 'Corylus_maxima',
      'filbert'           => 'Corylus_maxima',
      'cow'               => 'Cattle',
      'box tree'          => 'Box_(tree)',
      'yew tree'          => 'Taxus_baccata',
      'penny-cress'       => 'Thlaspi_arvense',
      'pennycress'        => 'Thlaspi_arvense',
      'daphne'            => 'Daphne_cneorum',
      'rose daphne'       => 'Daphne_cneorum',
      'common knotgrass'  => 'Polygonum_aviculare',
      'hazel tree'        => 'Hazel',
      'celandine'         => 'Greater_celandine',
    },
    6 => {
      'coltsfoot'               => 'Tussilago',
      'dogwood'                 => 'Cornus_(genus)',
      'hoary stock'             => 'Matthiola',
      'billygoat'               => 'Goat',
      'wild ginger'             => 'Asarum',
      'mediterranean buckthorn' => 'Rhamnus_alaternus',
      'italian buckthorn'       => 'Rhamnus_alaternus',
      'violet'                  => 'Viola_(plant)',
      'goat willow'             => 'Salix_caprea',
      'narcissus'               => 'Narcissus_(plant)',
      'elm tree'                => 'Elm',
      'fumitory'                => 'Fumaria_officinalis',
      'common fumitory'         => 'Fumaria_officinalis',
      'hedge mustard'           => 'Sisymbrium_officinale',
      "leopard's bane"          => 'Doronicum',
      'pimpernel'               => 'Anagallis',
      'line'                    => 'Twine',
      'mandrake'                => 'Mandragora_officinarum',
      'scurvy-grass'            => 'Cochlearia',
      'daisy'                   => 'Bellis_perennis',
      'tuna fish'               => 'Tuna',
      'dandelion'               => 'Taraxacum',
      'windflower'              => 'Anemone_nemorosa',
      'wood anemone'            => 'Anemone_nemorosa',
      'maidenhair fern'         => 'Adiantum_capillus-veneris',
      'ash tree'                => 'Fraxinus',
      'dibble'                  => 'Dibber',
    },
    7 => {
      'primula'        => 'Primula_vulgaris',
      'primrose'       => 'Primula_vulgaris',
      'plan tree'      => 'Planatus',
      'hen'            => 'Chicken',
      'birch tree'     => 'Birch',
      'daffodil'       => 'Narcissus_(plant)',
      'periwinkle'     => 'Vinca',
      'morel'          => 'Morchella',
      'beech tree'     => 'Fagus_sylvatica',
      'hemlock'        => 'Conium',
      'hive'           => 'Beehive_(beekeeping)',
      'redbud'         => 'Cercis',
      'judas tree'     => 'Cercis',
      'roman lettuce'  => 'Romaine_lettuce',
      'chestnut tree'  => 'Aesculus_hippocastanum',
      'horse chestnut' => 'Aesculus_hippocastanum',
      'rocket'         => 'Arugula',
      'anemone'        => 'Anemone_nemorosa',
      'blueberry'      => 'Bilberry',
      'dibber'         => 'Knife',
    },
    8 => {
      'oak tree'          => 'Quercus_robur',
      'hawthorn'          => 'Crataegus',
      'columbine'         => 'Aquilegia_vulgaris',
      'common columbine'  => 'Aquilegia_vulgaris',
      'mushroom'          => 'Agaricus_bisporus',
      'button mushroom'   => 'Agaricus_bisporus',
      'hyacinth'          => 'Hyacinth_(plant)',
      'rake'              => 'Rake_(tool)',
      'wallflower'        => 'Erysimum',
      'fan palm tree'     => 'Chamaerops',
      'burnet'            => 'Salad_burnet',
      'basket of gold'    => 'Aurinia_saxatilis',
      'hoe'               => 'Hoe_(tool)',
      'garden hoe'        => 'Hoe_(tool)',
      'statice'           => 'Armeria_maritima',
      'thrift'            => 'Armeria_maritima',
      'fritillary'        => 'Fritillaria',
      'valerian'          => 'Valerian_(plant)',
      'spindletree'       => 'Euonymus',
      'spindle (shrub)'   => 'Euonymus',
      'bugloss'           => 'Anchusa',
      'wild mustard'      => 'Mustard_plant',
      'shepherd staff'    => "Shepherd's_crook",
    },
    9 => {
      'angelica'            => 'Garden_angelica',
      'day-lily'            => 'Daylily',
      'oat grass'           => 'Arrhenatherum',
      'martagon'            => 'Lilium_martagon',
      'martagon lily'       => 'Lilium_martagon',
      'wild thyme'          => 'Thymus_serpyllum',
      'betony'              => 'Stachys_officinalis',
      'woundwort'           => 'Stachys_officinalis',
      'carnation'           => 'Dianthus_caryophyllus',
      'elder tree'          => 'Elderberry',
      'poppy'               => 'Papaver_rhoeas',
      'poppy plant'         => 'Papaver_rhoeas',
      'lime'                => 'Tilia_cordata',
      'linden'              => 'Tilia_cordata',
      'lime tree'           => 'Tilia_cordata',
      'linden or lime tree' => 'Tilia_cordata',
      'barbel'              => 'Cornflower',
      'bedstraw'            => 'Galium_album',
      'vervain'             => 'Verbena_officinalis',
      'carriage'            => 'Handcart',
      'hand cart'           => 'Handcart',
    },
    10 => {
      'oats'            => 'Oat',
      'speedwell'       => 'Veronica_(plant)',
      'wormwookd'       => 'Artemisia_absinthium',
      'artichoke'       => 'Globe_artichoke',
      'currant'         => 'Redcurrant',
      'vetchling'       => 'Lathyrus',
      'hairy vetchling' => 'Lathyrus',
      'mint'            => 'Mentha',
      'alkanet'         => 'Alcanna_tinctoria',
      'guinea hen'      => 'Guinea_fowl',
      'sage'            => 'Common_sage',
      'sage plant'      => 'Common_sage',
      'tare'            => 'Vicia_sativa',
      'corn'            => 'Wheat',
    },
    11 => {
      'mullein'          => 'Common_mullein',
      'melon'            => 'Muskmelon',
      'ram'              => 'Sheep',
      'horsetail'        => 'Equisetum',
      'mugwort'          => 'Artemisia_vulgaris',
      'parsnip'          => 'Panicum_virgatum',
      'switchgrass'      => 'Panicum_virgatum',
      'common glasswort' => 'Glasswort',
      'ewe'              => 'Sheep',
      'marshmallow'      => 'Althaea_officinalis',
      'waterlock'        => 'Lock_(water_transport)',
      'lock'             => 'Lock_(water_transport)',
      'horseheal'        => 'Inula',
      'myrtle'           => 'Myrtus',
      'oil-seed rape'    => 'Rapeseed',
      'mill'             => 'Windmill',
    },
    12 => {
      'lycoperdon'        => 'Puffball',
      'six-row barley'    => 'Barley',
      'bere'              => 'Barley',
      'winter barley'     => 'Barley',
      'dogbane'           => 'Apocynaceae',
      'apocynum'          => 'Apocynaceae',
      'stepladder'        => 'Ladder',
      'teasel'            => 'Dipsacus',
      'marigold'          => 'Tagetes',
      'mexican marigold'  => 'Tagetes',
      'harvesting basket' => 'Basket',
      'wild rose'         => 'Rosa_canina',
      'hops'              => 'Humulus_lupulus',
      'corn'              => 'Maize',
      'maize or corn'     => 'Maize',
      'chestnut'          => 'Sweet_chestnut',
      'pack basket'       => 'Basket',
    },
    13 => {
      'labour'     => 'Manual_labour',
      'rewards'    => 'Reward_system',
      'revolution' => 'French_Revolution',
    },
  }},
);

no Moose;
__PACKAGE__->meta->make_immutable;


# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
# Idea borrowed from Jean Forget's DateTime::Calendar::FrenchRevolutionary.
"Quand le gouvernement viole les droits du peuple,
l'insurrection est pour le peuple le plus sacré
et le plus indispensable des devoirs";

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en - English localization of (part of) L<DateTime::Calendar::FrenchRevolutionary::Locale::en>

=head1 VERSION

version 0.27

=head1 DESCRIPTION

This modules copies and fixes some of the English translations of L<DateTime::Calendar::FrenchRevolutionary::Locale::en>, which bases its translation on:

=over

=item [Carlyle]

"The French Revolution: A History", Thomas Carlyle, 1837, Ed. K. J. Fielding and David Sorensen, The World’s Classics, Oxford, New York,  Oxford University Press, 1989.

=item [Taylor]

Alan Taylor's web site: L<http://www.kokogiak.com/frc/default.asp>.

=item [Ruby]

Jonathan Badger's French Revolutionary Calendar module written in Ruby

L<https://github.com/jhbadger/FrenchRevCal-ruby>.

=item [Wikipedia]

L<http://en.wikipedia.org/wiki/French_Republican_Calendar>.

=back

When L<DateTime::Calendar::FrenchRevolutionary::Locale::en> leaves some translations as doubtful, they are fixed here based on Wikipedia.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
