# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Perl DateTime extension for providing English strings for the French Revolutionary calendar
# Copyright (c) 2003, 2004, 2010, 2011, 2014, 2016, 2019 Jean Forget. All rights reserved.
#
# See the license in the embedded documentation below.
#

package DateTime::Calendar::FrenchRevolutionary::Locale::en;

use utf8;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.15'; # same as parent module DT::C::FR

my @months_short  = qw (Vin Fog Fro Sno Rai Win Bud Flo Mea Rea Hea Fru S-C);

# based on Thomas Carlyle's book:
my @months = qw(Vintagearious Fogarious Frostarious
                Snowous       Rainous   Windous
                Buddal        Floweral  Meadowal
                Reapidor      Heatidor  Fruitidor);

push @months, "additional day";

my @decade_days = qw (Firsday Seconday Thirday Fourday Fifday Sixday Sevenday Eightday Nineday Tenday);
my @decade_days_short = qw (Fir Two Thi Fou Fif Six Sev Eig Nin Ten);

my @am_pms = qw(AM PM);

my $date_before_time = "1";
my $default_date_format_length = "medium";
my $default_time_format_length = "medium";
my $date_parts_order = "dmy";

my %date_formats = (
    "short"  => "\%d\/\%m\/\%Y",
    "medium" => "\%a\ \%d\ \%b\ \%Y",
    "long"   => "\%A\ \%d\ \%B\ \%EY",
    "full"   => "\%A\ \%d\ \%B\ \%EY\,\ \%{feast_long\}",
);

my %time_formats = (
    "short"  => "\%H\:\%M",
    "medium" => "\%H\:\%M\:\%S",
    "long"   => "\%H\:\%M\:\%S",
    "full"   => "\%H\ h\ \%M\ mn \%S\ s",
);

# When initializing an array with lists within lists, it means one of two things:
# Either it is a newbie who does not know how to make multi-dimensional arrays,
# Or it is a (at least mildly) experienced Perl-coder who, for some reason, 
# wants to initialize a flat array with the concatenation of lists.
# I am a (at least mildly) experienced programmer who wants to use qw() and yet insert
# comments in some places.
# This array is mainly based on L<https://www.allhotelscalifornia.com/kokogiakcom/frc/default.asp>
# Used with permission from Alan Taylor
# Checked with Jonathan Badger's FrenchRevCal-ruby and Wikipedia
my @feast = (
# Vendémiaire
        qw(
       grape                saffron         ?sweet_chestnut ?colchic        horse
       balsam               carrot          amaranth        parsnip         vat
       potato               everlasting     ?squash         mignonette      donkey
       four_o'clock_flower  pumpkin         buckwheat       sunflower       wine-press
       hemp                 peach           turnip          amaryllis       ox
       eggplant             chili_pepper    tomato          barley          barrel
        ),
# Brumaire
        qw(
       apple                celery          pear                    beetroot        goose
       heliotrope           fig             black_salsify           ?whitebeam      plow
       salsify              water_chestnut  jerusalem_artichoke     endive          turkey
       skirret              cress           ?plumbago               pomegranate     harrow
       ?bacchante           azarole         madder                  orange          pheasant
       pistachio            tuberous_pea    quince                  service_tree    roller
        ),
# Frimaire
        qw(
       rampion              turnip          chicory         medlar          pig
       corn_salad           cauliflower     honey           juniper         pickaxe
       wax                  horseradish     cedar_tree      fir_tree        roe_deer
       gorse                cypress_tree    ivy             savin_juniper   grub-hoe
       maple_tree           heather         reed            sorrel          cricket
       pine_nut             cork            truffle         olive           shovel
        ),
# Nivôse
        qw(
       peat                 coal           bitumen         sulphur         dog
       lava                 topsoil        manure          saltpeter       flail
       granite              clay           slate           sandstone       rabbit
       flint                marl           limestone       marble          winnowing_basket
       gypsum               salt           iron            copper          cat
       tin                  lead           zinc            mercury         sieve
        ),
# Pluviôse
        qw(
       spurge_laurel        moss            butcher's_broom snowdrop                bull
       laurustinus          tinder_polypore mezereon        poplar_tree             axe
       hellebore            broccoli        laurel          common_hazel            cow
       box_tree             lichen          yew_tree        lungwort                billhook
       penny-cress          daphne          couch_grass     common_knotgrass        hare
       woad                 hazel_tree      cyclamen        celandine               sleigh
        ),
# Ventôse
        qw(
       coltsfoot            dogwood                   ?hoary_stock      privet          billygoat
       wild_ginger          mediterranean_buckthorn   violet            goat_willow     spade
       narcissus            elm_tree                  fumitory          hedge_mustard   goat
       spinach              leopard's_bane            pimpernel         chervil         line
       mandrake             parsley                   scurvy-grass      daisy           tuna_fish
       dandelion            windflower                maidenhair_fern   ash_tree        dibble
        ),
# Germinal
        qw(
       primula              plane_tree      asparagus       tulip           hen
       chard                birch_tree      daffodil        alder           hatchery
       periwinkle           hornbeam        morel           beech_tree      bee
       lettuce              larch           hemlock         radish          hive
       ?redbud              roman_lettuce   chestnut_tree   rocket          pigeon
       lilac                anemone         pansy           blueberry       dibber
        ),
# Floréal
        qw(
       rose                 oak_tree                fern            hawthorn        nightingale
       columbine            lily_of_the_valley      mushroom        hyacinth        rake
       rhubarb              sainfoin                wallflower      ?chamerops      silkworm
       comfrey              burnet                  basket_of_gold  orache          hoe
       ?statice             fritillary              borage          valerian        carp
       spindletree          chive                   bugloss         wild_mustard    shepherd_staff
        ),
# Prairial
        qw(
       alfalfa              day-lily        clover          angelica        duck
       lemon_balm           oat_grass       martagon        wild_thyme      scythe
       strawberry           betony          pea             acacia          quail
       carnation            elder_tree      poppy           lime            pitchfork
       barbel               camomile        honeysuckle     bedstraw        tench
       jasmine              vervain         thyme           peony           carriage
        ),
# Messidor
        qw(
       rye                  oats            onion           speedwell       mule
       rosemary             cucumber        shallot         wormwood        sickle
       coriander            artichoke       clove           lavender        chamois
       tobacco              currant         vetchling       cherry          park
       mint                 cumin           bean            alkanet         guinea_hen
       sage                 garlic          tare            corn            shawm
        ),
# Thermidor
        qw(
       spelt                mullein         melon           ryegrass        ram
       horsetail            mugwort         safflower       blackberry      watering_can
       ?parsnip             glasswort       apricot         basil           ewe
       marshmallow          flax            almond          gentian         waterlock
       carline_thistle      caper           lentil          horseheal       otter
       myrtle               oil-seed_rape   lupin           cotton          mill
        ),
# Fructidor
        qw(
       plum                 millet          lycoperdon      barley          salmon
       tuberose             bere            dogbane         liquorice       stepladder      
       watermelon           fennel          barberry        walnut          trout
       lemon                teasel          buckthorn       marigold        harvesting_basket
       wild_rose            hazelnut        hops            sorghum         crayfish
       bitter_orange        goldenrod       corn            chestnut        basket
        ),
# Jours complémentaires
        qw(
       virtue               engineering    labour          opinion          rewards
       revolution
         ));

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
  $lb =~ s/^\?//;
  $lb =~ s/_/ /g;
  return $lb;
}

sub feast_long {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0] . " day";
  $lb =~ s/^\?//;
  $lb =~ s/_/ /g;
  return $lb;
}

sub feast_caps {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0] . " Day";
  $lb =~ s/^\?//;
  $lb =~ s/_/ /g;
  return ucfirst($lb);
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

sub    full_datetime_format { join ' ', ( $_[0]->full_date_format, $_[0]->full_time_format )[ $_[0]->_datetime_format_pattern_order ] }
sub    long_datetime_format { join ' ', ( $_[0]->long_date_format, $_[0]->long_time_format )[ $_[0]->_datetime_format_pattern_order ] }
sub  medium_datetime_format { join ' ', ( $_[0]->medium_date_format, $_[0]->medium_time_format )[ $_[0]->_datetime_format_pattern_order ] }
sub   short_datetime_format { join ' ', ( $_[0]->short_date_format, $_[0]->short_time_format )[ $_[0]->_datetime_format_pattern_order ] }
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
1 Vendémiaire I The French troops enter Savoy.

1 Vendémiaire III The posts in the woods of Aachen and Reckem are
taken by the Army of North.

0102
2 Vendémiaire I Conquest of Chambéry.

2 Vendémiaire III The Costouge redoubt and camp are taken by the Army of Eastern Pyrenees.

2 Vendémiaire V The Army of Italy routs the enemy at Governolo.

0103
3 Vendémiaire IV Affair of Garesio.

0104
4 Vendémiaire II The Army of Alps takes the Chatillon fieldworks; Piemontese rout across the Giffe river.

