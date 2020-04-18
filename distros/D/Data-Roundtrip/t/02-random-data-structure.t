#!perl -T
use 5.008;
use strict;
use warnings;

use utf8;

our $VERSION='0.03';

# NO UTF8 here, we are checking with random
# data structure which provides no unicode
# there is a separate file for testing with unicode

#### nothing to change below
use Test::More;

my $num_tests = 0;

use Data::Roundtrip;

use Data::Random::Structure;

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
for my $astestfunc (sort keys %testfuncs){
	no strict 'refs';
	my $astestfuncstr = 'Data::Roundtrip::'.$astestfunc;
	my $result = $astestfuncstr->($perl_var);
	ok(defined $result, "$astestfunc() called."); $num_tests++;
	my $areversefunc = $testfuncs{$astestfunc};
	my $areversefuncstr = 'Data::Roundtrip::'.$areversefunc;
	my $back = $areversefuncstr->($result);
	ok(defined $back, "$areversefunc() called."); $num_tests++;
}
$params = {
	'Terse' => 1,
	'dont-bloody-escape-unicode' => 1,
	'pretty' => 1,
	'escape-unicode' => 1,
};
for my $astestfunc (sort keys %testfuncs){
	no strict 'refs';
	my $astestfuncstr = 'Data::Roundtrip::'.$astestfunc;
	my $result = $astestfuncstr->($perl_var, $params);
	ok(defined $result, "$astestfunc() called.") or BAIL_OUT; $num_tests++;
	my $areversefunc = $testfuncs{$astestfunc};
	my $areversefuncstr = 'Data::Roundtrip::'.$areversefunc;
	my $back = $areversefuncstr->($result, $params);
	ok(defined $back, "$areversefunc() called."); $num_tests++;
}
done_testing($num_tests);
