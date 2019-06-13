# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Perl DateTime extension for providing French strings for the French Revolutionary calendar
# Copyright (c) 2003, 2004, 2010, 2011, 2014, 2016, 2019 Jean Forget. All rights reserved.
#
# See the license in the embedded documentation below.
#

package DateTime::Calendar::FrenchRevolutionary::Locale::fr;

use utf8;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.15'; # same as parent module DT::C::FR

my @months_short  = qw (Vnd Bru Fri Niv Plu Vnt Ger Flo Pra Mes The Fru S-C);
#my @add_days_short= qw (Vertu Génie Trav Raison Récomp Révol);
my @months = qw(Vendémiaire Brumaire  Frimaire
                Nivôse      Pluviôse  Ventôse
                Germinal    Floréal   Prairial
                Messidor    Thermidor Fructidor);
push @months, "jour complémentaire";

my @decade_days = qw (Primidi Duodi Tridi Quartidi Quintidi Sextidi Septidi Octidi Nonidi Décadi);
my @decade_days_short = qw (Pri Duo Tri Qua Qui Sex Sep Oct Non Déc);

my @am_pms = qw(AM PM);

my $date_before_time = "1";
my $default_date_format_length = "medium";
my $default_time_format_length = "medium";
my $date_parts_order = "dmy";

my %date_formats = (
    "short"   => "\%d\/\%m\/\%Y",
    "medium"  => "\%a\ \%d\ \%b\ \%Y",
    "long"    => "\%A\ \%d\ \%B\ \%EY",
    "full"    => "\%A\ \%d\ \%B\ \%EY\,\ \%{feast_long\}",
);

my %time_formats = (
    "short"   => "\%H\:\%M",
    "medium"  => "\%H\:\%M\:\%S",
    "long"    => "\%H\:\%M\:\%S",
    "full"    => "\%H\ h\ \%M\ mn \%S\ s",
);

# When initializing an array with lists within lists, it means one of two things:
# Either it is a newbie who does not know how to make multi-dimensional arrays,
# Or it is a (at least mildly) experienced Perl-coder who, for some reason, 
# wants to initialize a flat array with the concatenation of lists.
# I am a (at least mildly) experienced programmer who wants to use qw() and yet insert
# comments in some places.
my @feast = (
# Vendémiaire
        qw(
       0raisin           0safran           1châtaigne        1colchique        0cheval
       1balsamine        1carotte          2amaranthe        0panais           1cuve
       1pomme_de_terre   2immortelle       0potiron          0réséda           2âne
       1belle-de-nuit    1citrouille       0sarrasin         0tournesol        0pressoir
       0chanvre          1pêche            0navet            2amarillis        0bœuf
       2aubergine        0piment           1tomate           2orge             0tonneau
        ),
# Brumaire
        qw(
       1pomme            0céleri           1poire            1betterave        2oie
       2héliotrope       1figue            1scorsonère       2alisier          1charrue
       0salsifis         1macre            0topinambour      2endive           0dindon
       0chervis          0cresson          1dentelaire       1grenade          1herse
       1bacchante        2azerole          1garance          2orange           0faisan
       1pistache         0macjonc          0coing            0cormier          0rouleau
        ),
# Frimaire
        qw(
       1raiponce         0turneps          1chicorée         1nèfle            0cochon
       1mâche            0chou-fleur       0miel             0genièvre         1pioche
       1cire             0raifort          0cèdre            0sapin            0chevreuil
       2ajonc            0cyprès           0lierre           1sabine           0hoyau
       2érable-sucre     1bruyère          0roseau           2oseille          0grillon
       0pignon           0liège            1truffe           2olive            1pelle
        ),
# Nivôse
        qw(
       1tourbe           1houille          0bitume           0soufre           0chien
       1lave             1terre_végétale   0fumier           0salpêtre         0fléau
       0granit           2argile           2ardoise          0grès             0lapin
       0silex            1marne            1pierre_à_chaux   0marbre           0van
       1pierre_à_plâtre  0sel              0fer              0cuivre           0chat
       2étain            0plomb            0zinc             0mercure          0crible
        ),
# Pluviôse
        qw(
       1lauréole         1mousse           0fragon           0perce-neige      0taureau
       0laurier-thym     2amadouvier       0mézéréon         0peuplier         1coignée
       2ellébore         0brocoli          0laurier          2avelinier        1vache
       0buis             0lichen           2if               1pulmonaire       1serpette
       0thlaspi          0thymelé          0chiendent        1traînasse        0lièvre
       1guède            0noisetier        0cyclamen         1chélidoine       0traîneau
        ),
# Ventôse
        qw(
       0tussilage        0cornouiller      0violier          0troène           0bouc
       2asaret           2alaterne         1violette         0marceau          1bêche
       0narcisse         2orme             1fumeterre        0vélar            1chèvre
       3épinards         0doronic          0mouron           0cerfeuil         0cordeau
       1mandragore       0persil           0cochléaria       1pâquerette       0thon
       0pissenlit        1sylvie           0capillaire       0frêne            0plantoir
        ),
# Germinal
        qw(
       1primevère        0platane          2asperge          1tulipe           1poule
       1blette           0bouleau          1jonquille        2aulne            0couvoir
       1pervenche        0charme           1morille          0hêtre            2abeille
       1laitue           0mélèze           1ciguë            0radis            1ruche
       0gainier          1romaine          0marronnier       1roquette         0pigeon
       0lilas            2anémone          1pensée           1myrtille         0greffoir
        ),
# Floréal
        qw(
       1rose             0chêne            1fougère          2aubépine         0rossignol
       2ancolie          0muguet           0champignon       1hyacinthe        0râteau
       1rhubarbe         0sainfoin         0bâton-d'or       0chamérisier      0ver_à_soie
       1consoude         1pimprenelle      1corbeille-d'or   2arroche          0sarcloir
       0staticé          1fritillaire      1bourrache        1valériane        1carpe
       0fusain           1civette          1buglosse         0sénevé           1houlette
        ),
# Prairial
        qw(
       1luzerne          2hémérocale       0trèfle           2angélique        0canard
       1mélisse          0fromental        0martagon         0serpolet         1faulx
       1fraise           1bétoine          0pois             2acacia           1caille
       2œillet           0sureau           0pavot            0tilleul          1fourche
       0barbeau          1camomille        0chèvre-feuille   0caille-lait      1tanche
       0jasmin           1verveine         0thym             1pivoine          0chariot
        ),
# Messidor
        qw(
       0seigle           2avoine           2oignon           1véronique        0mulet
       0romarin          0concombre        2échalotte        2absinthe         1faucille
       1coriandre        2artichaut        1giroflée         1lavande          0chamois
       0tabac            1groseille        1gesse            1cerise           0parc
       1menthe           0cumin            3haricots         2orcanète         1pintade
       1sauge            2ail              1vesce            0blé              1chalémie
        ),
# Thermidor
        qw(
       2épeautre         0bouillon-blanc   0melon            2ivraie           0bélier
       1prêle            2armoise          0carthame         1mûre             2arrosoir
       0panis            0salicor          2abricot          0basilic          1brebis
       1guimauve         0lin              2amande           1gentiane         2écluse
       1carline          0caprier          1lentille         2aunée            1loutre
       1myrte            0colza            0lupin            0coton            0moulin
        ),
# Fructidor
        qw(
       1prune            0millet           0lycoperde        2escourgeon       0saumon
       1tubéreuse        0sucrion          2apocyn           1réglisse         2échelle
       1pastèque         0fenouil          2épine-vinette    1noix             1truite
       0citron           1cardère          0nerprun          0tagette          1hotte
       2églantier        1noisette         0houblon          0sorgho           2écrevisse
       1bigarade         1verge-d'or       0maïs             0marron           0panier
        ),
# Jours complémentaires
        qw(
       1vertu            0génie            0travail          2opinion          3récompenses
       1révolution
         ));
my @prefix = ('jour du ', 'jour de la ', "jour de l'", 'jour des ');

my %event = ();

sub new {
  return bless {},  $_[0];
}

sub month_name {
    my ($self, $date) = @_;
    return $months[$date->month_0]
}

sub month_abbreviation {
    my ($self, $date) = @_;
    return $months_short[$date->month_0]
}

sub day_name {
    my ($self, $date) = @_;
    return $decade_days[$date->day_of_decade_0];
}

sub day_abbreviation {
    my ($self, $date) = @_;
    return $decade_days_short[$date->day_of_decade_0];
}

sub am_pm                    { $_[0]->am_pms->             [ $_[1]->hour < 5 ? 0 : 1 ] }

sub _raw_feast {
  my ($self, $date) = @_;
  $feast[$date->day_of_year_0];
}

sub feast_short {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0];
  $lb =~ s/_/ /g;
  return substr($lb, 1);
}

sub feast_long {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0];
  $lb =~ s/_/ /g;
  $lb =~ s/^(\d)/$prefix[$1]/;
  return $lb;
}

sub feast_caps {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0];
  $lb =~ s/_/ /g;
  $lb =~ s/^(\d)(.)/\u$prefix[$1]\u$2/;
  return $lb;
}

sub    full_date_format      { $_[0]->date_formats->{full} }
sub    long_date_format      { $_[0]->date_formats->{long} }
sub  medium_date_format      { $_[0]->date_formats->{medium} }
sub   short_date_format      { $_[0]->date_formats->{short} }
sub default_date_format      { $_[0]->date_formats->{ $_[0]->default_date_format_length } }

sub    full_time_format      { $_[0]->time_formats->{full} }
sub    long_time_format      { $_[0]->time_formats->{long} }
sub  medium_time_format      { $_[0]->time_formats->{medium} }
sub   short_time_format      { $_[0]->time_formats->{short} }
sub default_time_format      { $_[0]->time_formats->{ $_[0]->default_time_format_length } }

sub _datetime_format_pattern_order { $_[0]->date_before_time ? (0, 1) : (1, 0) }

sub    full_datetime_format { join ' ', ( $_[0]->full_date_format,    $_[0]->full_time_format    )[ $_[0]->_datetime_format_pattern_order ] }
sub    long_datetime_format { join ' ', ( $_[0]->long_date_format,    $_[0]->long_time_format    )[ $_[0]->_datetime_format_pattern_order ] }
sub  medium_datetime_format { join ' ', ( $_[0]->medium_date_format,  $_[0]->medium_time_format  )[ $_[0]->_datetime_format_pattern_order ] }
sub   short_datetime_format { join ' ', ( $_[0]->short_date_format,   $_[0]->short_time_format   )[ $_[0]->_datetime_format_pattern_order ] }
sub default_datetime_format { join ' ', ( $_[0]->default_date_format, $_[0]->default_time_format )[ $_[0]->_datetime_format_pattern_order ] }

sub default_date_format_length { $default_date_format_length }
sub default_time_format_length { $default_time_format_length }

sub month_names                { [ @months ] }
sub month_abbreviations        { [ @months_short ] }
sub day_names                  { [ @decade_days ] }
sub day_abbreviations          { [ @decade_days_short ] }
sub am_pms                     { [ @am_pms ] }
sub date_formats               { \%date_formats         }
sub time_formats               { \%time_formats         }
sub date_before_time           { $date_before_time      }
sub date_parts_order           { $date_parts_order      }

