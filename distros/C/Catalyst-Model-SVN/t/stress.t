# Test by creating a small local svn repos, committing some stuff into it...
use strict;
use warnings;
use Test::More;
use FindBin qw( $Bin );
use lib ("$Bin/lib", "$Bin/../lib");
use TestLib;
use Catalyst::Model::SVN;
use Test::More;
use Test::Exception;

my $TESTS = 1000;

# Turned off by default as this will screw your machine in 0.05
plan skip_all => 'Stress test not running, set TEST_STRESS env var to run' 
	unless $ENV{TEST_STRESS};

my ($testlib, $repos_uri);
eval {
    $testlib = TestLib->new();
    $repos_uri = $testlib->create_svn_repos();
};
plan skip_all => $@ if $@;
# Ok, setup done - we are good to go.
plan tests => $TESTS * 2; # (2 tests per loop)

Catalyst::Model::SVN->config(
	repository => $repos_uri,
);
my $m = Catalyst::Model::SVN->new();

eval {
	for my $i (1..$TESTS) {
		my (@l, $f);
		@l = $m->ls();
		ok(scalar(@l) > 0, 'ls returns some files');
		$f = $m->cat($repos_uri . 'f1', 'HEAD');
		ok($f, 'File has contents');
	}
};
my $exception = $@;

BAIL_OUT("Caught exception $exception - stress test failed!") if $exception;

# $testlib goes out of scope, and automatically cleans up.


