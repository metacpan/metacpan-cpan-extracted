# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Sunrise
#     Copyright (C) 2003, 2004, 2013 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
#     and L<http://www.gnu.org/licenses/gpl-1.0.html>.
#
#     Here is the summary of GPL:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 1, or (at your option)
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software Foundation,
#     Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#
use strict;
use POSIX qw(floor ceil);
use Test::More;
use DateTime;
use DateTime::Duration;
use DateTime::Span;
use DateTime::SpanSet;
use DateTime::Event::Sunrise;

my $fudge = 2;
my @data = data();
plan tests => 14 + 2 * @data;
my $dt = DateTime->new( year   => 2000,
                        month  => 6,
                        day    => 20,
                        time_zone => 'America/Los_Angeles',
                         );
my $dt2 = DateTime->new( year   => 2000,
                         month  => 6,
                         day    => 22,
                         time_zone => 'America/Los_Angeles',
                          );

my $sunrise = DateTime::Event::Sunrise ->sunrise(
                     longitude  =>'-118',
                     latitude   => '33',
                     upper_limb => 1,                     
);
my $sunset = DateTime::Event::Sunrise ->sunset(
                     longitude  =>'-118',
                     latitude   => '33',
                     upper_limb => 1,                     
                     );

my $tmp_rise = $sunrise->current($dt);
my $tmp_set  = $sunset->current($dt);

is ($tmp_rise->datetime, '2000-06-19T05:42:07', 'current sunrise');
is ($tmp_set->datetime,  '2000-06-19T20:04:49', 'current sunset');

is ( $sunrise->current( $tmp_rise )->set_time_zone( 'America/Los_Angeles' )->datetime, 
     '2000-06-19T05:42:07', 'current sunrise unchanged');
is ( $sunset->current( $tmp_set )->set_time_zone( 'America/Los_Angeles' )->datetime, 
     '2000-06-19T20:04:49', 'current sunset unchanged');

is ( $sunrise->next( $tmp_rise )->set_time_zone( 'America/Los_Angeles' )->datetime, 
     '2000-06-20T05:42:19', 'next sunrise');
is ( $sunset->next( $tmp_set )->set_time_zone( 'America/Los_Angeles' )->datetime, 
     '2000-06-20T20:05:03', 'next sunset');

is ( $sunrise->previous( $tmp_rise )->set_time_zone( 'America/Los_Angeles' )->datetime, 
     '2000-06-18T05:41:56', 'previous sunrise');
is ( $sunset->previous( $tmp_set )->set_time_zone( 'America/Los_Angeles' )->datetime, 
     '2000-06-18T20:04:33', 'previous sunset');

is ( $sunrise->contains( $tmp_rise ), 
     1, 'is sunrise');
is ( $sunset->contains( $tmp_set ), 
     1, 'is sunset');

is ( $sunrise->contains( $dt ), 
     0, 'is not sunrise');
is ( $sunset->contains( $dt ), 
     0, 'is not sunset');

# I need to check this test, Flavio has changed this as of ver 0.14 od spanset

#my $dt_span = DateTime::Span->new( start =>$dt, end=>$dt2 );
#my $set = $sunrise->intersection($dt_span);
#my $iter = $set->iterator;
#my @res;
#for (0..1) {
#        my $tmp = $iter->next;
#        push @res, $tmp->datetime if defined $tmp;
#}
#my $res = join( ' ', @res );
#ok( $res eq '2000-06-19T05:43:43 2000-06-20T05:43:43');

my $sun = DateTime::Event::Sunrise ->new(
                     longitude  =>'-118',
                     latitude   => '33',
                     upper_limb => 1,                     
);

my $tmp_set1 = $sun->sunrise_sunset_span($dt);
$tmp_set->set_time_zone('America/Los_Angeles');
ok( $tmp_set1->start->datetime eq '2000-06-20T05:42:19');
ok( $tmp_set1->end->datetime eq '2000-06-20T20:05:03');

use vars qw($long $lat $offset);