sub on_date {
  my ($self, $date) = @_;
  _load_events() unless %event;
  $event{$date->strftime('%m%d')} || "";
}

sub _load_events {
  %event = ('dummy', split /(\d{4})\n/, <<'EVENTS');
0101
1 Vendémiaire I Entrée des troupes françaises en Savoie.

1 Vendémiaire III Les postes du bois d'Aix-la-Chapelle et de Reckem sont enlevés 
par l'Armée du Nord.

0102
2 Vendémiaire I Conquête de Chambéry.

2 Vendémiaire III Prise de la redoute et du camp de Costouge par l'Armée des
Pyrénées orientales.

2 Vendémiaire V L'Armée d'Italie met en déroute l'ennemi à Governolo.

0103
3 Vendémiaire IV Affaire de Garesio.

0104
4 Vendémiaire II L'Armée des Alpes enlève de vive force les retranchements
de Chatillon ; les Piémontais sont mis en déroute et repassent la rivière de Giffe.

0105
5 Vendémiaire III Armée des Pyrénées orientales. Défaite des
Espagnols à Olia et Monteilla.

0106
6 Vendémiaire III Capitulation de Crevecœur devant l'Armée du Nord.

6 Vendémiaire III Armée du Rhin. Reprise de Kayserlautern et d'Alsborn.

6 Vendémiaire V Armée de Sambre et Meuse. L'ennemi attaque sur les
points de Wurstatt, Nider-Ulm, Ober et Nider-Ingelheim et est repoussé.

6 Vendémiaire XII Naissance de Prosper Mérimée, écrivain français.

0107
7 Vendémiaire I Prise de la ville de Nice et de la forteresse de Montalban.

7 Vendémiaire II L'Armée des Alpes défait l'ennemi dans les gorges
de Sallanges et prend la redoute de Saint-Martin.

0108
8 Vendémiaire V Armée d'Italie. 150 hommes font une sortie de Mantoue pour
se procurer du fourrage et doivent se rendre aux habitants de Reggio.

0109
9 Vendémiaire I Les Français se rendent maîtres de la ville de Spire.

9 Vendémiaire II L'Armée des Alpes enlève de vive-force les
retranchements de Mont-Cormet tenus par les Piémontais.

0111
11 Vendémiaire II Armée des Alpes. Capture du poste de Valmeyer, du
poste de Beaufort, de Moutiers, du bourg Saint-Maurice et du Col de la
Madeleine.

11 Vendémiaire III Armée de Sambre-et-Meuse. Bataille d'Aldenhoven
et déroute des troupes coalisées.

11 Vendémiaire V L'Armée du Rhin et Moselle attaque sur toute la
ligne et met l'ennemi en déroute.

0112
12 Vendémiaire II Les Espagnols sont forcés dans leurs camps du Boulon 
et Argelès par l'Armée des Pyrénées orientales.

12 Vendémiaire III Le pays de Juliers se rend à l'Armée de Sambre-et-Meuse.

0113
13 Vendémiaire I Les Autrichiens sont forcés d'évacuer la ville de Worms.

13 Vendémiaire II Armée des Pyrénées orientales. Prise de Campredon et
déroute de la cavalerie espagnole par la garnison de Colioure.

13 Vendémiaire II L'Armée des Pyrénées occidentales attaque les postes d'Arau
et de la vallée d'Aure et les enlève.

13 Vendémiaire IV Bonaparte réprime une manifestation royaliste à l'église Saint-Roch.

0115
15 Vendémiaire III Cologne se rend à l'Armée de Sambre-et-Meuse.

0116
16 Vendémiaire V L'ennemi, bloqué à Mantoue par l'Armée d'Italie tente
une sortie de 4 600 hommes, sortie qui se solde par un échec.

0117
17 Vendémiaire I Les Autrichiens lèvent le siège de Lille.

17 Vendémiaire III Combat et prise de Frankenthal par l'Armée du Rhin.

0118
18 Vendémiaire II Bombardement de Lyon.

18 Vendémiaire III Prise de Shelaudenbach et de Vollfstein par l'Armée du Rhin
et jonction avec l'Armée de la Moselle à Lautreck.

0119
19 Vendémiaire III Devant Maestricht, l'Armée de Sambre-et-Meuse reprend
le château de Mont-Saint-Pierre.

0120
20 Vendémiaire III L'Armée de la Moselle marche sur Birkenfeldt, Oberstein,
Kirn et Meisenheim.

0121
21 Vendémiaire III Entrée de l'Armée du Nord dans Bois-le-Duc.

0122
22 Vendémiaire I Kellerman force les Prussiens à évacuer la ville de Verdun.

0123
23 Vendémiaire III L'Armée du Rhin prend Otterberg, Rockenhausen, 
Landsberg, Alzein et Oberhausen.

0124
24 Vendémiaire II L'Armée de la Moselle combat et provoque la retraite
précipitée des coalisés qui s'étaient portés sur Bitche et Rorbach.

24 Vendémiaire III Combat et prise de Gellheim et de Grunstad par 
l'Armée du Rhin ; les Français reprennent aussi Frankenthal.

0125
25 Vendémiaire II Combat près de Sarreguemines ; l'Armée de la Moselle
repousse l'ennemi.

25 Vendémiaire II Exécution de Marie-Antoinette.

0126
26 Vendémiaire I Les Autrichiens attaquent plusieurs fois inutilement Hasnon
et sont repoussés avec perte.

26 Vendémiaire II La bataille de Wattignies près de Maubeuge est remportée
par l'Armée du Nord sur les Autrichiens et le blocus de Maubeuge est levé.

26 Vendémiaire III L'Armée des Pyrénées occidentales prend la 
mâture d'Iraty et les fonderies d'Egay et d'Orbaycette.

26 Vendémiaire III Armée de la Moselle. Prise de Creutznach et de Worms.

26 Vendémiaire VI Armée d'Italie. Traité de paix définitif à Campo-Formio
près d'Udine entre le général Bonaparte et les plénipotentiaires de l'Empereur,
roi de Hongrie et de Bohême.

26 Vendémiaire VI Congrès à Rastadt pour la conclusion de la paix entre
la République française et l'Empire germanique.

0127
27 Vendémiaire II 600 républicains de l'Armée d'Italie remportent
l'avantage à Gillette sur 4 000 Autrichiens, Croates et Piémontais et les
repoussent.

27 Vendémiaire III L'Armée des Pyrénées occidentales défait 7 000 
Espagnols près de Buruet et d'Almandos.

27 Vendémiaire III L'Armée du Rhin met en déroute l'ennemi près
de Kircheim et de Worms et prend ces deux villes.

0128
28 Vendémiaire II L'Armée d'Italie remporte
une victoire complète à Gilette sur les Piémontais.

28 Vendémiaire III L'Armée du Nord défait l'ennemi près de Nimègue
et détruit la légion de Rohan.

28 Vendémiaire V L'Armée du Rhin et Moselle est attaquée à Retzengen
et à Simonswald.

0129
29 Vendémiaire I L'Armée française force les Autrichiens à évacuer Mayence.

29 Vendémiaire III L'Armée de la Moselle entre dans Bingen
après avoir chassé les Prussiens des positions qu'ils tenaient en avant
de la ville.

29 Vendémiaire V Armée d'Italie. Débarquement en Corse, prise
de Bastia, de Saint-Florent et de Bonifacio.

29 Vendémiaire XIV Bataille de Trafalgar.

0130
30 Vendémiaire II L'Armée des Pyrénées occidentales met
en déroute trois colonnes espagnoles après une fusillade de cinq heures.

30 Vendémiaire V Armée de Sambre et Meuse. L'ennemi passe le Rhin sur
six points depuis Bacharach jusqu'à Andernach, attaque la tête de pont
de Neuwied et est forcé à la retraite.

0201
1 Brumaire I Reprise de la ville de Longwi, les Prussiens évacuent le
territoire français.

1 Brumaire II Armée des Pyrénées orientales. Avantage sur les
espagnols dans la vallée de Baigory.

1 Brumaire II Armée du Nord. Enlèvement des postes de Warneton,
Comines, Werwick, Ronek, Alluin, Menin, Furnes et Poperingues.

1 Brumaire II Armée du Rhin. Prise d'Alzey et d'Oppenheim.

0202
2 Brumaire II Armée d'Italie. Défaite à Utel de cinq mille ennemis.

2 Brumaire II Armée du Rhin. Attaque du poste de Breitenstein par les
Autrichiens ; l'ennemi repoussé.

2 Brumaire III Armée de Sambre et Meuse. Prise de Coblentz.

2 Brumaire III Armée des Pyrénées orientales. Combat à Bhaga, 
les Espagnols sont repoussés.

2 Brumaire III Armée des Pyrénées orientales. Enlèvement
des postes de Dori et Tozas et des retranchements de Casteillan.

0203
3 Brumaire V Traité de paix conclu entre la République française et le
roi de Naples et des deux Siciles.

0204
4 Brumaire IV Début du Directoire.

4 Brumaire VI Armée d'Italie. Traité d'alliance entre la République
française et le roi de Sardaigne.

0205
5 Brumaire III Armée du Nord. Prise de Hultz, Axel et Sas-de-Gand.

5 Brumaire V Armée de Sambre et Meuse. Attaque et prise de Saint
Wendel, Kayserslautern, Kirchenpoland, Bingen et de la montagne de
Saint-Roch.

5 Brumaire V Armée du Rhin et Moselle. Passage du Rhin par les
Français, prise du fort de Khel.

0207
7 Brumaire V Armée d'Italie. Sortie ennemie de Mantoue repoussée.

0208
8 Brumaire III Armée du Nord. Prise de Venlo.

0209
9 Brumaire II Armée des Pyrénées orientales. Reprise à la baïonnette
d'une batterie ennemie en avant de Ville longue.

0211
11 Brumaire III Armée des Pyrénées orientales. Déroute des Espagnols
sur les revers de la montagne Noire.

0212
12 Brumaire I Les Autrichiens sont forcés d'évacuer Lanoy.

12 Brumaire III Armée de la Moselle. Entrée des Français dans
Rheinfels, évacué par douze cents ennemis.

12 Brumaire V Armée d'Italie. Prise du village de Saint-Michel ; les
ponts sur l'Adige brûlés par les Français. L'ennemi se porte sur le
Lavis, où il est battu et repoussé jusque dans le village de
Segonzano.

0214
14 Brumaire V Armée de Sambre et Meuse. Prise de Maestricht.

0215
15 Brumaire V Armée d'Italie. L'ennemi ayant passé la Brenta est
obligé de la repasser après un combat meurtrier.

0216
16 Brumaire I Bataille de Gemmapes. Les Français entrent dans Mons.

16 Brumaire III Armée du Nord. Prise du fort de Schenk.

0217
17 Brumaire III Armée du Nord. La sortie de la garnison de
Berg-op-zoom est repoussée.

0218
18 Brumaire I Prise de la ville de Tournay par les Français.

18 Brumaire III Armée du Nord. Entrée triomphante des Français dans
Nimègue.

18 Brumaire VIII Coup d'état de Bonaparte : fin du Directoire, début du Consulat.

0219
19 Brumaire IV Armée du Nord. Prise de Burick.

0220
20 Brumaire IV Armée de Sambre et Meuse. Combat près de Creutzenach,
dans lequel l'ennemi a été forcé de repasser la Nahe.

0221
21 Brumaire V Armée d'Italie. L'armée française, sur l'Adige,
rencontre l'ennemi entre Saint-Michel et Saint-Martin, le culbute et
le poursuit l'espace de trois milles.

0222
22 Brumaire I Armée du Nord. La ville de Gand ouvre ses portes à l'armée française.

22 Brumaire I Prise de Charleroy par les Français.

22 Brumaire III Armée du Rhin. Prise de Monbach et de tous les postes
de la forêt en avant de ce village.

22 Brumaire III Armée du Rhin. Prise de Weissenau.

0223
23 Brumaire I Bataille d'Anderlecht près Bruxelles. Défaite
complète de l'ennemi, l'armée française fait son entrée triomphante
dans Bruxelles.

0224
24 Brumaire I Prise de la ville de Francfort.

24 Brumaire II Armée de l'Ouest. Défaite des rebelles de la Vendée
sous les murs de Granville.

0225
25 Brumaire V Armée d'Italie. Bataille d'Arcole, conclue le 27.

0226
26 Brumaire I Les Français se rendent maîtres de la ville et du port
d'Ostende, évacué par les Autrichiens.

26 Brumaire I Prise de Saint-Remi.

26 Brumaire I Capitulation de la ville de Malines.

26 Brumaire II Armée du Rhin. L'armée surprend et enlève près de
Strasbourg trois postes ennemis vaillamment défendus.

26 Brumaire II Le siège de la ville de Granville est levé.

26 Brumaire IV Combat du champ di Pietri.

0227
27 Brumaire II Armée de la Moselle. Défaite autrichienne
devant Bitche. Déroute des Autrichiens près Lébach. Prise
de Bising et de Blise-Castel.

27 Brumaire III Armée des Pyrénées orientales. Dugommier général en
chef, tué à St. Sébastien de la Mouga.

27 Brumaire III Armée des Pyrénées orientales. Bataille gagnée sur
les Espagnols à Saint-Sébastien.

0228
28 Brumaire I Prise des villes d'Ypres, Furnes et Bruges. Entrée des
Français dans la ville d'Anvers.

28 Brumaire II Armée du Rhin. Enlèvement de vive force du poste de
Neuviller, et de quatre autres environnants. Prise d'une forte
redoute et de sept pièces de canons près de Wantzenau.

28 Brumaire V
Traité de paix conclu entre la République française et le duc de
Parme.

0229
29 Brumaire II L'Armée du Rhin enlève deux redoutes formidables près
de Bouxweiller.

29 Brumaire VIII Naissance de René Caillé, le premier européen à entrer à Tombouctou.

0230
30 Brumaire II Armée des Pyrénées orientales. Bataille gagnée à Escola,
Liers, Vilartoly, sur cinquante mille Espagnols.

30 Brumaire II Armée de la Moselle. Défaite de douze cents hommes
d'infanterie, et de trois cents de cavalerie auprès de Blascheidt, et
de Lorentsweiller.

0301
1 Frimaire I Armée des Ardennes. Prise de la ville de Namur par les Français.

1 Frimaire III Armée de la Moselle. Défaite de plus de quatre cents
ennemis dans la forêt de Grunnevald, près Luxembourg.

1 Frimaire V Armée d'Italie. L'ennemi est attaqué et repoussé de
position en position ; de Castel-Novo à Rivoli, la Corona, et le long
de l'Adige jusqu'à Dolce.

0302
2 Frimaire I Armée du Rhin. Cinq mille Français mettent en déroute
toute l'armée ennemie devant Tirlemont.

2 Frimaire II Armée du Rhin. Combats successifs et enlèvement des
postes de Bouxweiller, Brumpt et Haguenau par les Français ; déroute
de l'ennemi.

2 Frimaire IV Armée d'Italie. Bataille de Loano, déroute des
Austro-Sardes ; prise de la Pietra, Loano, Finale, Vado et Savonne.

2 Frimaire V Armée du Rhin et Moselle. Sortie par la garnison de Kehl.

0303
3 Frimaire IV Armée d'Italie. Combat d'Intrapa et de Garesio.

3 Frimaire V Sortie faite par la garnison de Mantoue, qui est
brusquement repoussée.

0304
4 Frimaire II Armée d'Italie. Défaite de huit cents Piémontais par
cinq cents Français, à Castel-Genest et à Brec, prise de Figaretto.

4 Frimaire III Armée des Pyrénées occidentales. Victoire remportée à
Ostés, après un combat de deux jours.

0306
6 Frimaire IV Armée d'Italie. Combat de Spinardo.

0307
7 Frimaire I Armée du Rhin. Prise de la ville de Liège, précédée
d'une victoire complète remportée sur les Autrichiens, après un combat
de dix heures.

7 Frimaire III Armée des Pyrénées orientales. Prise de la forteresse
de Figuières.

0308
8 Frimaire III Armée des Pyrénées orientales. Bataille gagnée sur les
Espagnols à Begara, Ascuatia et Aspetia.

0310
10 Frimaire I Armée du Nord. Capitulation de la citadelle d'Anvers.

10 Frimaire II Armée du Nord. Attaque des postes ennemis sur la Lys.

10 Frimaire IV Armée de Sambre et Meuse. Attaque et prise de Creutzenach.

0311
11 Frimaire I Armée des Ardennes. Capitulation de la citadelle de Namur.

11 Frimaire II Armée du Rhin. Enlèvement de la redoute du pont de
Landgraben et des retranchements de Gambsheim.

11 Frimaire III Armée du Rhin et Moselle. Enlèvement de la redoute,
dite de Merlin, devant Mayence.

11 Frimaire V L'ennemi attaque la tête du pont d'Huningue et s'empare
de la demi-lune mais en est délogé.

11 Frimaire XIII Napoléon Premier est couronné Empereur des Français.

11 Frimaire XIV Bataille d'Austerlitz : l'armée française écrase l'armée austro-russe.

0312
12 Frimaire II Armée des Ardennes. Vigoureuse sortie de la garnison
de Givet.

12 Frimaire II Armée du Rhin. Combat près du bois de Gambshein.

12 Frimaire VIII Bataille d'Hohenlinden.

0314
14 Frimaire II Armée du Rhin. L'ennemi, chassé du village
d'Oppendorff, est poursuivi jusqu'à Druzenheim.

14 Frimaire III Armée de la Moselle. Les républicains enlèvent de
vive force les redoutes de Salbach.

0319
19 Frimaire II Armée du Rhin. Prise des hauteurs de Dawendorff, après
une action très vive.

0320
20 Frimaire XII Naissance d'Hector Berlioz, musicien français.

0321
21 Frimaire I Armée du Nord. Prise des villes de Wezem et de Wert et
de Ruremonde, capitale de la Gueldre autrichienne.

0322
22 Frimaire II Armée de l'Ouest. Victoire remportée sur les rebelles
de la Vendée, près et dans la ville du Mans.

0323
23 Frimaire II Armée des Pyrénées occidentales. Déroute des Espagnols
près de Saint-Jean-de-Luz ; ils sont forcés de repasser la Bidassoa.

0324
24 Frimaire I Après plusieurs combats, les troupes françaises se
rendent maîtres des villes de Mertzicq, de Fredembourg et de
Saarbruck.

0325
25 Frimaire II Armée de la Moselle. Enlèvement de vive force des
hauteurs de Marsal du Dahnbruck et de Lambach.

25 Frimaire II Armée d'Italie. Les Républicains enlèvent de vive
force les retranchements et redoutes qui défendaient Toulon.

0326
26 Frimaire I Prise de Consarbruck.

26 Frimaire II Armée d'Italie. Prise de Toulon, fuite précipitée des
Anglais et des Espagnols.

26 Frimaire IV Armée de Sambre et Meuse. Combat sur toute la ligne
dans le Hundstruck ; l'ennemi est battu sur tous les points.

0327
27 Frimaire II Armée des Ardennes. Combat près de Philippeville,
dans le bois de Jamaïque, entre une partie de la garnison de Givet et
les Autrichiens ; l'ennemi est repoussé avec perte.

0329
29 Frimaire II Armée des Pyrénées orientales. Enlèvement à la
baïonnette par deux mille cinq cents Français, des hauteurs près
Villelongue.

0402
2 Nivôse II Armée du Rhin et Moselle. Défaite de l'ennemi à Werd.

0403
3 Nivôse II Armée du Rhin et Moselle. Enlèvement de tous les
retranchements de Bischweiller, Druzenheim et Haguenau.

0405
5 Nivôse II Armée du Rhin et Moselle. Déroute de l'ennemi à
Oberséebach. Prise du château de Geisberg.

0406
Armée du Rhin et Moselle. Evacuation forcée des lignes de la Lauter
et de Weissembourg, et levée du blocus de Landau par l'ennemi.

0407
7 Nivôse II Armée du Rhin. Les Français enlèvent les postes de
Germersheim et Spire.

0408
8 Nivôse III Armée du Nord. Passage du Vaal, prise de Bommel, du fort
Saint-André et de quatre postes environnants, reddition de Grave.

0413
13 Nivôse I Armée du Nord. Un détachement de l'avant-garde française
pénètre dans le pays de Luxembourg, et s'empare des caisses de
l'Empereur, dans lesquelles se trouvent deux cent mille francs
espèces.

0414
14 Nivôse II Armée de l'Ouest. Prise sur les rebelles de la Vendée de
l'île de Noirmoutiers.

0417
17 Nivôse II Armée du Rhin et Moselle. Prise de Worms.

17 Nivôse III Armée des Pyrénées occidentales. Prise du fort de la
Trinité.

0420
20 Nivôse VI Armée d'Italie. Deux colonnes de troupes françaises
marchent sur la ville de Rome pour venger la mort du général Duphot,
et l'insulte faite à l'ambassadeur de la République française ; à leur
approche, l'insurrection éclate dans l'Ombrie ; ses habitants secouent
le joug du gouvernement papal et se déclarent libres et indépendants.

0422
22 Nivôse III Armée du Nord. Prise de Thiel et de six forts.

0423
23 Nivôse II Armée des Pyrénées occidentales. Enlèvement de vive
force du poste de la Montagne de Louis XIV par quatre cents
républicains.

23 Nivôse V Armée d'Italie. Combat de Saint-Michel devant Véronne.

23 Nivôse V Armée d'Italie. L'ennemi attaque la tête de la ligne de
Montebaldo et est repoussé.

0424
24 Nivôse III Armée du Nord. Prise d'Heusdin.

0425
25 Nivôse V Armée d'Italie. Bataille de Rivoli, l'ennemi en déroute
complète.

0426
26 Nivôse V Armée d'Italie. Dix mille ennemis forcent le passage
d'Anghiari.

26 Nivôse V Armée d'Italie. Le général Provera à la tête de six mille
hommes, attaque le faubourg Saint-Georges de Mantoue pendant toute la
journée, mais inutilement.

0427
27 Nivôse II Armée du Rhin et Moselle. Les ennemis font une sortie du
fort Vauban et sont repoussés.

27 Nivôse V Bataille de la Favorite (faubourg de Mantoue), Wurmser
échoue dans sa sortie de Mantoue et Provera est obligé de capituler.

0428
28 Nivôse III Armée du Nord. Prise d'Utrecht, d'Amersford et des
lignes du Greb, passage de la Lech.

0429
29 Nivôse II Armée du Rhin. Evacuation totale du département du
Bas-Rhin par les coalisés ; reprise du fort Vauban.

29 Nivôse III Armée du Nord. Prise de Gertuydemberg.

0430
30 Nivôse VI Naissance d'Auguste Comte, philosophe français.

0502
2 Pluviôse I Exécution de Louis XVI.

2 Pluviôse II Armée des Pyrénées occidentales. Deux cents Français
enlèvent à la baïonette la redoute d'Harriette près Ispeguy.

2 Pluviôse III Armée du Nord. Les villes de Gorcum, Dordrecht et
d'Amsterdam se rendent aux Français.

0504
4 Pluviôse II Armée du Var. A l'approche des troupes Françaises, les
Anglais abandonnent les îles d'Hyères.

0507
7 Pluviôse V Armée d'Italie. L'ennemi, chassé au-delà de la Brenta,
est atteint à Carpenedelo, et est forcé à la retraite.

0508
8 Pluviôse V Armée d'Italie. L'ennemi poursuivi dans les gorges du
Tyrol est atteint à Avio.

0509
9 Pluviôse V Armée d'Italie. Le général Murat débarque à Torgole et chasse les ennemis ; 
le général Vial les tourne et leur fait quatre cent cinquante
prisonniers. Entrée des Français dans Roveredo et Trente.

9 Pluviôse VI Armée d'Italie. Prise de la ville d'Ancône, par l'armée
française.

0510
10 Pluviôse V Armée du Rhin et Moselle. A trois heures du matin, les
Républicains sur deux colonnes, font une sortie de la tête de pont
d'Huningue et chassent l'ennemi des deux premières parallèles.

0513
13 Pluviôse I La république française déclare la guerre au roi
d'Angleterre et au stathouder de Hollande.

13 Pluviôse VI Armée d'Italie. Une des colonnes de l'armée d'Italie,
première division, traverse le territoire Génévois et établit son
quartier général à Ferney-Voltaire.

0514
14 Pluviôse V Armée d'Italie. Les Français attaquent les débris de
l'armée autrichienne derrière le Lavis et les repoussent jusqu'à
Saint-Michel.
Entrée des Français à Jmola, Faenza et Forli.
Capitulation de Mantoue.

0515
15 Pluviôse III Armée des Pyrénées occidentales. Prise de Roses,
après 27 jours de siège.

Armée du Nord. Conquête de la Hollande : toutes les places fortes et
les vaisseaux de guerre restent au pouvoir des Français. Entrée des
troupes françaises à Midelbourg et à Flesingue.

0517
17 Pluviôse III Armée des Pyrénées occidentales. Déroute complète
des Espagnols à Sare et Berra.
Déroute de quinze mille Espagnols battus à Urrugne et à Chauvin-Dragon
par cinq mille républicains.

0518
18 Pluviôse V Armée d'Italie. Les avant-postes de l'ennemi repoussés
sur la droite de l'Adige ; prise de Derunbano.

0520
20 Pluviôse IV Naissance de Barthélémy Prosper Enfantin, membre du mouvement saint-simonien.

0521
21 Pluviôse V Armée d'Italie. Prise d'Ancône.

21 Pluviôse VI Armée d'Italie. Les troupes françaises continuent leur
marche sur Rome.

0522
22 Pluviôse V Armée d'Italie. Prise de Lorette.

0527
27 Pluviôse VI Armée d'Italie. Entrée des Français dans Rome ; le
général Berthier se rend au capitole, où, au nom de la République
française, il proclame la République romaine.

0601
1 Ventôse II Armée du Rhin. Les Français enlèvent de vive force le
poste d'Ogersheim.

1 Ventôse V Armée d'Italie. Traité de paix avec le pape, conclu à
Tolentino.

0604
4 Ventôse V Armée d'Italie. Reprise du poste de Treviso.

0605
5 Ventôse V Armée d'Italie. Affaire de Foi : l'ennemi est chassé de
ses retranchements ; les Français tombent ensuite sur un corps de
chasseurs Tyroliens et les défont.

Les Français, attaqués à Bidole, battent complètement l'ennemi.
Kellerman passe la Piave à San-Mamma, et met en fuite des hussards ennemis.

0607
7 Ventôse X. Naissance de Victor Hugo.

0611
11 Ventôse III Armée des Pyrénées orientales. Prise de Bezalu.

0612
12 Ventôse V Armée d'Italie. Les Français attaquent l'ennemi à Monte
di-Savaro et le défont.

0615
15 Ventôse VI Armée en Helvétie. Capitulation de la ville de Berne.

0616
16 Ventôse II Armée des Ardennes. Combat près Soumoy et Cerffontaine ; 
défaite de l'ennemi.

0617
17 Ventôse I Déclaration de guerre au roi d'Espagne.

0618
18 Ventôse II Armée de la Moselle. Défaite de trois bataillons
autrichiens sur les hauteurs des forges de Jœgerthal.

0620
20 Ventôse V Armée d'Italie. Une division de l'armée française se
rend à Feltre ; à son approche l'ennemi évacue la ligne de Cordevole
et se porte sur Bellurn.

0622
22 Ventôse V Armée d'Italie. Passage de la Piave vis-à-vis le
village de Vidor, l'ennemi évacue son camp de la Gampana.

0623
23 Ventôse V Armée d'Italie. Combat de Sacile.
Affaire de Bellurn, dans laquelle l'arrière-garde ennemie est
enveloppée et faite prisonnière.

23 Ventôse VI Après cinq combats successifs et meurtriers, les Suisses
évacuent Morat.

0626
26 Ventôse V Armée d'Italie. Passage du Tagliamento, malgré des
forces supérieures et une résistance opiniâtre.
Prise du village de Gradisca.

0627
27 Ventôse VI Traité d'alliance et de commerce entre les Républiques
française et cisalpine.

0628
28 Ventôse V Armée d'Italie. Prise de Palma Nova, que l'ennemi est
forcé d'évacuer.

0629
29 Ventôse V Armée d'Italie. Prise de la ville de Gradisca. Passage
du pont de Casasola.

29 Ventôse XII Exécution du duc d'Enghien.

0630
30 Ventôse V Armée d'Italie. Combat de Lavis. Les troupes ennemies,
après un combat opiniâtre, sont enveloppées par les Français.

0701
1 Germinal V Armée d'Italie. Entrée des Français dans Goritz.
Affaire de Caminia, entre l'avant-garde française et l'arrière-garde
ennemie.

0702
2 Germinal IV Armée d'Italie. Combat de Tramin et Combat de
Caporetto.

0703
3 Germinal V Armée d'Italie. Combat de Clausen. L'ennemi battu à
Botzen, s'enferme dans Clausen, où il est attaqué par les Français
puis est obligé de céder.

0704
4 Germinal V Armée des Pyrénées orientales. Entrée des Français à
Trieste. Les Français s'emparent des célèbres mines d'Ydria.

0705
5 Germinal II Armée de la Moselle. Avantage remporté sur les
Prussiens, qui attaquent les avant-postes d'Apach au nord de Sierck.

5 Germinal V Armée d'Italie. Combat de Tarvis ; après une opiniâtre
résistance, l'ennemi est mis en déroute.

0706
6 Germinal V Armée d'Italie. Affaire de la Chinse ; prise de ce poste
important.

0707
7 Germinal V Naissance d'Alfred de Vigny, poête français.

0708
8 Germinal V Armée d'Italie. Des bataillons ennemis, fraîchement
arrivés du Rhin, entreprennent de défendre la gorge d'Innsbruck ; ils
sont culbutés par la 85e demi-brigade.

0709
9 Germinal V Armée d'Italie. Les Français entrent dans la ville de
Clagenfurth, capitale de la haute et basse Carinthie ; le prince
Charles avec les débris de son armée, extrêmement découragée, fuit
devant eux.

0712
12 Germinal V Armée d'Italie. Combat des gorges de Neumarck ;
l'arrière garde ennemie est culbutée par l'avant-garde française et
les Français entrent dans Neumarck et Freissels.

0714
14 Germinal II Armée des Pyrénées occidentales. Les Français enlèvent
de vive force les retranchements d'Ozoné, près Saint-Jean de Luz, et
mettent en fuite les Espagnols.

14 Germinal V Armée d'Italie. Les Autrichiens, vaincus sur tous les
points, évacuent le Tyrol. Le prince Charles fait sa retraite à marche
forcée sur la route de Vienne ; il est battu par la division Massena.

0715
15 Germinal V Armée d'Italie. Combat de Hundsmarck ; l'arrière-garde ennemie est
défaite par l'avant-garde française. Entrée des Français dans
Hundsmark, Kintenfeld, Mureau et Judembourg.

0716
16 Germinal IV Armée d'Italie. Reconnaissance militaire vers Cairo ;
les postes ennemis sont culbutés.

0717
17 Germinal II Armée des Pyrénées occidentales. Défaite des Espagnols
près d'Hendaye.

Armée d'Italie. Prise du camp de Fougasse.

17 Germinal II Exécution de Georges Danton, Camille Desmoulins et Fabre d'Églantine.

0718
18 Germinal II Armée d'Italie. Enlèvement de tous les postes aux
environs de Breglio, dans le comté de Nice.

18 Germinal V Suspension d'armes de cinq jours, entre les armées
française en Italie, et impériale.

0719
19 Germinal II Armée d'Italie. Prise d'Oneille.

0720
20 Germinal IV Armée d'Italie. Affaire de Voltry.

0721
21 Germinal II Armée des Pyrénées orientales. Défaite des Espagnols à
Monteilla ; prise d'Urgel.

Armée des Ardennes. Avantage signalé remporté par un faible
détachement sorti de Philippeville, qui chasse l'ennemi du bois situé
entre Villiers et Florence, et le met en déroute.

21 Germinal IV Armée d'Italie. Attaque de la redoute de Montelezimo,
défendue par les Français ; l'ennemi est repoussé.

0722
22 Germinal VI Armée de Mayence. Blocus du fort d'Ehreinbrestein.

0723
23 Germinal IV Armée d'Italie. Bataille de Montenotte ; déroute
complète des ennemis.

0725
25 Germinal III Traité de paix entre la République française et le roi
de Prusse.

25 Germinal IV Armée d'Italie. Prise de Cossaria.

0726
26 Germinal II Armée de la Moselle. Combat sur les hauteurs de
Tiperdange, entre une compagnie du 1er bataillon du Haut Rhin et
quatre-vingt chasseurs républicains, contre soixante hussards de
Wurmser et quatre cents paysans armés.

26 Germinal IV Armée d'Italie. Bataille de Millesimo, gagnée sur les
Austro-Sardes. Combat de Dego, déroute de l'ennemi. Combat et prise
de Saint-Jean, dans la vallée de la Barmida. Prise de Batisolo, de
Bagnosco et de Pontenocetto. Prise des redoutes de Montezemo.

26 Germinal V Naissance d'Adolphe Thiers, écrivain et homme politique français.

0727
27 Germinal II Armée de la Moselle. Les Français occupent les
hauteurs de Mertzig, après en avoir chassé l'ennemi.

Armée d'Italie. Défaite de quinze cents Autrichiens à Ponte-di-Nava.

27 Germinal IV Armée d'Italie. Prise du camp retranché de la ville de
Cera.

0728
28 Germinal II Armée d'Italie. Prise d'Ormea.

0729
29 Germinal II Armée de la Moselle. Bataille d'Arlon ; prise de cette
ville, déroute complète de l'ennemi.

0802
2 Floréal I Armée des Pyrénées occidentales. Affaire de Jugazza
Mondi, dans laquelle les troupes républicaines ont mis dans une
déroute complète un corps d'Espagnols.

0803
3 Floréal II Armée des Ardennes. Déroute complète de l'ennemi à
Aussoy, près Philippeville, après un combat de douze heures.

3 Floréal IV Armée d'Italie. Combat et prise de la ville de Mondovi.

0804
4 Floréal II Armée du Rhin. Victoire remportée auprès de Kurweiller.

0805
5 Floréal I Armée des Pyrénées orientales. Affaire de Samouragaldi,
dans laquelle deux cents Français ont battu complètement quatre cents
Espagnols.

Bombardement de Fontarabie.

5 Floréal II Armée des Alpes. Enlèvement de vive force de toutes
les redoutes des Monts Valaisan et Saint-Bernard et du poste de la
Thuile.

5 Floréal IV Armée d'Italie. Entrée des Français dans la ville de
Bêne.

0806
6 Floréal IV Armée d'Italie. Prise de Fossano, de Cherasco, d'Alba.

0807
7 Floréal II Armée des Pyrénées occidentales. Déroute des Espagnols
et des émigrés, repoussé des postes d'Arnéguy et d'Irameaca.

Armée des Ardennes. Victoire remportée, après quatre heures d'une
résistance opiniâtre. Enlèvement de vive force, des hauteurs de Bossu ; 
entrée et réunion des armées des Ardennes et du Nord dans la ville
de Beaumont.

Armée du Nord. Prise de Courtray, après une bataille générale sur
toute la ligne, depuis Dunkerque jusqu'à Givet.

Armée des Pyrénées orientales. Les Français enlèvent de vive force le
poste du rocher d'Arrola.

Déroute de quatre mille hommes d'infanterie et de dix escadrons de
cavalerie espagnole à Roqueluche ; perte considérable de l'ennemi.

7 Floréal VI Naissance d'Eugène Delacroix, peintre français.

0808
8 Floréal II Armée des Pyrénées orientales. Les Français, au nombre
de trois mille, chassent dix mille ennemis du village d'Oms ; ils
enlèvent les gorges et le pont du Ceret.

0809
9 Floréal IV Armée d'Italie. Armistice conclu avec le roi de Sardaigne.

0810
10 Floréal II Armée du Nord. Victoire à Mont-Castel sur vingt mille
Autrichiens.

Prise de Menin et d'une grande quantité d'artillerie.
Armée d'Italie. Victoire sur les Piémontais.

10 Floréal IV Entrée des Français dans la cité de Ceva et de Coni.

10 Floréal V Traité de paix entre la République française et le pape.

0811
11 Floréal II Armée des Pyrénées orientales. Bataille gagnée sur les
Espagnols, aux Albères ; enlèvement de la fameuse redoute de
Montesquiou.

11 Floréal V Armée d'Italie. Préliminaires de paix entre la
République française et l'Empereur, signés à Leoben par le général
Buonaparte et les plénipotentiaires de l'Empereur.

0812
12 Floréal II Armée du Rhin. Prise de Lambsheim et de Franckental par
les Français ; les portes de cette dernière ville sont enfoncées à
coups de canons.

0815
15 Floréal II Armée des Pyrénées orientales. Les Français occupent
les hauteurs du cap de Bearn et du pays de Las-Daines, où six mille
hommes arrivent à travers les plus nombreux obstacles ; commencement
du siége de Collioure.

15 Floréal III Armée des Pyrénées orientales. Les Espagnols attaquant
le camp de Cistella, sont complètement battus et repoussés.

0816
16 Floréal IV Armée d'Italie. Entrée des Français dans la ville de
Tortonne.

0817
17 Floréal III Armée des Pyrénées orientales. Reconnoissance générale
faite par les Français sur les hauteurs de Crespia, de Bascara et sur
la Fluvia.

0818
18 Floréal IV Armée d'Italie. Reconnoissance faite sur la rive du Pô,
vers Plaisance.

0819
19 Floréal II Lavoisier est guillotiné.

19 Floréal IV Armée d'Italie. Passage du Pô par l'avant-garde
républicaine, et combat de Fombio.

0820
20 Floréal II Armée des Alpes. Prise du fort Mirabouck, après
quatorze heures d'attaque, et du poste de Villeneuve-des-Prats.
Prise de la redoute de Maupertuis.

20 Floréal III Armée des Pyrénées orientales. Attaque du camp de la
montagne de Musquirachu ; l'ennemi mis en fuite, abandonne son camp
tout tendu et tous les effets de campement ; cent quarante ennemis
tués, cinquante faits prisonniers.

20 Floréal IV Armée d'Italie. Les Autrichiens attaquent près de
Cordogno la division Laharpe, et sont vigoureusement repoussés par les
Républicains, qui s'emparent de Casale.
Conclusion de l'armistice avec le duc de Parme.

0821
21 Floréal II Armée des Ardennes. Prise de Thuin par les Français,
après un combat opiniâtre : enlèvement à la baïonnette de tous les
retranchements Autrichiens.

21 Floréal IV Armée d'Italie. Bataille de Lody : passage du pont
défendu par l'armée entière de Beaulieu.

0822
22 Floréal II Armée du Nord. Défaite des ennemis devant Tournay.
Combat de sept heures devant Courtray : déroute complète de
l'ennemi. Déroute de l'ennemi à Ingelsmunster.

22 Floréal IV Armée d'Italie. Buonaparte, général en chef. Prise de
Pizzighitone. Entrée des Français dans Crémone.

0823
23 Floréal II Armée des Ardennes. Les Français enlèvent tous les
ouvrages du camp de Merbes, d'où l'ennemi est forcé de se retirer.
Au passage de la Sambre, les grenadiers du 49e régiment s'élancent à
l'eau pour soutenir les tirailleurs, et mettent en déroute la légion
de Bourbon.

Le 68e régiment soutient seul sur un pont l'attaque des Autrichiens
supérieurs en nombre, quoiqu'en butte à l'artillerie, et conserve son
poste.

0824
24 Floréal II Armée des Ardennes. Combat opiniâtre : prise et reprise
trois fois du village de Grandreng près Beaumont.

0825
25 Floréal II Armée des Alpes. Les républicains enlèvent de vive
force les redoutes de Riveto, de la Ramasse, et autres postes sur le
Mont-Cénis.

0826
26 Floréal IV Armée d'Italie. Conclusion de la paix avec le roi de Sardaigne.

0827
27 Floréal II Armée des Pyrénées orientales. Sortie de la garnison de
Collioure : trois mille Espagnols repoussés avec perte. Le général en
chef blessé dans cette action.

0828
28 Floréal IV Armée d'Italie. Les Français occupent Milan, Pavie et
Come.

28 Floréal XII « Le gouvernement de la République Française est confié à un empereur. »

0829
29 Floréal II Armée du Nord. Défaite de l'ennemi à Moescroen.
Bataille gagnée sur les coalisés, entre Menin et Courtray.

Armée des Ardennes. Glorieuse résistance de quinze cents Français qui
s'opposent à la marche de quatorze mille Autrichiens vers Cunfoz.
Cent cinquante jeunes gens de la première réquisition qui tiennent en
échec toute la droite de l'armée de Beaulieu devant Bouillon.

Armée des Pyrénées occidentales. Enlèvement de six magasins
ennemis. Rupture des écluses de la grande mâture royale : prise d'une
grande quantité de bestiaux.

Déroute des Espagnols, repoussés à la baïonnette jusqu'à leur camp de
Berra.

0830
30 Floréal II Armée des Pyrénées orientales. Déroute des Espagnols
près de Figuières.

Armée des Ardennes. Belle défense de cent soixante Français renfermés
et attaqués par de nombreux ennemis dans le château de Bouillon.

30 Floréal VI Bombardement d'Ostende par les Anglais, et débarquement
de quatre mille d'entre eux ; les Français les enveloppent, font deux
mille prisonniers, et forcent le reste à se rembarquer précipitemment
avec perte de cent hommes tués. Le général anglais est lui-même
grièvement blessé.

0901
1 Prairial II Armée des Ardennes. Défaite de l'ennemi à Lobbes et
Erquelinne, après un combat de six heures.

1 Prairial IV Armée d'Italie. Conclusion d'une armistice avec le duc
de Modène.

1 Prairial VII Naissance d'Honoré de Balzac, écrivain français.

0904
4 Prairial II Armée du Rhin. Bataille de Schifferstadt, gagnée par
quinze mille républicains contre quarante mille autrichiens. Un
général autrichien tué.

Armée de la Moselle. Déroute complète de l'avant-garde de Beaulieu.

0905
5 Prairial II Armée des Ardennes. Victoire à Merbes-le-Château après
une charge générale.

0906
6 Prairial II Armée de la Moselle. Le poste de Saint-Hubert défendu
par deux mille autrichiens est enlevé par les Français ; fuite de
l'ennemi.

6 Prairial IV Armée d'Italie. Huit cents habitans révoltés, attaqués
à Bagnasco, sont mis en déroute ; cent des leurs tués, et leur village
brûlé.

6 Prairial VI Armée d'Italie. Réunion de la république de Genève à la
république française.

Les troupes françaises attaquent les insurgés du Haut-Valais.

0907
7 Prairial II Armée de la Moselle. Prise des redoutes et de la ville
de Dinan.

Armée des Pyrénées orientales. Evacuation par l'ennemi des forts
Saint-Elme et Port-Vendre, reprise de Collioure.

7 Prairial III Dix mille hommes d'infanterie, et douze cents de
cavalerie, espagnole attaquent une reconnaissance faite par les
troupes du camp des hauteurs de Pontos ; mais ils sont mis en déroute.

7 Prairial IV Armée d'Italie. Révolte de Pavie.

7 Prairial V Exécution de Gracchus Babeuf.

0908
8 Prairial III Traité de paix et d'alliance, conclu à la Haye, entre
la République française et les membres des états-généraux de Hollande.

0911
11 Prairial IV Armée d'Italie. Défaite de cinq mille Autrichiens à
Borghetto ; passage du Mincio par les grenadiers ; prise du village de
Valeggio.

0912
12 Prairial II Armée de la Moselle. Attaque des avant-postes du camp
de S. Gérard par les Français ; les coalisés sont chassés de la
majeure partie de leurs avant-postes.

12 Prairial IV Armée de Sambre et Meuse. A minuit les républicains
s'emparent des avant-postes, situés en avant de Nider-Diebach, et
dans le jour forcent l'ennemi d'abandonner la gorge de Mannebach.

0913
13 Prairial II Armée de la Moselle. Prise de la ville de Dinan par
les troupes républicaines.

13 Prairial IV Armée d'Italie. Prise de la forteresse de Peschiera.

Armée de Sambre et Meuse. Prise des retranchements de la Sieg et de la
Acher.

0914
14 Prairial II Armée des Ardennes. Déroute des ennemis, près du bois
de Sainte-Marie.

14 Prairial IV Naissance de Sadi Carnot, homme politique français.

0915
15 Prairial II Armée des Pyrénées occidentales. Bataille gagnée sur
plusieurs points ; les républicains enlèvent à la baïonnette, le camp
Ispeguy et les redoutes des Aldudes et de Berdaritz.

Armée des Pyrénées orientales. Prise de Thouzen et Riben, sur les
Espagnols, forcés à la retraite.

15 Prairial IV Armée de Sambre et Meuse. Bataille d'Altenkirchen ;
l'ennemi mis en déroute.

Armée d'Italie. Entrée des Français dans Véronne.

0916
16 Prairial IV Armée d'Italie. Six cents grenadiers Français enlèvent
à la baïonnette le faubourg S. Georges, et la tête du pont de Mantoue.

Prise du faubourg de Cherial, de ses retranchements, et de la tour ;
l'ennemi est forcé de se retirer dans Mantoue.

0917
17 Prairial II Armée des Alpes. Prise du fameux poste des barricades ; 
communication rétablie entre l'armée des Alpes et celle d'Italie.

17 Prairial IV Armée d'Italie. Une colonne française, dirigée sur le
lac de Conio, enlève et détruit le fort de Fuentes.

Armée de Sambre et Meuse. Prise de Dierdoff, et de Montabaur.

0918
18 Prairial IV Armée de Sambre et Meuse. Prise de Weilbourg.

0919
19 Prairial II Armée des Pyrénées orientales. Défaite de quatre mille
Espagnols par un petit nombre de Français, au-delà de la Jonquière ;
investissement de Bellegarde.

Les Français se rendent maîtres de Campredon et de différents postes.

0920
20 Prairial IV Armée du Rhin et Moselle. L'ennemi évacue
Kayserslautern, Tripstadt, Neustadt et Spire.

0923
23 Prairial II Armée des Alpes. Déroute de quinze cents Piémontais,
par deux cents Français, dans la vallée d'Aoste.

Armée des Pyrénées orientales. Les Français se rendent maîtres de
Ripoll, et détruisent ses forges.

23 Prairial VI Armée de l'Orient. Prise de l'île de Malte.

0924
24 Prairial II Armée de la Moselle. Passage de la Sambre, par l'armée
de la Moselle ; investissement de Charleroy.

Armée de la Moselle, des Ardennes, et du Nord réunies. Action
vigoureuse sur plusieurs colonnes qui repoussent tous les
avant-postes de Charleroy, et se portent victorieuses jusqu'au dessus
de Gosselies.

24 Prairial III Armée de Sambre et Meuse. Prise de Luxembourg.

0925
25 Prairial VIII Bataille de Marengo en Italie. Le général Kléber est assassiné au Caire le même jour.

0926
26 Prairial II Armée de la Moselle, des Ardennes, et du Nord réunies.
Les Français enlèvent et détruisent sous le feu du canon ennemi, une
redoute près Charleroy, après avoir vigoureusement repoussé la
garnison.

En moins de dix minutes, les Français enlèvent devant Charleroy, la
redoute placée à côté de la chaussée de Bruxelles ; le premier
bataillon du Bas-Rhin repousse vigoureusement une sortie de la
garnison de Charleroy.

26 Prairial III Armée des Pyrénées orientales. Bataille de la Fluvia ; 
déroute de vingt-huit mille Espagnols.

26 Prairial IV Armée de Sambre et Meuse. Six compagnies de grenadiers
s'emparent de Nassau.

Armée du Rhin et Moselle. Les retranchements des Autrichiens entre
Franckental et le Rehut, sont forcés par les Français.

0927
27 Prairial IV Armée de Sambre et Meuse. Combat près de Wetzlar ; les
ennemis sont forcés de repasser la Dyle.

0928
28 Prairial II Armée de la Moselle, des Ardennes, et du Nord.
Victoire remportée sur les coalisés auprès de Trassignies.

0929
29 Prairial IV Armée du Nord. Prise d'Ypres.

0930
30 Prairial II Armée des Alpes. Défaite des Piémontais, au petit
St. Bernard.

1001
1 Messidor II Armée des Pyrénées orientales. Reprise de Campredon,
après un combat opiniâtre.

1 Messidor IV Armée d'Italie. Entrée des Français dans Reggio et
Bologne.

Reddition du fort Urbain, et de trois cents hommes de garnison.

Ferrare et son château sont occupés par les Français.

1002
2 Messidor II Armée des Pyrénées orientales. Prise des postes de
l'Étoile et de Bezalu.

1003
3 Messidor IV Armée d'Italie. Les Français attaquent les avant-postes
de Beaulieu, et les mettent en déroute.

1005
5 Messidor II Armée des Pyrénées occidentales. Bataille de la Croix
des bouquets, et enlèvement des postes du Rocher et Dos d'Asne.

Armée d'Italie. Conclusion de l'armistice avec le Pape.

1006
6 Messidor IV Armée de Rhin et Moselle. Passage du Rhin près
Strasbourg ; prise du fort de Kell.

1007
7 Messidor II Armée du Nord, des Ardennes, et de la Moselle. Prise de
Charleroy.

7 Messidor IV Armée de Rhin et Moselle. Prise de Wilstett.

1008
8 Messidor II Armée du Nord, des Ardennes, et de la Moselle. Victoire
mémorable de Fleurus, remportée après dix-huit heures de combat, par
soixante-dix mille républicains, contre cent mille hommes des armées
coalisées. Première utilisation de la reconnaissance aérienne par le 
capitaine Coutelle, à bord du ballon L'Entreprenant.

Armée des Pyrénées orientales. Prise de Relver, et déroute complète
des Espagnols.

Armée de Sambre et Meuse. Avantage considérable remporté sur
l'ennemi, aux portes de Lernes, Marchiennes, Monceau et Souvret.

8 Messidor III Armée des Alpes et d'Italie. Défaite d'un corps
nombreux de Piémontais, venus pour s'emparer d'Ormea.

8 Messidor IV Armée de Rhin et Moselle. Prise d'Offembourg.

1009
9 Messidor IV Armée de Rhin et Moselle. L'ennemi est repoussé
d'Appenwhir.

L'ennemi est repoussé d'Urtassen.

Armée d'Italie. Entrée des Français dans Livourne.

1010
10 Messidor III Armée des Pyrénées occidentales. Prise du camp
retranché de Deva.

10 Messidor IV Armée de Rhin et Moselle. Bataille de Renchen.

1011
11 Messidor IV Armée d'Italie. Capitulation du château de Milan.

1012
12 Messidor XII Naissance de George Sand, écrivain français.

1013
13 Messidor II Armée de Sambre et Meuse. Enlèvement des redoutes et
du camp de Roxule, des postes du Mont-Palisel et du bois d'Harvé.

Prise de Mons.

Armée du Nord. Prise de la ville d'Ostende et de son port.

1014
Armée du Nord. Entrée des Français dans Tournay.

Armée du Rhin. Les retranchements ennemis et plusieurs de leurs
avant-postes sont forcés et pris par les Français.

Armée des Pyrénées occidentales. Les Républicains enlèvent toutes les
positions ennemies jusqu'à Lecumbery, et le forcent de se retirer
jusqu'à Yrursum.

Armée de Rhin et Moselle. Attaque de la montagne de Knubis ; prise
d'une redoute placée au sommet.

Armée de Sambre et Meuse. Passage du Rhin près de Neuwied ; prise de
plusieurs redoutes armées.

14 Messidor VI
Armée d'Egypte. L'armée française effectue son débarquement à
Alexandrie, défait les Mamelucks, et soumet les villes d'Alexandrie,
de Rosette et du Caire.

1015
15 Messidor II Armée d'Italie. Déroute de quatre mille Piémontais par
la garnison de Louano, qui les chasse de Pietra.

1016
16 Messidor IV Armée de Sambre et Meuse. Combat près Willerdorff.

Armée de Rhin et Moselle. Combat d'Oss ; attaque et prise de Baden et
de Freudenstatt.

1017
17 Messidor II Armée du Nord. Prise d'Oudenarde et de Gand.

17 Messidor IV Armée du Rhin et Moselle. Bataille de Rastadt ; perte
énorme de l'ennemi sur le champ de bataille ; il est chassé de
Kupenheim, et contraint de repasser la Murg.

Armée d'Italie. Enlèvement à la baïonette des retranchements
autrichiens, entre la tête du lac de Garde et l'Adige, et de la
position de Ballone.

1018
18 Messidor II Armée de Sambre et Meuse. Défaite de trente mille
ennemis à Vaterlo, par l'avant-garde française, composée de quatorze
mille hommes.

18 Messidor III Armée des Pyrénées occidentales. Combat d'Yrursum ;
l'infanterie française charge et défait la cavalerie espagnole.

18 Messidor IV Armée d'Italie. Plusieurs milliers de paysans révoltés
sont attaqués au village de Lugo par un bataillon Français et mis en
déroute.

1019
19 Messidor II Armée de Sambre et Meuse. Victoire remportée sur les
coalisés à Sombref.

19 Messidor IV Combat devant Limbourg ; l'ennemi est poursuivi jusques
dans la ville.

1020
20 Messidor II Armée de Sambre et Meuse. Combat très vif à
Chapelle-Saint-Lambert ; déroute de l'ennemi.

20 Messidor V Armée d'Italie. Par suite des conquêtes de l'armée
d'Italie, le général Buonaparte se rend à Milan, et proclame la
République cisalpine.

1021
21 Messidor IV Armée de Sambre et Meuse. Passage de la Lahn ; marche
de l'armée sur Francfort et Mayence.

Armée du Rhin et Moselle. Combat en avant de Rastadt et dans la gorge
en avant de Guersbach ; l'ennemi est forcé de se retirer derrière
Dourlach.

Armée de Sambre et Meuse. Combat en avant de Butzbach, d'Obermel et
de Camberg ; prise de Friedberg.

1022
22 Messidor II Armée de Sambre et Meuse. Entrée victorieuse de
l'armée dans Bruxelles.

Armée des Pyrénées occidentales. Les Français enlèvent de vive force
le camp des émigrés près Berdaritz.

22 Messidor IV Armée de Rhin et Moselle. L'ennemi est chassé
d'Ettlingen, Durlach et Carlsruh.

1024
24 Messidor III Armée des Pyrénées occidentales. Prise du camp
retranché de Deybar.

1025
25 Messidor I Jean-Paul Marat est assassiné dans son bain par Charlotte Corday.

25 Messidor II Armée du Rhin. Bataille gagnée sur toute la ligne ;
prise de quinze canons et des postes de Freibach, Freimersheim, et des
montagnes de Platzberg et de Sankolp.

25 Messidor III Armée des Pyrénées occidentales. Prise de Durango.

1026
26 Messidor II Armée du Rhin. Prise des gorges d'Hoehspire, et entrée
des Français dans Spire et Neustadt.

Armée d'Italie. Prise de Verttaute par les Français.

Armée de la Moselle. Prise à la baïonnette des redoutes et du poste
de Tripstadt.

Armée de Rhin et Moselle. Prise des postes d'Haslach et de Haussen.

1027
27 Messidor II Armée de Sambre et Meuse. Le poste de la Montagne de
Fer, près de Louvain, est enlevé de vive force par les Français, qui se
rendent maîtres de la ville de Louvain, malgré la vigoureuse
résistance de l'ennemi.

Armée du Nord. Prise de la ville de Malines.

1028
28 Messidor II Armée de Sambre et Meuse. Prise de Namur.

Armée d'Italie. Quatre mille cinq cents Autrichiens de la garnison de
Mantoue, font une sortie, et sont repoussés jusqu'aux palissades.

Armée de Sambre et Meuse. Prise de Francfort.

1029
29 Messidor I Charlotte Corday, qui a assassiné Jean-Paul Marat, est exécutée.

29 Messidor II Armée du Rhin. Prise de Kayserlauter.

Armée de Sambre et Meuse. Reddition de Landrécies, après six jours de
tranchée.

29 Messidor III L'ennemi, forcé dans toutes ses positions, abandonne
la Biscaye et se retire derrière l'Ebre ; prise des Salines de
Mictorie et de Bilbao.

29 Messidor IV Attaque et prise du poste d'Alpersbach.

Attaque et déroute de tous les postes ennemis, entre le Necker et la
Kinche.

Prise de Rheinfelden, Seckingen et de tout le Friekthal.

Reconnaissance militaire faite par les Français sur la route
d'Aschaffenbourg.

1030
30 Messidor II Armée du Nord. Prise de Nieuport, après cinq jours de
tranchée.

30 Messidor IV Armée d'Italie. Attaque du camp retranché des
Autrichiens sous Mantoue ; ils sont repoussés sous les murs de la
place ; pendant ce temps, les Français mettent le feu en cinq endroits
de la ville, et ouvrent la tranchée à cinquante toises des ouvrages
avancés.

Armée de Rhin et Moselle. Entrée des Français dans Stutgard ; combat
opiniâtre à Echingen ; les Français restent maîtres de toute la rive
gauche de Necker.

1101
1 Thermidor II Armée de Sambre et Meuse. Défaite de l'ennemi sur les
hauteurs en arrière de Tirlemont.

1103
3 Thermidor II Armée de Sambre et Meuse. Déroute de l'ennemi à Hui :
prise de Saint-Tros.

3 Thermidor III Victoire de Hoche à Quiberon contre les royalistes.

1104
4 Thermidor III Traité de paix conclu entre la République française et
le roi d'Espagne.

4 Thermidor IV Armée de Sambre et Meuse. Prise de Schwinfurt.

1105
5 Thermidor X Naissance d'Alexandre Dumas père, écrivain français.

1106
6 Thermidor II Armée des Pyrénées orientales. Entrée des républicains
dans la vallée de Bastan, bombardement de Fontarabie.

6 Thermidor IV Armée de Sambre et Meuse. Capitulation de la ville et
citadelle de Wurtsbourg.

1108
8 Thermidor II Armée d'Italie. Prise de vive force, par les Français,
du village de Roccavion.

8 Thermidor IV Armée de Sambre et Meuse. Capitulation du fort de
Koenigstein.

1109
9 Thermidor I Armée de Sambre et Meuse. Entrée des Français dans Liège.

9 Thermidor II La chute de Robespierre.

1110
10 Thermidor II Armée du Nord. Prise de Cassandria et passage du
Cacysche.

10 Thermidor II Robespierre et plusieurs de ses partisans (Couthon, Saint-Just, etc) sont guillotinés.

1111
11 Thermidor III Armée des Alpes et d'Italie. Enlèvement des redoutes
du champ di Pietri.

11 Thermidor IV Armée de Sambre et Meuse. Sortie de la garnison de
Mayence : l'ennemi est vigoureusement repoussé.

1112
12 Thermidor II Armée des Pyrénées occidentales. Conquête de la
vallée de Bastan. Prise du fort de Figuier, de Fontarabie.

1113
13 Thermidor IV Armée d'Italie. Défaite des Autrichiens à Solo.
L'ennemi est battu à Lonado.

1114
Armée d'Italie. Reprise de Brescia.

14 Thermidor VII Naissance de Sophie Rostopchine, future comtesse de Ségur.

1115
15 Thermidor IV Armée de Sambre et Meuse. prise de Koenigshoffen.

1116
16 Thermidor II Armée des Pyrénées occidentales. Les Français se
rendent maîtres du poste important d'Ernani, de la ville de
Saint-Sébastien, de sa citadelle et du port du passage.

16 Thermidor IV Armée du Rhin et Moselle. Prise du poste de
Heidenheim.

Armée d'Italie. Défaite complète des Autrichiens ; reprise de Solo,
Lonado et Castiglione.

1117
17 Thermidor IV Armée d'Italie. Prise de Saint-Ozeto. Un bataillon
français marche sur Gavardo et culbute les ennemis. Défaite d'une
colonne ennemie à Gavardo.

Armée de Sambre et Meuse. Prise de Bamberg.

1118
18 Thermidor IV Armée d'Italie. L'armée de Wurmser, postée entre le
village de Solférino, et la Chiesa, est mise en déroute.

1119
19 Thermidor IV L'ennemi retranché derrière le Mincio, entre Peschiera
et Mantoue, est attaqué, mis en déroute, et lève le siège de
Peschiera.

Armée de Sambre et Meuse. Combat d'Altendorff.

1120
20 Thermidor IV Armée d'Italie. Les Français reprennent leurs
anciennes positions, passent le Mincio et pénètrent à Vérone.

1121
21 Thermidor II Armée de la Moselle. Enlèvement des retranchements et
hauteurs de Pelingen. Les Français enlèvent de vive force le pont de
Vasserbilich.

Armée du Rhin et Moselle. L'ennemi évacue Neresheim.

Armée de Sambre et Meuse. Combat sur la Rednitz ; prise de Forscheim.

1122
22 Thermidor II Armée de la Moselle. Entrée des Français dans Trèves.

Armée des Pyrénées occidentales. Prise de Toloza.

1123
23 Thermidor IV Armée d'Italie. Les Français reprennent leurs
positions devant Mantoue.

1124
24 Thermidor IV Armée d'Italie. Les Français attaquent l'ennemi à la
Corona, et à Montebaldo ; ils s'emparent de ces postes et de Préabolo.

Armée du Rhin et Moselle. Bataille de Heidenheim, après dix-sept
heures de combat ; l'ennemi fait sa retraite derrière la Vernitz.

Armée de Sambre et Meuse. Prise du fort de Rhotemberg.

Armée du Rhin et Moselle. Entrée des Français dans Brégentz.

1125
25 Thermidor IV Armée d'Italie. L'ennemi est forcé à la
Roque-Danfonce et à Lodron. Une autre colonne de Français passe
l'Adige, pousse l'ennemi sur Roveredo, et fait quelques centaines de
prisonniers.

1126
26 Thermidor II Armée des Pyrénées occidentales. Les Espagnols se
laissent enlever plusieurs postes, ainsi que la redoute d'Alloqui.

Armée des Pyrénées orientales. Victoire remportée par les Français
auprès de St.-Laurent de la Mouga. Défaite à Rocaseins, de quinze
mille Espagnols, par quatre mille républicains.

1128
28 Thermidor II Armée de Sambre et Meuse. Reprise du Quesnoy.

28 Thermidor IV Prise de Neumarch.

1129
29 Thermidor IV Traité de paix entre la République française et le duc
de Wurtemberg.

1130
30 Thermidor IV Armée de Sambre et Meuse. L'ennemi est chassé de la
hauteur de Sulzbach.

Bataille de Poperg et Leinfeld, prise de Castel.

1202
2 Fructidor IV Armée d'Italie. Retraite de l'armée de Wurmser
derrière Trente, après avoir brûlé sa marine sur le lac de Garde.

1206
6 Fructidor VI Expédition d'Irlande. Les troupes françaises opèrent
leur débarqument en Irlande et se rendent maître de Killala.

1207
7 Fructidor IV Armée d'Italie. Prise de Borgoforte et de Governolo,
après une vive canonnade.

Armée du Rhin et Moselle. Combat de Friedberg et passage du Lech à la
nage par les Français ; l'ennemi est repoussé et mis en déroute.

7 Fructidor VI Traité d'alliance offensive et défensive entre les
Républiques française et helvétique.

1208
8 Fructidor III Armée des Alpes et d'Italie. Victoire remportée sur
un corps considérable de Piémontais.

1209
9 Fructidor II Armée du Nord. Prise du fort l'Ecluse.

1210
10 Fructidor II Armée de Sambre et Meuse. Enlèvement à la baïonette
du village d'Anzain et des postes et redoutes tenant à Valenciennes.

Reprise de Valenciennes.

10 Fructidor VI Expédition d'Irlande. Les Français débarqués en
Irlande attaquent le général Lack à Castlbar, lui prennent six pièces
de canons et le mettent en fuite.

1211
11 Fructidor II Armée des Pyrénées occidentales. Défaite de sept mille
Espagnols à Eibon. Déroute des Espagnols à Ermilla. Déroute de
quatre mille ennemis et entrée des Français à Ondoroa.

1213
13 Fructidor II Armée de Sambre et Meuse. Reprise de Condé.

1214
14 Fructidor III Armée des Alpes et d'Italie. Déroute de quatre mille
Piémontais, venus pour attaquer le Mont-Genève.

14 Fructidor IV Traité de paix entre la République française et le
margrave de Baden.

1215
15 Fructidor III Armée des Alpes et d'Italie. Défaite de quinze cents
Piémontais, venus pour attaquer le poste de Cerise.

15 Fructidor III Traité de paix entre la République française et le
landgrave de Hesse-Cassel.

1216
16 Fructidor II Armée de la Moselle. Combat très vif près
Sandweiller.

1217
17 Fructidor IV Armée du Rhin et Moselle. L'ennemi attaquant et
attaqué depuis Ingolstaldt jusqu'à Fresing, est battu sur tous les
points.

1218
18 Fructidor II Armée des Pyrénées occidentales. Défaite dans la
vallée d'Aspe de six mille Espagnols par six cents Français.

Déroute des Espagnols, mis en fuite par les avant postes de Lescun.

18 Fructidor IV Armée d'Italie. Attaque par les Français de
Santo-Marco. L'ennemi chassé de Piève et Roveredo, se retire au
château de la Pietra.

Armée du Rhin et Moselle. La garnison de Philisbourg et Manheim est
repoussée jusque sous les murs de Philisbourg.

18 Fructidor V Coup d'état contre les royalistes.

1219
19 Fructidor III Armée de Sambre et Meuse. Passage du Rhin par l'aile
gauche de l'armée. L'ennemi est chassé de tous ses retranchements.

Prise de Keyserwerth avec son artillerie et de Dusseldorff.

1221
21 Fructidor I Armée du Nord. Bataille d'Honscoote.

Armée des Ardennes. Les ennemis abandonnent les postes d'Hastières.

Armée d'Italie. Déroute complète des Piémontais, repoussés des postes
de Brouis-Hutel et Levenzo.

21 Fructidor IV
Armée du Rhin et Moselle. Armistice conclu avec S. A. S. R. Bavaro
palatine.

L'avant-garde du centre, rencontre l'ennemi à Mainbourg, et le
culbute.

Armée d'Italie. Attaque du camp retranché de Primolac ; l'ennemi mis
en fuite, se rallie dans le fort de Coveto, qu'il est forcé d'évacuer.

1222
22 Fructidor I Armée du Nord. Fuite précipitée du duc d'Yorc ;
retraite de quarante mille Anglais, Hessois et coalisés, forcés de
lever le blocus de Dunkerque et de Bergues.

22 Fructidor IV Armée d'Italie. L'ennemi chassé de la rive droite de
la Brenta, se retire à Bassano ; les républicains lui livrent bataille
en avant de la ville, le mettent en déroute, et le poursuivent jusqu'à
Citadella.

1223
23 Fructidor VI Armée française en Helvétie. Affaire de Stanz ; les
Suisses sont mis en pleine déroute.

1224
24 Fructidor I Armée des Alpes. Avantage remporté par les Français,
dans la plaine d'Aigue-Belles.

24 Fructidor III Armée de Sambre et Meuse. L'armée française passe le
Rhin en présence de l'ennemi, qui s'y oppose inutilement, et le
repousse au-delà de la ville de Dusseldorff, dont il reste le maître.

1225
25 Fructidor I Armée du Rhin. L'ennemi attaqué sur tous les points,
est chassé de tous ses postes, auprès de Lauterbourg.

1226
26 Fructidor I Armée du Nord. Combat à Werwick et Comines.

26 Fructidor II Armée de la Moselle. Combat en avant de Courteren.

26 Fructidor IV Armée du Rhin et Moselle. Combat de Kamlach ;
l'ennemi est repoussé jusqu'à Mindelheim.

26 Fructidor V Traité de paix conclu entre la République française et
la reine de Portugal.

1227
27 Fructidor I Armée des Alpes. L'ennemi est chassé des hauteurs de
Belleville ; prise de la redoute et des retranchements d'Epierre.

27 Fructidor III Armée de Sambre et Meuse. Combat d'Enef et
d'Hanleshorn.

27 Fructidor IV Armée d'Italie. Prise de Porto-Tegnago.

1228
28 Fructidor I Armée du Rhin. Les Français enlèvent le camp retranché
de Nothweiller, et poursuivent l'ennemi jusqu'au-delà de Bondenthal.

28 Fructidor II Armée des Alpes. L'ennemi est chassé par les
Français, des camps de la Chenal, Sambuck, Prati, et de divers autres
postes.

1229
29 Fructidor IV Armée d'Italie. Bataille de S. Georges ; l'ennemi,
battu sur tous les points, est contraint de se sauver dans Mantoue.

1230
30 Fructidor I Armée de l'Ouest. Victoire remportée par les
républicains sur les rebelles de la Vendée, près de Montaigu.

Armée des Pyrénées occidentales. Avantage remporté par les Français
sur les Espagnols, à Urdach, dans la vallée de Bastan.

30 Fructidor II Armée du Nord. Déroute totale de l'ennemi à Boxtel.

30 Fructidor IV Armée de Sambre et Meuse. Combat et prise
d'Altenkirchen ; l'ennemi, complettement battu, se retire sur la Lahn.

1301
1 jour complémentaire I Armée des Pyrénées orientales. Reprise du
poste de Verret.

Armée des Pyrénées orientales. Reprise de Bellegarde, dernière place
française occupée par l'ennemi.

1302
2 jour complémentaire I Armée des Pyrénées orientales. Les Français
se rendent maîtres de Sterry.

2 jour complémentaire II Armée de Sambre et Meuse. Victoire remportée
par toute la ligne de l'armée française, depuis Maseick jusqu'à
Sprimont.

Prise de Lauwfeld, d'Emale et de Montenack ; passage de l'Ourte et de
Laywale.

2 jour complémentaire IV Armée de Rhin et Moselle. Attaque
infructueuse du fort de Kehl par l'ennemi.

1303
3 jour complémentaire III Armée de Sambre et Meuse. Combat sur la
Lahn ; prise de Limbourg, Dietz et Nasseau.

Armée d'Italie. Combat sur la ligne de Borghetto ; défaite des
Autrichiens.

3 jour complémentaire V Mort du général Hoche, général en chef de
l'armée de Sambre et Meuse.

1304
4 jour complémentaire I Armée des Pyrénées occidentales. Prise de
Villefranche et du camp de Prades.

Prise d'Escalo et d'Uaborsy, occupés par les Espagnols.

4 jour complémentaire II Armée de Sambre et Meuse. Enlèvement de vive
force des hauteurs de Clermont, après sept attaques successives.

Armée d'Italie. Victoire du Cairo sur les Piémontais, soutenus par
dix mille Autrichiens.

4 jour complémentaire III Reddition de Manheim par capitulation.

1305
5 jour complémentaire II Armée des Pyrénées occidentales. Déroute des
Espagnols au Mont-Roch.

5 jour complémentaire IV Mort du général Marceau, âgé de 27 ans, tué à
Altenkirchen par un coup de carabine.
EVENTS
  delete $event{dummy};
}

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
"Dansons la carmagnole, vive le son du canon.";

