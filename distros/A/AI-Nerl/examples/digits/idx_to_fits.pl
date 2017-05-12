#!/usr/bin/perl

use Modern::Perl;
use PDL;
use PDL::NiceSlice;
use File::Slurp;
use PDL::IO::FITS;

use FindBin qw($Bin); 
chdir $Bin;

die 'filename' unless $ARGV[0];
my $img_filename = $ARGV[0];
my $img_data = read_file( $img_filename, binmode => ':raw' ) ;

my @header = map {ord}  split ('', substr ($img_data, 0, 4, ''));
my $numdims = $header[3];
my @dims = map {ord} split ('',substr($img_data, 0, 4*$numdims, ''));

#'IDX' format described here: http://yann.lecun.com/exdb/mnist/
for (0..$numdims-1){
   $dims[$_] = 256*$dims[4*$_+2] + $dims[4*$_+3];
}
@dims=@dims[0..$numdims-1];
#die join ' ',@dims;
#my @img_data = map{ord}split('',$img_data);
my $img_pdl = pdl(unpack('C*',$img_data));

use PDL::Graphics2D;

if(!defined($dims[1])){
   $img_pdl = $img_pdl->squeeze;
}
elsif ($dims[1]==28){ #images
   @dims = (28**2,$dims[0]);
   $img_pdl = $img_pdl->reshape(@dims)->transpose();
   #imag2d($img_pdl(3000)->reshape(28,28)/256);
}
say "out: " . join ',',$img_pdl->dims;

$img_pdl->wfits($img_filename . '.fits');

