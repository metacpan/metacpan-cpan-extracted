# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Perl DateTime extension for providing Spanish strings for the French Revolutionary calendar
# Copyright (c) 2021 Jean Forget. All rights reserved.
#
# See the license in the embedded documentation below.
#

package DateTime::Calendar::FrenchRevolutionary::Locale::es;

use utf8;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.17'; # same as parent module DT::C::FR

my @months_short  = qw (Vnd Bru Fri Niv Plu Vnt Ger Flo Pra Mes Ter Fru D-C);

# based on Gibus' App::SpreadRevolutionaryDate, itself 
# based on Wikipedia: L<https://es.wikipedia.org/wiki/Calendario_republicano_franc%C3%A9s>.
my @months = qw(Vendimiario Brumario  Frimario
                Nivoso      Pluvioso  Ventoso
                Germinal    Floreal   Pradial
                Mesidor     Termidor  Fructidor
    );

push @months, 'día complementario';

my @decade_days = qw (Primidi Duodi Tridi Quartidi Quintidi Sextidi Septidi Octidi Nonidi Décadi);
my @decade_days_short = qw (Pri Duo Tri Qua Qui Sex Sep Oct Non Déc);

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
# Vendémiaire
        qw(
           1uva             0azafrán          1castaña   1cólquida  0caballo
           1balsamina       1zanahoria        0amaranto  1chirivía  1tinaja
           1patata          1flor_de_papel    1calabaza  1reseda    0asno
           1bella_de_noche  1calabaza_otoñal  0alforfón  0girasol   0lagar
           0cáñamo          0melocotón        0nabo      1amarilis  0buey
           1berenjena       0pimiento         0tomate    1cebada    0barril
        ),
# Brumaire
        qw(
           1manzana     0apio                1pera         1remolacha  1oca
           0heliótropo  0higo                1escorzonera  0mostajo    0arado
           1salsifí     1castaña_de_agua     0tupinambo    1endibia    0guajolote
           1escaravía   0berro               1dentelaria   1granada    1grada
           1bacante     0acerolo             1rubia_roja   1naranja    0faisán
           0pistacho    0lathyrus_tuberosus  0membrillo    0serbal     0rodillo
        ),
# Frimaire
        qw(
           0rapónchigo  0nabo_forrajero  1achicoria  0níspero   0cerdo
           0canónigo    1coliflor        1miel       0enebro    0pico
           1cera        0rábano_picante  0cedro      0abeto     0corzo
           0tojo        1ciprés          1hiedra     1sabina    0azadón
           0arce        0brezo           1caña       1acedera   0grillo
           1piñón       0corcho          1trufa      1aceituna  1pala
        ),
# Nivôse
        qw(
           1turba           0carbón   0betún      0azufre    1perro
           1lava            0suelo    1estiércol  0salitre   0mayal
           0granito         1arcilla  1pizarra    1arenisca  0conejo
           1sílex           1marga    1caliza     0mármol    1aventadora_de_cereal
           1piedra_de_yeso  1sal      0hierro     0cobre     1gato
           0estaño          0plomo    0cinc       0mercurio  0tamiz
        ),
# Pluviôse
        qw(
           1laureola     0musgo           0rusco     0galanto          0toro
           0laurentino   0hongo_yesquero  0mezereón  0álamo            0hacha
           0eléboro      1brécol          0laurel    0avellano         1vaca
           0boj          0liquen          0tejo      1pulmonaria       1navaja_podadora
           0carraspique  0torvisco        1gramilla  1centinodia       1liebre
           1isatide      0avellano        0ciclamen  1celidonia_mayor  0trineo
        ),
# Ventôse
        qw(
           0tusilago            0corno              0alhelí       0aligustre      0macho_cabrío
           0jengibre_silvestre  0aladierno          0violeta      1sauce_cabruno  1laya
           0narciso             0olmo               1fumaria      0erísimo        1cabra
           1espinaca            0doronicum          1anagallis    0perifollo      0hilo
           1mandrágora          0perejil            1coclearia    1margarita      0atún
           0diente_de_león      1anémona_de_bosque  0culantrillo  0fresno         0plantador
        ),
# Germinal
        qw(
           1primavera       0sicomoro        0espárrago          0tulipán   1gallina
           1acelga          0abedul          0junquillo          0alnus     0nidal
           1vincapervinca   0carpe           1morchella          0haya      1abeja
           1lechuga         0alerce          1cicuta             0rábano    1colmena
           1árbol_de_Judea  1lechuga_romana  0castaño_de_Indias  1roqueta   1paloma
           0lila            1anémona         0pensamiento        0arándano  0cuchillo
        ),
