# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Perl Date::Convert extension to convert dates from/to the French Revolutionary calendar
#     Copyright (C) 2001-2003, 2013, 2015 Jean Forget
#
#     See the license in the embedded documentation below.
#
package Date::Convert::French_Rev;

use utf8;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Date::Convert;
use Carp;
use Roman;

require Exporter;

@ISA = qw(Date::Convert Exporter);
# Do not export methods, therefore export nothing
@EXPORT = qw(
        
);
$VERSION = '0.08';

use constant REV_BEGINNING => 2375840; # 1 Vendémiaire I in the Revolutionary calendar
my @MONTHS_SHORT  = qw ( Vnd Bru Fri Niv Plu Vnt Ger Flo Pra Mes The Fru S-C);
my @MONTHS = qw(Vendémiaire Brumaire  Frimaire
                Nivôse      Pluviôse  Ventôse
                Germinal    Floréal   Prairial
                Messidor    Thermidor Fructidor);
push @MONTHS, "jour complémentaire"; # Incompatible with qw(), because of embedded space

# The day numer 10 is counterintuitively placed in the 0-th element
# because the modulus operator and the Perl arrays are 0-based.
# It works. Do not report a bug.
my @DECADE_DAYS = qw ( Décadi Primidi Duodi Tridi Quartidi Quintidi Sextidi Septidi Octidi Nonidi);
my @DECADE_DAYS_SHORT = qw ( Déc Pri Duo Tri Qua Qui Sex Sep Oct Non);

