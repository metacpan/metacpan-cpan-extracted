#!perl -T
use 5.006;
use strict;
use warnings;

use utf8;

our $VERSION='0.03';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
# to avoid wide character in TAP output
# do this before loading Test* modules
use open ':std', ':encoding(utf8)';

#### nothing to change below
use Test::More;
#use Test::Deep;

my $num_tests = 0;

use Data::Roundtrip;
use Data::Random::Structure;
use Data::Dumper qw/Dumper/;

my $randomiser = Data::Random::Structure->new(
	max_depth => 5,
	max_elements => 20,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called."); $num_tests++;
my $perl_var = $randomiser->generate();
ok(defined $perl_var, "generate() called."); $num_tests++;

my %testfuncs = map {
	my @x = split /2/, $_;
	join('2',@x) => join('2',reverse @x)
} grep {/^perl2/} sort keys %Data::Roundtrip::;
#print join("\n", map { $_ .'=>'. $testfuncs{$_} } keys %testfuncs)."\n";

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
