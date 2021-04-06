# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Perl DateTime extension for providing Italian strings for the French Revolutionary calendar
# Copyright (c) 2021 Jean Forget. All rights reserved.
#
# See the license in the embedded documentation below.
#

package DateTime::Calendar::FrenchRevolutionary::Locale::it;

use utf8;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.17'; # same as parent module DT::C::FR

my @months_short  = qw (Vnd Bru Fri Nev Pio Vnt Ger Fio Pra Mes Ter Fru G-S);

# based on Gibus' App::SpreadRevolutionaryDate, itself 
# based on Wikipedia: L<https://it.wikipedia.org/wiki/Calendario_rivoluzionario_francese>.
my @months = qw(Vendemmiaio Brumaio   Frimaio   
                Nevoso      Piovoso   Ventoso   
                Germile     Fiorile   Pratile   
                Messidoro   Termidoro Fruttidoro
    );

push @months, 'giorni supplementari';

my @decade_days = qw (Primidi Duodi Tridi Quartidi Quintidi Sestidi Settidi Ottidi Nonidi Decadi);
my @decade_days_short = qw (Pri Duo Tri Qua Qui Sex Set Ott Non Dec);

my @am_pms = qw(AM PM);

my $date_before_time = "1";
my $default_date_format_length = "medium";
my $default_time_format_length = "medium";
my $date_parts_order = "dmy";

my %date_formats = (
    "short"  => "\%d\/\%m\/\%Y",
    "medium" => "\%a\ \%d\ \%b\ \%Y",
    "long"   => "\%A\ \%d\ \%B\ \%EY",
    "full"   => "\%A\ \%d\ \%B\ \%EY\,\ \%{feast_long\}",
);

my %time_formats = (
    "short"  => "\%H\:\%M",
    "medium" => "\%H\:\%M\:\%S",
    "long"   => "\%H\:\%M\:\%S",
    "full"   => "\%H\ h\ \%M\ mn \%S\ s",
);