# When initializing an array with lists within lists, it means one of two things:
# Either it is a newbie who does not know how to make multi-dimensional arrays,
# Or it is a (at least mildly) experienced Perl-coder who, for some reason, 
# wants to initialize a flat array with the concatenation of lists.
# I am a (at least mildly) experienced programmer who wants to use qw() and yet insert
# comments in some places.
my @DAYS = (
# Vendémiaire
        qw(
       0raisin           0safran           1châtaigne        1colchique        0cheval
       1balsamine        1carotte          2amarante         0panais           1cuve
       1pomme_de_terre   2immortelle       0potiron          0réséda           2âne
       1belle_de_nuit    1citrouille       0sarrasin         0tournesol        0pressoir
       0chanvre          1pêche            0navet            2amaryllis        0bœuf
       2aubergine        0piment           1tomate           2orge             0tonneau
        ),
# Brumaire
        qw(
       1pomme            0céleri           1poire            1betterave        2oie
       2héliotrope       1figue            1scorsonère       2alisier          1charrue
       0salsifis         1macre            0topinambour      2endive           0dindon
       0chervis          0cresson          1dentelaire       1grenade          1herse
       1bacchante        2azerole          1garance          2orange           0faisan
       1pistache         0macjon           0coing            0cormier          0rouleau
        ),
# Frimaire
        qw(
       1raiponce         0turneps          1chicorée         1nèfle            0cochon
       1mâche            0chou-fleur       0miel             0genièvre         1pioche
       1cire             0raifort          0cèdre            0sapin            0chevreuil
       2ajonc            0cyprès           0lierre           1sabine           0hoyau
       2érable-sucre     1bruyère          0roseau           2oseille          0grillon
       0pignon           0liège            1truffe           2olive            1pelle
        ),
# Nivôse
        qw(
       1tourbe           1houille          0bitume           0soufre           0chien
       1lave             1terre_végétale   0fumier           0salpêtre         0fléau
       0granit           2argile           2ardoise          0grès             0lapin
       0silex            1marne            1pierre_à_chaux   0marbre           0van
       1pierre_à_plâtre  0sel              0fer              0cuivre           0chat
       2étain            0plomb            0zinc             0mercure          0crible
        ),
# Pluviôse
        qw(
       1lauréole         1mousse           0fragon           0perce-neige      0taureau
       0laurier-thym     2amadouvier       0mézéréon         0peuplier         1cognée
       2ellébore         0brocoli          0laurier          2avelinier        1vache
       0buis             0lichen           2if               1pulmonaire       1serpette
       0thlaspi          0thymelé          0chiendent        1traînasse        0lièvre
       1guède            0noisetier        0cyclamen         1chélidoine       0traîneau
        ),
# Ventôse
        qw(
       0tussilage        0cornouiller      0violier          0troène           0bouc
       2asaret           2alaterne         1violette         0marsault         1bêche
       0narcisse         2orme             1fumeterre        0vélar            1chèvre
       2épinard          0doronic          0mouron           0cerfeuil         0cordeau
       1mandragore       0persil           0cochléaria       1pâquerette       0thon
       0pissenlit        1sylvie           0capillaire       0frêne            0plantoir
        ),
# Germinal
        qw(
       1primevère        0platane          2asperge          1tulipe           1poule
       1blette           0bouleau          1jonquille        2aulne            0couvoir
       1pervenche        0charme           1morille          0hêtre            2abeille
       1laitue           0mélèze           1ciguë            0radis            1ruche
       0gainier          1romaine          0marronnier       1roquette         0pigeon
       0lilas            2anémone          1pensée           1myrtille         0greffoir
        ),
# Floréal
        qw(
       1rose             0chêne            1fougère          2aubépine         0rossignol
       2ancolie          0muguet           0champignon       1jacinthe         0rateau
       1rhubarbe         0sainfoin         0bâton-d'or       0chamérisier      0ver_à_soie
       1consoude         1pimprenelle      1corbeille-d'or   2arroche          0sarcloir
       0statice          1fritillaire      1bourrache        1valériane        1carpe
       0fusain           1civette          1buglosse         0sénevé           1houlette
        ),
# Prairial
        qw(
       1luzerne          2hémérocalle      0trèfle           2angélique        0canard
       1mélisse          0fromental        0martagon         0serpolet         1faux
       1fraise           1bétoine          0pois             2acacia           1caille
       2œillet           0sureau           0pavot            0tilleul          1fourche
       0barbeau          1camomille        0chèvrefeuille    0caille-lait      1tanche
       0jasmin           1verveine         0thym             1pivoine          0chariot
        ),
# Messidor
        qw(
       0seigle           2avoine           2oignon           1véronique        0mulet
       0romarin          0concombre        2échalotte        2absinthe         1faucille
       1coriandre        2artichaut        1giroflée         1lavande          0chamois
       0tabac            1groseille        1gesse            1cerise           0parc
       1menthe           0cumin            0haricot          2orcanète         1pintade
       1sauge            2ail              1vesce            0blé              1chalémie
        ),
# Thermidor
        qw(
       2épautre          0bouillon-blanc   0melon            2ivraie           0bélier
       1prèle            2armoise          0carthame         1mûre             2arrosoir
       0panis            0salicor          2abricot          0basilic          1brebis
       1guimauve         0lin              2amande           1gentiane         2écluse
       1carline          0câprier          1lentille         2aunée            1loutre
       1myrte            0colza            0lupin            0coton            0moulin
        ),
# Fructidor
        qw(
       1prune            0millet           0lycoperdon       2escourgeon       0saumon
       1tubéreuse        0sucrion          2apocyn           1réglisse         2échelle
       1pastèque         0fenouil          2épine-vinette    1noix             1truite
       0citron           1cardère          0nerprun          0tagette          1hotte
       2églantier        1noisette         0houblon          0sorgho           2écrevisse
       1bagarade         1verge-d'or       0maïs             0marron           0panier
        ),
# Jours complémentaires
        qw(
       1vertu            0génie            0travail          2opinion          3récompenses
       1révolution
         ));

my @PREFIXES = ('jour du ', 'jour de la ', "jour de l'", 'jour des ');

