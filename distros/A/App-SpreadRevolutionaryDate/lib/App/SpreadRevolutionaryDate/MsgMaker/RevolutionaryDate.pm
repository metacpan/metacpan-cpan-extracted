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
package App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate;
$App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::VERSION = '0.10';
# ABSTRACT: MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with revolutionary date

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker';

use namespace::autoclean;

has 'acab' => (
    is  => 'ro',
    isa => 'Bool',
    required => 1,
    default => 0,
);

has 'wikipedia_link' => (
    is  => 'ro',
    isa => 'Bool',
    required => 1,
    default => 1,
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{locale} = 'fr' unless $args{locale} && $args{locale} eq 'en';
  return $class->$orig(%args);
};

# Wikipedia ambiguous links
our %wikipedia_redirect = (
  fr => {
    1 => {
      'safran'                  => 'safran (épice)',
      'balsamine'               => 'balsaminaceae',
      'amarante'                => 'amarante (plante)',
      'amaranthe'               => 'amarante (plante)',
      'immortelle'              => 'immortelle commune',
      'belle de nuit'           => 'mirabilis jalapa',
      'belle-de-nuit'           => 'mirabilis jalapa',
      'sarrasin'                => 'sarrasin (plante)',
      'pêche'                   => 'pêche (fruit)',
      'pèche'                   => 'pêche (fruit)',
      'amaryllis'               => 'amaryllis (plante)',
      'amarillis'               => 'amaryllis (plante)',
      'bœuf'                    => 'bos taurus',
      'orge'                    => 'orge commune',
      'tonneau'                 => 'tonneau (récipient)',
    },
    2 => {
      'alisier'                 => 'sorbus torminalis',
      'macre'                   => 'mâcre nageante',
      'chervi'                  => 'chervis',
      'cresson'                 => 'cresson de fontaine',
      'grenade'                 => 'grenade (fruit)',
      'herse'                   => 'herse (agriculture)',
      'bacchante'               => 'baccharis halimifolia',
      'garance'                 => 'garance des teinturiers',
      'orange'                  => 'orange (fruit)',
      'macjon'                  => 'gesse tubéreuse',
      'macjonc'                 => 'gesse tubéreuse',
      'coin'                    => 'coing',
      'rouleau'                 => 'rouleau agricole',
    },
    3 => {
      'raiponce'                => 'raiponce (plante)',
      'turneps'                 => 'betterave fourragère',
      'choufleur'               => 'chou-fleur',
      'genièvre'                => 'juniperus communis',
      'lierre'                  => 'hedera',
      'sabine'                  => 'juniperus sabina',
      'érable-sucre'            => 'érable à sucre',
      'érable-à-sucre'          => 'érable à sucre',
      'érable sucré'            => 'érable à sucre',
      'grillon'                 => 'gryllidae',
      'pignon'                  => 'pignon (pin)',
      'liège'                   => 'liège (matériau)',
      'truffe'                  => 'truffe (champignon)',
      'pelle'                   => 'pelle (outil)',
    },
    4 => {
      'terre végétale'          => 'humus',
      'fléau'                   => 'fléau (agriculture)',
      'grès'                    => 'grès (géologie)',
      'lapin'                   => 'oryctolagus cuniculus',
      'marne'                   => 'marne (géologie)',
      'pierre à chaux'          => 'calcaire',
      'pierre-à-chaux'          => 'calcaire',
      'van'                     => 'van (agriculture)',
      'pierre à plâtre'         => 'gypse',
      'pierre-à-plâtre'         => 'gypse',
      'sel'                     => 'chlorure de sodium',
      'mercure'                 => 'mercure (chimie)',
      'crible'                  => 'tamis',
    },
    5 => {
      'mousse'                  => 'bryophyta',
      'laurier-thym'            => 'viorne tin',
      'laurier-tin'             => 'viorne tin',
      'laurier'                 => 'laurus nobilis',
      'mézéréum'                => 'mézéréon',
      'coignée'                 => 'cognée',
      'avelinier'               => 'noisetier',
      'if'                      => 'taxus',
      'thymelé'                 => 'daphné garou',
      'thymele'                 => 'daphné garou',
      'traînasse'               => 'renouée des oiseaux',
      'trainasse'               => 'renouée des oiseaux',
      'ciclamen'                => 'cyclamen',
      'chélidoine'              => 'chelidonium majus',
    },
    6 => {
      'cornouiller'             => 'cornus (plante)',
      'violier'                 => 'vélar',
      'troêne'                  => 'troène',
      'bouc'                    => 'bouc (animal)',
      'violette'                => 'viola (genre végétal)',
      'marsault'                => 'saule marsault',
      'marceau'                 => 'saule marsault',
      'narcisse'                => 'narcissus',
      'épinards'                => 'épinard',
      'mouron'                  => 'mouron (flore)',
      'cochléaria'              => 'cochlearia',
      'capillaire'              => 'capillaire de montpellier',
    },
    7 => {
      'poule'                   => 'poule (animal)',
      'blette'                  => 'bette (plante)',
      'bette'                   => 'bette (plante)',
      'couvoir'                 => 'incubateur (œuf)',
      'morille'                 => 'morchella',
      'hêtre'                   => 'hêtre commun',
      'ciguë'                   => 'apiaceae',
      'romaine'                 => 'laitue romaine',
      'marronnier'              => 'marronnier commun',
      'roquette'                => 'roquette (plante)',
      'lilas'                   => 'syringa vulgaris',
      'pensée'                  => 'viola (genre végétal)',
      'myrtile'                 => 'myrtille',
    },
    8 => {
      'rose'                    => 'rose (fleur)',
      'muguet'                  => 'muguet de mai',
      'jacinthe'                => 'hyacinthus',
      'hyacinthe'               => 'hyacinthus',
      'rateau'                  => 'râteau (outil)',
      'râteau'                  => 'râteau (outil)',
      "bâton-d'or"              => 'erysimum',
      'chamérisier'             => 'lonicera xylosteum',
      'ver-à-soie'              => 'vers à soie',
      "corbeille-d'or"    => "corbeille d'or",
      'statice'                 => 'armérie maritime',
      'staticé'                 => 'armérie maritime',
      'carpe'                   => 'carpe (poisson)',
      'fusain'            => "fusain d'Europe",
      'civette'                 => 'ciboulette (botanique)',
      'houlette'                => 'houlette (agriculture)',
    },
    9 => {
      'luzerne'                 => 'luzerne cultivée',
      'hémérocale'              => 'hémérocalle',
      'angélique'               => 'angelica',
      'fromental'               => 'fromental (plante)',
      'faux'                    => 'faux (outil)',
      'faulx'                   => 'faux (outil)',
      'fraise'                  => 'fraise (fruit)',
      'acacia'                  => 'robinia pseudoacacia',
      'barbeau'                 => 'centaurea cyanus',
      'camomille'               => 'camomille romaine',
      'chèvre-feuille'          => 'chèvrefeuille',
    },
    10 => {
      'avoine'                  => 'avoine cultivée',
      'véronique'               => 'véronique (plante)',
      'absinthe'                => 'absinthe (plante)',
      'giroflée'                => 'giroflée des murailles',
      'gesse'                   => 'lathyrus',
      'haricots'                => 'haricot',
      'orcanète'                => 'orcanette des teinturiers',
      'ail'                     => 'ail cultivé',
    },
    11 => {
      'épautre'                 => 'épeautre',
      'épeautre'                => 'épeautre',
      'melon'                   => 'melon (plante)',
      'prèle'                   => 'sphenophyta',
      'prêle'                   => 'sphenophyta',
      'mûre'                    => 'mûre (fruit de la ronce)',
      'panic'                   => 'panic (plante)',
      'panis'                   => 'panic (plante)',
      'salicor'                 => 'salicorne',
      'salicorne'               => 'salicorne',
      'salicot'                 => 'salicorne',
      'basilic'                 => 'basilic (plante)',
      'brebis'                  => 'mouton',
      'guimauve'                => 'guimauve officinale',
      'lin'                     => 'lin cultivé',
      'caprier'                 => 'câprier',
      'lentille'                => 'lentille cultivée',
      'myrte'                   => 'myrtus',
      'myrthe'                  => 'myrtus',
      'colsa'                   => 'colza',
    },
    12 => {
      'prune'                   => 'prune (fruit)',
      'millet'                  => 'millet (graminée)',
      'lycoperde'               => 'lycoperdon',
      'apocyn'                  => 'asclepias syriaca',
      'échelle'                 => 'échelle (outil)',
      'cardère'                 => 'cardère sauvage',
      'hotte'                   => 'panier',
      'églantier'               => 'rosa canina',
      'sorgho'                  => 'sorgho commun',
      'bagarade'                => 'bigaradier',
      'bigarade'                => 'bigaradier',
      "verge-d'or"        => "verge d'or",
      'marron'                  => 'marron (fruit)',
    },
    13 => {
      'révolution'              => 'révolution française',
    },
  },
  en => {
    1 => {
      'sweet_chestnut'          => 'chestnut',
      'colchic'                 => 'colchicum autumnale',
      'crocus'                  => 'colchicum autumnale',
      'balsam'                  => 'impatiens',
      'everlasting'             => 'helichrysum arenarium',
      'strawflower'             => 'helichrysum arenarium',
      'squash'                  => 'winter squash',
      'mignonette'              => 'reseda (plant)',
      "four o'clock flower"     => 'mirabilis jalapa',
      'sunflower'               => 'helianthus',
      'sunflower'               => 'helianthus',
      'wine-press'              => 'fruit press',
      'ox'                      => 'cattle',
      'barrel'                  => 'barrel#Beverage_maturing',
    },
    2 => {
      'heliotrope'              => 'heliotropium',
      'fig'                     => 'common fig',
      'black salsify'           => 'scorzonera hispanica',
      'whitebeam'               => 'sorbus torminalis',
      'chequer tree'            => 'sorbus torminalis',
      'plow'                    => 'plough',
      'salsify'                 => 'tragopogon porrifolius',
      'water chestnut'          => 'water caltrop',
      'turkey'                  => 'turkey (bird)',
      'turkey'                  => 'turkey (bird)',
      'skirret'                 => 'sium sisarum',
      'cress'                   => 'watercress',
      'plumbago'                => 'plumbaginaceae',
      'leadworts'               => 'plumbaginaceae',
      'harrow'                  => 'harrow (tool)',
      'bacchante'               => 'baccharis halimifolia',
      'baccharis'               => 'baccharis halimifolia',
      'azarole'                 => 'crataegus azarolus',
      'madder'                  => 'rubia',
      'orange'                  => 'orange (fruit)',
      'tuberous pea'            => 'lathyrus tuberosus',
      'service tree'            => 'sorbus domestica',
      'roller'                  => 'roller (agricultural tool)',
    },
    3 => {
      'rampion'                 => 'phyteuma',
      'medlar'                  => 'mespilus germanica',
      'corn_salad'              => 'valerianella locusta',
      "lamb's lettuce"          => 'valerianella locusta',
      'juniper'                 => 'juniperus communis',
      'cedar tree'              => 'cedrus',
      'fir tree'                => 'fir',
      'gorse'                   => 'ulex',
      'cypress tree'            => 'cupressus sempervirens',
      'ivy'                     => 'hedera',
      'savin juniper'           => 'juniperus sabina',
      'grub-hoe'                => 'hoe_(tool)',
      'maple tree'              => 'acer saccharum',
      'sugar maple'             => 'acer saccharum',
      'heather'                 => 'calluna',
      'reed'                    => 'phragmites',
      'reed plant'              => 'phragmites',
      'cricket'                 => 'cricket (insect)',
    },
    4 => {
      'saltpeter'               => 'potassium nitrate',
      'flail'                   => 'flail (agriculture)',
      'winnowing basket'        => 'winnowing',
      'iron'                    => 'iron (material)',
      'mercury'                 => 'mercury (element)',
    },
    5 => {
      'spurge laurel'           => 'daphne laureola',
      "butcher's broom"         => 'ruscus aculeatus',
      'laurustinus'             => 'viburnum tinus',
      'tinder polypore'         => 'fomes fomentarius',
      'mezereon'                => 'daphne mezereum',
      'poplar_tree'             => 'populus',
      'poplar'                  => 'populus',
      'laurel'                  => 'bay laurel',
      'common_hazel'            => 'corylus maxima',
      'filbert'                 => 'corylus maxima',
      'cow'                     => 'cattle',
      'box tree'                => 'box (tree)',
      'yew tree'                => 'taxus baccata',
      'penny-cress'             => 'thlaspi arvense',
      'pennycress'              => 'thlaspi arvense',
      'daphne'                  => 'daphne cneorum',
      'rose daphne'             => 'daphne cneorum',
      'common knotgrass'        => 'polygonum aviculare',
      'hazel tree'              => 'hazel',
      'celandine'               => 'greater celandine',
    },
    6 => {
      'coltsfoot'               => 'tussilago',
      'dogwood'                 => 'cornus (genus)',
      'hoary stock'             => 'matthiola',
      'billygoat'               => 'goat',
      'wild ginger'             => 'asarum',
      'mediterranean buckthorn' => 'rhamnus alaternus',
      'italian buckthorn'       => 'rhamnus alaternus',
      'violet'                  => 'viola (plant)',
      'goat willow'             => 'salix caprea',
      'narcissus'               => 'narcissus (plant)',
      'elm tree'                => 'elm',
      'fumitory'                => 'fumaria officinalis',
      'common fumitory'         => 'fumaria officinalis',
      'hedge mustard'           => 'sisymbrium officinale',
      "leopard's bane"          => 'doronicum',
      'pimpernel'               => 'anagallis',
      'line'                    => 'twine',
      'mandrake'                => 'mandragora officinarum',
      'scurvy-grass'            => 'cochlearia',
      'daisy'                   => 'bellis perennis',
      'tuna fish'               => 'tuna',
      'dandelion'               => 'taraxacum',
      'windflower'              => 'anemone nemorosa',
      'wood anemone'            => 'anemone nemorosa',
      'maidenhair fern'         => 'adiantum capillus-veneris',
      'ash tree'                => 'fraxinus',
      'dibble'                  => 'dibber',
    },
    7 => {
      'primula'                 => 'primula vulgaris',
      'primrose'                => 'primula vulgaris',
      'plan tree'               => 'planatus',
      'hen'                     => 'chicken',
      'birch tree'              => 'birch',
      'daffodil'                => 'narcissus (plant)',
      'periwinkle'              => 'vinca',
      'morel'                   => 'morchella',
      'beech tree'              => 'fagus sylvatica',
      'hemlock'                 => 'conium',
      'hive'                    => 'beehive (beekeeping)',
      'redbud'                  => 'cercis',
      'judas tree'              => 'cercis',
      'roman lettuce'           => 'romaine lettuce',
      'chestnut tree'           => 'aesculus hippocastanum',
      'horse chestnut'          => 'aesculus hippocastanum',
      'rocket'                  => 'arugula',
      'anemone'                 => 'anemone nemorosa',
      'blueberry'               => 'bilberry',
      'dibber'                  => 'knife',
    },
    8 => {
      'oak tree'                => 'quercus robur',
      'hawthorn'                => 'crataegus',
      'columbine'               => 'aquilegia_vulgaris',
      'common columbine'        => 'aquilegia_vulgaris',
      'mushroom'                => 'agaricus bisporus',
      'button mushroom'         => 'agaricus bisporus',
      'hyacinth'                => 'hyacinth (plant)',
      'rake'                    => 'rake (tool)',
      'wallflower'              => 'erysimum',
      'fan palm tree'           => 'chamaerops',
      'burnet'                  => 'salad burnet',
      'basket of gold'          => 'aurinia saxatilis',
      'hoe'                     => 'hoe (tool)',
      'garden hoe'              => 'hoe (tool)',
      'statice'                 => 'armeria maritima',
      'thrift'                  => 'armeria maritima',
      'fritillary'              => 'fritillaria',
      'valerian'                => 'valerian (plant)',
      'spindletree'             => 'euonymus',
      'spindle (shrub)'         => 'euonymus',
      'bugloss'                 => 'anchusa',
      'wild mustard'            => 'mustard plant',
      'shepherd staff'          => "Shepherd's crook",
    },
    9 => {
      'angelica'                => 'garden angelica',
      'day-lily'                => 'daylily',
      'oat grass'               => 'arrhenatherum',
      'martagon'                => 'lilium martagon',
      'martagon lily'           => 'lilium martagon',
      'wild thyme'              => 'thymus serpyllum',
      'betony'                  => 'stachys officinalis',
      'woundwort'               => 'stachys officinalis',
      'carnation'               => 'dianthus caryophyllus',
      'elder_tree'              => 'elderberry',
      'poppy'                   => 'papaver rhoeas',
      'poppy plant'             => 'papaver rhoeas',
      'lime'                    => 'tilia cordata',
      'linden'                  => 'tilia cordata',
      'lime tree'               => 'tilia cordata',
      'linden or lime tree'     => 'tilia cordata',
      'barbel'                  => 'cornflower',
      'bedstraw'                => 'galium album',
      'vervain'                 => 'verbena officinalis',
      'carriage'                => 'handcart',
      'hand cart'               => 'handcart',
    },
    10 => {
      'oats'                    => 'oat',
      'speedwell'               => 'veronica (plant)',
      'wormwookd'               => 'artemisia absinthium',
      'artichoke'               => 'globe artichoke',
      'currant'                 => 'redcurrant',
      'vetchling'               => 'lathyrus',
      'hairy vetchling'         => 'lathyrus',
      'mint'                    => 'mentha',
      'alkanet'                 => 'alcanna tinctoria',
      'guinea hen'              => 'guinea fowl',
      'sage'                    => 'common sage',
      'sage plant'              => 'common sage',
      'tare'                    => 'vicia sativa',
      'corn'                    => 'wheat',
    },
    11 => {
      'mullein'                 => 'common mullein',
      'melon'                   => 'muskmelon',
      'ram'                     => 'sheep',
      'horsetail'               => 'equisetum',
      'mugwort'                 => 'artemisia vulgaris',
      'parsnip'                 => 'panicum virgatum',
      'switchgrass'             => 'panicum virgatum',
      'common glasswort'        => 'glasswort',
      'ewe'                     => 'sheep',
      'marshmallow'             => 'althaea officinalis',
      'waterlock'               => 'lock (water transport)',
      'lock'                    => 'lock (water transport)',
      'horseheal'               => 'inula',
      'myrtle'                  => 'myrtus',
      'oil-seed rape'           => 'rapeseed',
      'mill'                    => 'windmill',
    },
    12 => {
      'lycoperdon'              => 'puffball',
      'six-row barley'          => 'barley',
      'bere'                    => 'barley',
      'winter barley'           => 'barley',
      'dogbane'                 => 'apocynaceae',
      'apocynum'                => 'apocynaceae',
      'stepladder'              => 'ladder',
      'teasel'                  => 'dipsacus',
      'marigold'                => 'tagetes',
      'mexican marigold'        => 'tagetes',
      'harvesting basket'       => 'basket',
      'wild rose'               => 'rosa canina',
      'hops'                    => 'humulus lupulus',
      'corn'                    => 'maize',
      'maize or corn'           => 'maize',
      'chestnut'                => 'sweet chestnut',
      'pack basket'             => 'basket',
    },
  },
);


