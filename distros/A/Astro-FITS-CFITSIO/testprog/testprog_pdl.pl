#!/usr/bin/perl
use strict;

use blib;
use Astro::FITS::CFITSIO qw( :longnames :constants );
use PDL;
use PDL::Core qw( howbig ); # for building the type translation table

Astro::FITS::CFITSIO::PerlyUnpacking(0);

my %types = type_table();

# bug in PDL (error with pdl(longlong, [1,2,3]) even though all other
# types are fine with this sytax) forces us to use a workaround
# whereby we first copy the hash elements to scalar and then use those
# scalars as methods

my $tbyte = $types{TBYTE()};
my $tshort = $types{TSHORT()};
my $tint = $types{TINT()};
my $tlong = $types{TLONG()};

my $oskey='value_string';
my $olkey=1;
my $ojkey=11;
my $otint = 12345678;
my $ofkey = 12.121212;
my $oekey = 13.131313;
my $ogkey = 14.1414141414141414;
my $odkey = 15.1515151515151515;
my $otfrac = 0.1234567890123456;
my $xcoordtype = 'RA---TAN';
my $ycoordtype = 'DEC--TAN';
my $onskey = [ 'first string', 'second string', '        ' ];
my $inclist = [ 'key*', 'newikys' ];
my $exclist = [ 'key_pr*', 'key_pkls' ];
my $onlkey = pdl([1,0,1])->$tint; # fits_write_key_log expects int
my $onjkey = pdl([11,12,13])->$tlong;
my $onfkey = float [12.121212, 13.131313, 14.141414];
my $onekey = float [13.131313, 14.141414, 15.151515];
my $ongkey = double [14.1414141414141414, 15.1515151515151515,16.1616161616161616];
my $ondkey = double [15.1515151515151515, 16.1616161616161616,17.1717171717171717];
my $tbcol = pdl([1,17,28,43,56])->$tlong;
my $binname = "Test-BINTABLE";
my $template = "testprog.tpt";
my $tblname = "Test-ASCII";
my ($status,$tmp,$tmp1,$tmp2,@tmp);
my ($ttype,$tunit,$tdisp,$tform,$nrows,$tfields,$morekeys,$extvers,$koutarray);
my ($colnum,$colname,$typecode,$repeat,$width,$scale,$zero,$jnulval,$hdutype);
my ($rowlen,$errmsg,$nmsg,$cval,$oshtkey);

my ($version,$fptr,$tmpfptr);
my ($filename,$filemode);
my ($simple,$bitpix,$naxis,$naxes,$npixels,$pcount,$gcount,$extend);
my ($card,$card2,$comment,$comm);
my ($nkeys);
my ($boutarray,$ioutarray,$joutarray,$eoutarray,$doutarray);
my ($hdunum,$anynull);
my ($binarray,$iinarray,$jinarray,$einarray,$dinarray);
my ($ii,$jj,$larray,$larray2,$imgarray,$imgarray2);
my ($keyword,$value);
my ($iskey,$ilkey,$ijkey,$iekey,$idkey,$ishtkey,$inekey,$indkey);
my $lsptr;
my ($existkeys,$keynum);
my ($inskey,$nfound,$inlkey,$injkey);
my ($signval,$uchars,$nulstr);
my ($xinarray,$kinarray,$cinarray,$minarray);
my ($lpixels,$fpixels,$inc,$offset);
my ($bnul,$inul,$knul,$jnul,$enul,$dnul);
my ($xrval,$yrval,$xrpix,$yrpix,$xinc,$yinc,$rot,$ctype,$xpix,$ypix,$xpos,$ypos);
my ($checksum,$asciisum,$datsum,$datastatus,$hdustatus);

fits_get_version($version);

printf "CFITSIO TESTPROG, v%.3f\n\n",$version;

print "Try opening then closing a nonexistent file:\n";
$status=0;
$fptr=Astro::FITS::CFITSIO::open_file('tq123x.kjl',READWRITE,$status);
printf "  ffopen fptr, status  = %d %d (expect an error)\n",$fptr,$status;
eval {
	$status = 115; # cheat!!!
	$fptr->close_file($status);
};
printf "  ffclos status = %d\n\n", $status;
fits_clear_errmsg();

$status=0;
$fptr=Astro::FITS::CFITSIO::create_file('!testprog.fit',$status);
print "ffinit create new file status = $status\n";
$status and goto ERRSTATUS;

$fptr->file_name($filename,$status);
$fptr->file_mode($filemode,$status);
print "Name of file = $filename, I/O mode = $filemode\n";
$simple=1;
$bitpix=32;
$naxis=2;
$naxes=[10,2];
$npixels=20;
$pcount=0;
$gcount=1;
$extend=1;

############################
#  write single keywords   #
############################

$fptr->write_imghdr($bitpix,$naxis,$naxes,$status) and
	print "ffphps status = $status";

$fptr->write_record(
	"key_prec= 'This keyword was written by fxprec' / comment goes here",
	$status
) and printf"ffprec status = $status\n";

print "\ntest writing of long string keywords:\n";
$card =
	"1234567890123456789012345678901234567890" .
	"12345678901234567890123456789012345";
$fptr->write_key_str("card1",$card,"",$status);
$fptr->read_keyword('card1',$card2,$comment,$status);
print " $card\n$card2\n";

$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234'6789012345";
$fptr->write_key_str('card2',$card,"",$status);
$fptr->read_keyword('card2',$card2,$comment,$status);
print " $card\n$card2\n";

$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234''789012345";
$fptr->write_key_str('card3',$card,"",$status);
$fptr->read_keyword('card3',$card2,$comment,$status);
print " $card\n$card2\n";

$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234567'9012345";
$fptr->write_key_str('card4',$card,"",$status);
$fptr->read_keyword('card4',$card2,$comment,$status);
print " $card\n$card2\n";


$fptr->write_key_str('key_pkys',$oskey,'fxpkys comment',$status)
	and print "ffpkys status = $status\n";
$fptr->write_key_log('key_pkyl',$olkey,'fxpkyl comment',$status)
	and print "ffpkyl status = $status\n";
$fptr->write_key_lng('key_pkyj',$ojkey,'fxpkyj comment',$status)
	and print "ffpkyj status = $status\n";
$fptr->write_key_fixflt('key_pkyf',$ofkey,5,'fxpkyf comment',$status)
	and print "ffpkyf status = $status\n";
$fptr->write_key_flt('key_pkye',$oekey,6,'fxpkye comment',$status)
	and print "ffpkye status = $status\n";
$fptr->write_key_fixdbl('key_pkyg',$ogkey,14,'fxpkyg comment',$status)
	and print "ffpkyg status = $status\n";
$fptr->write_key_dbl('key_pkyd',$odkey,14,'fxpkyd comment',$status)
	and print "ffpkyd status = $status\n";
$fptr->write_key_cmp('key_pkyc',$onekey->get_dataref,6,'fxpkyc comment',$status)
	and print "ffpkyc status = $status\n";
$fptr->write_key_dblcmp('key_pkym',$ondkey->get_dataref,14,'fxpkym comment',$status)
	and print "ffpkym status = $status\n";
$fptr->write_key_fixcmp('key_pkfc',$onekey->get_dataref,6,'fxpkfc comment',$status)
	and print "ffpkfc status = $status\n";
$fptr->write_key_fixdblcmp('key_pkfm',$ondkey->get_dataref,14,'fxpkfm comment',$status)
	and print "ffpkfm status = $status\n";
$fptr->write_key_longstr(
	'key_pkls',
	'This is a very long string value that is continued over more than one keyword.',
	'fxpkls comment',
	$status,
) and print "ffpkls status = $status\n";
$fptr->write_key_longwarn($status)
	and print "ffplsw status = $status\n";
$fptr->write_key_triple('key_pkyt',$otint,$otfrac,'fxpkyt comment',$status)
	and print "ffpkyt status = $status\n";
$fptr->write_comment('  This keyword was written by fxpcom.',$status)
	and print "ffpcom status = $status\n";
$fptr->write_history("  This keyword written by fxphis (w/ 2 leading spaces).",$status)
	and print "ffphis status = $status\n";
$fptr->write_date($status) and print "ffpdat status = $status\n, goto ERRSTATUS";

############################
# write arrays of keywords #
############################
$nkeys = 3;

$fptr->write_keys_str('ky_pkns',1,$nkeys,$onskey,'fxpkns comment&',$status)
	and print "ffpkns status = $status\n";
$fptr->write_keys_log('ky_pknl',1,$nkeys,$onlkey->get_dataref,'fxpknl comment&',$status)
	and print "ffpknl status = $status\n";
$fptr->write_keys_lng('ky_pknj',1,$nkeys,$onjkey->get_dataref,'fxpknj comment&',$status)
	and print "ffpknj status = $status\n";
$fptr->write_keys_fixflt('ky_pknf',1,$nkeys,$onfkey->get_dataref,5,'fxpknf comment&',$status)
	and print "ffpknf status = $status\n";
$fptr->write_keys_flt('ky_pkne',1,$nkeys,$onekey->get_dataref,6,'fxpkne comment&',$status)
	and print "ffpkne status = $status\n";
$fptr->write_keys_fixdbl('ky_pkng',1,$nkeys,$ongkey->get_dataref,13,'fxpkng comment&',$status)
	and print "ffpkng status = $status\n";
$fptr->write_keys_dbl('ky_pknd',1,$nkeys,$ondkey->get_dataref,14,'fxpknd comment&',$status)
	and print "ffpknd status = $status\n",goto ERRSTATUS;

############################
#  write generic keywords  #
############################
$oskey = 1;
$fptr->write_key(TSTRING,'tstring',$oskey,'tstring comment',$status)
	and print "ffpky status = $status\n";
$olkey = TLOGICAL;
$fptr->write_key(TLOGICAL,'tlogical',$olkey,'tlogical comment',$status)
	and print "ffpky status = $status\n";
$cval = TBYTE;
$fptr->write_key(TBYTE,'tbyte',$cval,'tbyte comment',$status)
	and print "ffpky status = $status\n";
