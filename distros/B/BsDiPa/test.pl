#@ Automated test for S-bsdipa (make test).

#use Test::Simple tests => 1;
use Test2::API qw/context/;
our @EXPORT = qw/ok done_testing/;
sub ok($;$){
	my ($bool, $name) = @_;
	my $ctx = context();
	$ctx->ok($bool, $name);
	$ctx->release;
	return $bool
}
sub done_testing{
	my $ctx = context();
	$ctx->done_testing;
	$ctx->release
}

BEGIN {require BsDiPa}

use strict;
use diagnostics;
use Compress::Zlib;

## Core:

use BsDiPa;

#print BsDiPa::VERSION, "\n";
#print BsDiPa::CONTACT, "\n";
#print BsDiPa::COPYRIGHT;

# io_cookie's
our ($cJ,$cj,$cR,$cZ,$cz) = (undef,undef,undef,undef,undef);

sub doit{
	my ($t, $b, $a, $eq) = @_;

	$eq = (defined $eq && $eq != 0);
	my $iseq = 0;

	my ($pJ,$pj,$pR,$pZ,$pz, $rJ,$rj,$rR,$rZ,$rz) = (0,0,0,0,0, 0,0,0,0,0);

	ok(BsDiPa::core_diff_zlib(undef, $a, \$pz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, undef, \$pz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, $a, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_zlib($b, $a, $pz) eq BsDiPa::INVAL);
	BsDiPa::core_diff_level_set(3);
	ok(BsDiPa::core_diff_zlib($b, $a, \$pz, undef, undef, $cz) eq BsDiPa::OK);
	ok(defined $pz);
	BsDiPa::core_diff_level_set(0);
	ok(BsDiPa::core_diff_zlib($b, $a, \$pz, undef, $iseq, $cz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, $a, \$pz, undef, \$iseq, $cz) eq BsDiPa::OK);
	ok(defined $pz);
	ok($eq == $iseq);

	if(BsDiPa::HAVE_BZ2()){
		ok(BsDiPa::core_diff_bz2(undef, $a, \$pj) eq BsDiPa::INVAL);
		ok(!defined $pj);
		ok(BsDiPa::core_diff_bz2($b, undef, \$pj) eq BsDiPa::INVAL);
		ok(!defined $pj);
		ok(BsDiPa::core_diff_bz2($b, $a, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_diff_bz2($b, $a, $pj) eq BsDiPa::INVAL);
		BsDiPa::core_diff_level_set(3);
		ok(BsDiPa::core_diff_bz2($b, $a, \$pj, undef, undef, $cj) eq BsDiPa::OK);
		ok(defined $pj);
		BsDiPa::core_diff_level_set(0);
		ok(BsDiPa::core_diff_bz2($b, $a, \$pj, undef, $iseq, $cj) eq BsDiPa::INVAL);
		ok(!defined $pj);
		ok(BsDiPa::core_diff_bz2($b, $a, \$pj, undef, \$iseq, $cj) eq BsDiPa::OK);
		ok(defined $pj);
		ok($eq == $iseq);
	}

	if(BsDiPa::HAVE_XZ()){
		ok(BsDiPa::core_diff_xz(undef, $a, \$pJ) eq BsDiPa::INVAL);
		ok(!defined $pJ);
		ok(BsDiPa::core_diff_xz($b, undef, \$pJ) eq BsDiPa::INVAL);
		ok(!defined $pJ);
		ok(BsDiPa::core_diff_xz($b, $a, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_diff_xz($b, $a, $pJ) eq BsDiPa::INVAL);
		ok(BsDiPa::core_diff_xz($b, $a, \$pJ, undef, undef, $cJ) eq BsDiPa::OK);
		ok(defined $pJ);
		ok(BsDiPa::core_diff_xz($b, $a, \$pJ, undef, $iseq, $cJ) eq BsDiPa::INVAL);
		ok(!defined $pJ);
		ok(BsDiPa::core_diff_xz($b, $a, \$pJ, undef, \$iseq, $cJ) eq BsDiPa::OK);
		ok(defined $pJ);
		ok($eq == $iseq);
	}

	if(BsDiPa::HAVE_ZSTD()){
		ok(BsDiPa::core_diff_zstd(undef, $a, \$pZ) eq BsDiPa::INVAL);
		ok(!defined $pZ);
		ok(BsDiPa::core_diff_zstd($b, undef, \$pZ) eq BsDiPa::INVAL);
		ok(!defined $pZ);
		ok(BsDiPa::core_diff_zstd($b, $a, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_diff_zstd($b, $a, $pZ) eq BsDiPa::INVAL);
		ok(BsDiPa::core_diff_zstd($b, $a, \$pZ, undef, undef, $cZ) eq BsDiPa::OK);
		ok(defined $pZ);
		ok(BsDiPa::core_diff_zstd($b, $a, \$pZ, undef, $iseq, $cZ) eq BsDiPa::INVAL);
		ok(!defined $pZ);
		ok(BsDiPa::core_diff_zstd($b, $a, \$pZ, undef, \$iseq, $cZ) eq BsDiPa::OK);
		ok(defined $pZ);
		ok($eq == $iseq);
	}

	ok(BsDiPa::core_diff_raw(undef, $a, \$pR) eq BsDiPa::INVAL);
	ok(!defined $pR);
	ok(BsDiPa::core_diff_raw($b, undef, \$pR) eq BsDiPa::INVAL);
	ok(!defined $pR);
	ok(BsDiPa::core_diff_raw($b, $a, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_raw($b, $a, $pR) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_raw($b, $a, \$pR, undef, undef, $cR) eq BsDiPa::OK);
	ok(defined $pR);
	ok(BsDiPa::core_diff_raw($b, $a, \$pR, undef, $iseq, $cR) eq BsDiPa::INVAL);
	ok(!defined $pR);
	ok(BsDiPa::core_diff_raw($b, $a, \$pR, undef, \$iseq, $cR) eq BsDiPa::OK);
	ok(defined $pR);
	ok($eq == $iseq);

	my $x = uncompress($pz);
	ok(($pR cmp $x) == 0);
	undef $x;

	ok(BsDiPa::core_patch_zlib(undef, $pz, \$rz) eq BsDiPa::INVAL);
	ok(!defined $rz);
	ok(BsDiPa::core_patch_zlib($a, undef, \$rz) eq BsDiPa::INVAL);
	ok(!defined $rz);
	ok(BsDiPa::core_patch_zlib($a, $pz, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_zlib($a, $pz, $rz, undef, $cz) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_zlib($a, $pz, \$rz, undef, $cz) eq BsDiPa::OK);
	ok(defined $rz);
	ok(($rz cmp $b) == 0);

	if(BsDiPa::HAVE_BZ2){
		ok(BsDiPa::core_patch_bz2(undef, $pj, \$rj) eq BsDiPa::INVAL);
		ok(!defined $rj);
		ok(BsDiPa::core_patch_bz2($a, undef, \$rj) eq BsDiPa::INVAL);
		ok(!defined $rj);
		ok(BsDiPa::core_patch_bz2($a, $pj, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_bz2($a, $pj, $rj, undef, $cj) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_bz2($a, $pj, \$rj, undef, $cj) eq BsDiPa::OK);
		ok(defined $rj);
		ok(($rj cmp $b) == 0);

		ok(($rz cmp $rj) == 0);
	}

	if(BsDiPa::HAVE_XZ){
		ok(BsDiPa::core_patch_xz(undef, $pJ, \$rJ) eq BsDiPa::INVAL);
		ok(!defined $rJ);
		ok(BsDiPa::core_patch_xz($a, undef, \$rJ) eq BsDiPa::INVAL);
		ok(!defined $rJ);
		ok(BsDiPa::core_patch_xz($a, $pJ, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_xz($a, $pJ, $rJ, undef, $cJ) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_xz($a, $pJ, \$rJ, undef, $cJ) eq BsDiPa::OK);
		ok(defined $rJ);
		ok(($rJ cmp $b) == 0);

		ok(($rz cmp $rJ) == 0);
	}

	if(BsDiPa::HAVE_ZSTD){
		ok(BsDiPa::core_patch_zstd(undef, $pZ, \$rZ) eq BsDiPa::INVAL);
		ok(!defined $rZ);
		ok(BsDiPa::core_patch_zstd($a, undef, \$rZ) eq BsDiPa::INVAL);
		ok(!defined $rZ);
		ok(BsDiPa::core_patch_zstd($a, $pZ, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_zstd($a, $pZ, $rZ, undef, $cZ) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_zstd($a, $pZ, \$rZ, undef, $cZ) eq BsDiPa::OK);
		ok(defined $rZ);
		ok(($rZ cmp $b) == 0);

		ok(($rz cmp $rZ) == 0);
	}

	ok(BsDiPa::core_patch_raw(undef, $pR, \$rR) eq BsDiPa::INVAL);
	ok(!defined $rR);
	ok(BsDiPa::core_patch_raw($a, undef, \$rR) eq BsDiPa::INVAL);
	ok(!defined $rR);
	ok(BsDiPa::core_patch_raw($a, $pR, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_raw($a, $pR, $rR, undef, $cR) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_raw($a, $pR, \$rR, undef, $cR) eq BsDiPa::OK);
	ok(defined $rR);
	ok(($rR cmp $b) == 0);

	ok(($rR cmp $rz) == 0);

	#
	ok(BsDiPa::core_patch_zlib($a, $pz, \$rz, length($rz), $cz) eq BsDiPa::OK);
	ok(defined $rz);
	ok(($rz cmp $b) == 0);
	ok(BsDiPa::core_patch_zlib($a, $pz, \$rz, length($rz) - 1) eq BsDiPa::FBIG);
	ok(!defined $rz);
	ok(BsDiPa::core_patch_zlib($a, $pz, \$rz, "no") eq BsDiPa::INVAL);
	ok(!defined $rz);
	ok(BsDiPa::core_patch_zlib($a, $pz, \$rz, -44) eq BsDiPa::INVAL);
	ok(!defined $rz);

	if(BsDiPa::HAVE_BZ2){
		ok(BsDiPa::core_patch_bz2($a, $pj, \$rj, length($rj), $cJ) eq BsDiPa::OK);
		ok(defined $rj);
		ok(($rj cmp $b) == 0);
		ok(BsDiPa::core_patch_bz2($a, $pj, \$rj, length($rj) - 1) eq BsDiPa::FBIG);
		ok(!defined $rj);
		ok(BsDiPa::core_patch_bz2($a, $pj, \$rj, "no") eq BsDiPa::INVAL);
		ok(!defined $rj);
		ok(BsDiPa::core_patch_bz2($a, $pj, \$rj, -44) eq BsDiPa::INVAL);
		ok(!defined $rj);
	}

	if(BsDiPa::HAVE_XZ){
		ok(BsDiPa::core_patch_xz($a, $pJ, \$rJ, length($rJ), $cJ) eq BsDiPa::OK);
		ok(defined $rJ);
		ok(($rJ cmp $b) == 0);
		ok(BsDiPa::core_patch_xz($a, $pJ, \$rJ, length($rJ) - 1) eq BsDiPa::FBIG);
		ok(!defined $rJ);
		ok(BsDiPa::core_patch_xz($a, $pJ, \$rJ, "no") eq BsDiPa::INVAL);
		ok(!defined $rJ);
		ok(BsDiPa::core_patch_xz($a, $pJ, \$rJ, -44) eq BsDiPa::INVAL);
		ok(!defined $rJ);
	}

	if(BsDiPa::HAVE_ZSTD){
		ok(BsDiPa::core_patch_zstd($a, $pZ, \$rZ, length($rZ), $cZ) eq BsDiPa::OK);
		ok(defined $rZ);
		ok(($rZ cmp $b) == 0);
		ok(BsDiPa::core_patch_zstd($a, $pZ, \$rZ, length($rZ) - 1) eq BsDiPa::FBIG);
		ok(!defined $rZ);
		ok(BsDiPa::core_patch_zstd($a, $pZ, \$rZ, "no") eq BsDiPa::INVAL);
		ok(!defined $rZ);
		ok(BsDiPa::core_patch_zstd($a, $pZ, \$rZ, -44) eq BsDiPa::INVAL);
		ok(!defined $rZ);
	}

	ok(BsDiPa::core_patch_raw($a, $pR, \$rR, length($rR), $cR) eq BsDiPa::OK);
	ok(defined $rR);
	ok(($rR cmp $b) == 0);
	ok(BsDiPa::core_patch_raw($a, $pR, \$rR, length($rR) - 1) eq BsDiPa::FBIG);
	ok(!defined $rR);
	ok(BsDiPa::core_patch_raw($a, $pz, \$rR, "really not") eq BsDiPa::INVAL);
	ok(!defined $rR);
	ok(BsDiPa::core_patch_raw($a, $pz, \$rR, -33) eq BsDiPa::INVAL);
	ok(!defined $rR)
}

sub ckit{
	# Spaced so the several buffer size bongoos of s-bsdipa-io.h, ZLIB, drum
	my ($b, $a);

	($b, $a) = ("\012\013\00\01\02\03\04\05\06\07" x 3, "\010\011\012\013\014" x 4);
	#print 'Tiny size: ', length($b), ' / ', length($a), "\n";
	doit('tiny', $b, $a);

	($b, $a) = ("\012\013\00\01\02\03\04\05\06\07" x 3000, "\010\011\012\013\014" x 4000);
	#print 'Small size: ', length($b), ' / ', length($a), "\n";
	doit('small', $b, $a);

	($b, $a) = ("\012\013\00\01\02\03\04\05\06\07" x 10000, "\010\011\012\013\014" x 9000);
	#print 'Medium size: ', length($b), ' / ', length($a), "\n";
	doit('medium', $b, $a);

	($b, $a) = ("\012\013\00\01\02\03\04\05\06\07" x 80000, "\010\011\012\013\014" x 90000);
	#print 'Big size: ', length($b), ' / ', length($a), "\n";
	doit('big', $b, $a);

	($b, $a) = ("\012\013\00\01\02\03\04\05\06\07" x 120000, "\010\011\012\013\014" x 100000);
	#print 'Bigger size: ', length($b), ' / ', length($a), "\n";
	doit('bigger', $b, $a);

	#
	($b, $a) = ("\012\013\00\01\02\03\04" x 3, "\012\013\00\01\02\03\04" x 3);
	#print 'Equal: ', length($b), ' / ', length($a), "\n";
	doit('equal tiny', $b, $a, 1);

	($b, $a) = ("\012\013\00\01\02\03\04" x 3000, "\012\013\00\01\02\03\04" x 3000);
	#print 'Equal: ', length($b), ' / ', length($a), "\n";
	doit('equal small', $b, $a, 1);

	($b, $a) = ("\00" x 9000, "\00" x 9000);
	#print 'Equal: ', length($b), ' / ', length($a), "\n";
	doit('equal medium', $b, $a, 1);

	#
	($b, $a) = ("\012\013\00\01\02\03\04" x 3, "\012\013\00\01\02\03\04" x 3 . "\05");
	#print 'Equal+1: ', length($b), ' / ', length($a), "\n";
	doit('equal+1 tiny', $b, $a);

	($b, $a) = ("\012\013\00\01\02\03\04" x 3000, "\012\013\00\01\02\03\04" x 3000 . "\05");
	#print 'Equal+1: ', length($b), ' / ', length($a), "\n";
	doit('equal+1 small', $b, $a);

	#
	($b, $a) = ("\012\013\00\01\02\03\04" x 3, "\013\00\01\02\03\04" . "\012\013\00\01\02\03\04" x 2);
	#print 'Equal-1: ', length($b), ' / ', length($a), "\n";
	doit('equal-1 tiny', $b, $a);

	($b, $a) = ("\012\013\00\01\02\03\04" x 3000, "\013\00\01\02\03\04" . "\012\013\00\01\02\03\04" x 2999);
	#print 'Equal-1: ', length($b), ' / ', length($a), "\n";
	doit('equal-1 small', $b, $a)
}

ckit();

$cJ = BsDiPa::core_io_cookie_new_xz() if BsDiPa::HAVE_XZ;
$cZ = BsDiPa::core_io_cookie_new_zstd() if BsDiPa::HAVE_ZSTD;

BsDiPa::core_try_oneshot_set(0);
ckit();
BsDiPa::core_try_oneshot_set(1);
ckit();
BsDiPa::core_try_oneshot_set(-1);
for(my $i = 0; $i < 3; ++$i) {ckit()}

BsDiPa::core_io_cookie_gut($cZ) if BsDiPa::HAVE_ZSTD;
BsDiPa::core_io_cookie_gut($cJ) if BsDiPa::HAVE_XZ;

done_testing()
# s-itt-mode
