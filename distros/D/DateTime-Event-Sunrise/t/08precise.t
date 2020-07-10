# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Sunrise
#     Copyright © 2003, 2004, 2013, 2020 Ron Hill and Jean Forget
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
use Test::More;
use DateTime;
use DateTime::Event::Sunrise;

my $fuzz = 30; # fuzz time in seconds
my @Boston_data    = load_Boston();
my @Anchorage_data = load_Anchorage();
my @Fairbanks_data = load_Fairbanks();
plan tests => 2 * (@Boston_data + @Anchorage_data + @Fairbanks_data);

sub check {
  my ($dtes, $tz, $ln, $loc) = @_;
  my ($yyyy, $mm, $dd, $rise, $set) = $ln =~ /^\s*
                                               (\d{4})-(\d\d)-(\d\d)
                                               \s+
                                               (\d\d:\d\d:\d\d)
                                               \s+
                                               (\d\d:\d\d:\d\d)
                                               \s* $/x;
  my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd, time_zone => $tz);
  my $date = $dt->ymd;
  my $sunrise = $dtes->sunrise_datetime($dt)->set_time_zone($tz);
  my $sunset  = $dtes-> sunset_datetime($dt)->set_time_zone($tz);

  my  $sunrise_00 = $sunrise->clone                            ->hms;
  my  $sunrise_lo = $sunrise->clone->subtract(seconds => $fuzz)->hms;
  my  $sunrise_hi = $sunrise->clone->add     (seconds => $fuzz)->hms;
  ok ($sunrise_lo le $rise && $sunrise_hi ge $rise, "comparing $sunrise_00 with $rise in $loc on $date");

  my  $sunset_00  = $sunset ->clone                            ->hms;
  my  $sunset_lo  = $sunset ->clone->subtract(seconds => $fuzz)->hms;
  my  $sunset_hi  = $sunset ->clone->add     (seconds => $fuzz)->hms;
  ok ($sunset_lo  le $set  && $sunset_hi  ge $set , "comparing $sunset_00 with $set in $loc on $date");
}

my $Boston = DateTime::Event::Sunrise->new(
                     longitude => -71.2044 # 71°12'15"
                   , latitude  =>  42.3358 # 42°20'08"
                   , altitude  => -0.833
                   , precise   => 1
                   );
for my $ln (@Boston_data) {
  check($Boston, 'America/New_York', $ln, 'Boston');
}

my $Anchorage = DateTime::Event::Sunrise ->new(
                     longitude  => -149.9 # 149°54'
                   , latitude   =>   61.2 #  61°12'
                   , precise    => 1,
                   );
for my $ln (@Anchorage_data) {
  check($Anchorage, 'America/Anchorage', $ln, 'Anchorage');
}

my $Fairbanks = DateTime::Event::Sunrise ->new(
                     longitude  => -147.71639 # 147°42'59"
                   , latitude   =>   64.83778 #  64°50'16"
                   , precise    => 1,
                   );
for my $ln (@Fairbanks_data) {
  check($Fairbanks, 'America/Anchorage', $ln, 'Fairbanks');
}

#
# Data compiled from Stellarium, cross-checked with Astro::PAL + Astro::Coords and with the NOOA's solar calculator
#
sub load_Boston {
  return split "\n", <<'EOF';
    2020-01-01  07:13:59   16:22:42
    2020-02-01  06:58:50   16:58:23
    2020-03-01  06:19:23   17:35:24
    2020-04-01  06:26:29   19:11:19
    2020-05-01  05:39:27   19:45:02
    2020-06-01  05:10:29   20:15:31
    2020-07-01  05:12:12   20:25:20
    2020-08-01  05:38:00   20:03:39
    2020-09-01  06:10:36   19:17:54
    2020-10-01  06:42:29   18:25:24
    2020-11-01  06:18:47   16:37:30
    2020-12-01  06:54:51   16:13:08
    2020-04-01  06:26:29   19:11:19
    2020-04-02  06:24:46   19:12:27
    2020-04-03  06:23:04   19:13:34
    2020-04-04  06:21:22   19:14:42
    2020-04-05  06:19:40   19:15:49
    2020-04-06  06:17:58   19:16:56
    2020-04-07  06:16:17   19:18:04
    2020-04-08  06:14:37   19:19:11
    2020-04-09  06:12:57   19:20:18
    2020-04-10  06:11:17   19:21:26
    2020-04-11  06:09:38   19:22:33
    2020-04-12  06:08:00   19:23:41
    2020-04-13  06:06:22   19:24:48
    2020-04-14  06:04:45   19:25:56
    2020-04-15  06:03:09   19:27:03
    2020-04-16  06:01:33   19:28:11
    2020-04-17  05:59:58   19:29:19
    2020-04-18  05:58:24   19:30:26
    2020-04-19  05:56:51   19:31:34
    2020-04-20  05:55:19   19:32:42
    2020-04-21  05:53:47   19:33:49
    2020-04-22  05:52:16   19:34:57
    2020-04-23  05:50:47   19:36:05
    2020-04-24  05:49:18   19:37:12
    2020-04-25  05:47:50   19:38:20
    2020-04-26  05:46:24   19:39:27
    2020-04-27  05:44:58   19:40:34
    2020-04-28  05:43:34   19:41:41
    2020-04-29  05:42:10   19:42:48
    2020-04-30  05:40:48   19:43:55
EOF
}

