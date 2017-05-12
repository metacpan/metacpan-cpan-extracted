#!/usr/local/bin/perl -w
## gnuplot.t is a test script for the graphing package Graph.pm
##
## $Id: xmgrace.t,v 1.11 2001/10/24 18:41:09 elagache Exp $ $name$
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
use Chart::Graph qw(xmgrace);
use strict;
use File::Basename;

$Chart::Graph::save_tmpfiles = 0;
$Chart::Graph::debug = 0;

# assign $PNAME to the actual program name
# $script_path is the path to the directory the script is in
use vars qw($script_name $script_path $script_suffix $PNAME);

($script_name, $script_path, $script_suffix) = fileparse($0, ".pl");
$PNAME = "$script_name$script_suffix";

use vars qw($package);


#
#
# test script for the gnuplot package
#
#
print "1..3\n";

my @drivers = @t::Config::drivers;
my $test_xmgrace = 0;

for (@drivers) {
   if ($_ eq "xmgrace") {
	$test_xmgrace = 1;
    }
}

if ($test_xmgrace) {
    if (xmgrace( { "title" => "Example of a XY Chart",
             "subtitle" =>"optional subtitle",
             "type of graph" => "XY chart",
             "output type" => "png",
             "output file" => "test_results/xmgrace1.png",
             "x-axis label" => "my x-axis label",
             "y-axis label" => "my y-axis label",
             "logscale y" => "1",
             "xtics" => [ ["one", "1"], ["two", "2"], ["three", "3"] ],
             "ytics" => [ ["one", "1"], ["two", "2"], ["three", "3"] ],
             "grace output file" => "test_results/xmgrace1.agr",
           },

           [ { "title" => "XY presentation data1",
               "set presentation" => "XY",
               "options" => {
                           "line" => {
                                      "type" => "1",
                                      "color" => "8",
                                      "linewidth" => "1",
                                      "linestyle" => "3",
                                     },
                           "symbol" => {
                                        "symbol type" => "6",
                                        "color" => "1",
                                        "fill pattern" => "1",
                                        "fill color" => "1",
                                       },
                           "fill" => {
                                      "type" => "0",
                                     },
                          },
               "data format" => "matrix",
             },

             [ [1,2],
               [2,4],
               [3,6],
               [4,8],
               [5,10],
               [6,12],
               [7,14],
               [8,16],
               [9,18],
               [10,20] ]
           ],

           [ { "title" => "XY presentation data2",
               "options" => {
                           "line" => {
                                      "type" => "2",
                                      "color" => "4",
                                     },
                           "symbol" => {
                                        "symbol type" => "1",
                                        "color" => "1",
                                        "fill pattern" => "3",
                                        "fill color" => "5",
                                       },
                           "fill" => {
                                      "type" => "0",
                                     }
                          },
               "data format" => "columns",
             },
	     [
              [1,2,3,4,5,6,7,8,9,10],
              [3,6,9,12,15,18,21,24,27,30],
	     ]  
           ],

           [ { "title" => "BAR presentation data3",
               "set presentation" => "BAR",
               "data format" => "file"}, "sample"],

       )
) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}

# Second test case.
if ($test_xmgrace) {
    if (
  xmgrace({"title" => "Example of a XY Graph",
           "subtitle" => "optional subtitle",
           "type of graph" => "XY graph",
           "output type" => "png",
           "output file" => "test_results/xmgrace2.png",
	   "grace output file" => "test_results/xmgrace2.agr",	
           "x-axis label" => "my x-axis label",
           "y-axis label" => "my y-axis label"
	  },
	  [{"title" => "data",
	    "options" => {
                          "fill" => { "type" => "2" },
			 },
            "data format" => "file"
	   }, 
	   "sample"
	  ],
	 )

       ) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}
