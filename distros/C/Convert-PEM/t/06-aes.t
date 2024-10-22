use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;

require "./t/func.pl";

my $pem = get_rsa();

# choose some modules to test
# my @modules = grep { $_ ne "" } map { $pem->set_cipher_module("AES-128-CBC", $_) } ("Crypt::Cipher::AES", "Crypt::OpenSSL::AES");
my @modules = ("Crypt::Cipher::AES", "Crypt::OpenSSL::AES","Crypt::Rijndael","Crypt::Rijndael_PP");

my @tests = (
	{ name => "AES-128-CBC", rx => "t/data/rsakey-aes128.pem",
        tx => "t/data/rsakey-aes128.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "AES-192-CBC", rx => "t/data/rsakey-aes192.pem",
        tx => "t/data/rsakey-aes192.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "AES-256-CBC", rx => "t/data/rsakey-aes256.pem",
        tx => "t/data/rsakey-aes256.wr.pem", hash => "45f605c6186eaea0730958b0e3da52e4", },
	{ name => "AES-128-CBC", rx => "t/data/rsakey2-aes128.pem",
        tx => "t/data/rsakey2-aes128.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
	{ name => "AES-192-CBC", rx => "t/data/rsakey2-aes192.pem",
        tx => "t/data/rsakey2-aes192.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
	{ name => "AES-256-CBC", rx => "t/data/rsakey2-aes256.pem",
        tx => "t/data/rsakey2-aes256.wr.pem", hash => "9b334c60a2c0c2a543ac742ebf1f8ccd", },
);

run_tests($pem,\@modules,\@tests);
