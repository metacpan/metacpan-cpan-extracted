use strict;

use vars qw( $OK_column $loaded $tests_ran $tests_failed );

BEGIN {
	$| = 1;
	$OK_column = 40;
 	$loaded = 0;
	$tests_ran = 0;
	$tests_failed = 0;

	sub pre_test {
		print $_[0],'.'x($OK_column-length($_[0])-1);
	}

	sub post_test {
		print $_[0] ? 'ok' : 'not ok',"\n";
		$tests_ran++;
		$tests_failed++ unless $_[0];
	}

	print "\n";
	pre_test('Loading'); # get this in before 'use Astro::FITS::CFISTIO'
}

use Astro::FITS::CFITSIO qw( :shortnames :constants PerlyUnpacking );
$loaded = 1;
post_test($loaded);

my $template = './testprog/testprog.tpt';

END {
	post_test(0) unless $loaded;
	summarize_tests();
	print <<EOP;

This is beta software, and the test suite is not yet complete.
You may find the scripts in ./testprog and ./examples of interest,
however.

EOP

}

sub summarize_tests {
	print <<EOP;

${\($tests_ran-$tests_failed)} / $tests_ran tests passed (${\(sprintf("%.1f",100*(1-$tests_failed/$tests_ran)))}%)

EOP

}

#
# compare two numeric arrays, returning true if they are identical
#
sub cmp_num_arrays {
	my ($r1,$r2) = @_;
	(@$r1 == @$r2) or return; # number of elements is not identical
	for (my $i=0; $i<@$r1; $i++) {
		($r1->[$i] == $r2->[$i]) or return;
	}
	return 1;
}

#
# compare two string arrays, returning true if they are identical
#
sub cmp_str_arrays {
	my ($r1,$r2) = @_;
	(@$r1 == @$r2) or return; # number of elements is not identical
	for (my $i=0; $i<@$r1; $i++) {
		($r1->[$i] eq $r2->[$i]) or return;
	}
	return 1;
}

my $status = 0;

# fits_get_keyname
my $name;
pre_test('ffgknm');
ffgknm("TESTING  'This is a test'",$name,undef,$status);
post_test($name eq 'TESTING');

# cfitsio version 2.100 or better?
pre_test('ffvers');
post_test(ffvers(undef) > 2.09);

# try to open non-existant file
pre_test('ffopen');
$status = 0;
my $fptr;
ffopen($fptr,'tq123x.kjl',READWRITE,$status);
print "\nSTATUS = $status\n";
post_test(104 == $status);

# fits_create_file
$status = 0;
pre_test('ffinit');
ffinit($fptr,'!testprog.fit',$status);
post_test(0 == $status);

# fits_file_name
pre_test('ffflnm');
my $filename;
ffflnm($fptr,$filename,$status);
post_test($filename eq 'testprog.fit');

# fits_file_mode
pre_test('ffflmd');
my $filemode;
ffflmd($fptr,$filemode,$status);
post_test(1 == $filemode);

my ($simple,$bitpix,$naxis,$naxes,$npixels,$pcount,$gcount,$extend) =
 (1,32,2,[10,2],20,0,1,1);

# fits_write_imghdr
pre_test('ffphps');
post_test(ffphps($fptr,$bitpix,$naxis,$naxes,$status) == 0);

# fits_write_record
pre_test('ffprec');
post_test(
	ffprec(
		$fptr,
		"key_prec= 'This keyword was written by fxprec' / comment goes here",
		$status
	) == 0
);

# fits_write_key_str
pre_test('ffpkys/ffgkey');
my $card =
	"1234567890123456789012345678901234567890" .
	"12345678901234567890123456789012345"; 
my $card2;
ffpkys($fptr,"card1",$card,"",$status);
ffgkey($fptr,'card1',$card2,undef,$status);
post_test($card2 eq q/'12345678901234567890123456789012345678901234567890123456789012345678'/);

pre_test('ffpkys/ffgkey');
$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234'6789012345"; 
ffpkys($fptr,'card2',$card,"",$status);
ffgkey($fptr,'card2',$card2,undef,$status);
post_test($card2 eq q/'1234567890123456789012345678901234567890123456789012345678901234''67'/);