# When initializing an array with lists within lists, it means one of two things:
# Either it is a newbie who does not know how to make multi-dimensional arrays,
# Or it is a (at least mildly) experienced Perl-coder who, for some reason, 
# wants to initialize a flat array with the concatenation of lists.
# I am a (at least mildly) experienced programmer who wants to use qw() and yet insert
# comments in some places.
# This array is mainly based on Gibus' App::SpreadRevolutionaryDate, itself 
# based on Wikipedia: L<https://es.wikipedia.org/wiki/Calendario_republicano_franc%C3%A9s>.
my @feast = (
    # Vendémiaire https://it.wikipedia.org/wiki/Vendemmiaio
    qw(
      2uva             1zafferano    3castagna        0colchico    0cavallo
      3balsamina       3carota       2amaranto        3pastinaca   0tino
      3patata          0perpetuino   3zucca           3reseda      2asino
      3bella_di_notte  3zucca        0grano_saraceno  0girasole    0torchio
      3canapa          0pesca        3rapa            2amarillide  0bue
      3melanzana       0peperoncino  0pomodoro        2orzo        0barile
    ),
    # Brumaire https://it.wikipedia.org/wiki/Brumaio
    qw(
      0mela            0sedano            3pera         3barbabietola  2oca
      2eliotropio      0fico              3scorzonera   0ciavardello   2aratro
      3barba_di_becco  3castagna_d'acqua  0topinambur   2indivia       0tacchino
      0sisaro          0crescione         3piombaggine  0melograno     2erpice
      0baccaro         2azzeruolo         3robbia       2arancia       0fagiano
      0pistacchio      3cicerchia         0cotogno      0sorbo         0rullo
    ),
    # Frimaire https://it.wikipedia.org/wiki/Frimaio
    qw(
      0raponzolo          3rapa        3cicoria  0nespolo  0maiale
      0soncino            0cavolfiore  0miele    0ginepro  3zappa
      3cera               0rafano      0cedro    2abete    0capriolo
      0ginestrone         0cipresso    3edera    3sabina   3ascia
      2acero_da_zucchero  2erica       3canna    2acetosa  0grillo
      0pino               0sughero     0tartufo  2oliva    3pala
    ),
    # Nivôse https://it.wikipedia.org/wiki/Nevoso
    qw(
      3torba    0carbone_bituminoso  0bitume   0zolfo     0cane
      3lava     3terra_vegetale      0letame   0salnitro  0correggiato
      0granito  3argilla             2ardesia  2arenaria  0coniglio
      3selce    3marna               0calcare  0marmo     0setaccio
      0gesso    0sale                0ferro    0rame      0gatto
      0stagno   0piombo              0zinco    0mercurio  0colino
    ),
    # Pluviôse https://it.wikipedia.org/wiki/Piovoso
    qw(
      3dafne_laurella  0muschio          0pungitopo  0bucaneve    0toro
      0viburno         0fungo_dell'esca  3camalea    0pioppo      1scure
      0elleboro        0broccolo         2alloro     0nocciolo    3vacca
      0bosso           0lichene          0tasso      3polmonaria  0coltello_da_potatura
      0thlaspi         3dafne_odorosa    3gramigna   0centinodio  3lepre
      0guado           0nocciolo         0ciclamino  3celidonia   3slitta
    ),
    # Ventôse https://it.wikipedia.org/wiki/Ventoso
    qw(
      3tossillagine    0corniolo    3violacciocca  0ligustro    0caprone
      0baccaro_comune  2alaterno    3violetta      0salicone    3vanga
      0narciso         2olmo        3fumaria       2erisimo     3capra
      0spinacio        0doronico    3primula       0cerfoglio   3corda
      3mandragola      0prezzemolo  3coclearia     3margherita  0tonno
      0dente_di_leone  2anemone     0capelvenere   0frassino    0piantatoio
    ),
    # Germinal https://it.wikipedia.org/wiki/Germinale
    qw(
      3primula          0platano  2asparago            0tulipano   3gallina
      3bietola          3betulla  0narciso             0ontano     3covata
      3pervinca         0carpino  3spugnola            0faggio     2ape
      3lattuga          0larice   3cicuta              0ravanello  2arnia
      2albero_di_Giuda  3lattuga  0ippocastano         3rucola     0piccione
      0lillà            2anemone  3viola_del_pensiero  0mirtillo   0coltello_da_innesto
    ),
    # Floréal https://it.wikipedia.org/wiki/Fiorile
    qw(
      3rosa                3quercia         3felce                0biancospino  0usignolo
      2aquilegia           0mughetto        0fungo                0giacinto     0rastrello
      0rabarbaro           3lupinella       3violacciocca_gialla  3lonicera     0baco_da_seta
      3consolida_maggiore  3pimpinella      2alisso_sassicolo     2atriplice    0sarchiello
      3statice             3fritillaria     3borragine            3valeriana    3carpa
      3fusaggine           3erba_cipollina  3buglossa             0senape       0vincastro
    ),
    # Prairial https://it.wikipedia.org/wiki/Pratile
    qw(
      3erba_medica  2emerocallide     0trifoglio         2angelica       2anatra
      3melissa      2avena_altissima  0giglio_martagone  0timo_serpillo  3falce
      3fragola      3betonica         0pisello           3acacia         3quaglia
      0garofano     0sambuco          0papavero          0tiglio         0forcone
      0fiordaliso   3camomilla        0caprifoglio       0caglio         3tinca
      0gelsomino    3verbena          0timo              3peonia         0carro
    ),
    # Messidor https://it.wikipedia.org/wiki/Messidoro
    qw(
      3segale      2avena     3cipolla       3veronica  0mulo
      0rosmarino   0cetriolo  1scalogno      2assenzio  0falcetto
      0coriandolo  0carciofo  3violacciocca  3lavanda   0camoscio
      0tabacco     0ribes     3cicerchia     3ciliegia  2ovile
      3menta       0cumino    0fagiolo       2alcanna   3faraona
      3salvia      2aglio     3veccia        0grano     3ciaramella
    ),
    # Thermidor https://it.wikipedia.org/wiki/Termidoro
    qw(
      1spelto          0tasso_barbasso  0melone      0loglio    2ariete
      2equiseto        2artemisia       0cartamo     3mora      2annaffiatoio
      2eringio         3salicornia      2albicocca   0basilico  3pecora
      2altea           0lino            3mandorla    3genziana  3chiusa
      3carlina_bianca  0cappero         3lenticchia  2enula     3lontra
      0mirto           3colza           0lupino      0cotone    0mulino
    ),
    # Fructidor https://it.wikipedia.org/wiki/Fruttidoro
    qw(
      3prugna         0miglio       3vescia      2orzo_maschio      0salmone
      3tuberosa       2orzo_comune  2apocino     3liquirizia        3scala
      3anguria        0finocchio    3crespino    0noce              3trota
      0limone         0cardo        2alaterno    0garofano_d'India  3gerla
      3rosa_canina    3nocciola     0luppolo     0sorgo             0gambero
      2arancio_amaro  3verga_d'oro  0granoturco  3castagna          3cesta
    ),
    # Jours complémentaires
    qw(
      3virtù        0genio  0lavoro  2opinione  4ricompense
      3rivoluzione
    ),
 );
my @prefix = ( 'giorno del '
             , 'giorno dello '
             , "giorno dell'"
             , 'giorno della '
             , 'giorno delle '
    );