0105
5 Vendémiaire III The Spanish are defeated in Olia and Monteilla by the
Army of Eastern Pyrenees.

0106
6 Vendémiaire III Surrender at Crevecoeur to the Army of the North.

6 Vendémiaire III Kayserlautern, Alsborn and other surrounding posts
are taken again by the Army of the Rhine.

6 Vendémiaire V The enemy attacks the Army of Sambre and Meuse at
Wurstatt, Nider-Ulm, Ober and Nider-Ingelheim; the attack is repulsed.

6 Vendémiaire XII Birth of Prosper Mérimée, French writer.

0107
7 Vendémiaire I Anselme's troops conquer the city of Nice and the Montalban fortress. 

7 Vendémiaire II The Army of Alps (Verdelin) defeats the enemy in the Sallanges 
defiles and takes the Saint-Martin redoubt.

0108
8 Vendémiaire V 150 men from the Army of Italy sortie from Mantoue to forage.
They must surrender to the people of Reggio.

0109
9 Vendémiaire I Custines' French conquer Spire.

9 Vendémiaire II The Army of Alps takes the fieldworks at
Mont-Cormet, previously held by Piemontese.

0111
11 Vendémiaire II Prisy's troops (Army of Alps) take the Valmeyer outpost
after a bayonet charge, Saint-André's and Chamberlhac's troops take the Beaufort
post, General-in-Chief Kellerman's troops take Moutiers and the Saint-Maurice
town and Ledoyen's troops storm the Madeleine pass post. 

11 Vendémiaire III Battle of Aldenhoven, the Army of Sambre and Meuse
routs the coalised troops.

11 Vendémiaire V The Army of Rhine and Moselle attacks
on the whole front and routs the enemy.

0112
12 Vendémiaire II The Spanish troops are repulsed back in their camps in the Boulon 
and Argelès by the Army of Eastern Pyrenees.

12 Vendémiaire III The land of Juliers surrenders to the Army of Sambre and Meuse.

0113
13 Vendémiaire I The Austrians must leave Worms and Custines' troops enter the city.

13 Vendémiaire II Army of Eastern Pyrenees: Dagobert's troops take
Campredon while the Colioure garrison fights and routs the Spanish cavalry.

13 Vendémiaire II Army of Western Pyrenees. Attacks and capture of the
Arau and Aure valley posts.

13 Vendémiaire IV Bonaparte suppresses a royalist demonstration at the 
Saint-Roch church in Paris.

0115
15 Vendémiaire III Cologne surrenders to the Army of Sambre and Meuse.

0116
16 Vendémiaire V The enemy, blockaded in Mantoue by the Army of Italy
attempts a 4,600-troop sortie but fails.

0117
17 Vendémiaire I The Austrians call off the siege of Lille.

17 Vendémiaire III Fight for and capture of Frankenthal by the Army of the Rhine.

0118
18 Vendémiaire II Bombardment of Lyon, which opens her gates to
Dubois-de-Crancé's troops.

18 Vendémiaire III Capture of Shelaudenbach and Vollfstein by the Army of the Rhine
which links with the Army of Moselle in Lautreck.

0119
19 Vendémiaire III Before Maestricht, the Army of Sambre and Meuse takes back
the Mont-Saint-Pierre castle.

0120
20 Vendémiaire III The Army of Moselle marches on Birkenfeldt, Oberstein,
Kirn and Meisenheim.

0121
21 Vendémiaire III The Army of the North enters Bois-le-Duc.

0122
22 Vendémiaire I Kellerman forces the Prussians to leave the city of Verdun.
He enters Verdun and continues his march to the Prussians.

0123
23 Vendémiaire III The Army of the Rhine takes Otterberg, Rockenhausen, 
Landsberg, Alzein and Oberhausen.

0124
24 Vendémiaire II The Army of Moselle fights and routs the
Coalised who had advanced on Bitche and Rorbach.

24 Vendémiaire III Fight for and capture of Gellheim and Grunstad by
the Army of the Rhine; the French capture also Frankenthal.

0125
25 Vendémiaire II Combat near Sarreguemines; the Army of Moselle
repulses the enemy.

25 Vendémiaire II Queen Marie-Antoinette is beheaded.

0126
26 Vendémiaire I The Austrians attack Hasnon and fail several times.

26 Vendémiaire II Victory of Wattignies near Maubeuge against the
Austrians and end of the blockade of Maubeuge.

26 Vendémiaire III The Army of Western Pyrenees takes
Iraty, Egay and Orbaycette.

26 Vendémiaire III Army of Moselle. General-in-chief 
Moreau's troops take Creutznach and Custines' troops take Worms.

26 Vendémiaire VI Army of Italy. Peace treaty in Campo-Formio
near Udine between Bonaparte and the Austrians.

26 Vendémiaire VI Congress in Rastadt to conclude peace between the 
French Republic and the German Empire.

0127
27 Vendémiaire II Army of Italy. 600 republican troops repulse 4,000
Austrians, Croats and Piemontese.

27 Vendémiaire III The Army of Western Pyrenees defeats 7,000 
Spaniards near Buruet and Almandos.

27 Vendémiaire III The Army of the Rhine routs the enemy near
Kircheim and Worms and captures both cities.

0128
28 Vendémiaire II The Army of Italy achieves a complete
victory at Gilette over the Piemontese.

28 Vendémiaire III The Army of the North defeats the enemy near Nimegen
and destroys the legion of Rohan.

28 Vendémiaire V The Army of the Rhin and Moselle is attacked in
Retzengen and Simonswald.

0129
29 Vendémiaire I The French Army forces the Austrians to leave Mayence.

29 Vendémiaire III The Armée of Moselle enters Bingen.

29 Vendémiaire V The Army of Italy, debarking in Corsica,
captures Bastia, Saint-Florent and Bonifacio.

29 Vendémiaire XIV Battle of Trafalgar.

0130
30 Vendémiaire II The Army of Western Pyrenees
routs three Spanish columns after a five-hour firefight.

30 Vendémiaire V Army of Sambre and Meuse. Enemy crossing of the Rhine
at Bacharach and Andernach and failed attack of the Neuwied
bridgehead.

0201
1 Brumaire I Longwi taken back, the Prussians evacuate the French
territory.

1 Brumaire II Army of Eastern Pyrenees. Advantage over the Spanish
Army in the valley of Baigory.

1 Brumaire II Army of the North. The posts of Warneton, Comines,
Werwick, Ronek, Alluin, Menin, Furnes and Poperingues are taken.

1 Brumaire II Army of the Rhine. Alzey and Oppenheim captured.

0202
2 Brumaire II Army of Italy. 5000 enemies defeated in Utel.

2 Brumaire II Army of the Rhine. The Austrians attack the post of
Breitenstein and are repulsed.

2 Brumaire III Army of Sambre and Meuse. Coblentz taken, the enemy
crosses the Rhine and flees.

2 Brumaire III Army of Eastern Pyrenees. Fighting in Bhaga, the
Spaniards are repulsed.

2 Brumaire III Army of Eastern Pyrenees. The outposts of Dori and Tozas
and the fieldworks in Casteillan are taken.

0203
3 Brumaire V Peace treaty signed between the French Republic and the
King of Naples and the Two-Sicilies.

0204
4 Brumaire IV Beginning of the Directorate.

4 Brumaire VI Army of Italy. Treaty of alliance between the French
Republic and the King of Sardinia.

0205
5 Brumaire III Army of the North. Hultz, Axel and Sas-de-Gand taken.

5 Brumaire V Army of Sambre and Meuse. Attack and capture of Saint
Wendel, Kayserslautern, Kirchenpoland, Bingen and the Saint-Roch
mountain.

5 Brumaire V Army of the Rhine and Moselle. Crossing of the Rhine by
the French, capture of the Khel fort.

0207
7 Brumaire V Army of Italy. An enemy sortie from Mantoue is repulsed.

0208
8 Brumaire III Army of the North. Capture of Venlo.

0209
9 Brumaire II Army of Eastern Pyrenees. A battery before Ville longue
is taken by a bayonet charge.

0211
11 Brumaire III Army of Eastern Pyrenees. The Spaniards are routed on
the reverse slope of the montagne Noire.

0212
12 Brumaire I The Austrians must evacuate the small town Lanoy, their
last post on the French territory.

12 Brumaire III Army of Moselle. The French enter Rheinfels,
evacuated by 1200 enemies.

12 Brumaire V Army of Italy. Capture of the Saint-Michel village.
The French burn the bridges on the Adige. The enemy turns to Lavis,
where it is beaten and repulsed to the Segonzano village.

0214
14 Brumaire V Army of Sambre and Meuse. Capture of Maestricht.

0215
15 Brumaire V Army of Italy. The enemy attacks across Brenta and
crosses back after a murderous fight.

0216
16 Brumaire I Battle of Gemmapes. Following this victory, the
French enter Mons.

16 Brumaire III Army of the North. The fort of Schenk is taken.

0217
17 Brumaire III Army of the North. The sortie of the Berg-op-zoom
garrison is repulsed by a French bayonet charge.