use constant NORMAL_YEAR    => 365;
use constant LEAP_YEAR      => 366;
use constant FOUR_YEARS     => 4 * NORMAL_YEAR + 1; # one leap year every four years
use constant CENTURY        => 25 * FOUR_YEARS - 1; # centuries aren't leap years...
use constant FOUR_CENTURIES => 4 * CENTURY + 1;     # ...except every four centuries that are.
use constant FOUR_MILLENIA  => 10 * FOUR_CENTURIES - 1; # ...except every four millenia that are not.

# number of days between the start of the revolutionary calendar, and the
# beginning of year n - 1
my @YEARS_BEGINS=    (0, 365, 730, 1096, 1461, 1826, 2191, 2557, 2922, 3287, 3652,
                   4018, 4383, 4748, 5113, 5479, 5844);

# This method shoudl be in the master class, but for the moment, it is only available here
sub change_to {
  croak "Need to specify the new calendar"
    if @_ <= 1;
  my ($self, $new_cal) = @_;
  $new_cal->convert($self);
}

sub initialize {
    my $self = shift;
    my ($year, $month, $day) = @_;
    unless (defined($year) and defined($month) and defined($day))
      { croak "Date::Convert::French_Rev::initialize needs more args" }
    my $absol = REV_BEGINNING;
    $$self{'year'}  = $year;
    $$self{'month'} = $month;
    $$self{'day'}   = $day;

    my $is_leap = Date::Convert::French_Rev->is_leap($year);
    croak "year $year out of range" if $year <= 0;
    croak "month $month out of range" if $month > 13 or $month <= 0;
    croak "standard day number $day out of range" if $day <= 0 and $month <= 12;
    croak "standard day number $day out of range" if $day > 30 and $month <= 12;
    croak "additional day $day out of range" if ($month == 13) and ($day <= 0);
    croak "additional day $day out of range" if ($month == 13) and ($day > 5) and !$is_leap;
    croak "additional day $day out of range" if ($month == 13) and ($day > 6); # implying "and $is_leap" other cases already discarded

    $year --;  #get years *before* this year.  Makes math easier.  :)
    # first, convert year into days. . .
    if ($year >= 16) # Romme rule in effect, or nearly so
      {
        $absol += int($year/4000) * FOUR_MILLENIA;
        $year  %= 4000;
        $absol += int($year/400) * FOUR_CENTURIES;
        $year  %= 400;
        $absol += int($year/100) * CENTURY;
        $year  %= 100;
        $absol += int($year/4)* FOUR_YEARS;
        $year  %= 4;
        $absol += $year * NORMAL_YEAR;
      }
    else # table look-up for the programmer-hostile equinox rule
      { $absol += $YEARS_BEGINS[$year] }

    # now, month into days.
    $absol += 30 * ($month - 1) + $day - 1;

    $$self{absol} = $absol;
}

sub year {
    my $self = shift;
    return $$self{year} if exists $$self{year}; # no point recalculating.
    my $days;
    my $year;
    # note:  years and days are initially days *before* today, rather than
    # today's date.  This is because of fenceposts.  :)
    $days =  $$self{absol} - REV_BEGINNING;
    if ($days < $YEARS_BEGINS[16]) {
      $year = scalar grep { $_ <= $days } @YEARS_BEGINS;
      $days -= $YEARS_BEGINS[$year - 1];
      $days++;
    }
    else {
      my $x;
      $x     = int ($days / FOUR_MILLENIA);
      $year += $x * 4000;
      $days -= $x * FOUR_MILLENIA;

      $x     = int ($days / FOUR_CENTURIES);
      $year += $x * 400;
      $days -= $x * FOUR_CENTURIES;

      $x     = int ($days / CENTURY);
      $x     = 3 if $x == 4; # last day of the 400-year period
      $year += $x * 100;
      $days -= $x * CENTURY;

      $x     = int ($days / FOUR_YEARS);
      $year += $x * 4;
      $days -= $x * FOUR_YEARS;

      $x     = int ($days / NORMAL_YEAR);
      $x     = 3 if $x == 4; # last day of the 4-year period
      $year += $x;
      $days -= $x * NORMAL_YEAR;

      ++$year; # because of 0-based mathematics vs 1-based chronology
      ++$days;
    }
    $$self{year}           = $year;
    $$self{days_into_year} = $days;
    return $year;
}

