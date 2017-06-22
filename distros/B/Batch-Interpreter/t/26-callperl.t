#! /usr/bin/perl

use v5.10;
use warnings;
use strict;

use Test::More tests => 3;
use Batch::Interpreter::TestSupport qw(get_test_attr compare_output);

my $test_attr = get_test_attr;
compare_output {
	%$test_attr, in_dir => 't', filter_log => sub {
		my ($type, $stream, $content) = @_;
		if ($stream eq 'stdout') {
			if ($type eq 'lib' && $^O !~ /Win32/) {
				$content =~ s(//server/export\$/log)
						(||server|export\$|log)g;
			} else {
				$content =~ s(\\\\server\\export\$\\log)
						(||server|export\$|log)g;
			}
		}
		return $content;
	},
}, undef, 'callperl.bat', qw(--option ajshdf asdkf asdf ashd);
