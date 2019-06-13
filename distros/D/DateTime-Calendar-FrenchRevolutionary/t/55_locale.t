# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2010, 2011, 2012, 2014, 2016, 2019 Jean Forget. All rights reserved.
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
use DateTime::Calendar::FrenchRevolutionary::Locale::en;
use DateTime::Calendar::FrenchRevolutionary::Locale::fr;
use utf8;
use strict;
use warnings;

# Test with nearly empty subclass
package Alten;
use base 'DateTime::Calendar::FrenchRevolutionary::Locale::en';
sub date_before_time { "0"; }

package Altfr;
use base 'DateTime::Calendar::FrenchRevolutionary::Locale::fr';
sub date_before_time { "0"; }

package main;
my $n = 0;

sub check {
  my ($method, $fr_result, $en_result, $altfr_result, $alten_result) = @_;

  $altfr_result = $fr_result unless defined $altfr_result;
  $alten_result = $en_result unless defined $alten_result;

  my $fr_test = DateTime::Calendar::FrenchRevolutionary::Locale::fr->$method;
  my $en_test = DateTime::Calendar::FrenchRevolutionary::Locale::en->$method;
  my $altfr_test = Altfr->$method;
  my $alten_test = Alten->$method;

  ++ $n;
  if ($fr_test eq $fr_result) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected '$fr_result', got '$fr_test'\n";
  }

  ++ $n;
  if ($en_test eq $en_result) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected '$en_result', got '$en_test'\n";
  }

  ++ $n;
  if ($altfr_test eq $altfr_result) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected '$altfr_result', got '$altfr_test'\n";
  }

  ++ $n;
  if ($alten_test eq $alten_result) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected '$alten_result', got '$alten_test'\n";
  }

}


my @tests = (
       [ "full_date_format",         "%A %d %B %EY, %{feast_long}",                 "%A %d %B %EY, %{feast_long}" ],
       [ "long_date_format",         "%A %d %B %EY",                                "%A %d %B %EY"                ],
       [ "medium_date_format",       "%a %d %b %Y",                                 "%a %d %b %Y"                 ],
       [ "short_date_format",        "%d/%m/%Y",                                    "%d/%m/%Y"                    ],
       [ "default_date_format",      "%a %d %b %Y",                                 "%a %d %b %Y"                 ],
       [ "full_time_format",         "%H h %M mn %S s",                             "%H h %M mn %S s"             ],
       [ "long_time_format",         "%H:%M:%S",                                    "%H:%M:%S",                   ],
       [ "medium_time_format",       "%H:%M:%S",                                    "%H:%M:%S",                   ],
       [ "short_time_format",        "%H:%M",                                       "%H:%M",                      ],
       [ "default_time_format",      "%H:%M:%S",                                    "%H:%M:%S",                   ],
       [ "full_datetime_format",     "%A %d %B %EY, %{feast_long} %H h %M mn %S s", "%A %d %B %EY, %{feast_long} %H h %M mn %S s",
                                     "%H h %M mn %S s %A %d %B %EY, %{feast_long}", "%H h %M mn %S s %A %d %B %EY, %{feast_long}" ],
       [ "long_datetime_format",     "%A %d %B %EY %H:%M:%S",                       "%A %d %B %EY %H:%M:%S",
                                     "%H:%M:%S %A %d %B %EY",                       "%H:%M:%S %A %d %B %EY"       ],
       [ "medium_datetime_format",   "%a %d %b %Y %H:%M:%S",                        "%a %d %b %Y %H:%M:%S",
                                     "%H:%M:%S %a %d %b %Y",                        "%H:%M:%S %a %d %b %Y"        ],
       [ "short_datetime_format",    "%d/%m/%Y %H:%M",                              "%d/%m/%Y %H:%M",
                                     "%H:%M %d/%m/%Y",                              "%H:%M %d/%m/%Y"              ],
       [ "default_datetime_format",  "%a %d %b %Y %H:%M:%S",                        "%a %d %b %Y %H:%M:%S",
                                     "%H:%M:%S %a %d %b %Y",                        "%H:%M:%S %a %d %b %Y"        ],
       [ "date_parts_order",         "dmy",                                         "dmy",                        ],
);

printf "1..%d\n", 4 * @tests;

foreach (@tests) { check @$_ }

