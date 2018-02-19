#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck tests => 38;

is_licensed( 't/devscripts/academic.h',      'AFL-3.0' );
is_licensed( 't/grant/Apache/one_helper.rb', 'Apache-2.0' );
is_licensed(
	[   qw(
			t/devscripts/artistic-2-0-modules.pm
			t/devscripts/artistic-2-0.txt
			)
	],
	'Artistic-2.0'
);
is_licensed( 't/devscripts/beerware.cpp',     'Beerware' );
is_licensed( 't/devscripts/bsd-1-clause-1.c', 'BSD~unspecified' );
is_licensed( 't/devscripts/bsd.f',            'BSD-2-clause' );
is_licensed(
	[   qw(
			t/devscripts/bsd-3-clause.cpp
			t/devscripts/bsd-3-clause-authorsany.c
			t/devscripts/mame-style.c
			t/devscripts/bsd-regents.c
			)
	],
	'BSD-3-clause'
);
is_licensed( 't/devscripts/boost.h', 'BSL' );
is_licensed( 't/devscripts/epl.h',   'EPL-1.0' );

# Lisp Lesser General Public License (BTS #806424)
# see http://opensource.franz.com/preamble.html
is_licensed( 't/devscripts/llgpl.lisp',       'LLGPL' );
is_licensed( 't/devscripts/gpl-no-version.h', 'GPL' );
is_licensed( 't/devscripts/gpl-1',            'GPL-1+' );
is_licensed(
	[   qw(
			t/devscripts/gpl-2
			t/devscripts/bug-559429
			t/devscripts/gpl-2-comma.sh
			t/devscripts/gpl-2-incorrect-address
			t/devscripts/copr-iso8859.h
			)
	],
	'GPL-2'
);
is_licensed(
	[   qw(
			t/devscripts/gpl-2+
			t/devscripts/gpl-2+.scm
			t/devscripts/copr-utf8.h
			)
	],
	'GPL-2+'
);
is_licensed(
	[   qw(
			t/devscripts/gpl-3.sh
			t/devscripts/gpl-3-only.c
			)
	],
	'GPL-3'
);
is_licensed(
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
is_licensed( 't/devscripts/mpl-1.1.sh', 'MPL-1.1' );
is_licensed(
	[   qw(
			t/devscripts/mpl-2.0.sh
			t/devscripts/mpl-2.0-comma.sh
			)
	],
	'MPL-2.0'
);
is_licensed( 't/devscripts/freetype.c',    'FTL' );
is_licensed( 't/devscripts/cddl.h',        'CDDL' );
is_licensed( 't/devscripts/libuv-isc.am',  'ISC' );
is_licensed( 't/devscripts/info-at-eof.h', 'Expat' );
