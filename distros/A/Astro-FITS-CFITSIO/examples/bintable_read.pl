#!/usr/bin/perl

use strict;
use blib;

use Astro::FITS::CFITSIO qw( :constants );
use PDL;
use PDL::Graphics::PGPLOT;
use Carp;

require "check_status.pl";
require "match_datatype.pl";

Astro::FITS::CFITSIO::PerlyUnpacking(0);

my ($fptr,$file,$status,$ycol,$i,$nrows,$pdl);

$file = @ARGV ? shift : 'bintable.fits';

#
# open file, move to proper HDU
#
$fptr = Astro::FITS::CFITSIO::open_file($file,READONLY,$status);
check_status($status) or die;
$fptr->movnam_hdu(ANY_HDU,'EVENTS',0,$status);

#
# get number of rows in table
#
$fptr->get_num_rows($nrows,$status);

#
# find out which column the Y event coordinates are stored in
#
$fptr->get_colnum(0,'Y',$ycol,$status);
($status == COL_NOT_FOUND) and
    die "$0: could not find TTYPE 'Y' in binary table";

#
# make piddle, read data
#
$pdl = zeroes($nrows)->long;
$fptr->read_col(match_datatype(long),$ycol,1,1,$nrows,0,${$pdl->get_dataref},undef,$status);
$pdl->upd_data;

$fptr->close_file($status);
check_status($status) or die;

#
# create Y position histogram, plot data
#
my $hist = $pdl->hist($pdl->min,$pdl->max,1.0);
my $y = $hist->sequence + $pdl->min;
line $y, $hist;
