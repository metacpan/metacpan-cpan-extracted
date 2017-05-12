package CPAN::Search::Lite::Lang::it;
use strict;
use warnings;
our $VERSION = 0.77;

use base qw(Exporter);
our (@EXPORT_OK, $chaps_desc, $pages, $dslip, $months);
@EXPORT_OK = qw($chaps_desc $pages $dslip $months);

$chaps_desc = {
        2 => q{Moduli Core Perl},
        3 => q{Supporto per lo Sviluppo},
        4 => q{Interfacce per Sistemi Operativi},
        5 => q{Dispositivi di Rete e IPC},
        6 => q{Programmi di utilit&agrave; per Tipi di Dato},
        7 => q{Interfacce per Database},
        8 => q{Interfacce Utente},
        9 => q{Interfacce per Linguaggi},
        10 => q{File, File Systems, File Locking},
        11 => q{Elaborazione di Stringhe, Linguaggi e Testi},
        12 => q{Parametri, Argomenti, Opzioni e File di Configurazione},
        13 => q{Internazionalizzazione e Localizzazione},
        14 => q{Sicurezza e Crittografia},
        15 => q{World Wide Web HTML HTTP CGI},
        16 => q{Programmi di Utilit&agrave; per Demoni e Server},
        17 => q{Archiviazione e Compressione},
        18 => q{Immagini Pixmap Bitmap},
        19 => q{Posta e Newsgroup Usenet},
        20 => q{Programmi di utilit&agrave; per il Controllo di Flusso},
        21 => q{Filehandle Input Output},
        22 => q{Moduli per Microsoft Windows},
        23 => q{Moduli Vari},
        24 => q{Interfacce per Software Commerciali},
        26 => q{Documentazione},
        27 => q{Pragma},
        28 => q{Perl6},
        99 => q{Non Ancora in Modulelist},
};