__END__

=encoding utf8

=head1 NAME

DateTime::Calendar::FrenchRevolutionary::Locale::fr -- French localization for the French 
revolutionary calendar.

=head1 SYNOPSIS

  use DateTime::Calendar::FrenchRevolutionary::Locale;
  my $french_locale = DateTime::Calendar::FrenchRevolutionary::Locale->load('fr');

  my $french_month_name =$french_locale->month_name($date);

=head1 DESCRIPTION

This module provides localization for DateTime::Calendar::FrenchRevolutionary.
Usually, its methods will be invoked only from DT::C::FR.

=head1 USAGE

This module provides the following class methods:

=over 4

=item * new

Returns an  object instance,  which is just  a convenient value  to be
stored in a variable.

Contrary to  the widely used Gregorian  calendar, there is  no need to
customize a French Revolutionary calendar locale. Therefore, there are
no instance data and no instance methods.

=item * month_name ($date)

Returns  the French  name for  C<$date>'s month,  where C<$date>  is a
C<DateTime::Calendar::FrenchRevolutionary> object.

=item * month_abbreviation ($date)

Returns a 3-letter abbreviation for the French month name.

=item * day_name ($date)

Returns the French day name.

=item * day_abbreviation ($date)

Returns a 3-letter abbreviation for the French day name.

