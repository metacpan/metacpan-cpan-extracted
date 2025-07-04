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

our ($cz,$cx,$cr) = (undef,undef,undef);

sub doit{
	my ($t, $b, $a, $eq) = @_;

	$eq = (defined $eq && $eq != 0);
	my $iseq = 0;

	my ($pz,$px,$pr, $rz,$rx,$rr) = (0,0,0, 0,0,0);

	ok(BsDiPa::core_diff_zlib(undef, $a, \$pz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, undef, \$pz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, $a, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_zlib($b, $a, $pz) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_zlib($b, $a, \$pz, undef, undef, $cz) eq BsDiPa::OK);
	ok(defined $pz);
	ok(BsDiPa::core_diff_zlib($b, $a, \$pz, undef, $iseq, $cz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, $a, \$pz, undef, \$iseq, $cz) eq BsDiPa::OK);
	ok(defined $pz);
	ok($eq == $iseq);

	if(BsDiPa::HAVE_XZ()){
		ok(BsDiPa::core_diff_xz(undef, $a, \$px) eq BsDiPa::INVAL);
		ok(!defined $px);
		ok(BsDiPa::core_diff_xz($b, undef, \$px) eq BsDiPa::INVAL);
		ok(!defined $px);
		ok(BsDiPa::core_diff_xz($b, $a, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_diff_xz($b, $a, $px) eq BsDiPa::INVAL);
		ok(BsDiPa::core_diff_xz($b, $a, \$px, undef, undef, $cx) eq BsDiPa::OK);
		ok(defined $px);
		ok(BsDiPa::core_diff_xz($b, $a, \$px, undef, $iseq, $cx) eq BsDiPa::INVAL);
		ok(!defined $px);
		ok(BsDiPa::core_diff_xz($b, $a, \$px, undef, \$iseq, $cx) eq BsDiPa::OK);
		ok(defined $px);
		ok($eq == $iseq);
	}

	ok(BsDiPa::core_diff_raw(undef, $a, \$pr) eq BsDiPa::INVAL);
	ok(!defined $pr);
	ok(BsDiPa::core_diff_raw($b, undef, \$pr) eq BsDiPa::INVAL);
	ok(!defined $pr);
	ok(BsDiPa::core_diff_raw($b, $a, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_raw($b, $a, $pr) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_raw($b, $a, \$pr, undef, undef, $cr) eq BsDiPa::OK);
	ok(defined $pr);
	ok(BsDiPa::core_diff_raw($b, $a, \$pr, undef, $iseq, $cr) eq BsDiPa::INVAL);
	ok(!defined $pr);
	ok(BsDiPa::core_diff_raw($b, $a, \$pr, undef, \$iseq, $cr) eq BsDiPa::OK);
	ok(defined $pr);
	ok($eq == $iseq);

	my $x = uncompress($pz);
	ok(($pr cmp $x) == 0);
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

	if(BsDiPa::HAVE_XZ){
		ok(BsDiPa::core_patch_xz(undef, $px, \$rx) eq BsDiPa::INVAL);
		ok(!defined $rx);
		ok(BsDiPa::core_patch_xz($a, undef, \$rx) eq BsDiPa::INVAL);
		ok(!defined $rx);
		ok(BsDiPa::core_patch_xz($a, $px, undef) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_xz($a, $px, $rx, undef, $cx) eq BsDiPa::INVAL);
		ok(BsDiPa::core_patch_xz($a, $px, \$rx, undef, $cx) eq BsDiPa::OK);
		ok(defined $rx);
		ok(($rx cmp $b) == 0);

		ok(($rz cmp $rx) == 0);
	}

	ok(BsDiPa::core_patch_raw(undef, $pr, \$rr) eq BsDiPa::INVAL);
	ok(!defined $rr);
	ok(BsDiPa::core_patch_raw($a, undef, \$rr) eq BsDiPa::INVAL);
	ok(!defined $rr);
	ok(BsDiPa::core_patch_raw($a, $pr, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_raw($a, $pr, $rr, undef, $cr) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_raw($a, $pr, \$rr, undef, $cr) eq BsDiPa::OK);
	ok(defined $rr);
	ok(($rr cmp $b) == 0);

	ok(($rr cmp $rz) == 0);

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

	if(BsDiPa::HAVE_XZ){
		ok(BsDiPa::core_patch_xz($a, $px, \$rx, length($rx), $cx) eq BsDiPa::OK);
		ok(defined $rx);
		ok(($rx cmp $b) == 0);
		ok(BsDiPa::core_patch_xz($a, $px, \$rx, length($rx) - 1) eq BsDiPa::FBIG);
		ok(!defined $rx);
		ok(BsDiPa::core_patch_xz($a, $px, \$rx, "no") eq BsDiPa::INVAL);
		ok(!defined $rx);
		ok(BsDiPa::core_patch_xz($a, $px, \$rx, -44) eq BsDiPa::INVAL);
		ok(!defined $rx);
	}

	ok(BsDiPa::core_patch_raw($a, $pr, \$rr, length($rr), $cr) eq BsDiPa::OK);
	ok(defined $rr);
	ok(($rr cmp $b) == 0);
	ok(BsDiPa::core_patch_raw($a, $pr, \$rr, length($rr) - 1) eq BsDiPa::FBIG);
	ok(!defined $rr);
	ok(BsDiPa::core_patch_raw($a, $pz, \$rr, "really not") eq BsDiPa::INVAL);
	ok(!defined $rr);
	ok(BsDiPa::core_patch_raw($a, $pz, \$rr, -33) eq BsDiPa::INVAL);
	ok(!defined $rr);
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
	doit('equal-1 small', $b, $a);
}

ckit();
$cx = BsDiPa::core_io_cookie_new_xz() if BsDiPa::HAVE_XZ;
BsDiPa::_try_oneshot_set(0);
ckit();
BsDiPa::_try_oneshot_set(1);
ckit();
BsDiPa::_try_oneshot_set(-1);
for(my $i = 0; $i < 3; ++$i) {ckit()}
BsDiPa::core_io_cookie_gut($cx) if BsDiPa::HAVE_XZ;

done_testing()
# s-itt-mode