$dslip = {
    d => {
      M => q{Maturo (nessuna definizione rigorosa)},
      R => q{Rilasciato},
      S => q{Standard, distribuito con il Perl 5},
      a => q{Versione alfa},
      b => q{Versione beta},
      c => q{In sviluppo come pre-alfa (non ancora rilasciato)},
      desc => q{Stadio Di Sviluppo (Nota: * NESSUNA SCALA CRONOLOGICA IMPLICITA *)},
      i => q{Idea, elencata per guadagnare consenso o come segnaposto},
    },
    s => {
      a => q{Abbandonato, il modulo &egrave; stato abbandonato dal suo autore},
      d => q{Sviluppatore},
      desc => q{Livello del Supporto},
      m => q{Mailing-List},
      n => q{Non noto, provare comp.lang.perl.modules},
      u => q{Newsgroup Usenet comp.lang.perl.modules},
    },
    l => {
      '+' => q{C++ e Perl, un compilatore C++ sar&agrave; necessario},
      c => q{C e Perl, un compilatore C sar&agrave; necessario},
      desc => q{Linguaggio Usato},
      h => q{Ibrido, scritto in Perl con parti di codice C opzionali, nessun compilatore &grave; necessario},
      o => q{Perl e un altro linguaggio tranne il C o il C++},
      p => q{Perl solamente, nessun compilatore &egrave; necessario, dovrebbe essere independente della piattaforma},
    },
    i => {
      O => q{Orientato agli Oggetti con utilizzo di riferimenti 'blessed' e/o ereditariet&agrave;},
      desc => q{Stile dell'Interfaccia},
      f => q{Solo Funzioni, senza utilizzo di riferimenti},
      h => q{Ibrido, interfacce ad oggetti e funzioni disponibili},
      n => q{Nessuna interfaccia (huh?)},
      r => q{Utilizzo di riferimenti non 'blessed' o di legami (tie)},
    },
    p => {
      a => q{Artistic License solamente},
      b => q{BSD: BSD License},
      desc => q{Licenza Pubblica},
      g => q{GPL: GNU General Public License},
      l => q{LGPL: "GNU Lesser General Public License" (in passato conosciuta come "GNU Library General Public License")},
      o => q{altro (ma la distribuzione &egrave; permessa senza limitazioni)},
      p => q{Perl Standard: l'utente pu&ograve; scegliere fra le licenze GPL ed Artistic},
         },
         };

$pages = {
          title => 'Naviga e cerca in CPAN',
          list => { module => 'Moduli',
                     dist => 'Distribuzioni',
                     author => 'Autori',
                     chapter => 'Categorie',
                   },
          buttons => {Home => 'Home',
                      Documentation => 'Documentazione',
                      Recent => 'Recenti',
                      Mirror => 'Mirror',
                      Preferences => 'Preferenze',
                      Modules => 'Moduli',
                      Distributions => 'Distribuzioni',
                      Authors => 'Autori',
                     },
          form => {Find => 'Cerca',
                    in => 'in',
                    Search => 'Trova',
                   },
          Problems => 'Problemi, suggerimenti o osservazioni a',
          Questions => 'Domande? Consulta le',
          Language => 'Scelta della lingua',
          na => 'non specificato',
          bytes => 'byte',
          download => 'Scarica',
          cpanid => 'CPAN id',
          name => 'Nome completo',
          email => 'email',
          results => 'results found',
          try => 'Try this query on',
          categories => 'Categorie',
          category => 'Categoria',
          distribution => 'Distribuzione',
          author => 'Autore',
          module => 'Modulo',
          version => 'Versione',
          abstract => 'Estratto',
          released => 'Rilasciato',
          size => 'Dimensioni',
          cs => 'MD5 Checksum',
          additional => 'File Addizionali',
          links => 'Link',
          info => 'Informazioni',
          prereqs => 'Prerequisiti',
          packages => 'Pacchetti Win32',
          related => 'related',
          browse => 'Naviga per',
          uploads => 'Upload negli ultimi',
          days => 'giorni',
          more => 'more',
          nada => 'Nessun risultati trovati',
          error1 => 'Siamo spiacenti - si &egrave; verificato un errore per la tua ricerca',
          error2 => 'in',
          error3 => '',
          error4 => 'Siamo spiacenti - si &egrave; verificato un errore.',
          error5 => << 'END',
L'errore &egrave; stato registrato.
Se questo &egrave; accaduto dopo aver effettuato una ricerca contenente 
espressione regolari, potresti controllare su
<a 
href="http://www.mysql.com/documentation/mysql/bychapter/manual_Regexp.html#Regexp">
la sintassi permessa</a>. 
<p>Se pensi che questo sia un errore del motore di ricerca, 
puoi aiutarci a risolverlo inviando un messaggio a 
END
          error6 => << 'END',
con i particolari di quello che stavi cercando quando questo 
&egrave; accaduto. Grazie!
END
           missing1 => 'Siamo spiacenti - non &egrave; stato trovato alcun risultato per',
           missing2 => 'di tipo',
           missing3 => 'Sei pregato di specificare altri termini per la ricerca.',
           missing4 => 'Siamo spiacenti - non abbiamo capito che cosa hai cercato. Sei pregato di riprovare.',
           mirror => 'Mirror CPAN',
           public => 'Mirror pubblici',
           none => q{Nessuno - Usa l'URL personalizzato},
           custom => 'URL personalizzato',
           default => q{L'URL},
           alt => 'or',
           install => 'Installi',
           mirror1 => << 'END',
Con questo form puoi specificare da dove desideri scaricare 
i moduli (&egrave; necessario abilitare i cookie). 
La tua impostazione corrente &egrave; 
END
           mirror2 => << 'END',
basandosi sulla tua nazione d'origine, cercher&agrave; di 
ridirigerti ad un mirror CPAN vicino.
END
           webstart => << 'END',
La selezione della questa opzione fornir&agrave; i collegamenti 
permettendovi di installare i moduli di CPAN ed i pacchetti 
di Win32 PPM usando di applicazione
END
};

$months = {
         '01' => 'Gennaio',
         '02' => 'Febbraio',
         '03' => 'Marzo',
         '04' => 'Aprile',
         '05' => 'Maggio',
         '06' => 'Giugno',
         '07' => 'Luglio',
         '08' => 'Agosto',
         '09' => 'Settembre',
         '10' => 'Ottobre',
         '11' => 'Novembre',
         '12' => 'Dicembre',
};

1;

__END__

=head1 NAME

CPAN::Search::Lite::Lang::it - export some common data structures used by CPAN::Search::Lite::* for Italian

=head1 SEE ALSO

L<CPAN::Search::Lite::Lang>

=cut

