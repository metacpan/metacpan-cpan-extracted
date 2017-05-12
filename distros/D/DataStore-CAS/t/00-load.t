#! /usr/bin/env perl -T

use Test::More;
my @pkgs= qw(
		DataStore::CAS
		DataStore::CAS::File
		DataStore::CAS::VirtualHandle
		DataStore::CAS::FileCreatorHandle
		DataStore::CAS::Virtual
		DataStore::CAS::Simple
);

use_ok $_ or BAIL_OUT("use $_") for @pkgs;

diag "Testing on Perl $], $^X\n"
	.join('', map { sprintf("%-40s  %s\n", $_, $_->VERSION) } @pkgs);

done_testing;
