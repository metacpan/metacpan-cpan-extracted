use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;

require "./t/func.pl";

my $pem = get_rsa();

# choose some modules to test
my @modules = ("Crypt::SEED");

my @tests = (
	{ name => "SEED-CBC", rx => "t/data/rsakey-seed.pem",
        tx => "t/data/rsakey-seed.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "SEED-CBC", rx => "t/data/rsakey2-seed.pem",
        tx => "t/data/rsakey2-seed.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
);

run_tests($pem,\@modules,\@tests);
