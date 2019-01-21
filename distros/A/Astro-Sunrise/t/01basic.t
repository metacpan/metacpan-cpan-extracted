#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Astro::Sunrise
#     Copyright (C) 2001, 2002, 2003, 2013, 2015, 2017 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<https://dev.perl.org/licenses/artistic.html>
#     and L<https://www.gnu.org/licenses/gpl-1.0.html>.
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
#     Inc., <https://www.fsf.org/>.
#
use strict;
use warnings;
use POSIX qw(floor ceil);
use Astro::Sunrise;
use Test::More;

my @data = load_data();
plan(tests => 2 * @data); # I prefer having Perl counting my tests than myself

use vars qw($long $lat $offset);

my $test_year  = '2003';
my $test_month = '6';
my $test_day   = '21';


for (@data) {
/(\w+),\s+(\w+)\s+(\d+)\s+(\d+)\s+(\w)\s+(\d+)\s+(\d+)\s+(\w)\s+sunrise:\s+(\d+:\d+)\s+sunset:\s+(\d+:\d+)/;
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

    if ($long < 0) {
      $offset = ceil( $long / 15 );
    }
    elsif ($long > 0) {
      $offset = floor( $long /15 );
    }

    my ( $sunrise, $sunset ) =
      sunrise( $test_year, $test_month, $test_day, $long, $lat, $offset, 0 );

    is ($sunrise, $9, "Sunrise for $1, $2");
    is ($sunset , $10, "Sunset for $1, $2");

}

