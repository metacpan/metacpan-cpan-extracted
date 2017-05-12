package CPAN::Search::Lite::Lang::fr;
use strict;
use warnings;
our $VERSION = 0.77;

use base qw(Exporter);
our (@EXPORT_OK, $chaps_desc, $pages, $dslip, $months);
@EXPORT_OK = qw($chaps_desc $pages $dslip $months);

$chaps_desc = {
        2 => q{Modules int&eacute;gr&eacute; &agrave; Perl},
        3 => q{Aide au d&eacute;veloppement},
        4 => q{Interfaces du syst&egrave;me d'exploitation},
        5 => q{P&eacute;riph&eacute;riques r&eacute;seau, IPC},
        6 => q{Types de donn&eacute;es},
        7 => q{Interfaces de bases de donn&eacute;es},
        8 => q{Interfaces utilisateur},
        9 => q{Interfaces vers d'autres langages},
        10 => q{Fichiers, Syst&egrave;mes de fichiers, verrouillage},
        11 => q{String, Lang, Text, Proc},
        12 => q{Opt, Arg, Param, Proc},
        13 => q{Param&egrave;tres de lieu et internationalisation},
        14 => q{S&eacute;curit&eacute; et chiffrement},
        15 => q{World Wide Web, HTML, HTTP, CGI},
        16 => q{Serveurs et d&eacute;mons},
        17 => q{Archivage et compression},
        18 => q{Images, Pixmaps, Bitmaps},
        19 => q{Courriel et forums Usenet},
        20 => q{Utilitaires de flux de commande},
        21 => q{Descripteurs de fichier, Entr&eacute;es, Sorties},
        22 => q{Modules pour Microsoft Windows},
        23 => q{Modules divers},
        24 => q{Interfaces pour logiciels commerciaux},
        26 => q{Documentation},
        27 => q{Pragma},
        28 => q{Perl6},
        99 => q{Pas encore dans la liste des modules},
};

$dslip = {
    d => {
      M => q{Stable (pas de d&eacute;finition pr&eacute;cise)},
      R => q{Distribu&eacute;},
      S => q{Standard, fourni avec Perl 5},
      a => q{Version alpha},
      b => q{Version b&ecirc;ta},
      c => q{En d&eacute;veloppement, version pr&eacute;-alpha (pas encore distribu&eacute;)},
      desc => q{Stade de d&eacute;veloppement (Note&nbsp;: * PAS DE CALENDRIER D&Eacute;TERMIN&Eacute; *)},
      i => q{Id&eacute;e, &agrave; d&eacute;battre ou simplement plac&eacute;e l&agrave; pour l'instant},
    },
    s => {
      a => q{Abandonn&eacute;, le module a &eacute;t&eacute; abandonn&eacute; par son auteur},
      d => q{D&eacute;veloppeur},
      desc => q{Niveau de support},
      m => q{Liste de diffusion},
      n => q{Inconnu, essayez comp.lang.perl.modules},
      u => q{Forum Usenet comp.lang.perl.modules},
    },
    l => {
      '+' => q{C++ et Perl, un compilateur C++ est n&eacute;cessaire},
      c => q{C et Perl, un compilateur C est n&eacute;cessaire},
      desc => q{Langage utilis&eacute;},
      h => q{Hybride, &eacute;crit en Perl avec du code C optionnel, pas besoin de compilateur},
      o => q{Perl et un langage autre que C ou C++},
      p => q{Perl uniquement, pas besoin de compilateur, a priori ind&eacute;pendant de plate-forme},
    },
    i => {
      O => q{Orient&eacute; objet, avec des r&eacute;f&eacute;rences consacr&eacute;es et/ou de l'h&eacute;ritage},
      desc => q{Style d'interface},
      f => q{Fonctions simples, sans utilisation de r&eacute;f&eacute;rence},
      h => q{Interface hybride, orient&eacute;e objet et proc&eacute;durale},
      n => q{Aucune interface (hein ?)},
      r => q{Utilisation sporadique de r&eacute;f&eacute;rences non b&eacute;nies ou de r&eacute;f&eacute;rences li&eacute;es ("ties")},
    },
    p => {
      a => q{Licence artistique uniquement},
      b => q{BSD : Licence BSD},
      desc => q{Licence d'utilisation},
      g => q{GPL : Licence GPL ("GNU General Public License")},
      l => q{LGPL : Licence LGPL ("GNU Lesser General Public License") (pr&eacute;c&eacute;demment nomm&eacute;e "GNU Library General Public License")},
      o => q{Autre (mais la distribution est autoris&eacute;e sans restriction)},
      p => q{Licence Perl : l'utilisateur peut choisir entre les licences GPL et artistique},
    },
};

$pages = { title => 'Recherche et navigation sur le CPAN',
           list => { module => 'modules',
                    dist => 'distributions',
                    author => 'auteurs',
                    chapter => 'Cat&eacute;gories',
                  },
          buttons => {Home => 'Accueil',
                      Documentation => 'Documentation',
                      Recent => 'Nouveaut&eacute;s',
                      Mirror => 'Miroir',
                      Preferences => 'Pr&eacute;f&eacute;rences',
                      Modules => 'Modules',
                      Distributions => 'Distributions',
                      Authors => 'Auteurs',
                  },
           form => {Find => 'Rechercher',
                    in => 'dans',
                    Search => 'Recherche',
                   },
           Problems => 'Envoyez vos probl&egrave;mes, suggestions ou commentaires &agrave;',
           Questions => 'Des questions&nbsp;? Lisez d\'abord la',
          na => 'non pr&eacute;cis&eacute;',
          bytes => 'octets',
          Language => 'Choix de langue',
           download => 'T&eacute;l&eacute;charger',
           cpanid => 'Identifiant CPAN',
           name => 'Nom et pr&eacute;nom',
           email => 'E-mail',
           results => 'R&eacute;sultats',
           try => 'Recherchez sur',
           categories => 'Cat&eacute;gories',
           category => 'Cat&eacute;gories',
           distribution => 'Distribution',
           author => 'Auteur',
           module => 'Module',
           version => 'Version',
           abstract => 'R&eacute;sum&eacute;',
           released => 'Distribu&eacute; le',
           size => 'Taille',
           cs => 'MD5 Checksum',
           additional => 'Fichiers suppl&eacute;mentaires',
           links => 'Liens',
           info => 'Informations',
           prereqs => 'Fichiers n&eacute;cessaires',
           packages => 'Paquetage',
           related => 'related',
           browse => 'Index des',
           uploads => 'T&eacute;l&eacute;chargements de ces',
           days => 'derniers jours',
           more => 'more',
           nada => 'Aucuns r&eacute;sultats trouv&eacute;s',
           error1 => 'D&eacute;sol&eacute; - Un probl&egrave;me est survenu lors de votre requ&ecirc;te concernant',
           error2 => 'du type',
           error3 => '',
           error4 => 'D&eacute;sol&eacute; - Un probl&egrave;me est survenu.',
           error5 => << 'END',
Ce probl&egrave;me a &eacute;t&eacute; enregistr&eacute;. 
Si l'erreur s'est produite lors d'une recherche avec des expressions r&eacute;guli&egrave;res, nous vous conseillons de v&eacute;rifier  
<a 
href="http://www.mysql.com/documentation/mysql/bychapter/manual_Regexp.html#Regexp">les r&egrave;gles de syntaxe</a>. 
<p>Si vous pensez que le probl&egrave;me provient de l'outil de recherche, 
merci de nous aider en envoyant un message contenant les d&eacute;tails
de votre recherche, ainsi que la page d'erreur, &agrave; 
END
           error6 => << 'END',
Merci&nbsp;!
END
           missing1 => 'D&eacute;sol&eacute; - Votre requ&ecirc;te',
           missing2 => 'du type',
           missing3 => q{n'a donn&eacute; aucun r&eacute;sultat. Veuillez entrer un autre mot-cl&eacute; pour votre recherche.},
           missing4 => q{D&eacute;sol&eacute; - Je n'ai pas compris ce que vous demandiez. Veuillez r&eacute;essayer.},
           mirror => 'Miroirs CPAN',
           public => 'Miroir public',
           none => 'Aucun - Utiliser une URL personnalis&eacute;e',
           custom => 'Adresse URL personnalis&eacute;e',
           default => 'Le lien par d&eacute;faut',
           alt => 'or',
             install => 'Installez',
           mirror1 => << 'END',
Choisissez votre serveur de t&eacute;l&eacute;chargement 
pr&eacute;f&eacute;r&eacute; &agrave; l'aide de ce formulaire
(votre navigateur doit autoriser les cookies).
Vos param&egrave;tres actuels sont
END
           mirror2 => << 'END',
va vous rediriger sur le miroir CPAN le plus proche, selon votre 
pays d'origine.
END
           webstart => <<'END',
Le choix de cette option fournira des liens vous permettant 
d'installer des modules de CPAN et des paquetage de Win32 PPM
par employer d'application
END
};

$months = {
         '01' => 'janv',
         '02' => 'f&eacute;vr',
         '03' => 'mars',
         '04' => 'avril',
         '05' => 'mai',
         '06' => 'juin',
         '07' => 'juil',
         '08' => 'ao&ucirc;t',
         '09' => 'sept',
         '10' => 'oct',
         '11' => 'nov',
         '12' => 'd&eacute;c',
};

1;

__END__

=head1 NAME

CPAN::Search::Lite::Lang::fr - export some common data structures used by CPAN::Search::Lite::* for French

=head1 SEE ALSO

L<CPAN::Search::Lite::Lang>

=cut

