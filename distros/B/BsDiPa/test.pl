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

sub doit{
	my ($t, $b, $a) = @_;

	my $pz = 0;
	ok(BsDiPa::core_diff_zlib(undef, $a, \$pz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, undef, \$pz) eq BsDiPa::INVAL);
	ok(!defined $pz);
	ok(BsDiPa::core_diff_zlib($b, $a, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_zlib($b, $a, $pz) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_zlib($b, $a, \$pz) eq BsDiPa::OK);
	ok(defined $pz);

	my $pr = 0;
	ok(BsDiPa::core_diff_raw(undef, $a, \$pr) eq BsDiPa::INVAL);
	ok(!defined $pr);
	ok(BsDiPa::core_diff_raw($b, undef, \$pr) eq BsDiPa::INVAL);
	ok(!defined $pr);
	ok(BsDiPa::core_diff_raw($b, $a, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_raw($b, $a, $pr) eq BsDiPa::INVAL);
	ok(BsDiPa::core_diff_raw($b, $a, \$pr) eq BsDiPa::OK);
	ok(defined $pr);

	my $x = uncompress($pz);
	ok(($pr cmp $x) == 0);

	my $rz = 0;
	ok(BsDiPa::core_patch_zlib(undef, $pz, \$rz) eq BsDiPa::INVAL);
	ok(!defined $rz);
	ok(BsDiPa::core_patch_zlib($a, undef, \$rz) eq BsDiPa::INVAL);
	ok(!defined $rz);
	ok(BsDiPa::core_patch_zlib($a, $pz, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_zlib($a, $pz, $rz) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_zlib($a, $pz, \$rz) eq BsDiPa::OK);
	ok(defined $rz);
	ok(($rz cmp $b) == 0);

	my $rr = 0;
	ok(BsDiPa::core_patch_raw(undef, $pr, \$rr) eq BsDiPa::INVAL);
	ok(!defined $rr);
	ok(BsDiPa::core_patch_raw($a, undef, \$rr) eq BsDiPa::INVAL);
	ok(!defined $rr);
	ok(BsDiPa::core_patch_raw($a, $pr, undef) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_raw($a, $pr, $rr) eq BsDiPa::INVAL);
	ok(BsDiPa::core_patch_raw($a, $pr, \$rr) eq BsDiPa::OK);
	ok(defined $rr);
	ok(($rr cmp $b) == 0);

	ok(($rr cmp $rz) == 0);
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
}

ckit();
BsDiPa::_try_oneshot_set(0);
ckit();
BsDiPa::_try_oneshot_set(1);
ckit();
BsDiPa::_try_oneshot_set(-1);
for(my $i=0; $i < 5; ++$i) {ckit()}

done_testing()
# s-itt-mode