sub month {
    my $self = shift;
    return $$self{month} if exists $$self{month};
    my $year = $self -> year;
    my $days = $$self{days_into_year} - 1;
    my $day  = $days % 30;
    $days   -= $day;
    my $month = $days / 30 + 1;
    $$self{month} = $month;
    $$self{day}   = $day + 1;
    return $month;
}

sub day {
    my $self = shift;
    return $$self{day} if exists $$self{day};
    $self->month; # calculates day as a side-effect
    return $$self{day};
}

sub date {
    my $self = shift;
    return ($self->year, $self->month, $self->day);
}

sub is_leap {
    my ($self, $year) = @_;
    if (@_ == 1) {
      $year = $self->year; # so is_leap can be static or method
    }

    # Autumn equinox from I to XIX
    return 1 if ($year == 3) or ($year == 7) or ($year == 11) or ($year == 15);
    return 0 if ($year < 20);

    # Romme rule from XX on
    return 0 if $year %    4; # not a multiple of 4 -> normal year
    return 1 if $year %  100; # a multiple of 4 but not of 100 -> leap year
    return 0 if $year %  400; # a multiple of 100 but not of 400 -> normal year
    return 1 if $year % 4000; # a multiple of 400 but not of 4000 -> leap
    return 0; # multiple of 4000 -> normal year
}

sub field {
  my ($self, $spec) = @_;
  my $decade_day = $self->day % 10;
  # below, a switch statement, more or less, as described in perlfaq7

  $spec eq '%d'         && do { return sprintf "%02d", $self->day };
  $spec eq '%j'         && do { return sprintf "%03d", 30 * $self->month + $self->day - 30 };
  $spec eq '%e'         && do { return sprintf "%2d",  $self->day };
  $spec eq '%m'         && do { return sprintf "%02d", $self->month };
  $spec eq '%f'         && do { return sprintf "%2d",  $self->month };
  $spec =~ /\%[YGL]/    && do { return sprintf "%04d", $self->year };
  $spec =~ /\%B/        && do { return $MONTHS[$self->month - 1] };
  $spec =~ /\%[bh]/     && do { return $MONTHS_SHORT[$self->month - 1] };
  $spec eq '%y'         && do { return sprintf "%02d", $self->year % 100 };
  $spec eq '%n'         && do { return "\n" };
  $spec eq '%t'         && do { return "\t" };
  $spec eq '%+'         && do { return '+' };
  $spec eq '%%'         && do { return '%' };
  $spec eq '%a'         && do { return $DECADE_DAYS_SHORT[$decade_day] };
  $spec eq '%A'         && do { return $DECADE_DAYS[$decade_day] };
  $spec eq '%w'         && do { return sprintf("%2d", $decade_day || 10) };
  $spec eq '%EY'        && do { return $self->year < 4000 ? Roman($self->year) : $self->year };
  $spec eq '%Ey'        && do { return $self->year < 4000 ? roman($self->year) : $self->year };
 ($spec eq '%Ej' || $spec eq '%*')
                        && do
    {
      my $jj = 30 * $self->month + $self->day - 31; # %j is 1..366, but $jj is 0..365
      my $lb = $DAYS[$jj];
      $lb =~ s/_/ /g;
      $lb =~ s/^(\d)/$PREFIXES[$1]/;
      return $lb;
    };
  $spec eq '%EJ'  && do
    {
      my $jj = 30 * $self->month + $self->day - 31; # %j is 1..366, but $jj is 0..365
      my $lb = $DAYS[$jj];
      $lb =~ s/_/ /g;
      # Using a capitalized prefix, and capitalizing the first letter
      $lb =~ s/^(\d)(.)/\u$PREFIXES[$1]\u$2/;
      return $lb;
    };
  $spec eq '%Oj'  && do
    {
      my $jj = 30 * $self->month + $self->day - 31; # %j is 1..366, but $jj is 0..365
      my $lb = substr $DAYS[$jj], 1;
      $lb =~ s/_/ /g;
      return $lb;
    };
  return $spec;
}