# Floréal
        qw(
           0rosa               0roble        0helecho   0espino_albar   0ruiseñor
           1aguileña           1convalaria   1seta      0jacinto        0rastrillo
           0ruibarbo           1esparceta    0erysimum  0palmito        0gusano_de_seda
           1consuelda          1algáfita     0alyssum   0atriplex       0escardillo
           0limonium_sinuatum  1fritillaria  1borraja   1valeriana      1carpa
           0bonetero           0cebollino    1anchusa   1mostaza_negra  0armuelle
        ),
# Prairial
        qw(
           1alfalfa   0lirio_de_día  0trébol      1angélica  0pato
           0toronjil  1mazorra       0martagón    0serpol    1guadaña
           1fresa     1salvia        0guisante    1acacia    1codorniz
           0clavel    0saúco         1adormidera  0tilo      0bieldo
           0barbo     1manzanilla    1madreselva  0galium    1tenca
           0jazmín    1verbena       0tomillo     1peonía    0carro
        ),
# Messidor
        qw(
           0centeno   1avena      1cebolla    1veronica             1mula
           1romero    0pepino     0chalote    1absenta              1hoz
           0cilantro  1alcachofa  0alhelí     1lavanda              1gamuza
           0tabaco    1grosella   0lathyrus   1cereza               0parque
           1menta     0comino     1judía      1palomilla_de_tintes  1gallina_de_Guinea
           1salvia    0ajo        1algarroba  0trigo                1chirimía
        ),
# Thermidor
        qw(
           1escanda          0verbasco   0melón        1cizaña    0carnero
           1cola_de_caballo  1artemisa   0cártamo      1mora      1regadera
           0panicum          0salicor    0albaricoque  1albahaca  1oveja
           1malvaceae        0lino       1almendra     1genciana  1esclusa
           1carlina          1alcaparra  1lenteja      1inula     1nutria
           0mirto            1colza      0lupino       0algodón   0molino
        ),
# Fructidor
        qw(
           1ciruela         0mijo                0soplo_de_lobo  1cebada_de_otoño    0salmón
           0nardo           1cebada_de_invierno  1apocynaceae    0regaliz            1escala
           1sandía          0hinojo              0berberis       1nuez               1trucha
           0limón           1cardencha           0espino_cerval  0clavelón           0cesto
           0escaramujo      1avellana            1lúpulo         0sorgo              0cangrejo_de_río
           1naranja_amarga  1vara_de_oro         1maíz           1castaña            1cesta
        ),
# Jours complémentaires
        qw(
           1virtud      0talento  0trabajo  1opinión  3recompensas
           1revolución
         ));
my @prefix = ( 'día del ', 'día de la ', 'día de los ', 'día de las ');

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

DateTime::Calendar::FrenchRevolutionary::Locale::es -- Spanish localization for the French 
revolutionary calendar.

=head1 SYNOPSIS

  use DateTime::Calendar::FrenchRevolutionary::Locale;
  my $spanish_locale = DateTime::Calendar::FrenchRevolutionary::Locale->load('es');

  my $spanish_month_name =$spanish_locale->month_name($date);

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

Returns an Spanish translation for C<$date>'s month, where C<$date> is
a C<DateTime::Calendar::FrenchRevolutionary> object.

=item * month_abbreviation ($date)

Returns a 3-letter abbreviation for the Spanish month name.

=item * day_name ($date)

Returns an Spanish translation for the day name.

=item * day_abbreviation ($date)

Returns a 3-letter abbreviation for the Spanish day name.

=item * am_pm ($date)

Returns a code (typically C<AM> or C<PM>) showing whether the datetime
is in the morning or the  afternoon. Outside the sexagesimal time with
a 1..12 hour range, this is not very useful.

=item * feast_short ($date)

Hopefully  returns  an adequate  Spanish  translation  for the  plant,
animal or tool that correspond to C<$date>'s feast.

Note: in some cases, the feast French name is left untranslated, while
in some other cases, the  translation is inadequate. If you are fluent
in both French and Spanish, do not hesitate to send corrections to the
author.

=item * feast_long ($date)

Same as C<feast_short>, with a "day" prefix.

=item * feast_caps ($date)

Same as C<feast_long> with capitalized first letters.

=item * on_date ($date)

Not implemented for the Spanish locale. This method returns an empty string.

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

L<https://es.wikipedia.org/wiki/Calendario_republicano_franc%C3%A9s>

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
