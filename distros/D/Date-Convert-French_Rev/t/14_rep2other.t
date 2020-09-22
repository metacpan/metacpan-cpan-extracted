# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright © 2015, 2020 Jean Forget
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
use utf8;
use Test::More;
use Date::Convert::French_Rev;

sub check_Julian {
  my ($fy, $fm, $fd, $jy, $jm, $jd) = @_;

  my $string = Date::Convert::Julian->new($jy, $jm, $jd)->date_string;

  my $d1     = Date::Convert::French_Rev->new($fy, $fm, $fd);
  $d1->change_to("Date::Convert::Julian");
  my $date_resul = $d1->date_string;
  ok($d1->year eq $jy && $d1->month eq $jm && $d1->day eq $jd, "expected $string, got $date_resul" );

  my $d2     = Date::Convert::French_Rev->new($fy, $fm, $fd);
  Date::Convert::Julian->convert($d2);
  $date_resul = $d2->date_string;
  ok($d2->year eq $jy && $d2->month eq $jm && $d2->day eq $jd, "expected $string, got $date_resul" );

  $string   = Date::Convert::French_Rev->new($fy, $fm, $fd)->date_string;

  #my $d3     = Date::Convert::Julian->new($fy, $fm, $fd);
  #$d3->change_to("Date::Convert::French_Rev");
  #$date_resul = $d3->date_string;
  #ok($d3->year eq $fy && $d3->month eq $fm && $d3->day eq $fd, "expected $string, got $date_resul" );

  my $d4     = Date::Convert::Julian->new($jy, $jm, $jd);
  Date::Convert::French_Rev->convert($d4);
  $date_resul = $d4->date_string;
  ok($d4->year eq $fy && $d4->month eq $fm && $d4->day eq $fd, "expected $string, got $date_resul" );
}

sub check_Hebrew {
  my ($fy, $fm, $fd, undef, undef, undef, $jy, $jm, $jd) = @_;

  my $string = Date::Convert::Hebrew->new($jy, $jm, $jd)->date_string;

  my $d1     = Date::Convert::French_Rev->new($fy, $fm, $fd);
  $d1->change_to("Date::Convert::Hebrew");
  my $date_resul = $d1->date_string;
  ok($d1->year eq $jy && $d1->month eq $jm && $d1->day eq $jd, "expected $string, got $date_resul" );

  my $d2     = Date::Convert::French_Rev->new($fy, $fm, $fd);
  Date::Convert::Hebrew->convert($d2);
  $date_resul = $d2->date_string;
  ok($d2->year eq $jy && $d2->month eq $jm && $d2->day eq $jd, "expected $string, got $date_resul" );

  $string   = Date::Convert::French_Rev->new($fy, $fm, $fd)->date_string;

  #my $d3     = Date::Convert::Hebrew->new($fy, $fm, $fd);
  #$d3->change_to("Date::Convert::French_Rev");
  #$date_resul = $d3->date_string;
  #ok($d3->year eq $fy && $d3->month eq $fm && $d3->day eq $fd, "expected $string, got $date_resul" );

  my $d4     = Date::Convert::Hebrew->new($jy, $jm, $jd);
  Date::Convert::French_Rev->convert($d4);
  $date_resul = $d4->date_string;
  ok($d4->year eq $fy && $d4->month eq $fm && $d4->day eq $fd, "expected $string, got $date_resul" );
}

@tests = ([ 209,  4, 12, 2000, 12, 19, 5761, 10,  6 ]
        , [ 223, 11, 23, 2015,  7, 28, 5775,  5, 25 ]
          );

plan(tests => 6 * scalar @tests);

foreach (@tests) {
  check_Julian @$_;
  check_Hebrew @$_;
}