sub date_string {
  my ($self, $format) = @_;

  # Default value when not provided. I do not test true / false, because
  # some adventurous mind could think that "0" is a valid format, even if false.
  $format = "%e %B %EY" if (! defined $format or $format eq '');

  my $year  = $self->year; # possibly to trigger the side effect
  my $month = $self->month;
  $format =~ s/(          # start of $1
               \%         # percent sign
               (?:        # start of alternative
                (?:O.)    # extended field specifier: O with a second char
               |          # or
                (?:E.)    # other extended field specifier: E with a second char
               |          # or
                .         # basic field specifier: single char
               ))         # end of alternative and end of $1
              /'$self->field($1)'/eegx; # is there a simpler way to do it?

  return $format;
}

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
"Liberté, égalité, fraternité
ou la mort !";

__END__

=encoding utf8

=head1 NAME

Date::Convert::French_Rev - Convert from / to French Revolutionary Calendar

=head1 SYNOPSIS

  use Date::Convert::French_Rev;

Converting from Gregorian (or other) to Revolutionary

    $date = Date::Convert::Gregorian->new(1799, 11, 9); # 9th November 1799...
    Date::Convert::French_Rev->convert($date);
    print $date->date_string, "\n";                     # ... is "18 Brumaire VIII"
    my $format = "%A %d %B %EY %Ej";
    print $date->date_string($format), "\n";            # ... or "Octidi 18 Brumaire VIII jour de la dentelaire"

Converting from Revolutionary to Gregorian (or other)

    $date = Date::Convert::French_Rev->new(8, 2, 18);   # 18 Brumaire VIII...
    Date::Convert::Gregorian->convert($date);
    print $date->date_string, "\n";                     # ... is "1799 Nov 9"

Alternate way of converting from Revolutionary to Gregorian (or other)

    $date = Date::Convert::French_Rev->new(8, 2, 18);   # 18 Brumaire VIII...
    $date->change_to("Date::Convert::Gregorian");
    print $date->date_string, "\n";                     # ... is "1799 Nov 9"

=head1 REQUIRES

Date::Convert, Roman

A Unicode-friendly version of Perl,  that is, more or less, Perl 5.8.8
or greater.  Yet,  if you do not use  the C<date_string> accessor, you
can use a lower version of Perl.

=head1 EXPORTS

Nothing.

=head1 DESCRIPTION

The following methods are available:

=over 4

=item new

Create a new Revolutionary date object with the specified year, month,
day parameters, e.g.

  $date = Date::Convert::French_Rev->new(8, 2, 18)

for 18 Brumaire VIII.

=item date

Extract a  list consisting  of the  year, the month  and the  day. The
end-of-year additional days are assigned to the virtual 13th month.

=item year

Return just the year element of date.

=item month

Return the month  element of date, or 13 if the  date is an additional
day at the end of the year.

=item day

Return just the day number element of date.

=item is_leap

Boolean.

=item convert

Change the date to a new format. The invocant is the class name of the
destination calendar, the parameter is the C<Date::Convert::>I<whatever>
object to convert.

=item change_to

Change the date to a new format. The invocant is the
C<Date::Convert::>I<whatever> object to convert, the parameter is the
class name of the destination calendar. For the moment, this method is
available only for C<Date::Convert::French_Rev> invocant objects.

=item date_string

Return the date  in a pretty format. You can  give an string parameter
to adjust the date format to your preferences.

=back

