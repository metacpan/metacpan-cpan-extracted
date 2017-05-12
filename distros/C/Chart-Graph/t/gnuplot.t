#!/usr/local/bin/perl -w 
## gnuplot.t is a test script for the graphing package Graph.pm
##
## $Id: gnuplot.t,v 1.9 2006/04/18 17:56:50 emile Exp $ $name$
##
## This software product is developed by Michael Young and David Moore,
## and copyrighted(C) 1998 by the University of California, San Diego
## (UCSD), with all rights reserved. UCSD administers the CAIDA grant,
## NCR-9711092, under which part of this code was developed.
##
## There is no charge for this software. You can redistribute it and/or
## modify it under the terms of the GNU General Public License, v. 2 dated
## June 1991 which is incorporated by reference herein. This software is
## distributed WITHOUT ANY WARRANTY, IMPLIED OR EXPRESS, OF MERCHANTABILITY
## OR FITNESS FOR A PARTICULAR PURPOSE or that the use of it will not
## infringe on any third party's intellectual property rights.
##
## You should have received a copy of the GNU GPL along with this program.
##
## Contact: graph-request@caida.org
##

use t::Config;
use Chart::Graph qw(gnuplot xrt3d);
use strict;
use File::Basename;

$Chart::Graph::save_tmpfiles = 0;
$Chart::Graph::debug = 0; 

$|=1;

# assign $PNAME to the actual program name
# $script_path is the path to the directory the script is in
use vars qw($script_name $script_path $script_suffix $PNAME *OLDOUT);

($script_name, $script_path, $script_suffix) = fileparse($0, ".pl");
$PNAME = "$script_name$script_suffix";

use vars qw($package);


#
#
# test script for the gnuplot package
#
#
print "1..48\n";

my @drivers = @t::Config::drivers;
my $test_gnuplot = 0;

for (@drivers) {
   if ($_ eq "gnuplot") {
	$test_gnuplot = 1;
    }
}

### 1
my $base_test_options = {
	"output file" => "test_results/gnuplot1.png",
	"output type" => "png",
	"title" => "foo",
	"x2-axis label" => "bar",
	"logscale x2" => "1",
	"logscale y" => "1",
	"xtics" => [ ["small\\nfoo", 10], 
		["medium\\nfoo", 20], 
		["large\\nfoo", 30]],
	"ytics" => [10,20,30,40,50]
};
my @base_test_data = (
	[
		{"title" => "data1",
		 "type" => "matrix"}, 
		[[1, 10], 
		 [2, 20], 
		 [3, 30]] 
	],
	[
		{"title" => "data2", 
		 "style" => "lines",
		 "type" => "columns"}, 
	    [8, 26, 50, 60, 70], 
	    [5, 28, 50, 60, 70] 
	],
	[
		{"title" => "data3",
		 "style" => "lines",
		 "type" => "file"}, 
	    "sample"
	]
);
if ($test_gnuplot) {
    if (gnuplot($base_test_options,@base_test_data)) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}

### 2
if ($test_gnuplot) {
    if( gnuplot({"title" => "Examples of Errorbars",
              "xrange" => "[:11]",
              "yrange" => "[:45]",
              "output file" => "test_results/gnuplot2.gif",
	      "output type" => "gif",
             },
             # dataset 1
             [{"title" => "yerrorbars",
               "style" => "yerrorbars",
               "using" => "1:2:3:4",
               "type" => "columns"},
              [ 1, 2, 3, 4, 5, 6 ], # x
              [ 5, 7, 12, 19, 28, 39 ], # y
              [ 3, 5, 10, 17, 26, 38 ], # ylow
              [ 6, 8, 13, 20, 30, 40 ] ], # yhigh
             # dataset 2
             [{"title" => "xerrorbars",
               "style" => "xerrorbars",
               "using" => "1:2:3:4",
               "type" => "columns"},
              [ 4, 5, 6, 7, 8, 9 ], # x
              [ 1, 4, 5, 6, 7, 10 ], # y
              [ 3.3, 4.4, 5.5, 6.6, 7.7, 8.8 ], # xlow
              [ 4.1, 5.2, 6.1, 7.3, 8.1, 10 ] ], # xhigh
             # dataset 3
             [{"title" => "xyerrorbars",
               "style" => "xyerrorbars",
               "using" => "1:2:3:4:5:6",
               "type" => "columns"},
              [ 1.5, 2.5, 3.5, 4.5, 5.5, 6.5 ], # x
              [ 2, 3.5, 7.0, 14, 15, 20 ], # y
              [ 0.9, 1.9, 2.8, 3.7, 4.9, 5.8 ], # xlow
              [ 1.6, 2.7, 3.7, 4.8, 5.6, 6.7 ], # xhigh
              [ 1, 2, 3, 5, 7, 8 ], # ylow
              [ 5, 7, 10, 17, 18, 24 ] ], # yhigh
             # dataset 4
             [{"title" => "xerrorbars w/ xdelta",
               "style" => "xerrorbars",
               "using" => "1:2:3",
               "type" => "columns"},
              [ 4, 5, 6, 7, 8, 9 ], # x
              [ 2.5, 5.5, 6.5, 7.5, 8.6, 11.7 ], # y
              [ .2, .2, .1, .1, .3, .3 ] ], # xdelta
             # dataset 5
             [{"title" => "yerrorbars w/ ydelta",
               "style" => "yerrorbars",
               "using" => "1:2:3",
               "type" => "columns"},
              [ .7, 1.7, 2.7, 3.7, 4.7, 5.7 ], # x
              [ 10, 15, 20, 25, 30, 35 ], # y
              [ .8, 1.2, 1.1, 2.1, 1.3, 3.3 ] ], # ydelta
             # dataset 6
             [{"title" => "dummy data",
               "type" => "matrix"},
              [ [1,1] ]],
             # dataset 7
             [{"title" => "xyerrorbars w/ xydelta",
               "style" => "xyerrorbars",
               "using" => "1:2:3:4",
               "type" => "columns"},
               [ 7.5, 8.0, 8.5, 9.0, 9.5, 10.0 ], # x
               [ 30, 27, 25, 23, 27, 33 ], # y
               [ .2, .1, .3, .6, .4, .3 ], # xdelta
              [ .8, .7, .3, .6, 1.0, .3 ] ], # ydelta
           )

) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}


