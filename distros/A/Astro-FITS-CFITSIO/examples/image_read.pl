#!/usr/bin/perl

use strict;
use blib;

#
# Read FITS image, unpacking data into Perl array.
# Display image with PGPLOT
#

use Astro::FITS::CFITSIO;
use PGPLOT;
use Carp;

require "check_status.pl";

#
# open FITS file
#

my $file = @ARGV ? shift : 'm51.fits';
my $status = 0;
my $fptr = Astro::FITS::CFITSIO::open_file($file,Astro::FITS::CFITSIO::READONLY(),$status);
check_status($status) or die;

#
# read dimensions of image
#
my $naxes;
$fptr->get_img_parm(undef,undef,$naxes,$status);
my ($naxis1,$naxis2) = @$naxes;

#
# read image into $array, close file
#
print "Reading ${naxis2}x${naxis1} image...";
my ($array, $nullarray, $anynull);
$fptr->read_pixnull(Astro::FITS::CFITSIO::TLONG(), [1,1], $naxis1*$naxis2, $array, $nullarray, $anynull ,$status);
print "done\n";

$fptr->close_file($status);

check_status($status) or die;

#
# have a look
#
pgbeg(0,'/xs',1,1);
pgenv(0,$naxis2-1,0,$naxis1-1,0,0);
pgimag($array,$naxis1,$naxis2,1,$naxis1,1,$naxis2,0,400,[0,1,0,0,0,1]);
pgend();

exit;