The format parameter  to C<date_string> is a string  consisting of any
characters (letters, digits,  whitespace, other) with %-prefixed field
descriptors, inspired from the Unix standard C<date(1)> command.

The following field descriptors are recognized:

=over 4

=item %y

2-digit year - 00 to 99

=item %Y, %G, %L

year  - 0001  to  9999. There  is  no difference  between these  three
variants. This is because in the Revolutionary calendar, the beginning
of a year  is always aligned with the beginning of  a décade, while in
the Gregorian calendar, the beginning of a year is usually not aligned
with the beginning of a week.

=item %EY, %Ey

year as a Roman number - I to MMM

=item %m

month of year  - 01 to 12, or 13 for  the end-of-year additional days.
The number  is formatted as  a 2-char string,  with a leading  zero if
necessary.

=item %f

month of year  - " 1" to "12", or "13"  for the end-of-year additional
days.   The number is  formatted as  a 2-char  string, with  a leading
space if necessary.

=item %b, %h

month abbreviation - Ven to Fru, or S-C for the end-of-year additional
days (called I<Sans-Culottides>). A 3-char string.

=item %B

month full name - Vendémiaire to Fructidor, or "jour complémentaire"
for the end-of-year additional days. A variable length string.

=item %d

day of month - 01 to 30.   The number is formatted as a 2-char string,
with a leading zero if necessary.

=item %e

day of  month - "  1" to  "30".  The number  is formatted as  a 2-char
string, with a leading space if necessary.

=item %A

day of décade - "Primidi" to "Décadi". A variable length string.

=item %a

abbreviated day of décade -  "Pri" to "Déc".  A 3-char string. Beware:
do not confuse Sep, Oct and Déc with Gregorian calendar months

=item %w

day  of décade -  " 1"  to "10"  (" 1"  for Primidi,  " 2"  for Duodi,
etc). The number is formatted as a 2-char string, with a leading space
if necessary.

=item %j

day of the year - "001" to "366". A 3-char string, with leading zeroes
if necessary.

=item %Ej

full name of the day of the year. Instead of assigning a saint to each
day, the creators of the calendar decided to assign a plant, an animal
or a tool. A variable-length string.

=item %EJ

same as %Ej, but significant words are capitalized.

=item %*

same as %Ej.

=item %Oj

simple name of the day of the year. Same as %Ej, without the prefix.

=item %n, %t, %%, %+

replaced by a newline, tab, percent and plus character respectively.

=back

The time-related field specifiers  are irrelevant. Therefore, they are
copied "as is" into the result string. These fields are:

  %H, %k, %i, %I, %p, %M, %S, %s, %o, %Z, %z

Neither are the composite field specifiers supported:

  %c, %C, %u, %g, %D, %x, %l, %r, %R, %T, %X, %V, %Q, %q, %P, %F, %J, %K

If a percent-sequence  is not a valid specifier, it  is copied "as is"
into the  result string. This  is true especially  for C<%E>-sequences
and C<%O>-sequences other than those listed above.

=head1 DIAGNOSTICS

=over 4

=item year %s out of range

The module does  not deal with year prior to the  epoch. The year must
be "1" or greater.

=item month %s out of range

The  French  Revolutionary  calendar  has  12  months,  plus  5  or  6
additional days  that do not belong  to a month.  So  the month number
must be in the 1-12 range for normal days, or 13 for additional days

=item standard day number %s out of range

The day number for any normal month is in the 1-30 range.

=item additional day %s out of range

The day number for the end-of-year  additional days is a number in the
1-5 range (or the 1-6 range for leap years).

=item Date::Convert::French_Rev::initialize needs more args

You  must provide  a year,  a month  number and  a day  number to
C<Date::Convert::French_Rev::initialize>.

=back

=head1 KNOWN BUGS AND CAVEATS

Not many bugs, but many caveats.

