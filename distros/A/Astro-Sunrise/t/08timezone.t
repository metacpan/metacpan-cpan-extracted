#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Astro::Sunrise
#     Copyright (C) 2015, 2017, 2021 Ron Hill and Jean Forget
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
use Astro::Sunrise(qw(:DEFAULT :constants));
use Test::More;

BEGIN {
  eval "use DateTime;";
  if ($@) {
    plan skip_all => "DateTime needed";
    exit;
  }
}
plan(tests => 4);

my $sunrise_5 = sun_rise({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles', });
my $sunrise_6 = sun_rise({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles',
                           alt => DEFAULT, offset => 0, upper_limb => 0, precise => 0 });

is( $sunrise_5, $sunrise_6 , "Comparing basic parameters with all parameters");

my $sunset_5 = sun_set({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles', });
my $sunset_6 = sun_set({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles',
                         alt => DEFAULT, offset => 0, upper_limb => 0, precise => 0 });

is($sunset_5, $sunset_6, "Comparing basic parameters with all parameters");

my $then = DateTime->today ( time_zone =>'America/Los_Angeles', )->set_hour(12);
my $offset = ($then->offset) /60 /60;
my ($sunrise, $sunset) = sunrise($then->year, $then->mon, $then->mday,
                              -118, 33, $offset, 0);
is ($sunrise, $sunrise_6, "Test DateTime sunrise interface");
is ($sunset,  $sunset_6,  "Test DateTime sunset interface");


__END__

=encoding utf-8

=head1 NAME

08timezone.t -- test script for Astro::Sunrise and its interface with DateTime

=head1 SYNOPSIS

  prove t/08timezone.t

=head1 DESCRIPTION

This test scripts checks the L<Astro::Sunrise> module when used with L<DateTime>.

=head1 BUGS

In version 0.96, this test script would fail on two days each year: on America/Los_Angeles
spring-forward day and on America/Los_Angeles fall-back day. This happens no matter
where the computer is located and no matter how it is configured, because the
timezone name is hard-coded.

Explanation of the bug: the script computes the sunrise and sunset of the current day in
Los Angeles and returns them as L<DateTime> objects. Then it extracts the timezone offset
at midnight (that is, 0 hours in the morning, not 24h in the evening) and compares it with
the timezone offset of the sunrise L<DateTime> object and with the timezone offset of the
sunset L<DateTime> object. The problem is that DST has been put into effect or removed
between 0h and sunrise, so the offsets are different.

In 2017, the bug-inducing dates are 2017-03-12 and 2017-11-05.

=head1 USAGE

To check the bug fix, I need to change the computer's internal date. I do not dare
change it on my physical computer, so I use a VM. So, on the command line in the VM:

  scp jf@192.168.x.y:/path/to/Astro-Sunrise/Astro-Sunrise-0.99.tar.gz .
  tar -zxvf Astro-Sunrise-0.99.tar.gz
  cd Astro-Sunrise-0.99
  perl Makefile.PL
  make
  make test
  sudo date 031216302017
  make test
  sudo date 110512152017
  make test

And you can choose other dates to check the script a bit more thoroughly.

=head1 AUTHOR

Jean Forget (JFORGET at cpan dot org)

=head1 COPYRIGHT and LICENSE

This program is distributed under the same terms as Perl 5.16.3:
GNU Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<https://dev.perl.org/licenses/artistic.html>
and L<https://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., L<https://www.fsf.org/>.

=head1 SEE ALSO

perl(1).

L<Astro::Sunrise>

=cut
