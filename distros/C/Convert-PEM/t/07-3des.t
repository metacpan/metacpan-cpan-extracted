use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;

require "./t/func.pl";

my $pem = get_rsa();

# choose some modules to test
my @modules = ("Crypt::DES_EDE3");

my @tests = (
	{ name => "DES-EDE3-CBC", rx => "t/data/rsakey-3des.pem",
        tx => "t/data/rsakey-3des.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "DES-EDE3-CBC", rx => "t/data/rsakey2-3des.pem",
        tx => "t/data/rsakey2-3des.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
);

run_tests($pem,\@modules,\@tests);

