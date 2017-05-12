#!/usr/bin/perl
use strict;

use blib;
use Astro::FITS::CFITSIO qw( :shortnames :constants );

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
my $onlkey = [1,0,1];
my $onjkey = [11,12,13];
my $onfkey = [12.121212, 13.131313, 14.141414];
my $onekey = [13.131313, 14.141414, 15.151515];
my $ongkey = [14.1414141414141414, 15.1515151515151515,16.1616161616161616];
my $ondkey = [15.1515151515151515, 16.1616161616161616,17.1717171717171717];
my $tbcol = [1,17,28,43,56];
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

ffvers($version);

printf "CFITSIO TESTPROG, v%.3f\n\n",$version;

print "Try opening then closing a nonexistent file:\n";
$status=0;
ffopen($fptr,'tq123x.kjl',READWRITE,$status);
printf "  ffopen fptr, status  = %d %d (expect an error)\n",$fptr,$status;
eval {
	$status = 115; # cheat!!!
	ffclos($fptr,$status);
};
printf "  ffclos status = %d\n\n", $status;
ffcmsg();

$status=0;
ffinit($fptr,'!testprog.fit',$status);
print "ffinit create new file status = $status\n";
$status and goto ERRSTATUS;

ffflnm($fptr,$filename,$status);
ffflmd($fptr,$filemode,$status);
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

ffphps($fptr,$bitpix,$naxis,$naxes,$status) and
	print "ffphps status = $status";

ffprec(
	$fptr,
	"key_prec= 'This keyword was written by fxprec' / comment goes here",
	$status
) and printf"ffprec status = $status\n";

print "\ntest writing of long string keywords:\n";
$card =
	"1234567890123456789012345678901234567890" .
	"12345678901234567890123456789012345";
ffpkys($fptr,"card1",$card,"",$status);
ffgkey($fptr,'card1',$card2,$comment,$status);
print " $card\n$card2\n";

$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234'6789012345";
ffpkys($fptr,'card2',$card,"",$status);
ffgkey($fptr,'card2',$card2,$comment,$status);
print " $card\n$card2\n";

$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234''789012345";
ffpkys($fptr,'card3',$card,"",$status);
ffgkey($fptr,'card3',$card2,$comment,$status);
print " $card\n$card2\n";

$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234567'9012345";
ffpkys($fptr,'card4',$card,"",$status);
ffgkey($fptr,'card4',$card2,$comment,$status);
print " $card\n$card2\n";


ffpkys($fptr,'key_pkys',$oskey,'fxpkys comment',$status)
	and print "ffpkys status = $status\n";
ffpkyl($fptr,'key_pkyl',$olkey,'fxpkyl comment',$status)
	and print "ffpkyl status = $status\n";
ffpkyj($fptr,'key_pkyj',$ojkey,'fxpkyj comment',$status)
	and print "ffpkyj status = $status\n";
ffpkyf($fptr,'key_pkyf',$ofkey,5,'fxpkyf comment',$status)
	and print "ffpkyf status = $status\n";
ffpkye($fptr,'key_pkye',$oekey,6,'fxpkye comment',$status)
	and print "ffpkye status = $status\n";
ffpkyg($fptr,'key_pkyg',$ogkey,14,'fxpkyg comment',$status)
	and print "ffpkyg status = $status\n";
ffpkyd($fptr,'key_pkyd',$odkey,14,'fxpkyd comment',$status)
	and print "ffpkyd status = $status\n";
ffpkyc($fptr,'key_pkyc',$onekey,6,'fxpkyc comment',$status)
	and print "ffpkyc status = $status\n";
ffpkym($fptr,'key_pkym',$ondkey,14,'fxpkym comment',$status)
	and print "ffpkym status = $status\n";
ffpkfc($fptr,'key_pkfc',$onekey,6,'fxpkfc comment',$status)
	and print "ffpkfc status = $status\n";
ffpkfm($fptr,'key_pkfm',$ondkey,14,'fxpkfm comment',$status)
	and print "ffpkfm status = $status\n";
ffpkls(
	$fptr,
	'key_pkls',
	'This is a very long string value that is continued over more than one keyword.',
	'fxpkls comment',
	$status,
) and print "ffpkls status = $status\n";
ffplsw($fptr,$status)
	and print "ffplsw status = $status\n";
ffpkyt($fptr,'key_pkyt',$otint,$otfrac,'fxpkyt comment',$status)
	and print "ffpkyt status = $status\n";
ffpcom($fptr,'  This keyword was written by fxpcom.',$status)
	and print "ffpcom status = $status\n";
ffphis($fptr,"  This keyword written by fxphis (w/ 2 leading spaces).",$status)
	and print "ffphis status = $status\n";
ffpdat($fptr,$status) and print "ffpdat status = $status\n, goto ERRSTATUS";

############################
# write arrays of keywords #
############################
$nkeys = 3;

ffpkns($fptr,'ky_pkns',1,$nkeys,$onskey,'fxpkns comment&',$status)
	and print "ffpkns status = $status\n";
ffpknl($fptr,'ky_pknl',1,$nkeys,$onlkey,'fxpknl comment&',$status)
	and print "ffpknl status = $status\n";
ffpknj($fptr,'ky_pknj',1,$nkeys,$onjkey,'fxpknj comment&',$status)
	and print "ffpknj status = $status\n";
ffpknf($fptr,'ky_pknf',1,$nkeys,$onfkey,5,'fxpknf comment&',$status)
	and print "ffpknf status = $status\n";
ffpkne($fptr,'ky_pkne',1,$nkeys,$onekey,6,'fxpkne comment&',$status)
	and print "ffpkne status = $status\n";
ffpkng($fptr,'ky_pkng',1,$nkeys,$ongkey,13,'fxpkng comment&',$status)
	and print "ffpkng status = $status\n";
ffpknd($fptr,'ky_pknd',1,$nkeys,$ondkey,14,'fxpknd comment&',$status)
	and print "ffpknd status = $status\n",goto ERRSTATUS;

############################
#  write generic keywords  #
############################
$oskey = 1;
ffpky($fptr,TSTRING,'tstring',$oskey,'tstring comment',$status)
	and print "ffpky status = $status\n";
$olkey = TLOGICAL;
ffpky($fptr,TLOGICAL,'tlogical',$olkey,'tlogical comment',$status)
	and print "ffpky status = $status\n";
$cval = TBYTE;
ffpky($fptr,TBYTE,'tbyte',$cval,'tbyte comment',$status)
	and print "ffpky status = $status\n";
$oshtkey = TSHORT;
ffpky($fptr,TSHORT,'tshort',$oshtkey,'tshort comment',$status)
	and print "ffpky status = $status\n";
$olkey = TINT;
ffpky($fptr,TINT,'tint',$olkey,'tint comment',$status)
	and print "ffpky status = $status\n";
$ojkey = TLONG;
ffpky($fptr,TLONG,'tlong',$ojkey,'tlong comment',$status)
	and print "ffpky status = $status\n";
$oekey = TFLOAT;
ffpky($fptr,TFLOAT,'tfloat',$oekey,'tfloat comment',$status)
	and print "ffpky status = $status\n";
$odkey = TDOUBLE;
ffpky($fptr,TDOUBLE,'tdouble',$odkey,'tdouble comment',$status)
	and print "ffpky status = $status\n";


############################
#  write data              #
############################

ffpkyj($fptr,'BLANK',-99,'value to use for undefined pixels',$status)
	and print "BLANK keyword status = $status\n";

$boutarray = [1..$npixels];
$ioutarray = [1..$npixels];
$joutarray = [1..$npixels];
$eoutarray = [1..$npixels];
$doutarray = [1..$npixels];

ffpprb($fptr,1,1,2,[@{$boutarray}[0..1]],$status);
ffppri($fptr,1,5,2,[@{$ioutarray}[4..5]],$status);
ffpprj($fptr,1,9,2,[@{$joutarray}[8..9]],$status);
ffppre($fptr,1,13,2,[@{$eoutarray}[12..13]],$status);
ffpprd($fptr,1,17,2,[@{$doutarray}[16..17]],$status);
ffppnb($fptr,1,3,2,[@{$boutarray}[2..3]],4,$status);
ffppni($fptr,1,7,2,[@{$ioutarray}[6..7]],8,$status);
ffppnj($fptr,1,11,2,[@{$joutarray}[10..11]],12,$status);
ffppne($fptr,1,15,2,[@{$eoutarray}[14..15]],16,$status);
ffppnd($fptr,1,19,2,[@{$doutarray}[18..19]],20,$status);
ffppru($fptr,1,1,1,$status);
$status and  print "ffppnx status = $status\n", goto ERRSTATUS;

ffflus($fptr,$status);
print "ffflus status = $status\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

############################
#  read data               #
############################
print "\nValues read back from primary array (99 = null pixel)\n";
print "The 1st, and every 4th pixel should be undefined:\n";

$anynull = 0;
ffgpvb($fptr,1,1,$npixels,99,$binarray,$anynull,$status);
map printf(" %2d",$binarray->[$_]),(0..$npixels-1);
print "  $anynull (ffgpvb)\n";

