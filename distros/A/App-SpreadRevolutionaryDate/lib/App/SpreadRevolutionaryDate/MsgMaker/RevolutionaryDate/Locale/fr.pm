#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2025 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr;
$App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr::VERSION = '0.51';
# ABSTRACT: French localization of (part of) L<DateTime::Calendar::FrenchRevolutionary::Locale::fr>

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale';

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;


has '+months' => (
  default => sub {[
    'Vendémiaire', 'Brumaire',  'Frimaire',
    'Nivôse',      'Pluviôse',  'Ventôse',
    'Germinal',    'Floréal',   'Prairial',
    'Messidor',    'Thermidor', 'Fructidor',
    'jour complémentaire',
  ]},
);

has '+decade_days' => (
  default => sub {[
    'Primidi',
    'Duodi',
    'Tridi',
    'Quartidi',
    'Quintidi',
    'Sextidi',
    'Septidi',
    'Octidi',
    'Nonidi',
    'Décadi',
  ]},
);

has '+feast' => (
  default => sub {[
    # Vendémiaire
    qw(
      0raisin          0safran      1châtaigne  1colchique  0cheval
      1balsamine       1carotte     2amaranthe  0panais     1cuve
      1pomme_de_terre  2immortelle  0potiron    0réséda     2âne
      1belle-de-nuit   1citrouille  0sarrasin   0tournesol  0pressoir
      0chanvre         1pêche       0navet      2amarillis  0bœuf
      2aubergine       0piment      1tomate     2orge       0tonneau
    ),
    # Brumaire
    qw(
      1pomme       0céleri   1poire        1betterave  2oie
      2héliotrope  1figue    1scorsonère   2alisier    1charrue
      0salsifis    1macre    0topinambour  2endive     0dindon
      0chervis     0cresson  1dentelaire   1grenade    1herse
      1bacchante   2azerole  1garance      2orange     0faisan
      1pistache    0macjonc  0coing        0cormier    0rouleau
    ),
    # Frimaire
    qw(
      1raiponce      0turneps     1chicorée  1nèfle     0cochon
      1mâche         0chou-fleur  0miel      0genièvre  1pioche
      1cire          0raifort     0cèdre     0sapin     0chevreuil
      2ajonc         0cyprès      0lierre    1sabine    0hoyau
      2érable-sucre  1bruyère     0roseau    2oseille   0grillon
      0pignon        0liège       1truffe    2olive     1pelle
    ),
    # Nivôse
    qw(
      1tourbe           1houille         0bitume          0soufre    0chien
      1lave             1terre_végétale  0fumier          0salpêtre  0fléau
      0granit           2argile          2ardoise         0grès      0lapin
      0silex            1marne           1pierre_à_chaux  0marbre    0van
      1pierre_à_plâtre  0sel             0fer             0cuivre    0chat
      2étain            0plomb           0zinc            0mercure   0crible
    ),
    # Pluviôse
    qw(
      1lauréole      1mousse      0fragon     0perce-neige  0taureau
      0laurier-thym  2amadouvier  0mézéréon   0peuplier     1coignée
      2ellébore      0brocoli     0laurier    2avelinier    1vache
      0buis          0lichen      2if         1pulmonaire   1serpette
      0thlaspi       0thymelé     0chiendent  1traînasse    0lièvre
      1guède         0noisetier   0cyclamen   1chélidoine   0traîneau
    ),
    # Ventôse
    qw(
      0tussilage  0cornouiller  0violier     0troène      0bouc
      2asaret     2alaterne     1violette    0marceau     1bêche
      0narcisse   2orme         1fumeterre   0vélar       1chèvre
      3épinards   0doronic      0mouron      0cerfeuil    0cordeau
      1mandragore 0persil       0cochléaria  1pâquerette  0thon
      0pissenlit  1sylvie       0capillaire  0frêne       0plantoir
    ),
    # Germinal
    qw(
      1primevère  0platane  2asperge     1tulipe    1poule
      1blette     0bouleau  1jonquille   2aulne     0couvoir
      1pervenche  0charme   1morille     0hêtre     2abeille
      1laitue     0mélèze   1ciguë       0radis     1ruche
      0gainier    1romaine  0marronnier  1roquette  0pigeon
      0lilas      2anémone  1pensée      1myrtille  0greffoir
    ),
    # Floréal
    qw(
      1rose      0chêne        1fougère         2aubépine     0rossignol
      2ancolie   0muguet       0champignon      1hyacinthe    0râteau
      1rhubarbe  0sainfoin     0bâton-d'or      0chamérisier  0ver_à_soie
      1consoude  1pimprenelle  1corbeille-d'or  2arroche      0sarcloir
      0staticé   1fritillaire  1bourrache       1valériane    1carpe
      0fusain    1civette      1buglosse        0sénevé       1houlette
    ),
    # Prairial
    qw(
      1luzerne  2hémérocale  0trèfle          2angélique    0canard
      1mélisse  0fromental   0martagon        0serpolet     1faulx
      1fraise   1bétoine     0pois            2acacia       1caille
      2œillet   0sureau      0pavot           0tilleul      1fourche
      0barbeau  1camomille   0chèvre-feuille  0caille-lait  1tanche
      0jasmin   1verveine    0thym            1pivoine      0chariot
    ),
    # Messidor
    qw(
      0seigle     2avoine     2oignon     1véronique  0mulet
      0romarin    0concombre  2échalotte  2absinthe   1faucille
      1coriandre  2artichaut  1giroflée   1lavande    0chamois
      0tabac      1groseille  1gesse      1cerise     0parc
      1menthe     0cumin      3haricots   2orcanète   1pintade
      1sauge      2ail        1vesce      0blé        1chalémie
    ),
    # Thermidor
    qw(
      2épeautre  0bouillon-blanc  0melon     2ivraie    0bélier
      1prêle     2armoise         0carthame  1mûre      2arrosoir
      0panis     0salicot         2abricot   0basilic   1brebis
      1guimauve  0lin             2amande    1gentiane  2écluse
      1carline   0caprier         1lentille  2aunée     1loutre
      1myrte     0colza           0lupin     0coton     0moulin
    ),
    # Fructidor
    qw(
      1prune      0millet      0lycoperde      2escourgeon  0saumon
      1tubéreuse  0sucrion     2apocyn         1réglisse    2échelle
      1pastèque   0fenouil     2épine-vinette  1noix        1truite
      0citron     1cardère     0nerprun        0tagette     1hotte
      2églantier  1noisette    0houblon        0sorgho      2écrevisse
      1bigarade   1verge-d'or  0maïs           0marron      0panier
    ),
    # Jours complémentaires
    qw(
      1vertu       0génie  0travail  2opinion  3récompenses
      1révolution
    ),
  ]},
);