0218
18 Brumaire I The French capture Tournay.

18 Brumaire III Army of the North. Triumphant entry of the French
into Nimègue.

18 Brumaire VIII Bonaparte's coup: end of Directorate, beginning of Consulate.

0219
19 Brumaire IV Army of the North. Burick taken.

0220
20 Brumaire IV Army of Sambre and Meuse. Fight near Creutzenach,
during which the enemy must cross back the Nahe river.

0221
21 Brumaire V Army of Italy. Meeting engagement on the Adige river,
between Saint-Michel and Saint-Martin, the enemy is repulsed.

0222
22 Brumaire I Army of the North. The city of Gand open her gates to
the French army.

22 Brumaire I Charleroy taken by the French.

22 Brumaire III Army of the Rhine. Monbach and neighbour posts
taken, capture of Weissenau.

0223
23 Brumaire I Battle of Anderlecht near Brussels. The 
French army enters Brussels.

0224
24 Brumaire I Capture of Frankfurt.

24 Brumaire II Army of the West. The Vendean rebels are defeated
before the walls of Granville.

0225
25 Brumaire V Army of Italy. 3-day battle of Arcole. The Arcole village is taken
on 27.

0226
26 Brumaire I The French control the town and harbour of Ostende,
evacuated by the Austrians.

26 Brumaire I Saint-Remi captured.

26 Brumaire I The town of Malines capitulates.

26 Brumaire II Army of the Rhine. The army launches a surprise attack
and captures three enemy posts near Strasburg.

26 Brumaire II The siege of Granville is lifted.

26 Brumaire IV Fight of the di Pietri field.

0227
27 Brumaire II Army of Moselle. Austrian defeat before Bitche. Austrian
rout near Lebach. Bising and Blise-Castel captured.

27 Brumaire III Army of Eastern Pyrenees. General-in-chief Dugommier
killed at St. Sebastien de la Mouga.

27 Brumaire III Army of Eastern Pyrenees. Victorious battle against
the Spaniards at Saint-Sebastien.

0228
28 Brumaire I The cities of Ypres, Furnes and Bruges are captured.
The French enter Anvers.

28 Brumaire II Army of the Rhine. The Neuviller post and four other
are taken. A big redoubt and 7 cannons are captured near Wantzenau.

28 Brumaire V Peace treaty signed between the French Republic and the
Duke of Parme.

0229
29 Brumaire II The Army of the Rhine captures two redoubts near
Bouxweiller.

29 Brumaire VIII Birth of René Caillé, the first European to enter Timbuktu.

0230
30 Brumaire II Army of Eastern Pyrenees. Victorious battle at Escola,
Liers, Vilartoly, against 50,000 Spanish troops.

30 Brumaire II Army of Moselle. 1200 infantry and 300 cavalry
defeated near Blascheidt, and Lorentsweiller.

0301
1 Frimaire I Army of Ardennes. Namur captured by the French.

1 Frimaire III Army of the Moselle. More than 400 enemies defeated
in the forest of Grunnevald, near Luxemburg.

1 Frimaire V Army of Italy. The enemy is repetively attacked and
repulsed from Castel-Novo to Rivoli, la Corona, and along the Adige
river until Dolce.

0302
2 Frimaire I Army of the Rhine. 5,000 French rout the whole enemy
army before Tirlemont.

2 Frimaire II Army of the Rhine. Capture by the French of the
Bouxweiller, Brumpt and Haguenau posts.

2 Frimaire IV Army of Italy. Battle of Loano, the Austro-Sards rout.
Capture of la Pietra, Loano, Finale, Vado and Savonne.

2 Frimaire V Army of the Rhine And Moselle. The Kehl garrison sorties.
The enemy line is pushed through without a single shot. Part of its
artillery is spiked.

0303
3 Frimaire IV Army of Italy. Fight at Intrapa and Garesio.

3 Frimaire V Sortie by the garrison of Mantoue, which is repulsed.

0304
4 Frimaire II Army of Italy. 800 Piemontese defeated by 500 French at
Castel-Genest and Brec, capture of Figaretto.

4 Frimaire III Army of Western Pyrenees. Victory in Ostés.

0306
6 Frimaire IV Army of Italy. Fights in Spinardo and other places.

0307
7 Frimaire I Army of the Rhine. The city of Liege is taken.

7 Frimaire III Army of Eastern Pyrenees. Capture of the Figuières
fortress.

0308
8 Frimaire III Army of Eastern Pyrenees. Battle won against the
Spaniards at Begara, Ascuatia and Aspetia.

0310
10 Frimaire I Army of the North. Capitulation of the Anvers citadel.

10 Frimaire II Army of the North. Attack of all the enemy posts on
the Lys.

10 Frimaire IV Army of Sambre and Meuse. Attack and capture of
Creutzenach.

0311
11 Frimaire I Army of Ardennes. Capitulation of the Namur citadel.

11 Frimaire II Army of the Rhine. The redoubt of the Landgraben
bridge and the fieldworks at Gambsheim are taken.

11 Frimaire III Army of the Rhine And Moselle. The redoubt known as
"Merlin redoubt" before Mayence is taken.

11 Frimaire V The enemy, arrayed in three columns, attacks the
bridghead at Huningue and takes a fortification but is repulsed.

11 Frimaire XIII Napoleon the First is crowned Emperor of the French.

11 Frimaire XIV Battle of Austerlitz: the French army crushes the Austro-Russian army.

0312
12 Frimaire II Army of Ardennes. Strong sortie of the Givet garrison,
which inflicts many enemy casualties while losing only 5 to 6 troops,
between Falmagne and Falmignoule.

12 Frimaire II Army of the Rhine. Fight near the Gambshein wood.

12 Frimaire VIII Battle of Hohenlinden.

0314
14 Frimaire II Army of the Rhine. The enemy, expelled from the
Oppendorff village, is pursued until Druzenheim.

14 Frimaire III Army of the Moselle. The Republic's troops storm the
Salbach redoubts.

0319
19 Frimaire II Army of the Rhine. The Dawendorff highgrounds are captured.

0320
20 Frimaire XII Birth of Hector Berlioz, French musician.

0321
21 Frimaire I Army of the North. Capture of Wezem, Wert and Ruremonde.

0322
22 Frimaire II Army of the West. Victory against the Vendean rebels
near Le Mans.

0323
23 Frimaire II Army of Western Pyrenees. The Spanish troops are routed
near Saint-Jean-de-Luz; they must cross the Bidassoa.

0324
24 Frimaire I The French troops take the towns
of Mertzicq, Fredembourg and Saarbruck.

0325
25 Frimaire II Army of the Moselle. Three divisions take the
highgrounds of Marsal, Dahnbruck and Lambach.

25 Frimaire II Army of Italy. The French troops take the fieldworks
and redoubts that were defending Toulon.

0326
26 Frimaire I Capture of Consarbruck.

26 Frimaire II Army of Italy. Toulon conquered, the English and
Spanish troops flee.

26 Frimaire IV Army of Sambre and Meuse. Fight on the whole
Hundstruck line; the enemy is beaten everywhere.

0327
27 Frimaire II Army of Ardennes. Fight near Philippeville, in the
Jamaica wood, the Austrians are repulsed.

0329
29 Frimaire II Army of Eastern Pyrenees. Capture or the highgrounds
near Villelongue.

0402
2 Nivôse II Army of the Rhine and Moselle. The enemy defeated at Werd.

0403
3 Nivôse II Army of the Rhine and Moselle. All fieldworks at
Bischweiller, Druzenheim and Haguenau are taken.

0405
5 Nivôse II Army of the Rhine and Moselle. The enemy is routed at
Oberseebach. Capture of the castle of Geisberg.

0406
Army of the Rhine and Moselle. The enemy is forced to evacuate the
lines of Lauter and Weissembourg and to lift the blockade of Landau.

0407
7 Nivôse II Army of the Rhine. The French capture the posts at
Germersheim and Spire.

0408
8 Nivôse III Army of the North. Crossing of the Vaal, capture of
Bommel and the Saint-André fort, surrender of Grave.

0413
13 Nivôse I Army of the North. Elements of the French vanguard enter
the region of Luxembourg and grab the Emperor's warchest.

0414
14 Nivôse II Army of the West. The island of Noirmoutiers is taken
from the Vendean rebels.

0417
17 Nivôse II Army of the Rhine and Moselle. Worms captured.

17 Nivôse III Army of Western Pyrenees. Trinité fort captured.

0420
20 Nivôse VI Army of Italy. Two French columns converge on Rome to
avenge the death of general Duphot and the insult to the ambassador of
the French Republic. Popular uprising and overthrow of the papal government.

0422
22 Nivôse III Army of the North. Capture of Thiel and six forts.

0423
23 Nivôse II Army of Western Pyrenees. 400 Republican troops storm the
"poste de la Montagne" of Louis XIV.

23 Nivôse V Army of Italy. Fight of Saint-Michel before Verona. The
enemy attacks the Montebaldo line and is repulsed.

