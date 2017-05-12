package CPAN::Search::Lite::Lang::de;
use strict;
use warnings;
our $VERSION = 0.77;

use base qw(Exporter);
our (@EXPORT_OK, $chaps_desc, $pages,
     $dslip, $months);
@EXPORT_OK = qw($chaps_desc $pages
                $dslip $months);

$chaps_desc = {
        2 => q{Perl Kernmodule},
        3 => q{Entwicklungsunterst&uuml;tzung},
        4 => q{Betriebssystem-Schnittstellen},
        5 => q{Netzwerke Devices IPC},
        6 => q{Datentyp-Utilities},
        7 => q{Datenbankschnittstellen},
        8 => q{Benutzerschnittstellen},
        9 => q{Sprachenschnittstellen},
        10 => q{Dateinamen System Locking},
        11 => q{Strings Sprachen Text Proc},
        12 => q{Optionen Argumente Parameter Proc},
        13 => q{Internationalisierung Lokalisierung},
        14 => q{Sicherheit und Verschl&uuml;sselung},
        15 => q{World Wide Web HTML HTTP Cgi},
        16 => q{Server D&auml;monen},
        17 => q{Archivierung und Kompression},
        18 => q{Bilder Pixmaps Bitmaps},
        19 => q{eMail und Usenet},
        20 => q{Kontrollflu&szlig;-Utilities},
        21 => q{Dateihandles Input Output},
        22 => q{Microsoft Windows Module},
        23 => q{Verschiedene Module},
        24 => q{Kommerzielle Programmschnittstellen},
        26 => q{Dokumentation},
        27 => q{Pragma},
        28 => q{Perl6},
        99 => q{Noch nicht katalogisiert},
};

$dslip = {
    d => {
      M => q{Ausgereift},
      R => q{Freigegeben},
      S => q{Standard, geliefert mit Perl 5},
      a => q{Alphaphase},
      b => q{Betaphase},
      c => q{Pre-alpha Stadium (noch nicht freigegeben)},
      desc => q{Entwicklungsstatus (Anmerkung: * IMPLIZIERT KEINE ZEITSKALA *)},
      i => q{Idee - nur zur Koordination oder als Platzhalter verzeichnet},
    },
    s => {
      a => q{Aufgegeben, Autor k&uuml;mmert sich nicht mehr um sein Modul},
      d => q{Entwickler},
      desc => q{Support Level},
      m => q{Mailingliste},
      n => q{Unbekannt, m&ouml;glicherweise &uuml;ber comp.lang.perl.modules},
      u => q{Usenet: comp.lang.perl.modules},
    },
    l => {
      '+' => q{C++ und Perl, C++ Compiler erforderlich},
      c => q{C und Perl, C Compiler erforderlich},
      desc => q{Verwendete Sprache(n)},
      h => q{Hybrid, geschrieben in Perl mit optionalem C Code, Compiler nicht ben&ouml;tigt},
      o => q{Perl und weitere Sprache (weder C noch C++)},
      p => q{Perl, kein Compiler n&ouml;tig, sollte plattformunabh&auml;ngig sein},
    },
    i => {
      O => q{Objektorientiert mit Blessed References und/oder Vererbung},
      desc => q{Art der Schnittstelle},
      f => q{Normale Funktionen, keine Referenzen},
      h => q{Hybrid, objektorientierte und funktionale Schnittstellen vorhanden},
      n => q{Keinerlei Schnittstelle (nanu?)},
      r => q{Unblessed References oder Ties},
    },
    p => {
      a => q{Artistic License},
      b => q{BSD: Die BSD Lizenz},
      desc => q{Lizenz},
      g => q{GPL: Gnu Public License},
      l => q{LGPL: "GNU Lesser General Public License" (fr&uuml;her bekannt als "GNU Library General Public License")},
      o => q{Andere Lizenz (Verteilung unbeschr&auml;nkt erlaubt)},
      p => q{Standard-Perl: Freie Wahl zwischen GPL und Artistic License},
    },
};

