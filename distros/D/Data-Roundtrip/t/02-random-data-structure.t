#!perl -T

use 5.008;
use strict;
use warnings;

our $VERSION='0.30';

# NO UTF8 here, we are checking with random
# data structure which provides no unicode
# there is a separate file for testing with unicode

my $MAXTRIALS = 1000;

#### nothing to change below
use Test::More;

use Data::Dump qw/pp/;

my $num_tests = 0;

use Data::Roundtrip;

use Data::Random::Structure;

# there is a tiny problem here.
# Data::Random::Structure uses (hardcoded)
# the full set of printable characters for
# producing $perl_var (keys, values, array elements)
# and that kind of kills YAML (and possibly JSON)
# because of special chars escaping.
# This is not our problem and solving this not our responsibility.
# a seed of 397 will produce a data structure which makes
# YAML::Load() to fail.

# but at the moment we are using YAML::PP, so no worries

my $seed = 397+1;

srand $seed;

my $randomiser = Data::Random::Structure->new(
	max_depth => 50,
	max_elements => 200,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called."); $num_tests++;
my $perl_var = $randomiser->generate();

ok(defined $perl_var, "generate() called."); $num_tests++;

my %testfuncs;
for my $k (sort grep {/^perl2/} keys %Data::Roundtrip::){
	my @x = split /2/, $k;
	my $newsub = join('2',reverse @x);
	next unless Data::Roundtrip->can($newsub);
	$testfuncs{$k} = $newsub
}
ok(0 < scalar keys %testfuncs, "built test-funcs"); $num_tests++;
ok(1, "checking these functions pairs: ".join(",", map { $_ .'=>'. $testfuncs{$_} } keys %testfuncs)."."); $num_tests++;

# also add these
$testfuncs{'perl2dump_filtered'} = 'dump2perl';
$testfuncs{'perl2dump_homebrew'} = 'dump2perl';

my $params = {};
for my $aperl2Xfunc (sort keys %testfuncs){
	# aperl2Xfunc
	no strict 'refs';
	my $aperl2Xfuncstr = 'Data::Roundtrip::'.$aperl2Xfunc;
	my $result = $aperl2Xfuncstr->($perl_var);
	ok(defined $result, "$aperl2Xfunc() called.") or BAIL_OUT("$aperl2Xfunc() : (seed=$seed) failed for this var:\n".pp($perl_var)); $num_tests++;
	my $aX2perlfunc = $testfuncs{$aperl2Xfunc};
	my $aX2perlfuncstr = 'Data::Roundtrip::'.$aX2perlfunc;
	my $back = $aX2perlfuncstr->($result);
	ok(defined $back, "$aX2perlfunc() called.") or BAIL_OUT("$aX2perlfuncstr() : (seed=$seed) failed for this string:\n".$result); $num_tests++;
	ok(ref($back) eq ref($perl_var), "checking same rountrip refs ".ref($back)." and ".ref($perl_var)."."); $num_tests++;
}
$params = {
	'Terse' => 1,
	'dont-bloody-escape-unicode' => 1,
	'pretty' => 1,
	'escape-unicode' => 1,
};
for my $aperl2Xfunc (sort keys %testfuncs){
	no strict 'refs';
	my $aperl2Xfuncstr = 'Data::Roundtrip::'.$aperl2Xfunc;
	my $result = $aperl2Xfuncstr->($perl_var, $params);
	ok(defined $result, "$aperl2Xfunc() called.") or BAIL_OUT("$aperl2Xfunc() : (seed=$seed) failed for this var:\n".pp($perl_var)); $num_tests++;
	my $aX2perlfunc = $testfuncs{$aperl2Xfunc};
	my $aX2perlfuncstr = 'Data::Roundtrip::'.$aX2perlfunc;
	my $back = $aX2perlfuncstr->($result, $params);
	ok(defined $back, "$aX2perlfunc() called.") or BAIL_OUT("$aX2perlfunc() : (seed=$seed) failed for this string:\n".$result); $num_tests++;
	ok(ref($back) eq ref($perl_var), "checking same rountrip refs ".ref($back)." and ".ref($perl_var)."."); $num_tests++;
}
done_testing($num_tests);