0424
24 Nivôse III Army of the North. Capture of Heusdin.

0425
25 Nivôse V Army of Italy. Battle of Rivoli, the enemy is completely
routed.

0426
26 Nivôse V Army of Italy. 10 000 enemy troops cross at Anghiari.

26 Nivôse V Army of Italy. General Provera, leading 6 000 troops,
attacks the Saint-George suburb of Mantoue to no effect.

0427
27 Nivôse II Army of the Rhine and Moselle. The enemies sortie from
the Vauban fort but they are repulsed.

27 Nivôse V Battle of the Favorite (suburb of Mantoue), Wurmser
sorties from Mantoue and fails, and Provera must capitulate.

0428
28 Nivôse III Army of the North. Capture of Utrecht, Amersford and
the Greb lines, crossing of the Lech.

0429
29 Nivôse II Army of the Rhine. The coalized evacuate completely the
Lower-Rhine department. The Vauban fort is taken back.

29 Nivôse III Army of the North. Capture of Gertuydemberg.

0430
30 Nivôse VI Birth of Auguste Comte, French philosopher.

0502
2 Pluviôse I Louis XVI is beheaded.

2 Pluviôse II Army of Western Pyrenees. 200 French storm the
Harriette redoubt near Ispeguy.

2 Pluviôse III Army of the North. The towns of Gorcum, Dordrecht and
Amsterdam surrender to the French.

0504
4 Pluviôse II Army of Var. The English leave the Hyeres islands.

0507
7 Pluviôse V Army of Italy. The enemy, repulsed beyond the Brenta, is
reached at Carpenedelo, and forced to retreat.

0508
8 Pluviôse V Army of Italy. The enemy, pursued in the Tyrol gorges, is
reached at Avio.

0509
9 Pluviôse V Army of Italy. General Murat lands in Torgole and repulses the enemy;
General Vial outflank them. The French enter in Roveredo and Trente.

9 Pluviôse VI Army of Italy. Capture of the town of Ancône, by the
French army, which continues toward Rome through Maurata.

0510
10 Pluviôse V Army of the Rhine and Moselle. The Republican army
sorties from the Huningue brigdgehead and repulses the enemy.

0513
13 Pluviôse I The French Republic declares war on the King of England
and the Stathouder of Holland.

13 Pluviôse VI Army of Italy. A column of the Army of Italy crosses
the Geneva region and establishes its headquarters in Ferney-Voltaire.

0514
14 Pluviôse V Army of Italy. The French attack the remnants of the
Austrian army behind the Lavis and repulse them.
The French enter Jmola, Faenza and Forli.
Capitulation of Mantoue.

0515
15 Pluviôse III Army of Western Pyrenees. Capture of Roses, after a
27-day siege.

Army of the North. Conquest of Holland: all the fortresses and
warships are controlled by the French. The French troops enter
Midelbourg and Flesingue.

0517
17 Pluviôse III Army of Western Pyrenees. Complete Spanish rout at
Sare and Berra.

15 000 Spanish are vanquished and routed at Urrugne and
Chauvin-Dragon.

0518
18 Pluviôse V Army of Italy. The enemy outposts are repulsed on the
Adige right bank. Derunbano captured.

0520
20 Pluviôse IV Birth of Barthélémy Prosper Enfantin, French social reformer.

0521
21 Pluviôse V Army of Italy. The Pope's troops, on the highground
before Ancona, are surrounded and taken prisoners without a single
shot. Ancona captured.

21 Pluviôse VI Army of Italy. The French troops continue their advance
on Rome.

0522
22 Pluviôse V Army of Italy. Capture of Lorette.

0527
27 Pluviôse VI Army of Italy. The French enter Rome. General
Berthier proclaims the Roman Republic.

0601
1 Ventôse II Army of the Rhine. The French capture the Ogersheim post.

1 Ventôse V Army of Italy. Treaty of peace with the Pope, signed in
Tolentino.

0604
4 Ventôse V Army of Italy. The Treviso post is taken back.

0605
5 Ventôse V Army of Italy. The enemy is repulsed out of its
fieldworks in Foi. Then the French encounter a Tyrolian Jäger corps
and defeat them.

The French, attacked in Bidole, smash the enemy. Kellerman crosses
the Piave in San-Mamma, and routs some enemy hussards.

0607
7 Ventôse X. Birth of Victor Hugo.

0611
11 Ventôse III Army of Eastern Pyrenees. Bezalu captured.

0612
12 Ventôse V Army of Italy. The French attack the enemy at Monte
di-Savaro and beat him.

0615
15 Ventôse VI Army of Helvetia. Capitulation of the city of Berne.

0616
16 Ventôse II Army of Ardennes. Fight near Soumoy and Cerffontaine;
the enemy is defeated.

0617
17 Ventôse I War is declared on the King of Spain.

0618
18 Ventôse II Army of the Moselle. Three Austrian battalions are
defeated on the Joegerthal highground.

0620
20 Ventôse V Army of Italy. A French division goes to Feltre; as it
nears the town, the enemy evacuates the Cordevole line and goes to
Bellurn.

0622
22 Ventôse V Army of Italy. The 21th Light crosses the Piava opposite
to the Vidor village and repulses the enemy.

0623
23 Ventôse V Army of Italy. Fight in Sacile. Fight in Bellurn, in
which the enemy rearguard is surrounded and taken prisoner.

23 Ventôse VI After five murderous fights, the Swiss evacuate Morat.

0626
26 Ventôse V Army of Italy. Crossing of the Tagliamento, despite a
superior enemy force and a deliberate resistance. The Gradisca village
is taken.

0627
27 Ventôse VI Treaty of alliance and trade between the French and
Cisalpine Republics.

0628
28 Ventôse V Army of Italy. Capture of Palma Nova, which the enemy
must evacuate.

0629
29 Ventôse V Army of Italy. Capture of the town of Gradisca. Crossing
of the Casasola bridge.

29 Ventôse XII The Duke of Enghien is executed.

0630
30 Ventôse V Army of Italy. Fight of Lavis. The enemy troops are
surrounded by the French.

0701
1 Germinal V Army of Italy. The French enter Goritz. Affair of
Caminia, between the French vanguard and the enemy rearguard.

0702
2 Germinal IV Army of Italy. Fights at Tramin and at Caporetto.

0703
3 Germinal V Army of Italy. Fight at Clausen. The enemy, beaten in
Botzen, withdraws inside Clausen, where it is attacked by the French
and forced to yield.

0704
4 Germinal V Army of Eastern Pyrenees. The French enter Trieste and
take the famous mines of Ydria.

0705
5 Germinal II Army of the Moselle. The French prevail against the
Prussians who attack the outposts of Apach, north of Sierck.

5 Germinal V Army of Italy. Fight at Tarvis; after a fierce
resistance, the enemy is routed.

0706
6 Germinal V Army of Italy. Affair of the Chinse; this important 
position is taken.

0707
7 Germinal V Birth of Alfred de Vigny, French poet.

0708
8 Germinal V Army of Italy. Enemy battalions, fresh from the Rhine
front, attempt to defend the Innsbruck defile; they are repulsed by
the 85th half-brigade.

0709
9 Germinal V Army of Italy. The French enter the town of Clagenfurth,
capital of Higher and Lower Carinthie; Prince Charles flees with the
remnants of his army.

0712
12 Germinal V Army of Italy. Fight in the gorges of Neumarck; the
enemy rearguard is repulsed by the French vanguard and the French
enter Neumarck and Freissels.

0714
14 Germinal II Army of Western Pyrenees. The French storm the Ozone
fieldworks, near Saint-Jean de Luz and rout the Spanish troops.

14 Germinal V Army of Italy. The Austrians, beaten everywhere,
evacuate Tyrol. Prince Charles retreats toward Vienna and is beaten by
the Massena division.

0715
15 Germinal V Army of Italy. Fight at Hundsmarck; the enemy rearguard is defeated by
the French vanguard. The French enter Hundsmark, Kintenfeld, Mureau
and Judembourg.

0716
16 Germinal IV Army of Italy. Military reconnaissance toward Cairo;
the enemy posts are repulsed.

0717
17 Germinal II Army of Western Pyrenees. Spanish defeat near Hendaye.

Army of Italy. Capture of the Fougasse camp.

17 Germinal II Execution of Georges Danton, Camille Desmoulins and Fabre d'Églantine.

0718
18 Germinal II Army of Italy. Capture of all the posts near Breglio,
in the county of Nice.

18 Germinal V Five-day halt of the fighting between the French army
and the Imperial army in Italy.

0719
19 Germinal II Army of Italy. Capture of Oneille.

0720
20 Germinal IV Army of Italy. Affair of Voltry.

0721
21 Germinal II Army of Eastern Pyrenees. Spanish defeat at Monteilla;
Urgel captured.

Army of Ardennes. A small detachment from Philippeville prevails and
repulses the enemy from the woods between Villiers and Florence, and
routs it.