my %event = ();

sub new {
  return bless {},  $_[0];
}

sub month_name {
    my ($self, $date) = @_;
    return $months[$date->month_0]
}

sub month_abbreviation {
    my ($self, $date) = @_;
    return $months_short[$date->month_0]
}

sub day_name {
    my ($self, $date) = @_;
    return $decade_days[$date->day_of_decade_0];
}

sub day_abbreviation {
    my ($self, $date) = @_;
    return $decade_days_short[$date->day_of_decade_0];
}

sub am_pm { $_[0]->am_pms->[ $_[1]->hour < 5 ? 0 : 1 ] }

sub _raw_feast {
  my ($self, $date) = @_;
  $feast[$date->day_of_year_0];
}

sub feast_short {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0];
  $lb =~ s/^\?//;
  $lb =~ s/_/ /g;
  return substr($lb, 1);
}

sub feast_long {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0];
  $lb =~ s/^\?//;
  $lb =~ s/_/ /g;
  $lb =~ s/^(\d)/$prefix[$1]/;
  return $lb;
}

sub feast_caps {
  my ($self, $date) = @_;
  my $lb = $feast[$date->day_of_year_0];
  $lb =~ s/^\?//;
  $lb =~ s/_/ /g;
  $lb =~ s/^(\d)(.)/\u$prefix[$1]\u$2/;
  return $lb;
}

sub    full_date_format      { $_[0]->date_formats->{full} }
sub    long_date_format      { $_[0]->date_formats->{long} }
sub  medium_date_format      { $_[0]->date_formats->{medium} }
sub   short_date_format      { $_[0]->date_formats->{short} }
sub default_date_format      { $_[0]->date_formats->{ $_[0]->default_date_format_length } }

sub    full_time_format      { $_[0]->time_formats->{full} }
sub    long_time_format      { $_[0]->time_formats->{long} }
sub  medium_time_format      { $_[0]->time_formats->{medium} }
sub   short_time_format      { $_[0]->time_formats->{short} }
sub default_time_format      { $_[0]->time_formats->{ $_[0]->default_time_format_length } }

sub _datetime_format_pattern_order { $_[0]->date_before_time ? (0, 1) : (1, 0) }

sub    full_datetime_format { join ' ', ( $_[0]->   full_date_format, $_[0]->   full_time_format )[ $_[0]->_datetime_format_pattern_order ] }
sub    long_datetime_format { join ' ', ( $_[0]->   long_date_format, $_[0]->   long_time_format )[ $_[0]->_datetime_format_pattern_order ] }
sub  medium_datetime_format { join ' ', ( $_[0]-> medium_date_format, $_[0]-> medium_time_format )[ $_[0]->_datetime_format_pattern_order ] }
sub   short_datetime_format { join ' ', ( $_[0]->  short_date_format, $_[0]->  short_time_format )[ $_[0]->_datetime_format_pattern_order ] }
sub default_datetime_format { join ' ', ( $_[0]->default_date_format, $_[0]->default_time_format )[ $_[0]->_datetime_format_pattern_order ] }

sub default_date_format_length { $default_date_format_length }
sub default_time_format_length { $default_time_format_length }

sub month_names                { [ @months ] }
sub month_abbreviations        { [ @months_short ] }
sub day_names                  { [ @decade_days ] }
sub day_abbreviations          { [ @decade_days_short ] }
sub am_pms                     { [ @am_pms ] }
sub date_formats               { \%date_formats         }
sub time_formats               { \%time_formats         }
sub date_before_time           { $date_before_time      }
sub date_parts_order           { $date_parts_order      }

sub on_date {
  return '';
}

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
"Ah ! ça ira ! ça ira !";

__END__

=encoding utf8

=head1 NAME

DateTime::Calendar::FrenchRevolutionary::Locale::it -- Italian localization for the French 
revolutionary calendar.

=head1 SYNOPSIS

  use DateTime::Calendar::FrenchRevolutionary::Locale;
  my $italian_locale = DateTime::Calendar::FrenchRevolutionary::Locale->load('it');

  my $italian_month_name =$italian_locale->month_name($date);

=head1 DESCRIPTION

This module provides localization for DateTime::Calendar::FrenchRevolutionary.
Usually, its methods will be invoked only from DT::C::FR.

=head1 USAGE

This module provides the following class methods:

=over 4

=item * new

Returns an  object instance,  which is just  a convenient value  to be
stored in a variable.

Contrary to  the widely used Gregorian  calendar, there is  no need to
customize a French Revolutionary calendar locale. Therefore, there are
no instance data and no instance methods.

=item * month_name ($date)

Returns an Italian translation for C<$date>'s month, where C<$date> is
a C<DateTime::Calendar::FrenchRevolutionary> object.

