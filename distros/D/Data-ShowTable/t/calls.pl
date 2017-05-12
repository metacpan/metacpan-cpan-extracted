#!/usr/bin/env perl

# Test calling sequences.
# set $showSub or default to 'ShowBoxTable'.

use Data::ShowTable;
require 'Test-Setup.pl';

sub start_tests($);
sub run_test($&);

$showSub = \&ShowBoxTable unless $showSub ne '';

start_tests 8;

run_test 1, sub { 
    &$showSub(\@Titles, \@Types, \@Widths, \&showDataRow); 
};

run_test 2, sub { 
    &$showSub(\@Titles, \@Types, \@Widths, \&showDataRow, \&ShowTableValue); 
};

run_test 3, sub { 
    &$showSub(\@Titles, \@Types, \@Widths, \&showDataRow, \&ShowTableValue, 80); 
};

run_test 4, sub { 
    &$showSub(\@Titles, \@Types, \@Widths, \&showDataRow, '', 80); 
};

run_test 5, sub { 
    &$showSub({	titles => \@Titles, 
		types  => \@Types, 
		widths => \@Widths,
		row_sub => \&showDataRow,
	      });
};

run_test 6, sub { 
    &$showSub({	titles => \@Titles, 
		types  => \@Types, 
		widths => \@Widths,
		row_sub => \&showDataRow,
		fmt_sub => \&ShowTableValue,
	      });
};

run_test 7, sub { 
    &$showSub({	titles => \@Titles, 
		types  => \@Types, 
		widths => \@Widths,
		row_sub => \&showDataRow,
		fmt_sub => \&ShowTableValue,
		max_width => 80,
	      });
};

run_test 8, sub { 
    &$showSub({	titles => \@Titles, 
		types  => \@Types, 
		widths => \@Widths,
		row_sub => \&showDataRow,
		max_width => 80,
	      });
};
