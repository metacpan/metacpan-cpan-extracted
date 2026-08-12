#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use require::relative q (test-helper.pl);

plan tests => 4;

my $root = current_frame;

it q (root frame should return itself as a root)
	=> got    => current_frame->root_frame
	=> expect => shallow ($root)
	;

frame {
	it q (child frame should return a root)
		=> got    => current_frame->root_frame
		=> expect => shallow ($root)
		;

	frame {
		it q (another child frame should return a root)
			=> got    => current_frame->root_frame
			=> expect => shallow ($root)
			;
	};
};

had_no_warnings;

done_testing;