=item * feast_short ($date)

Returns  the name for  the plant,  animal or  tool that  correspond to
C<$date>'s feast.

=item * feast_long ($date)

Same  as  C<feast_short>, with  a  "jour"  prefix.

=item * feast_caps ($date)

Same as C<feast_long> with capitalized first letters.

=item * on_date ($date)

Gives a small text about the  events which occurred the same month and
day as C<$date> between the calendar's epoch (22 Sep 1792) and the day
it was rescinded (31 Dec 1805).

Most of these events come  from an anonymous propaganda book published
in year  VIII (1799--1800). The others are  common knowledge available
in any French History book or any encyclopedia.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See L<https://lists.perl.org/> for more details.

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

The development of this module is hosted by I<Les Mongueurs de Perl>,
L<http://www.mongueurs.net/>.

=head1 SEE ALSO

=head2 Books

Calendrier Militaire, anonymous (see the last entry of the Internet section).

=head2 Internet

L<https://github.com/houseabsolute/DateTime.pm/wiki>

L<https://en.wikipedia.org/wiki/French_Republican_Calendar>

L<https://fr.wikipedia.org/wiki/Calendrier_républicain>

L<https://archive.org/details/decretdelaconven00fran_40>

"Décret  du  4 frimaire,  an  II  (24  novembre  1793) sur  l'ère,  le
commencement et l'organisation de l'année et sur les noms des jours et
des mois"