21 Germinal IV
Army of Italy. Attack of the Montelezimo redoubt, defended by the
French; the enemy is repulsed.

0722
22 Germinal VI Army of Mayence. Blockade of the Ehreinbrestein fort.

0723
23 Germinal IV Army of Italy. Battle of Montenotte; the enemy is
completely routed.

0725
25 Germinal III Peace treaty between the French Republic and the King
of Prussia.

25 Germinal IV Army of Italy. Capture of Cossaria.

0726
26 Germinal II Army of the Moselle. Fight on the highgrounds of
Tiperdange.

26 Germinal IV Army of Italy. Battle of Millesimo, won against the
Austro-Sards. Fight at Dego, the enemy is routed. Fight and capture
of Saint-Jean, in the valley of Barmida. Capture of Batisolo, Bagnosco
and Pontenocetto. Capture of the Montezemo redoubts.

26 Germinal V Birth of Adolphe Thiers, French writer and politician.

0727
27 Germinal II Army of the Moselle. The French occupy the highground
of Mertzig, the enemy having been repulsed.

Army of Italy. Fifteen hundred Austrians defeated at Ponte-di-Nava.

27 Germinal IV Army of Italy. Capture of the fortified camp of Cera.

0728
28 Germinal II Army of Italy. Capture of Ormea.

0729
29 Germinal II Army of the Moselle. Battle of Arlon; the town is taken
and the enemy is completely routed.

0802
2 Floréal I Army of Western Pyrenees. Skirmish in Jugazza Mondi.

0803
3 Floréal II Army of the Ardennes. Complete rout of the enemy at
Aussoy, near Philippeville, after a 12-hour fight.

3 Floréal IV Army of Italy. Fight and conquest of the town of Mondovi.

0804
4 Floréal II Army of the Rhine. Victory near Kurweiller.

0805
5 Floréal I Army of Eastern Pyrenees. Skirmish in Samouragaldi,
during which 200 French troops defeat 400 Spanish troops.
Bombardment of Fontarabie.

5 Floréal II Army of the Alps. All the redoubts in Mount Valaisan and
Mount Saint-Bernard are stormed.

5 Floréal IV Army of Italy. The French troops enter the town of Bêne.

0806
6 Floréal IV Army of Italy. Capture of Fossano, Cherasco and Alba.

0807
7 Floréal II Army of Western Pyrenees. The Spanish and Emigrate
troops are repulsed from Arnéguy and Irameaca.

Army of the Ardennes. Victory after a hard-fought 4-hour fight. The
Bossu high-grounds are stormed. The Army of Ardennes and the Army of
the North enter Beaumont and link with each other.

Army of the North. Capture of Courtray, after a general battle on the
whole front, from Dunkirk to Givet.

Army of Eastern Pyrenees. The French troops capture the rock of
Arrola.
4000 Spanish infantry troops and 10 Spanish cavalry squadrons rout at
Roqueluche.

7 Floréal VI Birth of Eugène Delacroix, French painter.

0808
8 Floréal II Army of Eastern Pyrenees. 3000 French troops repulse
10000 enemy troops from the village of Oms. They take the defile and
the bridge of Ceret.

0809
9 Floréal IV Army of Italy. Armistice signed with the king of
Sardinia.

0810
10 Floréal II Army of the North. Victory at Mont-Castel over 20,000
Austrians. Capture of Menin and much artillery.

Army of Italy. Victory over the Piemontese and capture of Saorgio.

10 Floréal IV The French troops enter the cities of Ceva and Coni.

10 Floréal V Treaty of peace between the French Republic and the Pope.

0811
11 Floréal II Army of Eastern Pyrenees. Victorious battle against
Spanish troops, at Albères; storming of the famous Montesquiou
redoubt.

11 Floréal V Army of Italy. Peace preliminaries between the French
Republic and the Austrian Emperor, signed at Leoben by general
Buonaparte and the Emperor's plenipotentiaries.

0812
12 Floréal II Army of the Rhine. Capture of Lambsheim and Franckental
by the French; the gates of the latter town are destroyed by
cannon-fire.

0815
15 Floréal II Army of Eastern Pyrenees. The French occupy the
high-grounds of cap de Bearn and of the land of Las-Daines. The siege
of Collioure begins.

15 Floréal III Army of Eastern Pyrenees. The Spanish troops attack the
Cistella camp but are beaten and repulsed.

0816
16 Floréal IV Army of Italy. The French enter the town of Tortonne.

0817
17 Floréal III Army of Eastern Pyrenees. General reconnaissance by the
French on the Crespia and Bascara highgrounds and on the Fluvia.

0818
18 Floréal IV Army of Italy. Reconnaissance on the Po bank, toward
Plaisance.

0819
19 Floréal II Lavoisier is guillotined.

19 Floréal IV Army of Italy. The Republican vanguard crosses the Po.
Fight in Fombio.

0820
20 Floréal II Army of the Alps. The Mirabouck fort is taken, after a
14-hour attack. The Villeneuve-des-Prats post is captured.
Capture of the Maupertuis redoubt.

20 Floréal III Army of Eastern Pyrenees. Attack of the camp of the
Musquirachu montain; the enemy flees and discards its camp, already
set-up.

20 Floréal IV Army of Italy. Near Cordogno, the Austrians attack the
Laharpe division, and are strongly repulsed by the Republican troops
which take Casale.

Armistice concluded with the Duke of Parma.

0821
21 Floréal II Army of the Ardennes. Capture of Thuin by the French
troops.

21 Floréal IV Army of Italy. Battle of Lody: crossing of the bridge
defended by Beaulieu's complete army.

0822
22 Floréal II Army of the North. The enemy is defeated before Tournay.
7-hour fight before Courtray: the enemy is completely routed. The
enemy is routed at Ingelsmunster.

22 Floréal IV Army of Italy. Capture of Pizzighitone. The French enter
Crémone.

0823
23 Floréal II Army of the Ardennes. The French capture all fieldworks
in the Merbes camp, from which the enemy retreat.
During the crossing of the Sambre, the 49th Regiment grenadiers throw
themselves into the water to help the skirmishers and rout the Bourbon
Legion.

The 68th Regiment defends alone a bridge attacked by more Austrians
and do not yield.

0824
24 Floréal II Army of the Ardennes. Hard-fought combat: the village of
Grandreng near Beaumont is taken and retaken three times.

0825
25 Floréal II Army of the Alps. The Republican troops storms the
Riveto and la Ramasse redoubts and other posts on Mount-Cenis.

0826
26 Floréal IV Army of Italy. Peace is concluded with the king of
Sardinia.

0827
27 Floréal II Army of Eastern Pyrenees. The Collioure garrison
sorties. 3000 Spanish troops are repulsed with loss. The
general-in-chief is wounded during this action.

0828
28 Floréal IV Army of Italy. The French occupy Milan, Pavie and Come.

28 Floréal XII "The government of the French Republic is given to an emperor."

0829
29 Floréal II Army of the North. The enemy is defeated at Moescroen.
Victorious battle against the coalised, between Menin and Courtray.

Army of the Ardennes. Glorious resistance of 1500 French troops
against the advance of 14000 Austrians toward Cunfoz. 150 conscripts
hold agains the right wing of Beaulieu's army, before Bouillon.

Army of Western Pyrenees. Six enemy stores are taken. The Spanish
troops are repulsed by a bayonet attack until their camp in Berra.

0830
30 Floréal II Army of Eastern Pyrenees. The Spanish troops rout near
Figuières.

Army of the Ardennes. 160 French in the castel of Bouillon defend
against numerous enemies.

30 Floréal VI Bombardment of Ostende by the English, and 4000 English
troops land. The French surround them, take 2000 prisoners and cause
the remainder to reimbark. The English general is seriously wounded.

0901
1 Prairial II Army of the Ardennes. The enemy is defeated at Lobbes
and Erquelinne after a 6-hour fight.

1 Prairial IV Army of Italy. An armistice with the Duke of Modene is
concluded.

1 Prairial VII Birth of Honoré de Balzac, French writer.

0904
4 Prairial II Army of the Rhine. Battle of Schifferstadt, won
by 15,000 Republican troops agains 40,000 Austrians. One
Austrian general is killed.

Army of Moselle. Complete rout of Beaulieu's vanguard.

0905
5 Prairial II Army of the Ardennes. Victory at Merbes-le-Château
after a general charge.

0906
6 Prairial II Army of Moselle. The Saint-Hubert post is taken by the French.

6 Prairial IV Army of Italy. 800 people of Bagnasco revolt, are
attacked and routed; 100 of them are killed and the village is burned.

6 Prairial VI Army of Italy. The Republic of Geneva merges with the
French Republic.

The French troops attack the Haut-Valais insurgents.

0907
7 Prairial II Army of Moselle. The Dinan redoubts and the city itself
are captured.

Army of Eastern Pyrenees. The enemy evacuates the Saint-Elme and
Port-Vendre forts. Collioure is retaken.

7 Prairial III 10,000 Spanish infantry and 1,200 Spanish cavalry 
attack a reco party from the camp on the Pontos highground
but they are routed.

