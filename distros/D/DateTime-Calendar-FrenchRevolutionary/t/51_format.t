# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2011, 2012, 2014, 2016 Jean Forget. All rights reserved.
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
#     Inc., <http://www.fsf.org/>.
#
use DateTime::Calendar::FrenchRevolutionary;
use DateTime;
use utf8;
use strict;
use warnings;

# Checking dates with default French locale
sub g2r {
  my ($n, $ref_date_r, $ref_format, $y, $m, $d) = @_;
  my @format = @$ref_format;
  my @date_r = @$ref_date_r;
  my $date_g = DateTime->new(year => $y, month => $m, day => $d);
  my @date_resul = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g)->strftime(@format);

  my $ok = "ok";
  for (my $i = 0; $i < @date_resul; $i++) {
    if ($date_resul[$i] ne $date_r[$i]) {
      $ok = "not ok";
      last;
    }
  }
  print "$ok $n\n";
}

# Checking dates with alternate English locale
sub g2r_en {
  my ($n, $ref_date_r, $ref_format, $y, $m, $d) = @_;
  my @format = @$ref_format;
  my @date_r = @$ref_date_r;
  my $date_g = DateTime->new(year => $y, month => $m, day => $d);
  my @date_resul = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g)->set(locale => 'en')->strftime(@format);

  my $ok = "ok";
  for (my $i = 0; $i < @date_resul; $i++) {
    if ($date_resul[$i] ne $date_r[$i]) {
      $ok = "not ok";
      last;
    }
  }
  print "$ok $n\n";
}

# checking times and dates-times
sub fr_t {
  my ($n, $date_r, $format, $locale, $y, $m, $d, $H, $M, $S) = @_;
  my $date_resul = DateTime::Calendar::FrenchRevolutionary->new(
        year => $y, month => $m, day => $d, hour => $H, minute => $M, second => $S, locale => $locale)->strftime($format);
  if ($date_r eq $date_resul) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $date_r, got $date_resul\n";
  }
}

my @tests = ([ [ qw/Nonidi 09 Thermidor II/ ], [ qw/%A %d %B %EY/ ], 1794,  7, 27],
             [ [ qw/Oct 18 Bru 0008/ ],        [ qw/%a %d %b %Y/ ],  1799, 11,  9],
             );

my @tests_en = ([ [ qw/Nineday 09 Heatidor II/ ], [ qw/%A %d %B %EY/ ], 1794,  7, 27],
       [ [ qw/Tenday Ten 10/ ], [ qw/%A %a %d/ ], 1794, 7, 28],
             );


my $nb_tests = @tests + @tests_en;
my $n = 1;

print "1..$nb_tests\n";

foreach (@tests     ) { g2r    $n++, @$_ }
foreach (@tests_en  ) { g2r_en $n++, @$_ }

