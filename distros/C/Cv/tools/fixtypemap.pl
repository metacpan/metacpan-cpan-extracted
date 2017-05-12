#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;

use Getopt::Long;
my $output = "/dev/null";
GetOptions("output=s", \$output) and @ARGV == 1 or
	die "usage: $0 -o outfile infile\n";

use version;
use lib qw(lib);
eval "use Cv::Config";
my $cf = new Cv::Config;

sub _CV_VERSION { $cf->_version }
sub _VERSION { qv('v'.join('.', @_)) }

sub cpp {
	my ($code, $where) = @_;
	my @line; my @cond = (1);
	for (split("\n", $code)) {
		if (/\.if\s+(.*)/) {
			push(@cond, eval $1);
			die "can't eval \"$_\" in $where\n" if $@;
		} elsif (/\.else/) {
			$cond[-1] = !$cond[-1];
		} elsif (/\.endif/) {
			pop(@cond);
		} else {
			push(@line, $_) if $cond[-1];
		}
	}
	join("\n", @line);
}

use ExtUtils::Typemaps;
my $t = ExtUtils::Typemaps->new(file => $ARGV[0]);
for (@{$t->{input_section}}, @{$t->{output_section}}) {
	$_->{code} = cpp($_->{code}, "$_->{xstype}, file $ARGV[0]");
}

# use Data::Dumper;
# warn Dumper($t->{input_section}->[$t->{input_lookup}{T_CvSURFParams}]);
# warn Dumper($t->{output_section}->[$t->{output_lookup}{T_CvSURFParams}]);

$t->write(file => $output);
exit 0;