$pages = {
          title => 'CPAN Browsen / Durchsuchen',
          list => { module => 'Modulen',
                     dist => 'Distributionen',
                    author => 'Autoren',
                    chapter => 'Kategorien',
                  },
          buttons => {Home => 'Home',
                      Documentation => 'Dokumentation',
                      Recent => 'Neue Module',
                      Mirror => 'CPAN Mirrors',
                      Preferences => 'Pr&auml;ferenzen',
                      Modules => 'Module',
                      Distributions => 'Distributionen',
                      Authors => 'Autoren',
                     },
          form => {Find => 'Suche',
                   in => 'in',
                   Search => 'Suchen',
                  },
          Problems => 'Probleme, Vorschl&auml;ge oder Anmerkungen bitte an',
          Questions => 'Fragen? Versuchen Sie mit der',
          na => 'nicht spezifiziert',
          Language => 'Wahl der Sprache',
          bytes => 'Bytes',
          download => 'Download',
          cpanid => 'CPAN id',
          name => 'Voller Name',
          email => 'email',
          results => 'Resultate gefunden',
          try => 'Auf',
          categories => 'Kategorien',
          category => 'Kategorie',
          distribution => 'Distribution',
          author => 'Autor',
          module => 'Modul',
          version => 'Version',
          abstract => 'Kurzbeschreibung',
          released => 'Erstellt',
          size => 'Gr&ouml;&szlig;e',
          cs => 'MD5 Checksum',
          additional => 'Zus&auml;tzliche Dateien',
          links => 'Links',
          info => 'Informationen',
          prereqs => 'Voraussetzungen',
          packages => 'Pakete f&uuml;r',
          related => 'related',
          browse => 'durchsuchen',
          uploads => 'Neue Module der letzten',
          days => 'Tage',
          more => 'more',
          nada => 'Keine Resultate gefunden',
          error1 => 'Leider ist bei der Verarbeitung Ihrer Frage nach',
          error2 => 'in der Rubrik',
          error3 => 'ein Fehler aufgetreten.',
          error4 => 'Bei der Verarbeitung ist ein Fehler aufgetreten.',
          error5 => << 'END',
Genaue Fehlerinformationen sind zur Kontrolle gespeichert worden. 
<p>Wenn dieser Fehler auftrat, w&auml;hrend eine regex-Suche durchgef&uuml;hrt 
wurde, pr&uuml;fen Sie bitte die 
<a 
href="http://www.mysql.com/documentation/mysql/bychapter/manual_Regexp.html#Regexp">
syntaktische Korrektheit</a> Ihrer Anfrage.
<p>Wenn Sie denken, da&szlig; dies ein Bug ist, 
k&ouml;nnen Sie helfen ihn aufzusp&uuml;ren, indem Sie 
END
          error6 => << 'END',
eine eMail schicken, in welcher Sie erkl&auml;ren wonach Sie suchten, 
als der Fehler auftrat. Danke!
END
          missing1 => 'Es konnten keine Ergebnisse f&uuml;r',
          missing2 => 'in der Rubrik',
          missing3 => 'gefunden werden. Versuchen Sie bitte einen anderen Suchbegriff.',
          missing4 => 'Es ist leider ein Fehler aufgetreten - Ihre Anfrage konnte nicht beantwortet werden. Bitte versuchen Sie es später noch einmal.',
           mirror => 'CPAN mirrors',
           public => '&Ouml;ffentlicher Mirror',
           none => 'Keiner - privaten Mirror nutzen',
           custom => 'Privater Mirror',
           default => 'Der Deafaultlink',
           alt => 'oder',
          install => 'Bringen Sie an',
           mirror1 => << 'END',
Mit dieser Formular k&ouml;nnen Sie einstellen, 
von welchem Mirror Sie Ihre Downloads beziehen wollen. 
Dieses Feature ben&ouml;tigt Cookies. 
Ihre aktuelle Einstellung ist
END
           mirror2 => << 'END',
versucht automatisch, Sie auf einen &ouml;rtlich nahegelegenen 
CPAN Mirror weiterzuleiten.
END
          webstart => << 'END',
Das Vorw&auml;hlen dieser Wahl liefert Verbindungen, 
Ihnen erm&ouml;glichend, CPAN Module und Win32 PPM Pakete 
durch ein Anwendung Verwenden anzubringen
END
};

$months = {
         '01' => 'J&auml;n',
         '02' => 'Feb',
         '03' => 'M&auml;rz',
         '04' => 'Apr',
         '05' => 'Mai',
         '06' => 'Juni',
         '07' => 'Juli',
         '08' => 'Aug',
         '09' => 'Sep',
         '10' => 'Okt',
         '11' => 'Nov',
         '12' => 'Dez',
};

1;

__END__

=head1 NAME

CPAN::Search::Lite::Lang::de - export some common data structures used by CPAN::Search::Lite::* for German

=head1 SEE ALSO

L<CPAN::Search::Lite::Lang>

=cut
