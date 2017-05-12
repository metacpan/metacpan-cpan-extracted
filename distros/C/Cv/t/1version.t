# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More qw(no_plan);
BEGIN { use_ok('Cv') }
BEGIN { use_ok('Cv::Config') }
BEGIN { use_ok('Cv::Qt') if Cv->hasQt }

# test CV_*_VERSION defined OpenCV
my @v = Cv::CV_VERSION;
is($v[0], Cv::CV_MAJOR_VERSION);
is($v[1], Cv::CV_MINOR_VERSION);
is($v[2], Cv::CV_SUBMINOR_VERSION);
my $v = Cv::CV_VERSION;
is($v, join('.', @v));
is(Cv::cvVersion(), $v[0] + $v[1] * 1e-3 + $v[2] * 1e-6);
# diag "OpenCV $v";
is(scalar Cv::Version, Cv::cvVersion());
is(scalar Cv::version, cvVersion());
is(scalar Cv->Version, Cv::cvVersion());
is(scalar Cv->version, cvVersion());

# test our VERSION
use version;
my $cv = version->parse($Cv::VERSION);
foreach (sort &classes('Cv')) {
	next if /^Cv::.*::Ghost$/;
	next if /^Cv::Constant$/;
	my $pm = join('/', split(/::/, $_)) . ".pm";
	no warnings 'uninitialized';
	if ($INC{$pm}) {
		my $pv = "\$${_}::VERSION";
		my $x = version->new(eval $pv);
		is($x, $cv, "$pv in $pm");
	}
}

sub classes {
	my @list = ();
	my $name = shift;
	my $class = eval "\\%${name}::";
	if (ref $class eq 'HASH') {
		for (keys %$class) {
			if (/^(\w+)::$/) {
				push(@list, &classes("${name}::$1"));
			}
		}
		push(@list, $name);
	}
	@list;
}