ffgpvi($fptr,1,1,$npixels,99,$iinarray,$anynull,$status);
map printf(" %2d",$iinarray->[$_]),(0..$npixels-1);
print "  $anynull (ffgpvi)\n";

ffgpvj($fptr,1,1,$npixels,99,$jinarray,$anynull,$status);
map printf(" %2d",$jinarray->[$_]),(0..$npixels-1);
print "  $anynull (ffgpvj)\n";

ffgpve($fptr,1,1,$npixels,99,$einarray,$anynull,$status);
map printf(" %2.0f",$einarray->[$_]),(0..$npixels-1);
print "  $anynull (ffgpve)\n";

ffgpvd($fptr,1,1,$npixels,99,$dinarray,$anynull,$status);
map printf(" %2.0d",$dinarray->[$_]),(0..$npixels-1);
print "  $anynull (ffgpvd)\n";

$status and print("ERROR: ffgpv_ status = $status\n"), goto ERRSTATUS;
$anynull or print "ERROR: ffgpv_ did not detect null values\n";

for ($ii=3;$ii<$npixels;$ii+=4) {
	$boutarray->[$ii] = 99;
	$ioutarray->[$ii] = 99;
	$joutarray->[$ii] = 99;
	$eoutarray->[$ii] = 99.;
	$doutarray->[$ii] = 99.;
}
$ii=0;
$boutarray->[$ii] = 99;
$ioutarray->[$ii] = 99;
$joutarray->[$ii] = 99;
$eoutarray->[$ii] = 99.;
$doutarray->[$ii] = 99.;

for ($ii=0; $ii<$npixels;$ii++) {
	($boutarray->[$ii] != $binarray->[$ii]) and
		print "bout != bin = $boutarray->[$ii] $binarray->[$ii]\n";
	($ioutarray->[$ii] != $iinarray->[$ii]) and
		print "iout != iin = $ioutarray->[$ii] $iinarray->[$ii]\n";
	($joutarray->[$ii] != $jinarray->[$ii]) and
		print "jout != jin = $joutarray->[$ii] $jinarray->[$ii]\n";
	($eoutarray->[$ii] != $einarray->[$ii]) and
		print "eout != ein = $eoutarray->[$ii] $einarray->[$ii]\n";
	($doutarray->[$ii] != $dinarray->[$ii]) and
		print "dout != din = $doutarray->[$ii] $dinarray->[$ii]\n";
}

@$binarray = map(0,(0..$npixels-1));
@$iinarray = map(0,(0..$npixels-1));
@$jinarray = map(0,(0..$npixels-1));
@$einarray = map(0.0,(0..$npixels-1));
@$dinarray = map(0.0,(0..$npixels-1));


$anynull = 0;
ffgpfb($fptr,1,1,$npixels,$binarray,$larray,$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->[$ii]) { print "  *" }
	else { printf " %2d",$binarray->[$ii] }
}
print "  $anynull (ffgpfb)\n";

ffgpfi($fptr,1,1,$npixels,$iinarray,$larray,$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->[$ii]) { print "  *" }
	else { printf " %2d",$iinarray->[$ii] }
}
print "  $anynull (ffgpfi)\n";

ffgpfj($fptr,1,1,$npixels,$jinarray,$larray,$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->[$ii]) { print "  *" }
	else { printf " %2d",$jinarray->[$ii] }
}
print "  $anynull (ffgpfj)\n";

ffgpfe($fptr,1,1,$npixels,$einarray,$larray,$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->[$ii]) { print "  *" }
	else { printf " %2.0f",$einarray->[$ii] }
}
print "  $anynull (ffgpfe)\n";

ffgpfd($fptr,1,1,$npixels,$dinarray,$larray,$anynull,$status);
for ($ii=0;$ii<$npixels;$ii++) {
	if ($larray->[$ii]) { print "  *" }
	else { printf " %2.0f",$dinarray->[$ii] }
}
print "  $anynull (ffgpfd)\n";

$status and print("ERROR: ffgpf_ status = $status\n"), goto ERRSTATUS;
$anynull or print "ERROR: ffgpf_ did not detect null values\n";


##########################################
#  close and reopen file multiple times  #
##########################################

for ($ii=0;$ii<10;$ii++) {
	ffclos($fptr,$status) and
		print("ERROR in ftclos (1) = $status"), goto ERRSTATUS;
	ffopen($fptr,$filename,READWRITE,$status) and
		print("ERROR: ffopen open file status = $status\n"), goto ERRSTATUS;
}
print "\nClosed then reopened the FITS file 10 times.\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

$filename = "";
ffflnm($fptr,$filename,$status);
ffflmd($fptr,$filemode,$status);
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
ffghpr($fptr,$simple,$bitpix,$naxis,$naxes,$pcount,$gcount,$extend,$status);
print "simple = $simple, bitpix = $bitpix, naxis = $naxis, naxes = ($naxes->[0], $naxes->[1])\n";
print "  pcount = $pcount, gcount = $gcount, extend = $extend\n";

ffgrec($fptr,9,$card,$status);
print $card,"\n";
(substr($card,0,15) eq "KEY_PREC= 'This") or print "ERROR in ffgrec\n";

ffgkyn($fptr,9,$keyword,$value,$comment,$status);
print "$keyword : $value : $comment :\n";
($keyword eq 'KEY_PREC') or print "ERROR in ffgkyn: $keyword\n";

ffgcrd($fptr,$keyword,$card,$status);
print $card,"\n";
($keyword eq substr($card,0,8)) or print "ERROR in ffgcrd: $keyword\n";

ffgkey($fptr,'KY_PKNS1',$value,$comment,$status);
print "KY_PKNS1 : $value : $comment :\n";
(substr($value,0,14) eq "'first string'") or print "ERROR in ffgkey $value\n";

ffgkys($fptr,'key_pkys',$iskey,$comment,$status);
print "KEY_PKYS $iskey $comment $status\n";

ffgkyl($fptr,'key_pkyl',$ilkey,$comment,$status);
print "KEY_PKYL $ilkey $comment $status\n";

