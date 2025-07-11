#!/usr/bin/env perl

use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use Data::OFN::Thing;
use Data::Text::Simple;
use DateTime;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $obj = Data::OFN::Thing->new(
        'created' => Data::OFN::Common::TimeMoment->new(
                'date_and_time' => DateTime->new(
                        'day' => 27,
                        'month' => 9,
                        'year' => 2019,
                        'hour' => 9,
                        'minute' => 30,
                        'time_zone' => '+02:00',
                ),
        ),
        'description' => [
                Data::Text::Simple->new(
                        'lang' => 'cs',
                        'text' => decode_utf8("Ve čtvrtek 26. září večer došlo k loupeži banky na Masarykově náměstí.\nLupič pak prchal směrem ven z města. Obsluha městského kamerového systému incident zaznamenala,\nstrážníci městské policie zastavili auto ve Francouzské ulici a přivolali státní policii.\nTi záležitost převzali k dořešení. Pachateli hrozí až 10 let za mřížemi."),
                ),
                Data::Text::Simple->new(
                        'lang' => 'en',
                        'text' => decode_utf8("On Thursday evening, September 26, the bank was robbed on Masaryk Square.\nThe robber then fled out of town. The operator of the city's camera system recorded the incident,\nthus the city police officers were able to identify and stop the car in Francouzská Street and called the state police.\nThey took over the matter. Offenders face up to 10 years behind bars."),
                ),
        ],
        'id' => 7,
        'iri' => decode_utf8('https://www.trebic.cz/zdroj/aktualita/2020/dopadení-lupiče-na-francouzské-ulici'),
        'name' => [
                Data::Text::Simple->new(
                        'lang' => 'cs',
                        'text' => decode_utf8('Díky policistům byl lupič dopaden'),
                ),
                Data::Text::Simple->new(
                        'lang' => 'en',
                        'text' => 'Culprit was immediately caught, thanks to the police.',
                ),
        ],
        'relevant_to' => Data::OFN::Common::TimeMoment->new(
                'date_and_time' => DateTime->new(
                        'day' => 27,
                        'month' => 11,
                        'year' => 2019,
                        'hour' => 9,
                        'time_zone' => '+02:00',
                ),
        ),
);

sub _text {
        my $obj = shift;

        return encode_utf8($obj->text.' ('.$obj->lang.')');
}

# Print out.
print 'Id: '.$obj->id."\n";
print 'Name: '._text($obj->name->[0])."\n";
print 'Name: '._text($obj->name->[1])."\n";
print 'Description: '._text($obj->description->[0])."\n";
print 'Description: '._text($obj->description->[1])."\n";
print 'IRI: '.encode_utf8($obj->iri)."\n";
print 'Created: '.$obj->created->date_and_time."\n";
print 'Relevant to: '.$obj->relevant_to->date_and_time."\n";

# Output:
# Id: 7
# Name: Díky policistům byl lupič dopaden (cs)
# Name: Culprit was immediately caught, thanks to the police. (en)
# Description: Ve čtvrtek 26. září večer došlo k loupeži banky na Masarykově náměstí.
# Lupič pak prchal směrem ven z města. Obsluha městského kamerového systému incident zaznamenala,
# strážníci městské policie zastavili auto ve Francouzské ulici a přivolali státní policii.
# Ti záležitost převzali k dořešení. Pachateli hrozí až 10 let za mřížemi. (cs)
# Description: On Thursday evening, September 26, the bank was robbed on Masaryk Square.
# The robber then fled out of town. The operator of the city's camera system recorded the incident,
# thus the city police officers were able to identify and stop the car in Francouzská Street and called the state police.
# They took over the matter. Offenders face up to 10 years behind bars. (en)
# IRI: https://www.trebic.cz/zdroj/aktualita/2020/dopadení-lupiče-na-francouzské-ulici
# Created: 2019-09-27T09:30:00
# Relevant to: 2019-11-27T09:00:00