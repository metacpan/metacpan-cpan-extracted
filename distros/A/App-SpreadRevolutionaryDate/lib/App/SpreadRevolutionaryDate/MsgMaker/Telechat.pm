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
package App::SpreadRevolutionaryDate::MsgMaker::Telechat;
$App::SpreadRevolutionaryDate::MsgMaker::Telechat::VERSION = '0.43';
# ABSTRACT: MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with Téléchat date

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker';

use DateTime;
use File::ShareDir ':ALL';
use App::SpreadRevolutionaryDate;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has '+locale' => (
  default => 'fr',
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{locale} = 'fr';
  return $class->$orig(%args);
};


sub compute {
  my $self = shift;

  my %telechat_calendar = (
    '0101' => ['veisalgie', 'veisalgies', 'f'],
    '0102' => ['ankylostome', 'ankylostomes', 'm'],
    '0103' => ['apex', 'apexes', 'm'],
    '0104' => ['arlequin', 'arlequins', 'm'],
    '0105' => ['bengali', 'bengalis', 'm'],
    '0106' => ['bouquetin', 'bouquetins', 'm'],
    '0107' => ['cancrelat', 'cancrelats', 'm'],
    '0108' => ['cerf-volant', 'cerfs-volants', 'm'],
    '0109' => ['colibri', 'colibris', 'm'],
    '0110' => ['dromadaire', 'dromadaires', 'm'],
    '0111' => ['embrouillamini', 'embrouillaminis', 'm'],
    '0112' => ['fauconneau', 'fauconeaux', 'm'],
    '0113' => ['gambette', 'gambettes', 'f'],
    '0114' => ['hérisson', ' hérissons', 'm'],
    '0115' => ['javelot', 'javelots', 'm'],
    '0116' => ['kangourou', 'kangourous', 'm'],
    '0117' => ['lampion', 'lampions', 'm'],
    '0118' => ['manuscrit', 'manuscrits', 'm'],
    '0119' => ['quignon', 'quignons', 'm'],
    '0120' => ['tablier', 'tabliers', 'm'],
    '0121' => ['zorglub', 'zorglubs', 'm'],
    '0122' => ['pataquès', 'pataquès', 'm'],
    '0123' => ['bobèche', 'bobèches', 'f'],
    '0124' => ['zézaiement', 'zézaiements', 'm'],
    '0125' => ['flibustier', 'flibustiers', 'm'],
    '0126' => ['mirliton', 'mirlitons', 'm'],
    '0127' => ['craspouille', 'craspouilles', 'f'],
    '0128' => ['zigouigoui', 'zigouigouis', 'm'],
    '0129' => ['faribole', 'fariboles', 'f'],
    '0130' => ['pantouflette', 'pantouflettes', 'f'],
    '0131' => ['zinzin', 'zinzins', 'm'],
    '0201' => ['bibelot', 'bibelots', 'm'],
    '0202' => ['ukulélé', 'ukulélés', 'm'],
    '0203' => ['grigris', 'grigris', 'm'],
    '0204' => ['crinoline', 'crinolines', 'f'],
    '0205' => ['turlutaine', 'turlutaines', 'f'],
    '0206' => ['boudeuse', 'boudeuses', 'f'],
    '0207' => ['tralala', 'tralalas', 'm'],
    '0208' => ['carambolage', 'carambolages', 'm'],
    '0209' => ['frimousse', 'frimousses', 'f'],
    '0210' => ['catafalque', 'catafalques', 'm'],
    '0211' => ['chicane', 'chicanes', 'f'],
    '0212' => ['barbichette', 'barbichettes', 'f'],
    '0213' => ['croquignole', 'croquignoles', 'm'],
    '0214' => ['rouleau de sopalin', 'rouleaux de sopalin', 'm'],
    '0215' => ['clavicule', 'clavicules', 'f'],
    '0216' => ['bambinette', 'bambinettes', 'f'],
    '0217' => ['sporange', 'sporanges', 'm'],
    '0218' => ['fléole', 'fléoles', 'f'],
    '0219' => ['goubelin', 'goubelins', 'm'],
    '0220' => ['bélin', 'bélins', 'm'],
    '0221' => ['grébiche', 'grébiches', 'f'],
    '0222' => ['pipistrelle', 'pipistrelles', 'f'],
    '0223' => ['badine', 'badines', 'f'],
    '0224' => ['guttule', 'guttules', 'f'],
    '0225' => ['sautoir', 'sautoirs', 'm'],
    '0226' => ['tourniquet', 'tourniquets', 'm'],
    '0227' => ['grenouillère', 'grenouillères', 'f'],
    '0228' => ['torsade', 'torsades', 'f'],
    '0229' => ['calicot', 'calicots', 'm'],
    '0301' => ['gousset', 'goussets', 'm'],
    '0302' => ['tournebille', 'tournebilles', 'f'],
    '0303' => ['gibelotte', 'gibelottes', 'f'],
    '0304' => ['cabestan', 'cabestans', 'm'],
    '0305' => ['mélopée', 'mélopées', 'f'],
    '0306' => ['galurin', 'galurins', 'm'],
    '0307' => ['joug', 'jougs', 'm'],
    '0308' => ['cabriole', 'cabrioles', 'f'],
    '0309' => ['attache parisienne', 'attaches parisiennes', 'f'],
    '0310' => ['bac à charbon', 'bacs à charbon', 'm'],
    '0311' => ['béquille', 'béquilles', 'f'],
    '0312' => ['boussole', 'boussoles', 'f'],
    '0313' => ['caméra argentique', 'caméras argentiques', 'f'],
    '0314' => ['canne', 'cannes', 'f'],
    '0315' => ['cloche', 'cloches', 'f'],
    '0316' => ['clou', 'clous', 'm'],
    '0317' => ['coton-tige', 'cotons-tiges', 'm'],
    '0318' => ['disque vinyle', 'disques vinyles', 'm'],
    '0319' => ['encrier', 'encriers', 'm'],
    '0320' => ['fer à repasser', 'fers à repasser', 'm'],
    '0321' => ['fusil à pompe', 'fusils à pompe', 'm'],
    '0322' => ['gourde', 'gourdes', 'f'],
    '0323' => ['imprimante à marguerite', 'imprimantes à marguerite', 'f'],
    '0324' => ['tendu-de-majeur', 'doigts d\'honneur', 'm'],
    '0325' => ['machine à écrire', 'machines à écrire', 'f'],
    '0326' => ['poignée de porte', 'poignées de porte', 'f'],
    '0327' => ['savon de marseille', 'savons de marseille', 'm'],
    '0328' => ['stylo à plume', 'stylos à plume', 'm'],
    '0329' => ['téléviseur cathodique', 'téléviseurs cathodiques', 'm'],
    '0330' => ['urne funéraire', 'urnes funéraires', 'f'],
    '0331' => ['balai', 'balais', 'm'],
    '0401' => ['microplastique', 'microplastiques', 'm'],
    '0402' => ['bougie', 'bougies', 'f'],
    '0403' => ['cabine téléphonique', 'cabines téléphoniques', 'f'],
    '0404' => ['canapé', 'canapés', 'm'],
    '0405' => ['carte postale', 'cartes postales', 'f'],
    '0406' => ['ceinture', 'ceintures', 'f'],
    '0407' => ['engrenage', 'engrenages', 'm'],
    '0408' => ['escalier', 'escaliers', 'm'],
    '0409' => ['monogramme', 'monogrammes', 'm'],
    '0410' => ['acanthe', 'acanthes', 'f'],
    '0411' => ['humus', 'humus', 'm'],
    '0412' => ['entroque', 'entroque', 'f'],
    '0413' => ['fourneau', 'fourneaux', 'm'],
    '0414' => ['ampoule, multiprise et rallonge', 'ampoules, multiprises et rallonges', 'f'],
    '0415' => ['alésoir à cliquet', 'alésoirs à cliquets', 'm'],
    '0416' => ['clapier', 'clapiers', 'm'],
    '0417' => ['taloche', 'taloches', 'f'],
    '0418' => ['occiput', 'occiputs', 'm'],
    '0419' => ['diodon', 'diodons', 'm'],
    '0420' => ['tricorne', 'tricornes', 'm'],
    '0421' => ['spume', 'spumes', 'f'],
    '0422' => ['manchon', 'manchons', 'm'],
    '0423' => ['limaçon', 'limaçons', 'm'],
    '0424' => ['levraut', 'levrauts', 'm'],
    '0425' => ['gymkhana', 'gymkhanas', 'm'],
    '0426' => ['dosimètre', 'dosimètres', 'm'],
    '0427' => ['queue-de-pie', 'queues-de-pie', 'f'],
    '0428' => ['clé à pipe débouchée', 'clés à pipe débouchées', 'f'],
    '0429' => ['perruque', 'perruques', 'f'],
    '0430' => ['traille', 'trailles', 'f'],
    '0501' => ['tripalium', 'tripaliums', 'm'],
    '0502' => ['pastille', 'pastilles', 'f'],
    '0503' => ['francisque', 'francisques', 'f'],
    '0504' => ['pirouette', 'pirouettes', 'f'],
    '0505' => ['marmouset', 'marmousets', 'm'],
    '0506' => ['pédicelle', 'pédicelles', 'm'],
    '0507' => ['hypsomètre', 'hypsomètres', 'm'],
    '0508' => ['lambrequin', 'lambrequins', 'm'],
    '0509' => ['cribellum', 'cribellums', 'm'],
    '0510' => ['hélicoïde', 'hélicoïdes', 'f'],
    '0511' => ['quenouille', 'quenouilles', 'f'],
    '0512' => ['zythum', 'zytha', 'm'],
    '0513' => ['sarbacane', 'sarbacanes', 'f'],
    '0514' => ['turion', 'turions', 'm'],
    '0515' => ['blaireau', 'blaireaux', 'm'],
    '0516' => ['sémaphore', 'sémaphores', 'f'],
    '0517' => ['crispatule', 'crispatules', 'f'],
    '0518' => ['zist', 'zists', 'm'],
    '0519' => ['chiquenaude', 'chiquenaudes', 'f'],
    '0520' => ['sagouin', 'sagouins', 'm'],
    '0521' => ['borborygme', 'borborygmes', 'm'],
    '0522' => ['zéphyr', 'zéphyrs', 'm'],
    '0523' => ['schnock', 'schnocks', 'm'],
    '0524' => ['pendeloque', 'pendeloques', 'f'],
    '0525' => ['falbala', 'falbalas', 'm'],
    '0526' => ['nycthémère', 'nycthémères', 'm'],
    '0527' => ['houppier', 'houppiers', 'm'],
    '0528' => ['suaire', 'suaires', 'm'],
    '0529' => ['jable', 'jables', 'm'],
    '0530' => ['goulot', 'goulots', 'm'],
    '0531' => ['bourdalou', 'bourdalous', 'm'],
    '0601' => ['zibeline', 'zibelines', 'f'],
    '0602' => ['turpitude', 'turpitudes', 'f'],
    '0603' => ['carafon', 'carafons', 'm'],
    '0604' => ['roubignole', 'roubignoles', 'f'],
    '0605' => ['cantharide', 'cantharides', 'f'],
    '0606' => ['pédoncule', 'pédoncules', 'm'],
    '0607' => ['élytre', 'élytres', 'm'],
    '0608' => ['cressonnière', 'cressonnières', 'f'],
    '0609' => ['araignée', 'araignées', 'f'],
    '0610' => ['sarment', 'sarments', 'm'],
    '0611' => ['argousin', 'argousins', 'm'],
    '0612' => ['poudingue', 'poudingues', 'm'],
    '0613' => ['pandiculation', 'pandiculations', 'f'],
    '0614' => ['gaudriole', 'gaudrioles', 'f'],
    '0615' => ['chenapan', 'chenapans', 'm'],
    '0616' => ['carabistouille', 'carabistouilles', 'f'],
    '0617' => ['baliverne', 'balivernes', 'f'],
    '0618' => ['histrion', 'histrions', 'm'],
    '0619' => ['babiole', 'babioles', 'f'],
    '0620' => ['pétouille', 'pétouilles', 'f'],
    '0621' => ['baragouin', 'baragouins', 'm'],
    '0622' => ['patatras', 'patatras', 'm'],
    '0623' => ['alambic', 'alambics', 'm'],
    '0624' => ['billevesée', 'billevesées', 'f'],
    '0625' => ['rigolboche', 'rigolboches', 'f'],
    '0626' => ['turlupin', 'turlupins', 'm'],
    '0627' => ['turlurette', 'turlurettes', 'f'],
    '0628' => ['guignol', 'guignols', 'm'],
    '0629' => ['bille-molle', 'billes-molles', 'f'],
    '0630' => ['brimborion', 'brimborions', 'm'],
    '0701' => ['mirliflore', 'mirliflores', 'f'],
    '0702' => ['clapiotte', 'clapiottes', 'f'],
    '0703' => ['gaffophone', 'gaffophones', 'm'],
    '0704' => ['légumineur', 'légumineurs', 'm'],
    '0705' => ['micro-onduleur', 'micro-onduleurs', 'm'],
    '0706' => ['frite-magique', 'frites-magiques', 'f'],
    '0707' => ['extracteur du potentiel de point zéro', 'extracteurs du potentiel de point zéro', 'm'],
    '0708' => ['réveil-tartine', 'réveils-tartines', 'm'],
    '0709' => ['horloge-moussante', 'horloges-moussantes', 'f'],
    '0710' => ['canapélicoptère', 'canapélicoptères', 'm'],
    '0711' => ['éponge-lumineuse', 'éponges-lumineuses', 'f'],
    '0712' => ['spatulon', 'spatulons', 'm'],
    '0713' => ['vaissellier-volant', 'vaisselliers-volants', 'm'],
    '0714' => ['boîte-à-bêtises', 'boîtes-à-bêtises', 'f'],
    '0715' => ['télé-poubelle', 'télé-poubelles', 'f'],
    '0716' => ['baignoire-parlante', 'baignoires-parlantes', 'f'],
    '0717' => ['armoire-à-glissade', 'armoires-à-glissade', 'f'],
    '0718' => ['pierre manale', 'pierres manales', 'f'],
    '0719' => ['grille-pain de l\'espace', 'grilles-pains de l\'espace', 'm'],
    '0720' => ['robot-raccommodeur', 'robots-raccommodeurs', 'm'],
    '0721' => ['fourchette-à-comptine', 'fourchettes-à-comptines', 'f'],
    '0722' => ['pantoufle-réactive', 'pantoufles-réactives', 'f'],
    '0723' => ['coussin-péteur', 'coussins-péteurs', 'm'],
    '0724' => ['télé-orbitale', 'télés-orbitales', 'f'],
    '0725' => ['brosse-à-dent sonique', 'brosses-à-dent soniques', 'f'],
    '0726' => ['couette-intelligente', 'couettes-intelligentes', 'f'],
    '0727' => ['pyjama-à-histoires', 'pyjamas-à-histoires', 'm'],
    '0728' => ['bol-à-mystère', 'bols-à-mystère', 'm'],
    '0729' => ['tabouret-téléphone', 'tabourets-téléphone', 'm'],
    '0730' => ['miroir-savant', 'miroirs-savants', 'm'],
    '0731' => ['tapis-volant d\'intérieur', 'tapis-volants d\'intérieur', 'm'],
    '0801' => ['oreiller-à-musique', 'oreillers-à-musique', 'm'],
    '0802' => ['papier-peint interactif', 'papiers-peints interactifs', 'm'],
    '0803' => ['xylophone', 'xylophones', 'm'],
    '0804' => ['guilloché', 'guillochés', 'm'],
    '0805' => ['djembé', 'djembés', 'm'],
    '0806' => ['caipirinha', 'caipirinhas', 'f'],
    '0807' => ['tzatziki', 'tzatzikis', 'm'],
    '0808' => ['karaoke', 'karaokes', 'm'],
    '0809' => ['kantele', 'kanteles', 'f'],
    '0810' => ['haiku', 'haikus', 'm'],
    '0811' => ['colchique', 'colchiques', 'f'],
    '0812' => ['molinillo', 'molinillos', 'm'],
    '0813' => ['quokka', 'quokkas', 'f'],
    '0814' => ['duduk', 'duduks', 'm'],
    '0815' => ['balalaïka', 'balalaïkas', 'f'],
    '0816' => ['fajitas', 'fajitas', 'f'],
    '0817' => ['bobineau', 'bobineaux', 'm'],
    '0818' => ['fjord', 'fjords', 'm'],
    '0819' => ['tsampa', 'tsampas', 'f'],
    '0820' => ['qipao', 'qipaos', 'f'],
    '0821' => ['boomerang', 'boomerangs', 'm'],
    '0822' => ['cachou', 'cachous', 'm'],
    '0823' => ['sac à dos', 'sacs à dos', 'm'],
    '0824' => ['brosse à dents', 'brosses à dents', 'f'],
    '0825' => ['lampe de bureau', 'lampes de bureau', 'f'],
    '0826' => ['tapis de souris', 'tapis de souris', 'm'],
    '0827' => ['pot de fleurs', 'pots de fleurs', 'm'],
    '0828' => ['brosse à cheveux', 'brosses à cheveux', 'f'],
    '0829' => ['boucle d\'oreille', 'boucles d\'oreilles', 'f'],
    '0830' => ['manette de jeu', 'manettes de jeu', 'f'],
    '0831' => ['tapis de yoga', 'tapis de yoga', 'm'],
    '0901' => ['corde à sauter', 'cordes à sauter', 'f'],
    '0902' => ['haltère', 'haltères', 'm'],
    '0903' => ['trottinette', 'trottinettes', 'f'],
    '0904' => ['sac de couchage', 'sacs de couchage', 'm'],
    '0905' => ['réchaud de camping', 'réchauds de camping', 'm'],
    '0906' => ['chaussure de randonnée', 'chaussures de randonnée', 'f'],
    '0907' => ['taille-crayon', 'taille-crayons', 'm'],
    '0908' => ['agrafeuse', 'agrafeuses', 'f'],
    '0909' => ['aspirateur', 'aspirateurs', 'm'],
    '0910' => ['lave-linge', 'lave-linges', 'm'],
    '0911' => ['sèche-linge', 'sèche-linges', 'm'],
    '0912' => ['machine à coudre', 'machines à coudre', 'f'],
    '0913' => ['serpillère', 'serpillères', 'f'],
    '0914' => ['tronçonneuse', 'tronçonneuses', 'f'],
    '0915' => ['débroussailleuse', 'débroussailleuses', 'f'],
    '0916' => ['motoculteur', 'motoculteurs', 'm'],
    '0917' => ['râteau', 'râteaux', 'm'],
    '0918' => ['clé à molette', 'clés à molette', 'f'],
    '0919' => ['scie circulaire', 'scies circulaires', 'f'],
    '0920' => ['détecteur de fumée', 'détecteurs de fumée', 'm'],
    '0921' => ['caméra de surveillance', 'caméras de surveillance', 'f'],
    '0922' => ['moustiquaire', 'moustiquaires', 'f'],
    '0923' => ['brise-vent', 'brise-vent', 'm'],
    '0924' => ['balcon', 'balcons', 'm'],
    '0925' => ['jardinière', 'jardinières', 'f'],
    '0926' => ['buisson', 'buissons', 'm'],
    '0927' => ['haie', 'haies', 'f'],
    '0928' => ['système d\'irrigation', 'systèmes d\'irrigation', 'm'],
    '0929' => ['thermomètre', 'thermomètres', 'm'],
    '0930' => ['hygromètre', 'hygromètres', 'm'],
    '1001' => ['luxmètre', 'luxmètres', 'm'],
    '1002' => ['anémomètre', 'anémomètres', 'm'],
    '1003' => ['pluviomètre', 'pluviomètres', 'm'],
    '1004' => ['baromètre', 'baromètres', 'm'],
    '1005' => ['chronomètre', 'chronomètres', 'm'],
    '1006' => ['microscope', 'microscopes', 'm'],
    '1007' => ['télescope', 'télescopes', 'm'],
    '1008' => ['spectroscope', 'spectroscopes', 'm'],
    '1009' => ['sac à bière', 'sacs à bière', 'm'],
    '1010' => ['ohmmètre', 'ohmmètres', 'm'],
    '1011' => ['ampermètre', 'ampermètres', 'm'],
    '1012' => ['voltmètre', 'voltmètres', 'm'],
    '1013' => ['oscilloscope', 'oscilloscopes', 'm'],
    '1014' => ['fréquencemètre', 'fréquencemètres', 'm'],
    '1015' => ['analyseur de spectre', 'analyseurs de spectre', 'm'],
    '1016' => ['circuit imprimé' ,'circuits imprimés', 'm'],
    '1017' => ['disjoncteur', 'disjoncteurs', 'm'],
    '1018' => ['machine-à-faire-des-trous-dans-les-spaghetti', 'machines-à-faire-des-trous-dans-les-spaghetti', 'f'],
    '1019' => ['morceau de bois', 'morceaux de bois', 'm'],
    '1020' => ['pot de colle', 'pots de colle', 'm'],
    '1021' => ['paquet cadeau', 'paquets cadeaux', 'm'],
    '1022' => ['cacatoès', 'cacatoès', 'f'],
    '1023' => ['harmonica', 'harmonicas', 'm'],
    '1024' => ['bigoudi', 'bigoudis', 'm'],
    '1025' => ['dent de lait', 'dents de lait', 'f'],
    '1026' => ['bonhomme de neige', 'bonhommes de neige', 'm'],
    '1027' => ['marteau picoreur', 'marteaux picoreurs', 'm'],
    '1028' => ['bande magnétique', 'bandes magnétiques', 'f'],
    '1029' => ['punaise de lit', 'punaises de lit', 'f'],
    '1030' => ['carte de voeux', 'cartes de voeux', 'f'],
    '1031' => ['moins que rien', 'moins que rien', 'm'],
    '1101' => ['tour eiffel', 'tours eiffel', 'f'],
    '1102' => ['symptôme', 'symptômes', 'm'],
    '1103' => ['mamanite', 'amanites', 'f'],
    '1104' => ['cornichon', 'cornichons', 'm'],
    '1105' => ['zinzolin', 'zinzolins', 'm'],
    '1106' => ['jouet à bascule', 'jouets à bascule', 'm'],
    '1107' => ['bloc-notes', 'blocs-notes', 'm'],
    '1108' => ['routoir', 'routoirs', 'm'],
    '1109' => ['guenille', 'guenilles', 'f'],
    '1110' => ['lunette de soleil', 'lunettes de soleil', 'f'],
    '1111' => ['octavin', 'octavins', 'm'],
    '1112' => ['toque à trois cornes', 'toques à trois cornes', 'f'],
    '1113' => ['navire-hôpital', 'navires-hôpitaux', 'm'],
    '1114' => ['sesquiplan', 'sesquiplans', 'm'],
    '1115' => ['baldaquin', 'baldaquins', 'm'],
    '1116' => ['anémoscope', 'anémoscopes', 'm'],
    '1117' => ['clavicythérium', 'clavicythériums', 'm'],
    '1118' => ['certificat de conformité' ,'certificats de conformité', 'm'],
    '1119' => ['bonnet de nuit', ' bonnets de nuit', 'm'],
    '1120' => ['atmomètre', 'atmomètres', 'm'],
    '1121' => ['pnéomètre', 'pnéomètres', 'm'],
    '1122' => ['marie-salope', 'marie-salopes', 'f'],
    '1123' => ['lettre de crédit', 'lettres de crédit', 'f'],
    '1124' => ['cithare', 'cithares', 'f'],
    '1125' => ['tramezzino', 'tramezzinos', 'm'],
    '1126' => ['ichcahuipilli', 'ichcahuipillis', 'f'],
    '1127' => ['journal intime', 'journaux intimes', 'm'],
    '1128' => ['harpe celtique', 'harpes celtiques', 'f'],
    '1129' => ['nœud d’agui', 'nœuds d’agui', 'm'],
    '1130' => ['cabotière', 'cabotières', 'f'],
    '1201' => ['pique-œuf', 'pique-œufs', 'm'],
    '1202' => ['revue de contrat', 'revues de contrats', 'f'],
    '1203' => ['grande surface', 'grandes surfaces', 'f'],
    '1204' => ['manteau de cheminée', 'manteaux de cheminées', 'm'],
    '1205' => ['charentaise', 'charentaises', 'f'],
    '1206' => ['chasse-goupille', 'chasse-goupilles', 'm'],
    '1207' => ['chaussure à orteils', 'chaussures à orteils', 'f'],
    '1208' => ['giroflée à cinq pétales', 'giroflées a cinq pétales', 'f'],
    '1209' => ['salade de phalanges', 'salades de phalanges', 'f'],
    '1210' => ['rogntudju', 'rogntudju', 'm'],
    '1211' => ['lixiviateuse', 'lixiviateuses', 'f'],
    '1212' => ['chaise berçante', 'chaises berçantes', 'f'],
    '1213' => ['chebec', 'chebec', 'm'],
    '1214' => ['boulevard circulaire', 'boulevards circulaires', 'm'],
    '1215' => ['bande cyclable', 'bandes cyclables', 'f'],
    '1216' => ['coupe-boulons', 'coupe-boulons', 'm'],
    '1217' => ['clé à pipe', 'clés à pipes', 'f'],
    '1218' => ['ensacheuse', 'ensacheuses', 'f'],
    '1219' => ['fulguromètre', 'fulguromètre', 'm'],
    '1220' => ['diptyque', 'diptyques', 'm'],
    '1221' => ['cucurbitacée', 'cucurbitacées', 'm'],
    '1222' => ['glassophone', 'glassophones', 'm'],
    '1223' => ['métaphore', 'métaphores', 'f'],
    '1224' => ['pentécontère', 'pentécontères', 'm'],
    '1225' => ['prépuce', 'prépuces', 'm'],
    '1226' => ['cumulus bourgeonnant', 'cumulus bourgeonnants', 'm'],
    '1227' => ['pyréolophore', 'pyréolophores', 'm'],
    '1228' => ['soubassophone', 'soubassophones', 'm'],
    '1229' => ['béret basque', 'bérets basques', 'm'],
    '1230' => ['vocifération sportive', 'vociférations sportives', 'm'],
    '1231' => ['armoire à glace', 'armoires à glace', 'f'],
  );
  my @telechat_days = ('Lourdi', 'Pardi', 'Morquidi', 'Jourdi', 'Dendrevi', 'Sordi', 'Mitanche');

  my $today = DateTime->now(time_zone => 'Europe/Paris');
  my $day_name = $telechat_days[$today->day_of_week_0];
  my $feast = $telechat_calendar{sprintf("%02d", $today->month).sprintf("%02d", $today->day)};
  my $feast_gender = $feast->[2] eq 'm' ? 'Saint' : 'Sainte';
  my $feast_singular = $feast->[0];
  $feast_singular =~ s/\b(\w)/\U$1/g;
  my $feast_plural = $feast->[1];
  my $every_gender = $feast->[2] eq 'm' ? 'tous' : 'toutes';
  my $msg = sprintf("Chalut ! Aujourd'hui, %s %d, c'est la %s-%s.\nBonne fête à %s les %s !", $day_name, $today->day, $feast_gender, $feast_singular, $every_gender, $feast_plural);

  my $img_path = dist_file('App-SpreadRevolutionaryDate', 'images/groucha.png');
  my $img_alt = "Grouchat de Téléchat : « $msg »";
  $img_alt =~ s/\n+/ /g;
  my $img = {path => $img_path, alt => $img_alt};

  return ($msg, $img);
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

App::SpreadRevolutionaryDate::MsgMaker::Telechat - MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with Téléchat date

=head1 VERSION

version 0.43

=head1 METHODS

=head2 compute

Computes date of the day similar to the Belgian-French TV show 'Téléchat" on the 1980's. Takes no argument. Returns message as string and hash with the path to an image file of Groucha, the presenter of Téléchat, and its alt text, with 'path' and 'alt' keys respectively.

This message maker is greatly based on I<SaintObjetBot> a bot spreading, in "Téléchat style", the date and the feast of the day, see L<https://github.com/tobozo/SaintObjetBot>.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Bluesky>

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

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