pre_test('ffpkys/ffgkey');
$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234''789012345"; 
ffpkys($fptr,'card3',$card,"",$status);
ffgkey($fptr,'card3',$card2,undef,$status);
post_test($card2 eq q/'1234567890123456789012345678901234567890123456789012345678901234'''''/);

pre_test('ffpkys/ffgkey');
$card =
	"1234567890123456789012345678901234567890" .
	"123456789012345678901234567'9012345"; 
ffpkys($fptr,'card4',$card,"",$status);
ffgkey($fptr,'card4',$card2,undef,$status);
post_test($card2 eq q/'1234567890123456789012345678901234567890123456789012345678901234567'/);


#
# test writing of various types of keywords
#
my $oskey='value_string';
my $olkey=1;
my $ojkey=11;
my $otint = 12345678;
my $ofkey = 12.121212;
my $oekey = 13.131313;
my $ogkey = 14.1414141414141414;
my $odkey = 15.1515151515151515;
my $otfrac = 0.1234567890123456;
my $onekey = [13.131313, 14.141414, 15.151515];
my $ondkey = [15.1515151515151515, 16.1616161616161616,17.1717171717171717];

pre_test('ffpkys');
post_test(ffpkys($fptr,'key_pkys',$oskey,'fxpkys comment',$status) == 0);

pre_test('ffpkyl');
post_test(ffpkyl($fptr,'key_pkyl',$olkey,'fxpkyl comment',$status) == 0);

pre_test('ffpkyj');
post_test(ffpkyj($fptr,'key_pkyj',$ojkey,'fxpkyj comment',$status) == 0);

pre_test('ffpkyf');
post_test(ffpkyf($fptr,'key_pkyf',$ofkey,5,'fxpkyf comment',$status) == 0);

pre_test('ffpkye');
post_test(ffpkye($fptr,'key_pkye',$oekey,6,'fxpkye comment',$status) == 0);

pre_test('ffpkyg');
post_test(ffpkyg($fptr,'key_pkyg',$ogkey,14,'fxpkyg comment',$status) == 0);

pre_test('ffpkyd');
post_test(ffpkyd($fptr,'key_pkyd',$odkey,14,'fxpkyd comment',$status) == 0);

pre_test('ffpkyc');
post_test(ffpkyc($fptr,'key_pkyc',$onekey,6,'fxpkyc comment',$status) == 0);

pre_test('ffpkym');
post_test(ffpkym($fptr,'key_pkym',$ondkey,14,'fxpkym comment',$status) == 0);

pre_test('ffpkfc');
post_test(ffpkfc($fptr,'key_pkfc',$onekey,6,'fxpkfc comment',$status) == 0);

pre_test('ffpkfm');
post_test(ffpkfm($fptr,'key_pkfm',$ondkey,14,'fxpkfm comment',$status) == 0);

pre_test('ffpkls');
post_test(
	ffpkls(
		$fptr, 
		'key_pkls',
		'This is a very long string value that is continued over more than one keyword.',
		'fxpkls comment',
		$status,
	) == 0
);

pre_test('ffplsw');
post_test(ffplsw($fptr,$status) == 0);

pre_test('ffpkyt');
post_test(ffpkyt($fptr,'key_pkyt',$otint,$otfrac,'fxpkyt comment',$status)==0);

pre_test('ffpcom');
post_test(ffpcom($fptr,'This keyword was written by fxpcom.',$status) == 0);

pre_test('ffphis');
post_test(ffphis($fptr,"  This keyword written by fxphis (w/ 2 leading spaces).",$status) == 0);

pre_test('ffpdat');
post_test(ffpdat($fptr,$status) == 0);

my $onskey = [ 'first string', 'second string', '        ' ];
my $onlkey = [1,0,1]; 
my $onjkey = [11,12,13];
my $onfkey = [12.121212, 13.131313, 14.141414];
my $ongkey = [14.1414141414141414, 15.1515151515151515,16.1616161616161616];

my $nkeys = 3;

pre_test('ffpkns');
post_test(ffpkns($fptr,'ky_pkns',1,$nkeys,$onskey,'fxpkns comment&',$status) == 0);

pre_test('ffpknl');
post_test(ffpknl($fptr,'ky_pknl',1,$nkeys,$onlkey,'fxpknl comment&',$status) == 0);

pre_test('ffpknj');
post_test(ffpknj($fptr,'ky_pknj',1,$nkeys,$onjkey,'fxpknj comment&',$status) == 0);

pre_test('ffpknf');
post_test(ffpknf($fptr,'ky_pknf',1,$nkeys,$onfkey,5,'fxpknf comment&',$status) == 0);

pre_test('ffpkne');
post_test(ffpkne($fptr,'ky_pkne',1,$nkeys,$onekey,6,'fxpkne comment&',$status) == 0);

pre_test('ffpkng');
post_test(ffpkng($fptr,'ky_pkng',1,$nkeys,$ongkey,13,'fxpkng comment&',$status) == 0);

pre_test('ffpknd');
post_test(ffpknd($fptr,'ky_pknd',1,$nkeys,$ondkey,14,'fxpknd comment&',$status) == 0);

pre_test('ffpky/TSTRING');
$oskey = 1;
post_test(ffpky($fptr,TSTRING,'tstring',$oskey,'tstring comment',$status) == 0);

pre_test('ffpky/TLOGICAL');
$olkey = TLOGICAL;
post_test(ffpky($fptr,TLOGICAL,'tlogical',$olkey,'tlogical comment',$status) == 0);

pre_test('ffpky/TBYTE');
my $cval = TBYTE;
post_test(ffpky($fptr,TBYTE,'tbyte',$cval,'tbyte comment',$status) == 0);

pre_test('ffpky/TSHORT');
my $oshtkey = TSHORT;
post_test(ffpky($fptr,TSHORT,'tshort',$oshtkey,'tshort comment',$status) == 0);

pre_test('ffpky/TINT');
$olkey = TINT;
post_test(ffpky($fptr,TINT,'tint',$olkey,'tint comment',$status) == 0);

pre_test('ffpky/TLONG');
$ojkey = TLONG;
post_test(ffpky($fptr,TLONG,'tlong',$ojkey,'tlong comment',$status) == 0);

pre_test('ffpky/TFLOAT');
$oekey = TFLOAT;
post_test(ffpky($fptr,TFLOAT,'tfloat',$oekey,'tfloat comment',$status) == 0);

pre_test('ffpky/TDOUBLE');
$odkey = TDOUBLE;
post_test(ffpky($fptr,TDOUBLE,'tdouble',$odkey,'tdouble comment',$status) == 0);

pre_test('ffpkyj');
post_test(ffpkyj($fptr,'BLANK',-99,'value to use for undefined pixels',$status) == 0);

my $boutarray = [1..$npixels];
my $ioutarray = [1..$npixels];
my $joutarray = [1..$npixels];
my $eoutarray = [1..$npixels];
my $doutarray = [1..$npixels];

pre_test('ffpprX');
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
post_test($status == 0);

pre_test('ffflus');
ffflus($fptr,$status);
post_test($status == 0);

my $hdunum;
pre_test('ffghdn');
post_test(ffghdn($fptr,$hdunum) == 1);

my $standard = [qw(99 2 3 99 5 6 7 99 9 10 11 99 13 14 15 99 17 18 19 99)];
my $anynull = 0;

pre_test('ffpprb/ffgpvb');
my $binarray;
ffgpvb($fptr,1,1,$npixels,99,$binarray,$anynull,$status);
post_test(cmp_num_arrays($binarray,$standard) and $anynull == 1);

pre_test('ffppri/ffgpvi');
my $iinarray;
ffgpvi($fptr,1,1,$npixels,99,$iinarray,$anynull,$status);
post_test(cmp_num_arrays($iinarray,$standard) and $anynull == 1);

pre_test('ffpprj/ffgpvj');
my $jinarray;
ffgpvj($fptr,1,1,$npixels,99,$jinarray,$anynull,$status);
post_test(cmp_num_arrays($jinarray,$standard) and $anynull == 1);

pre_test('ffppre/ffgpve');
my $einarray;
ffgpve($fptr,1,1,$npixels,99,$einarray,$anynull,$status);
post_test(cmp_num_arrays($einarray,$standard) and $anynull == 1);

pre_test('ffpprd/ffgpvd');
my $dinarray;
ffgpvd($fptr,1,1,$npixels,99,$dinarray,$anynull,$status);
post_test(cmp_num_arrays($dinarray,$standard) and $anynull == 1);

@$boutarray = @$binarray;
@$ioutarray = @$iinarray;
@$joutarray = @$jinarray;
@$eoutarray = @$einarray;
@$doutarray = @$dinarray;

@$binarray = map(0,(0..$npixels-1));
@$iinarray = map(0,(0..$npixels-1));
@$jinarray = map(0,(0..$npixels-1));
@$einarray = map(0,(0..$npixels-1));
@$dinarray = map(0,(0..$npixels-1));

$anynull = 0;
$standard = [qw( *  2  3  *  5  6  7  *  9 10 11  * 13 14 15  * 17 18 19  * )];
my $larray;

pre_test('ffpprb/ffgpfb');
ffgpfb($fptr,1,1,$npixels,$binarray,$larray,$anynull,$status);
foreach (0..$#{$larray}) { $larray->[$_] and $binarray->[$_] = '*' }
post_test(cmp_str_arrays($binarray,$standard) and $anynull == 1);

pre_test('ffppri/ffgpfi');
ffgpfi($fptr,1,1,$npixels,$iinarray,$larray,$anynull,$status);
foreach (0..$#{$larray}) { $larray->[$_] and $iinarray->[$_] = '*' }
post_test(cmp_str_arrays($iinarray,$standard) and $anynull == 1);

pre_test('ffpprj/ffgpfj');
ffgpfj($fptr,1,1,$npixels,$jinarray,$larray,$anynull,$status);
foreach (0..$#{$larray}) { $larray->[$_] and $jinarray->[$_] = '*' }
post_test(cmp_str_arrays($jinarray,$standard) and $anynull == 1);

pre_test('ffppre/ffgpfe');
ffgpfe($fptr,1,1,$npixels,$einarray,$larray,$anynull,$status);
foreach (0..$#{$larray}) { $larray->[$_] and $einarray->[$_] = '*' }
post_test(cmp_str_arrays($einarray,$standard) and $anynull == 1);

pre_test('ffpprd/ffgpfd');
ffgpfd($fptr,1,1,$npixels,$dinarray,$larray,$anynull,$status);
foreach (0..$#{$larray}) { $larray->[$_] and $dinarray->[$_] = '*' }
post_test(cmp_str_arrays($dinarray,$standard) and $anynull == 1);

pre_test('ffclos/ffopen (10 times)');
my $ii;
for ($ii=0;$ii<10;$ii++) {
	ffclos($fptr,$status);
	ffopen($fptr,$filename,READWRITE,$status);
}
post_test($status == 0);

{
  # try assigning the filehandle elsewhere and seeing if it
  # still works
  pre_test("filehandle assign" );
  my $tfptr = $fptr;
  $tfptr->file_name( my $fname, $status );
  post_test( $status == 0 and $fname eq $filename );

  # this should cause $fptr to indicate it has been closed.
  pre_test( "filehandle assign close" );
  $tfptr->close_file( $status );
  post_test( $status == 0 and $fptr->_is_open == 0 );

  # reopen on fptr.  this should not call DESTROY on anything, as
  # tfptr should still point at the original file handle
  pre_test( "filehandle assign pass" );
  ffopen($fptr,$filename,READWRITE,$status);
  post_test( $status == 0 && $tfptr->_is_open == 0);

  # now, assign $fptr to $tfptr (DESTROYING $tfptr) and let $tfptr go
  # out of scope. this shouldn't destroy anything and thus shouldn't
  # affect $fptr
  pre_test( "filehandle assign" );
  $tfptr = $fptr;
  post_test( $status == 0 && $tfptr->_is_open == 1);
}

# we should still be able to do this.
pre_test("post assign DESTROY check");
$fptr->movabs_hdu(1,undef,$status);
post_test( $status == 0 );

pre_test('PerlyUnpacking set');
PerlyUnpacking(0);
post_test( PerlyUnpacking(-1) == PerlyUnpacking() &&
	   PerlyUnpacking(-1) == 0 );
PerlyUnpacking(1);

pre_test('fptr->perlyunpacking init');
post_test( $fptr->perlyunpacking == -1 );

pre_test('fptr->perlyunpacking == -1');
post_test( $fptr->PERLYUNPACKING == PerlyUnpacking() );

pre_test('fptr->perlyunpacking(0)');
$fptr->perlyunpacking(0);
post_test( $fptr->perlyunpacking == 0 && $fptr->PERLYUNPACKING == 0 );

pre_test('fptr->perlyunpacking(1)');
$fptr->perlyunpacking(1);
post_test( $fptr->perlyunpacking == 1 && $fptr->PERLYUNPACKING == 1 );

pre_test('fptr->perlyunpacking(-1)');
$fptr->perlyunpacking(-1);
post_test( $fptr->perlyunpacking == -1 
	   && $fptr->PERLYUNPACKING == PerlyUnpacking() );


pre_test('ffghdn');
post_test(ffghdn($fptr,$hdunum) == 1);

pre_test('ffflnm');
ffflnm($fptr,$filename,$status);
post_test($filename eq 'testprog.fit');

pre_test('ffflmd');
ffflmd($fptr,$filemode,$status);
post_test(1 == $filemode);

$simple = 0;
$bitpix = 0;
$naxis = 0;
$naxes = [0,0];
$pcount = -99;
$gcount = -99;
$extend = -99;

pre_test('ffghpr');
ffghpr($fptr,$simple,$bitpix,$naxis,$naxes,$pcount,$gcount,$extend,$status);
post_test(
	$status == 0 and
	$simple == 1 and
	$bitpix == 32 and
	$naxis == 2 and
	cmp_num_arrays($naxes,[10,2]) and
	$pcount == 0 and
	$gcount == 1 and
	$extend == 1
);

pre_test('ffgrec');
ffgrec($fptr,9,$card,$status);
post_test($card eq q!KEY_PREC= 'This keyword was written by fxprec' / comment goes here!);

pre_test('ffgkyn');
my ($keyword,$value,$comment);
ffgkyn($fptr,9,$keyword,$value,$comment,$status);
post_test(
	$keyword eq 'KEY_PREC' and
	$value eq q/'This keyword was written by fxprec'/ and
	$comment eq 'comment goes here'
);

pre_test('ffgcrd');
ffgcrd($fptr,$keyword,$card,$status);
post_test($card eq q!KEY_PREC= 'This keyword was written by fxprec' / comment goes here!);

pre_test('ffgkey');
ffgkey($fptr,'KY_PKNS1',$value,$comment,$status);
post_test( $value eq q!'first string'! and $comment eq 'fxpkns comment');

pre_test('ffgkys');
my $iskey;
ffgkys($fptr,'key_pkys',$iskey,$comment,$status);
post_test($iskey eq 'value_string' and $comment eq 'fxpkys comment');

pre_test('ffgkyl');
my $ilkey;
ffgkyl($fptr,'key_pkyl',$ilkey,$comment,$status);
post_test($ilkey ==1 and $comment eq 'fxpkyl comment');

pre_test('ffgkyj');
my $ijkey;
ffgkyj($fptr,'KEY_PKYJ',$ijkey,$comment,$status);
post_test($ijkey == 11 and $comment eq 'fxpkyj comment');

pre_test('ffgkye');
my $iekey;
ffgkye($fptr,'KEY_PKYJ',$iekey,$comment,$status);
post_test($iekey == 11.0 and $comment eq 'fxpkyj comment');

pre_test('ffgkyd');
my $idkey;
ffgkyd($fptr,'KEY_PKYJ',$idkey,$comment,$status);
post_test($idkey == 11 and $comment eq 'fxpkyj comment');

$iskey = '';
pre_test('ffgky/TSTRING');
ffgky($fptr,TSTRING,'key_pkys',$iskey,$comment,$status);
post_test($iskey eq 'value_string' and $comment eq 'fxpkys comment');

$ilkey = 0;
pre_test('ffgky/TLOGICAL');
ffgky($fptr,TLOGICAL,'key_pkyl',$ilkey,$comment,$status);
post_test($ilkey ==1 and $comment eq 'fxpkyl comment');

pre_test('ffgky/TBYTE');
ffgky($fptr,TBYTE,'key_pkyj',$cval,$comment,$status);
post_test($cval==11 and $comment eq 'fxpkyj comment');

my $ishtkey;
pre_test('ffgky/TSHORT');
ffgky($fptr,TSHORT,'key_pkyj',$ishtkey,$comment,$status);
post_test($ishtkey ==11 and $comment eq 'fxpkyj comment');

pre_test('ffgky/TINT');
ffgky($fptr,TINT,'key_pkyj',$ilkey,$comment,$status);
post_test($ilkey ==11 and $comment eq 'fxpkyj comment');

$ijkey=0;
pre_test('ffgky/TLONG');
ffgky($fptr,TLONG,'KEY_PKYJ',$ijkey,$comment,$status);
post_test($ijkey == 11 and $comment eq 'fxpkyj comment');

$iekey=0.0;
pre_test('ffgky/TFLOAT');
ffgky($fptr,TFLOAT,'KEY_PKYE',$iekey,$comment,$status);
post_test(sprintf("%f",$iekey) eq '13.131310' and $comment eq 'fxpkye comment');

$idkey=0.0;
pre_test('ffgky/TDOUBLE');
ffgky($fptr,TDOUBLE,'KEY_PKYD',$idkey,$comment,$status);
post_test(sprintf("%f",$idkey) eq '15.151515' and $comment eq 'fxpkyd comment');

pre_test('ffgkyd');
ffgkyd($fptr,'KEY_PKYF',$idkey,$comment,$status);
post_test(sprintf("%f",$idkey) eq '12.121210' and $comment eq 'fxpkyf comment');

pre_test('ffgkyd');
ffgkyd($fptr,'KEY_PKYE',$idkey,$comment,$status);
post_test(sprintf("%f",$idkey) eq '13.131310' and $comment eq 'fxpkye comment');

pre_test('ffgkyd');
ffgkyd($fptr,'KEY_PKYG',$idkey,$comment,$status);
post_test(sprintf("%.14f",$idkey) eq '14.14141414141414' and $comment eq 'fxpkyg comment');

my ($inekey,$indkey);

pre_test('ffgkyc');
ffgkyc($fptr,'KEY_PKYC',$inekey,$comment,$status);
post_test(
	sprintf("%f",$inekey->[0]) eq '13.131310' and
	sprintf("%f",$inekey->[1]) eq '14.141410' and
	$comment eq 'fxpkyc comment'
);

pre_test('ffgkyc');
ffgkyc($fptr,'KEY_PKFC',$inekey,$comment,$status);
post_test(
	sprintf("%f",$inekey->[0]) eq '13.131313' and
	sprintf("%f",$inekey->[1]) eq '14.141414' and
	$comment eq 'fxpkfc comment'
);

pre_test('ffgkym');
ffgkym($fptr,'KEY_PKYM',$indkey,$comment,$status);
post_test(
	sprintf("%f",$indkey->[0]) eq '15.151515' and
	sprintf("%f",$indkey->[1]) eq '16.161616' and
	$comment eq 'fxpkym comment'
);

pre_test('ffgkym');
ffgkym($fptr,'KEY_PKFM',$indkey,$comment,$status);
post_test(
	sprintf("%f",$indkey->[0]) eq '15.151515' and
	sprintf("%f",$indkey->[1]) eq '16.161616' and
	$comment eq 'fxpkfm comment'
);

pre_test('ffgkyt');
ffgkyt($fptr,'KEY_PKYT',$ijkey,$idkey,$comment,$status);
post_test(
	$ijkey == 12345678 and
	sprintf("%.14f",$idkey) eq '0.12345678901235' and
	$comment eq 'fxpkyt comment'
);

pre_test('ffpunt/ffgunt');
ffpunt($fptr,'KEY_PKYJ','km/s/Mpc',$status);
ffgunt($fptr,'KEY_PKYJ',$comment,$status);
post_test($comment eq 'km/s/Mpc');

pre_test('ffpunt/ffgunt');
ffpunt($fptr,'KEY_PKYJ','',$status);
ffgunt($fptr,'KEY_PKYJ',$comment,$status);
post_test($comment eq '');

pre_test('ffpunt/ffgunt');
ffpunt($fptr,'KEY_PKYJ','feet/second/second',$status);
ffgunt($fptr,'KEY_PKYJ',$comment,$status);
post_test($comment eq 'feet/second/second');

my $lsptr;
pre_test('ffgkls');
ffgkls($fptr,'key_pkls',$lsptr,$comment,$status);
post_test($lsptr eq q!This is a very long string value that is continued over more than one keyword.!);

pre_test('ffgkns');
my ($nfound,$inskey);
ffgkns($fptr,'ky_pkns',1,3,$inskey,$nfound,$status);
post_test(
	$nfound == 3 and
	cmp_str_arrays($inskey,[ 'first string', 'second string', ''])
);

pre_test('ffgknl');
my $inlkey;
ffgknl($fptr,'ky_pknl',1,3,$inlkey,$nfound,$status);
post_test(
	$nfound == 3 and
	cmp_num_arrays($inlkey,[1,0,1])
);

pre_test('ffgknj');
my $injkey;
ffgknj($fptr,'ky_pknj',1,3,$injkey,$nfound,$status);
post_test(
	$nfound == 3 and
	cmp_num_arrays($injkey,[11,12,13])
);

pre_test('ffgkne');
ffgkne($fptr,'ky_pkne',1,3,$inekey,$nfound,$status);
post_test(
	$nfound == 3 and
	sprintf("%f",$inekey->[0]) eq '13.131310' and
	sprintf("%f",$inekey->[1]) eq '14.141410' and
	sprintf("%f",$inekey->[2]) eq '15.151520'
);

pre_test('ffgknd');
ffgknd($fptr,'ky_pknd',1,3,$indkey,$nfound,$status);
post_test(
	$nfound == 3 and
	sprintf("%f",$indkey->[0]) eq '15.151515' and
	sprintf("%f",$indkey->[1]) eq '16.161616' and
	sprintf("%f",$indkey->[2]) eq '17.171717'
);

pre_test('ffgcrd/ffghps/ffgrec');
my ($existkeys,$keynum);
ffgcrd($fptr,'HISTORY',$card,$status);
ffghps($fptr,$existkeys,$keynum,$status);  
$keynum -= 2;
my @tmp;
for ($ii=$keynum; $ii<=$keynum+3;$ii++) {
	ffgrec($fptr,$ii,$card,$status);
	push @tmp, substr($card,0,8);
}
post_test(
	cmp_str_arrays(\@tmp,['COMMENT ','HISTORY ','DATE    ','KY_PKNS1'] )
);

pre_test('ffdrec/ffdkey');
@tmp = ();
ffdrec($fptr,$keynum+1,$status);      
ffdkey($fptr,'DATE',$status);
for ($ii=$keynum; $ii<=$keynum+1;$ii++) {
	ffgrec($fptr,$ii,$card,$status);  
	push @tmp,$card;
}
post_test(
	cmp_str_arrays(
		\@tmp,
		[
			q!COMMENT This keyword was written by fxpcom.!,
			q!KY_PKNS1= 'first string'       / fxpkns comment!
		]
	) and $status == 0
);

pre_test('ffirec/ffikyX');
$keynum += 4;
ffirec($fptr,$keynum-3,"KY_IREC = 'This keyword inserted by fxirec'",$status);
ffikys($fptr,'KY_IKYS',"insert_value_string", "ikys comment", $status);
ffikyj($fptr,'KY_IKYJ',49,"ikyj comment", $status);
ffikyl($fptr,'KY_IKYL',1, "ikyl comment", $status);
ffikye($fptr,'KY_IKYE',12.3456, 4, "ikye comment", $status);
ffikyd($fptr,'KY_IKYD',12.345678901234567, 14, "ikyd comment", $status);
ffikyf($fptr,'KY_IKYF',12.3456, 4, "ikyf comment", $status);
ffikyg($fptr,'KY_IKYG',12.345678901234567, 13, "ikyg comment", $status);
@tmp = ();
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) { 
	ffgrec($fptr,$ii,$card,$status);  
	push @tmp, $card;
}
post_test(
	cmp_str_arrays(
		\@tmp,
		[
			q!COMMENT This keyword was written by fxpcom.!,
			q!KY_IREC = 'This keyword inserted by fxirec'!,
			q!KY_IKYS = 'insert_value_string' / ikys comment!,
			q!KY_IKYJ =                   49 / ikyj comment!,
			q!KY_IKYL =                    T / ikyl comment!,
			q!KY_IKYE =           1.2346E+01 / ikye comment!,
			q!KY_IKYD = 1.23456789012346E+01 / ikyd comment!,
			q!KY_IKYF =              12.3456 / ikyf comment!,
			q!KY_IKYG =     12.3456789012346 / ikyg comment!,
			q!KY_PKNS1= 'first string'       / fxpkns comment!
		]
	) and $status == 0
);

pre_test('ffmrec/ffmcrd/ffmnam/ffmcom/ffmkyX');
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
@tmp = ();
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) {
	ffgrec($fptr,$ii,$card,$status);  
	push @tmp, $card;
}
post_test(
	cmp_str_arrays(
		\@tmp,
		[
			q!COMMENT   This keyword was modified by fxmrec!,
			q!KY_MREC = 'This keyword was modified by fxmcrd'!,
			q!NEWIKYS = 'modified_string'    / ikys comment!,
			q!KY_IKYJ =                   50 / This is a modified comment!,
			q!KY_IKYL =                    F / ikyl comment!,
			q!KY_IKYE =          -1.2346E+01 / ikye comment!,
			q!KY_IKYD = -1.23456789012346E+01 / modified comment!,
			q!KY_IKYF =             -12.3456 / ikyf comment!,
			q!KY_IKYG =    -12.3456789012346 / ikyg comment!,
			q!KY_PKNS1= 'first string'       / fxpkns comment!,
		]
	) and $status == 0
);

pre_test('ffucrd/ffukyX');
ffucrd($fptr,'KY_MREC',"KY_UCRD = 'This keyword was updated by fxucrd'",$status);
ffukyj($fptr,'KY_IKYJ',51,'&',$status);
ffukyl($fptr,'KY_IKYL',1,'&',$status); 
ffukys($fptr,'NEWIKYS',"updated_string",'&',$status);
ffukye($fptr,'KY_IKYE',-13.3456, 4,'&',$status);
ffukyd($fptr,'KY_IKYD',-13.345678901234567, 14,'modified comment',$status);
ffukyf($fptr,'KY_IKYF',-13.3456, 4,'&',$status);
ffukyg($fptr,'KY_IKYG',-13.345678901234567, 13,'&',$status);
@tmp=();
for ($ii=$keynum-4; $ii<=$keynum+5;$ii++) { 
	ffgrec($fptr,$ii,$card,$status);  
	push @tmp,$card;
}
post_test(
	cmp_str_arrays(
		\@tmp,
		[
			q!COMMENT   This keyword was modified by fxmrec!,
			q!KY_UCRD = 'This keyword was updated by fxucrd'!,
			q!NEWIKYS = 'updated_string'     / ikys comment!,
			q!KY_IKYJ =                   51 / This is a modified comment!,
			q!KY_IKYL =                    T / ikyl comment!,
			q!KY_IKYE =          -1.3346E+01 / ikye comment!,
			q!KY_IKYD = -1.33456789012346E+01 / modified comment!,
			q!KY_IKYF =             -13.3456 / ikyf comment!,
			q!KY_IKYG =    -13.3456789012346 / ikyg comment!,
			q!KY_PKNS1= 'first string'       / fxpkns comment!,
		]
	) and $status == 0
);


pre_test('ffgnxk');
ffgrec($fptr,0,$card,$status);
$nfound = 0;
@tmp = ();
my $inclist = [ 'key*', 'newikys' ];
my $exclist = [ 'key_pr*', 'key_pkls' ];   
while (!ffgnxk($fptr,$inclist,2,$exclist,2,$card,$status)) {
	$nfound++;
	push @tmp, $card;
}
post_test(
	$nfound == 13 and
	cmp_str_arrays(
		\@tmp,
		[
			q!KEY_PKYS= 'value_string'       / fxpkys comment!,
			q!KEY_PKYL=                    T / fxpkyl comment!,
			q!KEY_PKYJ=                   11 / [feet/second/second] fxpkyj comment!,
			q!KEY_PKYF=             12.12121 / fxpkyf comment!,
			q!KEY_PKYE=         1.313131E+01 / fxpkye comment!,
			q!KEY_PKYG=    14.14141414141414 / fxpkyg comment!,
			q!KEY_PKYD= 1.51515151515152E+01 / fxpkyd comment!,
			q!KEY_PKYC= (1.313131E+01, 1.414141E+01) / fxpkyc comment!,
			q!KEY_PKYM= (1.51515151515152E+01, 1.61616161616162E+01) / fxpkym comment!,
			q!KEY_PKFC= (13.131313, 14.141414) / fxpkfc comment!,
			q!KEY_PKFM= (15.15151515151515, 16.16161616161616) / fxpkfm comment!,
			q!KEY_PKYT= 12345678.1234567890123456 / fxpkyt comment!,
			q!NEWIKYS = 'updated_string'     / ikys comment!,
		]
	)
);
$status = 0;

pre_test('ffcpky');
ffcpky($fptr,$fptr,1,4,'KY_PKNE',$status); 
ffgkns($fptr,'ky_pkne',2,4,$inekey,$nfound,$status);
post_test(
	$status == 0 and
	sprintf("%f %f %f",@$inekey) eq '14.141410 15.151520 13.131310'
);

pre_test('ffpktp');
post_test( ffpktp($fptr,$template,$status) == 0);

my $tform = [ qw( 15A 1L 16X 1B 1I 1J 1E 1D 1C 1M ) ];
my $ttype = [ qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue ) ];
my $tunit = [ ( '', 'm**2', 'cm', 'erg/s', 'km/s', '', '', '', '', '') ];

my $nrows = 21;
my $tfields = 10;
$pcount = 0;

my $binname = 'Test-BINTABLE';
pre_test('ffibin');
post_test(
	ffibin($fptr,$nrows,$tfields,$ttype,$tform,$tunit,$binname,0,$status) == 0 and
	ffghdn($fptr,$hdunum) == 2
);

pre_test('ffghps');
ffghps($fptr,$existkeys,$keynum,$status);
post_test( $existkeys == 33 and $keynum == 1);

pre_test('ffhdef/ffghsp');
my $morekeys=40;
ffhdef($fptr,$morekeys,$status);
ffghsp($fptr,$existkeys,$morekeys,$status);
post_test( $existkeys == 33 and $morekeys == 74 );

fftnul($fptr,4,99,$status);
fftnul($fptr,5,99,$status);
fftnul($fptr,6,99,$status);

my $extvers=1;
ffpkyj($fptr,'EXTVER',$extvers,'extension version number', $status);
ffpkyj($fptr,'TNULL4',99,'value for undefined pixels',$status);
ffpkyj($fptr,'TNULL5',99,'value for undefined pixels',$status);
ffpkyj($fptr,'TNULL6',99,'value for undefined pixels',$status);

pre_test('ffptdm/ffgtdm');
$naxis=3;
$naxes=[1,2,8];
ffptdm($fptr,3,$naxis,$naxes,$status);
$naxis=0;
$naxes=undef;
ffgtdm($fptr,3,$naxis,$naxes,$status);
ffgkys($fptr,'TDIM3',$iskey,$comment,$status);
post_test(
	$iskey eq '(1,2,8)' and
	$naxis = 3 and
	cmp_num_arrays($naxes,[1,2,8])
);

ffrdef($fptr,$status);

my $signval = -1;
my $koutarray;
for ($ii=0;$ii<21;$ii++) {
    $signval *= -1;
    $boutarray->[$ii] = ($ii + 1);
    $ioutarray->[$ii] = ($ii + 1) * $signval;
    $joutarray->[$ii] = ($ii + 1) * $signval;
    $koutarray->[$ii] = ($ii + 1) * $signval;
    $eoutarray->[$ii] = ($ii + 1) * $signval;
    $doutarray->[$ii] = ($ii + 1) * $signval;
}

pre_test('ffpclX/ffpcnX');
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

post_test($status == 0);
 
pre_test('ffgcno/ffgcnn');
my (@tmp1,@tmp2,@tmp3);
my ($colnum,$colname);
ffgcno($fptr,0,'Xvalue',$colnum,$status);  
push @tmp1, $colnum;
push @tmp2, $status;
push @tmp3, 'Xvalue';
while ($status != COL_NOT_FOUND) {    
    ffgcnn($fptr,1,'*ue',$colname,$colnum,$status);
	push @tmp1, $colnum;
	push @tmp2, $status;
	push @tmp3, $colname;
}
post_test(
	cmp_num_arrays(\@tmp1,[3,1,2,3,4,5,6,7,8,9,10,0]) and
	cmp_num_arrays(\@tmp2,[0,237,237,237,237,237,237,237,237,237,237,219]) and
	cmp_str_arrays(\@tmp3,['Xvalue','Avalue','Lvalue','Xvalue','Bvalue','Ivalue','Jvalue','Evalue','Dvalue','Cvalue','Mvalue',''])
);
$status = 0;

pre_test('ffgtcl/ffgbcl');
@tmp1 = @tmp2 = @tmp3 = ();
my (@tmp4,@tmp5,@tmp6,@tmp7,@tmp8,@tmp9,@tmp10,@tmp11);
my ($typecode,$repeat,$width,$scale,$zero,$jnulval,$tdisp);
for ($ii=0;$ii<$tfields;$ii++) {
    ffgtcl($fptr,$ii+1,$typecode,$repeat,$width,$status);
	ffgbcl($fptr,$ii+1,$ttype->[0],$tunit->[0],$cval,$repeat,$scale,$zero,$jnulval,$tdisp,$status);

	push @tmp1,$typecode;
	push @tmp2,$repeat;
	push @tmp3,$width;
	push @tmp4,$ttype->[0];
	push @tmp5,$tunit->[0];
	push @tmp6,$cval;
	push @tmp7,$repeat;
	push @tmp8,$scale;
	push @tmp9,$zero;
	push @tmp10,$jnulval;
	push @tmp11,$tdisp;
}

post_test(
	cmp_num_arrays(\@tmp1,[16,14,1,11,21,41,42,82,83,163]) and
	cmp_num_arrays(\@tmp2,[15,1,16,1,1,1,1,1,1,1]) and
	cmp_num_arrays(\@tmp3,[15,1,1,1,2,4,4,8,8,16]) and
	cmp_str_arrays(\@tmp4,[qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue )]) and
	cmp_str_arrays(\@tmp5,['','m**2','cm','erg/s','km/s','','','','','']) and
	cmp_str_arrays(\@tmp6,[qw( A L X B I J E D C M )]) and
	cmp_num_arrays(\@tmp7,[15,1,16,1,1,1,1,1,1,1]) and
	cmp_num_arrays(\@tmp8,[map(1.0,(0..$tfields-1))]) and
	cmp_num_arrays(\@tmp9,[map(0.0,(0..$tfields-1))]) and
	cmp_num_arrays(\@tmp10,[1234554321,1234554321,1234554321,99,99,99,1234554321,1234554321,1234554321,1234554321]) and
	cmp_str_arrays(\@tmp11,[map('',(0..$tfields-1))])
);

pre_test('ffmrhd');
post_test(ffmrhd($fptr,-1,undef,$status) == 0);

$tform = [ qw( A15 I10 F14.6 E12.5 D21.14 ) ];
$ttype = [ qw( Name Ivalue Fvalue Evalue Dvalue ) ];
$tunit = [ ('','m**2','cm','erg/s','km/s') ];
my $rowlen = 76;
$nrows = 11;
$tfields = 5;

pre_test('ffitab');
my $tblname = 'Test-ASCII';
my $tbcol = [1,17,28,43,56];
ffitab($fptr,$rowlen,$nrows,$tfields,$ttype,$tbcol,$tform,$tunit,$tblname,$status);
post_test($status == 0 and ffghdn($fptr,$hdunum) == 2);


pre_test('ffsnul/ffpkyj');
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
post_test($status == 0);

for ($ii=0;$ii<21;$ii++) {
	$boutarray->[$ii] = $ii+1;
	$ioutarray->[$ii] = $ii+1;
	$joutarray->[$ii] = $ii+1;
	$eoutarray->[$ii] = $ii+1;
	$doutarray->[$ii] = $ii+1;
}  

pre_test('ffpclX');
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
post_test($status == 0);

pre_test('ffghtb');
my $extname;
ffghtb($fptr,$rowlen,$nrows,$tfields,$ttype,$tbcol,$tform,$tunit,$tblname,$status);
post_test(
	$rowlen == 76 and $nrows == 11 and $tfields == 5 and $tblname eq 'Test-ASCII' and
	cmp_str_arrays($ttype,[qw( Name Ivalue Fvalue Evalue Dvalue )]) and
	cmp_num_arrays($tbcol,[1,17,28,43,56]) and
	cmp_str_arrays($tform,[qw( A15 I10 F14.6 E12.5 D21.14 )])
);

$nrows=11;
pre_test('ffgcvX');
$inskey = $binarray = $iinarray = $jinarray = $einarray = $dinarray = undef;
ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcvj($fptr,3,1,1,$nrows,99,$jinarray,$anynull,$status);
ffgcve($fptr,4,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,5,1,1,$nrows,99,$dinarray,$anynull,$status);
post_test(
	cmp_str_arrays($inskey,['first string','second string',' ','UNDEFINED',' ',' ',' ',' ',' ',' ',' ']) and
	cmp_num_arrays($binarray,[1..10,99]) and
	cmp_num_arrays($iinarray,[1..10,99]) and
	cmp_num_arrays($jinarray,[1..10,99]) and
	cmp_num_arrays($einarray,[1..10,99]) and
	cmp_num_arrays($dinarray,[1..10,99])
);

pre_test('ffgtbb');
my $uchars;
ffgtbb($fptr,1,20,78,$uchars,$status);
ffptbb($fptr,1,20,78,$uchars,$status);
post_test(
	pack("C78",@$uchars) eq q!      1       1.000000  1.00000E+00  1.00000000000000E+00second string        !
);

pre_test('ffgcno/ffgcnn');
@tmp1=@tmp2=@tmp3=();
ffgcno($fptr,0,'name',$colnum,$status);
push @tmp1, 'name';
push @tmp2, $colnum;
push @tmp3, $status;
while ($status != COL_NOT_FOUND) {
	ffgcnn($fptr,0,'*ue',$colname,$colnum,$status);
	push @tmp1, $colname;
	push @tmp2, $colnum;
	push @tmp3, $status;
}
$status = 0;
post_test(
	cmp_str_arrays(\@tmp1,['name', 'Ivalue', 'Fvalue', 'Evalue', 'Dvalue','']) and
	cmp_num_arrays(\@tmp2,[1,2,3,4,5,0]) and
	cmp_num_arrays(\@tmp3,[0,237,237,237,237,219])
);

pre_test('ffgtcl/ffgacl');
my $nulstr;
@tmp1=@tmp2=@tmp3=@tmp4=@tmp5=@tmp6=@tmp7=@tmp8=@tmp9=@tmp10=@tmp11=();
for ($ii=0;$ii<$tfields;$ii++) {      
	ffgtcl($fptr,$ii+1,$typecode,$repeat,$width,$status);
	ffgacl($fptr,$ii+1,$ttype->[0],$tbcol,$tunit->[0],$tform->[0],$scale,$zero,$nulstr,$tdisp,$status);
	push @tmp1,$typecode;
	push @tmp2,$repeat;
	push @tmp3,$width;
	push @tmp4,$ttype->[0];
	push @tmp5,$tbcol;
	push @tmp6,$tunit->[0];
	push @tmp7,$tform->[0];
	push @tmp8,$scale;
	push @tmp9,$zero;
	push @tmp10,$nulstr;
	push @tmp11,$tdisp;
}
post_test(
	cmp_num_arrays(\@tmp1,[16,41,82,42,82]) and
	cmp_num_arrays(\@tmp2,[1,1,1,1,1]) and
	cmp_num_arrays(\@tmp3,[15,10,14,12,21]) and
	cmp_str_arrays(\@tmp4,[qw( Name Ivalue Fvalue Evalue Dvalue )]) and
	cmp_num_arrays(\@tmp5,[1,17,28,43,56]) and
	cmp_str_arrays(\@tmp6,['','m**2','cm','erg/s','km/s']) and
	cmp_str_arrays(\@tmp7,[qw( A15 I10 F14.6 E12.5 D21.14 )]) and
	cmp_num_arrays(\@tmp8,[map(1.0,(0..$tfields-1))]) and
	cmp_num_arrays(\@tmp9,[map(0.0,(0..$tfields-1))]) and
	cmp_str_arrays(\@tmp10,[map('null'.$_,(1..$tfields))]) and
	cmp_str_arrays(\@tmp11,[map('',(0..$tfields-1))])
);

pre_test('ffirow');
ffirow($fptr,2,3,$status);

$nrows=14;

$inskey=$binarray=$iinarray=$jinarray=$einarray=$dinarray=undef;
ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcvj($fptr,3,1,1,$nrows,99,$jinarray,$anynull,$status);
ffgcve($fptr,4,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,5,1,1,$nrows,99,$dinarray,$anynull,$status);

post_test(
	cmp_str_arrays($inskey,['first string','second string',' ',' ',' ',' ','UNDEFINED',map(' ',(0..6))]) and
	cmp_num_arrays($binarray,[1,2,0,0,0,3..10,99]) and
	cmp_num_arrays($iinarray,[1,2,0,0,0,3..10,99]) and
	cmp_num_arrays($jinarray,[1,2,0,0,0,3..10,99]) and
	cmp_num_arrays($einarray,[1,2,0,0,0,3..10,99]) and
	cmp_num_arrays($dinarray,[1,2,0,0,0,3..10,99])
);

pre_test('ffdrow');
ffdrow($fptr,10,2,$status);
$nrows=12;

$inskey=$binarray=$iinarray=$jinarray=$einarray=$dinarray=undef;
ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcvj($fptr,3,1,1,$nrows,99,$jinarray,$anynull,$status);
ffgcve($fptr,4,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,5,1,1,$nrows,99,$dinarray,$anynull,$status);

post_test(
	cmp_str_arrays($inskey,['first string','second string',' ',' ',' ',' ','UNDEFINED',map(' ',(0..4))]) and
	cmp_num_arrays($binarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($iinarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($jinarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($einarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($dinarray,[1,2,0,0,0,3..6,9..10,99])
);

pre_test('ffdcol');
ffdcol($fptr,3,$status);

$inskey=$binarray=$iinarray=$jinarray=$einarray=$dinarray=undef;
ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcve($fptr,3,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,4,1,1,$nrows,99,$dinarray,$anynull,$status);

post_test(
	cmp_str_arrays($inskey,['first string','second string',' ',' ',' ',' ','UNDEFINED',map(' ',(0..4))]) and
	cmp_num_arrays($binarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($iinarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($einarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($dinarray,[1,2,0,0,0,3..6,9..10,99])
);

pre_test('fficol');
fficol($fptr,5,'INSERT_COL','F14.6',$status);

$inskey=$binarray=$iinarray=$jinarray=$einarray=$dinarray=undef;
ffgcvs($fptr,1,1,1,$nrows,'UNDEFINED',$inskey,$anynull,$status);
ffgcvb($fptr,2,1,1,$nrows,99,$binarray,$anynull,$status);
ffgcvi($fptr,2,1,1,$nrows,99,$iinarray,$anynull,$status);
ffgcve($fptr,3,1,1,$nrows,99,$einarray,$anynull,$status);
ffgcvd($fptr,4,1,1,$nrows,99,$dinarray,$anynull,$status);
ffgcvj($fptr,5,1,1,$nrows,99,$jinarray,$anynull,$status);

post_test(
	cmp_str_arrays($inskey,['first string','second string',' ',' ',' ',' ','UNDEFINED',map(' ',(0..4))]) and
	cmp_num_arrays($binarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($iinarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($einarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($dinarray,[1,2,0,0,0,3..6,9..10,99]) and
	cmp_num_arrays($jinarray,[map(0,(0..$nrows-1))])
);


$bitpix=16;
$naxis=0;
$filename = '!t1q2s3v6.tmp';

pre_test('ffinit');
my $tmpfptr;
post_test(ffinit($tmpfptr,$filename,$status) == 0);

pre_test('ffiimg');
post_test(ffiimg($tmpfptr,$bitpix,$naxis,$naxes,$status) == 0);

$nrows=12;
$tfields=0;
$rowlen=0;

pre_test('ffitab');
ffitab($tmpfptr,$rowlen,$nrows,$tfields,$ttype,$tbcol,$tform,$tunit,$tblname,$status);
post_test($status == 0);

pre_test('ffcpcl');
ffcpcl($fptr,$tmpfptr,4,1,TRUE,$status);
ffcpcl($fptr,$tmpfptr,3,1,TRUE,$status);
ffcpcl($fptr,$tmpfptr,2,1,TRUE,$status);
ffcpcl($fptr,$tmpfptr,1,1,TRUE,$status);
post_test($status == 0);

pre_test('ffibin');
ffibin($tmpfptr,$nrows,$tfields,$ttype,$tform,$tunit,$tblname,0,$status);
post_test($status == 0);

pre_test('ffcpcl');
ffcpcl($fptr,$tmpfptr,4,1,TRUE,$status);
ffcpcl($fptr,$tmpfptr,3,1,TRUE,$status);
ffcpcl($fptr,$tmpfptr,2,1,TRUE,$status);
ffcpcl($fptr,$tmpfptr,1,1,TRUE,$status);
post_test($status == 0);

pre_test('ffdelt');
ffdelt($tmpfptr,$status);
post_test($status == 0);

pre_test('ffmrhd');
ffmrhd($fptr,1,undef,$status);
post_test($status == 0 and ffghdn($fptr,$hdunum) == 3);

pre_test('ffghsp');
ffghsp($fptr,$existkeys,$morekeys,$status);
post_test($existkeys == 38 and $morekeys == 69);

pre_test('ffghbn');
$tfields = $ttype = $tform = $tunit = $binname = undef;
ffghbn($fptr,$nrows,$tfields,$ttype,$tform,$tunit,$binname,$pcount,$status);
post_test(
	$nrows == 21 and $tfields == 10 and $binname eq 'Test-BINTABLE' and $pcount == 0 and
	cmp_str_arrays($ttype,[qw( Avalue Lvalue Xvalue Bvalue Ivalue Jvalue Evalue Dvalue Cvalue Mvalue )]) and
	cmp_str_arrays($tform,[qw( 15A 1L 16X 1B 1I 1J 1E 1D 1C 1M )]) and
	cmp_str_arrays($tunit,['','m**2','cm','erg/s','km/s','','','','',''])
);

pre_test('ffgcx');
@$larray = map(0,(0..39));
ffgcx($fptr,3,1,1,36,$larray,$status);
my $tmp = '';
for ($ii=0;$ii<5;$ii++) {
	foreach ($ii*8..$ii*8+7) { $tmp .= $larray->[$_] }
	$tmp .= ' ';
}
post_test($tmp eq '01001100 01110000 11110000 01111100 00000000 ');

my ($kinarray,$cinarray,$minarray,$xinarray);
@{$larray} = map(0,(0..$nrows-1));    
@{$xinarray} = map(0,(0..$nrows-1));  
@{$binarray} = map(0,(0..$nrows-1));  
@{$iinarray} = map(0,(0..$nrows-1));  
@{$kinarray} = map(0,(0..$nrows-1));  
@{$einarray} = map(0.0,(0..$nrows-1));
@{$dinarray} = map(0.0,(0..$nrows-1));
@{$cinarray} = map(0.0,(0..2*$nrows-1));
@{$minarray} = map(0.0,(0..2*$nrows-1));

pre_test('ffgcvs');
ffgcvs($fptr,1,4,1,1,'',$inskey,$anynull,$status);
post_test($inskey->[0] eq '');

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

