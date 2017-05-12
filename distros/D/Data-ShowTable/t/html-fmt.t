#!/usr/bin/perl5

# Test HTML formatting

use Data::ShowTable;

unshift(@INC,'../blib/lib') if -d '../blib/lib';
unshift(@INC,'t') if -d 't';

@Data = ();

require 'Test-Setup.pl';

sub start_tests($);
sub run_test($&);

start_tests 12;

run_test 1, sub { 
    &ShowHTMLTable(\@Titles, \@Types, \@Widths, \&showDataRow, '', 80); 
};

run_test 2, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			dformats => [ 'FONT SIZE=-1', '' ],
			row_sub => \&showDataRow,
	      });
};

run_test 3, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			dformats => [ 'FONT SIZE=-1' ],
			row_sub => \&showDataRow,
	      });
};

run_test 4, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			tformats => [ 'B,I' ],
			row_sub => \&showDataRow,
			fmt_sub => \&ShowTableValue,
	      });
};

run_test 5, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			row_sub => \&showDataRow,
			fmt_sub => \&ShowTableValue,
			table_attrs => 'BORDER=0',
	      });
};

run_test 6, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			row_sub => \&showDataRow,
			fmt_sub => \&ShowTableValue,
			table_attrs => 'ALIGN=CENTER',
	      });
};

run_test 7, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			row_sub => \&showDataRow,
			max_width => 80,
			tformats => [ 'b,i' ],
			dformats => [ 'tt' ],
			table_attrs => 'align=center',
	      });
};

run_test 8, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			url_keys => { "Name" => "/cgi/foo?name=%V",
				      "Address" => "/cgi/foo?addr=%V",
				      "Index" => "/cgi/foo?index=%V",
				    },
			row_sub => \&showDataRow,
	      });
};

# On this test, use embedded URLs
foreach $row (@Data) {
    $row->[1] = "<B>".$row->[1]."</B>";
    $row->[2] = "<I>".$row->[2]."</I>";
}

run_test 9, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			no_escape => 1,
			widths => \@Widths,
			row_sub => \&showDataRow,
	      });
};

run_test 10, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			no_escape => 1,
			table_attrs => 'BORDER=2 CELLSPACING=0 CELLPADDING=2',
			widths => \@Widths,
			row_sub => \&showDataRow,
	      });
};

run_test 11, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			no_escape => 1,
			dformats => [ 'FONT SIZE=-1', '' ],
			url_keys => {
				Index => "http://cgi-bin/lookup?%K=%V",
				Name  => "http://cgi-bin/lookup?%K=%V",
			    },
			row_sub => \&showDataRow,
	      });
};

run_test 12, sub { 
    &ShowHTMLTable({	titles => \@Titles, 
			types  => \@Types, 
			widths => \@Widths,
			no_escape => 1,
			dformats => [ 'FONT SIZE=-1' ],
			url_keys => {
				Index   => "http://cgi-bin/lookup?Index=%I?Key=%K?Value=%V",
				Name    => "http://cgi-bin/lookup?Index=%I?Key=%K?Value=%V",
				Phone   => "http://cgi-bin/lookup?Index=%I?Key=%K?Value=%V",
				Address => "http://cgi-bin/lookup?Index=%I?Key=%K?Value=%V",
			    },
			row_sub => \&showDataRow,
	      });
};