My sources  disagree about the 4th  additional day. One  says "jour de
l'opinion", the other says "jour de la raison".

Another disagreement is  that some sources ignore the  Romme rule, and
use only the equinox rule. So, a 1- or 2-day difference can happen.

This  module  inherits  its  user  interface  from  Mordechai  Abzug's
C<Date::Convert>,  which is,  according to  its author,  "in pre-alpha
state".  Therefore, my  module's  user interface  is  also subject  to
changes.

I  have checked the  manpage for  C<date(1)> in  two flavors  of Unix:
Linux and AIX. In the best case, the extended field descriptors C<%Ex>
and C<%Oy> are poorly documented, but usually they are not documented.

The C<Test::Exception>  module is required for the  build process, not
for  the   regular  use  of   C<Date::Convert::French_Rev>.  But  with
C<ExtUtils::MakeMaker>,   I   do   not   know  how   to   generate   a
C<build_requires> entry in F<META.yml>.

=head1 HISTORICAL NOTES

The Revolutionary calendar was in  use in France from 24 November 1793
(4 Frimaire II) to 31 December 1805 (10 Nivôse XIV). An attempt to use
the  decimal   rule  (the   basis  of  the   metric  system)   to  the
calendar. Therefore, the week  disappeared, replaced by the décade (10
days, totally different from the  English word "decade", 10 years). In
addition, all months have exactly 3 decades, no more, no less.

At first,  the year was  beginning on the  equinox of autumn,  for two
reasons.  First, the  republic had  been established  on  22 September
1792, which  happened to be the  equinox, and second,  the equinox was
the symbol of equality, the day and the night lasting exactly 12 hours
each. It  was therefore  in tune with  the republic's  motto "Liberty,
Equality, Fraternity". But  it was not practical, so  Romme proposed a
leap year rule similar to the Gregorian calendar rule.

In his book  I<The French Revolution>, the 19th  century writer Thomas
Carlyle proposes these translations for the month names:

  Vendémiaire -> Vintagearious
  Brumaire    -> Fogarious
  Frimaire    -> Frostarious
  Nivôse      -> Snowous
  Pluviôse    -> Rainous
  Ventôse     -> Windous
  Germinal    -> Buddal
  Floréal     -> Floweral
  Prairial    -> Meadowal
  Messidor    -> Reapidor
  Thermidor   -> Heatidor
  Fructidor   -> Fruitidor

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

based on Mordechai T. Abzug's work <morty@umbc.edu>

=head1 SEE ALSO

=head2 Software

date(1), perl(1), L<Date::Convert>

calendar/cal-french.el in emacs or xemacs

L<DateTime> and L<DateTime::Calendar::FrenchRevolutionary>

=head2 books

Quid 2001, M and D Frémy, publ. Robert Laffont

Agenda Républicain 197 (1988/89), publ. Syros Alternatives

Any French schoolbook about the French Revolution

The French Revolution, Thomas Carlyle, Oxford University Press

=head2 Internet

L<http://www.faqs.org/faqs/calendars/faq/part3/>

L<http://h2g2.com/approved_entry/A2903636>

L<http://en.wikipedia.org/wiki/French_Republican_Calendar>

L<http://prairial.free.fr/calendrier/calendrier.php?lien=sommairefr>
(in French)

=head1 LICENSE

Copyright (c)  2001, 2002, 2003,  2013, 2015 Jean Forget.   All rights
reserved.  This program is free software.  You can distribute, modify,
and otherwise mangle Date::Convert::French_Rev under the same terms as
Perl 5.16.3: GNU  Public License version 1 or  later and Perl Artistic
License

You can  find the text  of the licenses  in the F<LICENSE> file  or at
L<http://www.perlfoundation.org/artistic_license_1_0> and
L<http://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You  should have received  a copy  of the  GNU General  Public License
along  with  this  program;  if   not,  write  to  the  Free  Software
Foundation, Inc., <http://www.fsf.org/>.

=cut