7 Prairial IV Army of Italy. Revolt of Pavie.

7 Prairial V Gracchus Babeuf is executed.

0908
8 Prairial III Treaty of Peace and Alliance signed in The Hague
between the French Republic and the members of Holland's Etats-Generaux.

0911
11 Prairial IV Army of Italy. 5,000 Austrians defeated at Borghetto;
the grenadiers cross the Mincio; the Valeggio village is captured.

0912
12 Prairial II Army of Moselle. The French attack the outposts of the S. Gerard
camp; the coalised are repulsed from most of their outposts.

12 Prairial IV Army of Sambre and Meuse. At midnight, the Republican
troops capture the outposts before Nider-Diebach, and the following
day, they force the enemy to leave the Mannebach defile.

0913
13 Prairial II Army of Moselle. Dinan is taken by the Republican troops.

13 Prairial IV Army of Italy. The Peschiera fortress is captured.

Army of Sambre and Meuse. The Sieg and Acher fieldworks are
captured.

0914
14 Prairial II Army of the Ardennes. The enemy is routed near the
Sainte-Marie woods.

14 Prairial IV Birth of Sadi Carnot, French politician.

0915
15 Prairial II Army of Western Pyrenees. Battle won on several
points; the Republican troops execute a bayonet charge and capture the
Ispeguy camp and the Aldudes and Berdaritz redoubts.

Army of Eastern Pyrenees. Thouzen and Riben captured from the
Spanish troops.

15 Prairial IV Army of Sambre and Meuse. Battle of Altenkirchen; the
enemy routs.

Army of Italy. The French enter Verona.

0916
16 Prairial IV Army of Italy. 600 French grenadiers execute a bayonet
charge and take the S. George suburb and a bridgehead in Mantoue.

The Cherial suburb, its fieldworks and its tower are taken; the
enemy withdraws into Mantoue.

0917
17 Prairial II Army of the Alps. The famous Barricades outpost is
captured; the Army of Alps links with the Army of Italy.

17 Prairial IV Army of Italy. A French column, aiming at Conio lake,
capture and destroys the Fuentes fort.

Army of Sambre and Meuse. Dierdoff and Montabaur captured.

0918
18 Prairial IV Army of Sambre and Meuse. Weilbourg captured.

0919
19 Prairial II Army of Eastern Pyrenees. 4,000 Spanish troops are
defeated by a small number of French troops, beyond la Jonquière;
Bellegarde taken.

The French occupy Campredon and various posts.

0920
20 Prairial IV Army of the Rhine and Moselle. The enemy evacuates
Kayserslautern, Tripstadt, Neustadt and Spire.

0923
23 Prairial II Army of the Alps. 1,500 Piemontese are routed by 200
French troops in the Aosta valley.

Army of Eastern Pyrenees. The French troops conquer Ripoll, and
destroy the smitheries.

23 Prairial VI Army of Orient. Malta island taken.

0924
24 Prairial II Army of Moselle. The Army of Moselle crosses the
Sambre and occupies Charleroy.

United Armies of Moselle, Ardennes and North. Several columns launch a
vigorous offensive which repulses all Charleroy outposts and continue
their victorious advances until Gosselies.

24 Prairial III Army of Sambre and Meuse. Capture of Luxembourg.

0925
25 Prairial VIII Battle of Marengo, Italy. The same day, general Kleber is assassinated in Cairo.

0926
26 Prairial II United Armies of Moselle, Ardennes and North. Near
Charleroy, the French troops capture and destroy a redoubt while under
enemy cannonfire.

Before Charleroy, in less than 10 minutes, the French capture the
redoubt near the Brussels road. The 1st Bas-Rhin battalion repulses a
sortie by the Charleroy garrison.

26 Prairial III Army of Eastern Pyrenees. Battle of Fluvia; 28,000
Spanish troops are routed.

26 Prairial IV Army of Sambre and Meuse. Six grenadier companies
capture Nassau.

Army of the Rhine and Moselle. The Austrian fieldworks between
Franckental and le Rehut are stormed by the French.

0927
27 Prairial IV Army of Sambre and Meuse. Combat near Wetzlar; the
enemy crosses back the Dyle.

0928
28 Prairial II Armies of Moselle, Ardennes and North. Victory against
the coalised near Trassignies.

0929
29 Prairial IV Army of the North. Capture of Ypres.

0930
30 Prairial II Army of the Alps. The Piemontese are defeated at the
Petit St. Bernard.

1001
1 Messidor II Army of Eastern Pyrenees. Campredon captured back, after
a hard fight.

1 Messidor IV Army of Italy. The French enter Reggio and Bologne.
Surrender of Fort Urbain, and the 300-man garrison.
Ferrare and its castle are occupied by the French.

1002
2 Messidor II Army of Eastern Pyrenees. Capture of the posts of
Etoile and Bezalu.

1003
3 Messidor IV Army of Italy. The French attack Beaulieu's outposts and
rout them.

1005
5 Messidor II Army of Western Pyrenees. Battle of Croix
des bouquets, and capture of the posts of Rocher and Dos d'Asne.

Army of Italy. Conclusion of an armistice with the Pope.

1006
6 Messidor IV Army of the Rhine and Moselle. Crossing of the Rhine near
Strasburg; capture of the Kell fort.

1007
7 Messidor II Army of the North, Ardennes, and Moselle. Capture of
Charleroy.

7 Messidor IV Army of the Rhine and Moselle. Capture of Wilstett.

1008
8 Messidor II Army of the North, Ardennes, and Moselle. Memorable
victory of Fleurus, after a 18-hour fight, by 70,000 Republican troops
against 100,000 coalised troops. First use of aerial reco, by 
Captain Coutelle in the balloon "L'Entreprenant".

Army of Eastern Pyrenees. Capture of Belver, and complete rout of the
Spanish troops.

Army of Sambre and Meuse. Substantive advantage over the enemy, at the gates of
Lernes, Marchiennes, Monceau and Souvret.

8 Messidor III Army of the Alps and Italy. A numerous Piemontese corps is
defeated while trying to take Ormea.

8 Messidor IV Army of the Rhine and Moselle. Capture of Offembourg.

1009
9 Messidor IV Army of the Rhine and Moselle. The enemy is repulsed from
Appenwhir and Urtassen.

Army of Italy. The French enter Livourne.

1010
10 Messidor III Army of Western Pyrenees. Capture of the entrenched position at
Deva.

10 Messidor IV Army of the Rhine and Moselle. Battle of Renchen.

1011
11 Messidor IV Army of Italy. The Milan castle capitulates.

1012
12 Messidor XII Birth of George Sand, French writer.

1013
13 Messidor II Army of Sambre and Meuse. Capture of the Roxule
redoubts and camp, of the Mont-Palisel post and the Harve woods post.
Capture of Mons.

Army of the North. Capture of the city and port of Ostende.

1014
Army of the North. The French enter Tournay.

Army of the Rhine. The enemy fieldworks and posts are captured
by the French.

Army of Western Pyrenees. The Republican troops take all the enemy positions
until Lecumbery, and force them to retreat to Yrursum.

Army of the Rhine and Moselle. Attack of the Knubis mountain; capture
of a redoubt at the mountaintop.

Army of Sambre and Meuse. Crossing of the Rhine near Neuwied; capture of
several armed redoubts.

14 Messidor VI
Army of Egypt. The French Army debarks at Alexandria, defeats the
Mamelucks, and conquers Alexandria, Rosette and Cairo.

1015
15 Messidor II Army of Italy. 4,000 Piemontese troops are routed by the
Louano garrison, which expels them from Pietra.

1016
16 Messidor IV Army of Sambre and Meuse. Fight near Willerdorff.

Army of the Rhine and Moselle. Fight of Oss; attack and capture of Baden and
Freudenstatt.

1017
17 Messidor II Army of the North. Capture of Oudenarde and Gand.

17 Messidor IV Army of the Rhine and Moselle. Battle of Rastadt; 
tremendous enemy losses on the battlefield; it is repulsed from
Kupenheim, and must cross back the Murg.

Army of Italy. The Austrians entrenchments are stormed by a bayonet charge,
between the lake of Garde and the Adige river. The Ballone position falls also.

1018
18 Messidor II Army of Sambre and Meuse. 30,000 enemy troops defeated at
Vaterlo, by the 14,000-man French vanguard.

18 Messidor III Army of Western Pyrenees. Fight of Yrursum;
the French infantry charges and defeats the Spanish cavalery.

18 Messidor IV Army of Italy. Several thousands peasants revolt, are
attacked in the Lugo village by a French battalion and are routed.

1019
19 Messidor II Army of Sambre and Meuse. Victory over the 
coalised at Sombref.

19 Messidor IV Fight before Limbourg; the enemy is repulsed within the town.

1020
20 Messidor II Army of Sambre and Meuse. Fierce fight at
Chapelle-Saint-Lambert; the enemy routs.

