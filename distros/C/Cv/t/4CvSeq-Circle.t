# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 16;
use Test::Exception;
BEGIN { use_ok('Cv') }

my $stor = Cv::MemStorage->new;

if (1) {
	my $seq = bless Cv::Seq->new(CV_32FC4), 'Cv::Seq::Circle';

	$seq->push([[ 1, 2 ], 3 ]);
	my $x = $seq->pop;
	is($x->[0]->[0], 1);
	is($x->[0]->[1], 2);
	is($x->[1], 3);

	$seq->push([[ 11, 12 ], 13 ],
			   [[ 21, 22 ], 23 ],
		);
	my @x = $seq->toArray;
	is($x[0]->[0]->[0], 11);
	is($x[0]->[0]->[1], 12);
	is($x[0]->[1], 13);
	is($x[1]->[0]->[0], 21);
	is($x[1]->[0]->[1], 22);
	is($x[1]->[1], 23);

	# overload
	@x = @$seq;
	is($x[0]->[0]->[0], 11);
	is($x[0]->[0]->[1], 12);
	is($x[0]->[1], 13);
	is($x[1]->[0]->[0], 21);
	is($x[1]->[0]->[1], 22);
	is($x[1]->[1], 23);
}
