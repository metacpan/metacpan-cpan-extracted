#!/usr/local/bin/perl -w
## xrt2d.t is a test script for the graphing package Graph.pm
##
## $Id: xrt2d.t,v 1.9 2001/10/24 18:41:09 elagache Exp $ $name$
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
use lib ".";
use Chart::Graph qw(xrt2d);
use strict;
use File::Basename;

$Chart::Graph::save_tmpfiles = 0;
$Chart::Graph::debug = 0; 
$Chart::Graph::xrt = $t::Config::xrt2d;
$Chart::Graph::xvfb = $t::Config::xvfb;
$Chart::Graph::Xrt2d::xvfb = $t::Config::xvfb;
$Chart::Graph::Xrt2d::xrt = $t::Config::xrt2d;

# assign $PNAME to the actual program name
# $script_path is the path to the directory the script is in
use vars qw($script_name $script_path $script_suffix $PNAME);

($script_name, $script_path, $script_suffix) = fileparse($0, ".pl");
$PNAME = "$script_name$script_suffix";

#
#
# test script for the xrt2d package
#
#
print "1..2\n";

my @drivers = @t::Config::drivers;
my $test_xrt2d = 0;

for (@drivers) {
   if ($_ eq "xrt2d") {
	$test_xrt2d = 1;
    }
}

if ($test_xrt2d) {
if ( xrt2d({"output file" => "test_results/xrt2d-1.jpg",
        	"output type" => "jpg",
        "set labels"=> ["Joe's", "Ralph's"],
			"invert" => 1,
			"point labels" => ["Jan/Feb", "Mar/Apr", "May/Jun", "Jul/Aug",
                         "Sep/Oct", "Nov/Dec"],
        "x-axis title" => "Month's tracked",
        "y-axis title" => "Stock prices for Rival restaurant chains"
       },
       [{"color" => "MistyRose"}, ["8", "13", "20", "45", "50", "100"]],
 	   [{"color" => "#000000"},   ["75", "50", "25", "25", "50", "75"]]
       )
   ) {
    print "ok\n";
} else {
    print "not ok\n";
}
} else {
    print "ok # skip Not available on this platform\n";
}


if ($test_xrt2d) {
if ( xrt2d({"output file" => "test_results/xrt2d-2.gif",
			 "output type" => "gif",
		"set labels" => ["set1", "set2", "set3", "set4"],
		"point labels" => ["point1", "point2", "point3"]},
                # Each entry here corresponds to a set
		[{"color" => "MistyRose"}, ["15", "23", "10"]],
		[{"color" => "#0000FF"}, ["13", "35", "45"]],
		[{"color" => "#00FF00"}, ["15", "64", "24"]],
		[{"color" => "Navy"}, ["18", "48", "32"]],
      )
   ) {
    print "ok\n";
} else {
    print "not ok\n";
}
} else {
    print "ok # skip Not available on this platform\n";
}