sub load_data {
    return split "\n", <<'EOD';
Aberdeen,            Scotland             57  9 N   2  9 W sunrise: 03:12 sunset: 21:08
Adelaide,            Australia            34 55 S 138 36 E sunrise: 06:53 sunset: 16:41
Algiers,             Algeria              36 50 N   3  0 E sunrise: 04:29 sunset: 19:10
Amsterdam,           Netherlands          52 22 N   4 53 E sunrise: 03:18 sunset: 20:06
Ankara,              Turkey               39 55 N  32 55 E sunrise: 04:20 sunset: 19:20
Asuncion,            Paraguay             25 15 S  57 40 W sunrise: 07:35 sunset: 18:09
Athens,              Greece               37 58 N  23 43 E sunrise: 04:03 sunset: 18:51
Auckland,            New_Zealand          36 52 S 174 45 E sunrise: 06:34 sunset: 16:11
Bangkok,             Thailand             13 45 N 100 30 E sunrise: 04:51 sunset: 17:48
Barcelona,           Spain                41 23 N   2  9 E sunrise: 04:18 sunset: 19:28
Beijing,             China                39 55 N 116 25 E sunrise: 03:46 sunset: 18:46
Belem,               Brazil                1 28 S  48 29 W sunrise: 06:15 sunset: 18:17
Belfast,             Northern_Ireland     54 37 N   5 56 W sunrise: 03:47 sunset: 21:04
Belgrade,            Yugoslavia           44 52 N  20 32 E sunrise: 03:52 sunset: 19:28
Berlin,              Germany              52 30 N  13 25 E sunrise: 02:43 sunset: 19:33
Birmingham,          England              52 25 N   1 55 W sunrise: 03:45 sunset: 20:34
Bogota,              Colombia              4 32 N  74 15 W sunrise: 06:47 sunset: 19:10
Bombay,              India                19  0 N  72 48 E sunrise: 04:32 sunset: 17:49
Bordeaux,            France               44 50 N   0 31 W sunrise: 04:16 sunset: 19:52
Bremen,              Germany              53  5 N   8 49 E sunrise: 02:58 sunset: 19:55
Brisbane,            Australia            27 29 S 153  8 E sunrise: 06:37 sunset: 17:01
Bristol,             England              51 28 N   2 35 W sunrise: 03:53 sunset: 20:31
Brussels,            Belgium              50 52 N   4 22 E sunrise: 03:29 sunset: 20:00
Bucharest,           Romania              44 25 N  26  7 E sunrise: 03:31 sunset: 19:03
Budapest,            Hungary              47 30 N  19  5 E sunrise: 03:46 sunset: 19:44
Buenos_Aires,        Argentina            34 35 S  58 22 W sunrise: 08:00 sunset: 17:50
Cairo,               Egypt                30  2 N  31 21 E sunrise: 04:54 sunset: 18:59
Calcutta,            India                22 34 N  88 24 E sunrise: 04:23 sunset: 17:54
Canton,              China                23  7 N 113 15 E sunrise: 04:42 sunset: 18:15
Cape_Town,           South_Africa         33 55 S  18 22 E sunrise: 06:51 sunset: 16:45
Caracas,             Venezuela            10 28 N  67  2 W sunrise: 06:08 sunset: 18:52
Cayenne,             French_Guiana         4 49 N  52 18 W sunrise: 06:19 sunset: 18:43
Chihuahua,           Mexico               28 37 N 106  5 W sunrise: 05:07 sunset: 19:05
Chongqing,           China                29 46 N 106 34 E sunrise: 04:54 sunset: 18:57
Copenhagen,          Denmark              55 40 N  12 34 E sunrise: 02:25 sunset: 19:57
Cordoba,             Argentina            31 28 S  64 10 W sunrise: 07:16 sunset: 17:21
Dakar,               Senegal              14 40 N  17 28 W sunrise: 05:42 sunset: 18:41
Darwin,              Australia            12 28 S 130 51 E sunrise: 05:36 sunset: 17:00
Djibouti,            Djibouti             11 30 N  43  3 E sunrise: 04:45 sunset: 17:33
Dublin,              Ireland              53 20 N   6 15 W sunrise: 03:57 sunset: 20:57
Durban,              South_Africa         29 53 S  30 53 E sunrise: 06:52 sunset: 17:05
Edinburgh,           Scotland             55 55 N   3 10 W sunrise: 03:26 sunset: 21:02
Frankfurt,           Germany              50  7 N   8 41 E sunrise: 03:15 sunset: 19:39
Georgetown,          Guyana                6 45 N  58 15 W sunrise: 06:39 sunset: 19:10
Glasgow,             Scotland             55 50 N   4 15 W sunrise: 03:31 sunset: 21:06
Guatemala_City,      Guatemala            14 37 N  90 31 W sunrise: 05:34 sunset: 18:34
Guayaquil,           Ecuador               2 10 S  79 56 W sunrise: 06:22 sunset: 18:21
Hamburg,             Germany              53 33 N  10  2 E sunrise: 02:50 sunset: 19:53
Havana,              Cuba                 23  8 N  82 23 W sunrise: 05:45 sunset: 19:18
Helsinki,            Finland              60 10 N  25  0 E sunrise: 01:54 sunset: 20:50
Hobart,              Tasmania             42 52 S 147 19 E sunrise: 06:42 sunset: 15:43
Iquique,             Chile                20 10 S  70  7 W sunrise: 07:15 sunset: 18:09
Irkutsk,             Russia               52 30 N 104 20 E sunrise: 02:39 sunset: 19:29
Jakarta,             Indonesia             6 16 S 106 48 E sunrise: 06:02 sunset: 17:47
Johannesburg,        South_Africa         26 12 S  28  4 E sunrise: 05:55 sunset: 16:24
Kingston,            Jamaica              17 59 N  76 49 W sunrise: 05:33 sunset: 18:45
Kinshasa,            Congo                 4 18 S  15 17 E sunrise: 06:04 sunset: 17:57
La_Paz,              Bolivia              16 27 S  68 22 W sunrise: 07:01 sunset: 18:10
Leeds,               England              53 45 N   1 30 W sunrise: 03:35 sunset: 20:40
Lima,                Peru                 12  0 S  77  2 W sunrise: 06:27 sunset: 17:52
Lisbon,              Portugal             38 44 N   9  9 W sunrise: 05:12 sunset: 20:05
Liverpool,           England              53 25 N   3  0 W sunrise: 03:43 sunset: 20:44
London,              England              51 32 N   0  5 W sunrise: 03:43 sunset: 20:21
Lyons,               France               45 45 N   4 50 E sunrise: 03:51 sunset: 19:34
Madrid,              Spain                40 26 N   3 42 W sunrise: 04:45 sunset: 19:48
Manchester,          England              53 30 N   2 15 W sunrise: 03:40 sunset: 20:42
Manila,              Philippines          14 35 N 120 57 E sunrise: 05:28 sunset: 18:27
Marseilles,          France               43 20 N   5 20 E sunrise: 03:58 sunset: 19:22
Mazatlan,            Mexico               23 12 N 106 25 W sunrise: 05:21 sunset: 18:54
Mecca,               Saudi_Arabia         21 29 N  39 45 E sunrise: 04:39 sunset: 18:06
Melbourne,           Australia            37 47 S 144 58 E sunrise: 06:35 sunset: 16:08
Mexico_City,         Mexico               19 26 N  99  7 W sunrise: 05:59 sunset: 19:17
Milan,               Italy                45 27 N   9 10 E sunrise: 03:35 sunset: 19:15
Montevideo,          Uruguay              34 53 S  56 10 W sunrise: 07:52 sunset: 17:41
Moscow,              Russia               55 45 N  37 36 E sunrise: 02:45 sunset: 20:18
Munich,              Germany              48  8 N  11 35 E sunrise: 03:13 sunset: 19:17
Nagasaki,            Japan                32 48 N 129 57 E sunrise: 04:12 sunset: 18:31
Nagoya,              Japan                35  7 N 136 56 E sunrise: 04:38 sunset: 19:10
Nairobi,             Kenya                 1 25 S  36 55 E sunrise: 05:33 sunset: 17:35
Nanjing_Nanking,     China                32  3 N 118 53 E sunrise: 03:59 sunset: 18:14
Naples,              Italy                40 50 N  14 15 E sunrise: 03:31 sunset: 18:38
Newcastle-on-Tyne,   England              54 58 N   1 37 W sunrise: 03:27 sunset: 20:49
Odessa,              Ukraine              46 27 N  30 48 E sunrise: 04:04 sunset: 19:53
Osaka,               Japan                34 32 N 135 30 E sunrise: 04:46 sunset: 19:14
Oslo,                Norway               59 57 N  10 42 E sunrise: 01:53 sunset: 20:44
Panama_City,         Panama                8 58 N  79 32 W sunrise: 06:00 sunset: 18:39
Paramaribo,          Suriname              5 45 N  55 15 W sunrise: 06:29 sunset: 18:56
Paris,               France               48 48 N   2 20 E sunrise: 03:47 sunset: 19:57
Perth,               Australia            31 57 S 115 52 E sunrise: 06:16 sunset: 16:20
Plymouth,            England              50 25 N   4  5 W sunrise: 04:05 sunset: 20:31
Port_Moresby,        Papua_New_Guinea      9 25 S 147  8 E sunrise: 05:26 sunset: 17:00
Prague,              Czech_Republic       50  5 N  14 26 E sunrise: 02:52 sunset: 19:15
Rangoon,             Myanmar              16 50 N  96  0 E sunrise: 05:04 sunset: 18:12
Reykjavik,           Iceland              64  4 N  21 58 W sunrise: 01:57 sunset: 23:02
Rio_de_Janeiro,      Brazil               22 57 S  43 12 W sunrise: 07:33 sunset: 18:16
Rome,                Italy                41 54 N  12 27 E sunrise: 03:35 sunset: 18:49
Salvador,            Brazil               12 56 S  38 27 W sunrise: 06:55 sunset: 18:16
Santiago,            Chile                33 28 S  70 45 W sunrise: 07:47 sunset: 17:43
St_Petersburg,       Russia               59 56 N  30 18 E sunrise: 02:35 sunset: 21:26
Sao_Paulo,           Brazil               23 31 S  46 31 W sunrise: 06:47 sunset: 17:28
Shanghai,            China                31 10 N 121 28 E sunrise: 04:51 sunset: 19:01
Singapore,           Singapore             1 14 N 103 55 E sunrise: 05:00 sunset: 17:12
Sofia,               Bulgaria             42 40 N  23 20 E sunrise: 03:49 sunset: 19:08
Stockholm,           Sweden               59 17 N  18  3 E sunrise: 02:31 sunset: 21:08
Sydney,              Australia            34  0 S 151  0 E sunrise: 07:01 sunset: 16:54
Tananarive,          Madagascar           18 50 S  47 33 E sunrise: 06:22 sunset: 17:21
Teheran,             Iran                 35 45 N  51 45 E sunrise: 04:17 sunset: 18:52
Tokyo,               Japan                35 40 N 139 45 E sunrise: 04:25 sunset: 19:00
Tripoli,             Libya                32 57 N  13 12 E sunrise: 03:59 sunset: 18:19
Venice,              Italy                45 26 N  12 20 E sunrise: 03:22 sunset: 19:03
Veracruz,            Mexico               19 10 N  96 10 W sunrise: 05:48 sunset: 19:05
Vienna,              Austria              48 14 N  16 20 E sunrise: 03:54 sunset: 19:59
Vladivostok,         Russia               43 10 N 132  0 E sunrise: 03:32 sunset: 18:55
Warsaw,              Poland               52 14 N  21  0 E sunrise: 03:14 sunset: 20:01
Wellington,          New_Zealand          41 17 S 174 47 E sunrise: 06:47 sunset: 15:58
Zurich,              Switzerland          47 21 N   8 31 E sunrise: 03:29 sunset: 19:26
EOD
}
