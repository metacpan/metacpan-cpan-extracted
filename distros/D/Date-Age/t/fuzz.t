#!/usr/bin/env perl

use strict;
use warnings;

use Test::Needs {
	'App::Test::Generator' => '0.19'
};
use Test::Which 'fuzz-harness-generator';
use FindBin qw($Bin);
use IPC::Run3;
use IPC::System::Simple qw(system);
use Test::Most;

my $dirname = "$Bin/conf";

if((-d $dirname) && opendir(my $dh, $dirname)) {
	while (my $filename = readdir($dh)) {
		# Skip '.' and '..' entries and vi temporary files
		next if ($filename eq '.' || $filename eq '..') || ($filename =~ /\.swp$/);

		my $filepath = "$dirname/$filename";

		if(-f $filepath) {	# Check if it's a regular file
			diag($filepath) if ($ENV{'TEST_VERBOSE'});
			my ($stdout, $stderr);
			run3 ['fuzz-harness-generator', '-r', $filepath], undef, \$stdout, \$stderr;

			ok($? == 0, 'Generated test script exits successfully');

			if($? == 0) {
				ok($stdout =~ /^Result: PASS/ms);
				if($stdout =~ /Files=1, Tests=(\d+)/ms) {
					diag("$1 tests run");
				}
			} else {
				diag("$filepath: STDOUT:\n$stdout");
				diag($stderr) if(length($stderr));
				diag("$filepath Failed");
				last;
			}
			diag($stderr) if(length($stderr));
		}
	}
	closedir($dh);
}

done_testing();