$oshtkey = TSHORT;
$fptr->write_key(TSHORT,'tshort',$oshtkey,'tshort comment',$status)
	and print "ffpky status = $status\n";
$olkey = TINT;
$fptr->write_key(TINT,'tint',$olkey,'tint comment',$status)
	and print "ffpky status = $status\n";
$ojkey = TLONG;
$fptr->write_key(TLONG,'tlong',$ojkey,'tlong comment',$status)
	and print "ffpky status = $status\n";
$oekey = TFLOAT;
$fptr->write_key(TFLOAT,'tfloat',$oekey,'tfloat comment',$status)
	and print "ffpky status = $status\n";
$odkey = TDOUBLE;
$fptr->write_key(TDOUBLE,'tdouble',$odkey,'tdouble comment',$status)
	and print "ffpky status = $status\n";


############################
#  write data              #
############################

$fptr->write_key_lng('BLANK',-99,'value to use for undefined pixels',$status)
	and print "BLANK keyword status = $status\n";

$boutarray = sequence($types{TBYTE()}, $npixels+1)+1;
$ioutarray = sequence($types{TSHORT()}, $npixels+1)+1;
$koutarray = sequence($types{TINT()}, $npixels+1)+1;
$joutarray = sequence($types{TLONG()}, $npixels+1)+1;
$eoutarray = sequence(float, $npixels+1)+1;
$doutarray = sequence(double, $npixels+1)+1;

$fptr->write_img_byt(1,1,2,$boutarray->slice('0:1')->get_dataref,$status);
$fptr->write_img_sht(1,5,2,$ioutarray->slice('4:5')->get_dataref,$status);
$fptr->write_img_lng(1,9,2,$joutarray->slice('8:9')->get_dataref,$status);
$fptr->write_img_flt(1,13,2,$eoutarray->slice('12:13')->get_dataref,$status);
$fptr->write_img_dbl(1,17,2,$doutarray->slice('16:17')->get_dataref,$status);
$fptr->write_imgnull_byt(1,3,2,$boutarray->slice('2:3')->get_dataref,4,$status);
$fptr->write_imgnull_sht(1,7,2,$ioutarray->slice('6:7')->get_dataref,8,$status);
$fptr->write_imgnull_lng(1,11,2,$joutarray->slice('10:11')->get_dataref,12,$status);
$fptr->write_imgnull_flt(1,15,2,$eoutarray->slice('14:15')->get_dataref,16,$status);
$fptr->write_imgnull_dbl(1,19,2,$doutarray->slice('18:19')->get_dataref,20,$status);
$fptr->write_img_null(1,1,1,$status);
$status and  print "ffppnx status = $status\n", goto ERRSTATUS;

$fptr->flush_file($status);
print "ffflus status = $status\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

############################
#  read data               #
############################
print "\nValues read back from primary array (99 = null pixel)\n";
print "The 1st, and every 4th pixel should be undefined:\n";

$anynull = 0;
$binarray = zeroes($types{TBYTE()}, $npixels);
$fptr->read_img_byt(1,1,$npixels,99,${$binarray->get_dataref},$anynull,$status);
map printf(" %2d",$binarray->at($_)),(0..$npixels-1);
print "  $anynull (ffgpvb)\n";

$iinarray = zeroes($types{TSHORT()}, $npixels);
$fptr->read_img_sht(1,1,$npixels,99,${$iinarray->get_dataref},$anynull,$status);
map printf(" %2d",$iinarray->at($_)),(0..$npixels-1);
print "  $anynull (ffgpvi)\n";

$jinarray = zeroes($types{TLONG()}, $npixels);
$fptr->read_img_lng(1,1,$npixels,99,${$jinarray->get_dataref},$anynull,$status);
map printf(" %2d",$jinarray->at($_)),(0..$npixels-1);
print "  $anynull (ffgpvj)\n";

$einarray = zeroes(float, $npixels);
$fptr->read_img_flt(1,1,$npixels,99,${$einarray->get_dataref},$anynull,$status);
map printf(" %2.0f",$einarray->at($_)),(0..$npixels-1);
print "  $anynull (ffgpve)\n";

$dinarray = zeroes(double, $npixels);
$fptr->read_img_dbl(1,1,$npixels,99,${$dinarray->get_dataref},$anynull,$status);
map printf(" %2.0d",$dinarray->at($_)),(0..$npixels-1);
print "  $anynull (ffgpvd)\n";

$status and print("ERROR: ffgpv_ status = $status\n"), goto ERRSTATUS;
$anynull or print "ERROR: ffgpv_ did not detect null values\n";

for ($ii=3;$ii<$npixels;$ii+=4) {
	$boutarray->set($ii,99);
	$ioutarray->set($ii,99);
	$joutarray->set($ii,99);
	$eoutarray->set($ii,99.0);
	$doutarray->set($ii,99.0);
}
$ii=0;
$boutarray->set($ii,99);
$ioutarray->set($ii,99);
$joutarray->set($ii,99);
$eoutarray->set($ii,99.0);
$doutarray->set($ii,99.0);

for ($ii=0; $ii<$npixels;$ii++) {
	($boutarray->at($ii) != $binarray->at($ii)) and
		print "bout != bin = ${\($boutarray->at($ii))} ${\($binarray->at($ii))}}\n";
	($ioutarray->at($ii) != $iinarray->at($ii)) and
		print "iout != iin = ${\($ioutarray->at($ii))} ${\($iinarray->at($ii))}\n";
	($joutarray->at($ii) != $jinarray->at($ii)) and
		print "jout != jin = ${\($joutarray->at($ii))} ${\($jinarray->at($ii))}\n";
	($eoutarray->at($ii) != $einarray->at($ii)) and
		print "eout != ein = ${\($eoutarray->at($ii))} ${\($einarray->at($ii))}\n";
	($doutarray->at($ii) != $dinarray->at($ii)) and
		print "dout != din = ${\($doutarray->at($ii))} ${\($dinarray->at($ii))}\n";
}

$binarray = zeroes($types{TBYTE()}, $npixels);
$larray = $binarray->copy;
$iinarray = zeroes($types{TSHORT()}, $npixels);
$jinarray = zeroes($types{TLONG()}, $npixels);
$einarray = zeroes(float, $npixels);
$dinarray = zeroes(double, $npixels);

$anynull = 0;

$fptr->read_imgnull_byt(1,1,$npixels,${$binarray->get_dataref},${$larray->get_dataref},$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->at($ii)) { print "  *" }
	else { printf " %2d",$binarray->at($ii) }
}
print "  $anynull (ffgpfb)\n";

$fptr->read_imgnull_sht(1,1,$npixels,${$iinarray->get_dataref},${$larray->get_dataref},$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->at($ii)) { print "  *" }
	else { printf " %2d",$iinarray->at($ii) }
}
print "  $anynull (ffgpfi)\n";

$fptr->read_imgnull_lng(1,1,$npixels,${$jinarray->get_dataref},${$larray->get_dataref},$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->at($ii)) { print "  *" }
	else { printf " %2d",$jinarray->at($ii) }
}
print "  $anynull (ffgpfj)\n";

$fptr->read_imgnull_flt(1,1,$npixels,${$einarray->get_dataref},${$larray->get_dataref},$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->at($ii)) { print "  *" }
	else { printf " %2.0f",$einarray->at($ii) }
}
print "  $anynull (ffgpfe)\n";

$fptr->read_imgnull_dbl(1,1,$npixels,${$dinarray->get_dataref},${$larray->get_dataref},$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->at($ii)) { print "  *" }
	else { printf " %2.0f",$dinarray->at($ii) }
}
print "  $anynull (ffgpfd)\n";

$status and print("ERROR: ffgpf_ status = $status\n"), goto ERRSTATUS;
$anynull or print "ERROR: ffgpf_ did not detect null values\n";


##########################################
#  close and reopen file multiple times  #
##########################################

for ($ii=0;$ii<10;$ii++) {
	$fptr->close_file($status) and
		print("ERROR in ftclos (1) = $status"), goto ERRSTATUS;
	$fptr=Astro::FITS::CFITSIO::open_file($filename,READWRITE,$status);
		$status and
			print("ERROR: ffopen open file status = $status\n"), goto ERRSTATUS;
}
print "\nClosed then reopened the FITS file 10 times.\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

$filename = "";
$fptr->file_name($filename,$status);
$fptr->file_mode($filemode,$status);
print "Name of file = $filename, I/O mode = $filemode\n";


############################
#  read single keywords    #
############################

$simple = 0;
$bitpix = 0;
$naxis = 0;
$naxes = [0,0];
$pcount = -99;
$gcount = -99;
$extend = -99;
print "\nRead back keywords:\n";

Astro::FITS::CFITSIO::PerlyUnpacking(1);
$fptr->read_imghdr($simple,$bitpix,$naxis,$naxes,$pcount,$gcount,$extend,$status);
Astro::FITS::CFITSIO::PerlyUnpacking(0);

print "simple = $simple, bitpix = $bitpix, naxis = $naxis, naxes = ($naxes->[0], $naxes->[1])\n";
print "  pcount = $pcount, gcount = $gcount, extend = $extend\n";

$fptr->read_record(9,$card,$status);
print $card,"\n";
(substr($card,0,15) eq "KEY_PREC= 'This") or print "ERROR in ffgrec\n";

$fptr->read_keyn(9,$keyword,$value,$comment,$status);
print "$keyword : $value : $comment :\n";
($keyword eq 'KEY_PREC') or print "ERROR in ffgkyn: $keyword\n";

$fptr->read_card($keyword,$card,$status);
print $card,"\n";
($keyword eq substr($card,0,8)) or print "ERROR in ffgcrd: $keyword\n";

$fptr->read_keyword('KY_PKNS1',$value,$comment,$status);
print "KY_PKNS1 : $value : $comment :\n";
(substr($value,0,14) eq "'first string'") or print "ERROR in ffgkey $value\n";

$fptr->read_key_str('key_pkys',$iskey,$comment,$status);
print "KEY_PKYS $iskey $comment $status\n";

$fptr->read_key_log('key_pkyl',$ilkey,$comment,$status);
print "KEY_PKYL $ilkey $comment $status\n";