L<https://archive.org/details/decretdelaconven00fran_41>

Same text, with a slightly different typography.

L<https://purl.stanford.edu/dx068ky1531>

"Archives parlementaires  de 1789 à  1860: recueil complet  des débats
législatifs & politiques  des Chambres françaises", J.  Madival and E.
Laurent, et. al.,  eds, Librairie administrative de  P. Dupont, Paris,
1912.

Starting with  page 6,  this document  includes the  same text  as the
previous links, with  a much improved typography.  Especially, all the
"long s"  letters have been replaced  by short s. Also  interesting is
the text  following the  decree, page 21  and following:  "Annuaire ou
calendrier pour la seconde année de la République française, annexe du
décret  du  4  frimaire,  an  II (24  novembre  1793)  sur  l'ère,  le
commencement et l'organisation de l'année et sur les noms des jours et
des mois".

L<https://gallica.bnf.fr/ark:/12148/bpt6k48746z>

[Fabre] "Rapport fait à la Convention nationale dans la séance du 3 du
second mois de la seconde année  de la République française, au nom de
la   Commission    chargée   de   la   confection    du   calendrier",
Philippe-François-Nazaire  Fabre  d'Églantine,  Imprimerie  nationale,
Paris, 1793

L<https://gallica.bnf.fr/ark:/12148/bpt6k49016b>

