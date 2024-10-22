use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;

require "./t/func.pl";

my $pem = get_rsa();

# choose some modules to test
my @modules = ("Crypt::IDEA");

if (!@modules) {
	plan skip_all => "because tests require at least 1 IDEA cipher module to be installed" if !@modules;
	exit;
}

my @tests = (
	{ name => "IDEA-CBC", rx => "t/data/rsakey-idea.pem", tx => "t/data/rsakey-idea.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "IDEA-CBC", rx => "t/data/rsakey2-idea.pem", tx => "t/data/rsakey2-idea.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
);

run_tests($pem,\@modules,\@tests);
