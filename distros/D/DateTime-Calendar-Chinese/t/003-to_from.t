use strict;
use Test::More (tests => 4);
use_ok("DateTime::Calendar::Chinese");

my $dt = DateTime->now();
my $cc1 = DateTime::Calendar::Chinese->from_object(object => $dt);
my $cc2 = DateTime::Calendar::Chinese->from_object(object => $cc1);

my @rd_values_1 = $cc1->utc_rd_values;
my @rd_values_2 = $cc2->utc_rd_values;

is($rd_values_1[0], $rd_values_2[0]);
is($rd_values_1[1], $rd_values_2[1]);
is($rd_values_1[2], $rd_values_2[2]);
