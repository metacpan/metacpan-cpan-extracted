package Acme::MetaSyntactic::pm_groups;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.030';
__PACKAGE__->init();

our %Remote = (
    source  => 'http://www.pm.org/groups/perl_mongers.xml',
    extract => sub {
        return
            map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
            map { s/#/Pound_/g; $_ }
            map { s/&([aeiouy])(?:acute|grave|circ|uml);/$1/g; $_ }
            $_[0] =~ m!<group id="\d+" status="active">\s*<name>\s*([^<]+)\s*</nam!g;
    },
);

1;

=head1 NAME

Acme::MetaSyntactic::pm_groups - The Perl Mongers groups theme

=head1 DESCRIPTION

List all the B<active> Perl Mongers groups, as described in the master
Perl Mongers file L<http://www.pm.org/groups/perl_mongers.xml>.

=head1 CONTRIBUTOR

Philippe Bruhat (BooK)

=head1 CHANGES

=over 4

=item *

2019-07-29 - v1.030

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.053.

=item *

2018-10-29 - v1.029

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.052.

=item *

2017-11-13 - v1.028

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.051.

=item *

2017-06-12 - v1.027

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.050.

=item *

2016-03-21 - v1.026

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.049.

=item *

2015-10-19 - v1.025

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.048.

=item *

2015-08-10 - v1.024

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.047.

=item *

2015-06-08 - v1.023

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.046.

=item *

2015-02-02 - v1.022

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.045.

=item *

2015-01-05 - v1.021

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.044.

=item *

2014-08-18 - v1.020

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.041.

=item *

2014-06-16 - v1.019

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.040.

=item *

2014-04-07 - v1.018

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-12-09 - v1.017

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.038.

=item *

2013-10-14 - v1.016

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.037.

=item *

2013-09-16 - v1.015

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.036.

=item *

2013-07-29 - v1.014

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.035.

=item *

2013-07-22 - v1.013

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.034.

=item *

2013-06-17 - v1.012

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.033.

=item *

2013-06-03 - v1.011

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.032.

=item *

2013-03-25 - v1.010

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.031.

=item *

2013-02-18 - v1.009

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.030.

=item *

2013-01-14 - v1.008

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.029.

=item *

2012-11-19 - v1.007

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.028.

=item *

2012-10-29 - v1.006

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.025.

=item *

2012-10-22 - v1.005

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.024.

=item *

2012-09-10 - v1.004

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.018.

=item *

2012-08-27 - v1.003

Added support for accented group names
in Acme-MetaSyntactic-Themes version 1.016.

=item *

2012-06-25 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.007.

=item *

2012-05-28 - v1.001

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.003.

=item *

2012-05-07 - v1.000

Updated with changes since November 2006, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-11-06

Updated from the source web site in Acme-MetaSyntactic version 0.99.

=item *

2006-10-09

Updated from the source web site in Acme-MetaSyntactic version 0.95.

=item *

2006-09-25

Updated from the source web site in Acme-MetaSyntactic version 0.93.

=item *

2006-09-11

Updated from the source web site in Acme-MetaSyntactic version 0.91.

=item *

2006-080-14

Updated from the source web site in Acme-MetaSyntactic version 0.87.

=item *

2006-07-10

Updated from the source web site in Acme-MetaSyntactic version 0.82.

=item *

2006-06-19

Updated from the source web site in Acme-MetaSyntactic version 0.79.

=item *

2006-06-05

Updated from the source web site in Acme-MetaSyntactic version 0.77.

=item *

2006-05-01

Updated from the source web site in Acme-MetaSyntactic version 0.72.

=item *

2006-03-06

Updated from the source web site in Acme-MetaSyntactic version 0.64.

=item *

2006-02-13

Updated from the source web site in Acme-MetaSyntactic version 0.61.

=item *

2006-02-06

Updated from the source web site in Acme-MetaSyntactic version 0.60.

=item *

2006-01-23

Updated from the source web site in Acme-MetaSyntactic version 0.58.

=item *

2006-01-09

Updated from the source web site in Acme-MetaSyntactic version 0.56.

=item *

2005-11-21

Introduced in Acme-MetaSyntactic version 0.49.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Albany_pm
Albuquerque_pm
Atlanta_pm
Austin_pm
Baltimore_pm
Boston_pm
Boulder_pm
Champaign_Urbana_pm
Chicago_pm
Cincinnati_pm
Cleveland_pm
Columbus_pm
DFW_pm
DC_pm
Denver_pm
DesMoines_pm
HudsonValley_pm
Houston_pm
KansasCity_pm
LasVegas_pm
Milwaukee_pm
Minneapolis_pm
Montreal_pm
OrangeCounty_pm
Ottawa_pm
Philadelphia_pm
Phoenix_pm
PDX_pm
Raleigh_pm
SanDiego_pm
SanFrancisco_pm
Seattle_pm
Sonoma_pm
StLouis_pm
Tallahassee_pm
Toronto_pm
Vancouver_pm
Curitiba_pm
Amsterdam_pm
Bath_pm
Braga_pm
Bratislava_pm
Bristol_pm
Edinburgh_pm
Glasgow_pm
Helsinki_pm
Copenhagen_pm
Leipzig_pm
Lisbon_pm
London_pm
Munich_pm
Paris_pm
Porto_pm
Roma_pm
Southampton_pm
SPb_pm
Torino_pm
Vienna_pm
Zagreb_pm
Brisbane_pm
Melbourne_pm
Perth_pm
Singapore_pm
Sydney_pm
Bandung_pm
Beijing_pm
Delhi_pm
HongKong_pm
Kyoto_pm
Pune_pm
Shanghai_pm
Israel_pm
Rehovot_pm
CapeTown_pm
Guimaraes_pm
SiliconValley_pm
Tempe_pm
Oslo_pm
Madrid_pm
Hyderabad_pm
Budapest_pm
Purdue_pm
Frankfurt_pm
Milan_pm
Coimbra_pm
Kansai_pm
Madras_pm
Granada_pm
Seneca_pm
Ulm_pm
AtlanticCity_pm
Los_Angeles_pm
Athens_pm
Qatar_pm
Chisinau_pm
Birmingham_pm
Colombo_pm
Toulouse_pm
Niederrhein_pm
Barcelona_pm
Santa_Fe_Los_Alamos_pm
Victoria_pm
Wellington_pm
Marseille_pm
Timisoara_pm
Salem_pm
Prague_pm
Bend_pm
Berlin_pm
Bergen_pm
SaltLake_pm
Nordest_pm
CaFe_pm
Tucson_pm
Devon_and_Cornwall_pm
Lyon_pm
Basel_pm
Bruxelles_pm
CAMEL_pm
Belgrade_pm
China_pm
Bucharest_pm
Mumbai_pm
Kw_pm
Dresden_pm
Cologne_pm
Hamburg_pm
Guatemala_pm
Helsingborg_pm
Vlaanderen_pm
Saarland_pm
Shibuya_pm
Pisa_pm
Arnhem_pm
Stuttgart_pm
Dahut_pm
Roederbergweg_pm
Bielefeld_pm
Nottingham_pm
Jerusalem_pm
Ankara_pm
Italia_pm
Geneva_pm
Paderborn_pm
Campinas_pm
BH_pm
Argentina_pm
Groningen_pm
Innsbruck_pm
Santiago_pm
Erlangen_pm
MiltonKeynes_pm
Darmstadt_pm
Ruhr_pm
Poznan_pm
Kaiserslautern_pm
Coimbatore_pm
Sophia_pm
Warszawa_pm
Hannover_pm
Szczecin_pm
Ithaca_pm
Tomar_pm
Fukuoka_pm
Vladivostok_pm
RostovOnDon_pm
Minsk_pm
Odessa_pm
Yokohama_pm
Krasnodar_pm
Fredericton_pm
Northwestengland_pm
Quito_pm
Kushiro_pm
Lima_pm
Advent_pm
Madurai_pm
Hokkaido_pm
Linz_pm
Nagoya_pm
Kamakura_pm
Kathmandu_pm
TelAviv_pm
Makati_pm
Bordeaux_pm
Petropolis_pm
Brno_pm
Logan_pm
SouthernOregon_pm
Plzen_pm
Sendai_pm
Kerman_pm
Cluj_pm
Niigata_pm
Hardware_pm
Duesseldorf_pm
Augsburg_pm
CorpusChristi_pm
Cochin_pm
AmsterdamX_pm
UKCoordinators_pm
Swindon_pm
NewTaipeiCity_pm
Gdansk_pm
Chico_pm
Gotanda_pm
Fleet_pm
Niceville_pm
Okinawa_pm
Ryazan_pm
BlairCountyPA_pm
Charlotte_pm
Madison_pm