### 3
if ($test_gnuplot) {
    if(gnuplot({"title" => "Corporate stock values for major computer maker",
           "x-axis label" => "Month and Year",
	   "y-axis label" => "Stock price",
	   "output type" => "png",
           "output file" => "test_results/gnuplot3.png",
	   "xdata" => "time",
	   "timefmt" => "%m/%d/%Y",
	   "xrange" => "[\"06/01/2000\":\"08/01/2001\"]",
	   "format" => ["x", "%m/%d/%Y"],
	   "extra_opts" => join("\n", "set grid", "set timestamp"),


	  },

	  # Data for when stock opened
          [{"title" => "open",
            "type" => "matrix",
	    "style" => "lines",
	   },
	   [
	    ["06/01/2000",  "81.75"],
	    ["07/01/2000", "52.125"],
	    ["08/01/2000", "50.3125"],
	    ["09/01/2000", "61.3125"],
	    ["10/01/2000", "26.6875"],
	    ["11/01/2000", "19.4375"],
	    ["12/01/2000", "17"],
	    ["01/01/2001", "14.875"],
	    ["02/01/2001", "20.6875"],
	    ["03/01/2001", "17.8125"],
	    ["04/01/2001", "22.09"],
	    ["05/01/2001", "25.41"],
	    ["06/01/2001", "20.13"],
	    ["07/01/2001", "23.64"],
	    ["08/01/2001", "19.01"],
	   ]
	  ],


	  # Data for stock high
          [{"title" => "high",
            "type" => "matrix",
	    "style" => "lines",
	   },
	   [
	    ["06/01/2000", "103.9375"],
	    ["07/01/2000", "60.625"],
	    ["08/01/2000", "61.50"],
	    ["09/01/2000", "64.125"],
	    ["10/01/2000", "26.75"],
	    ["11/01/2000", "23"],
	    ["12/01/2000", "17.50"],
	    ["01/01/2001", "22.50"],
	    ["02/01/2001", "21.9375"],
	    ["03/01/2001", "23.75"],
	    ["04/01/2001", "27.12"],
	    ["05/01/2001", "26.70"],
	    ["06/01/2001", "25.10"],
	    ["07/01/2001", "25.22"],
	    ["08/01/2001", "19.90"],
	   ]
	   ],


	  # Data for stock close
          [{"title" => "close",
            "type" => "matrix",
	    "style" => "lines",
	   },
	   [

	    ["06/01/2000", "52.375"],
	    ["07/01/2000", "50.8125"],
	    ["08/01/2000", "60.9375"],
	    ["09/01/2000", "25.75"],
	    ["10/01/2000", "19.5625"],
	    ["11/01/2000", "16.50"],
	    ["12/01/2000", "14.875"],
	    ["01/01/2001", "21.625"],
	    ["02/01/2001", "18.25"],
	    ["03/01/2001", "22.07"],
	    ["04/01/2001", "25.49"],
	    ["05/01/2001", "19.95"],
	    ["06/01/2001", "23.25"],
	    ["07/01/2001", "18.79"],
	    ["08/01/2001", "18.55"],
	   ]
	  ]
		)
      )  {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}

##### 4
# Test example #2 Example on UNIX time stamps.
if ($test_gnuplot) {
    if(gnuplot({"title" => "foo",
                 "output file" => "test_results/gnuplot4.gif",
		 "output type" =>"gif",
                 "x2-axis label" => "bar",
                 "xtics" => [ ["\\n10pm", 954795600] ],
                 "ytics" => [10,20,30,40,50],
                 "extra_opts" => "set nokey",
                 "uts" => [954791100, 954799300],
               },
	       [{"title" => "Your title",
		 "type" => "matrix"},
		[
		 [954792100, 10],
		 [954793100, 18],
		 [954794100, 12],
		 [954795100, 26],
		 [954795600, 13], # 22:00
		 [954796170, 23],
		 [954797500, 37],
		 [954799173, 20],
		 [954799300, 48],
		],
	       ]
	      )
      ) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}

#### 5
# test output to stdout
if ($test_gnuplot) {
	my $fail = undef;
	my $test_filename = "test_results/gnuplot5.png";
	if ( -r $base_test_options->{"output file"} ) {
	    my $local_test_options;
	    %{$local_test_options} = %{$base_test_options};
	    $local_test_options->{"output file"} = undef; #force to stdout
	    open(OLDOUT, ">&STDOUT"); #mmm can't really die here ...
	    open(STDOUT, "> $test_filename")
		or $fail = "can't open STDOUT to file";
	    $fail = "gnuplot execution failed" unless (gnuplot($local_test_options,@base_test_data));
	    close(STDOUT);
	    open(STDOUT, ">&OLDOUT");
	    # compare files
	    {
		local $/; #file slurp mode
		open (ORIG, $base_test_options->{"output file"})
		    or $fail = "can't open test result";
		open (T5, $test_filename)
		    or $fail = "can't open test result '$test_filename'";
		my $t_orig = <ORIG>;
		my $t_test5 = <T5>;
		close ORIG;
		close T5;
		$fail = "print to stdout creates different output than print to file" unless ($t_orig eq $t_test5);
	    }
	    if ($fail) {
		print "not ok # redirect to stdout ($fail)\n";
	    } else {
		print "ok # redirect to stdout\n";
	    }
	} else {
	    print "not ok # can't read file created in gnuplot test 1\n";
	}
} else {
    print "ok # skip Not available on this platform\n";
}

#### 6
# test output to stdout for 'gif'
if ($test_gnuplot) {
    my $file_6a = "test_results/gnuplot6a.gif";
    my $file_6b = "test_results/gnuplot6b.gif";
    my $fail = undef;
    my $local_test_options;
    %{$local_test_options} = %{$base_test_options};
    $local_test_options->{"output file"} = $file_6a;
    $local_test_options->{"output type"} = "gif";

    # Test 6A
    $fail = "couldn't create 'gif' file" unless (gnuplot($local_test_options,@base_test_data));

    # now do the same  trick but to STDOUT 
    $local_test_options->{"output file"} = undef;
    open(OLDOUT, ">&STDOUT"); #mmm can't really die here ...
    open(STDOUT, "> $file_6b")
	or $fail = "can't open STDOUT to file";
    # Test 6B
    $fail = "gnuplot execution failed" unless (gnuplot($local_test_options,@base_test_data));
    close(STDOUT);
    open(STDOUT, ">&OLDOUT");
    # compare
    {
	local $/; #file slurp mode
	open (F6A, $file_6a)
	    or $fail = "can't open test result";
	open (F6B, $file_6b)
	    or $fail = "can't open test result '$file_6b'";
	my $t_6a = <F6A>;
	my $t_6b = <F6B>;
	close F6A;
	close F6B;
	$fail = "print to stdout creates different output than print to file" unless ($t_6a eq $t_6b);
    }

    if ($fail) {
	print "not ok # redirect to stdout for gif ($fail)\n";
    } else {
	print "ok # redirect to stdout for gif\n";
    }
    
} else {
    print "ok # skip Not available on this platform\n";
}


### 7 - 42 ( 35 tests)
# GLOBAL OPTION TESTING
###
sub unit_test_opts_to_stdout {
    my ($opts) = @_;
    my $data = [{'type' => 'matrix'},[ [0,10], [3,30] ] ];
    $opts->{'output file'} = undef;
    open (OLDOUT, '>&STDOUT');
    open (STDOUT, '>/dev/null');
    my $rv = undef;
    eval {
	$rv = gnuplot($opts, $data);
    };
    open (STDOUT, '>&OLDOUT');
    if ($@) {
	warn $@;
	return undef;
    } else {
	if ($rv) {
	    return 1;
	} else {
	    return undef;
	}
    }
}
my @opts = (
    'title' => 'some title',
    'output type' => 'pbm',
    'output type' => 'gif',
    'output type' => 'tgif',
#   'output type' => 'svg', #not supported for gnuplot < v4.0 p0
    'output type' => 'eps',
    'output type' => 'eps color "Arial" 18',
# output file already tested in previous tests
    'x-axis label' => 'some x-axis label',
    'y-axis label' => 'some y-axis label',
    'x2-axis label' => 'some x2-axis label',
    'y2-axis label' => 'some y2-axis label',
#  'logscale x' => 1,  # prints warnings, i'm ok with only testing logscale for y/x2/y2
    'logscale y' => 1,
    'logscale x2' => 1,
    'logscale y2' => 1,
    'xtics' => [ 10, 20, 30 ],
    'xtics' => [ ['x small',10], ['medium',20], ['large',30] ],
    'x2tics' => [ 10, 20, 30 ],
    'x2tics' => [ ['x2 small',10], ['medium',20], ['large',30] ],
    'ytics' => [ 10, 20, 30 ],
    'ytics' => [ ['y small',10], ['medium',20], ['large',30] ],
    'y2tics' => [ 10, 20, 30 ],
    'y2tics' => [ ['y2 small',10], ['medium',20], ['large',30] ],
#   'xdata' => 'time', #not sure why this fails, but tested already in previous tests
    'ydata' => 'time',
    'x2data' => 'time',
    'y2data' => 'time',
    'timefmt' => '%d%m%y%Y%j%H%M%S%b%B', #concat of all in doc table 1
    'format' =>  ['x','%f%e%E%g%G%x%X%o%O%t%l%s%T%L%S%c%P'], #concat of all in doc table 2
    'xrange' => '[0:100]',
    'xrange' => [0 , 100],
    'yrange' => '[0:100]',
    'yrange' => [0 , 100],
    'extra_opts' => "set key left top Left\nset border 10",
    'extra_opts' => ['set key left top Left', 'set border 10'],
    'uts' => [ 100000000, 1100000000 ],
    'size' => [ 2 , 2 ],
);

while (@opts) {
    my $key = shift @opts;
    my $val = shift @opts;
    my $test_string = "'$key' => ";
    if ( ref $val ) {
	$test_string .= ref($val);
    } else {
	$test_string .= "'$val'";
    }

    if ($test_gnuplot) {
	if ( unit_test_opts_to_stdout({$key => $val}) ) {
	    print "ok # option test $test_string\n";
	} else {
	    print "not ok # option test $test_string\n";
	}
    } else {
	print "ok # skip Not available on this platform\n";
    }
}

### 
# END GLOBAL OPTION TESTING
###

###
# DATA OPTION TESTING
#
sub unit_test_data_to_stdout {
    my ($data) = @_;
    my $opts = {'output file' => undef};
    open (OLDOUT, '>&STDOUT');
    open (STDOUT, '>/dev/null');
    my $rv = undef;
    eval {
	$rv = gnuplot($opts, $data);
    };
    open (STDOUT, '>&OLDOUT');
    if ($@) {
	warn $@;
	return undef;
    } else {
	if ( $rv) {
	    return 1;
	} else {
	    return undef;
	}
    }
}

my @data_tests =  (
    'type matrix' =>  [{ type => 'matrix'},   [ [0,0] , [1,1], [3,3] ]  ],
    'type columns' => [{ type => 'columns'},  [0,1,2,3,4] , [0,1,2,3,4] ],
    'type file' =>    [{ type => 'file'},     't/sample.gnuplot'], #assumes test run from root-dir ..
    'type function' =>[{ type => 'function'}, 'sin(x)'],
# use matrix for next few tests
    'set "title"'   =>             [{ type => 'matrix', title => 'my title'}, [ [0,0] , [1,1], [3,3] ]  ],
    'set "style" (impulses)'   =>  [{ type => 'matrix', style => 'impulses'}, [ [0,0] , [1,1], [3,3] ]  ],
    'set "axes" (impulses)'   =>   [{ type => 'matrix',  axes => 'x2y2'},      [ [0,0] , [1,1], [3,3] ]  ],
    'set "using"'   =>             [{ type => 'matrix',  using => '2:1'},      [ [0,0] , [1,1], [3,3] ]  ],
);
while (@data_tests) {
    my $testname = shift @data_tests;
    my $data = shift @data_tests;
    if ($test_gnuplot) {
	if ( unit_test_data_to_stdout($data) ) {
	    print "ok # data test '$testname'\n";
	} else {
	    print "not ok # data test '$testname'\n";
	}
    } else {
	print "ok # skip Not available on this platform\n";
    }
}
###
# END DATA OPTION TESTING
###
