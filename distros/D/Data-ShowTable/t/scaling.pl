#!/usr/bin/env perl

# Test column scaling

use Data::ShowTable;
require 'Test-Setup.pl';

sub start_tests($);
sub run_test($&);

$showSub = \&ShowBoxTable unless $showSub ne '';

start_tests 8;

# Test negative widths
run_test 1, sub {
    &$showSub({	widths  => [ -5, -20, -10, -30, -10 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
		max_width => 60,
	  });
};

# Test positive widths
run_test 2, sub {
    &$showSub({ widths  => [ +5, +20, +10, +30, -10 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
		max_width => 40,
	  });
};

# Test no widths
run_test 3, sub {
    &$showSub({ widths  => [ ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
		max_width => 30,
	  });
};

# Test large widths (with a rewindable data set, should be the same as minimal 
# columns).

run_test 4, sub {
    &$showSub({ widths  => [ +15, +30, +20, +40, +10 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
		max_width => 30,
	  });
};

# Test large widths with non-rewindable data set. (can't analyze the data,
# so columns will be large).

run_test 5, sub {
    &$showSub({ widths  => [ +15, +30, +20, +40, +15 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRowOnce,
		max_width => 70,
	  });
};


# Still have fixed columns, but maybe cause wrapping
run_test 6, sub {
    &$showSub({ widths  => [ +14, +25, +15, +25, +10 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRowOnce,
		max_width => 60,
	  });
};

# Now, have a no-limit column mixed in with a fixed width
run_test 7, sub {
    &$showSub({ widths  => [ +14, 0, +15, +25, +10 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
		max_width => 60,
	  });
};

# Now, have a no-limit column mixed in with a max width
run_test 8, sub {
    &$showSub({ widths  => [ +14, '', +10, +10, +10 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
		max_width => 30,
	  });
};
