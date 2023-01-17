use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';

use String::License::Naming;

use App::Licensecheck;

plan 10;

my $naming = String::License::Naming::SPDX->new;

my @opts = (
	naming    => $naming,
	top_lines => 0,
);

my $todo;

sub parse
{
	my ($path) = @_;

	my ( $license, $copyright ) = App::Licensecheck->new(@opts)->parse($path);

	return wantarray ? ( $license, $copyright ) : $license;
}

like [ parse('t/devscripts/bsd-regents.c') ], array {
	item 'BSD-3-Clause';
	item qr{1987, 1993.*1994 The Regents of the University of California.};
}, 'copyright declared on 2 lines';

like [ parse('t/devscripts/texinfo.tex') ], array {
	item 'GPL-3.0-or-later';
	item qr{1985.*2012 Free Software Foundation, Inc.};
}, 'copyright declared on 3 lines';

$todo = todo 'unsupported by String::Copyright (Debian bug#519080)';
like [ parse('t/devscripts/multi-line-copyright.c') ], array {
	item 'GPL-3 and/or public-domain';
	item qr{2008 Aaron Plattner, NVIDIA Corporation};
}, 'multi-line multi-statements';
$todo = undef;

like [ parse('t/grant/Apache/one_helper.rb') ], array {
	item 'Apache-2.0';
	item qr{2002-2015,? OpenNebula Project \(OpenNebula.org\), C12G Labs};
}, 'Duplicated copyright';

like [ parse('t/devscripts/dual.c') ], array {
	item 'GPL-3 and/or public-domain';
	item '2012 Devscripts developers';
}, 'Duplicated copyright';

like [ parse('t/devscripts/bsd.f') ], array {
	item 'BSD-2-Clause';
}, 'Fortran comments';

like [ parse('t/devscripts/comments-detection.h') ], array {
	item 'GPL-3.0-or-later';
}, 'comments; C++ inline style';

like [ parse('t/devscripts/comments-detection.txt') ], array {
	item 'LGPL-2.1-or-later';
}, 'comments; hash style';

like [ parse('t/devscripts/false-positives') ], array {
	item 'public-domain';
	item '2013 Devscripts developers';
}, 'false positives';

unlike parse('t/devscripts/info-at-eof.h'),
	qr{notice and this},
	'does not capture non-copyright string at end';

done_testing;
