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
package App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es;
$App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es::VERSION = '0.27';
# ABSTRACT: French localization of (part of) L<DateTime::Calendar::FrenchRevolutionary::Locale::fr>

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale';

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;


has '+months' => (
  default => sub {[
    'Vendemiario', 'Brumario',  'Frimario',
    'Nivoso',      'Pluvioso',  'Ventoso',
    'Germinal',    'Floreal',   'Pradial',
    'Mesidor',     'Termidor',  'Fructidor',
    'día complementario',
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
      1uva             0azafrán          1castaña   1cólquida  0caballo
      1balsamina       1zanahoria        0amaranto  1chirivía  1tinaja
      1patata          1flor_de_papel    1calabaza  1reseda    0asno
      1bella_de_noche  1calabaza_otoñal  0alforfón  0girasol   0lagar
      0cáñamo          0melocotón        0nabo      1amarilis  0buey
      1berenjena       0pimiento         0tomate    1cebada    0barril
    ),
    # Brumaire
    qw(
      1manzana     0apio                1pera         1remolacha  1oca
      0heliótropo  0higo                1escorzonera  0mostajo    0arado
      1salsifí     1castaña_de_agua     0tupinambo    1endibia    0guajolote
      1escaravía   0berro               1dentelaria   1granada    1grada
      1bacante     0acerolo             1rubia_roja   1naranja    0faisán
      0pistacho    0lathyrus_tuberosus  0membrillo    0serbal     0rodillo
    ),
    # Frimaire
    qw(
      0rapónchigo  0nabo_forrajero  1achicoria  0níspero   0cerdo
      0canónigo    1coliflor        1miel       0enebro    0pico
      1cera        0rábano_picante  0cedro      0abeto     0corzo
      0tojo        1ciprés          1hiedra     1sabina    0azadón
      0arce        0brezo           1caña       1acedera   0grillo
      1piñón       0corcho          1trufa      1aceituna  1pala
    ),
    # Nivôse
    qw(
      1turba           0carbón   0betún      0azufre    1perro
      1lava            0suelo    1estiércol  0salitre   0mayal
      0granito         1arcilla  1pizarra    1arenisca  0conejo
      1sílex           1marga    1caliza     0mármol    1aventadora_de_cereal
      1piedra_de_yeso  1sal      0hierro     0cobre     1gato
      0estaño          0plomo    0cinc       0mercurio  0tamiz
    ),
    # Pluviôse
    qw(
      1laureola     0musgo           0rusco     0galanto          0toro
      0laurentino   0hongo_yesquero  0mezereón  0álamo            0hacha
      0eléboro      1brécol          0laurel    0avellano         1vaca
      0boj          0liquen          0tejo      1pulmonaria       1navaja_podadora
      0carraspique  0torvisco        1gramilla  1centinodia       1liebre
      1isatide      0avellano        0ciclamen  1celidonia_mayor  0trineo
    ),
    # Ventôse
    qw(
      0tusilago            0corno              0alhelí       0aligustre      0macho_cabrío
      0jengibre_silvestre  0aladierno          0violeta      1sauce_cabruno  1laya
      0narciso             0olmo               1fumaria      0erísimo        1cabra
      1espinaca            0doronicum          1anagallis    0perifollo      0hilo
      1mandrágora          0perejil            1coclearia    1margarita      0atún
      0diente_de_león      1anémona_de_bosque  0culantrillo  0fresno         0plantador
    ),
    # Germinal
    qw(
      1primavera       0sicomoro        0espárrago          0tulipán   1gallina
      1acelga          0abedul          0junquillo          0alnus     0nidal
      1vincapervinca   0carpe           1morchella          0haya      1abeja
      1lechuga         0alerce          1cicuta             0rábano    1colmena
      1árbol_de_Judea  1lechuga_romana  0castaño_de_Indias  1roqueta   1paloma
      0lila            1anémona         0pensamiento        0arándano  0cuchillo
    ),
    # Floréal
    qw(
      0rosa               0roble        0helecho   0espino_albar   0ruiseñor
      1aguileña           1convalaria   1seta      0jacinto        0rastrillo
      0ruibarbo           1esparceta    0erysimum  0palmito        0gusano_de_seda
      1consuelda          1algáfita     0alyssum   0atriplex       0escardillo
      0limonium_sinuatum  1fritillaria  1borraja   1valeriana      1carpa
      0bonetero           0cebollino    1anchusa   1mostaza_negra  0armuelle
    ),
    # Prairial
    qw(
      1alfalfa   0lirio_de_día  0trébol      1angélica  0pato
      0toronjil  1mazorra       0martagón    0serpol    1guadaña
      1fresa     1salvia        0guisante    1acacia    1codorniz
      0clavel    0saúco         1adormidera  0tilo      0bieldo
      0barbo     1manzanilla    1madreselva  0galium    1tenca
      0jazmín    1verbena       0tomillo     1peonía    0carro
    ),
    # Messidor
    qw(
      0centeno   1avena      1cebolla    1veronica             1mula
      1romero    0pepino     0chalote    1absenta              1hoz
      0cilantro  1alcachofa  0alhelí     1lavanda              1gamuza
      0tabaco    1grosella   0lathyrus   1cereza               0parque
      1menta     0comino     1judía      1palomilla_de_tintes  1gallina_de_Guinea
      1salvia    0ajo        1algarroba  0trigo                1chirimía
    ),
    # Thermidor
    qw(
      1escanda          0verbasco   0melón        1cizaña    0carnero
      1cola_de_caballo  1artemisa   0cártamo      1mora      1regadera
      0panicum          0salicor    0albaricoque  1albahaca  1oveja
      1malvaceae        0lino       1almendra     1genciana  1esclusa
      1carlina          1alcaparra  1lenteja      1inula     1nutria
      0mirto            1colza      0lupino       0algodón   0molino
    ),
    # Fructidor
    qw(
      1ciruela         0mijo                0soplo_de_lobo  1cebada_de_otoño    0salmón
      0nardo           1cebada_de_invierno  1apocynaceae    0regaliz            1escala
      1sandía          0hinojo              0berberis       1nuez               1trucha
      0limón           1cardencha           0espino_cerval  0clavelón           0cesto
      0escaramujo      1avellana            1lúpulo         0sorgo              0cangrejo_de_río
      1naranja_amarga  1vara_de_oro         1maíz           1castaña            1cesta
    ),
    # Jours complémentaires
    qw(
      1virtud      0talento  0trabajo  1opinión  3recompensas
      1revolución
    ),
  ]},
);

