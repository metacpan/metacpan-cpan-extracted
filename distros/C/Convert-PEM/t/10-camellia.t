use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;

require "./t/func.pl";

my $pem = get_rsa();

# choose some modules to test
my @modules = ("Crypt::Camellia","Crypt::Camellia_PP");

my @tests = (
	{ name => "CAMELLIA-128-CBC", rx => "t/data/rsakey-camellia128.pem",
        tx => "t/data/rsakey-camellia128.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "CAMELLIA-192-CBC", rx => "t/data/rsakey-camellia192.pem",
        tx => "t/data/rsakey-camellia192.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "CAMELLIA-256-CBC", rx => "t/data/rsakey-camellia256.pem",
        tx => "t/data/rsakey-camellia256.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "CAMELLIA-128-CBC", rx => "t/data/rsakey2-camellia128.pem",
        tx => "t/data/rsakey2-camellia128.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
	{ name => "CAMELLIA-192-CBC", rx => "t/data/rsakey2-camellia192.pem",
        tx => "t/data/rsakey2-camellia192.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
	{ name => "CAMELLIA-256-CBC", rx => "t/data/rsakey2-camellia256.pem",
        tx => "t/data/rsakey2-camellia256.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
);

run_tests($pem,\@modules,\@tests);
