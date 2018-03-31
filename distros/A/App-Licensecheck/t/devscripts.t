use strictures 2;

use Test::More tests => 17;
use Test::Script 1.09;

sub licensecheck
{
	my ( $desc, $args, $file, $stdout, $stderr ) = @_;
	my @args     = @{$args};
	my $path     = "t/devscripts/$file";
	my @cmd      = ( 'bin/licensecheck', @args, $path );
	my $expected = scalar @args ? "$path\t$stdout" : "$path: $stdout\n";

	subtest "$desc; $path" => sub {
		script_runs( [@cmd], join ' ', @cmd );
		ref $stdout eq 'Regexp'
			? script_stdout_like($expected)
			: script_stdout_is($expected);
		ref $stderr eq 'Regexp'
			? script_stderr_like($stderr)
			: script_stderr_is( $stderr || '' );
	};
}

licensecheck 'copyright declared on 2 lines',
	[qw(-m --copyright)], 'bsd-regents.c',
	qr{BSD (?:3-clause "New" or "Revised" License|\(3 clause\))	1987, 1993.*1994 The Regents of the University of California.};
licensecheck 'copyright declared on 3 lines',
	[qw(-m --copyright)], 'texinfo.tex',
	qr{GPL \(v3 or later\)	1985.*2012 Free Software Foundation, Inc.};
TODO: {
	local $TODO
		= 'not yet supported by String::Copyright (Debian bug#519080)';
	licensecheck 'multi-line multi-statements',
		[qw(-m --copyright)], 'multi-line-copyright.c',
		qr{Public domain GPL \(v3\)	2008 Aaron Plattner, NVIDIA Corporation / 2005 Lars Knoll & Zack Rusin, Trolltech / 2000 Keith Packard, member of The XFree86 Project, Inc.?};
}

licensecheck 'Duplicated copyright',
	[qw(-m --copyright)], '../grant/Apache/one_helper.rb',
	qr{Apache(?: License)? \(v2.0\)	2002-2015,? OpenNebula Project \(OpenNebula.org\), C12G Labs};
licensecheck 'Duplicated copyright',
	[], 'dual.c', 'Public domain GPL (v3)';

licensecheck 'machine-readable output; short-form option',
	[qw(-m)], 'beerware.cpp',
	qr{Beerware(?: License)?};
licensecheck 'machine-readable output; long-form option',
	[qw(--machine)], 'gpl-2',
	'GPL (v2)
';
licensecheck 'machine-readable output w/ copyright',
	[qw(-m --copyright)], 'gpl-2',
	'GPL (v2)	2012 Devscripts developers
';

licensecheck 'Fortran comments',
	[], 'bsd.f',
	qr{BSD (?:2-clause "Simplified" License|\(2 clause\))};

licensecheck 'comments; C++ inline style',
	[], 'comments-detection.h',
	'GPL (v3 or later)';
licensecheck 'comments; hash style',
	[], 'comments-detection.txt',
	qr{\*No copyright\* (?:GNU Lesser General Public License|LGPL) \(v2\.1 or later\)};

licensecheck 'false positives',
	[qw(-m --copyright)], 'false-positives',
	'Public domain	2013 Devscripts developers
';

licensecheck 'regexp killer',
	[], 'regexp-killer.c', 'UNKNOWN';

licensecheck 'encoding; ISO 8859-1',
	[qw(-m --copyright --encoding iso-8859-1)], 'copr-iso8859.h',
	qr{GPL \(v2\) \(with incorrect FSF address\)	2011 Heinrich Müller <henmull\@src.gnome.org>};
licensecheck 'encoding; UTF-8',
	[qw(-m --copyright --encoding utf8)], 'copr-utf8.h',
	qr{GPL \(v2 or later\)	2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' Stevénsön};
licensecheck 'encoding; ISO 8859-1 parsed as UTF-8',
	[qw(-m --copyright --encoding utf8)], 'copr-iso8859.h',
	qr{GPL \(v2\) \(with incorrect FSF address\)	2011 Heinrich M.*ller <henmull\@src.gnome.org>},
	qr{|utf8 .* does not map to Unicode at};

licensecheck 'info at end',
	[qw(-m --copyright --lines 0)], 'info-at-eof.h',
	qr{(?:Expat License|MIT/X11 \(BSD like\))	1994-2012 Lua.org, PUC-Rio.*};
