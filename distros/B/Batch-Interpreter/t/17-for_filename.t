#! /usr/bin/perl

use v5.10;
use warnings;
use strict;

use Test::More tests => 3;
use Batch::Interpreter::TestSupport qw(get_test_attr compare_output);

use File::Spec;

my ($volume, $directories, undef) =
	File::Spec->splitpath(File::Spec->rel2abs('t'), 'is dir');

my $test_attr = get_test_attr;
{
	local $test_attr->{filter_log} = sub {
		my ($type, $stream, $content) = @_;
		$content =~ s/\Q$directories\E\\/\\test\\/gmio
			if $type eq 'cmd';
		return $content;
	};
	compare_output $test_attr, undef, 't/for_filename.bat';
}
