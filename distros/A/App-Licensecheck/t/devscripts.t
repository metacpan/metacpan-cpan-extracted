use Test2::V0;

use Test::Command::Simple;

use Path::Tiny 0.053;

plan 14;

my $CMD = $ENV{'LICENSECHECK'} || 'bin/licensecheck';

# ensure local script is executable
path($CMD)->chmod('a+x') if ( $CMD eq 'bin/licensecheck' );

# TODO: drop later alternative when Regexp::Pattern::License v3.7.0 is required
subtest 'copyright declared on 2 lines' => sub {
	run_ok $CMD, qw(-m --copyright t/devscripts/bsd-regents.c);
	like stdout,
		qr{(?:BSD 3-Clause License|BSD 3-clause "New" or "Revised" License)\t1987, 1993.*1994 The Regents of the University of California.},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'copyright declared on 3 lines' => sub {
	run_ok $CMD, qw(-m --copyright t/devscripts/texinfo.tex);
	like stdout,
		qr{GNU General Public License v3.0 or later	1985.*2012 Free Software Foundation, Inc.},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'multi-line multi-statements' => sub {
	my $todo
		= todo 'not yet supported by String::Copyright (Debian bug#519080)';
	run_ok $CMD, qw(-m --copyright t/devscripts/multi-line-copyright.c);
	like stdout,
		qr{Public domain GPL \(v3\)\t2008 Aaron Plattner, NVIDIA Corporation / 2005 Lars Knoll & Zack Rusin, Trolltech / 2000 Keith Packard, member of The XFree86 Project, Inc.?},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'Duplicated copyright' => sub {
	my $todo = todo 'not yet supported by Regexp::Pattern::License';
	run_ok $CMD,
		qw(-m --copyright t/devscripts/../grant/Apache/one_helper.rb);
	like stdout,
		qr{Apache License \(v2.0\)	2002-2015,? OpenNebula Project \(OpenNebula.org\), C12G Labs},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'Duplicated copyright' => sub {
	run_ok $CMD, qw(t/devscripts/dual.c);
	like stdout, qr{Public domain GNU General Public License, Version 3$},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'machine-readable output; short-form option' => sub {
	run_ok $CMD, qw(-m t/devscripts/beerware.cpp);
	like stdout, qr{Beerware License}, 'Testing stdout';
	is stderr,   '',                   'No stderr';
};
subtest 'machine-readable output; long-form option' => sub {
	run_ok $CMD, qw(--machine t/devscripts/gpl-2);
	like stdout, qr{GNU General Public License, Version 2$}, 'Testing stdout';
	is stderr,   '',                                         'No stderr';
};
subtest 'machine-readable output w/ copyright' => sub {
	run_ok $CMD, qw(-m --copyright t/devscripts/gpl-2);
	like stdout,
		qr{GNU General Public License, Version 2\t2012 Devscripts developers\n$},
		'Testing stdout';
	is stderr, '', 'No stderr';
};

# TODO: drop later alternative when Regexp::Pattern::License v3.7.0 is required
subtest 'Fortran comments' => sub {
	run_ok $CMD, qw(t/devscripts/bsd.f);
	like stdout,
		qr{(?:BSD 2-Clause License|BSD 2-clause "Simplified" License)},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'comments; C++ inline style' => sub {
	run_ok $CMD, qw(t/devscripts/comments-detection.h);
	like stdout, qr{GNU General Public License v3.0 or later$},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'comments; hash style' => sub {
	run_ok $CMD, qw(t/devscripts/comments-detection.txt);
	like stdout,
		qr{\*No copyright\* GNU Lesser General Public License v2\.1 or later},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'false positives' => sub {
	run_ok $CMD, qw(-m --copyright t/devscripts/false-positives);
	like stdout, qr{Public domain\t2013 Devscripts developers},
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'regexp killer' => sub {
	run_ok $CMD, qw(t/devscripts/regexp-killer.c);
	like stdout, qr{UNKNOWN}, 'Testing stdout';
	is stderr,   '',          'No stderr';
};
subtest 'info at end' => sub {
	run_ok $CMD,
		qw(-m --shortname-scheme=debian --copyright --lines 0 t/devscripts/info-at-eof.h);
	like stdout,
		qr{Expat\t1994-2012 Lua.org, PUC-Rio.*},
		'Testing stdout';
	is stderr, '', 'No stderr';
};

done_testing;
