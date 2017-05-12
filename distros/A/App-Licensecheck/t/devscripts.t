use strictures 2;

use Test::More tests => 10;
use Test::Script 1.09;

sub licensecheck
{
	my ( $args, $file, $stdout, $stderr ) = @_;

	my @script_parts = ('bin/licensecheck');
	my $expected_f   = "t/devscripts/%s: %s\n";

	if ($args) {
		push @script_parts, split( ' ', $args );
		$expected_f = "t/devscripts/%s\t%s\n";
	}
	script_runs( [ @script_parts, "t/devscripts/$file" ], $file );
	ref $stdout eq 'Regexp'
		? script_stdout_like( sprintf $expected_f, $file, $stdout )
		: script_stdout_is( sprintf $expected_f, $file, $stdout );
	ref $stderr eq 'Regexp'
		? script_stderr_like($stderr)
		: script_stderr_is( $stderr // '' );
}

subtest 'MultiLine declaration' => sub {

	# test copyright declared on 2 lines
	licensecheck '-m --copyright', 'bsd-regents.c',
		qr{BSD \(3 clause\)	1987, 1993.*1994 The Regents of the University of California.};

	# or 3 lines
	licensecheck '-m --copyright', 'texinfo.tex',
		qr{GPL \(v3 or later\)	1985.*2012 Free Software Foundation, Inc.};

	# BTS #519080
	TODO: {
		local $TODO
			= 'regression: multi-line multi-statements not yet supported by String::Copyright';
		licensecheck '-m --copyright', 'multi-line-copyright.c',
			qr{Public domain GPL \(v3\)	2008 Aaron Plattner, NVIDIA Corporation / 2005 Lars Knoll & Zack Rusin, Trolltech / 2000 Keith Packard, member of The XFree86 Project, Inc.?};
	}
};

subtest 'Duplicated copyright' => sub {
	licensecheck '-m --copyright', '../grant/Apache/one_helper.rb',
		qr{Apache \(v2.0\)	2002-2015,? OpenNebula Project \(OpenNebula.org\), C12G Labs};
};

subtest 'Dual' => sub {
	licensecheck '', 'dual.c', 'Public domain GPL (v3)';
};

subtest 'Machine' => sub {
	licensecheck '-m',        'beerware.cpp', 'Beerware';
	licensecheck '--machine', 'gpl-2',        'GPL (v2)';
	licensecheck '-m --copyright', 'gpl-2',
		'GPL (v2)	2012 Devscripts developers';
};

subtest 'Fortran comments' => sub {
	licensecheck '', 'bsd.f', 'BSD (2 clause)';
};

subtest 'Comments detection' => sub {
	licensecheck '', 'comments-detection.h', 'GPL (v3 or later)';
	licensecheck '', 'comments-detection.txt',
		'*No copyright* LGPL (v2.1 or later)';
};

subtest 'False positives' => sub {
	licensecheck '-m --copyright', 'false-positives',
		'Public domain	2013 Devscripts developers';
};

subtest 'Regexp killer' => sub {
	licensecheck '', 'regexp-killer.c', 'UNKNOWN';
};

subtest 'Encoding' => sub {
	licensecheck '-m --copyright --encoding iso-8859-1', 'copr-iso8859.h',
		qr{GPL \(v2\) \(with incorrect FSF address\)	2011 Heinrich Müller <henmull\@src.gnome.org>};
	licensecheck '-m --copyright --encoding utf8', 'copr-utf8.h',
		qr{GPL \(v2 or later\)	2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' Stevénsön};

	# test wrong user choice and fallback
	licensecheck '-m --copyright --encoding utf8', 'copr-iso8859.h',
		qr{GPL \(v2\) \(with incorrect FSF address\)	2011 Heinrich M.*ller <henmull\@src.gnome.org>},
		qr{|utf8 .* does not map to Unicode at};
};

subtest 'Info at end' => sub {
	licensecheck '-m --copyright --lines 0', 'info-at-eof.h',
		qr{MIT/X11 \(BSD like\)	1994-2012 Lua.org, PUC-Rio.*};
};