20 Messidor V Army of Italy. As a result of the conquests of the Army
of Italy, general Bonaparte goes to Milan, and installs the
Cisalpine Republic.

1021
21 Messidor IV Army of Sambre and Meuse. Crossing of the Lahn; the army
marches on Frankfurt and Mayence.

Army of the Rhine and Moselle. Fight before Rastadt and in the defile
before Guersbach; the enemy retreats behind Dourlach.

Army of Sambre and Meuse. Fight before Butzbach, Obermel and
Camberg; capture of Friedberg.

1022
22 Messidor II Army of Sambre and Meuse. The army victoriously enters Brussels.

Army of Western Pyrenees. The French troops capture the Emigrates' camp
near Berdaritz.

22 Messidor IV Army of the Rhine and Moselle. The enemy is repulsed from
Ettlingen, Durlach and Carlsruh.

1024
24 Messidor III Army of Western Pyrenees. Capture of the 
Deybar fortified camp.

1025
25 Messidor I Jean-Paul Marat is assassinated by Charlotte Corday while taking a bath.

25 Messidor II Army of the Rhine. Capture of the posts at Freibach,
Freimersheim, Platzberg mountain and Sankolp mountain.

25 Messidor III Army of Western Pyrenees. Capture of Durango.

1026
26 Messidor II Army of the Rhine. Capture of the
Hoehspire defile, and the French enter Spire and Neustadt.

Army of Italy. Capture of Verttaute by the French.

Army of Moselle. The Tripstadt redoubts and post are taken by a bayonet assault.

Army of the Rhine and Moselle. The Haslach and Haussen posts are taken.

1027
27 Messidor II Army of Sambre and Meuse. The post of the Iron Mountain,
near Louvain, is stormed by the French, who also conquer the town of
Louvain, despite the strong enemy resistance.

Army of the North. Capture of the town of Malines.

1028
28 Messidor II Army of Sambre and Meuse. Capture of Namur.

Army of Italy. 4,500 Austrian troops sortie from Mantoue and are
repulsed back.

Army of Sambre and Meuse. Capture of Francfort.

1029
29 Messidor I Charlotte Corday, murderer of Jean-Paul Marat, is executed.

29 Messidor II Army of the Rhine. Capture of Kayserlauter.

Army of Sambre and Meuse. Surrender of Landrecies, after 6 days.

29 Messidor III The enemy, pressured everywhere, leaves Biscay
and withdraws behind the Ebre; Mictorie and Bilbao taken.

29 Messidor IV Attack and capture of the post of Alpersbach.

Beween the Necker and Kinche rivers, all the enemy posts are attacked
and routed.

Capture of Rheinfelden, Seckingen and the whole Friekthal.

Military reconnaissance by the French on the Aschaffenbourg road.

1030
30 Messidor II Army of the North. Capture of Nieuport, after 5 days.

30 Messidor IV Army of Italy. The Austrian entrenched camp under Mantoue
is attacked; the Austrians are repulsed to the town walls; meanwhile, the 
French start fires in 5 different places of the town.

Army of the Rhine and Moselle. French entry into Stutgard; sustained fight
in Echingen; the French keep the whole left bank of the 
Necker river.

1101
1 Thermidor II Army of Sambre and Meuse. Enemy defeat on the
highgrounds behind Tirlemont.

1103
3 Thermidor II Army of Sambre and Meuse. Enemy rout at Hui: capture
of Saint-Tros.

3 Thermidor III Victory of Hoche at Quiberon against Royalist forces.

1104
4 Thermidor III Peace Treaty between the French Republic and the king
of Spain.

4 Thermidor IV Army of Sambre and Meuse. Capture of Schwinfurt.

1105
5 Thermidor X Birth of Alexandre Dumas the elder, French writer.

1106
6 Thermidor II Army of Eastern Pyrenees. The Republican troops enter
the Bastan valley and bombard Fontarabie.

6 Thermidor IV Army of Sambre and Meuse. Capitulation of the
Wurtsbourg town and citadel.

1108
8 Thermidor II Army of Italy. The French capture the Roccavion
village.

8 Thermidor IV Army of Sambre and Meuse. Capitulation of the
Koenigstein fort.

1109
9 Thermidor I Army of Sambre and Meuse. The French enter Liège.

9 Thermidor II Robespierre's downfall.

1110
10 Thermidor II Army of the North. Capture of Cassandria and crossing
of the Cacysche.

10 Thermidor II Robespierre and several of his followers (Couthon, Saint-Just, etc) are beheaded.

1111
11 Thermidor III Army of the Alps and Italy. Assault on the redoubts
of the di Pietri field.

11 Thermidor IV Army of Sambre and Meuse. Sortie by the Mayence
garrison: the enemy is repulsed.

1112
12 Thermidor II Army of Western Pyrenees. Conquest of the Bastan
valley. Capture of the Figuier fort and Fontarabie.

1113
13 Thermidor IV Army of Italy. Austrian defeat at Solo. The enemy is
beaten at Lonado.

1114
Army of Italy. Brescia taken back.

14 Thermidor VII Birth of Sophie Rostopchine, later known as countess of Ségur.

1115
15 Thermidor IV Army of Sambre and Meuse. Capture of Koenigshoffen.

1116
16 Thermidor II Army of Western Pyrenees. The French troops conquer
the Ernani post, the San Sebastian town and its fortress.

16 Thermidor IV Army of the Rhine and Moselle. Capture of the
Heidenheim post.

Army of Italy. Complete Austrian defeat; Solo, Lonado and Castiglione
taken back.

1117
17 Thermidor IV Army of Italy. Capture of Saint-Ozeto. A French
battalion marches on Gavardo and overcomes the enemy. An enemy column
is defeated at Gavardo.

Army of Sambre and Meuse. Capture of Bamberg.

1118
18 Thermidor IV Army of Italy. Wurmser's army, arrayed between the
Solferino village and the Chiesa river, is routed.

1119
19 Thermidor IV The enemy entrenched behind the Mincio, between
Peschiera and Mantoue, is attacked, routs and lifts the siege of
Peschiera.

Army of Sambre and Meuse. Fight at Altendorff.

1120
20 Thermidor IV Army of Italy. The French occupy their former
positions, cross the Mincio and enter Vérone.

1121
21 Thermidor II Army of Moselle. Capture of the fieldworks on the
Pelingen highgrounds. The French storm the Vasserbilich bridge.

Army of the Rhine and Moselle. The enemy evacuates Neresheim.

Army of Sambre and Meuse. Fight on the Rednitz; capture of Forscheim.

1122
22 Thermidor II Army of Moselle. The French enter Trier.

Army of Western Pyrenees. Capture of Toloza.

1123
23 Thermidor IV Army of Italy. The French reoccupy their positions
before Mantoue.

1124
24 Thermidor IV Army of Italy. The French attack the enemy at Corona
and Montebaldo; they take these posts and Preabolo.

Army of the Rhine and Moselle. Battle of Heidenheim, after a 17-hour
fight; the enemy withdraws behind the Vernitz.

Army of Sambre and Meuse. Capture of the Rhotemberg fort.

Army of the Rhine and Moselle. The French enter Bregentz.

1125
25 Thermidor IV Army of Italy. The enemy is attacked at
Roque-Danfonce and Lodron. Another French column crosses the Adige,
pushes the enemy to Roveredo.

1126
26 Thermidor II Army of Western Pyrenees. The Spanish troops lose
several posts, as well as the redoubt of Alloqui.

Army of Eastern Pyrenees. French victory near St.-Laurent de la
Mouga. 15,000 Spanish troops defeated at Rocaseins by 4,000 Republican
troops.

1128
28 Thermidor II Army of Sambre and Meuse. Le Quesnoy taken back.

28 Thermidor IV Capture of Neumarch.

1129
29 Thermidor IV Peace treaty between the French Republic and the duke
of Wurtemberg.

1130
30 Thermidor IV Army of Sambre and Meuse. The enemy is repulsed from
the Sulzbach highground.

Battle of Poperg and Leinfeld, capture of Castel.

1202
2 Fructidor IV Army of Italy. The Wurmser army retreats behind Trente
after burning its navy on the lake of Garda.

1206
6 Fructidor VI Expedition of Ireland. The French troops land
in Ireland and conquer Killala.

1207
7 Fructidor IV Army of Italy. Capture of Borgoforte and Governolo.

Army of the Rhine and Moselle. Fight at Friedberg, the French troops
swim across the Lech. The enemy is repulsed and routed.

7 Fructidor VI Alliance Treaty between the French and Helvetic
Republics.

1208
8 Fructidor III Army of the Alps and Italie. Victory against a numerous
Piemontese corps.

1209
9 Fructidor II Army of the North. Capture of the Ecluse fort.

1210
10 Fructidor II Army of Sambre and Meuse. The Anzain village and the
posts and redoubt near Valenciennes are taken by a bayonet charge.

Valenciennes is taken back.

10 Fructidor VI Expedition of Ireland. The French troops in Ireland
attack general Lack in Castlebar and make him flee.