[Annuaire] "Annuaire  du cultivateur,  pour la  troisième année  de la
République  : présenté  le  30 pluviôse  de l'an  II  à la  Convention
nationale, qui en  a décrété l'impression et l'envoi,  pour servir aux
écoles  de la  République",  Gilbert Romme,  Imprimerie nationale  des
lois, Paris, 1794-1795

L<https://gallica.bnf.fr/ark:/12148/bpt6k43978x>

"Calendrier militaire,  ou tableau  sommaire des  victoires remportées
par les  Armées de  la République française,  depuis sa  fondation (22
septembre 1792),  jusqu'au 9  floréal an  7, époque  de la  rupture du
Congrès de Rastadt et de la reprise des hostilités" Moutardier, Paris,
An  VIII de  la République  française.  The source  of the  C<on_date>
method.


=head1 LICENSE STUFF

Copyright (c)  2003, 2004, 2010,  2012, 2014, 2016, 2019  Jean Forget.
All  rights  reserved.   This  program  is  free   software.  You  can
distribute,         modify,        and         otherwise        mangle
DateTime::Calendar::FrenchRevolutionary under  the same terms  as perl
5.16.3.

This program is  distributed under the same terms  as Perl 5.16.3: GNU
Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<https://dev.perl.org/licenses/artistic.html>
and L<https://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You should  have received  a copy  of the  GNU General  Public License
along with  this program; if not,  see <https://www.gnu.org/licenses/>
or write to the Free Software Foundation, Inc., L<https://www.fsf.org>.

=cut
