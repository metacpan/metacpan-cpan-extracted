#!/usr/bin/env perl
# t/132-error-mask-languages.t -- DBIO::MSSQL::Util::mask_error_details on the
# texts SQL Server writes when the session reports in another language,
# without a server (the live half is t/131).
#
# WHY this matters: SQL Server reports in the language of the session
# (SET LANGUAGE, the login's or the server's default). The English wording of
# the sentence rules is then gone, and a value the server quotes -- also a
# short one the bound-value pass does not look for -- stood in the exception.
# The masking goes by what does not change with the language: the number of the
# message and the marks the server quotes with. The texts below were
# measured (SQL Server 2022, DBD::Sybase and DBD::ODBC over FreeTDS 1.3.17).
# Where the server quotes no mark at all (Czech, Finnish, Swedish, Dutch ...)
# the value cannot be told from the words, and the text of that message falls
# away, the number stays.

use strict;
use warnings;
use utf8;
use Test::More;
use Time::HiRes ();

binmode(Test::More->builder->$_, ':utf8') for qw(output failure_output todo_output);
use DBIO::MSSQL::Util ();

sub mask { DBIO::MSSQL::Util::mask_error_details(@_) }

my $syb  = sub { my ($n, $t) = @_; "Server message number=$n severity=16 state=1 line=1 server=mssql-dev-0 text=$t" };
my $odbc = sub { my ($n, $t, $st) = @_; "[FreeTDS][SQL Server]$t (SQL-$st)" };

# [ language, number, sqlstate, text, value that must be gone, text that must stay ]
my @cases = (
  [ 'Deutsch', 245, '22018', 'Fehler beim Konvertieren des varchar-Werts "xy" in den int-Datentyp.',
    'xy', 'Fehler beim Konvertieren des varchar-Werts "***" in den int-Datentyp.' ],
  [ 'Français', 245, '22018', "Échec de la conversion de la valeur varchar 'xy' en type de données int.",
    'xy', "Échec de la conversion de la valeur varchar '***' en type de données int." ],
  [ 'Français', 245, '22018', "Échec de la conversion de la valeur varchar 'x'y' en type de données int.",
    "x'y", "Échec de la conversion de la valeur varchar '***' en type de données int." ],
  [ 'Español', 245, '22018', "Error de conversión al convertir el valor varchar 'xy' al tipo de datos int.",
    'xy', undef ],
  [ 'Polski', 245, '22018', 'Konwersja wartości „xy” obiektu varchar na typ danych int nie powiodła się.',
    'xy', 'Konwersja wartości „***” obiektu varchar na typ danych int nie powiodła się.' ],
  [ 'Magyar', 245, '22018', 'Az átalakítás leállt a(z) varchar érték („xy”) int adattípusúvá való átalakításakor.',
    'xy', 'Az átalakítás leállt a(z) varchar érték („***”) int adattípusúvá való átalakításakor.' ],
  [ '日本語', 245, '22018', "varchar の値 'xy' をデータ型 int に変換できませんでした。",
    'xy', "varchar の値 '***' をデータ型 int に変換できませんでした。" ],
  [ 'Deutsch', 244, 'HY019', 'Die Konvertierung des varchar-Werts "3000000000" führte zum Überlauf einer INT1-Spalte. Verwenden Sie eine Spalte mit ganzen Zahlen höherer Größe.',
    '3000000000', 'Die Konvertierung des varchar-Werts "***" führte zum Überlauf einer INT1-Spalte. Verwenden Sie eine Spalte mit ganzen Zahlen höherer Größe.' ],
  [ 'Français', 248, 'HY019', "La conversion de la valeur varchar '99999999999' a dépassé une colonne int.",
    '99999999999', "La conversion de la valeur varchar '***' a dépassé une colonne int." ],
  [ 'Deutsch', 2627, '23000', 'Verletzung der UNIQUE KEY-Einschränkung "UQ__t_u". Ein doppelter Schlüssel kann in das dbo.t-Objekt nicht eingefügt werden. Der doppelte Schlüsselwert ist (ab).',
    'ab', 'Verletzung der UNIQUE KEY-Einschränkung "UQ__t_u". Ein doppelter Schlüssel kann in das dbo.t-Objekt nicht eingefügt werden. Der doppelte Schlüsselwert ist (***).' ],
  [ 'Français', 2627, '23000', "Violation de la contrainte UNIQUE KEY « UQ__t_u ». Impossible d'insérer une clé en double dans l'objet « dbo.t ». Valeur de clé dupliquée : (ab).",
    'ab', "Violation de la contrainte UNIQUE KEY « UQ__t_u ». Impossible d'insérer une clé en double dans l'objet « dbo.t ». Valeur de clé dupliquée : (***)." ],
  [ 'Français', 2601, '23000', "Impossible d'insérer une ligne de clé en double dans l'objet « dbo.x » avec un index unique « x_ux ». Valeur de clé dupliquée : (a, b) c).",
    'b) c', "Impossible d'insérer une ligne de clé en double dans l'objet « dbo.x » avec un index unique « x_ux ». Valeur de clé dupliquée : (***)." ],
  [ 'Čeština', 2627, '23000', 'Porušení omezení PRIMARY KEY PK__t. Nelze vložit duplicitní klíč do objektu dbo.t.Hodnota duplicitního klíče je(ab).',
    'ab', 'Porušení omezení PRIMARY KEY PK__t. Nelze vložit duplicitní klíč do objektu dbo.t.Hodnota duplicitního klíče je(***).' ],
  [ '日本語', 2627, '23000', "制約 'PK__t' の PRIMARY KEY 違反。オブジェクト 'dbo.t' には重複するキーを挿入できません。重複するキーの値は (ab) です。",
    'ab', "制約 'PK__t' の PRIMARY KEY 違反。オブジェクト 'dbo.t' には重複するキーを挿入できません。重複するキーの値は (***) です。" ],
  [ 'Deutsch', 2628, '42000', 'Zeichenfolgen- oder Binärdaten werden in Tabelle "tempdb.dbo.t", Spalte "s" abgeschnitten. Abgeschnittener Wert: geheim.',
    'geheim', 'Zeichenfolgen- oder Binärdaten werden in Tabelle "tempdb.dbo.t", Spalte "s" ***' ],
  [ 'Italiano', 2628, '42000', "I dati stringa o binari verranno troncati nella tabella 'tempdb.dbo.t', colonna 's'. Valore troncato: (geheim).",
    'geheim', "I dati stringa o binari verranno troncati nella tabella 'tempdb.dbo.t', colonna 's' ***" ],
  [ 'Español', 2628, '42000', 'Los datos binarios o de la cadena se truncan en la columna "s" de la tabla "tempdb.dbo.t". Valor truncado: "geheim".',
    'geheim', 'Los datos binarios o de la cadena se truncan en la columna "s" de la tabla "tempdb.dbo.t" ***' ],
  [ 'Deutsch', 102, '42000', 'Falsche Syntax in der Nähe von "GARB".',
    'GARB', 'Falsche Syntax in der Nähe von "***".' ],
  [ 'Français', 102, '42000', "Syntaxe incorrecte vers 'GARB'.",
    'GARB', "Syntaxe incorrecte vers '***'." ],
  [ 'Deutsch', 13609, '42000', 'Der JSON-Text ist nicht ordnungsgemäß formatiert. An Position 0 wurde das unerwartete Zeichen "g" gefunden.',
    '"g"', 'Der JSON-Text ist nicht ordnungsgemäß formatiert. An Position 0 wurde das unerwartete Zeichen "***" gefunden.' ],
  [ 'Français', 13609, '42000', "Le format du texte JSON n'est pas correct. Un caractère inattendu « g » se trouve à la position 0.",
    'g »', "Le format du texte JSON n'est pas correct. Un caractère inattendu «***» se trouve à la position 0." ],
  [ 'Čeština', 13609, '42000', 'Text JSON není správně naformátovaný. Na pozici 0 je neočekávaný znak „g“.',
    '„g“', 'Text JSON není správně naformátovaný. Na pozici 0 je neočekávaný znak „***“.' ],
);