#
# Data compiled from Stellarium, cross-checked with the NOOA's solar calculator
#
sub load_Anchorage {
  return split "\n", <<'EOF';
    2020-01-01  10:13:57   15:52:38
    2020-02-01  09:20:43   17:06:33
    2020-03-01  07:58:02   18:26:49
    2020-04-01  07:20:27   20:47:38
    2020-05-01  05:48:37   22:06:35
    2020-06-01  04:34:47   23:21:52
    2020-07-01  04:28:18   23:38:14
    2020-08-01  05:33:48   22:36:10
    2020-09-01  06:53:14   21:03:47
    2020-10-01  08:08:02   19:28:38
    2020-11-01  08:29:34   16:55:51
    2020-12-01  09:47:04   15:50:28
    2020-06-01  04:34:47   23:21:51
    2020-06-02  04:33:13   23:23:41
    2020-06-03  04:31:44   23:25:28
    2020-06-04  04:30:19   23:27:10
    2020-06-05  04:28:59   23:28:47
    2020-06-06  04:27:45   23:30:20
    2020-06-07  04:26:35   23:31:49
    2020-06-08  04:25:30   23:33:12
    2020-06-09  04:24:31   23:34:31
    2020-06-10  04:23:38   23:35:44
    2020-06-11  04:22:50   23:36:52
    2020-06-12  04:22:08   23:37:54
    2020-06-13  04:21:32   23:38:51
    2020-06-14  04:21:02   23:39:41
    2020-06-15  04:20:38   23:40:26
    2020-06-16  04:20:21   23:41:05
    2020-06-17  04:20:09   23:41:37
    2020-06-18  04:20:04   23:42:03
    2020-06-19  04:20:05   23:42:24
    2020-06-20  04:20:13   23:42:37
    2020-06-21  04:20:27   23:42:44
    2020-06-22  04:20:47   23:42:45
    2020-06-23  04:21:13   23:42:40
    2020-06-24  04:21:46   23:42:28
    2020-06-25  04:22:24   23:42:10
    2020-06-26  04:23:09   23:41:46
    2020-06-27  04:23:59   23:41:15
    2020-06-28  04:24:56   23:40:39
    2020-06-29  04:25:57   23:39:56
    2020-06-30  04:27:05   23:39:08
EOF
}

#
# Data compiled from Stellarium, cross-checked with the NOOA's solar calculator
#
sub load_Fairbanks {
  return split "\n", <<'EOF';
    2020-06-01  03:30:23   00:10:05
    2020-06-02  03:27:32   00:13:13
    2020-06-03  03:24:45   00:16:15
    2020-06-04  03:22:03   00:19:15
    2020-06-05  03:19:24   00:22:09
    2020-06-06  03:16:53   00:24:59
    2020-06-07  03:14:28   00:27:42
    2020-06-08  03:12:10   00:30:18
    2020-06-09  03:09:59   00:32:46
    2020-06-10  03:07:56   00:35:06
    2020-06-11  03:06:02   00:37:16
    2020-06-12  03:04:17   00:39:16
    2020-06-13  03:02:44   00:41:06
    2020-06-14  03:01:21   00:42:43
    2020-06-15  03:00:10   00:44:09
    2020-06-16  02:59:12   00:45:20
    2020-06-17  02:58:29   00:46:18
    2020-06-18  02:57:58   00:47:01
    2020-06-19  02:57:43   00:47:30
    2020-06-20  02:57:42   00:47:44
    2020-06-21  02:57:56   00:47:42
    2020-06-22  02:58:25   00:47:26
    2020-06-23  02:59:08   00:46:55
    2020-06-24  03:00:06   00:46:10
    2020-06-25  03:01:19   00:45:11
    2020-06-26  03:02:43   00:44:00
    2020-06-27  03:04:21   00:42:37
    2020-06-28  03:06:11   00:41:02
    2020-06-29  03:08:11   00:39:17
    2020-06-30  03:10:20   00:37:22
EOF
}
