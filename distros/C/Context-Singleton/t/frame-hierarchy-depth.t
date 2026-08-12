#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use require::relative q (test-helper.pl);

plan tests => 5;

it q (depth of root frame should be 0)
	=> got    => current_frame->depth
	=> expect => 0
	;

frame {
	it q (depth of root's child frame should be 1)
		=> got    => current_frame->depth
		=> expect => 1
		;

	frame {
		it q (depth of another child frame should be 2)
			=> got    => current_frame->depth
			=> expect => 2
			;
	};

	it q (after returning back current frame depth should be 1 again)
		=> got    => current_frame->depth
		=> expect => 1
		;
};

had_no_warnings;

done_testing;