my $dt3 = DateTime->new(
  year  => 2003,
  month => 6,
  day   => 21,
);

for  (@data) {
/(\w+),\s+(\w+)\s+(\d+)\s+(\d+)\s+(\w)\s+(\d+)\s+(\d+)\s+(\w)\s+sunrise:\s+(\d+:\d+:\d+)\s+sunset:\s+(\d+:\d+:\d+)/;
    if ( $5 eq 'N' ) {
        $lat = sprintf( "%.3f", ( $3 + ( $4 / 60 ) ) );
    }
    elsif ( $5 eq 'S' ) {
        $lat = sprintf( "%.3f", -( $3 + ( $4 / 60 ) ) );
    }

    if ( $8 eq 'E' ) {
        $long = sprintf( "%.3f", $6 + ( $7 / 60 ) );
    }
    elsif ( $8 eq 'W' ) {
        $long = sprintf( "%.3f", -( $6 + ( $7 / 60 ) ) );
    }

    if ( $long < 0 ) {
        $offset = DateTime::TimeZone::offset_as_string( ceil( $long / 15 ) * 60 * 60 );
    }
    elsif ( $long > 0 ) {
        $offset = DateTime::TimeZone::offset_as_string( floor( $long / 15 ) * 60 * 60 );
    }

    my $sunrise = DateTime::Event::Sunrise->sunrise(
      longitude => $long,
      latitude  => $lat,
      upper_limb => 0,                     
    );
    my $sunset = DateTime::Event::Sunrise->sunset(
      longitude => $long,
      latitude  => $lat,
      upper_limb => 0,                     
    );

    my $cloned_date = $dt3->clone();
    $cloned_date->set_time_zone($offset);

    my $tmp_rise = $sunrise->next($cloned_date);
    my $tmp_set  = $sunset->next($cloned_date);

    my $tmp_rise_lo = $tmp_rise->clone->add(seconds => - $fudge)->hms;
    my $tmp_rise_hi = $tmp_rise->clone->add(seconds =>   $fudge)->hms;
    my $tmp_set_lo  = $tmp_set ->clone->add(seconds => - $fudge)->hms;
    my $tmp_set_hi  = $tmp_set ->clone->add(seconds =>   $fudge)->hms;

    ok(($tmp_rise_lo lt $9) && ($9 lt $tmp_rise_hi), "sunrise for $1, $2");
    ok(($tmp_set_lo lt $10) && ($10 lt $tmp_set_hi), "sunset  for $1, $2");

}

