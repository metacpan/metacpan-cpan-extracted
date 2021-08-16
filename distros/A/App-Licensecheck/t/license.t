use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use lib 't/lib';
use Test2::Licensecheck;

plan 36;

license_is( 't/devscripts/academic.h',      'AFL-3.0' );
license_is( 't/grant/Apache/one_helper.rb', 'Apache-2.0' );
license_is(
	[   qw(
			t/devscripts/artistic-2-0-modules.pm
			t/devscripts/artistic-2-0.txt
			)
	],
	'Artistic-2.0'
);
license_is( 't/devscripts/beerware.cpp', 'Beerware' );
license_is(
	't/devscripts/bsd-1-clause-1.c',
	'BSD-1-Clause'
);
license_is( 't/devscripts/bsd.f', 'BSD-2-clause' );
license_is(
	[   qw(
			t/devscripts/bsd-3-clause.cpp
			t/devscripts/bsd-3-clause-authorsany.c
			t/devscripts/bsd-regents.c
			)
	],
	'BSD-3-clause'
);
license_is(
	[qw(	t/devscripts/mame-style.c)],
	'BSD-3-clause'
);
license_is( 't/devscripts/boost.h', 'BSL-1.0' );
license_is( 't/devscripts/epl.h',   'EPL-1.0' );

# Lisp Lesser General Public License (BTS #806424)
# see http://opensource.franz.com/preamble.html
license_is( 't/devscripts/llgpl.lisp',       'LLGPL' );
license_is( 't/devscripts/gpl-no-version.h', 'GPL' );
license_is( 't/devscripts/gpl-1',            'GPL-1+' );
license_is(
	[   qw(
			t/devscripts/gpl-2
			t/devscripts/bug-559429
			t/devscripts/gpl-2-comma.sh
			t/devscripts/gpl-2-incorrect-address
			)
	],
	'GPL-2'
);
license_is(
	[   qw(
			t/devscripts/gpl-2+
			t/devscripts/gpl-2+.scm
			)
	],
	'GPL-2+'
);
license_is(
	[   qw(
			t/devscripts/gpl-3.sh
			t/devscripts/gpl-3-only.c
			)
	],
	'GPL-3'
);
license_is(
	[   qw(
			t/devscripts/gpl-3+
			t/devscripts/gpl-3+-with-rem-comment.xml
			t/devscripts/gpl-variation.c
			t/devscripts/gpl-3+.el
			t/devscripts/comments-detection.h
			)
	],
	'GPL-3+'
);
license_is( 't/devscripts/mpl-1.1.sh', 'MPL-1.1' );
license_is(
	[   qw(
			t/devscripts/mpl-2.0.sh
			t/devscripts/mpl-2.0-comma.sh
			)
	],
	'MPL-2.0'
);
license_is( 't/devscripts/freetype.c',    'FTL' );
license_is( 't/devscripts/cddl.h',        'CDDL' );
license_is( 't/devscripts/libuv-isc.am',  'ISC' );
license_is( 't/devscripts/info-at-eof.h', 'Expat' );