$fptr->read_key_lng('KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKYJ $ijkey $comment $status\n";

$fptr->read_key_flt('KEY_PKYJ',$iekey,$comment,$status);
printf "KEY_PKYJ %f $comment $status\n",$iekey;

$fptr->read_key_dbl('KEY_PKYJ',$idkey,$comment,$status);
printf "KEY_PKYJ %f $comment $status\n",$idkey;

($ijkey == 11 and $iekey == 11.0 and $idkey == 11.0) or
	printf "ERROR in ffgky[jed]: %d, %f, %f\n",$ijkey,$iekey,$idkey;

$iskey = "";
$fptr->read_key(TSTRING,'key_pkys',$iskey,$comment,$status);
print "KEY_PKY S $iskey $comment $status\n";

$ilkey = 0;
$fptr->read_key(TLOGICAL,'key_pkyl',$ilkey,$comment,$status);
print "KEY_PKY L $ilkey $comment $status\n";

$fptr->read_key(TBYTE,'KEY_PKYJ',$cval,$comment,$status);
print "KEY_PKY BYTE $cval $comment $status\n";

$fptr->read_key(TSHORT,'KEY_PKYJ',$ishtkey,$comment,$status);
print "KEY_PKY SHORT $ishtkey $comment $status\n";

$fptr->read_key(TINT,'KEY_PKYJ',$ilkey,$comment,$status);
print "KEY_PKY INT $ilkey $comment $status\n";

$ijkey=0;
$fptr->read_key(TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";

$iekey=0;
$fptr->read_key(TFLOAT,'KEY_PKYE',$iekey,$comment,$status);
printf "KEY_PKY E %f $comment $status\n",$iekey;

$idkey=0;
$fptr->read_key(TDOUBLE,'KEY_PKYD',$idkey,$comment,$status);
printf "KEY_PKY D %f $comment $status\n",$idkey;

$fptr->read_key_dbl('KEY_PKYF',$idkey,$comment,$status);
printf "KEY_PKYF %f $comment $status\n",$idkey;

$fptr->read_key_dbl('KEY_PKYE',$idkey,$comment,$status);
printf "KEY_PKYE %f $comment $status\n",$idkey;

$fptr->read_key_dbl('KEY_PKYG',$idkey,$comment,$status);
printf "KEY_PKYG %.14f $comment $status\n",$idkey;

$fptr->read_key_dbl('KEY_PKYD',$idkey,$comment,$status);
printf "KEY_PKYD %.14f $comment $status\n",$idkey;

$fptr->read_key_cmp('KEY_PKYC',$inekey,$comment,$status);
printf "KEY_PKYC %f %f $comment $status\n",@$inekey;

$fptr->read_key_cmp('KEY_PKFC',$inekey,$comment,$status);
printf "KEY_PKFC %f %f $comment $status\n",@$inekey;

$fptr->read_key_dblcmp('KEY_PKYM',$indkey,$comment,$status);
printf "KEY_PKYM %f %f $comment $status\n",@$indkey;

$fptr->read_key_dblcmp('KEY_PKFM',$indkey,$comment,$status);
printf "KEY_PKFM %f %f $comment $status\n",@$indkey;

$fptr->read_key_triple('KEY_PKYT',$ijkey,$idkey,$comment,$status);
printf "KEY_PKYT $ijkey %.14f $comment $status\n",$idkey;

$fptr->write_key_unit('KEY_PKYJ',"km/s/Mpc",$status);
$ijkey=0;
$fptr->read_key(TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";
$fptr->read_key_unit('KEY_PKYJ',$comment,$status);
print "KEY_PKY units = $comment\n";

$fptr->write_key_unit('KEY_PKYJ','',$status);
$ijkey=0;
$fptr->read_key(TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";
$fptr->read_key_unit('KEY_PKYJ',$comment,$status);
print "KEY_PKY units = $comment\n";

$fptr->write_key_unit('KEY_PKYJ','feet/second/second',$status);
$ijkey=0;
$fptr->read_key(TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";
$fptr->read_key_unit('KEY_PKYJ',$comment,$status);
print "KEY_PKY units = $comment\n";

$fptr->read_key_longstr('key_pkls',$lsptr,$comment,$status);
print "KEY_PKLS long string value = \n$lsptr\n";

$fptr->get_hdrpos($existkeys,$keynum,$status);
print "header contains $existkeys keywords; located at keyword $keynum \n";

############################
#  read array keywords     #
############################
Astro::FITS::CFITSIO::PerlyUnpacking(1);

$fptr->read_keys_str('ky_pkns',1,3,$inskey,$nfound,$status);
print "ffgkns:  $inskey->[0], $inskey->[1], $inskey->[2]\n";
($nfound == 3 and $status == 0) or print "\nERROR in ffgkns $nfound, $status\n";

$fptr->read_keys_log('ky_pknl',1,3,$inlkey,$nfound,$status);
print "ffgknl:  $inlkey->[0], $inlkey->[1], $inlkey->[2]\n";
($nfound == 3 and $status == 0) or print "\nERROR in ffgknl $nfound, $status\n";

$fptr->read_keys_lng('ky_pknj',1,3,$injkey,$nfound,$status);
print "ffgknj:  $injkey->[0], $injkey->[1], $injkey->[2]\n";
($nfound == 3 and $status == 0) or print "\nERROR in ffgknj $nfound, $status\n";

$fptr->read_keys_flt('ky_pkne',1,3,$inekey,$nfound,$status);
printf "ffgkne:  %f, %f, %f\n",@{$inekey};
($nfound == 3 and $status == 0) or print "\nERROR in ffgkne $nfound, $status\n";

$fptr->read_keys_dbl('ky_pknd',1,3,$indkey,$nfound,$status);
printf "ffgknd:  %f, %f, %f\n",@{$indkey};
($nfound == 3 and $status == 0) or print "\nERROR in ffgknd $nfound, $status\n";
Astro::FITS::CFITSIO::PerlyUnpacking(0);

$fptr->read_card('HISTORY',$card,$status);
$fptr->get_hdrpos($existkeys,$keynum,$status);
$keynum -= 2;

print "\nBefore deleting the HISTORY and DATE keywords...\n";
for ($ii=$keynum; $ii<=$keynum+3;$ii++) {
	$fptr->read_record($ii,$card,$status);
	print substr($card,0,8),"\n";
}

############################
#  delete keywords         #
############################

$fptr->delete_record($keynum+1,$status);
$fptr->delete_key('DATE',$status);

print "\nAfter deleting the keywords...\n";
for ($ii=$keynum; $ii<=$keynum+1;$ii++) {
	$fptr->read_record($ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR deleting keywords\n";

############################
#  insert keywords         #
############################

$keynum += 4;
$fptr->insert_record($keynum-3,"KY_IREC = 'This keyword inserted by fxirec'",$status);
$fptr->insert_key_str('KY_IKYS',"insert_value_string", "ikys comment", $status);
$fptr->insert_key_lng('KY_IKYJ',49,"ikyj comment", $status);
$fptr->insert_key_log('KY_IKYL',1, "ikyl comment", $status);
$fptr->insert_key_flt('KY_IKYE',12.3456, 4, "ikye comment", $status);
$fptr->insert_key_dbl('KY_IKYD',12.345678901234567, 14, "ikyd comment", $status);
$fptr->insert_key_fixflt('KY_IKYF',12.3456, 4, "ikyf comment", $status);
$fptr->insert_key_fixdbl('KY_IKYG',12.345678901234567, 13, "ikyg comment", $status);

print "\nAfter inserting the keywords...\n";
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) {
	$fptr->read_record($ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR inserting keywords\n";

############################
#  modify keywords         #
############################

$fptr->modify_record($keynum-4,'COMMENT   This keyword was modified by fxmrec', $status);
$fptr->modify_card('KY_IREC',"KY_MREC = 'This keyword was modified by fxmcrd'",$status);
$fptr->modify_name('KY_IKYS','NEWIKYS',$status);
$fptr->modify_comment('KY_IKYJ','This is a modified comment', $status);
$fptr->modify_key_lng('KY_IKYJ',50,'&',$status);
$fptr->modify_key_log('KY_IKYL',0,'&',$status);
$fptr->modify_key_str('NEWIKYS','modified_string', '&', $status);
$fptr->modify_key_flt('KY_IKYE',-12.3456, 4, '&', $status);
$fptr->modify_key_dbl('KY_IKYD',-12.345678901234567, 14, 'modified comment', $status);
$fptr->modify_key_fixflt('KY_IKYF',-12.3456, 4, '&', $status);
$fptr->modify_key_fixdbl('KY_IKYG',-12.345678901234567, 13, '&', $status);

print "\nAfter modifying the keywords...\n";
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) {
	$fptr->read_record($ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR modifying keywords\n";

############################
#  update keywords         #
############################

$fptr->update_card('KY_MREC',"KY_UCRD = 'This keyword was updated by fxucrd'",$status);

$fptr->update_key_lng('KY_IKYJ',51,'&',$status);
$fptr->update_key_log('KY_IKYL',1,'&',$status);
$fptr->update_key_str('NEWIKYS',"updated_string",'&',$status);
$fptr->update_key_flt('KY_IKYE',-13.3456, 4,'&',$status);
$fptr->update_key_dbl('KY_IKYD',-13.345678901234567, 14,'modified comment',$status);
$fptr->update_key_fixflt('KY_IKYF',-13.3456, 4,'&',$status);
$fptr->update_key_fixdbl('KY_IKYG',-13.345678901234567, 13,'&',$status);

print "\nAfter updating the keywords...\n";
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) {
	$fptr->read_record($ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR modifying keywords\n";

$fptr->read_record(0,$card,$status);

print "\nKeywords found using wildcard search (should be 13)...\n";
$nfound = 0;
while (!$fptr->find_nextkey($inclist,2,$exclist,2,$card,$status)) {
	$nfound++;
	print $card,"\n";
}
($nfound == 13) or print("\nERROR reading keywords using wildcards (ffgnxk)\n"), goto ERRSTATUS;

$status=0;

############################
#  copy index keyword      #
############################

$fptr->copy_key($fptr,1,4,'KY_PKNE',$status);
$fptr->read_keys_str('ky_pkne',2,4,$inekey,$nfound,$status);
printf "\nCopied keyword: ffgkne:  %f, %f, %f\n", @$inekey;

$status and print("\nERROR in ffgkne $nfound, $status\n"),goto ERRSTATUS;

######################################
#  modify header using template file #
######################################

$fptr->write_key_template($template,$status) and
	print "\nERROR returned by ffpktp\n", goto ERRSTATUS;
print "Updated header using template file (ffpktp)\n";

############################
#  create binary table     #
############################

$tform = [ qw( 15A 1L 16X 1B 1I 1J 1E 1D 1C 1M ) ];
$ttype = [ qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue ) ];
$tunit = [ ( '', 'm**2', 'cm', 'erg/s', 'km/s', '', '', '', '', '') ];

$nrows = 21;
$tfields = 10;
$pcount = 0;

$fptr->insert_btbl($nrows,$tfields,$ttype,$tform,$tunit,$binname,0,$status);
print "\nffibin status = $status\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

$fptr->get_hdrpos($existkeys,$keynum,$status);
print "header contains $existkeys keywords; located at keyword $keynum \n";

$morekeys=40;
$fptr->set_hdrsize($morekeys,$status);
$fptr->get_hdrspace($existkeys,$morekeys,$status);
print "header contains $existkeys keywords with room for $morekeys more\n";

$fptr->set_btblnull(4,99,$status);
$fptr->set_btblnull(5,99,$status);
$fptr->set_btblnull(6,99,$status);

$extvers=1;
$fptr->write_key_lng('EXTVER',$extvers,'extension version number', $status);
$fptr->write_key_lng('TNULL4',99,'value for undefined pixels',$status);
$fptr->write_key_lng('TNULL5',99,'value for undefined pixels',$status);
$fptr->write_key_lng('TNULL6',99,'value for undefined pixels',$status);

$naxis=3;
$naxes=[1,2,8];
$fptr->write_tdim(3,$naxis,$naxes,$status);
$naxis=0;
$naxes=undef;
Astro::FITS::CFITSIO::PerlyUnpacking(1);    # make naxes a normal Perl array
$fptr->read_tdim(3,$naxis,$naxes,$status);
Astro::FITS::CFITSIO::PerlyUnpacking(0);
$fptr->read_key_str('TDIM3',$iskey,$comment,$status);
print "TDIM3 = $iskey, $naxis, $naxes->[0], $naxes->[1], $naxes->[2]\n";

$fptr->set_hdustruc($status);

############################
#  write data to columns   #
############################

$signval = -1;
for ($ii=0;$ii<21;$ii++) {
	$signval *= -1;
	$boutarray->set($ii,$ii+1);
	$ioutarray->set($ii, ($ii+1) * $signval);
	$koutarray->set($ii, ($ii+1) * $signval);
	$joutarray->set($ii, ($ii+1) * $signval);
	$eoutarray->set($ii, ($ii+1) * $signval);
	$doutarray->set($ii, ($ii+1) * $signval);
}

$fptr->write_col_str(1,1,1,3,$onskey,$status);
$fptr->write_col_null(1,4,1,1,$status);

$larray = byte [0,1,0,0,1,1,0,0,0,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0];
$fptr->write_col_bit(3,1,1,36,$larray->get_dataref,$status);

for ($ii=4;$ii<9;$ii++) {
	$fptr->write_col_byt($ii,1,1,2,$boutarray->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_sht($ii,3,1,2,$ioutarray->slice('2:3')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_int($ii,5,1,2,$koutarray->slice('4:5')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_flt($ii,7,1,2,$eoutarray->slice('6:7')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_dbl($ii,9,1,2,$doutarray->slice('8:9')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_null($ii,11,1,1,$status);
}

$fptr->write_col_cmp(9,1,1,10,$eoutarray->get_dataref,$status);
$fptr->write_col_dblcmp(10,1,1,10,$doutarray->get_dataref,$status);

for ($ii=4;$ii<9;$ii++) {
	$fptr->write_colnull_byt($ii,12,1,2,$boutarray->slice('11:12')->get_dataref,13,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_colnull_sht($ii,14,1,2,$ioutarray->slice('13:14')->get_dataref,15,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_colnull_int($ii,16,1,2,$koutarray->slice('15:16')->get_dataref,17,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_colnull_flt($ii,18,1,2,$eoutarray->slice('17:18')->get_dataref,19.,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_colnull_dbl($ii,20,1,2,$doutarray->slice('19:20')->get_dataref,21.,$status);
	($status == NUM_OVERFLOW) and $status = 0;
}
$fptr->write_col_log(2,1,1,21,$larray->get_dataref,$status);
$fptr->write_col_null(2,11,1,1,$status);
print "ffpcl_ status = $status\n";

#########################################
#  get information about the columns    #
#########################################

print "\nFind the column numbers; a returned status value of 237 is";
print "\nexpected and indicates that more than one column name matches";
print "\nthe input column name template.  Status = 219 indicates that";
print "\nthere was no matching column name.";

$fptr->get_colnum(0,'Xvalue',$colnum,$status);
print "\nColumn Xvalue is number $colnum; status = $status.\n";

while ($status != COL_NOT_FOUND) {
	$fptr->get_colname(1,'*ue',$colname,$colnum,$status);
	print "Column $colname is number $colnum; status = $status.\n";
}
$status = 0;

print "\nInformation about each column:\n";
for ($ii=0;$ii<$tfields;$ii++) {
	$fptr->get_coltype($ii+1,$typecode,$repeat,$width,$status);
	printf("%4s %3d %2d %2d", $tform->[$ii], $typecode, $repeat, $width);
	$fptr->get_bcolparms($ii+1,$ttype->[0],$tunit->[0],$cval,$repeat,$scale,$zero,$jnulval,$tdisp,$status);
	printf " $ttype->[0], $tunit->[0], $cval, $repeat, %f, %f, $jnulval, $tdisp.\n",$scale,$zero;
}
print "\n";

###############################################
#  insert ASCII table before the binary table #
###############################################

$fptr->movrel_hdu(-1,$hdutype,$status) and goto ERRSTATUS;

$tform = [ qw( A15 I10 F14.6 E12.5 D21.14 ) ];
$ttype = [ qw( Name Ivalue Fvalue Evalue Dvalue ) ];
$tunit = [ ('','m**2','cm','erg/s','km/s') ];
$rowlen = 76;
$nrows = 11;
$tfields = 5;

$fptr->insert_atbl($rowlen,$nrows,$tfields,$ttype,$tbcol->get_dataref,$tform,$tunit,$tblname,$status);
print "ffitab status = $status\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

$fptr->set_atblnull(1,'null1',$status);
$fptr->set_atblnull(2,'null2',$status);
$fptr->set_atblnull(3,'null3',$status);
$fptr->set_atblnull(4,'null4',$status);
$fptr->set_atblnull(5,'null5',$status);

$extvers=2;
$fptr->write_key_lng('EXTVER',$extvers,'extension version number',$status);
$fptr->write_key_str('TNULL1','null1','value for undefined pixels',$status);
$fptr->write_key_str('TNULL2','null2','value for undefined pixels',$status);
$fptr->write_key_str('TNULL3','null3','value for undefined pixels',$status);
$fptr->write_key_str('TNULL4','null4','value for undefined pixels',$status);
$fptr->write_key_str('TNULL5','null5','value for undefined pixels',$status);

$status and goto ERRSTATUS;

############################
#  write data to columns   #
############################

for ($ii=0;$ii<21;$ii++) {
	$boutarray->set($ii,$ii+1);
	$ioutarray->set($ii,$ii+1);
	$joutarray->set($ii,$ii+1);
	$eoutarray->set($ii,$ii+1);
	$doutarray->set($ii,$ii+1);
}

$fptr->write_col_str(1,1,1,3,$onskey,$status);
$fptr->write_col_null(1,4,1,1,$status);

for ($ii=2;$ii<6;$ii++) {
	$fptr->write_col_byt($ii,1,1,2,$boutarray->slice('0:1')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_sht($ii,3,1,2,$ioutarray->slice('2:3')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_lng($ii,5,1,2,$joutarray->slice('4:5')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_flt($ii,7,1,2,$eoutarray->slice('6:7')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	$fptr->write_col_dbl($ii,9,1,2,$doutarray->slice('8:9')->get_dataref,$status);
	($status == NUM_OVERFLOW) and $status = 0;

	$fptr->write_col_null($ii,11,1,1,$status);
}
print "ffpcl_ status = $status\n";

################################
#  read data from ASCII table  #
################################

$fptr->read_atblhdr($rowlen,$nrows,$tfields,$ttype,${$tbcol->get_dataref},$tform,$tunit,$tblname,$status);

print "\nASCII table: rowlen, nrows, tfields, extname: $rowlen $nrows $tfields $tblname\n";
for ($ii=0;$ii<$tfields;$ii++) {
	printf "%8s %3d %8s %8s \n", $ttype->[$ii], $tbcol->at($ii), $tform->[$ii], $tunit->[$ii];
}

$nrows = 11;

$fptr->read_col_str(1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(2,1,1,$nrows,99,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(2,1,1,$nrows,99,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(3,1,1,$nrows,99,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(4,1,1,$nrows,99,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(5,1,1,$nrows,99,${$dinarray->get_dataref},$anynull,$status);

print "\nData values read from ASCII table:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$jinarray->at($ii), $einarray->at($ii), $dinarray->at($ii)
	);
}

$uchars = zeroes(78)->byte;
$fptr->read_tblbytes(1,20,78,${$uchars->get_dataref},$status);
print "\n";
foreach (0..77) { print pack "C", $uchars->at($_) }
print "\n";
$fptr->write_tblbytes(1,20,78,$uchars->get_dataref,$status);

#########################################
#  get information about the columns    #
#########################################

$fptr->get_colnum(0,'name',$colnum,$status);
print "\nColumn name is number $colnum; status = $status.\n";

while ($status != COL_NOT_FOUND) {
	$fptr->get_colname(0,'*ue',$colname,$colnum,$status);
	print "Column $colname is number $colnum; status = $status.\n";
}
$status = 0;

for ($ii=0;$ii<$tfields;$ii++) {
	$fptr->get_coltype($ii+1,$typecode,$repeat,$width,$status);
	printf "%4s %3d %2d %2d", $tform->[$ii], $typecode, $repeat, $width;
	$fptr->get_acolparms($ii+1,$ttype->[0],$tbcol,$tunit->[0],$tform->[0],$scale,
		$zero,$nulstr,$tdisp,$status);
	printf " $ttype->[0], $tbcol, $tunit->[0], $tform->[0], %f, %f, $nulstr, $tdisp.\n",
		$scale, $zero;
}
print "\n";

###############################################
#  test the insert/delete row/column routines #
###############################################

$fptr->insert_rows(2,3,$status) and goto ERRSTATUS;

$nrows = 14;

$fptr->read_col_str(1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(2,1,1,$nrows,99,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(2,1,1,$nrows,99,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(3,1,1,$nrows,99,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(4,1,1,$nrows,99,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(5,1,1,$nrows,99,${$dinarray->get_dataref},$anynull,$status);

print "\nData values after inserting 3 rows after row 2:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$jinarray->at($ii), $einarray->at($ii), $dinarray->at($ii)
	);
}

$fptr->delete_rows(10,2,$status) and goto ERRSTATUS;

$nrows = 12;

$fptr->read_col_str(1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(2,1,1,$nrows,99,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(2,1,1,$nrows,99,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(3,1,1,$nrows,99,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(4,1,1,$nrows,99,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(5,1,1,$nrows,99,${$dinarray->get_dataref},$anynull,$status);

print "\nData values after deleting 2 rows at row 10:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$jinarray->at($ii), $einarray->at($ii), $dinarray->at($ii)
	);
}

$fptr->delete_col(3,$status) and goto ERRSTATUS;

$fptr->read_col_str(1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(2,1,1,$nrows,99,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(2,1,1,$nrows,99,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(3,1,1,$nrows,99,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(4,1,1,$nrows,99,${$dinarray->get_dataref},$anynull,$status);

print "\nData values after deleting column 3:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$einarray->at($ii), $dinarray->at($ii)
	);
}

$fptr->insert_col(5,'INSERT_COL','F14.6',$status) and goto ERRSTATUS;

$fptr->read_col_str(1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(2,1,1,$nrows,99,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(2,1,1,$nrows,99,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(3,1,1,$nrows,99,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(4,1,1,$nrows,99,${$dinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(5,1,1,$nrows,99,${$jinarray->get_dataref},$anynull,$status);

print "\nData values after inserting column 5:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %4.1f %4.1f %d\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$einarray->at($ii), $dinarray->at($ii), $jinarray->at($ii),
	);
}

############################################################
#  create a temporary file and copy the ASCII table to it, #
#  column by column.                                       #
############################################################

$bitpix=16;
$naxis=0;
$filename = '!t1q2s3v6.tmp';
$tmpfptr=Astro::FITS::CFITSIO::create_file($filename,$status);
print "Create temporary file: ffinit status = $status\n";

$tmpfptr->insert_img($bitpix,$naxis,$naxes,$status);
print "\nCreate null primary array: ffiimg status = $status\n";

$nrows=12;
$tfields=0;
$rowlen=0;

$tmpfptr->insert_atbl($rowlen,$nrows,$tfields,$ttype,$tbcol,$tform,$tunit,$tblname,$status);
print "\nCreate ASCII table with 0 columns: ffitab status = $status\n";

$fptr->copy_col($tmpfptr,4,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,3,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,2,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,1,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";

$tmpfptr->insert_btbl($nrows,$tfields,$ttype,$tform,$tunit,$tblname,0,$status);
print "\nCreate Binary table with 0 columns: ffibin status = $status\n";

$fptr->copy_col($tmpfptr,4,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,3,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,2,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,1,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";

$tmpfptr->delete_file($status);
print "Delete the tmp file: ffdelt status = $status\n";

$status and goto ERRSTATUS;

################################
#  read data from binary table #
################################

$fptr->movrel_hdu(1,$hdutype,$status) and goto ERRSTATUS;
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

$fptr->get_hdrspace($existkeys,$morekeys,$status);
print "header contains $existkeys keywords with room for $morekeys more\n";

$fptr->read_btblhdr($nrows,$tfields,$ttype,$tform,$tunit,$binname,$pcount,$status);
print "\nBinary table: nrows, tfields, extname, pcount: $nrows $tfields $binname $pcount\n";

for ($ii=0;$ii<$tfields;$ii++) {
	printf "%8s %8s %8s \n", $ttype->[$ii], $tform->[$ii], $tunit->[$ii];
}

$larray = zeroes($types{TBYTE()}, 40);
print "\nData values read from binary table:\n";
printf "  Bit column (X) data values: \n\n";

$fptr->read_col_bit(3,1,1,36,${$larray->get_dataref},$status);
for ($jj=0;$jj<5;$jj++) {
	foreach ($jj*8..$jj*8+7) {
		print $larray->at($_);
	}
	print " ";
}

$larray = zeroes($types{TBYTE()}, $nrows);
$xinarray = zeroes($types{TBYTE()}, $nrows);
$binarray = zeroes($types{TBYTE()}, $nrows);
$iinarray = zeroes($types{TSHORT()}, $nrows);
$kinarray = zeroes($types{TINT()}, $nrows);
$einarray = zeroes(float, $nrows);
$dinarray = zeroes(double, $nrows);
$cinarray = zeroes(float, $nrows*2);
$minarray = zeroes(double, $nrows*2);

print "\n\n";

$fptr->read_col_str(1,4,1,1,'',$inskey,$anynull,$status);
print "null string column value = -$inskey->[0]- (should be --)\n";

$nrows=21;
$fptr->read_col_str(1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
$fptr->read_col_log(2,1,1,$nrows,0,${$larray->get_dataref},$anynull,$status);
$fptr->read_col_byt(3,1,1,$nrows,98,${$xinarray->get_dataref},$anynull,$status);
$fptr->read_col_byt(4,1,1,$nrows,98,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(5,1,1,$nrows,98,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_int(6,1,1,$nrows,98,${$kinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(7,1,1,$nrows,98.,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(8,1,1,$nrows,98.,${$dinarray->get_dataref},$anynull,$status);
$fptr->read_col_cmp(9,1,1,$nrows,98.,${$cinarray->get_dataref},$anynull,$status);
$fptr->read_col_dblcmp(10,1,1,$nrows,98.,${$minarray->get_dataref},$anynull,$status);

print "\nRead columns with ffgcv_:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf "%15s %d %3d %2d %3d %3d %5.1f %5.1f (%5.1f,%5.1f) (%5.1f,%5.1f) \n",
		$inskey->[$ii], $larray->at($ii), $xinarray->at($ii),
		$binarray->at($ii),
		$iinarray->at($ii),$kinarray->at($ii), $einarray->at($ii),
		$dinarray->at($ii),
		$cinarray->at($ii*2),$cinarray->at($ii*2+1),
		$minarray->at($ii*2),$minarray->at($ii*2+1),
}

@tmp = (0..$nrows-1);
$larray = pdl(\@tmp)->$tbyte;
$larray2 = $larray->copy;
$xinarray = pdl(\@tmp)->$tbyte;
$binarray = pdl(\@tmp)->$tbyte;
$iinarray = pdl(\@tmp)->$tshort;
$kinarray = pdl(\@tmp)->$tint;
$einarray = float \@tmp;
$dinarray = double \@tmp;
@tmp = (0..2*$nrows-1);
$cinarray = float \@tmp;
$minarray = double \@tmp;

$fptr->read_colnull_str(1,1,1,$nrows,$inskey,${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_log(2,1,1,$nrows,${$larray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_byt(3,1,1,$nrows,${$xinarray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_byt(4,1,1,$nrows,${$binarray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_sht(5,1,1,$nrows,${$iinarray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_int(6,1,1,$nrows,${$kinarray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_flt(7,1,1,$nrows,${$einarray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_dbl(8,1,1,$nrows,${$dinarray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_cmp(9,1,1,$nrows,${$cinarray->get_dataref},${$larray2->get_dataref},$anynull,$status);
$fptr->read_colnull_dblcmp(10,1,1,$nrows,${$minarray->get_dataref},${$larray2->get_dataref},$anynull,$status);

print "\nRead columns with ffgcf_:\n";
for ($ii=0;$ii<10;$ii++) {
	printf "%15s %d %3d %2d %3d %3d %5.1f %5.1f (%5.1f,%5.1f) (%5.1f,%5.1f)\n",
		$inskey->[$ii], $larray->at($ii), $xinarray->at($ii),
		$binarray->at($ii),
		$iinarray->at($ii), $kinarray->at($ii), $einarray->at($ii),
		$dinarray->at($ii),
		$cinarray->at($ii*2),$cinarray->at($ii*2+1),
		$minarray->at($ii*2),$minarray->at($ii*2+1),
}

for ($ii=10; $ii<$nrows;$ii++) {
	printf "%15s %d %3d %2d %3d \n",
		$inskey->[$ii], $larray->at($ii), $xinarray->at($ii),
		$binarray->at($ii), $iinarray->at($ii);
}
$fptr->write_record("key_prec= 'This keyword was written by f_prec' / comment here", $status);

###############################################
#  test the insert/delete row/column routines #
###############################################

$fptr->insert_rows(2,3,$status) and goto ERRSTATUS;
$nrows=14;
$fptr->read_col_str(1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(4,1,1,$nrows,98,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(5,1,1,$nrows,98,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(6,1,1,$nrows,98,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(7,1,1,$nrows,98.,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(8,1,1,$nrows,98.,${$dinarray->get_dataref},$anynull,$status);

print "\nData values after inserting 3 rows after row 2:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %3d %5.1f %5.1f\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$jinarray->at($ii), $einarray->at($ii), $dinarray->at($ii);
}

$fptr->delete_rows(10,2,$status) and goto ERRSTATUS;

$nrows=12;
$fptr->read_col_str(1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(4,1,1,$nrows,98,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(5,1,1,$nrows,98,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(6,1,1,$nrows,98,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(7,1,1,$nrows,98.,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(8,1,1,$nrows,98.,${$dinarray->get_dataref},$anynull,$status);

print "\nData values after deleting 2 rows at row 10:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %3d %5.1f %5.1f\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$jinarray->at($ii), $einarray->at($ii), $dinarray->at($ii);
}

$fptr->delete_col(6,$status) and goto ERRSTATUS;
$fptr->read_col_str(1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(4,1,1,$nrows,98,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(5,1,1,$nrows,98,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(6,1,1,$nrows,98.,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(7,1,1,$nrows,98.,${$dinarray->get_dataref},$anynull,$status);

print "\nData values after deleting column 6:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %5.1f %5.1f\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$einarray->at($ii), $dinarray->at($ii);
}

$fptr->insert_col(8,'INSERT_COL','1E',$status) and goto ERRSTATUS;
$fptr->read_col_str(1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(4,1,1,$nrows,98,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(5,1,1,$nrows,98,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(8,1,1,$nrows,98,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(6,1,1,$nrows,98.,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(7,1,1,$nrows,98.,${$dinarray->get_dataref},$anynull,$status);

print "\nData values after inserting column 8:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %5.1f %5.1f %d\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$einarray->at($ii), $dinarray->at($ii) , $jinarray->at($ii);
}


$fptr->write_col_null(8,1,1,10,$status);
$fptr->read_col_str(1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
$fptr->read_col_byt(4,1,1,$nrows,98,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col_sht(5,1,1,$nrows,98,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col_flt(6,1,1,$nrows,98.,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col_dbl(7,1,1,$nrows,98.,${$dinarray->get_dataref},$anynull,$status);
$fptr->read_col_lng(8,1,1,$nrows,98,${$jinarray->get_dataref},$anynull,$status);

print "\nValues after setting 1st 10 elements in column 8 = null:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %5.1f %5.1f %d\n",
		$inskey->[$ii], $binarray->at($ii), $iinarray->at($ii),
		$einarray->at($ii), $dinarray->at($ii) , $jinarray->at($ii);
}

############################################################
#  create a temporary file and copy the binary table to it,#
#  column by column.                                       #
############################################################

$bitpix=16;
$naxis=0;
$filename = '!t1q2s3v5.tmp';

$tmpfptr=Astro::FITS::CFITSIO::create_file($filename,$status);
print "Create temporary file: ffinit status = $status\n";

$tmpfptr->insert_img($bitpix,$naxis,$naxes,$status);
print "\nCreate null primary array: ffiimg status = $status\n";

$nrows=22;
$tfields=0;
$tmpfptr->insert_btbl($nrows,$tfields,$ttype,$tform,$tunit,$binname,0,$status);
print "\nCreate binary table with 0 columns: ffibin status = $status\n";

$fptr->copy_col($tmpfptr,7,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,6,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,5,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,4,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,3,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,2,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
$fptr->copy_col($tmpfptr,1,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";

$tmpfptr->delete_file($status);
print "Delete the tmp file: ffdelt status = $status\n";

$status and goto ERRSTATUS;

####################################################
#  insert binary table following the primary array #
####################################################

$fptr->movabs_hdu(1,$hdutype,$status);
$tform = [ qw( 15A 1L 16X 1B 1I 1J 1E 1D 1C 1M ) ];
$ttype = [ qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue ) ];
$tunit = [ ( '', 'm**2', 'cm', 'erg/s', 'km/s', '', '', '', '', '' ) ];

$nrows=20;
$tfields=10;
$pcount=0;

$fptr->insert_btbl($nrows,$tfields,$ttype,$tform,$tunit,$binname,$pcount,$status);
print "ffibin status = $status\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

$extvers=3;
$fptr->write_key_lng('EXTVER',$extvers,'extension version number',$status);

$fptr->write_key_lng('TNULL4',77,'value for undefined pixels',$status);
$fptr->write_key_lng('TNULL5',77,'value for undefined pixels',$status);
$fptr->write_key_lng('TNULL6',77,'value for undefined pixels',$status);

$fptr->write_key_lng('TSCAL4',1000,'scaling factor',$status);
$fptr->write_key_lng('TSCAL5',1,'scaling factor',$status);
$fptr->write_key_lng('TSCAL6',100,'scaling factor',$status);

$fptr->write_key_lng('TZERO4',0,'scaling offset',$status);
$fptr->write_key_lng('TZERO5',32768,'scaling offset',$status);
$fptr->write_key_lng('TZERO6',100,'scaling offset',$status);

$fptr->set_btblnull(4,77,$status);
$fptr->set_btblnull(5,77,$status);
$fptr->set_btblnull(6,77,$status);

$fptr->set_tscale(4,1000.,0.,$status);
$fptr->set_tscale(5,1.,32768.,$status);
$fptr->set_tscale(6,100.,100.,$status);

############################
#  write data to columns   #
############################

$joutarray = pdl([0,1000,10000,32768,65535])->$tlong;

for ($ii=4;$ii<7;$ii++) {
	$fptr->write_col_lng($ii,1,1,5,$joutarray->get_dataref,$status);
	($status == NUM_OVERFLOW) and print("Overflow writing to column $ii\n"),$status=0;
	$fptr->write_col_null($ii,6,1,1,$status);
}

for ($jj=4;$jj<7;$jj++) {
	$fptr->read_col_lng($jj,1,1,6,-999,${$jinarray->get_dataref},$anynull,$status);
	for ($ii=0;$ii<6;$ii++) {
		printf " %6d",$jinarray->at($ii);
	}
	print "\n";
}

print "\n";
$fptr->set_tscale(4,1.,0.,$status);
$fptr->set_tscale(5,1.,0.,$status);
$fptr->set_tscale(6,1.,0.,$status);

for ($jj=4;$jj<7;$jj++) {
	$fptr->read_col_lng($jj,1,1,6,-999,${$jinarray->get_dataref},$anynull,$status);
	for ($ii=0;$ii<6;$ii++) {
		printf " %6d",$jinarray->at($ii);
	}
	print "\n";
}

######################################################
#  insert image extension following the binary table #
######################################################

$bitpix=-32;
$naxis=2;
$naxes=[15,25];
$fptr->insert_img($bitpix,$naxis,$naxes,$status);
print "\nCreate image extension: ffiimg status = $status\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

$imgarray = zeroes($types{TSHORT()}, 19,30);
for ($jj=0;$jj<30;$jj++) {
	for ($ii=0;$ii<19;$ii++) {
		$imgarray->set($ii,$jj, ($ii<15) ? ($jj * 10) + $ii : 0 );;
	}
}

$fptr->write_2d_sht(1,19,$naxes->[0],$naxes->[1],$imgarray->get_dataref,$status);
print "\nWrote whole 2D array: ffp2di status = $status\n";

$imgarray = zeroes($types{TSHORT()}, 19,30);
$fptr->read_2d_sht(1,0,19,$naxes->[0],$naxes->[1],${$imgarray->get_dataref},$anynull,$status);
print "\nRead whole 2D array: ffg2di status = $status\n";

for ($jj=0;$jj<30;$jj++) {
	foreach (15..18) { $imgarray->set($_,$jj,0) }
	for ($ii=0;$ii<19;$ii++) {
		printf " %3d", $imgarray->at($ii,$jj);
	}
	print "\n";
}

$imgarray2 = zeroes($types{TSHORT()}, 10,20);
for ($jj=0;$jj<20;$jj++) {
	for ($ii=0;$ii<10;$ii++) {
		$imgarray2->set($ii,$jj, ($jj * -10) - $ii);
	}
}

$fpixels=[5,5];
$lpixels = [14,14];
$fptr->write_subset_sht(1,$naxis,$naxes,$fpixels,$lpixels,$imgarray2->get_dataref,$status);
print "\nWrote subset 2D array: ffpssi status = $status\n";

$imgarray = zeroes($types{TSHORT()}, 19,30);
$fptr->read_2d_sht(1,0,19,$naxes->[0],$naxes->[1],${$imgarray->get_dataref},$anynull,$status);
print "\nRead whole 2D array: ffg2di status = $status\n";

for ($jj=0;$jj<30;$jj++) {
	foreach (15..18) { $imgarray->set($_,$jj,0) }
	for ($ii=0;$ii<19;$ii++) {
		printf " %3d", $imgarray->at($ii,$jj);
	}
	print "\n";
}

$fpixels = [2,5];
$lpixels = [10,8];
$inc = [2,3];

$imgarray = zeroes($types{TSHORT()}, 19,30);

$fptr->read_subset_sht(1,$naxis,$naxes,$fpixels,$lpixels,$inc,0,${$imgarray->get_dataref},$anynull,$status);
print "\nRead subset of 2D array: ffgsvi status = $status\n";

for ($ii=0;$ii<10;$ii++) {
	printf " %3d",$imgarray->at($ii,0);
}
print "\n";

###########################################################
#  insert another image extension                         #
#  copy the image extension to primary array of tmp file. #
#  then delete the tmp file, and the image extension      #
###########################################################

$bitpix=16;
$naxis=2;
$naxes = [15,25];
$fptr->insert_img($bitpix,$naxis,$naxes,$status);
print "\nCreate image extension: ffiimg status = $status\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

$filename = 't1q2s3v4.tmp';
$tmpfptr=Astro::FITS::CFITSIO::create_file($filename,$status);
print "Create temporary file: ffinit status = $status\n";

$fptr->copy_hdu($tmpfptr,0,$status);
print "Copy image extension to primary array of tmp file.\n";
print "ffcopy status = $status\n";

$tmpfptr->read_record(1,$card,$status);
print "$card\n";
$tmpfptr->read_record(2,$card,$status);
print "$card\n";
$tmpfptr->read_record(3,$card,$status);
print "$card\n";
$tmpfptr->read_record(4,$card,$status);
print "$card\n";
$tmpfptr->read_record(5,$card,$status);
print "$card\n";
$tmpfptr->read_record(6,$card,$status);
print "$card\n";

$tmpfptr->delete_file($status);
print "Delete the tmp file: ffdelt status = $status\n";

$fptr->delete_hdu($hdutype,$status);
print "Delete the image extension; hdutype, status = $hdutype $status\n";
print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";

###########################################################
#  append bintable extension with variable length columns #
###########################################################

$fptr->create_hdu($status);
print "ffcrhd status = $status\n";

$tform = [ qw( 1PA 1PL 1PB 1PB 1PI 1PJ 1PE 1PD 1PC 1PM ) ];
$ttype = [ qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue ) ];
$tunit = [ ( '', 'm**2', 'cm', 'erg/s', 'km/s', '', '', '', '', '' ) ];

$nrows=20;
$tfields = 10;
$pcount=0;

$fptr->write_btblhdr($nrows,$tfields,$ttype,$tform,$tunit,$binname,$pcount,$status);
print "Variable length arrays: ffphbn status = $status\n";

$extvers=4;
$fptr->write_key_lng('EXTVER',$extvers,'extension version number',$status);

$fptr->write_key_lng('TNULL4', 88, 'value for undefined pixels', $status);
$fptr->write_key_lng('TNULL5', 88, 'value for undefined pixels', $status);
$fptr->write_key_lng('TNULL6', 88, 'value for undefined pixels', $status);

############################
#  write data to columns   #
############################

$iskey = 'abcdefghijklmnopqrst';

$boutarray = pdl([1..21])->$tbyte;
$ioutarray = pdl([1..21])->$tshort;
$joutarray = pdl([1..21])->$tlong;
$eoutarray = float [1..21];
$doutarray = double [1..21];

$larray = pdl([0,1,0,0,1,1,0,0,0,1,1,1,0,0,0,0,1,1,1,1])->$tbyte;

$inskey=[''];
$fptr->write_col_str(1,1,1,1,$inskey,$status);
$fptr->write_col_log(2,1,1,1,$larray->get_dataref,$status);
$fptr->write_col_bit(3,1,1,1,$larray->get_dataref,$status);
$fptr->write_col_byt(4,1,1,1,$boutarray->get_dataref,$status);
$fptr->write_col_sht(5,1,1,1,$ioutarray->get_dataref,$status);
$fptr->write_col_lng(6,1,1,1,$joutarray->get_dataref,$status);
$fptr->write_col_flt(7,1,1,1,$eoutarray->get_dataref,$status);
$fptr->write_col_dbl(8,1,1,1,$doutarray->get_dataref,$status);

for ($ii=2;$ii<=20;$ii++) {
	$inskey->[0] = $iskey;
	$inskey->[0] = substr($inskey->[0],0,$ii);
	$fptr->write_col_str(1,$ii,1,1,$inskey,$status);

	$fptr->write_col_log(2,$ii,1,$ii,$larray->get_dataref,$status);
	$fptr->write_col_null(2,$ii,$ii-1,1,$status);

	$fptr->write_col_bit(3,$ii,1,$ii,$larray->get_dataref,$status);

	$fptr->write_col_byt(4,$ii,1,$ii,$boutarray->get_dataref,$status);
	$fptr->write_col_null(4,$ii,$ii-1,1,$status);

	$fptr->write_col_sht(5,$ii,1,$ii,$ioutarray->get_dataref,$status);
	$fptr->write_col_null(5,$ii,$ii-1,1,$status);

	$fptr->write_col_lng(6,$ii,1,$ii,$joutarray->get_dataref,$status);
	$fptr->write_col_null(6,$ii,$ii-1,1,$status);

	$fptr->write_col_flt(7,$ii,1,$ii,$eoutarray->get_dataref,$status);
	$fptr->write_col_null(7,$ii,$ii-1,1,$status);

	$fptr->write_col_dbl(8,$ii,1,$ii,$doutarray->get_dataref,$status);
	$fptr->write_col_null(8,$ii,$ii-1,1,$status);
}
print "ffpcl_ status = $status\n";

#################################
#  close then reopen this HDU   #
#################################

$fptr->movrel_hdu(-1,$hdutype,$status);
$fptr->movrel_hdu(1,$hdutype,$status);

#############################
#  read data from columns   #
#############################

$fptr->read_key_lng('PCOUNT',$pcount,$comm,$status);
print "PCOUNT = $pcount\n";

$inskey->[0] = ' ';
$iskey = ' ';

print "HDU number = ${\($fptr->get_hdu_num($hdunum))}\n";
for ($ii=1;$ii<=20;$ii++) {
	$larray = zeroes($types{TBYTE()}, $ii);
	$boutarray = zeroes($types{TBYTE()}, $ii);
	$ioutarray = zeroes($types{TSHORT()}, $ii);
	$joutarray = zeroes($types{TLONG()}, $ii);
	$eoutarray = zeroes(float, $ii);
	$doutarray = zeroes(double, $ii);

	$fptr->read_col_str(1,$ii,1,1,$iskey,$inskey,$anynull,$status);
	print "A $inskey->[0] $status\nL";

	$fptr->read_col_log(2,$ii,1,$ii,0,${$larray->get_dataref},$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $larray->at($_);
	}
	print " $status\nX";

	$fptr->read_col_bit(3,$ii,1,$ii,${$larray->get_dataref},$status);
	foreach (0..$ii-1) {
		printf " %2d", $larray->at($_);
	}
	print " $status\nB";


	$fptr->read_col_byt(4,$ii,1,$ii,99,${$boutarray->get_dataref},$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $boutarray->at($_);
	}
	print " $status\nI";

	$fptr->read_col_sht(5,$ii,1,$ii,99,${$ioutarray->get_dataref},$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $ioutarray->at($_);
	}
	print " $status\nJ";


	$fptr->read_col_lng(6,$ii,1,$ii,99,${$joutarray->get_dataref},$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $joutarray->at($_);
	}
	print " $status\nE";

	$fptr->read_col_flt(7,$ii,1,$ii,99,${$eoutarray->get_dataref},$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2.0f", $eoutarray->at($_);
	}
	print " $status\nD";

	$fptr->read_col_dbl(8,$ii,1,$ii,99,${$doutarray->get_dataref},$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2.0f", $doutarray->at($_);
	}
	print " $status\n";

	$fptr->read_descript(8,$ii,$repeat,$offset,$status);
	print "Column 8 repeat and offset = $repeat $offset\n";
}

#####################################
#  create another image extension   #
#####################################

$bitpix=32;
$naxis=2;
$naxes=[10,2];
$npixels=20;

$fptr->insert_img($bitpix,$naxis,$naxes,$status);
print "\nffcrim status = $status\n";

@tmp = map(($_*2),(0..$npixels-1));
$boutarray = pdl(\@tmp)->$tbyte;
$ioutarray = pdl(\@tmp)->$tshort;
$koutarray = pdl(\@tmp)->$tint;
$joutarray = pdl(\@tmp)->$tlong;
$eoutarray = float \@tmp;
$doutarray = double \@tmp;

$fptr->write_img(TBYTE, 1, 2, $boutarray->slice('0:1')->get_dataref, $status);
$fptr->write_img(TSHORT, 3, 2,$ioutarray->slice('2:3')->get_dataref, $status);
$fptr->write_img(TINT, 5, 2, $koutarray->slice('4:5')->get_dataref, $status);
$fptr->write_img(TSHORT, 7, 2, $ioutarray->slice('6:7')->get_dataref, $status);
$fptr->write_img(TLONG, 9, 2, $joutarray->slice('8:9')->get_dataref, $status);
$fptr->write_img(TFLOAT, 11, 2, $eoutarray->slice('10:11')->get_dataref, $status);
$fptr->write_img(TDOUBLE, 13, 2, $doutarray->slice('12:13')->get_dataref, $status);
print "ffppr status = $status\n";

$bnul=0;
$inul=0;
$knul=0;
$jnul=0;
$enul=0.0;
$dnul=0.0;

$fptr->read_img(TBYTE,1,14,$bnul,${$binarray->get_dataref},$anynull,$status);
$fptr->read_img(TSHORT,1,14,$inul,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_img(TINT,1,14,$knul,${$kinarray->get_dataref},$anynull,$status);
$fptr->read_img(TLONG,1,14,$jnul,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_img(TFLOAT,1,14,$enul,${$einarray->get_dataref},$anynull,$status);
$fptr->read_img(TDOUBLE,1,14,$dnul,${$dinarray->get_dataref},$anynull,$status);

print "\nImage values written with ffppr and read with ffgpv:\n";

$npixels=14;
foreach (0..$npixels-1) { printf " %2d", $binarray->at($_) }; print "  $anynull (byte)\n";
foreach (0..$npixels-1) { printf " %2d", $iinarray->at($_) }; print "  $anynull (short)\n";
foreach (0..$npixels-1) { printf " %2d", $kinarray->at($_) }; print "  $anynull (int)\n";
foreach (0..$npixels-1) { printf " %2d", $jinarray->at($_) }; print "  $anynull (long)\n";
foreach (0..$npixels-1) { printf " %2.0f", $einarray->at($_) }; print "  $anynull (float)\n";
foreach (0..$npixels-1) { printf " %2.0f", $dinarray->at($_) }; print "  $anynull (double)\n";

##########################################
#  test world coordinate system routines #
##########################################

$xrval=45.83;
$yrval=63.57;
$xrpix=256.0;
$yrpix=257.0;
$xinc =  -.00277777;
$yinc =   .00277777; 

$fptr->write_key_dbl('CRVAL1',$xrval,10,'comment',$status);
$fptr->write_key_dbl('CRVAL2',$yrval,10,'comment',$status);
$fptr->write_key_dbl('CRPIX1',$xrpix,10,'comment',$status);
$fptr->write_key_dbl('CRPIX2',$yrpix,10,'comment',$status);
$fptr->write_key_dbl('CDELT1',$xinc,10,'comment',$status);
$fptr->write_key_dbl('CDELT2',$yinc,10,'comment',$status);
$fptr->write_key_str('CTYPE1',$xcoordtype,'comment',$status);
$fptr->write_key_str('CTYPE2',$ycoordtype,'comment',$status);
print "\nWrote WCS keywords status = $status\n";

$xrval = 0;
$yrval = 0;
$xrpix = 0;
$yrpix = 0;
$xinc = 0;
$yinc = 0;
$rot = 0;

$fptr->read_img_coord($xrval,$yrval,$xrpix,$yrpix,$xinc,$yinc,$rot,$ctype,$status);
print "Read WCS keywords with ffgics status = $status\n";

$xpix = 0.5;
$ypix = 0.5;

fits_pix_to_world($xpix,$ypix,$xrval,$yrval,$xrpix,$yrpix,$xinc,$yinc,$rot,$ctype,$xpos,$ypos,$status);

printf "  CRVAL1, CRVAL2 = %16.12f, %16.12f\n", $xrval,$yrval;
printf "  CRPIX1, CRPIX2 = %16.12f, %16.12f\n", $xrpix,$yrpix;
printf "  CDELT1, CDELT2 = %16.12f, %16.12f\n", $xinc,$yinc;
printf "  Rotation = %10.3f, CTYPE = $ctype\n", $rot;
print "Calculated sky coordinate with ffwldp status = $status\n";
printf "  Pixels (%8.4f,%8.4f) --> (%11.6f, %11.6f) Sky\n",$xpix,$ypix,$xpos,$ypos;

fits_world_to_pix($xpos,$ypos,$xrval,$yrval,$xrpix,$yrpix,$xinc,$yinc,$rot,$ctype,$xpix,$ypix,$status);
print "Calculated pixel coordinate with ffxypx status = $status\n";
printf "  Sky (%11.6f, %11.6f) --> (%8.4f,%8.4f) Pixels\n",$xpos,$ypos,$xpix,$ypix;

######################################
#  append another ASCII table        #
######################################

$tform = [ qw( A15 I11 F15.6 E13.5 D22.14 ) ];
$ttype = [ qw( Name Ivalue Fvalue Evalue Dvalue ) ];
$tunit = [ ( '', 'm**2', 'cm', 'erg/s', 'km/s' ) ];

$nrows = 11;
$tfields = 5;
$tblname = 'new_table';

$fptr->create_tbl(ASCII_TBL,$nrows,$tfields,$ttype,$tform,$tunit,$tblname,$status);
print "\nffcrtb status = $status\n";

$extvers = 5;
$fptr->write_key_lng('EXTVER',$extvers,'extension version number',$status);

$fptr->write_col(TSTRING,1,1,1,3,$onskey,$status);

@tmp = map(($_*3),(0..$npixels-1));
$boutarray = pdl(\@tmp)->$tbyte;
$ioutarray = pdl(\@tmp)->$tshort;
$koutarray = pdl(\@tmp)->$tint;
$joutarray = pdl(\@tmp)->$tlong;
$eoutarray = float \@tmp;
$doutarray = double \@tmp;

for ($ii=2;$ii<6;$ii++) {
	$fptr->write_col(TBYTE,$ii,1,1,2,$boutarray->slice('0:1')->get_dataref,$status);
	$fptr->write_col(TSHORT,$ii,3,1,2,$ioutarray->slice('2:3')->get_dataref,$status);
	$fptr->write_col(TLONG,$ii,5,1,2,$joutarray->slice('4:5')->get_dataref,$status);
	$fptr->write_col(TFLOAT,$ii,7,1,2,$eoutarray->slice('6:7')->get_dataref,$status);
	$fptr->write_col(TDOUBLE,$ii,9,1,2,$doutarray->slice('8:9')->get_dataref,$status);
}
print "ffpcl status = $status\n";

$fptr->read_col(TBYTE,2,1,1,10,$bnul,${$binarray->get_dataref},$anynull,$status);
$fptr->read_col(TSHORT,2,1,1,10,$inul,${$iinarray->get_dataref},$anynull,$status);
$fptr->read_col(TINT,3,1,1,10,$knul,${$kinarray->get_dataref},$anynull,$status);
$fptr->read_col(TLONG,3,1,1,10,$jnul,${$jinarray->get_dataref},$anynull,$status);
$fptr->read_col(TFLOAT,4,1,1,10,$enul,${$einarray->get_dataref},$anynull,$status);
$fptr->read_col(TDOUBLE,5,1,1,10,$dnul,${$dinarray->get_dataref},$anynull,$status);

print "\nColumn values written with ffpcl and read with ffgcl:\n";
$npixels = 10;
foreach (0..$npixels-1) { printf " %2d",$binarray->at($_) }; print "  $anynull (byte)\n";
foreach (0..$npixels-1) { printf " %2d",$iinarray->at($_) }; print "  $anynull (short)\n";
foreach (0..$npixels-1) { printf " %2d",$kinarray->at($_) }; print "  $anynull (int)\n";
foreach (0..$npixels-1) { printf " %2d",$jinarray->at($_) }; print "  $anynull (long)\n";
foreach (0..$npixels-1) { printf " %2.0f",$einarray->at($_) }; print "  $anynull (float)\n";
foreach (0..$npixels-1) { printf " %2.0f",$dinarray->at($_) }; print "  $anynull (double)\n";

###########################################################
#  perform stress test by cycling thru all the extensions #
###########################################################

print "\nRepeatedly move to the 1st 4 HDUs of the file:\n";
for ($ii=0;$ii<10;$ii++) {
	$fptr->movabs_hdu(1,$hdutype,$status);
	print $fptr->get_hdu_num($hdunum);
	$fptr->movrel_hdu(1,$hdutype,$status);
	print $fptr->get_hdu_num($hdunum);
	$fptr->movrel_hdu(1,$hdutype,$status);
	print $fptr->get_hdu_num($hdunum);
	$fptr->movrel_hdu(1,$hdutype,$status);
	print $fptr->get_hdu_num($hdunum);
	$fptr->movrel_hdu(-1,$hdutype,$status);
	print $fptr->get_hdu_num($hdunum);
	$status and last;
}
print "\n";

print "Move to extensions by name and version number: (ffmnhd)\n";
$extvers=1;
$fptr->movnam_hdu(ANY_HDU,$binname,$extvers,$status);
$fptr->get_hdu_num($hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";

$extvers=3;
$fptr->movnam_hdu(ANY_HDU,$binname,$extvers,$status);
$fptr->get_hdu_num($hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";

$extvers=4;
$fptr->movnam_hdu(ANY_HDU,$binname,$extvers,$status);
$fptr->get_hdu_num($hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";


$tblname = 'Test-ASCII';
$extvers=2;
$fptr->movnam_hdu(ANY_HDU,$tblname,$extvers,$status);
$fptr->get_hdu_num($hdunum);
print " $tblname, $extvers = hdu $hdunum, $status\n";

$tblname = 'new_table';
$extvers=5;
$fptr->movnam_hdu(ANY_HDU,$tblname,$extvers,$status);
$fptr->get_hdu_num($hdunum);
print " $tblname, $extvers = hdu $hdunum, $status\n";

$extvers=0;
$fptr->movnam_hdu(ANY_HDU,$binname,$extvers,$status);
$fptr->get_hdu_num($hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";

$extvers=17;
$fptr->movnam_hdu(ANY_HDU,$binname,$extvers,$status);
$fptr->get_hdu_num($hdunum);
print " $binname, $extvers = hdu $hdunum, $status";

print " (expect a 301 error status here)\n";
$status = 0;

$fptr->get_num_hdus($hdunum,$status);
print "Total number of HDUs in the file = $hdunum\n";

########################
#  checksum tests      #
########################

$checksum=1234567890;
fits_encode_chksum($checksum,0,$asciisum);
print "\nEncode checksum: $checksum -> $asciisum\n";
$checksum = 0;
fits_decode_chksum($asciisum,0,$checksum);
print "Decode checksum: $asciisum -> $checksum\n";

$fptr->write_chksum($status);

$fptr->read_card('DATASUM',$card,$status);
printf "%.30s\n", $card;

$fptr->get_chksum($datsum,$checksum,$status);
print "ffgcks data checksum, status = $datsum, $status\n";

$fptr->verify_chksum($datastatus,$hdustatus,$status);
print "ffvcks datastatus, hdustatus, status = $datastatus $hdustatus $status\n";

$fptr->write_record("new_key = 'written by fxprec' / to change checksum",$status);
$fptr->update_chksum($status);
print "ffupck status = $status\n";

$fptr->read_card('DATASUM',$card,$status);
printf "%.30s\n", $card;
$fptr->verify_chksum($datastatus,$hdustatus,$status);
print "ffvcks datastatus, hdustatus, status = $datastatus $hdustatus $status\n";

$fptr->delete_key('CHECKSUM',$status);
$fptr->delete_key('DATASUM',$status);

############################
#  close file and quit     #
############################

ERRSTATUS: {
	$fptr->close_file($status);
	print "ffclos status = $status\n";

	print "\nNormally, there should be 8 error messages on the stack\n";
	print "all regarding 'numerical overflows':\n";

	fits_read_errmsg($errmsg);
	$nmsg = 0;
	while (length $errmsg) {
		printf " $errmsg\n";
		$nmsg++;
		fits_read_errmsg($errmsg);
	}

	if ($nmsg != 8) {
		print "\nWARNING: Did not find the expected 8 error messages!\n";
	}

	fits_get_errstatus($status,$errmsg);
	print "\nStatus = $status: $errmsg\n";

}

sub type_table {

  my %table;

  my (@pdl_types, @cfitsio_types);

  # unsigned type routines are not tested in this program, so we only
  # need to handle the signed types

  @pdl_types = (byte, short, long, longlong);
  @cfitsio_types = ( TBYTE, TSHORT, TINT, TLONG, TLONGLONG );

 CFITSIO_TYPES:
  for my $cfitsio_type ( @cfitsio_types ) {
    for my $ptype (@pdl_types) {
      howbig($ptype) == Astro::FITS::CFITSIO::sizeof_datatype($cfitsio_type)
	and $table{$cfitsio_type} = $ptype, next CFITSIO_TYPES;
    }

    die "could not find a matching PDL type for cfitsio type $cfitsio_type";
  }

  return %table;

}