# no mark to take hold of: the text of the message falls away, the number stays
my @withheld = (
  [ 'Čeština', 245, '22018', 'Převod datového typu varchar s hodnotou xy@z na datový typ int se nezdařil.', 'xy@z' ],
  [ 'Suomi', 244, 'HY019', 'Kohteen varchar arvon 3000000000 muuntaminen aiheutti ylivuodon sarakkeessa INT1.', '3000000000' ],
  [ 'Svenska', 2628, '42000', 'Sträng- eller binärdata skulle trunkeras i tabell tempdb.dbo.t, kolumn s. Trunkerat värde: geheim.', 'geheim' ],
  [ 'Čeština', 102, '42000', 'Nesprávná syntaxe poblíž textu GARB.', 'GARB' ],
  [ 'Русский', 13609, '42000', 'Текст JSON имеет неправильный формат. В позиции 0 найден непредвиденный символ g.', 'символ g' ],
);

for my $c (@cases) {
  my ($lang, $n, $state, $text, $value, $want) = @$c;
  my $label = "$lang $n";

  my $s = mask($syb->($n, $text), [ $value =~ /\A\w{4,}\z/ ? $value : () ]);
  unlike $s, qr/\Q$value\E/, "$label [sybase]: the value is gone";
  is $s, $syb->($n, $want), "  the rest stays" if defined $want and $want !~ /\*\*\* *\z/;
  like $s, qr/\Q$n\E/, '  the number stays';
  is mask($s), $s, '  idempotent';

  # DBD::ODBC: the numbers the handle reported ...
  my $o = mask($odbc->($n, $text, $state), undef, undef, [ [ $n, "[FreeTDS][SQL Server]$text" ] ]);
  unlike $o, qr/\Q$value\E/, "$label [odbc, number reported]: the value is gone";
  is $o, $odbc->($n, $want, $state), '  the rest stays' if defined $want and $want !~ /\*\*\* *\z/;

  # ... as bytes, which is how the DBD hands the text over
  if ($text =~ /[^\x00-\x7F]/) {
    my ($bt, $bw) = ($odbc->($n, $text, $state), $odbc->($n, $want // '', $state));
    utf8::encode($bt); utf8::encode($bw);
    my $diag = "[FreeTDS][SQL Server]$text"; utf8::encode($diag);
    my $b = mask($bt, undef, undef, [ [ $n, $diag ] ]);
    ok !utf8::is_utf8($b), "$label [odbc, bytes]: still bytes";
    my $v = $value; utf8::encode($v);
    unlike $b, qr/\Q$v\E/, '  the value is gone';
    is $b, $bw, '  the rest stays' if defined $want and $want !~ /\*\*\* *\z/;
  }
}

# a form the SQLSTATE alone decides (no record of the handle)
for my $c (@cases) {
  my ($lang, $n, $state, $text, $value) = @$c;
  next unless $n == 245 or $n == 244 or $n == 248 or $n == 2627;
  my $o = mask($odbc->($n, $text, $state));
  unlike $o, qr/\Q$value\E/, "$lang $n [odbc, SQLSTATE $state only]: the value is gone";
}

for my $c (@withheld) {
  my ($lang, $n, $state, $text, $value) = @$c;
  my $s = mask($syb->($n, $text));
  unlike $s, qr/\Q$value\E/, "$lang $n [sybase]: the value is gone";
  like $s, qr/number=$n .* text=\(text withheld/, '  the number stays, the text falls away';
  my $o = mask($odbc->($n, $text, $state), undef, undef, [ [ $n, "[FreeTDS][SQL Server]$text" ] ]);
  unlike $o, qr/\Q$value\E/, "$lang $n [odbc]: the value is gone";
  like $o, qr/\(text withheld.*\(SQL-$state\)/, '  the SQLSTATE stays, the text falls away';
}

# two messages: only the one with a number of the list is touched
{
  my $t = $syb->(2627, 'Verletzung der PRIMARY KEY-Einschränkung "PK_t". Ein doppelter Schlüssel kann in das dbo.t-Objekt nicht eingefügt werden. Der doppelte Schlüsselwert ist (ab).')
        . "\n" . $syb->(3621, 'Die Anweisung wurde beendet.');
  my $m = mask($t);
  like $m, qr/Schlüsselwert ist \(\*\*\*\)\.\nServer message number=3621 .* text=Die Anweisung wurde beendet\.\z/,
    'the message after it stays as it is';
}

# what carries no value is not touched, in any language
for my $c (
  [ 156, 'Falsche Syntax in der Nähe des FROM-Schlüsselworts.' ],
  [ 8114, 'Fehler beim Konvertieren des varchar-Datentyps in numeric.' ],
  [ 547, 'Die INSERT-Anweisung steht in Konflikt mit der FOREIGN KEY-Einschränkung "FK_t_p". Der Konflikt trat in der "d"-Datenbank, Tabelle "dbo.p", column \'id\' auf.' ],
) {
  my $t = $syb->(@$c);
  is mask($t), $t, "number $c->[0]: a message without a value is as it is";
}

# the text of the TEXTSIZE guard of the Sybase class names a column, no value, in any language
{
  my $t = $syb->(245, "Fehler beim Konvertieren des varchar-Werts \"DBIO::MSSQL TEXTSIZE guard: column 'body' holds a value longer than the session's TEXTSIZE, 32768 bytes\" in den int-Datentyp.");
  is mask($t), $t, 'the TEXTSIZE guard text stays';
}

# a cut message: a value with a mark inside, no closing mark
{
  my $long = "geheim'42" . ('x' x 3000);
  my $m = mask($syb->(245, "Fehler beim Konvertieren des varchar-Werts \"$long"));
  unlike $m, qr/geheim|xxx/, 'a cut message is masked to its end';
}

# no backtracking blow-up on big input
for my $case (
  [ 2628 => '"a" ' . ('"' x 100_000) ],
  [ 2628 => ('„x“ ' x 25_000) ],
  [ 245  => ("'" x 100_000) ],
  [ 245  => ('d\'x ' x 25_000) ],
  [ 2627 => ('(' x 100_000) ],
) {
  my ($n, $text) = @$case;
  my $t0 = [ Time::HiRes::gettimeofday ];
  my $got = mask($syb->($n, $text));
  my $took = Time::HiRes::tv_interval($t0);
  cmp_ok $took, '<', 2, "fast on 100 KB: number $n (" . sprintf('%.3f', $took) . ' s)';
  ok defined $got, '  answers';
}

done_testing;