has '+prefixes' => (
  default => sub {[
    'día del ',
    'día de la ',
    'día de los ',
    'día de las ',
  ]},
);

has '+suffix' => (
  default => '',
);

has '+wikipedia_entries' => (
  default => sub {{
    1 => {
      'azafrán'         => 'Crocus_sativus',
      'cólquida'        => 'Colchicum_autumnale',
      'caballo'         => 'Equus_ferus_caballus',
      'balsamina'       => 'Balsaminaceae',
      'zanahoria'       => 'Daucus_carota',
      'amaranto'        => 'Amaranthus',
      'chirivía'        => 'Pastinaca sativa',
      'patata'          => 'Solanum_tuberosum',
      'flor de papel'   => 'Helichrysum',
      'calabaza'        => 'Cucurbita',
      'reseda'          => 'Reseda',
      'asno'            => 'Equus_africanus_asinus',
      'bella de noche'  => 'Mirabilis_jalapa',
      'calabaza otoñal' => 'Cucurbita_maxima',
      'alforfón'        => 'Fagopyrum_esculentum',
      'girasol'         => 'Helianthus_annuus',
      'lagar'           => 'Lagar_(recipiente)',
      'melocotón'       => 'Prunus_persica',
      'nabo'            => 'Brassica_napus',
      'amarilis'        => 'Amaryllis',
      'berenjena'       => 'Solanum_melongena',
      'pimiento'        => 'Chile_(pimiento)',
      'tomate'          => 'Solanum_lycopersicum',
      'cebada'          => 'Hordeum_vulgare',
    },
    2 => {
      'apio'               => 'Apium_graveolens',
      'remolacha'          => 'Beta_vulgaris',
      'oca'                => 'Anser_anser',
      'heliótropo'         => 'Heliotropium',
      'escorzonera'        => 'Scorzonera_hispanica',
      'mostajo'            => 'Sorbus_torminalis',
      'salsifí'            => 'Tragopogon',
      'castaña de agua'    => 'Trapa',
      'tupinambo'          => 'Helianthus_tuberosus',
      'endibia'            => 'Cichorium_endivia',
      'guajolote'          => 'Meleagris',
      'escaravía'          => 'Sium_sisarum',
      'berro'              => 'Nasturtium_officinale',
      'dentelaria'         => 'Plumbago_europaea',
      'granada'            => 'Punica_granatum',
      'grada'              => 'Grada_(agricultura)',
      'bacante'            => 'Bacantes',
      'acerolo'            => 'Crataegus_azarolus',
      'rubia roja'         => 'Rubia_tinctorum',
      'naranja'            => 'Citrus_×_sinensis',
      'faisán'             => 'Phasianus_colchicus',
      'pistacho'           => 'Pistacia_vera',
      'lathyrus tuberosus' => 'Lathyrus',
      'membrillo'          => 'Cydonia_oblonga',
      'serbal'             => 'Sorbus_domestica',
      'rodillo'            => 'Rodillo_(agricultura)',
    },
    3 => {
      'rapónchigo'     => 'Campanula_rapunculus',
      'nabo forrajero' => 'Brassica_napus',
      'achicoria'      => 'Cichorium_intybus',
      'níspero'        => 'Eriobotrya_japonica',
      'cerdo'          => 'Sus_scrofa_domestica',
      'canónigo'       => 'Valerianella_locusta',
      'coliflor'       => 'Brassica_oleracea_var._botrytis',
      'enebro'         => 'Juniperus',
      'pico'           => 'Pico_(herramienta)',
      'rábano picante' => 'Armoracia_rusticana',
      'cedro'          => 'Cedrus',
      'abeto'          => 'Abies',
      'corzo'          => 'Capreolus_capreolus',
      'tojo'           => 'Ulex',
      'ciprés'         => 'Cupressus',
      'hiedra'         => 'Hedera',
      'sabina'         => 'Juniperus_sabina',
      'azadón'         => 'Azada',
      'arce'           => 'Acer_(planta)',
      'brezo'          => 'Erica',
      'caña'           => 'Caña_(vegetal)',
      'acedera'        => 'Rumex_acetosa',
      'grillo'         => 'Gryllidae',
      'trufa'          => 'Tuber',
    },
    4 => {
      'perro'                => 'Canis_lupus_familiaris',
      'pizarra'              => 'Pizarra_(roca)',
      'conejo'               => 'Oryctolagus_cuniculus',
      'aventadora de cereal' => 'Criba',
      'piedra de yeso'       => 'Yeso',
      'gato'                 => 'Felis_silvestris_catus',
      'mercurio'             => 'Mercurio_(elemento)',
      'tamiz'                => 'Cedazo',
    },
    5 => {
      'laureola'        => 'Daphne_laureola',
      'musgo'           => 'Bryophyta_sensu_stricto',
      'rusco'           => 'Ruscus_aculeatus',
      'galanto'         => 'Galanthus_nivalis',
      'toro'            => 'Bos_primigenius_taurus',
      'laurentino'      => 'Viburnum_tinus',
      'mezereón'        => 'Daphne_mezereum',
      'álamo'           => 'Populus',
      'eléboro'         => 'Helleborus',
      'brécol'          => 'Brassica_oleracea_var._italica',
      'laurel'          => 'Laurus_nobilis',
      'avellano'        => 'Corylus_avellana',
      'vaca'            => 'Bos_primigenius_taurus',
      'boj'             => 'Buxus',
      'tejo'            => 'Taxus',
      'navaja podadora' => 'Corquete',
      'carraspique'     => 'Thlaspi_arvense',
      'torvisco'        => 'Daphne_gnidium',
      'gramilla'        => 'Cynodon',
      'centinodia'      => 'Polygonum_aviculare',
      'isatide'         => 'Isatis_tinctoria',
      'avellano'        => 'Corylus_avellana',
      'ciclamen'        => 'Cyclamen',
      'celidonia mayor' => 'Chelidonium_majus',
    },
    6 => {
      'tusilago'           => 'Tussilago',
      'corno'              => 'Cornus',
      'alhelí'             => 'Erysimum',
      'aligustre'          => 'Ligustrum',
      'jengibre silvestre' => 'Asarum_canadense',
      'aladierno'          => 'Rhamnus_alaternus',
      'violeta'            => 'Viola_(género)',
      'sauce cabruno'      => 'Salix_caprea',
      'laya'               => 'Pala',
      'narciso'            => 'Narcissus',
      'olmo'               => 'Ulmus',
      'erísimo'            => 'Sisymbrium_officinale',
      'cabra'              => 'Capra',
      'espinaca'           => 'Spinacia_oleracea',
      'perifollo'          => 'Anthriscus_cerefolium',
      'mandrágora'         => 'Mandragora',
      'perejil'            => 'Petroselinum_crispum',
      'coclearia'          => 'Cochlearia',
      'margarita'          => 'Bellis_perennis',
      'atún'               => 'Thunnus',
      'diente de león'     => 'Taraxacum_officinale',
      'anémona de bosque'  => 'Anemone_nemorosa',
      'culantrillo'        => 'Adiantum_capillus-veneris',
      'fresno'             => 'Fraxinus',
      'plantador'          => 'Herramienta_agrícola',
    },
    7 => {
      'primavera'         => 'Primula',
      'sicomoro'          => 'Acer_pseudoplatanus',
      'espárrago'         => 'Asparagus_officinalis',
      'tulipán'           => 'Tulipa',
      'gallina'           => 'Gallus_gallus_domesticus',
      'acelga'            => 'Beta_vulgaris_var._cicla',
      'abedul'            => 'Betula',
      'junquillo'         => 'Narcissus_jonquilla',
      'nidal'             => 'Incubación_artificial',
      'vincapervinca'     => 'Vinca',
      'carpe'             => 'Carpinus',
      'haya'              => 'Fagus_sylvatica',
      'abeja'             => 'Anthophila',
      'lechuga'           => 'Lactuca_sativa',
      'alerce'            => 'Larix',
      'cicuta'            => 'Conium_maculatum',
      'rábano'            => 'Armoracia_rusticana',
      'árbol de Judea'    => 'Cercis_siliquastrum',
      'castaño de Indias' => 'Aesculus_hippocastanum',
      'roqueta'           => 'Eruca_vesicaria',
      'paloma'            => 'Columbidae',
      'lila'              => 'Syringa_vulgaris',
      'anémona'           => 'Anemone',
      'pensamiento'       => 'Viola_×_wittrockiana',
    },
    8 => {
      'helecho'        => 'Filicopsida',
      'espino albar'   => 'Crataegus',
      'ruiseñor'       => 'Luscinia_megarhynchos',
      'aguileña'       => 'Aquilegia',
      'convalaria'     => 'Convallaria_majalis',
      'jacinto'        => 'Hyacinthus',
      'rastrillo'      => 'Rastrillo_(herramienta)',
      'ruibarbo'       => 'Rheum_rhabarbarum',
      'esparceta'      => 'Onobrychis',
      'palmito'        => 'Chamaerops_humilis',
      'gusano de seda' => 'Bombyx_mori',
      'consuelda'      => 'Symphytum',
      'algáfita'       => 'Sanguisorba_minor',
      'escardillo'     => 'Azada',
      'borraja'        => 'Borago_officinalis',
      'valeriana'      => 'Valeriana_officinalis',
      'carpa'          => 'Cyprinus_carpio',
      'bonetero'       => 'Euonymus_europaeus',
      'cebollino'      => 'Allium_schoenoprasum',
      'mostaza negra'  => 'Brassica_nigra',
      'armuelle'       => 'Cayado_(bastón)',
    },
    9 => {
      'alfalfa' => 'Medicago_sativa',
      'lirio de día' => 'Hemerocallis',
      'trébol' => 'Trifolium',
      'angélica' => 'Angelica',
      'mazorra' => 'Arrhenatherum_elatius',
      'martagón' => 'Lilium_martagon',
      'serpol' => 'Thymus_serpyllum',
      'fresa' => 'Fragaria',
      'guisante' => 'Pisum_sativum',
      'codorniz' => 'Coturnix_coturnix',
      'clavel' => 'Dianthus_caryophyllus',
      'saúco' => 'Sambucus',
      'adormidera' => 'Papaver',
      'tilo' => 'Tilia',
      'bieldo' => 'Horca_(herramienta)',
      'barbo' => 'Barbus_barbus',
      'manzanilla' => 'Chamaemelum_nobile',
      'madreselva' => 'Lonicera',
      'tenca' => 'Tinca_tinca',
      'jazmín' => 'Jasminum',
      'verbena' => 'Verbena_officinalis',
      'tomillo' => 'Thymus',
      'peonía' => 'Paeoniaceae',
    },
    10 => {
      'centeno'             => 'Secale_cereale',
      'cebolla'             => 'Allium_cepa',
      'veronica'            => 'Veronica_(planta)',
      'mula'                => 'Mula_(animal)',
      'romero'              => 'Rosmarinus_officinalis',
      'pepino'              => 'Cucumis_sativus',
      'chalote'             => 'Allium_ascalonicum',
      'hoz'                 => 'Hoz_(herramienta)',
      'cilantro'            => 'Coriandrum_sativum',
      'alcachofa'           => 'Cynara_scolymus',
      'alhelí'              => 'Erysimum_cheiri',
      'lavanda'             => 'Lavandula',
      'gamuza'              => 'Rupicapra_rupicapra',
      'grosella'            => 'Ribes_alpinum',
      'comino'              => 'Cuminum_cyminum',
      'judía'               => 'Phaseolus_vulgaris',
      'palomilla de tintes' => 'Alkanna_tinctoria',
      'ajo'                 => 'Allium_sativum',
      'trigo'               => 'Triticum',
    },
    11 => {
      'escanda'         => 'Triticum_dicoccoides',
      'verbasco'        => 'Verbascum_thapsus',
      'melón'           => 'Cucumis_melo',
      'cizaña'          => 'Lolium_temulentum',
      'carnero'         => 'Ovis_orientalis_aries',
      'cola de caballo' => 'Equisetaceae',
      'artemisa'        => 'Artemisia_vulgaris',
      'cártamo'         => 'Carthamus_tinctorius',
      'mora'            => 'Mora_(fruta)',
      'salicor'         => 'Salicornia',
      'albaricoque'     => 'Prunus_armeniaca',
      'albahaca'        => 'Ocimum_basilicum',
      'oveja'           => 'Ovis_orientalis_aries',
      'lino'            => 'Linum_usitatissimum',
      'genciana'        => 'Gentiana',
      'alcaparra'       => 'Capparis_spinosa',
      'lenteja'         => 'Lens_culinaris',
      'nutria'          => 'Lutrinae',
      'mirto'           => 'Myrtus',
      'colza'           => 'Brassica_napus',
      'lupino'          => 'Lupinus',
      'algodón'         => 'Gossypium',
    },
    12 => {
      'soplo de lobo' => 'Lycoperdaceae',
      'cebada de otoño' => 'Hordeum_vulgare',
      'salmón' => 'Salmo_(género)',
      'nardo' => 'Polianthes_tuberosa',
      'cebada de invierno' => 'Hordeum_vulgare',
      'regaliz' => 'Glycyrrhiza_glabra',
      'escala' => 'Escalera_de_mano',
      'sandía' => 'Citrullus_lanatus',
      'hinojo' => 'Foeniculum_vulgare',
      'nuez' => 'Nuez_(fruto)',
      'limón' => 'Citrus_×_limon',
      'cardencha' => 'Dipsacus_fullonum',
      'espino cerval' => 'Rhamnus_catharticus',
      'clavelón' => 'Tagetes',
      'cesto' => 'Cesta',
      'lúpulo' => 'Humulus_lupulus',
      'sorgo' => 'Sorghum',
      'naranja amarga' => 'Citrus_×_aurantium',
      'vara de oro' => 'Solidago',
      'maíz' => 'Zea_mays',
    },
    13 => {
      'talento' => 'Talento_(aptitud)',
      'trabajo' => 'Trabajo_(sociología)',
      'recompensas' => 'Recompensa',
      'revolución' => 'Revolución_francesa',
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

App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es - French localization of (part of) L<DateTime::Calendar::FrenchRevolutionary::Locale::fr>

=head1 VERSION

version 0.27

=head1 DESCRIPTION

This modules adds Spanish translations to L<DateTime::Calendar::FrenchRevolutionary>, based on Wikipedia: L<https://es.wikipedia.org/wiki/Calendario_republicano_franc%C3%A9s>.

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

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

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
