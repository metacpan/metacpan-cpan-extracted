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
package App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it;
$App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it::VERSION = '0.51';
# ABSTRACT: Italian localization of (part of) L<DateTime::Calendar::FrenchRevolutionary>

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale';

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;


has '+months' => (
  default => sub {[
    'Vendemmiaio', 'Brumaio',   'Frimaio',
    'Nevoso',      'Piovoso',   'Ventoso',
    'Germile',     'Fiorile',   'Pratile',
    'Messidoro',   'Termidoro', 'Fruttidoro',
    'giorni supplementari',
  ]},
);

has '+decade_days' => (
  default => sub {[
    'Primidì',
    'Duodì',
    'Tridì',
    'Quartidì',
    'Quintidì',
    'Sestidì',
    'Settidì',
    'Ottidì',
    'Nonidì',
    'Decadì',
  ]},
);

has '+feast' => (
  default => sub {[
    # Vendémiaire https://it.wikipedia.org/wiki/Vendemmiaio
    qw(
      2uva             1zafferano    3castagna        0colchico    0cavallo
      3balsamina       3carota       2amaranto        3pastinaca   0tino
      3patata          0perpetuino   3zucca           3reseda      2asino
      3bella_di_notte  3zucca        0grano_saraceno  0girasole    0torchio
      3canapa          0pesca        3rapa            2amarillide  0bue
      3melanzana       0peperoncino  0pomodoro        2orzo        0barile
    ),
    # Brumaire https://it.wikipedia.org/wiki/Brumaio
    qw(
      0mela            0sedano            3pera         3barbabietola  2oca
      2eliotropio      0fico              3scorzonera   0ciavardello   2aratro
      3barba_di_becco  3castagna_d'acqua  0topinambur   2indivia       0tacchino
      0sisaro          0crescione         3piombaggine  0melograno     2erpice
      0baccaro         2azzeruolo         3robbia       2arancia       0fagiano
      0pistacchio      3cicerchia         0cotogno      0sorbo         0rullo
    ),
    # Frimaire https://it.wikipedia.org/wiki/Frimaio
    qw(
      0raponzolo          3rapa        3cicoria  0nespolo  0maiale
      0soncino            0cavolfiore  0miele    0ginepro  3zappa
      3cera               0rafano      0cedro    2abete    0capriolo
      0ginestrone         0cipresso    3edera    3sabina   3ascia
      2acero_da_zucchero  2erica       3canna    2acetosa  0grillo
      0pino               0sughero     0tartufo  2oliva    3pala
    ),
    # Nivôse https://it.wikipedia.org/wiki/Nevoso
    qw(
      3torba    0carbone_bituminoso  0bitume   0zolfo     0cane
      3lava     3terra_vegetale      0letame   0salnitro  0correggiato
      0granito  3argilla             2ardesia  2arenaria  0coniglio
      3selce    3marna               0calcare  0marmo     0setaccio
      0gesso    0sale                0ferro    0rame      0gatto
      0stagno   0piombo              0zinco    0mercurio  0colino
    ),
    # Pluviôse https://it.wikipedia.org/wiki/Piovoso
    qw(
      3dafne_laurella  0muschio          0pungitopo  0bucaneve    0toro
      0viburno         0fungo_dell'esca  3camalea    0pioppo      1scure
      0elleboro        0broccolo         2alloro     0nocciolo    3vacca
      0bosso           0lichene          0tasso      3polmonaria  0coltello_da_potatura
      0thlaspi         3dafne_odorosa    3gramigna   0centinodio  3lepre
      0guado           0nocciolo         0ciclamino  3celidonia   3slitta
    ),
    # Ventôse https://it.wikipedia.org/wiki/Ventoso
    qw(
      3tossillagine    0corniolo    3violacciocca  0ligustro    0caprone
      0baccaro_comune  2alaterno    3violetta      0salicone    3vanga
      0narciso         2olmo        3fumaria       2erisimo     3capra
      0spinacio        0doronico    3primula       0cerfoglio   3corda
      3mandragola      0prezzemolo  3coclearia     3margherita  0tonno
      0dente_di_leone  2anemone     0capelvenere   0frassino    0piantatoio
    ),
    # Germinal https://it.wikipedia.org/wiki/Germinale
    qw(
      3primula          0platano  2asparago            0tulipano   3gallina
      3bietola          3betulla  0narciso             0ontano     3covata
      3pervinca         0carpino  3spugnola            0faggio     2ape
      3lattuga          0larice   3cicuta              0ravanello  2arnia
      2albero_di_Giuda  3lattuga  0ippocastano         3rucola     0piccione
      0lillà            2anemone  3viola_del_pensiero  0mirtillo   0coltello_da_innesto
    ),
    # Floréal https://it.wikipedia.org/wiki/Fiorile
    qw(
      3rosa                3quercia         3felce                0biancospino  0usignolo
      2aquilegia           0mughetto        0fungo                0giacinto     0rastrello
      0rabarbaro           3lupinella       3violacciocca_gialla  3lonicera     0baco_da_seta
      3consolida_maggiore  3pimpinella      2alisso_sassicolo     2atriplice    0sarchiello
      3statice             3fritillaria     3borragine            3valeriana    3carpa
      3fusaggine           3erba_cipollina  3buglossa             0senape       0vincastro
    ),
    # Prairial https://it.wikipedia.org/wiki/Pratile
    qw(
      3erba_medica  2emerocallide     0trifoglio         2angelica       2anatra
      3melissa      2avena_altissima  0giglio_martagone  0timo_serpillo  3falce
      3fragola      3betonica         0pisello           3acacia         3quaglia
      0garofano     0sambuco          0papavero          0tiglio         0forcone
      0fiordaliso   3camomilla        0caprifoglio       0caglio         3tinca
      0gelsomino    3verbena          0timo              3peonia         0carro
    ),
    # Messidor https://it.wikipedia.org/wiki/Messidoro
    qw(
      3segale      2avena     3cipolla       3veronica  0mulo
      0rosmarino   0cetriolo  1scalogno      2assenzio  0falcetto
      0coriandolo  0carciofo  3violacciocca  3lavanda   0camoscio
      0tabacco     0ribes     3cicerchia     3ciliegia  2ovile
      3menta       0cumino    0fagiolo       2alcanna   3faraona
      3salvia      2aglio     3veccia        0grano     3ciaramella
    ),
    # Thermidor https://it.wikipedia.org/wiki/Termidoro
    qw(
      1spelto          0tasso_barbasso  0melone      0loglio    2ariete
      2equiseto        2artemisia       0cartamo     3mora      2annaffiatoio
      2eringio         3salicornia      2albicocca   0basilico  3pecora
      2altea           0lino            3mandorla    3genziana  3chiusa
      3carlina_bianca  0cappero         3lenticchia  2enula     3lontra
      0mirto           3colza           0lupino      0cotone    0mulino
    ),
    # Fructidor https://it.wikipedia.org/wiki/Fruttidoro
    qw(
      3prugna         0miglio       3vescia      2orzo_maschio      0salmone
      3tuberosa       2orzo_comune  2apocino     3liquirizia        3scala
      3anguria        0finocchio    3crespino    0noce              3trota
      0limone         0cardo        2alaterno    0garofano_d'India  3gerla
      3rosa_canina    3nocciola     0luppolo     0sorgo             0gambero
      2arancio_amaro  3verga_d'oro  0granoturco  3castagna          3cesta
    ),
    # Jours complémentaires
    qw(
      3virtù        0genio  0lavoro  2opinione  4ricompense
      3rivoluzione
    ),
  ]},
);