has '+prefixes' => (
  default => sub {[
    'jour du ',
    'jour de la ',
    "jour de l'",
    'jour des ',
  ]},
);

has '+suffix' => (
  default => '',
);

has '+wikipedia_entries' => (
  default => sub {{
    1 => {
      'safran'        => 'Safran_(épice)',
      'balsamine'     => 'Balsaminaceae',
      'amarante'      => 'Amarante_(plante)',
      'amaranthe'     => 'Amarante_(plante)',
      'immortelle'    => 'Immortelle_commune',
      'belle de nuit' => 'Mirabilis_jalapa',
      'belle-de-nuit' => 'Mirabilis_jalapa',
      'sarrasin'      => 'Sarrasin_(plante)',
      'pêche'         => 'Pêche_(fruit)',
      'pèche'         => 'Pêche_(fruit)',
      'amaryllis'     => 'Amaryllis_(plante)',
      'amarillis'     => 'Amaryllis_(plante)',
      'bœuf'          => 'Bos_taurus',
      'orge'          => 'Orge_commune',
      'tonneau'       => 'Tonneau_(récipient)',
    },
    2 => {
      'alisier'   => 'Sorbus_torminalis',
      'macre'     => 'Mâcre_nageante',
      'chervi'    => 'Chervis',
      'cresson'   => 'Cresson_de_fontaine',
      'grenade'   => 'Grenade_(fruit)',
      'herse'     => 'Herse_(agriculture)',
      'bacchante' => 'Baccharis_halimifolia',
      'garance'   => 'Garance_des_teinturiers',
      'orange'    => 'Orange_(fruit)',
      'macjon'    => 'Gesse_tubéreuse',
      'macjonc'   => 'Gesse_tubéreuse',
      'coin'      => 'Coing',
      'rouleau'   => 'Rouleau_agricole',
    },
    3 => {
      'raiponce'       => 'Raiponce_(plante)',
      'turneps'        => 'Betterave_fourragère',
      'choufleur'      => 'Chou-fleur',
      'genièvre'       => 'Juniperus_communis',
      'lierre'         => 'Hedera',
      'sabine'         => 'Juniperus_sabina',
      'érable-sucre'   => 'Érable_à_sucre',
      'érable-à-sucre' => 'Érable_à_sucre',
      'érable sucré'   => 'Érable_à_sucre',
      'grillon'        => 'Gryllidae',
      'pignon'         => 'Pignon_(pin)',
      'liège'          => 'Liège_(matériau)',
      'truffe'         => 'Truffe_(champignon)',
      'pelle'          => 'Pelle_(outil)',
    },
    4 => {
      'terre végétale'  => 'Humus',
      'fléau'           => 'Fléau_(agriculture)',
      'grès'            => 'Grès_(géologie)',
      'lapin'           => 'Oryctolagus_cuniculus',
      'marne'           => 'Marne_(géologie)',
      'pierre à chaux'  => 'Calcaire',
      'pierre-à-chaux'  => 'Calcaire',
      'van'             => 'Van_(agriculture)',
      'pierre à plâtre' => 'Gypse',
      'pierre-à-plâtre' => 'Gypse',
      'sel'             => 'Chlorure_de_sodium',
      'mercure'         => 'Mercure_(chimie)',
      'crible'          => 'Tamis',
    },
    5 => {
      'mousse'       => 'Bryophyta',
      'laurier-thym' => 'Viorne_tin',
      'laurier-tin'  => 'Viorne_tin',
      'laurier'      => 'Laurus_nobilis',
      'mézéréum'     => 'Mézéréon',
      'coignée'      => 'Cognée',
      'avelinier'    => 'Noisetier',
      'if'           => 'Taxus',
      'thymelé'      => 'Daphné_garou',
      'thymele'      => 'Daphné_garou',
      'traînasse'    => 'Renouée_des_oiseaux',
      'trainasse'    => 'Renouée_des_oiseaux',
      'ciclamen'     => 'Cyclamen',
      'chélidoine'   => 'Chelidonium_majus',
    },
    6 => {
      'cornouiller' => 'Cornus_(plante)',
      'violier'     => 'Vélar',
      'troêne'      => 'Troène',
      'bouc'        => 'Bouc_(animal)',
      'violette'    => 'Viola_(genre_végétal)',
      'marsault'    => 'Saule_marsault',
      'marceau'     => 'Saule_marsault',
      'narcisse'    => 'Narcissus',
      'épinards'    => 'Épinard',
      'mouron'      => 'Mouron_(flore)',
      'cochléaria'  => 'Cochlearia',
      'sylvie'      => 'Anémone_sylvie',
      'capillaire'  => 'Capillaire_de_montpellier',
    },
    7 => {
      'poule'      => 'Poule_(animal)',
      'blette'     => 'Bette_(plante)',
      'bette'      => 'Bette_(plante)',
      'couvoir'    => 'Incubateur_(œuf)',
      'morille'    => 'Morchella',
      'hêtre'      => 'Hêtre_commun',
      'ciguë'      => 'Apiaceae',
      'romaine'    => 'Laitue_romaine',
      'marronnier' => 'Marronnier_commun',
      'roquette'   => 'Roquette_(plante)',
      'lilas'      => 'Syringa_vulgaris',
      'pensée'     => 'Viola_(genre_végétal)',
      'myrtile'    => 'Myrtille',
    },
    8 => {
      'rose'           => 'Rose_(fleur)',
      'muguet'         => 'Muguet_de_mai',
      'jacinthe'       => 'Hyacinthus',
      'hyacinthe'      => 'Hyacinthus',
      'rateau'         => 'Râteau_(outil)',
      'râteau'         => 'Râteau_(outil)',
      "bâton-d'or"     => 'Erysimum',
      'chamérisier'    => 'Lonicera_xylosteum',
      'ver-à-soie'     => 'Vers_à_soie',
      "corbeille-d'or" => "Corbeille_d'or",
      'statice'        => 'Armérie_maritime',
      'staticé'        => 'Armérie_maritime',
      'carpe'          => 'Carpe_(poisson)',
      'fusain'         => "Fusain_d'Europe",
      'civette'        => 'Ciboulette_(botanique)',
      'houlette'       => 'Houlette_(agriculture)',
    },
    9 => {
      'luzerne'        => 'Luzerne_cultivée',
      'hémérocale'     => 'Hémérocalle',
      'angélique'      => 'Angelica',
      'fromental'      => 'Fromental_(plante)',
      'faux'           => 'Faux_(outil)',
      'faulx'          => 'Faux_(outil)',
      'fraise'         => 'Fraise_(fruit)',
      'acacia'         => 'Robinia_pseudoacacia',
      'barbeau'        => 'Centaurea_cyanus',
      'camomille'      => 'Camomille_romaine',
      'chèvre-feuille' => 'Chèvrefeuille',
    },
    10 => {
      'avoine'    => 'Avoine_cultivée',
      'véronique' => 'Véronique_(plante)',
      'absinthe'  => 'Absinthe_(plante)',
      'giroflée'  => 'Giroflée_des_murailles',
      'gesse'     => 'Lathyrus',
      'haricots'  => 'Haricot',
      'orcanète'  => 'Orcanette_des_teinturiers',
      'ail'       => 'Ail_cultivé',
    },
    11 => {
      'épautre'   => 'Épeautre',
      'épeautre'  => 'Épeautre',
      'melon'     => 'Melon_(plante)',
      'prèle'     => 'Sphenophyta',
      'prêle'     => 'Sphenophyta',
      'mûre'      => 'Mûre (fruit de la ronce)',
      'panic'     => 'Panic_(plante)',
      'panis'     => 'Panic_(plante)',
      'salicor'   => 'Salicorne',
      'salicorne' => 'Salicorne',
      'salicot'   => 'Salicorne',
      'basilic'   => 'Basilic_(plante)',
      'brebis'    => 'Mouton',
      'guimauve'  => 'Guimauve_officinale',
      'lin'       => 'Lin_cultivé',
      'caprier'   => 'Câprier',
      'lentille'  => 'Lentille_cultivée',
      'myrte'     => 'Myrtus',
      'myrthe'    => 'Myrtus',
      'colsa'     => 'Colza',
    },
    12 => {
      'prune'      => 'Prune_(fruit)',
      'millet'     => 'Millet_(graminée)',
      'lycoperde'  => 'Lycoperdon',
      'apocyn'     => 'Asclepias_syriaca',
      'échelle'    => 'Échelle_(outil)',
      'cardère'    => 'Cardère_sauvage',
      'hotte'      => 'Panier',
      'églantier'  => 'Rosa_canina',
      'sorgho'     => 'Sorgho_commun',
      'bagarade'   => 'Bigaradier',
      'bigarade'   => 'Bigaradier',
      "verge-d'or" => "Verge_d'or",
      'marron'     => 'Marron_(fruit)',
    },
    13 => {
      'génie'       => 'Génie_(personne)',
      'récompenses' => 'Système_de_récompense',
      'révolution'  => 'Révolution_française',
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

App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr - French localization of (part of) L<DateTime::Calendar::FrenchRevolutionary::Locale::fr>

=head1 VERSION

version 0.51

=head1 DESCRIPTION

This modules copies and fixes some of the French translations of L<DateTime::Calendar::FrenchRevolutionary::Locale::fr>.

Sources:

=over

=item [Décret]

"Annuaire ou calendrier pour la seconde année de la République française, annexe du décret du 4 frimaire, an II (24 novembre 1793) sur l'ère, le commencement et l'organisation de l'année et sur les noms des jours et des mois" ; in J. Madival and E. Laurent, et. al., eds. "Archives parlementaires de 1789 à 1860: recueil complet des débats législatifs & politiques des Chambres françaises", Librairie administrative de P. Dupont, Paris, 1862 L<https://purl.stanford.edu/dx068ky1531>.

=item [Fabre]

"Rapport fait à la Convention nationale dans la séance du 3 du second mois de la seconde année de la République française, au nom de la Commission chargée de la confection du calendrier", Philippe-François-Nazaire Fabre d'Églantine, Imprimerie nationale, Paris, 1793 L<https://gallica.bnf.fr/ark:/12148/bpt6k48746z>.

=item [Annuaire]

"Annuaire du cultivateur, pour la troisième année de la République : présenté le 30 pluviôse de l'an II à la Convention nationale, qui en a décrété l'impression et l'envoi, pour servir aux écoles de la République", Gilbert Romme, Imprimerie nationale des lois, Paris, 1794-1795 L<https://gallica.bnf.fr/ark:/12148/bpt6k49016b>.

=item [Wikipedia]

L<https://fr.wikipedia.org/wiki/Calendrier_républicain>.

=back

Sources have slight differences between them. All of them obviously include some typos. [Décret] is chosen as the reference since it is the definitive legislative text that officially defines names of days in the French revolutionary calendar. This text introduces amendments to the original calendar set up by Fabre d'Églantine in [Fabre], and gives in annex the amended calendar. When there is a difference between the amended calendar and [Fabre] with amendments (yes it can happen!), [Fabre] version prevails. Obvious typos in [Décret] (yes it can happen!) are preserved, with the exception of accented letters because they are fuzzy rendered in original prints, or cannot be printed at all at that time on letters in uppercase.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::BlueSky>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat::Bot>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Telechat>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Gemini>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