1211
11 Fructidor II Army of Western Pyrenees. 7000 Spanish troops
defeated in Eibon. Spanish rout at Ermilla.
4000 enemy rout and the French troops enter Ondoroa.

1213
13 Fructidor II Army of Sambre and Meuse. Condé taken back.

1214
14 Fructidor III Army of the Alps and Italy. 4,000 Piemontese troops
intending to attack Mont-Geneve are routed.

14 Fructidor IV Peace treaty between the French Republic and the
Margrave of Baden.

1215
15 Fructidor III Army of the Alps and Italy. 1500 Piemontese troops,
intending to attack the Cerise post, are defeated.

15 Fructidor III Peace treaty between the Republic French and the
Landgrave of Hesse-Cassel.

1216
16 Fructidor II Army of Moselle. Intense Fight near Sandweiller.

1217
17 Fructidor IV Army of the Rhine and Moselle. The enemy is beaten
everywhere between Ingolstaldt and Fresing.

1218
18 Fructidor II Army of Western Pyrenees. 6,000 Spanish troops
defeated by 600 French troops in the Aspe Valley.

The Spanish are routed by the Lescun outposts.

18 Fructidor IV Army of Italy. French attack on Santo-Marco. The
enemy, repulsed from Pieve and Roveredo, retires to the la Pietra
castle.

Army of the Rhine and Moselle. The Philisbourg and Manheim garrisons
are repulsed until the Philisbourg walls.

18 Fructidor V Coup against the royalist faction.

1219
19 Fructidor III Army of Sambre and Meuse. The army left wing crosses
the Rhine. The enemy is repulsed from all its fieldworks.

Capture of Keyserwerth with its artillery and capture of Dusseldorff.

1221
21 Fructidor I Army of the North. Battle of Honscoote.

Army of the Ardennes. The enemy leaves the Hastieres posts.

Army of Italy. Complete rout of the Piemontese, repulsed from the
Brouis-Hutel and Levenzo posts.

21 Fructidor IV
Army of the Rhine and Moselle. Armistice signed with the Prince of Bavaria
and Palatinate.

The center's vanguard encounters the enemy at Mainbourg, and
pushes it.

Army of Italy. Attack of the Primolac fortified camp; the enemy
flees, rallies in the Coveto fort and leaves it.

1222
22 Fructidor I Army of the North. The Duke of York flees in a hurry.
40,000 English, Hessian and allied troops retreat and lift the Dunkirk
blockade.

22 Fructidor IV Army of Italy. The enemy is expelled from the right
bank of the Brenta river and withdraws to Bassano; The Republican troops
fight them before the town. The enemy routs and is pursued until
Citadella.

1223
23 Fructidor VI Army in Helvetia. Skirmish in Stanz; the Swiss are
routed.

1224
24 Fructidor I Army of the Alps. French advantage in the plain of
Aigue-Belles.

24 Fructidor III Army of Sambre and Meuse. The French army crosses the
Rhine in front of the enemy, which opposes the crossing to no avail.
The enemy is repulsed beyond Dusseldorff.

1225
25 Fructidor I Army of the Rhine. The enemy is attacked and repulsed
at every position near Lauterbourg.

1226
26 Fructidor I Army of the North. Fight at Werwick and Comines.

26 Fructidor II Army of Moselle. Fight before Courteren.

26 Fructidor IV Army of the Rhine and Moselle. Fight at Kamlach; the
enemy is repulsed to Mindelheim.

26 Fructidor V Peace treaty signed between the French Republic and the
Queen of Portugal.

1227
27 Fructidor I Army of the Alps. The enemy is expelled from the
Belleville highgrounds; capture of the Epierre redoubt and fieldworks.

27 Fructidor III Army of Sambre and Meuse. Fight at Enef and Hanleshorn.

27 Fructidor IV Army of Italy. Capture of Porto-Tegnago.

1228
28 Fructidor I Army of the Rhine. Capture of the
fortified camp at Nothweiller.

28 Fructidor II Army of the Alps. The enemy is expelled by the French
troops from the Chenal, Sambuck et Prati camps, and from other posts.

1229
29 Fructidor IV Army of Italy. Battle of S. Georges; the enemy,
beaten everywhere, must withdraw into Mantoue.

1230
30 Fructidor I Army of the West. Republican victory over the Vendean
rebels, near Montaigu.

Army of Western Pyrenees. The French prevail over the Spanish at
Urdach, in the Bastan valley.

30 Fructidor II Army of the North. Complete enemy rout at Boxtel.

30 Fructidor IV Army of Sambre and Meuse. Fight and capture of
Altenkirchen; the enemy withdraws to the Lahn river.

1301
1 additional day I Army of Eastern Pyrenees. The Verret post
is recaptured. Bellegarde recaptured, it was the last
enemy-occupied place in France.

1302
2 additional day I Army of Eastern Pyrenees. The French troops take
Sterry.

2 additional day II Army of Sambre and Meuse. Victory on the whole
French army front, from Maseick to Sprimont.

Capture of Lauwfeld, Emale and Montenack; crossing of Ourte and
Laywale.

2 additional day IV Army of the Rhine and Moselle. The enemy attacks
the Kehl fort in vain.

1303
3 additional day III Army of Sambre and Meuse. Fight on the Lahn
river; capture of Limbourg, Dietz and Nasseau.

Army of Italy. Austrian defeat on the Borghetto line.

3 additional day V Death of general Hoche, general-in-chief of 
the Army of Sambre and Meuse.

1304
4 additional day I Army of Western Pyrenees. Capture of Villefranche
and the Prades camp.

Capture of Escalo and Uaborsy, which were occupied by Spanish troops.

4 additional day II Army of Sambre and Meuse. The Clermont highgrounds
are stormed, after 7 successive attacks.

Army of Italy. Victory at Cairo over the Piemontese, supported by
10,000 Austrians.

4 additional day III Surrender of Manheim.

1305
5 additional day II Army of Western Pyrenees. Spanish troops at
Mont-Roch are routed.

5 additional day IV Death of general Marceau, aged 27, killed at
Altenkirchen by a carbine shot.
EVENTS
  delete $event{dummy};
}

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
"Ah ! ça ira ! ça ira !";

__END__

=encoding utf8

=head1 NAME

DateTime::Calendar::FrenchRevolutionary::Locale::en -- English localization for the French 
revolutionary calendar.

=head1 SYNOPSIS

  use DateTime::Calendar::FrenchRevolutionary::Locale;
  my $english_locale = DateTime::Calendar::FrenchRevolutionary::Locale->load('en');

  my $english_month_name =$english_locale->month_name($date);

=head1 DESCRIPTION

This module provides localization for DateTime::Calendar::FrenchRevolutionary.
Usually, its methods will be invoked only from DT::C::FR.

The month  names come  from Thomas Carlyle's  book. Most of  the feast
names  come from Alan  Taylor's kokogiak.com  web site,  later checked
with  Wikipedia  and   with  Jonathan  Badger's  French  Revolutionary
Calendar module written in Ruby.  The day names are from this module's
author.

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

Returns an English translation for C<$date>'s month, where C<$date> is
a C<DateTime::Calendar::FrenchRevolutionary> object.

=item * month_abbreviation ($date)

Returns a 3-letter abbreviation for the English month name.

=item * day_name ($date)

Returns an English translation for the day name.

=item * day_abbreviation ($date)

Returns a 3-letter abbreviation for the English day name.

=item * feast_short ($date)

Hopefully  returns  an adequate  English  translation  for the  plant,
animal or tool that correspond to C<$date>'s feast.

Note: in some cases, the feast French name is left untranslated, while
in some other cases, the  translation is inadequate. If you are fluent
in both French and English, do not hesitate to send corrections to the
author.

=item * feast_long ($date)

Same  as  C<feast_short>, with  a  "day"  suffix,  as in  the  current
calendar's "groundhog day" or "Colombus day".

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

The French Revolution, Thomas Carlyle, Oxford University Press

Calendrier Militaire, anonymous

=head2 Internet

L<http://datetime.perl.org/>

L<https://www.allhotelscalifornia.com/kokogiakcom/frc/default.asp>

L<https://github.com/jhbadger/FrenchRevCal-ruby>

L<https://en.wikipedia.org/wiki/French_Republican_Calendar>

=head1 LICENSE STUFF

Copyright (c)  2003, 2004, 2010,  2012, 2014, 2016, 2019  Jean Forget.
All  rights  reserved.   This  program  is  free   software.  You  can
distribute,      adapt,     modify,      and     otherwise      mangle
DateTime::Calendar::FrenchRevolutionary under  the same terms  as perl
5.16.3.

This program is  distributed under the same terms  as Perl 5.16.3: GNU
Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<https://dev.perl.org/licenses/artistic.html> and
L<https://www.gnu.org/licenses/old-licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You  should have received  a copy  of the  GNU General  Public License
along with this program; if not, see <https://www.gnu.org/licenses/> or
write to the Free Software Foundation, Inc., L<https://www.fsf.org>.

=cut
