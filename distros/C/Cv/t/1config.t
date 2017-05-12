# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More qw(no_plan);
# use Test::More tests => 10;
use Test::Exception;
use version;

BEGIN {
	chop(my $ccflags = eval { `pkg-config opencv` });
	is($?, 0, "can pkg-config opencv");
	use_ok('Cv::Config');
}

if (1) {
	# no warnings;
	local $ENV{CC} = undef;
	local $ENV{CXX} = undef;
	my $cf = eval { new Cv::Config };
	# like($cf->cvdir, qr{/(blib/)?lib/Cv});
	ok(-d $cf->cvdir);
	# like(${$cf->typemaps}[0], qr{/(blib/)?lib/Cv/typemap});
	ok(-f ${$cf->typemaps}[0]);
	is($cf->cc, 'c++');
	my $min = version->parse('1.001000');
	# local $Cv::Config::verbose = 1;
	cmp_ok($cf->_version, '>=', $min);
	cmp_ok(version->parse($cf->version), '>=', $min);
}

if (2) {
	# no warnings;
	my $dynamic_lib = 0;
	my @cxx = ();
	for my $cxx (qw(c++ g++ g++-4 g++44 g++45 g++46)) {
		local *STDERR_COPY;
		open(STDERR_COPY, '>&STDERR');
		open(STDERR, '/dev/null');
		eval { `$cxx -v` };
		my $r = $?;
		open(STDERR, '>&STDERR_COPY');
		next unless $r == 0;
		push(@cxx, $cxx);
		delete $ENV{CC};
		$ENV{CXX} = $cxx;
		my $cf = eval { new Cv::Config };
		$dynamic_lib++ if $cf->dynamic_lib;
	}
	is($dynamic_lib, scalar @cxx);
	diag("cxx: ", join(' ', @cxx));
}

if (3) {
	# no warnings;
	local %Cv::Config::opencv = ();
	my $include = '/path/to/include';
	my $define = 'define=something';
	$Cv::Config::opencv{cflags} = "-I$include -D$define";
	my $cf = eval { new Cv::Config };
	like($cf->ccflags, qr{-I$include});
	like($cf->ccflags, qr{-D$define});
}

# Cv-0.25
if (4) {
	# no warnings;
	my $cf = eval { new Cv::Config };
	lives_ok { $cf->hasqt };
}

if (5) {
	my $lib = '/usr/local/lib';
	for (
		[ "$lib/libopencv_core-2.4.so", "-L$lib -lopencv_core" ],
		[ "$lib/libopencv_core-2.4.dll", "-L$lib -lopencv_core" ],
		[ "-L$lib -lopencv_core", "-L$lib -lopencv_core" ],
		) {
		local $Cv::Config::opencv{libs} = $_->[0];
		my $cf = eval { new Cv::Config };
		ok(!defined $cf->{LIBS});
		is(${$cf->libs}[0], $_->[1]);
	}
}
