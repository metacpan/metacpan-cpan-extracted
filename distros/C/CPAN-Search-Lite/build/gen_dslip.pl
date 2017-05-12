#!/usr/bin/perl -w
use strict;
use Template;
use lib qw(lib);
use CPAN::Search::Lite::Lang qw($dslip);
use File::Spec::Functions;
my $dslip_order = {
    d => [qw( i c a b R M S )],
    s => [qw( m d u n a     )],
    l => [qw( p c h + o     )],
    i => [qw( f h n r O     )],
    p => [qw( p g l b a o   )],
};

my $dslip_page = {
    de => {
        title => 'DSLIP Informationen',
        intro => 'Die volle Liste der m&ouml;glichen DSLIP Wahlen sind:',
        disclaimer => <<'.',
<b>VERZICHT:</b> Der Status des allgemeinen Lizenzfeldes ist dort
   nur zum informierenden Zweck und setzt nicht eine zugelassene
   Schwerg&auml;ngigkeit irgendwie der Art fest. Um korrekte
   Informationen &uuml;ber die Genehmigenbezeichnungen eines
   Moduls und seiner angeschlossenen Akten einzuholen, beziehen
   Sie bitte sich die auf Verteilung der Module oder treten Sie
   mit dem Autor in Verbindung wie passend. Informieren Sie bitte
   <a href="mailto:modules@perl.org">modules@perl.org,</a> wenn
   Sie irgendeine Fehlanpassung zwischen dem Inhalt des
   allgemeinen Lizenzfeldes antreffen und was die Verteilung
   wirklich &uuml;ber sie sagt.
.
    },
    fr => {
        title => 'Informations DSLIP',
        intro => 'Voici la liste compl&egrave;te des options DSLIP&nbsp;:',
        disclaimer => <<'.',
<b>AVIS DE NON-RESPONSABILIT&Eacute;&nbsp;:</b> Ce qui est indiqu&eacute; dans le champ
   "Licence d'utilisation" ne l'est qu'&agrave; titre indicatif et n'a aucune
   valeur juridique. Pour obtenir des informations pr&eacute;cises sur un module et ses
   fichiers, veuillez-vous reporter &agrave; la distribution du module ou contactez
   directement son auteur. Merci d'informer la liste <a
   href="mailto:modules@perl.org">modules@perl.org</a> si vous rencontrez des erreurs
   dans le contenu du champ "Licence d'utilisation". 
.
    },
    en => {
        title => 'DSLIP Information',
        intro => 'The full list of possible DSLIP options are:',
        disclaimer => <<'.',
<b>DISCLAIMER:</b> The status of the Public License field is there for
   informational purpose only and does not constitute a legal binding of
   any kind. To obtain proper information about the Licencing terms of a
   module and its accompanying files, please refer to the distribution
   of the modules or contact the author as appropriate. Please inform <a
   href="mailto:modules@perl.org">modules@perl.org</a> if you encounter
   any mismatch between the contents of the Public License field and
   what the distribution actually says about it.
.
    },
    es => {
        title => 'Informaci&oacute;n de DSLIP',
        intro => 'La lista completa de las opciones posibles de DSLIP es:',
        disclaimer => <<'.',
<b>NEGACI&Oacute;N:</b> El estado del campo p&uacute;blico de la
   licencia est&aacute; all&iacute; para el prop&oacute;sito informativo
   solamente y no constituye un atascamiento legal de la clase. Para
   obtener la informaci&oacute;n apropiada sobre los t&eacute;rminos de
   la autorizaci&oacute;n de un m&oacute;dulo y de sus archivos de
   acompa&ntilde;amiento, refiera por favor a la distribuci&oacute;n de
   los m&oacute;dulos o entre en contacto con a autor como apropiado.
   Informe por favor <a href="mailto:modules@perl.org">a
   modules@perl.org</a> si usted encuentra cualquier uni&oacute;n mal
   hecha entre el contenido del campo p&uacute;blico de la licencia y
   qu&eacute; la distribuci&oacute;n dice realmente sobre ella.
.
    },
    it => {
        title => 'Le Informazioni di DSLIP',
        intro => 'La lista completa delle opzioni possibili di DSLIP &egrave;:',
        disclaimer => <<'.',
<b>INFORMATIVA:</b> Lo stato del campo Pubblica Licenza &egrave; inteso
   solamente a fini informativi e non costituisce alcun legame legale di
   nessun genere. Per ottenere le opportune informazioni sui reali
   termini di licenza di un modulo e dei relativi file, siete pregati di
   riferirvi alla distribuzione del modulo o di mettervi in contatto con
   l'autore. Siete pregati di informare <a
   href="mailto:modules@perl.org">modules@perl.org</a> se incontrate
   qualunque incongruenza fra il contenuto del campo Pubblica Licenza e
   quello che la distribuzione realmente dice a proposito.
.
    },
};

die "Please run this from the top-level source directory"
  unless (-d 'htdocs');
my $pos = tell(DATA);
for my $lang (qw( de fr en es it )) {
  my $file = catfile 'htdocs', "dslip.html.$lang";
  my $tt = new Template();
  my $vars = {
              dslip       => $dslip->{$lang},
              dslip_order => $dslip_order,
              dslip_page  => $dslip_page->{$lang},
    };
  $tt->process( \*DATA, $vars, $file ) || die $tt->error(), "\n";
  seek(DATA, $pos, 0);
}
__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html ; charset=iso-8859-1">
  <title>[% dslip_page.title %]</title>
  <link rel="stylesheet" href="/htdocs/style.css" type="text/css">
</head>
<body>
  [% dslip_page.intro %] 
  <dl>
    [% FOREACH cat = [ 'd', 's', 'l', 'i', 'p'  ] %]
    <dt class="l1">[% FILTER upper %][% cat %][% END %] - [% dslip.$cat.desc %]</dt>
    <dd>
      <table>
      [%  FOREACH entry = dslip_order.$cat %]
        <tr>
          <td>[% entry %]</td>
          <td>&nbsp;-&nbsp;</td>
          <td>[% dslip.$cat.$entry %]</td>
        </tr>
      [% END %]
      </table>
    </dd>
    [% END %]
  </dl>
  <p>[% dslip_page.disclaimer %]</p>
  <hr>
</body>
</html>