=item * month_abbreviation ($date)

Returns a 3-letter abbreviation for the Italian month name.

=item * day_name ($date)

Returns an Italian translation for the day name.

=item * day_abbreviation ($date)

Returns a 3-letter abbreviation for the Italian day name.

=item * am_pm ($date)

Returns a code (typically C<AM> or C<PM>) showing whether the datetime
is in the morning or the  afternoon. Outside the sexagesimal time with
a 1..12 hour range, this is not very useful.

=item * feast_short ($date)

Hopefully  returns  an adequate  italian  translation  for the  plant,
animal or tool that correspond to C<$date>'s feast.

Note: in some cases, the feast French name is left untranslated, while
in some other cases, the  translation is inadequate. If you are fluent
in both French and Italian, do not hesitate to send corrections to the
author.

=item * feast_long ($date)

Same as C<feast_short>, with a "day" prefix.

=item * feast_caps ($date)

Same as C<feast_long> with capitalized first letters.

=item * on_date ($date)

Not implemented for the Italian locale. This method returns an empty string.

=item * full_date_format, long_date_format, medium_date_format, short_date_format

Class  methods,  giving four  C<strftime>  canned  formats for  dates,
without the need to remember all the C<%> specifiers.

=item * full_time_format, long_time_format, medium_time_format, short_time_format

Same thing, C<strftime> canned formats for decimal time.

=item * full_datetime_format, long_datetime_format, medium_datetime_format, short_datetime_format

Same thing, for formats including both the date and the decimal time.

=item * default_date_format, default_time_format, default_datetime_format

Class methods  suggesting one each  of the  date formats, of  the time
formats and of the datetime formats.

=item * full_time_format, long_time_format, medium_time_format, short_time_format

Same thing, C<strftime> canned formats for decimal time.

=item * full_datetime_format, long_datetime_format, medium_datetime_format, short_datetime_format

Same thing, for formats including both the date and the decimal time.

=item * default_date_format, default_time_format, default_datetime_format

Class methods  suggesting one each  of the  date formats, of  the time
formats and of the datetime formats.

=item * default_date_format_length, default_time_format_length

While  C<default_date_format>  and   C<default_time_format>  give  the
actual default formats, with C<%> and  all, these class methods give a
one-word  description of  the  default  formats: C<short>,  C<medium>,
C<long> or C<full>.

=item * date_formats, time_formats

These  class methods  give a  hashtable where  the key  is the  length
(C<short>,  C<medium>,  C<long> and  C<full>)  and  the value  is  the
corresponding format, complete with C<%> and specifiers.

=item * month_names, month_abbreviations, day_names, day_abbreviations

Class methods giving the whole array of month or day names or abbrevs,
not limited to the date implemented by the invocant.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See L<https://lists.perl.org/> for more details.

Please   report  any   bugs   or  feature   requests   to  Github   at
L<https://github.com/jforget/DateTime-Calendar-FrenchRevolutionary>,
and create an issue or submit a pull request.

If you have no  feedback after a week or so, try to  reach me by email
at JFORGET  at cpan  dot org.  The notification  from Github  may have
failed to reach  me. In your message, please  mention the distribution
name in the subject, so my spam  filter and I will easily dispatch the
email to the proper folder.

On the other  hand, I may be  on vacation or away from  Internet for a
good  reason. Do  not be  upset if  I do  not answer  immediately. You
should write  me at a leisurely  rythm, about once per  month, until I
react.

If after about six  months or a year, there is  still no reaction from
me, you can worry and start the CPAN procedure for module adoption.
See L<https://groups.google.com/g/perl.module-authors/c/IPWjASwuLNs>
L<https://www.cpan.org/misc/cpan-faq.html#How_maintain_module>
and L<https://www.cpan.org/misc/cpan-faq.html#How_adopt_module>.

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 SEE ALSO

=head2 Internet

L<http://datetime.perl.org/>

L<https://it.wikipedia.org/wiki/Calendario_rivoluzionario_francese>.

=head1 LICENSE STUFF

Copyright (c) 2021  Jean Forget. All rights reserved.  This program is
free software. You can distribute, adapt, modify, and otherwise mangle
DateTime::Calendar::FrenchRevolutionary under  the same terms  as perl
5.16.3.

This program is  distributed under the same terms  as Perl 5.16.3: GNU
Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<https://dev.perl.org/licenses/artistic.html> and
L<https://www.gnu.org/licenses/old-licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You should  have received  a copy  of the  GNU General  Public License
along with this program;  if not, see L<https://www.gnu.org/licenses/>
or contact the Free Software Foundation, Inc., L<https://www.fsf.org>.

=cut