has '+prefixes' => (
  default => sub {[
    'giorno del ',
    'giorno dello ',
    "giorno dell'",
    'giorno della ',
    'giorno delle '
  ]},
);

has '+suffix' => (
  default => '',
);

has '+wikipedia_entries' => (
  default => sub {{
    1 => {
      'zafferano'       => 'Crocus_sativus',
      'colchico'        => 'Colchicum',
      'balsamina'       => 'Impatiens',
      'carota'          => 'Daucus_carota',
      'amaranto'        => 'Amaranthus',
      'pastinaca'       => 'Pastinaca_(botanica)',
      'tino'            => 'Tino_(vinificazione)',
      'patata'          => 'Solanum_tuberosum',
      'perpetuino'      => 'Helichrysum_stoechas',
      'asino'           => 'Equus_asinus',
      'bella di notte'  => 'Mirabilis_jalapa',
      'torchio'         => 'Torchio_vinario',
      'canapa'          => 'Cannabis',
      'pesca'           => 'Prunus_persica#Frutto',
      'rapa'            => 'Brassica_rapa_rapa',
      'amarillide'      => 'Amaryllis',
      'bue'             => 'Bos_taurus',
      'melanzana'       => 'Solanum_melongena',
      'pomodoro'        => 'Solanum_lycopersicum',
      'orzo'            => 'Hordeum_vulgare',
      'barile'          => 'Botte',
    },
    2 => {
      'sedano'           => 'Apium_graveolens',
      'barbabietola'     => 'Beta_vulgaris',
      'fico'             => 'Ficus',
      'ciavardello'      => 'Sorbus_torminalis',
      'barba_di_becco'   => 'Tragopogon',
      "castagna_d'acqua" => 'Trapa_natans',
      'topinambur'       => 'Helianthus_tuberosus',
      'indivia'          => 'Cichorium_endivia',
      'tacchino'         => 'Meleagris',
      'sisaro'           => 'Sium_sisarum',
      'crescione'        => 'Lepidium_sativum',
      'melograno'        => 'Punica_granatum',
      'baccaro'          => 'Baccharidinae',
      'azzeruolo'        => 'Crataegus_azarolus',
      'robbia'           => 'Rubia',
      'arancia'          => 'Citrus_sinensis',
      'fagiano'          => 'Phasianidae',
      'pistacchio'       => 'Pistacia_vera',
      'cicerchia'        => 'Lathyrus',
      'cotogno'          => 'Cydonia_oblonga',
      'sorbo'            => 'Sorbus_domestica',
      'rullo'            => 'Rullo_compattatore',
    },
    3 => {
      'raponzolo'         => 'Phyteuma',
      'rapa'              => 'Brassica_rapa_rapa',
      'cicoria'           => 'Cichorium_intybus',
      'nespolo'           => 'Mespilus_germanica',
      'maiale'            => 'Sus_scrofa_domesticus',
      'soncino'           => 'Valerianella_locusta',
      'cavolfiore'        => 'Brassica_oleracea_var._botrytis',
      'ginepro '          => 'Juniperus',
      'zappa'             => 'Zappa_(attrezzo)',
      'rafano'            => 'Armoracia_rusticana',
      'cedro'             => 'Cedrus',
      'abete'             => 'Abies',
      'capriolo'          => 'Capreolus_capreolus',
      'ginestrone'        => 'Ulex',
      'cipresso'          => 'Cupressus',
      'sabina'            => 'Juniperus',
      'acero_da_zucchero' => 'Acer_saccharum',
      'canna'             => 'Arundo_donax',
      'acetosa'           => 'Rumex_acetosa',
      'grillo'            => 'Gryllidae',
      'pino'              => 'Pinus',
      'tartufo'           => 'Tuber_(micologia)',
      'pala'              => 'Pala_(attrezzo)',
    },
    4 => {
      'carbone_bituminoso' => 'Carbone#Litantrace',
      'cane'               => 'Canis_lupus_familiaris',
      'terra_vegetale'     => 'Humus',
      'salnitro'           => 'Nitrato_di_potassio',
      'marna'              => 'Marna_(roccia)',
      'gesso'              => 'Gesso_(minerale)',
      'sale'               => 'Cloruro_di_sodio',
      'gatto'              => 'Felis_silvestris_catus',
      'stagno'             => 'Stagno_(elemento_chimico)',
      'mercurio'           => 'Mercurio_(elemento_chimico)',
    },
    5 => {
      'dafne_laurella'       => 'Daphne_laureola',
      'muschio'              => 'Bryophyta',
      'pungitopo'            => 'Ruscus_aculeatus',
      'bucaneve'             => 'Galanthus_nivalis',
      'toro'                 => 'Bos_taurus',
      'viburno'              => 'Viburnum',
      "fungo_dell'esca"      => 'Fomes_fomentarius',
      'camalea'              => 'Daphne_mezereum',
      'pioppo'               => 'Populus',
      'elleboro'             => 'Helleborus',
      'broccolo'             => 'Brassica_oleracea',
      'alloro'               => 'Laurus_nobilis',
      'nocciolo'             => 'Corylus_avellana',
      'vacca'                => 'Bos_taurus',
      'bosso'                => 'Buxus',
      'tasso'                => 'Taxus',
      'polmonaria'           => 'Pulmonaria_officinalis',
      'coltello_da_potatura' => 'Falcetto',
      'dafne_odorosa'        => 'Daphne_gnidium',
      'gramigna'             => 'Cynodon_dactylon',
      'centinodio'           => 'Polygonum_aviculare',
      'lepre'                => 'Lepus_europaeus',
      'guado'                => 'Isatis_tinctoria',
      'nocciolo'             => 'Corylus_avellana',
      'ciclamino'            => 'Cyclamen',
      'celidonia'            => 'Chelidonium_majus',
    },
    6 =>  {
      'tossillagine'   => 'Tussilago_farfara',
      'corniolo'       => 'Cornus_mas',
      'violacciocca'   => 'Matthiola_incana',
      'ligustro'       => 'Ligustrum',
      'caprone'        => 'Caprinae',
      'baccaro_comune' => 'Asarum_europaeum',
      'alaterno'       => 'Rhamnus_alaternus',
      'violetta'       => 'Viola_(botanica)',
      'salicone'       => 'Salix_caprea',
      'narciso'        => 'Narcissus',
      'olmo'           => 'Ulmus',
      'erisimo'        => 'Sisymbrium_officinale',
      'capra'          => 'Capra_(zoologia)',
      'spinacio'       => 'Spinacia_oleracea',
      'doronico'       => 'Doronicum',
      'cerfoglio'      => 'Anthriscus_cerefolium',
      'mandragola'     => 'Mandragora',
      'prezzemolo'     => 'Petroselinum_crispum',
      'coclearia'      => 'Armoracia_rusticana',
      'margherita'     => 'Bellis_perennis',
      'tonno'          => 'Thunnus',
      'dente_di_leone' => 'Taraxacum_officinale',
      'capelvenere'    => 'Adiantum_capillus-veneris',
      'frassino'       => 'Fraxinus',
    },
    7 => {
      'platano'             => 'Platanus',
      'asparago'            => 'Asparagus_officinalis',
      'tulipano'            => 'Tulipa',
      'gallina'             => 'Gallus_gallus_domesticus',
      'betulla'             => 'Betula',
      'narciso'             => 'Narcissus',
      'ontano'              => 'Alnus',
      'covata'              => 'Incubatrice_(zootecnia)',
      'pervinca'            => 'Vinca',
      'carpino'             => 'Carpinus',
      'spugnola'            => 'Morchella',
      'faggio'              => 'Fagus',
      'ape'                 => 'Apis',
      'lattuga'             => 'Lactuca_sativa',
      'larice'              => 'Larix',
      'ravanello'           => 'Raphanus_sativus',
      'albero_di_Giuda'     => 'Cercis_siliquastrum',
      'lattuga'             => 'Lactuca_sativa',
      'ippocastano'         => 'Aesculus_hippocastanum',
      'rucola'              => 'Eruca_vesicaria',
      'piccione'            => 'Columba_livia',
      'lillà'               => 'Syringa',
      'viola_del_pensiero'  => 'Viola_tricolor',
      'mirtillo'            => 'Vaccinium',
      'coltello_da_innesto' => 'Innesto',
    },
    8 => {
      'rosa'                => 'Rosa_(botanica)',
      'quercia'             => 'Quercus',
      'felce'               => 'Pteridophyta',
      'biancospino'         => 'Crataegus_monogyna',
      'usignolo'            => 'Luscinia_megarhynchos',
      'mughetto'            => 'Convallaria_majalis',
      'fungo'               => 'Fungi',
      'giacinto'            => 'Hyacinthus',
      'rabarbaro'           => 'Rheum',
      'lupinella'           => 'Lupinus',
      'violacciocca_gialla' => 'Erysimum_bonannianum',
      'baco_da_seta'        => 'Bombyx_mori',
      'consolida_maggiore'  => 'Symphytum_officinale',
      'pimpinella'          => 'Pimpinella_major',
      'alisso_sassicolo'    => 'Alyssum',
      'atriplice'           => 'Atriplex_hortensis',
      'sarchiello'          => 'Sarchiatura',
      'statice'             => 'Armeria_(botanica)',
      'borragine'           => 'Borago_officinalis',
      'carpa'               => 'Cyprinus_carpio',
      'fusaggine'           => 'Euonymus_europaeus',
      'erba_cipollina'      => 'Allium_schoenoprasum',
      'buglossa'            => 'Anchusa',
    },
    9 => {
      'erba_medica'      => 'Medicago_sativa',
      'emerocallide'     => 'Hemerocallis',
      'trifoglio'        => 'Trifolium',
      'angelica'         => 'Angelica_(botanica)',
      'melissa'          => 'Melissa_(botanica)',
      'avena_altissima'  => 'Arrhenatherum_elatius',
      'giglio_martagone' => 'Lilium_martagon',
      'timo_serpillo'    => 'Thymus_serpyllum',
      'falce'            => 'Falce_(attrezzo)',
      'betonica'         => 'Stachys_officinalis',
      'pisello'          => 'Pisum_sativum',
      'quaglia'          => 'Coturnix_coturnix',
      'garofano'         => 'Dianthus_caryophyllus',
      'sambuco'          => 'Sambucus',
      'papavero'         => 'Papaver',
      'tiglio'           => 'Tilia',
      'forcone'          => 'Forca_(attrezzo)',
      'fiordaliso'       => 'Centaurea_cyanus',
      'camomilla'        => 'Matricaria_chamomilla',
      'caprifoglio'      => 'Lonicera',
      'caglio'           => 'Galium',
      'tinca'            => 'Tinca_tinca',
      'gelsomino'        => 'Jasminum',
      'verbena'          => 'Verbena_(botanica)',
      'timo'             => 'Thymus',
      'peonia'           => 'Paeonia',
      'carro'            => 'Carro_(trasporto)',
    },
    10 => {
      'segale'       => 'Secale_cereale',
      'avena'        => 'Avena_sativa',
      'cipolla'      => 'Allium_cepa',
      'veronica'     => 'Veronica_(botanica)',
      'rosmarino'    => 'Rosmarinus_officinalis',
      'cetriolo'     => 'Cucumis_sativus',
      'scalogno'     => 'Allium_ascalonicum',
      'assenzio'     => 'Artemisia_absinthium',
      'coriandolo'   => 'Coriandrum_sativum',
      'carciofo'     => 'Cynara_scolymus',
      'violacciocca' => 'Matthiola_incana',
      'lavanda'      => 'Lavandula',
      'camoscio'     => 'Rupicapra',
      'cicerchia'    => 'Lathyrus',
      'menta'        => 'Mentha',
      'cumino'       => 'Cuminum_cyminum',
      'fagiolo'      => 'Phaseolus_vulgaris',
      'alcanna'      => 'Alkanna_tinctoria',
      'faraona'      => 'Numida_meleagris',
      'aglio'        => 'Allium_sativum',
      'veccia'       => 'Vicia_sativa',
      'grano'        => 'Triticum',
    },
    11 => {
      'spelto'         => 'Triticum_spelta',
      'tasso_barbasso' => 'Verbascum_thapsus',
      'melone'         => 'Cucumis_melo',
      'loglio'         => 'Lolium',
      'ariete'         => 'Ovis_aries',
      'equiseto'       => 'Equisetum',
      'cartamo'        => 'Carthamus_tinctorius',
      'mora'           => 'Rubus_ulmifolius',
      'eringio'        => 'Panicum',
      'basilico'       => 'Ocimum_basilicum',
      'pecora'         => 'Ovis_aries',
      'altea'          => 'Althaea_officinalis',
      'lino'           => 'Linum_usitatissimum',
      'genziana'       => 'Gentiana',
      'chiusa'         => 'Chiusa_(ingegneria)',
      'carlina_bianca' => 'Carlina',
      'cappero'        => 'Capparis_spinosa',
      'lenticchia'     => 'Lens_culinaris',
      'enula'          => 'Inula',
      'lontra'         => 'Lutrinae',
      'mirto'          => 'Myrtus',
      'colza'          => 'Brassica_napus',
      'lupino'         => 'Lupinus',
      'cotone'         => 'Cotone_(fibra)',
    },
    12 => {
      'prugna'           => 'Prunus_domestica',
      'miglio'           => 'Panicum_miliaceum',
      'vescia'           => 'Lycoperdon_perlatum',
      'orzo_maschio'     => 'Hordeum',
      'salmone'          => 'Salmonidae',
      'tuberosa'         => 'Polianthes',
      'orzo_comune'      => 'Hordeum_vulgare',
      'apocino'          => 'Asclepiadoideae',
      'liquirizia'       => 'Glycyrrhiza_glabra',
      'scala'            => 'Scala_(utensile)',
      'anguria'          => 'Citrullus_lanatu',
      'finocchio'        => 'Foeniculum_vulgare',
      'crespino'         => 'Berberis_vulgaris',
      'noce'             => 'Noce_(frutto)',
      'limone'           => 'Citrus_limon',
      'cardo'            => 'Carduus',
      'alaterno'         => 'Rhamnus_alaternus',
      "garofano_d'India" => 'Tagetes',
      'luppolo'          => 'Humulus_lupulus',
      'sorgo'            => 'Sorghum_vulgare',
      'arancio_amaro'    => 'Citrus_×_aurantium',
      "verga_d'oro"      => 'Solidago_virgaurea',
      'granoturco'       => 'Zea_mays',
      'cesta'            => 'Cesto',
    },
    13 => {
      'genio'       => 'Genio_(filosofia)',
      'ricompense'  => 'Sistema_di_ricompensa',
      'rivoluzione' => 'Rivoluzione_francese',
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

App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it - Italian localization of (part of) L<DateTime::Calendar::FrenchRevolutionary>

=head1 VERSION

version 0.51

=head1 DESCRIPTION

This modules adds Italian translations to L<DateTime::Calendar::FrenchRevolutionary>, based on Wikipedia: L<https://it.wikipedia.org/wiki/Calendario_rivoluzionario_francese>.

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

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

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
