## xrt3d.t is a test script for the graphing package Graph.pm
##
## $Id: xrt3d.t,v 1.9 2001/10/24 18:57:20 elagache Exp $ $name$
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
$Chart::Graph::xrt = $t::Config::xrt3d;
$Chart::Graph::xvfb = $t::Config::xvfb;

# assign $PNAME to the actual program name
# $script_path is the path to the directory the script is in
use vars qw($script_name $script_path $script_suffix $PNAME);

($script_name, $script_path, $script_suffix) = fileparse($0, ".pl");
$PNAME = "$script_name$script_suffix";

#
#
# test script for the xrt3d package
#
#
print "1..4\n";

my @drivers = @t::Config::drivers;
my $test_xrt3d = 0;

for (@drivers) {
   if ($_ eq "xrt3d") {
	$test_xrt3d = 1;
    }
}

if ($test_xrt3d) {
    if (
xrt3d({"output file" => "test_results/xrt3d-1.jpg",
			"output type" => "jpg",
			"header" => 
			   ["Stock prices for Joe's restaurant chain",
				"Compiled from local records"
			   ],
			   "footer" =>
			   ["Joe's Restaurant"],
			   "y-ticks"=>["Jan/Feb", "Mar/Apr", "May/Jun", "Jul/Aug",
						   "Sep/Oct", "Nov/Dec"],
			   "x-axis title" => "Years monitored",
			   "y-axis title" => "Month's tracked",
			   "z-axis title" => "Stock prices",
			  },
			  [{"type" => "matrix"},
               ["4", "5", "3", "6", "6", "5"],
			   ["8", "13", "20", "45", "100", "110" ],
			   ["70", "45", "10", "5", "4", "3"]])
) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}

if ($test_xrt3d) {
    if (xrt3d({"output file" => "test_results/xrt3d-2.png",
               "output type" => "png",
			   "header" => 
			   ["Growth of Early Internet", 
				"(according to Internet Wizards - http://www.nw.com/)",
			   ],
			   "footer" =>
			   ["http://www.mit.edu/people/mkgray/net/internet-growth-raw-data.html"],
			   "y-ticks"=>["Jan 93", "Apr 93", "Jul 93",
						   "Oct 93", "Jan 94", "Jul 94",
						   "Oct 94", "Jan 95", "Jul 95",
						   "Jan 96"
						  ],
			   "x-ticks"=>["Hosts", "Domains", "Replied to Ping"],},
	    [{"type" => "matrix"},
	      ["1.3e6", "1.5e6", "1.8e6", "2.1e6", "2.2e6", "3.2e6", 
			"3.9e6","4.9e6", "6.6e6", "9.5e6"
		   ],
	       ["21000","22000", "26000", "28000", "30000", "46000", 
			"56000", "71000", "120000", "240000"
		   ],
	       ["NA", "0.4e6", "NA", "0.5e6", "0.6e6", "0.7e6", 
			"1.0e6", "1.0e6", "1.1e6", "1.7e6" 
		   ]
		  ])) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}


# Date Hosts Domains Replied to Ping 
# Jan 96 9.5 million 240,000 1.7 million 
# Jul 95 6.6 million 120,000 1.1 million 
# Jan 95 4.9 million 71,000 1.0 million 
# Oct 94 3.9 million 56,000 1.0 million 
# Jul 94 3.2 million 46,000 0.7 million 
# Jan 94 2.2 million 30,000 0.6 million 
# Oct 93 2.1 million 28,000 NA 
# Jul 93 1.8 million 26,000 0.5 million 
# Apr 93 1.5 million 22,000 0.4 million 
# Jan 93 1.3 million 21,000 NA

# http://www.mit.edu/people/mkgray/net/internet-growth-raw-data.html

if ($test_xrt3d) {
    if (xrt3d({"output file" => "test_results/xrt3d-3.gif",
               "output type" => "gif",
           "x-ticks"=>["a", "b", "c"],
	       "y-ticks"=>["w", "x", "y", "z"],},
	    [{"type" => "file"},
		 "xrt3d_data.txt"])) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}


if ($test_xrt3d) {
    if (xrt3d({"output file" => "test_results/xrt3d-4.gif",
               "output type" => "gif",
		"x-ticks"=>["a", "b", "c"],
	       "y-ticks"=>["w", "x", "y", "z"],},
	    [{"type" => "matrix"},
		["10", "15", "23", "10"],
	       ["4", "13", "35", "45"],
	       ["29", "15", "64", "24"]])) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}

