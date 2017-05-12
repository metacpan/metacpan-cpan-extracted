use strict;
use warnings;
use Test::More tests => 3;
use Data::Deduper;

my @data = (1, 2, 3);

my $dd = Data::Deduper->new(
	size => 3,
	data => \@data,
);

is_deeply([$dd->dedup(3,4,5)], [4,5], 'dedup');
is_deeply([$dd->data], [3,4,5], 'data');
is_deeply([$dd->init(2,5,6)], [2,5,6], 'init');
