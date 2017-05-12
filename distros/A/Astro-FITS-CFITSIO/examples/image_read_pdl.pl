#!/usr/bin/perl

use strict;
use blib;

#
# Read FITS image, unpacking data into scalar. Make a piddle and
# display the image.
#

use Astro::FITS::CFITSIO;
use PDL;
use PDL::Graphics::PGPLOT;
use Carp;

require "check_status.pl";
require "match_datatype.pl";

my $status = 0;

#
# open file
#
my $file = @ARGV ? shift : 'm51.fits';
my $fptr = Astro::FITS::CFITSIO::open_file($file, Astro::FITS::CFITSIO::READONLY(), $status);
check_status($status) or die;

#
# read dimensions of image and data storage type
#
my ($naxes, $bitpix);
$fptr->get_img_parm($bitpix,undef,$naxes,$status);
my ($naxis1,$naxis2) = @$naxes;

my %read_funcs = (
		Astro::FITS::CFITSIO::TBYTE()   => \&Astro::FITS::CFITSIO::fits_read_2d_byt,
		Astro::FITS::CFITSIO::TSHORT()  => \&Astro::FITS::CFITSIO::fits_read_2d_sht,
		Astro::FITS::CFITSIO::TUSHORT() => \&Astro::FITS::CFITSIO::fits_read_2d_usht,
		Astro::FITS::CFITSIO::TINT()    => \&Astro::FITS::CFITSIO::fits_read_2d_int,
		Astro::FITS::CFITSIO::TUINT()   => \&Astro::FITS::CFITSIO::fits_read_2d_uint,
		Astro::FITS::CFITSIO::TLONG()   => \&Astro::FITS::CFITSIO::fits_read_2d_lng,
		Astro::FITS::CFITSIO::TULONG()  => \&Astro::FITS::CFITSIO::fits_read_2d_ulng,
		Astro::FITS::CFITSIO::TFLOAT()  => \&Astro::FITS::CFITSIO::fits_read_2d_flt,
		Astro::FITS::CFITSIO::TDOUBLE() => \&Astro::FITS::CFITSIO::fits_read_2d_dbl,
);

#
# This does not take into account BSCALE and BZERO
#
my %pdl_funcs = (
		 '8'   => { 'pdl' => \&byte, },
		 '16'  => { 'pdl' => \&short, },
		 '32'  => { 'pdl' => \&long, },
		 '-32' => { 'pdl' => \&float, },
		 '-64' => { 'pdl' => \&double, },
);

exists $pdl_funcs{$bitpix} or
    $fptr->close_file($status),
    croak "unhandled BITPIX = $bitpix";

my $cfitsio_datatype = match_datatype(&{$pdl_funcs{$bitpix}{pdl}});
exists $read_funcs{$cfitsio_datatype} or 
    croak "unhandled CFITSIO datatype = $cfitsio_datatype";

print STDERR "Reading ${naxis2}x${naxis1} image...";

Astro::FITS::CFITSIO::PerlyUnpacking(0);
my $pdl = $pdl_funcs{$bitpix}{'pdl'}->(zeroes($naxis1,$naxis2));
my $nullarray = byte(zeroes($naxis1,$naxis2));
$fptr->read_pixnull($cfitsio_datatype, [1,1], $pdl->nelem, ${$pdl->get_dataref},${$nullarray->get_dataref},undef,$status);
Astro::FITS::CFITSIO::PerlyUnpacking(1);

print STDERR "done\n";

$pdl->upd_data;
$fptr->close_file($status);

check_status($status) or die;


#
# have a look
#
imag $pdl;