sub compute {
  my $self = shift;

  # As of DateTime::Calendar::FrenchRevolutionary 0.14
  # locale is limited to 'en' or 'fr', defaults to 'fr'
  my $revolutionary = $self->acab ?
      DateTime::Calendar::FrenchRevolutionary->now->set(hour => 1, minute => 31, second => 20, locale => $self->locale)
    : DateTime::Calendar::FrenchRevolutionary->now->set(locale => $self->locale);

  my $msg;

  if ($self->wikipedia_link) {
    use URI::Escape;
    $msg = $self->locale eq 'fr' ?
        $revolutionary->strftime("Nous sommes le %A, %d %B de l'An %EY (%Y) de la Révolution, %Ej, il est %T! https://" . $self->locale . ".wikipedia.org/wiki/!!%Oj!!")
      : $revolutionary->strftime("We are %A, %d %B of Revolution Year %EY (%Y), %Ej, it is %T! https://" . $self->locale . ".wikipedia.org/wiki/!!%Oj!!");

    $msg =~ s/!!([^!]+)!!/!!$wikipedia_redirect{$self->locale}->{$revolutionary->month}->{$1}!!/
      if    exists $wikipedia_redirect{$self->locale}
         && exists $wikipedia_redirect{$self->locale}->{$revolutionary->month}
         && exists $wikipedia_redirect{$self->locale}->{$revolutionary->month}->{$revolutionary->strftime("%Oj")};

    $msg =~ s/!!([^!]+)!!/uri_escape_utf8($1)/e;
  } else {
    $msg = $self->locale eq 'fr' ?
        $revolutionary->strftime("Nous sommes le %A, %d %B de l'An %EY (%Y) de la Révolution, %Ej, il est %T!")
      : $revolutionary->strftime("We are %A, %d %B of Revolution Year %EY (%Y), %Ej, it is %T!");
  }

  return $msg
}


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

App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate - MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with revolutionary date

=head1 VERSION

version 0.10

=head1 METHODS

=head2 compute

Computes revolutionary date. Takes no argument. Returns message as string, ready to be spread.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date|https://metacpan.org/pod/distribution/App-SpreadRevolutionaryDate/bin/spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::MsgMaker>

=item L<App::SpreadRevolutionaryDate::Target::MsgMaker::PromptUser>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
