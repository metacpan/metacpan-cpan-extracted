#
#     Test script for DateTime::Format::Roman
#     Copyright (C) 2003, 2004, 2018, 2019 Eugene van der Pijll, Dave Rolsky and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.28.0:
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
BEGIN { $^W = 1 }

use Test::More tests => 4;
use DateTime;
use DateTime::Format::Roman;

my $f = DateTime::Format::Roman->new(pattern =>
    '%d:%f:%m:%y:%B:%b:%Od:%od:%1f:%O1D');

for (['2003-03-01', '1:Kal:3:2003:March:Mar:I:i:K:K'],
     ['2003-03-02', '6:Non:3:2003:March:Mar:VI:vi:N:VI N'],
     ['2003-03-08', '8:Id:3:2003:March:Mar:VIII:viii:Id:VIII Id'],
     ['2000-02-24', '6bis:Kal:3:2000:March:Mar:VI bis:vi bis:K:VI bis K'],
    ){
    my ($date, $r) = @$_;

    my ($y, $m, $d) = split /-/, $date;
    my $dt = DateTime->new( year => $y, month => $m, day => $d);

    is( $f->format_datetime( $dt ), $r, $date );;
}
