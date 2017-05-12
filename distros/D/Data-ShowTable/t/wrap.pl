#!/usr/bin/env perl

# Test use of wrapping

use Data::ShowTable;
require 'Test-Setup.pl';

sub start_tests($);
sub run_test($&);

$showSub = \&ShowBoxTable unless $showSub ne '';

@Data = ( [ "Alan", "This is a very long line of text which simulates a text ".
		    "string which is supposed to wrap in its field width." ],
	  [ "Kevin", "This is another long line of text which will also wrap ".
		    "so I can see if this part of ShowTable really works as ".
		    "designed.  If not it's back to the drawing board." ],
	  [ "Toad",  "This is a short line" ],
	  [ "Monica", "This is another short line" ],
	  [ "Stu",   "Finally, here is another long line which shold wrap but ".
		    "maybe not" ],
	);
@Types  = qw( char text );
@Titles = qw( Name Biography );

start_tests 5;

# Test negative widths
run_test 1, sub {
    &$showSub({	widths	=> [ -10, 40 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
	      });
};

# Test with positive widths
run_test 2, sub {
    &$showSub({	widths	=> [ 10, 40 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
	      });
};

# Test with no widths
run_test 3, sub {
    &$showSub({ widths  => [ ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
	  });
};

# Test large widths (with a rewindable data set, should be the same as
# minimal columns).
run_test 4, sub {
    &$showSub({ widths  => [ 20, 60 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRow,
	  });
};

# Test large widths with non-rewindable data set. (can't analyze the
# data, so columns will be large).

run_test 5, sub {
    &$showSub({ widths  => [ 20, 60 ],
		titles  => \@Titles,
		types   => \@Types, 
		row_sub => \&showDataRowOnce,
	  });
};

