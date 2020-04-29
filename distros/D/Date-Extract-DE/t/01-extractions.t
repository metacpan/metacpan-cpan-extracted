#!/usr/bin/env perl

use Test::More;

use warnings;
use strict;
use utf8;

use Date::Simple;

use_ok 'Date::Extract::DE';

my @examples = (
    {   text =>
            'Einmal gab es bereits einen Pop-up-Store in der Bezirkshauptstadt: Barbara Rapolter, die fünf Jahre ihre Boutique „spiriti‘m“ in der Innenstadt betrieb, bot für kurze Zeit Ende Mai 2019 Mode in der ehemaligen Styx-Filiale am Rathausplatz an. VP-Stadträtin Ute Reisinger und Zunftzeichen-Obfrau Ilse Kossarz wollen das Modell um die temporären Geschäfte, die vorübergehend in Leerstände ziehen, weiter forcieren. Am Montag, 20. Jänner, findet um 19 Uhr im Wachauerhof eine Info-Veranstaltung statt. Max Homolka, Geschäftsführer des Stadtmarketing Enns, erzählt dabei von seinen Erfahrungen.',
        dts => [qw/2020-01-20/]
    },
    {   text =>
            'GEMEINLEBARN Die „Kreative Runde“ in Gemeinlebarn lädt am Mittwoch, 15. Jänner, ab 15 Uhr zu einer „Mittendrin“-Veranstaltung in das Feuerwehrhaus Gemeinlebarn recht herzlich ein.

    TRAISMAUER Am Samstag, 18. Jänner, findet ab 10 Uhr in der Städtischen Turnhalle Traismauer ein Dart- Turnier in mehreren Kategorien statt. Organisiert wird das Turnier vom SC Traismauer. Um Anmeldung wird gebeten.

    WAGRAM Die Landjugend lädt am Samstag, 18. Jänner, ab 19.30 Uhr in den Landgasthof Huber in Wagram zum Ball.

    GEMEINLEBARN Am Donnerstag, 23. Jänner, findet ab 19.30 Uhr im Gasthof Windhör in Gemeinlebarn ein Wirtshaussingen der Lewinger Gigerl statt.

    TRAISMAUER Der Musikverein Traismauer lädt am Sonntag, 26. Jänner, ab 16 Uhr in die Städtische Turnhalle zum Jugend-Faschingskonzert.
',
        dts => [qw/2020-01-15 2020-01-18 2020-01-18 2020-01-23 2020-01-26/]
    },
    {   text =>
            'Ein besonders wichtiges Thema in der Gemeinde ist derzeit natürlich der Ausbau des Glasfasernetzes, der im Frühjahr starten soll. „Wer noch die günstigen Konditionen nutzen will – der Anschluss kostet pro Haushalt 300 Euro – der hat noch bis 17.Februar dazu Zeit“, berichtete die Ortschefin.',
        dts => [qw/2020-02-17/]
    },
    {   text => 'Die (un)heimlichen Miterzieher“. Anschließend
    Diskussion. Eintritt 5 Euro. Eine Veranstaltung des Katholischen
    Bildungswerks. Infos bei Charlotte Ennser',
        dts => []
    },
    {   text =>
            'Am Freitag, den 1.5. finden zahlreiche Veranstaltung heuer nur vorm Bildschirm statt.',
        dts => [qw/2020-05-01/]
    },
    {   text =>
            'Der beliebte Markt wird heuer vom 4. bis zum 6. Mai am Hauptplatz stattfinden',
        dts => [qw/2020-05-04 2020-05-05 2020-05-06/]
    },
    {   text =>
            'Am 11. und 14. Mai finden Sondersprechstundentage des Bürgermeisters statt',
        dts => [qw/2020-05-11 2020-05-14/]
    },
    {   text =>
            'Zwischen 11. und 14. Mai 2021 werden verstärkt Sternschnuppen zu beobachten sein',
        dts => [qw/2021-05-11 2021-05-12 2021-05-13 2021-05-14/]
    },
    {   text =>
            'Das Angebot gilt vom 29. Mai bis zum 2. Juni zu den üblichen Bedingunen',
        dts => [qw/2020-05-29 2020-05-30 2020-05-31 2020-06-01 2020-06-02/]
    },
    {   text =>
            "Grazer Augartenfest: Das 40. Augartenfest in Graz (geplant am 27. Juni) fällt ins Wasser.",
        dts => [qw/2020-06-27/]
    },
    {   text =>
            "Genauso ist es beim Auftritt der Saxofon-Queen Candy Dulfer, der nun am 14. November stattfindet.",
        dts => [qw/2020-11-14/]
    },
    {   text =>
            "Am 16. März wurden viele Veranstaltung der kommenden Monate abgesagt",
        dts => [qw/2020-03-16/]
    },
);

my $ref_date = Date::Simple::ymd( 2020, 01, 01 );
my $parser = Date::Extract::DE->new(
    reference_date => $ref_date,
    lookback_days  => 31
);
my $i = 0;
foreach (@examples) {
    ++$i;
    my $dates    = $parser->extract( $_->{text} );
    my $got      = [ map { $_->as_iso } @$dates ];
    my $expected = $_->{dts};
    is_deeply(
        $got,
        $expected,
        sprintf(
            'Example %s: All expected dates found ([%s] vs. [%s])',
            $i,
            join( ' ', @$got ),
            join( ' ', @$expected )
        )
    );
}
done_testing;
