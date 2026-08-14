#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use require::relative q (test-helper.pl);

plan tests => 4;

sub inner_probe;
sub outer_probe;

it q (FRAME_DEPTH should be the documented call-stack offset of frame {})
	=> got    => Context::Singleton::FRAME_DEPTH
	=> expect => 2
	;

outer_probe;

had_no_warnings;
done_testing;

sub inner_probe {
	frame {
		it q (caller (FRAME_DEPTH) from inside a nested frame {} block should also resolve to its direct caller)
			=> got    => (caller (Context::Singleton::FRAME_DEPTH)) [3]
			=> expect => q (main::inner_probe)
			;
	};
}

sub outer_probe {
	frame {
		it q (caller (FRAME_DEPTH) from inside a top-level frame {} block should resolve to its direct caller)
			=> got    => (caller (Context::Singleton::FRAME_DEPTH)) [3]
			=> expect => q (main::outer_probe)
			;

		inner_probe;
	};
}