ffgkyj($fptr,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKYJ $ijkey $comment $status\n";

ffgkye($fptr,'KEY_PKYJ',$iekey,$comment,$status);
printf "KEY_PKYJ %f $comment $status\n",$iekey;

ffgkyd($fptr,'KEY_PKYJ',$idkey,$comment,$status);
printf "KEY_PKYJ %f $comment $status\n",$idkey;

($ijkey == 11 and $iekey == 11.0 and $idkey == 11.0) or
	printf "ERROR in ffgky[jed]: %d, %f, %f\n",$ijkey,$iekey,$idkey;

$iskey = "";
ffgky($fptr,TSTRING,'key_pkys',$iskey,$comment,$status);
print "KEY_PKY S $iskey $comment $status\n";

$ilkey = 0;
ffgky($fptr,TLOGICAL,'key_pkyl',$ilkey,$comment,$status);
print "KEY_PKY L $ilkey $comment $status\n";

ffgky($fptr,TBYTE,'KEY_PKYJ',$cval,$comment,$status);
print "KEY_PKY BYTE $cval $comment $status\n";

ffgky($fptr,TSHORT,'KEY_PKYJ',$ishtkey,$comment,$status);
print "KEY_PKY SHORT $ishtkey $comment $status\n";

ffgky($fptr,TINT,'KEY_PKYJ',$ilkey,$comment,$status);
print "KEY_PKY INT $ilkey $comment $status\n";

$ijkey=0;
ffgky($fptr,TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";

$iekey=0;
ffgky($fptr,TFLOAT,'KEY_PKYE',$iekey,$comment,$status);
printf "KEY_PKY E %f $comment $status\n",$iekey;

$idkey=0;
ffgky($fptr,TDOUBLE,'KEY_PKYD',$idkey,$comment,$status);
printf "KEY_PKY D %f $comment $status\n",$idkey;

ffgkyd($fptr,'KEY_PKYF',$idkey,$comment,$status);
printf "KEY_PKYF %f $comment $status\n",$idkey;

ffgkyd($fptr,'KEY_PKYE',$idkey,$comment,$status);
printf "KEY_PKYE %f $comment $status\n",$idkey;

ffgkyd($fptr,'KEY_PKYG',$idkey,$comment,$status);
printf "KEY_PKYG %.14f $comment $status\n",$idkey;

ffgkyd($fptr,'KEY_PKYD',$idkey,$comment,$status);
printf "KEY_PKYD %.14f $comment $status\n",$idkey;

ffgkyc($fptr,'KEY_PKYC',$inekey,$comment,$status);
printf "KEY_PKYC %f %f $comment $status\n",@$inekey;

ffgkyc($fptr,'KEY_PKFC',$inekey,$comment,$status);
printf "KEY_PKFC %f %f $comment $status\n",@$inekey;

ffgkym($fptr,'KEY_PKYM',$indkey,$comment,$status);
printf "KEY_PKYM %f %f $comment $status\n",@$indkey;

ffgkym($fptr,'KEY_PKFM',$indkey,$comment,$status);
printf "KEY_PKFM %f %f $comment $status\n",@$indkey;

ffgkyt($fptr,'KEY_PKYT',$ijkey,$idkey,$comment,$status);
printf "KEY_PKYT $ijkey %.14f $comment $status\n",$idkey;

ffpunt($fptr,'KEY_PKYJ',"km/s/Mpc",$status);
$ijkey=0;
ffgky($fptr,TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";
ffgunt($fptr,'KEY_PKYJ',$comment,$status);
print "KEY_PKY units = $comment\n";

ffpunt($fptr,'KEY_PKYJ','',$status);
$ijkey=0;
ffgky($fptr,TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";
ffgunt($fptr,'KEY_PKYJ',$comment,$status);
print "KEY_PKY units = $comment\n";

ffpunt($fptr,'KEY_PKYJ','feet/second/second',$status);
$ijkey=0;
ffgky($fptr,TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
print "KEY_PKY J $ijkey $comment $status\n";
ffgunt($fptr,'KEY_PKYJ',$comment,$status);
print "KEY_PKY units = $comment\n";

ffgkls($fptr,'key_pkls',$lsptr,$comment,$status);
print "KEY_PKLS long string value = \n$lsptr\n";

ffghps($fptr,$existkeys,$keynum,$status);
print "header contains $existkeys keywords; located at keyword $keynum \n";

############################
#  read array keywords     #
############################

ffgkns($fptr,'ky_pkns',1,3,$inskey,$nfound,$status);
print "ffgkns:  $inskey->[0], $inskey->[1], $inskey->[2]\n";
($nfound == 3 and $status == 0) or print "\nERROR in ffgkns $nfound, $status\n";

ffgknl($fptr,'ky_pknl',1,3,$inlkey,$nfound,$status);
print "ffgknl:  $inlkey->[0], $inlkey->[1], $inlkey->[2]\n";
($nfound == 3 and $status == 0) or print "\nERROR in ffgknl $nfound, $status\n";

ffgknj($fptr,'ky_pknj',1,3,$injkey,$nfound,$status);
print "ffgknj:  $injkey->[0], $injkey->[1], $injkey->[2]\n";
($nfound == 3 and $status == 0) or print "\nERROR in ffgknj $nfound, $status\n";

ffgkne($fptr,'ky_pkne',1,3,$inekey,$nfound,$status);
printf "ffgkne:  %f, %f, %f\n",@{$inekey};
($nfound == 3 and $status == 0) or print "\nERROR in ffgkne $nfound, $status\n";

ffgknd($fptr,'ky_pknd',1,3,$indkey,$nfound,$status);
printf "ffgknd:  %f, %f, %f\n",@{$indkey};
($nfound == 3 and $status == 0) or print "\nERROR in ffgknd $nfound, $status\n";

ffgcrd($fptr,'HISTORY',$card,$status);
ffghps($fptr,$existkeys,$keynum,$status);
$keynum -= 2;

print "\nBefore deleting the HISTORY and DATE keywords...\n";
for ($ii=$keynum; $ii<=$keynum+3;$ii++) {
	ffgrec($fptr,$ii,$card,$status);
	print substr($card,0,8),"\n";
}

############################
#  delete keywords         #
############################

ffdrec($fptr,$keynum+1,$status);
ffdkey($fptr,'DATE',$status);

print "\nAfter deleting the keywords...\n";
for ($ii=$keynum; $ii<=$keynum+1;$ii++) {
	ffgrec($fptr,$ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR deleting keywords\n";

############################
#  insert keywords         #
############################

$keynum += 4;
ffirec($fptr,$keynum-3,"KY_IREC = 'This keyword inserted by fxirec'",$status);
ffikys($fptr,'KY_IKYS',"insert_value_string", "ikys comment", $status);
ffikyj($fptr,'KY_IKYJ',49,"ikyj comment", $status);
ffikyl($fptr,'KY_IKYL',1, "ikyl comment", $status);
ffikye($fptr,'KY_IKYE',12.3456, 4, "ikye comment", $status);
ffikyd($fptr,'KY_IKYD',12.345678901234567, 14, "ikyd comment", $status);
ffikyf($fptr,'KY_IKYF',12.3456, 4, "ikyf comment", $status);
ffikyg($fptr,'KY_IKYG',12.345678901234567, 13, "ikyg comment", $status);

print "\nAfter inserting the keywords...\n";
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) {
	ffgrec($fptr,$ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR inserting keywords\n";

############################
#  modify keywords         #
############################

ffmrec($fptr,$keynum-4,'COMMENT   This keyword was modified by fxmrec', $status);
ffmcrd($fptr,'KY_IREC',"KY_MREC = 'This keyword was modified by fxmcrd'",$status);
ffmnam($fptr,'KY_IKYS','NEWIKYS',$status);
ffmcom($fptr,'KY_IKYJ','This is a modified comment', $status);
ffmkyj($fptr,'KY_IKYJ',50,'&',$status);
ffmkyl($fptr,'KY_IKYL',0,'&',$status);
ffmkys($fptr,'NEWIKYS','modified_string', '&', $status);
ffmkye($fptr,'KY_IKYE',-12.3456, 4, '&', $status);
ffmkyd($fptr,'KY_IKYD',-12.345678901234567, 14, 'modified comment', $status);
ffmkyf($fptr,'KY_IKYF',-12.3456, 4, '&', $status);
ffmkyg($fptr,'KY_IKYG',-12.345678901234567, 13, '&', $status);

print "\nAfter modifying the keywords...\n";
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) {
	ffgrec($fptr,$ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR modifying keywords\n";

############################
#  update keywords         #
############################

ffucrd($fptr,'KY_MREC',"KY_UCRD = 'This keyword was updated by fxucrd'",$status);

ffukyj($fptr,'KY_IKYJ',51,'&',$status);
ffukyl($fptr,'KY_IKYL',1,'&',$status);
ffukys($fptr,'NEWIKYS',"updated_string",'&',$status);
ffukye($fptr,'KY_IKYE',-13.3456, 4,'&',$status);
ffukyd($fptr,'KY_IKYD',-13.345678901234567, 14,'modified comment',$status);
ffukyf($fptr,'KY_IKYF',-13.3456, 4,'&',$status);
ffukyg($fptr,'KY_IKYG',-13.345678901234567, 13,'&',$status);

print "\nAfter updating the keywords...\n";
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) {
	ffgrec($fptr,$ii,$card,$status);
	print $card,"\n";
}

$status and print "ERROR modifying keywords\n";

ffgrec($fptr,0,$card,$status);

print "\nKeywords found using wildcard search (should be 13)...\n";
$nfound = 0;
while (!ffgnxk($fptr,$inclist,2,$exclist,2,$card,$status)) {
	$nfound++;
	print $card,"\n";
}
($nfound == 13) or print("\nERROR reading keywords using wildcards (ffgnxk)\n"), goto ERRSTATUS;

$status=0;

############################
#  copy index keyword      #
############################

ffcpky($fptr,$fptr,1,4,'KY_PKNE',$status);
ffgkns($fptr,'ky_pkne',2,4,$inekey,$nfound,$status);
printf "\nCopied keyword: ffgkne:  %f, %f, %f\n", @$inekey;

$status and print("\nERROR in ffgkne $nfound, $status\n"),goto ERRSTATUS;

######################################
#  modify header using template file #
######################################

ffpktp($fptr,$template,$status) and
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

ffibin($fptr,$nrows,$tfields,$ttype,$tform,$tunit,$binname,0,$status);
print "\nffibin status = $status\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

ffghps($fptr,$existkeys,$keynum,$status);
print "header contains $existkeys keywords; located at keyword $keynum \n";

$morekeys=40;
ffhdef($fptr,$morekeys,$status);
ffghsp($fptr,$existkeys,$morekeys,$status);
print "header contains $existkeys keywords with room for $morekeys more\n";

fftnul($fptr,4,99,$status);
fftnul($fptr,5,99,$status);
fftnul($fptr,6,99,$status);

$extvers=1;
ffpkyj($fptr,'EXTVER',$extvers,'extension version number', $status);
ffpkyj($fptr,'TNULL4',99,'value for undefined pixels',$status);
ffpkyj($fptr,'TNULL5',99,'value for undefined pixels',$status);
ffpkyj($fptr,'TNULL6',99,'value for undefined pixels',$status);

$naxis=3;
$naxes=[1,2,8];
ffptdm($fptr,3,$naxis,$naxes,$status);
$naxis=0;
$naxes=undef;
ffgtdm($fptr,3,$naxis,$naxes,$status);
ffgkys($fptr,'TDIM3',$iskey,$comment,$status);
print "TDIM3 = $iskey, $naxis, $naxes->[0], $naxes->[1], $naxes->[2]\n";

ffrdef($fptr,$status);

############################
#  write data to columns   #
############################

$signval = -1;
for ($ii=0;$ii<21;$ii++) {
	$signval *= -1;
	$boutarray->[$ii] = ($ii + 1);
	$ioutarray->[$ii] = ($ii + 1) * $signval;
	$joutarray->[$ii] = ($ii + 1) * $signval;
	$koutarray->[$ii] = ($ii + 1) * $signval;
	$eoutarray->[$ii] = ($ii + 1) * $signval;
	$doutarray->[$ii] = ($ii + 1) * $signval;
}

ffpcls($fptr,1,1,1,3,$onskey,$status);
ffpclu($fptr,1,4,1,1,$status);

$larray = [0,1,0,0,1,1,0,0,0,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0];
ffpclx($fptr,3,1,1,36,$larray,$status);

for ($ii=4;$ii<9;$ii++) {
	ffpclb($fptr,$ii,1,1,2,$boutarray,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcli($fptr,$ii,3,1,2,[@{$ioutarray}[2..3]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpclk($fptr,$ii,5,1,2,[@{$koutarray}[4..5]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcle($fptr,$ii,7,1,2,[@{$eoutarray}[6..7]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcld($fptr,$ii,9,1,2,[@{$doutarray}[8..9]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpclu($fptr,$ii,11,1,1,$status);
}

ffpclc($fptr,9,1,1,10,$eoutarray,$status);
ffpclm($fptr,10,1,1,10,$doutarray,$status);

for ($ii=4;$ii<9;$ii++) {
	ffpcnb($fptr,$ii,12,1,2,[@{$boutarray}[11..12]],13,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcni($fptr,$ii,14,1,2,[@{$ioutarray}[13..14]],15,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcnk($fptr,$ii,16,1,2,[@{$koutarray}[15..16]],17,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcne($fptr,$ii,18,1,2,[@{$eoutarray}[17..18]],19.,$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcnd($fptr,$ii,20,1,2,[@{$doutarray}[19..20]],21.,$status);
	($status == NUM_OVERFLOW) and $status = 0;
}
ffpcll($fptr,2,1,1,21,$larray,$status);
ffpclu($fptr,2,11,1,1,$status);
print "ffpcl_ status = $status\n";

#########################################
#  get information about the columns    #
#########################################

print "\nFind the column numbers; a returned status value of 237 is";
print "\nexpected and indicates that more than one column name matches";
print "\nthe input column name template.  Status = 219 indicates that";
print "\nthere was no matching column name.";

ffgcno($fptr,0,'Xvalue',$colnum,$status);
print "\nColumn Xvalue is number $colnum; status = $status.\n";

while ($status != COL_NOT_FOUND) {
	ffgcnn($fptr,1,'*ue',$colname,$colnum,$status);
	print "Column $colname is number $colnum; status = $status.\n";
}
$status = 0;

print "\nInformation about each column:\n";
for ($ii=0;$ii<$tfields;$ii++) {
	ffgtcl($fptr,$ii+1,$typecode,$repeat,$width,$status);
	printf("%4s %3d %2d %2d", $tform->[$ii], $typecode, $repeat, $width);
	ffgbcl($fptr,$ii+1,$ttype->[0],$tunit->[0],$cval,$repeat,$scale,$zero,$jnulval,$tdisp,$status);
	printf " $ttype->[0], $tunit->[0], $cval, $repeat, %f, %f, $jnulval, $tdisp.\n",$scale,$zero;
}
print "\n";

###############################################
#  insert ASCII table before the binary table #
###############################################

ffmrhd($fptr,-1,$hdutype,$status) and goto ERRSTATUS;

$tform = [ qw( A15 I10 F14.6 E12.5 D21.14 ) ];
$ttype = [ qw( Name Ivalue Fvalue Evalue Dvalue ) ];
$tunit = [ ('','m**2','cm','erg/s','km/s') ];
$rowlen = 76;
$nrows = 11;
$tfields = 5;

ffitab($fptr,$rowlen,$nrows,$tfields,$ttype,$tbcol,$tform,$tunit,$tblname,$status);
print "ffitab status = $status\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

ffsnul($fptr,1,'null1',$status);
ffsnul($fptr,2,'null2',$status);
ffsnul($fptr,3,'null3',$status);
ffsnul($fptr,4,'null4',$status);
ffsnul($fptr,5,'null5',$status);

$extvers=2;
ffpkyj($fptr,'EXTVER',$extvers,'extension version number',$status);
ffpkys($fptr,'TNULL1','null1','value for undefined pixels',$status);
ffpkys($fptr,'TNULL2','null2','value for undefined pixels',$status);
ffpkys($fptr,'TNULL3','null3','value for undefined pixels',$status);
ffpkys($fptr,'TNULL4','null4','value for undefined pixels',$status);
ffpkys($fptr,'TNULL5','null5','value for undefined pixels',$status);

$status and goto ERRSTATUS;

############################
#  write data to columns   #
############################

for ($ii=0;$ii<21;$ii++) {
	$boutarray->[$ii] = $ii+1;
	$ioutarray->[$ii] = $ii+1;
	$joutarray->[$ii] = $ii+1;
	$eoutarray->[$ii] = $ii+1;
	$doutarray->[$ii] = $ii+1;
}

ffpcls($fptr,1,1,1,3,$onskey,$status);
ffpclu($fptr,1,4,1,1,$status);

for ($ii=2;$ii<6;$ii++) {
	ffpclb($fptr,$ii,1,1,2,[@{$boutarray}[0..1]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcli($fptr,$ii,3,1,2,[@{$ioutarray}[2..3]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpclj($fptr,$ii,5,1,2,[@{$joutarray}[4..5]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcle($fptr,$ii,7,1,2,[@{$eoutarray}[6..7]],$status);
	($status == NUM_OVERFLOW) and $status = 0;
	ffpcld($fptr,$ii,9,1,2,[@{$doutarray}[8..9]],$status);
	($status == NUM_OVERFLOW) and $status = 0;

	ffpclu($fptr,$ii,11,1,1,$status);
}
print "ffpcl_ status = $status\n";

################################
#  read data from ASCII table  #
################################

ffghtb($fptr,$rowlen,$nrows,$tfields,$ttype,$tbcol,$tform,$tunit,$tblname,$status);

print "\nASCII table: rowlen, nrows, tfields, extname: $rowlen $nrows $tfields $tblname\n";
for ($ii=0;$ii<$tfields;$ii++) {
	printf "%8s %3d %8s %8s \n", $ttype->[$ii], $tbcol->[$ii], $tform->[$ii], $tunit->[$ii];
}

$nrows = 11;

ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcvj($fptr,3,1,1,$nrows,99,$jinarray,$anynull,$status);
ffgcve($fptr,4,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,5,1,1,$nrows,99,$dinarray,$anynull,$status);

print "\nData values read from ASCII table:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii], $jinarray->[$ii],
		$einarray->[$ii], $dinarray->[$ii]
	);
}

ffgtbb($fptr,1,20,78,$uchars,$status);
print "\n",pack("C78",@$uchars),"\n";
ffptbb($fptr,1,20,78,$uchars,$status);

#########################################
#  get information about the columns    #
#########################################

ffgcno($fptr,0,'name',$colnum,$status);
print "\nColumn name is number $colnum; status = $status.\n";

while ($status != COL_NOT_FOUND) {
	ffgcnn($fptr,0,'*ue',$colname,$colnum,$status);
	print "Column $colname is number $colnum; status = $status.\n";
}
$status = 0;

for ($ii=0;$ii<$tfields;$ii++) {
	ffgtcl($fptr,$ii+1,$typecode,$repeat,$width,$status);
	printf "%4s %3d %2d %2d", $tform->[$ii], $typecode, $repeat, $width;
	ffgacl($fptr,$ii+1,$ttype->[0],$tbcol,$tunit->[0],$tform->[0],$scale,
		$zero,$nulstr,$tdisp,$status);
	printf " $ttype->[0], $tbcol, $tunit->[0], $tform->[0], %f, %f, $nulstr, $tdisp.\n",
		$scale, $zero;
}
print "\n";

###############################################
#  test the insert/delete row/column routines #
###############################################

ffirow($fptr,2,3,$status) and goto ERRSTATUS;

$nrows = 14;

ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcvj($fptr,3,1,1,$nrows,99,$jinarray,$anynull,$status);
ffgcve($fptr,4,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,5,1,1,$nrows,99,$dinarray,$anynull,$status);

print "\nData values after inserting 3 rows after row 2:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii],
		$jinarray->[$ii], $einarray->[$ii], $dinarray->[$ii]
	);
}

ffdrow($fptr,10,2,$status) and goto ERRSTATUS;

$nrows = 12;

ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcvj($fptr,3,1,1,$nrows,99,$jinarray,$anynull,$status);
ffgcve($fptr,4,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,5,1,1,$nrows,99,$dinarray,$anynull,$status);

print "\nData values after deleting 2 rows at row 10:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii],
		$jinarray->[$ii], $einarray->[$ii], $dinarray->[$ii]
	);
}

ffdcol($fptr,3,$status) and goto ERRSTATUS;

ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcve($fptr,3,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,4,1,1,$nrows,99,$dinarray,$anynull,$status);

print "\nData values after deleting column 3:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %4.1f %4.1f\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii],
		$einarray->[$ii], $dinarray->[$ii]
	);
}

fficol($fptr,5,'INSERT_COL','F14.6',$status) and goto ERRSTATUS;

ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcve($fptr,3,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,4,1,1,$nrows,99,$dinarray,$anynull,$status);
ffgcvj($fptr,5,1,1,$nrows,99,$jinarray,$anynull,$status);

print "\nData values after inserting column 5:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf("%15s %2d %2d %4.1f %4.1f %d\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii],
		$einarray->[$ii], $dinarray->[$ii], $jinarray->[$ii],
	);
}

############################################################
#  create a temporary file and copy the ASCII table to it, #
#  column by column.                                       #
############################################################

$bitpix=16;
$naxis=0;
$filename = '!t1q2s3v6.tmp';
ffinit($tmpfptr,$filename,$status);
print "Create temporary file: ffinit status = $status\n";

ffiimg($tmpfptr,$bitpix,$naxis,$naxes,$status);
print "\nCreate null primary array: ffiimg status = $status\n";

$nrows=12;
$tfields=0;
$rowlen=0;

ffitab($tmpfptr,$rowlen,$nrows,$tfields,$ttype,$tbcol,$tform,$tunit,$tblname,$status);
print "\nCreate ASCII table with 0 columns: ffitab status = $status\n";

ffcpcl($fptr,$tmpfptr,4,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,3,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,2,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,1,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";

ffibin($tmpfptr,$nrows,$tfields,$ttype,$tform,$tunit,$tblname,0,$status);
print "\nCreate Binary table with 0 columns: ffibin status = $status\n";

ffcpcl($fptr,$tmpfptr,4,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,3,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,2,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,1,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";

ffdelt($tmpfptr,$status);
print "Delete the tmp file: ffdelt status = $status\n";

$status and goto ERRSTATUS;

################################
#  read data from binary table #
################################

ffmrhd($fptr,1,$hdutype,$status) and goto ERRSTATUS;
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

ffghsp($fptr,$existkeys,$morekeys,$status);
print "header contains $existkeys keywords with room for $morekeys more\n";

ffghbn($fptr,$nrows,$tfields,$ttype,$tform,$tunit,$binname,$pcount,$status);
print "\nBinary table: nrows, tfields, extname, pcount: $nrows $tfields $binname $pcount\n";

for ($ii=0;$ii<$tfields;$ii++) {
	printf "%8s %8s %8s \n", $ttype->[$ii], $tform->[$ii], $tunit->[$ii];
}

@$larray = map(0,(0..39));
print "\nData values read from binary table:\n";
printf "  Bit column (X) data values: \n\n";

ffgcx($fptr,3,1,1,36,$larray,$status);
for ($jj=0;$jj<5;$jj++) {
	print @{$larray}[$jj*8..$jj*8+7];
	print " ";
}

@{$larray} = map(0,(0..$nrows-1));
@{$xinarray} = map(0,(0..$nrows-1));
@{$binarray} = map(0,(0..$nrows-1));
@{$iinarray} = map(0,(0..$nrows-1));
@{$kinarray} = map(0,(0..$nrows-1));
@{$einarray} = map(0.0,(0..$nrows-1));
@{$dinarray} = map(0.0,(0..$nrows-1));
@{$cinarray} = map(0.0,(0..2*$nrows-1));
@{$minarray} = map(0.0,(0..2*$nrows-1));

print "\n\n";

ffgcvs($fptr,1,4,1,1,'',$inskey,$anynull,$status);
print "null string column value = -$inskey->[0]- (should be --)\n";

$nrows=21;
ffgcvs($fptr,1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
ffgcvl($fptr,2,1,1,$nrows,0,$larray,$anynull,$status);
ffgcvb($fptr,3,1,1,$nrows,98,$xinarray,$anynull,$status);
ffgcvb($fptr,4,1,1,$nrows,98,$binarray,$anynull,$status);
ffgcvi($fptr,5,1,1,$nrows,98,$iinarray,$anynull,$status);
ffgcvj($fptr,6,1,1,$nrows,98,$kinarray,$anynull,$status);
ffgcve($fptr,7,1,1,$nrows,98.,$einarray,$anynull,$status);
ffgcvd($fptr,8,1,1,$nrows,98.,$dinarray,$anynull,$status);
ffgcvc($fptr,9,1,1,$nrows,98.,$cinarray,$anynull,$status);
ffgcvm($fptr,10,1,1,$nrows,98.,$minarray,$anynull,$status);

print "\nRead columns with ffgcv_:\n";
for ($ii=0;$ii<$nrows;$ii++) {
	printf "%15s %d %3d %2d %3d %3d %5.1f %5.1f (%5.1f,%5.1f) (%5.1f,%5.1f) \n",
		$inskey->[$ii], $larray->[$ii], $xinarray->[$ii], $binarray->[$ii],
		$iinarray->[$ii],$kinarray->[$ii], $einarray->[$ii], $dinarray->[$ii],
		@{$cinarray->[$ii]}, @{$minarray->[$ii]};
}

@tmp = (0..$nrows-1);
@$larray = @tmp;
@$xinarray = @tmp;
@$binarray = @tmp;
@$iinarray = @tmp;
@$kinarray = @tmp;
@$einarray = @tmp;
@$dinarray = @tmp;
@tmp = (0..2*$nrows-1);
@$cinarray = @tmp;
@$minarray = @tmp;

ffgcfs($fptr,1,1,1,$nrows,$inskey,$larray2,$anynull,$status);
ffgcfl($fptr,2,1,1,$nrows,$larray,$larray2,$anynull,$status);
ffgcfb($fptr,3,1,1,$nrows,$xinarray,$larray2,$anynull,$status);
ffgcfb($fptr,4,1,1,$nrows,$binarray,,$larray2,$anynull,$status);
ffgcfi($fptr,5,1,1,$nrows,$iinarray,$larray2,$anynull,$status);
ffgcfk($fptr,6,1,1,$nrows,$kinarray,$larray2,$anynull,$status);
ffgcfe($fptr,7,1,1,$nrows,$einarray,$larray2,$anynull,$status);
ffgcfd($fptr,8,1,1,$nrows,$dinarray,$larray2,$anynull,$status);
ffgcfc($fptr,9,1,1,$nrows,$cinarray,$larray2,$anynull,$status);
ffgcfm($fptr,10,1,1,$nrows,$minarray,$larray2,$anynull,$status);

print "\nRead columns with ffgcf_:\n";
for ($ii=0;$ii<10;$ii++) {
	printf "%15s %d %3d %2d %3d %3d %5.1f %5.1f (%5.1f,%5.1f) (%5.1f,%5.1f)\n",
		$inskey->[$ii], $larray->[$ii], $xinarray->[$ii], $binarray->[$ii],
		$iinarray->[$ii], $kinarray->[$ii], $einarray->[$ii], $dinarray->[$ii],
		@{$cinarray->[$ii]}, @{$minarray->[$ii]};
}

for ($ii=10; $ii<$nrows;$ii++) {
	printf "%15s %d %3d %2d %3d \n",
		$inskey->[$ii], $larray->[$ii], $xinarray->[$ii], $binarray->[$ii],
		$iinarray->[$ii];
}
ffprec($fptr,"key_prec= 'This keyword was written by f_prec' / comment here", $status);

###############################################
#  test the insert/delete row/column routines #
###############################################

ffirow($fptr,2,3,$status) and goto ERRSTATUS;
$nrows=14;
ffgcvs($fptr,1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,4,1,1,$nrows,98,$binarray,$anynull,$status);
ffgcvi($fptr,5,1,1,$nrows,98,$iinarray,$anynull,$status);
ffgcvj($fptr,6,1,1,$nrows,98,$jinarray,$anynull,$status);
ffgcve($fptr,7,1,1,$nrows,98.,$einarray,$anynull,$status);
ffgcvd($fptr,8,1,1,$nrows,98.,$dinarray,$anynull,$status);

print "\nData values after inserting 3 rows after row 2:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %3d %5.1f %5.1f\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii], $jinarray->[$ii],
		$einarray->[$ii], $dinarray->[$ii];
}

ffdrow($fptr,10,2,$status) and goto ERRSTATUS;

$nrows=12;
ffgcvs($fptr,1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,4,1,1,$nrows,98,$binarray,$anynull,$status);
ffgcvi($fptr,5,1,1,$nrows,98,$iinarray,$anynull,$status);
ffgcvj($fptr,6,1,1,$nrows,98,$jinarray,$anynull,$status);
ffgcve($fptr,7,1,1,$nrows,98.,$einarray,$anynull,$status);
ffgcvd($fptr,8,1,1,$nrows,98.,$dinarray,$anynull,$status);

print "\nData values after deleting 2 rows at row 10:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %3d %5.1f %5.1f\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii], $jinarray->[$ii],
		$einarray->[$ii], $dinarray->[$ii];
}

ffdcol($fptr,6,$status) and goto ERRSTATUS;
ffgcvs($fptr,1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,4,1,1,$nrows,98,$binarray,$anynull,$status);
ffgcvi($fptr,5,1,1,$nrows,98,$iinarray,$anynull,$status);
ffgcve($fptr,6,1,1,$nrows,98.,$einarray,$anynull,$status);
ffgcvd($fptr,7,1,1,$nrows,98.,$dinarray,$anynull,$status);

print "\nData values after deleting column 6:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %5.1f %5.1f\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii], $einarray->[$ii],
		$dinarray->[$ii];
}

fficol($fptr,8,'INSERT_COL','1E',$status) and goto ERRSTATUS;
ffgcvs($fptr,1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,4,1,1,$nrows,98,$binarray,$anynull,$status);
ffgcvi($fptr,5,1,1,$nrows,98,$iinarray,$anynull,$status);
ffgcve($fptr,6,1,1,$nrows,98.,$einarray,$anynull,$status);
ffgcvd($fptr,7,1,1,$nrows,98.,$dinarray,$anynull,$status);
ffgcvj($fptr,8,1,1,$nrows,98,$jinarray,$anynull,$status);

print "\nData values after inserting column 8:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %5.1f %5.1f %d\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii], $einarray->[$ii],
		$dinarray->[$ii] , $jinarray->[$ii];
}


ffpclu($fptr,8,1,1,10,$status);
ffgcvs($fptr,1,1,1,$nrows,'NOT DEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,4,1,1,$nrows,98,$binarray,$anynull,$status);
ffgcvi($fptr,5,1,1,$nrows,98,$iinarray,$anynull,$status);
ffgcve($fptr,6,1,1,$nrows,98.,$einarray,$anynull,$status);
ffgcvd($fptr,7,1,1,$nrows,98.,$dinarray,$anynull,$status);
ffgcvj($fptr,8,1,1,$nrows,98,$jinarray,$anynull,$status);

print "\nValues after setting 1st 10 elements in column 8 = null:\n";
for ($ii = 0; $ii < $nrows; $ii++) {
	printf "%15s %2d %3d %5.1f %5.1f %d\n",
		$inskey->[$ii], $binarray->[$ii], $iinarray->[$ii], $einarray->[$ii],
		$dinarray->[$ii] , $jinarray->[$ii];
}

############################################################
#  create a temporary file and copy the binary table to it,#
#  column by column.                                       #
############################################################

$bitpix=16;
$naxis=0;
$filename = '!t1q2s3v5.tmp';
ffinit($tmpfptr,$filename,$status);
print "Create temporary file: ffinit status = $status\n";

ffiimg($tmpfptr,$bitpix,$naxis,$naxes,$status);
print "\nCreate null primary array: ffiimg status = $status\n";

$nrows=22;
$tfields=0;
ffibin($tmpfptr,$nrows,$tfields,$ttype,$tform,$tunit,$binname,0,$status);
print "\nCreate binary table with 0 columns: ffibin status = $status\n";

ffcpcl($fptr,$tmpfptr,7,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,6,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,5,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,4,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,3,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,2,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";
ffcpcl($fptr,$tmpfptr,1,1,TRUE,$status);
print "copy column, ffcpcl status = $status\n";

ffdelt($tmpfptr,$status);
print "Delete the tmp file: ffdelt status = $status\n";

$status and goto ERRSTATUS;

####################################################
#  insert binary table following the primary array #
####################################################

ffmahd($fptr,1,$hdutype,$status);
$tform = [ qw( 15A 1L 16X 1B 1I 1J 1E 1D 1C 1M ) ];
$ttype = [ qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue ) ];
$tunit = [ ( '', 'm**2', 'cm', 'erg/s', 'km/s', '', '', '', '', '' ) ];

$nrows=20;
$tfields=10;
$pcount=0;

ffibin($fptr,$nrows,$tfields,$ttype,$tform,$tunit,$binname,$pcount,$status);
print "ffibin status = $status\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

$extvers=3;
ffpkyj($fptr,'EXTVER',$extvers,'extension version number',$status);

ffpkyj($fptr,'TNULL4',77,'value for undefined pixels',$status);
ffpkyj($fptr,'TNULL5',77,'value for undefined pixels',$status);
ffpkyj($fptr,'TNULL6',77,'value for undefined pixels',$status);

ffpkyj($fptr,'TSCAL4',1000,'scaling factor',$status);
ffpkyj($fptr,'TSCAL5',1,'scaling factor',$status);
ffpkyj($fptr,'TSCAL6',100,'scaling factor',$status);

ffpkyj($fptr,'TZERO4',0,'scaling offset',$status);
ffpkyj($fptr,'TZERO5',32768,'scaling offset',$status);
ffpkyj($fptr,'TZERO6',100,'scaling offset',$status);

fftnul($fptr,4,77,$status);
fftnul($fptr,5,77,$status);
fftnul($fptr,6,77,$status);

fftscl($fptr,4,1000.,0.,$status);
fftscl($fptr,5,1.,32768.,$status);
fftscl($fptr,6,100.,100.,$status);

############################
#  write data to columns   #
############################

@$joutarray = (0,1000,10000,32768,65535);

for ($ii=4;$ii<7;$ii++) {
	ffpclj($fptr,$ii,1,1,5,$joutarray,$status);
	($status == NUM_OVERFLOW) and print("Overflow writing to column $ii\n"),$status=0;
	ffpclu($fptr,$ii,6,1,1,$status);
}

for ($jj=4;$jj<7;$jj++) {
	ffgcvj($fptr,$jj,1,1,6,-999,$jinarray,$anynull,$status);
	for ($ii=0;$ii<6;$ii++) {
		printf " %6d",$jinarray->[$ii];
	}
	print "\n";
}

print "\n";
fftscl($fptr,4,1.,0.,$status);
fftscl($fptr,5,1.,0.,$status);
fftscl($fptr,6,1.,0.,$status);

for ($jj=4;$jj<7;$jj++) {
	ffgcvj($fptr,$jj,1,1,6,-999,$jinarray,$anynull,$status);
	for ($ii=0;$ii<6;$ii++) {
		printf " %6d",$jinarray->[$ii];
	}
	print "\n";
}

######################################################
#  insert image extension following the binary table #
######################################################

$bitpix=-32;
$naxis=2;
$naxes=[15,25];
ffiimg($fptr,$bitpix,$naxis,$naxes,$status);
print "\nCreate image extension: ffiimg status = $status\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

for ($jj=0;$jj<30;$jj++) {
	for ($ii=0;$ii<19;$ii++) {
		$imgarray->[$jj]->[$ii] = ($ii<15) ? ($jj * 10) + $ii : 0;
	}
}

ffp2di($fptr,1,19,$naxes->[0],$naxes->[1],$imgarray,$status);
print "\nWrote whole 2D array: ffp2di status = $status\n";

for ($jj=0;$jj<30;$jj++) {
	@{$imgarray->[$jj]} = map(0,(0..18));
}

ffg2di($fptr,1,0,19,$naxes->[0],$naxes->[1],$imgarray,$anynull,$status);
print "\nRead whole 2D array: ffg2di status = $status\n";

for ($jj=0;$jj<30;$jj++) {
	@{$imgarray->[$jj]}[15..18] = (0,0,0,0);
	for ($ii=0;$ii<19;$ii++) {
		printf " %3d", $imgarray->[$jj]->[$ii];
	}
	print "\n";
}

for ($jj=0;$jj<30;$jj++) {
	@{$imgarray->[$jj]} = map(0,(0..18));
}

for ($jj=0;$jj<20;$jj++) {
	@{$imgarray2->[$jj]} = map(($jj * -10 - $_),(0..9));
}

$fpixels=[5,5];
$lpixels = [14,14];
ffpssi($fptr,1,$naxis,$naxes,$fpixels,$lpixels,$imgarray2,$status);
print "\nWrote subset 2D array: ffpssi status = $status\n";

ffg2di($fptr,1,0,19,$naxes->[0],$naxes->[1],$imgarray,$anynull,$status);
print "\nRead whole 2D array: ffg2di status = $status\n";

for ($jj=0;$jj<30;$jj++) {
	@{$imgarray->[$jj]}[15..18] = (0,0,0,0);
	for ($ii=0;$ii<19;$ii++) {
		printf " %3d", $imgarray->[$jj]->[$ii];
	}
	print "\n";
}

$fpixels = [2,5];
$lpixels = [10,8];
$inc = [2,3];

for ($jj=0;$jj<30;$jj++) {
	@{$imgarray->[$jj]} = map(0,(0..18));
}

ffgsvi($fptr,1,$naxis,$naxes,$fpixels,$lpixels,$inc,0,$imgarray->[0],$anynull,$status);
print "\nRead subset of 2D array: ffgsvi status = $status\n";

for ($ii=0;$ii<10;$ii++) {
	printf " %3d",$imgarray->[0]->[$ii];
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
ffiimg($fptr,$bitpix,$naxis,$naxes,$status);
print "\nCreate image extension: ffiimg status = $status\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

$filename = 't1q2s3v4.tmp';
ffinit($tmpfptr,$filename,$status);
print "Create temporary file: ffinit status = $status\n";

ffcopy($fptr,$tmpfptr,0,$status);
print "Copy image extension to primary array of tmp file.\n";
print "ffcopy status = $status\n";

ffgrec($tmpfptr,1,$card,$status);
print "$card\n";
ffgrec($tmpfptr,2,$card,$status);
print "$card\n";
ffgrec($tmpfptr,3,$card,$status);
print "$card\n";
ffgrec($tmpfptr,4,$card,$status);
print "$card\n";
ffgrec($tmpfptr,5,$card,$status);
print "$card\n";
ffgrec($tmpfptr,6,$card,$status);
print "$card\n";

ffdelt($tmpfptr,$status);
print "Delete the tmp file: ffdelt status = $status\n";

ffdhdu($fptr,$hdutype,$status);
print "Delete the image extension; hdutype, status = $hdutype $status\n";
print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";

###########################################################
#  append bintable extension with variable length columns #
###########################################################

ffcrhd($fptr,$status);
print "ffcrhd status = $status\n";

$tform = [ qw( 1PA 1PL 1PB 1PB 1PI 1PJ 1PE 1PD 1PC 1PM ) ];
$ttype = [ qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue ) ];
$tunit = [ ( '', 'm**2', 'cm', 'erg/s', 'km/s', '', '', '', '', '' ) ];

$nrows=20;
$tfields = 10;
$pcount=0;

ffphbn($fptr,$nrows,$tfields,$ttype,$tform,$tunit,$binname,$pcount,$status);
print "Variable length arrays: ffphbn status = $status\n";

$extvers=4;
ffpkyj($fptr,'EXTVER',$extvers,'extension version number',$status);

ffpkyj($fptr, 'TNULL4', 88, 'value for undefined pixels', $status);
ffpkyj($fptr, 'TNULL5', 88, 'value for undefined pixels', $status);
ffpkyj($fptr, 'TNULL6', 88, 'value for undefined pixels', $status);

############################
#  write data to columns   #
############################

$iskey = 'abcdefghijklmnopqrst';

@tmp = (1..20);
@{$boutarray} = @tmp;
@{$ioutarray} = @tmp;
@{$joutarray} = @tmp;
@{$eoutarray} = @tmp;
@{$doutarray} = @tmp;

$larray = [0,1,0,0,1,1,0,0,0,1,1,1,0,0,0,0,1,1,1,1];

$inskey=[''];
ffpcls($fptr,1,1,1,1,$inskey,$status);
ffpcll($fptr,2,1,1,1,$larray,$status);
ffpclx($fptr,3,1,1,1,$larray,$status);
ffpclb($fptr,4,1,1,1,$boutarray,$status);
ffpcli($fptr,5,1,1,1,$ioutarray,$status);
ffpclj($fptr,6,1,1,1,$joutarray,$status);
ffpcle($fptr,7,1,1,1,$eoutarray,$status);
ffpcld($fptr,8,1,1,1,$doutarray,$status);

for ($ii=2;$ii<=20;$ii++) {
	$inskey->[0] = $iskey;
	$inskey->[0] = substr($inskey->[0],0,$ii);
	ffpcls($fptr,1,$ii,1,1,$inskey,$status);

	ffpcll($fptr,2,$ii,1,$ii,$larray,$status);
	ffpclu($fptr,2,$ii,$ii-1,1,$status);

	ffpclx($fptr,3,$ii,1,$ii,$larray,$status);
	
	ffpclb($fptr,4,$ii,1,$ii,$boutarray,$status);
	ffpclu($fptr,4,$ii,$ii-1,1,$status);

	ffpcli($fptr,5,$ii,1,$ii,$ioutarray,$status);
	ffpclu($fptr,5,$ii,$ii-1,1,$status);

	ffpclj($fptr,6,$ii,1,$ii,$joutarray,$status);
	ffpclu($fptr,6,$ii,$ii-1,1,$status);

	ffpcle($fptr,7,$ii,1,$ii,$eoutarray,$status);
	ffpclu($fptr,7,$ii,$ii-1,1,$status);

	ffpcld($fptr,8,$ii,1,$ii,$doutarray,$status);
	ffpclu($fptr,8,$ii,$ii-1,1,$status);
}
print "ffpcl_ status = $status\n";

#################################
#  close then reopen this HDU   #
#################################

ffmrhd($fptr,-1,$hdutype,$status);
ffmrhd($fptr,1,$hdutype,$status);

#############################
#  read data from columns   #
#############################

ffgkyj($fptr,'PCOUNT',$pcount,$comm,$status);
print "PCOUNT = $pcount\n";

$inskey->[0] = ' ';
$iskey = ' ';

print "HDU number = ${\(ffghdn($fptr,$hdunum))}\n";
for ($ii=1;$ii<=20;$ii++) {
	@tmp = map(0,(0..$ii-1));
	@$larray = @tmp;
	@$boutarray = @tmp;
	@$ioutarray = @tmp;
	@$joutarray = @tmp;
	@$eoutarray = @tmp;
	@$doutarray = @tmp;

	ffgcvs($fptr,1,$ii,1,1,$iskey,$inskey,$anynull,$status);
	print "A $inskey->[0] $status\nL";

	ffgcvl($fptr,2,$ii,1,$ii,0,$larray,$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $larray->[$_];
	}
	print " $status\nX";

	ffgcx($fptr,3,$ii,1,$ii,$larray,$status);
	foreach (0..$ii-1) {
		printf " %2d", $larray->[$_];
	}
	print " $status\nB";

	ffgcvb($fptr,4,$ii,1,$ii,99,$boutarray,$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $boutarray->[$_];
	}
	print " $status\nI";

	ffgcvi($fptr,5,$ii,1,$ii,99,$ioutarray,$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $ioutarray->[$_];
	}
	print " $status\nJ";

	ffgcvj($fptr,6,$ii,1,$ii,99,$joutarray,$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2d", $joutarray->[$_];
	}
	print " $status\nE";

	ffgcve($fptr,7,$ii,1,$ii,99,$eoutarray,$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2.0f", $eoutarray->[$_];
	}
	print " $status\nD";

	ffgcvd($fptr,8,$ii,1,$ii,99,$doutarray,$anynull,$status);
	foreach (0..$ii-1) {
		printf " %2.0f", $doutarray->[$_];
	}
	print " $status\n";
	
	ffgdes($fptr,8,$ii,$repeat,$offset,$status);
	print "Column 8 repeat and offset = $repeat $offset\n";
}

#####################################
#  create another image extension   #
#####################################

$bitpix=32;
$naxis=2;
$naxes=[10,2];
$npixels=20;

ffiimg($fptr,$bitpix,$naxis,$naxes,$status);
print "\nffcrim status = $status\n";

@tmp = map(($_*2),(0..$npixels-1));
@$boutarray = @tmp;
@$ioutarray = @tmp;
@$joutarray = @tmp;
@$koutarray = @tmp;
@$eoutarray = @tmp;
@$doutarray = @tmp;

ffppr($fptr,TBYTE, 1, 2, [@{$boutarray}[0..1]], $status);
ffppr($fptr,TSHORT, 3, 2,[ @{$ioutarray}[2..3]], $status);
ffppr($fptr,TINT, 5, 2, [@{$koutarray}[4..5]], $status);
ffppr($fptr,TSHORT, 7, 2, [@{$ioutarray}[6..7]], $status);
ffppr($fptr,TLONG, 9, 2, [@{$joutarray}[8..9]], $status);
ffppr($fptr,TFLOAT, 11, 2, [@{$eoutarray}[10..11]], $status);
ffppr($fptr,TDOUBLE, 13, 2, [@{$doutarray}[12..13]], $status);
print "ffppr status = $status\n";

$bnul=0;
$inul=0;
$knul=0;
$jnul=0;
$enul=0.0;
$dnul=0.0;

ffgpv($fptr,TBYTE,1,14,$bnul,$binarray,$anynull,$status);
ffgpv($fptr,TSHORT,1,14,$inul,$iinarray,$anynull,$status);
ffgpv($fptr,TINT,1,14,$knul,$kinarray,$anynull,$status);
ffgpv($fptr,TLONG,1,14,$jnul,$jinarray,$anynull,$status);
ffgpv($fptr,TFLOAT,1,14,$enul,$einarray,$anynull,$status);
ffgpv($fptr,TDOUBLE,1,14,$dnul,$dinarray,$anynull,$status);

print "\nImage values written with ffppr and read with ffgpv:\n";

$npixels=14;
foreach (0..$npixels-1) { printf " %2d", $binarray->[$_] }; print "  $anynull (byte)\n";
foreach (0..$npixels-1) { printf " %2d", $iinarray->[$_] }; print "  $anynull (short)\n";
foreach (0..$npixels-1) { printf " %2d", $kinarray->[$_] }; print "  $anynull (int)\n";
foreach (0..$npixels-1) { printf " %2d", $jinarray->[$_] }; print "  $anynull (long)\n";
foreach (0..$npixels-1) { printf " %2.0f", $einarray->[$_] }; print "  $anynull (float)\n";
foreach (0..$npixels-1) { printf " %2.0f", $dinarray->[$_] }; print "  $anynull (double)\n";

##########################################
#  test world coordinate system routines #
##########################################

$xrval=45.83;
$yrval=63.57;
$xrpix=256.0;
$yrpix=257.0;
$xinc =  -.00277777;
$yinc =   .00277777; 

ffpkyd($fptr,'CRVAL1',$xrval,10,'comment',$status);
ffpkyd($fptr,'CRVAL2',$yrval,10,'comment',$status);
ffpkyd($fptr,'CRPIX1',$xrpix,10,'comment',$status);
ffpkyd($fptr,'CRPIX2',$yrpix,10,'comment',$status);
ffpkyd($fptr,'CDELT1',$xinc,10,'comment',$status);
ffpkyd($fptr,'CDELT2',$yinc,10,'comment',$status);
ffpkys($fptr,'CTYPE1',$xcoordtype,'comment',$status);
ffpkys($fptr,'CTYPE2',$ycoordtype,'comment',$status);
print "\nWrote WCS keywords status = $status\n";

$xrval = 0;
$yrval = 0;
$xrpix = 0;
$yrpix = 0;
$xinc = 0;
$yinc = 0;
$rot = 0;

ffgics($fptr,$xrval,$yrval,$xrpix,$yrpix,$xinc,$yinc,$rot,$ctype,$status);
print "Read WCS keywords with ffgics status = $status\n";

$xpix = 0.5;
$ypix = 0.5;

ffwldp($xpix,$ypix,$xrval,$yrval,$xrpix,$yrpix,$xinc,$yinc,$rot,$ctype,$xpos,$ypos,$status);

printf "  CRVAL1, CRVAL2 = %16.12f, %16.12f\n", $xrval,$yrval;
printf "  CRPIX1, CRPIX2 = %16.12f, %16.12f\n", $xrpix,$yrpix;
printf "  CDELT1, CDELT2 = %16.12f, %16.12f\n", $xinc,$yinc;
printf "  Rotation = %10.3f, CTYPE = $ctype\n", $rot;
print "Calculated sky coordinate with ffwldp status = $status\n";
printf "  Pixels (%8.4f,%8.4f) --> (%11.6f, %11.6f) Sky\n",$xpix,$ypix,$xpos,$ypos;

ffxypx($xpos,$ypos,$xrval,$yrval,$xrpix,$yrpix,$xinc,$yinc,$rot,$ctype,$xpix,$ypix,$status);
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

ffcrtb($fptr,ASCII_TBL,$nrows,$tfields,$ttype,$tform,$tunit,$tblname,$status);
print "\nffcrtb status = $status\n";

$extvers = 5;
ffpkyj($fptr,'EXTVER',$extvers,'extension version number',$status);

ffpcl($fptr,TSTRING,1,1,1,3,$onskey,$status);

@tmp = map(($_*3),(0..$npixels-1));
@$boutarray = @tmp;
@$ioutarray = @tmp;
@$joutarray = @tmp;
@$koutarray = @tmp;
@$eoutarray = @tmp;
@$doutarray = @tmp;

for ($ii=2;$ii<6;$ii++) {
	ffpcl($fptr,TBYTE,$ii,1,1,2,[@{$boutarray}[0..1]],$status);
	ffpcl($fptr,TSHORT,$ii,3,1,2,[@{$ioutarray}[2..3]],$status);
	ffpcl($fptr,TLONG,$ii,5,1,2,[@{$joutarray}[4..5]],$status);
	ffpcl($fptr,TFLOAT,$ii,7,1,2,[@{$eoutarray}[6..7]],$status);
	ffpcl($fptr,TDOUBLE,$ii,9,1,2,[@{$doutarray}[8..9]],$status);
}
print "ffpcl status = $status\n";

ffgcv($fptr,TBYTE,2,1,1,10,$bnul,$binarray,$anynull,$status);
ffgcv($fptr,TSHORT,2,1,1,10,$inul,$iinarray,$anynull,$status);
ffgcv($fptr,TINT,3,1,1,10,$knul,$kinarray,$anynull,$status);
ffgcv($fptr,TLONG,3,1,1,10,$jnul,$jinarray,$anynull,$status);
ffgcv($fptr,TFLOAT,4,1,1,10,$enul,$einarray,$anynull,$status);
ffgcv($fptr,TDOUBLE,5,1,1,10,$dnul,$dinarray,$anynull,$status);

print "\nColumn values written with ffpcl and read with ffgcl:\n";
$npixels = 10;
foreach (0..$npixels-1) { printf " %2d",$binarray->[$_] }; print "  $anynull (byte)\n";
foreach (0..$npixels-1) { printf " %2d",$iinarray->[$_] }; print "  $anynull (short)\n";
foreach (0..$npixels-1) { printf " %2d",$kinarray->[$_] }; print "  $anynull (int)\n";
foreach (0..$npixels-1) { printf " %2d",$jinarray->[$_] }; print "  $anynull (long)\n";
foreach (0..$npixels-1) { printf " %2.0f",$einarray->[$_] }; print "  $anynull (float)\n";
foreach (0..$npixels-1) { printf " %2.0f",$dinarray->[$_] }; print "  $anynull (double)\n";

###########################################################
#  perform stress test by cycling thru all the extensions #
###########################################################

print "\nRepeatedly move to the 1st 4 HDUs of the file:\n";
for ($ii=0;$ii<10;$ii++) {
	ffmahd($fptr,1,$hdutype,$status);
	print ffghdn($fptr,$hdunum);
	ffmrhd($fptr,1,$hdutype,$status);
	print ffghdn($fptr,$hdunum);
	ffmrhd($fptr,1,$hdutype,$status);
	print ffghdn($fptr,$hdunum);
	ffmrhd($fptr,1,$hdutype,$status);
	print ffghdn($fptr,$hdunum);
	ffmrhd($fptr,-1,$hdutype,$status);
	print ffghdn($fptr,$hdunum);
	$status and last;
}
print "\n";

print "Move to extensions by name and version number: (ffmnhd)\n";
$extvers=1;
ffmnhd($fptr,ANY_HDU,$binname,$extvers,$status);
ffghdn($fptr,$hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";

$extvers=3;
ffmnhd($fptr,ANY_HDU,$binname,$extvers,$status);
ffghdn($fptr,$hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";

$extvers=4;
ffmnhd($fptr,ANY_HDU,$binname,$extvers,$status);
ffghdn($fptr,$hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";


$tblname = 'Test-ASCII';
$extvers=2;
ffmnhd($fptr,ANY_HDU,$tblname,$extvers,$status);
ffghdn($fptr,$hdunum);
print " $tblname, $extvers = hdu $hdunum, $status\n";

$tblname = 'new_table';
$extvers=5;
ffmnhd($fptr,ANY_HDU,$tblname,$extvers,$status);
ffghdn($fptr,$hdunum);
print " $tblname, $extvers = hdu $hdunum, $status\n";

$extvers=0;
ffmnhd($fptr,ANY_HDU,$binname,$extvers,$status);
ffghdn($fptr,$hdunum);
print " $binname, $extvers = hdu $hdunum, $status\n";

$extvers=17;
ffmnhd($fptr,ANY_HDU,$binname,$extvers,$status);
ffghdn($fptr,$hdunum);
print " $binname, $extvers = hdu $hdunum, $status";

print " (expect a 301 error status here)\n";
$status = 0;

ffthdu($fptr,$hdunum,$status);
print "Total number of HDUs in the file = $hdunum\n";

########################
#  checksum tests      #
########################

$checksum=1234567890;
ffesum($checksum,0,$asciisum);
print "\nEncode checksum: $checksum -> $asciisum\n";
$checksum = 0;
ffdsum($asciisum,0,$checksum);
print "Decode checksum: $asciisum -> $checksum\n";

ffpcks($fptr,$status);

ffgcrd($fptr,'DATASUM',$card,$status);
printf "%.30s\n", $card;

ffgcks($fptr,$datsum,$checksum,$status);
print "ffgcks data checksum, status = $datsum, $status\n";

ffvcks($fptr,$datastatus,$hdustatus,$status);
print "ffvcks datastatus, hdustatus, status = $datastatus $hdustatus $status\n";

ffprec($fptr,"new_key = 'written by fxprec' / to change checksum",$status);
ffupck($fptr,$status);
print "ffupck status = $status\n";

ffgcrd($fptr,'DATASUM',$card,$status);
printf "%.30s\n", $card;
ffvcks($fptr,$datastatus,$hdustatus,$status);
print "ffvcks datastatus, hdustatus, status = $datastatus $hdustatus $status\n";

ffdkey($fptr,'CHECKSUM',$status);
ffdkey($fptr,'DATASUM',$status);

############################
#  close file and quit     #
############################

ERRSTATUS: {
	ffclos($fptr,$status);
	print "ffclos status = $status\n";

	print "\nNormally, there should be 8 error messages on the stack\n";
	print "all regarding 'numerical overflows':\n";

	ffgmsg($errmsg);
	$nmsg = 0;
	while (length $errmsg) {
		printf " $errmsg\n";
		$nmsg++;
		ffgmsg($errmsg);
	}

	if ($nmsg != 8) {
		print "\nWARNING: Did not find the expected 8 error messages!\n";
	}

	ffgerr($status,$errmsg);
	print "\nStatus = $status: $errmsg\n";

}