#
# The data below have been prepared by a C program which includes
# Paul Schlyter's code. Therefore, what is tested is the compatibility
# of the Perl code with the C code.
#
# See how this C program is generated in
# https://github.com/jforget/Astro-Sunrise/blob/master/util/mktest-01d
#
sub data {
  return split "\n", <<'DATA';
Aberdeen,            Scotland             57  9 N   2  9 W sunrise: 03:12:22 sunset: 21:08:11
Adelaide,            Australia            34 55 S 138 36 E sunrise: 06:53:01 sunset: 16:41:22
Algiers,             Algeria              36 50 N   3  0 E sunrise: 04:29:04 sunset: 19:10:17
Amsterdam,           Netherlands          52 22 N   4 53 E sunrise: 03:18:01 sunset: 20:06:16
Ankara,              Turkey               39 55 N  32 55 E sunrise: 04:19:49 sunset: 19:20:09
Asuncion,            Paraguay             25 15 S  57 40 W sunrise: 07:35:29 sunset: 18:09:17
Athens,              Greece               37 58 N  23 43 E sunrise: 04:02:47 sunset: 18:50:48
Auckland,            New_Zealand          36 52 S 174 45 E sunrise: 06:33:40 sunset: 16:11:28
Bangkok,             Thailand             13 45 N 100 30 E sunrise: 04:51:29 sunset: 17:47:44
Barcelona,           Spain                41 23 N   2  9 E sunrise: 04:17:59 sunset: 19:28:10
Beijing,             China                39 55 N 116 25 E sunrise: 03:45:46 sunset: 18:46:06
Belem,               Brazil                1 28 S  48 29 W sunrise: 06:14:33 sunset: 18:16:43
Belfast,             Northern_Ireland     54 37 N   5 56 W sunrise: 03:46:54 sunset: 21:03:55
Belgrade,            Yugoslavia           44 52 N  20 32 E sunrise: 03:51:33 sunset: 19:27:30
Berlin,              Germany              52 30 N  13 25 E sunrise: 02:43:05 sunset: 19:32:55
Birmingham,          England              52 25 N   1 55 W sunrise: 03:44:55 sunset: 20:33:46
Bogota,              Colombia              4 32 N  74 15 W sunrise: 06:47:12 sunset: 19:10:15
Bombay,              India                19  0 N  72 48 E sunrise: 04:32:12 sunset: 17:48:39
Bordeaux,            France               44 50 N   0 31 W sunrise: 04:15:54 sunset: 19:51:35
Bremen,              Germany              53  5 N   8 49 E sunrise: 02:57:56 sunset: 19:54:52
Brisbane,            Australia            27 29 S 153  8 E sunrise: 06:36:59 sunset: 17:01:07
Bristol,             England              51 28 N   2 35 W sunrise: 03:53:03 sunset: 20:30:58
Brussels,            Belgium              50 52 N   4 22 E sunrise: 03:28:33 sunset: 19:59:51
Bucharest,           Romania              44 25 N  26  7 E sunrise: 03:30:59 sunset: 19:03:23
Budapest,            Hungary              47 30 N  19  5 E sunrise: 03:46:14 sunset: 19:44:25
Buenos_Aires,        Argentina            34 35 S  58 22 W sunrise: 08:00:08 sunset: 17:50:13
Cairo,               Egypt                30  2 N  31 21 E sunrise: 04:53:51 sunset: 18:58:39
Calcutta,            India                22 34 N  88 24 E sunrise: 04:22:30 sunset: 17:53:33
Canton,              China                23  7 N 113 15 E sunrise: 04:41:55 sunset: 18:15:17
Cape_Town,           South_Africa         33 55 S  18 22 E sunrise: 06:51:26 sunset: 16:44:58
Caracas,             Venezuela            10 28 N  67  2 W sunrise: 06:07:46 sunset: 18:51:56
Cayenne,             French_Guiana         4 49 N  52 18 W sunrise: 06:18:53 sunset: 18:42:56
Chihuahua,           Mexico               28 37 N 106  5 W sunrise: 05:07:04 sunset: 19:05:04
Chongqing,           China                29 46 N 106 34 E sunrise: 04:53:35 sunset: 18:57:06
Copenhagen,          Denmark              55 40 N  12 34 E sunrise: 02:25:20 sunset: 19:57:28
Cordoba,             Argentina            31 28 S  64 10 W sunrise: 07:15:31 sunset: 17:21:14
Dakar,               Senegal              14 40 N  17 28 W sunrise: 05:41:42 sunset: 18:41:24
Darwin,              Australia            12 28 S 130 51 E sunrise: 05:36:28 sunset: 16:59:56
Djibouti,            Djibouti             11 30 N  43  3 E sunrise: 04:45:29 sunset: 17:33:25
Dublin,              Ireland              53 20 N   6 15 W sunrise: 03:56:39 sunset: 20:56:43
Durban,              South_Africa         29 53 S  30 53 E sunrise: 06:51:31 sunset: 17:04:44
Edinburgh,           Scotland             55 55 N   3 10 W sunrise: 03:26:23 sunset: 21:02:18
Frankfurt,           Germany              50  7 N   8 41 E sunrise: 03:15:14 sunset: 19:38:38
Georgetown,          Guyana                6 45 N  58 15 W sunrise: 06:39:17 sunset: 19:10:08
Glasgow,             Scotland             55 50 N   4 15 W sunrise: 03:31:21 sunset: 21:06:00
Guatemala_City,      Guatemala            14 37 N  90 31 W sunrise: 05:34:03 sunset: 18:33:33
Guayaquil,           Ecuador               2 10 S  79 56 W sunrise: 06:21:35 sunset: 18:21:20
Hamburg,             Germany              53 33 N  10  2 E sunrise: 02:50:07 sunset: 19:52:57
Havana,              Cuba                 23  8 N  82 23 W sunrise: 05:44:32 sunset: 19:17:59
Helsinki,            Finland              60 10 N  25  0 E sunrise: 01:53:43 sunset: 20:49:36
Hobart,              Tasmania             42 52 S 147 19 E sunrise: 06:41:50 sunset: 15:42:48
Iquique,             Chile                20 10 S  70  7 W sunrise: 07:14:55 sunset: 18:09:27
Irkutsk,             Russia               52 30 N 104 20 E sunrise: 02:39:22 sunset: 19:29:11
Jakarta,             Indonesia             6 16 S 106 48 E sunrise: 06:01:40 sunset: 17:47:09
Johannesburg,        South_Africa         26 12 S  28  4 E sunrise: 05:54:31 sunset: 16:24:15
Kingston,            Jamaica              17 59 N  76 49 W sunrise: 05:32:46 sunset: 18:45:12
Kinshasa,            Congo                 4 18 S  15 17 E sunrise: 06:04:22 sunset: 17:56:42
La_Paz,              Bolivia              16 27 S  68 22 W sunrise: 07:00:47 sunset: 18:09:35
Leeds,               England              53 45 N   1 30 W sunrise: 03:34:58 sunset: 20:40:22
Lima,                Peru                 12  0 S  77  2 W sunrise: 06:27:17 sunset: 17:52:26
Lisbon,              Portugal             38 44 N   9  9 W sunrise: 05:11:54 sunset: 20:04:40
Liverpool,           England              53 25 N   3  0 W sunrise: 03:43:07 sunset: 20:44:14
London,              England              51 32 N   0  5 W sunrise: 03:42:41 sunset: 20:21:20
Lyons,               France               45 45 N   4 50 E sunrise: 03:50:47 sunset: 19:33:53
Madrid,              Spain                40 26 N   3 42 W sunrise: 04:44:36 sunset: 19:48:21
Manchester,          England              53 30 N   2 15 W sunrise: 03:39:35 sunset: 20:41:46
Manila,              Philippines          14 35 N 120 57 E sunrise: 05:28:07 sunset: 18:27:29
Marseilles,          France               43 20 N   5 20 E sunrise: 03:58:16 sunset: 19:22:25
Mazatlan,            Mexico               23 12 N 106 25 W sunrise: 05:20:33 sunset: 18:54:16
Mecca,               Saudi_Arabia         21 29 N  39 45 E sunrise: 04:39:23 sunset: 18:05:55
Melbourne,           Australia            37 47 S 144 58 E sunrise: 06:35:24 sunset: 16:08:02
Mexico_City,         Mexico               19 26 N  99  7 W sunrise: 05:59:06 sunset: 19:17:18
Milan,               Italy                45 27 N   9 10 E sunrise: 03:34:41 sunset: 19:15:19
Montevideo,          Uruguay              34 53 S  56 10 W sunrise: 07:52:07 sunset: 17:40:38
Moscow,              Russia               55 45 N  37 36 E sunrise: 02:44:33 sunset: 20:17:57
Munich,              Germany              48  8 N  11 35 E sunrise: 03:13:21 sunset: 19:17:19
Nagasaki,            Japan                32 48 N 129 57 E sunrise: 04:12:23 sunset: 18:31:12
Nagoya,              Japan                35  7 N 136 56 E sunrise: 04:38:11 sunset: 19:09:32
Nairobi,             Kenya                 1 25 S  36 55 E sunrise: 05:32:48 sunset: 17:35:09
Nanjing_Nanking,     China                32  3 N 118 53 E sunrise: 03:58:37 sunset: 18:13:32
Naples,              Italy                40 50 N  14 15 E sunrise: 03:31:27 sunset: 18:37:53
Newcastle_on_Tyne,   England              54 58 N   1 37 W sunrise: 03:27:11 sunset: 20:49:06
Odessa,              Ukraine              46 27 N  30 48 E sunrise: 04:03:58 sunset: 19:52:57
Osaka,               Japan                34 32 N 135 30 E sunrise: 04:45:32 sunset: 19:13:39
Oslo,                Norway               59 57 N  10 42 E sunrise: 01:53:27 sunset: 20:44:17
Panama_City,         Panama                8 58 N  79 32 W sunrise: 06:00:28 sunset: 18:39:14
Paramaribo,          Suriname              5 45 N  55 15 W sunrise: 06:29:03 sunset: 18:56:22
Paris,               France               48 48 N   2 20 E sunrise: 03:47:12 sunset: 19:57:29
Perth,               Australia            31 57 S 115 52 E sunrise: 06:16:27 sunset: 16:19:49
Plymouth,            England              50 25 N   4  5 W sunrise: 04:04:45 sunset: 20:31:16
Port_Moresby,        Papua_New_Guinea      9 25 S 147  8 E sunrise: 05:25:51 sunset: 17:00:15
Prague,              Czech_Republic       50  5 N  14 26 E sunrise: 02:52:25 sunset: 19:15:27
Rangoon,             Myanmar              16 50 N  96  0 E sunrise: 05:03:38 sunset: 18:11:36
Reykjavik,           Iceland              64  4 N  21 58 W sunrise: 01:57:12 sunset: 23:01:55
Rio_de_Janeiro,      Brazil               22 57 S  43 12 W sunrise: 07:32:48 sunset: 18:16:11
Rome,                Italy                41 54 N  12 27 E sunrise: 03:34:59 sunset: 18:48:45
Salvador,            Brazil               12 56 S  38 27 W sunrise: 06:54:37 sunset: 18:16:23
Santiago,            Chile                33 28 S  70 45 W sunrise: 07:46:48 sunset: 17:42:38
St_Petersburg,       Russia               59 56 N  30 18 E sunrise: 02:35:14 sunset: 21:25:41
Sao_Paulo,           Brazil               23 31 S  46 31 W sunrise: 06:47:15 sunset: 17:28:18
Shanghai,            China                31 10 N 121 28 E sunrise: 04:50:31 sunset: 19:00:57
Singapore,           Singapore             1 14 N 103 55 E sunrise: 05:00:10 sunset: 17:11:43
Sofia,               Bulgaria             42 40 N  23 20 E sunrise: 03:48:42 sunset: 19:07:57
Stockholm,           Sweden               59 17 N  18  3 E sunrise: 02:31:22 sunset: 21:07:34
Sydney,              Australia            34  0 S 151  0 E sunrise: 07:01:01 sunset: 16:54:08
Tananarive,          Madagascar           18 50 S  47 33 E sunrise: 06:21:35 sunset: 17:21:18
Teheran,             Iran                 35 45 N  51 45 E sunrise: 04:17:10 sunset: 18:52:07
Tokyo,               Japan                35 40 N 139 45 E sunrise: 04:25:22 sunset: 18:59:49
Tripoli,             Libya                32 57 N  13 12 E sunrise: 03:59:04 sunset: 18:18:40
Venice,              Italy                45 26 N  12 20 E sunrise: 03:22:05 sunset: 19:02:35
Veracruz,            Mexico               19 10 N  96 10 W sunrise: 05:47:50 sunset: 19:04:58
Vienna,              Austria              48 14 N  16 20 E sunrise: 03:53:53 sunset: 19:58:47
Vladivostok,         Russia               43 10 N 132  0 E sunrise: 03:32:08 sunset: 18:55:03
Warsaw,              Poland               52 14 N  21  0 E sunrise: 03:14:19 sunset: 20:01:00
Wellington,          New_Zealand          41 17 S 174 47 E sunrise: 06:46:43 sunset: 15:58:09
Zurich,              Switzerland          47 21 N   8 31 E sunrise: 03:29:11 sunset: 19:26:01
DATA
}
