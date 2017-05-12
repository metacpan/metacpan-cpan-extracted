# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 16;
use Test::Exception;
BEGIN { use_ok('Cv') }

if (1) {
	my $arr = Cv::Mat->new([ 3, 3 ], CV_32FC2);
	ok($arr);

	is($arr->rows, 3);
	is($arr->cols, 3);
	
	$arr->set(
		[],
		[ [ [ 0, 0 ], [ 0, 1 ], [ 0, 2 ], ],
		  [ [ 1, 0 ], [ 1, 1 ], [ 1, 2 ], ],
		  [ [ 2, 0 ], [ 2, 1 ], [ 2, 2 ], ], ],
		);

	my $x = $arr->m_get([]);

	# use Data::Dumper;
	# print STDERR Data::Dumper->Dump([$x], [qw(*x)]);

	is_deeply($x->[0]->[0], [0, 0]);
	is_deeply($x->[0]->[1], [0, 1]);
	is_deeply($x->[0]->[2], [0, 2]);

	is_deeply($x->[1]->[0], [1, 0]);
	is_deeply($x->[1]->[1], [1, 1]);
	is_deeply($x->[1]->[2], [1, 2]);

	is_deeply($x->[2]->[0], [2, 0]);
	is_deeply($x->[2]->[1], [2, 1]);
	is_deeply($x->[2]->[2], [2, 2]);


	my $x2 = $arr->m_get([2]);
	is_deeply($x2->[0], [2, 0]);
	is_deeply($x2->[1], [2, 1]);
	is_deeply($x2->[2], [2, 2]);
}
