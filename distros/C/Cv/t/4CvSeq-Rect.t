# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 21;
use Test::Exception;
BEGIN { use_ok('Cv') }

my $stor = Cv::MemStorage->new;

if (1) {
	my $seq = bless Cv::Seq->new(CV_32SC4), 'Cv::Seq::Rect';

	$seq->push([ 1, 2, 3, 4 ]);
	my $x = $seq->pop;
	is($x->[0], 1);
	is($x->[1], 2);
	is($x->[2], 3);
	is($x->[3], 4);

	$seq->push([ 11, 12, 13, 14 ],
			   [ 21, 22, 23, 24 ],
		);
	my @x = $seq->toArray;
	is($x[0]->[0], 11);
	is($x[0]->[1], 12);
	is($x[0]->[2], 13);
	is($x[0]->[3], 14);
	is($x[1]->[0], 21);
	is($x[1]->[1], 22);
	is($x[1]->[2], 23);
	is($x[1]->[3], 24);

	# overload
	@x = @$seq;
	is($x[0]->[0], 11);
	is($x[0]->[1], 12);
	is($x[0]->[2], 13);
	is($x[0]->[3], 14);
	is($x[1]->[0], 21);
	is($x[1]->[1], 22);
	is($x[1]->[2], 23);
	is($x[1]->[3], 24);
}