# Third test case.
if ($test_xmgrace) {
    if (
	xmgrace({'y-axis label' => 'Percent of widgets',
		 'output file' => 'test_results/xmgrace3.png',
		 'type of graph' => 'Bar chart',
		 'output type' => 'png',
		 'title' => 'Percent of widgets',
		 'grace output file' => 'test_results/xmgrace3.agr',
		 'subtitle' => 'Data collected from 07/24/2001 to 08/01/2001',
		 'x-axis label' => 'Date of data sampling'
		},
		[{'data format' => 'matrix',
		  'title' => 'Widget A'
		 },
		 [
		  [ '2001-07-24',  '32.58' ],
		  [ '2001-07-25',  '30.4291287386216'  ],
		  [ '2001-07-26',  '34.4106463878327'  ],
		  [ '2001-07-27',  '34.44'	  ],
		  [ '2001-07-28',  '37.4482270936458' ],
		  [ '2001-07-29',  '37.8769479862376'  ],
		  [ '2001-07-30',  '34.9437860832574'  ],
		  [ '2001-07-31',  '36.0707388962293'  ],
		  [ '2001-08-01',  '40.0591353996737'  ]
		 ]
		],
		[{'data format' => 'matrix',
		  'title' => 'Widget B'
		 },
		 [
		  [ '2001-07-24',  '29.13'  ],
		  [ '2001-07-25',  '30.8192457737321'  ],
		  [ '2001-07-26',  '29.1775065039023'  ],
		  [ '2001-07-27',  '29.82'             ],
		  [ '2001-07-28',  '28.9221133447823'  ],
		  [ '2001-07-29',  '28.5772110908723'  ],
		  [ '2001-07-30',  '29.2109794388737'  ],
		  [ '2001-07-31',  '26.8624860250025'  ],
		  [ '2001-08-01',  '8.442088091354'    ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget C'
		 },
		 [
		  [ '2001-07-24', '15.42'        ],
		  [ '2001-07-25', '17.2251675502651' ],
		  [ '2001-07-26', '15.6093656193716' ],
		  [ '2001-07-27', '16.02'            ],
		  [ '2001-07-28', '14.526719870694'  ],
		  [ '2001-07-29', '15.1791135397693' ],
		  [ '2001-07-30', '16.8337891218475' ],
		  [ '2001-07-31', '16.3227970322187' ],
		  [ '2001-08-01', '17.7304241435563' ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget D'
		 },
		 [
		  [ '2001-07-24', '7.61'  ],
		  [ '2001-07-25', '7.80234070221066' ],
		  [ '2001-07-26', '7.82469481689013' ],
		  [ '2001-07-27', '7.57'            ],
		  [ '2001-07-28', '7.72805333872108'  ],
		  [ '2001-07-29', '7.34669095324833' ],
		  [ '2001-07-30', '7.95097741314697' ],
		  [ '2001-07-31', '10.7226344140665'  ],
		  [ '2001-08-01', '12.9282218597064'  ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget E'
		 },
		 [
		  [  '2001-07-24', '10.75'  ],
		  [  '2001-07-25', '9.53285985795739'  ],
		  [  '2001-07-26', '8.375025015009'    ],
		  [  '2001-07-27', '7.79'           ],
		  [  '2001-07-28', '6.32387109809072'  ],
		  [  '2001-07-29', '6.90143695608177'  ],
		  [  '2001-07-30', '6.26962422769169'  ],
		  [  '2001-07-31', '5.43754446590101'  ],
		  [  '2001-08-01', '14.8960032626427'  ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget F'
		 },
		 [
		  [  '2001-07-24', '3.16'         ],
		  [  '2001-07-25', '2.68080424127238'   ],
		  [  '2001-07-26', '3.08184910946568'   ],
		  [  '2001-07-27', '2.85'           ],
		  [  '2001-07-28', '2.78816042024447'  ],
		  [  '2001-07-29', '2.6006881198138'   ],
		  [  '2001-07-30', '3.0892332624329'   ],
		  [  '2001-07-31', '3.02876308567944'  ],
		  [  '2001-08-01', '3.02814029363785'  ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget G'
		 },
		 [
		  [ '2001-07-24',  '1.14'      ],
		  [ '2001-07-25',  '1.28038411523457'  ],
		  [ '2001-07-26',  '1.26075645387232'  ],
		  [ '2001-07-27',  '1.33'              ],
		  [ '2001-07-28',  '2.09112031518335'  ],
		  [ '2001-07-29',  '1.27504553734062'  ],
		  [ '2001-07-30',  '1.43826597791958'  ],
		  [ '2001-07-31',  '1.31110885252566'  ],
		  [ '2001-08-01',  '2.76305057096248'  ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget H'
		 },
		 [
		  [ '2001-07-24', '0.09'	  ],
		  [ '2001-07-25', '0.110033009902971'  ],
		  [ '2001-07-26', '0.150090054032419'  ],
		  [ '2001-07-27', '0.07'             ],
		  [ '2001-07-28', '0.111122335589453' ],
		  [ '2001-07-29', '0.121432908318154' ],
		  [ '2001-07-30', '0.121543603767852' ],
		  [ '2001-07-31', '0.111799979672731' ],
		  [ '2001-08-01', '0.0815660685154976']
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget I'
		 },
		 [
		  [  '2001-07-24', '0.04'  ],
		  [  '2001-07-25', '0.0500150045013504'  ],
		  [  '2001-07-26', '0.0500300180108065'  ],
		  [  '2001-07-27', '0.02'             ],
		  [  '2001-07-28', '0.0303060915243964' ],
		  [  '2001-07-29', '0.0607164541590771'  ],
		  [  '2001-07-30', '0.0709004355312468'  ],
		  [  '2001-07-31', '0.0203272690314056'  ],
		  [  '2001-08-01', '0.0101957585644372'  ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget J'
		 },
		 [
		  [ '2001-07-24', '0.03'  ],
		  [ '2001-07-25', '0.0600180054016205'  ],
		  [ '2001-07-26', '0.0400240144086452'  ],
		  [ '2001-07-27', '0.08' ],
		  [ '2001-07-28', '0.0202040610162643'   ],
		  [ '2001-07-29', '0.0303582270795386'   ],
		  [ '2001-07-30', '0.0607718018839259'   ],
		  [ '2001-07-31', '0.0609818070942169'   ],
		  [ '2001-08-01', '0.0203915171288744'   ]
		 ]
		],
		[
		 {
		  'data format' => 'matrix',
		  'title' => 'Widget K'
		 },
		 [
		  [ '2001-07-24', '0.05' ],
		  [ '2001-07-25','0.0100030009002701' ],
		  [ '2001-07-26','0.0200120072043226' ],
		  [ '2001-07-27', '0.01'             ],
		  [ '2001-07-28','0.0101020305081321' ],
		  [ '2001-07-29', '0.0303582270795386' ],
		  [ '2001-07-30',  '0.010128633647321'  ],
		  [ '2001-07-31',  '0.0508181725785141' ],
		  [ '2001-08-01',  '0.0407830342577488' ]
		 ]
		]
	       ) # xmgrace call
       ) # if xmgrace call is successful



 {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}
