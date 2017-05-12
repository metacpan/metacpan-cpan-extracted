
=head1 NAME

t001.t	- How to use this module
#!perl  -T

=head1 DESCRIPTION

Check that the Shabbat before Tisha b'Av is Devarim. If 9 Av is
a Shabbat then Devarim is read on 9th Av, and Tisha b'Av is on
Sunday 10 Av.

This variant is for outside Israel.

=cut

use strict;
use warnings;
use Test::More tests => 30;
use FindBin qw($Bin);
use lib qq($Bin/../lib);

use DateTime;
use DateTime::Event::Jewish::Parshah qw(parshah);
use DateTime::Calendar::Hebrew;

for (my $year=5770; $year< 5800; $year++) {
    my $date	= DateTime::Calendar::Hebrew->new(day=>2,
			month=>5, year=>$year);
    my $parshah	= parshah($date);

    like($parshah, qr/Devarim/, "Tisha B'Av $year");
}
exit 0;
