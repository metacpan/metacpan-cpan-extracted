#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Validate::DNS::NAPTR::Regexp;

my $res = <<'EOF';
(cat)(dog)(mouse) 3
(cat(dog(mouse))bird) 3
(bird(horse(a(z)))) 4
what 0
EOF

for my $pair (split(/\n/, $res)) {
	my ($reg, $count) = split(/\s+/, $pair);

	is(Data::Validate::DNS::NAPTR::Regexp::_count_nsubs($reg), $count, "Got $count for $reg\n");	
}

done_testing;
