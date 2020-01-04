#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck tests => 46;

# AFL
license_is(
	't/grant/AFL_and_more/xdgmime.c',
	[ 'AFL-2.0 and/or LGPL-2+', 'AFL-2.0 or LGPL-2+' ]
);

# AGPL
license_is(
	[   qw(
			t/grant/AGPL/fastx.c
			t/grant/AGPL/fet.cpp
			t/grant/AGPL/setup.py
			)
	],
	'AGPL-3+'
);

# Apache
license_is( 't/grant/Apache_and_more/PIE.htc', 'Apache-2.0 or GPL-2' );
license_is(
	't/grant/Apache_and_more/rust.lang',
	[ 'Apache-2.0 and/or MIT~unspecified', 'Apache-2.0 or MIT~unspecified' ]
);
license_is(
	't/grant/Apache_and_more/select2.js',
	[ 'Apache-2.0 and/or Apache-2.0 or GPL-2', 'Apache-2.0 or GPL-2' ]
);
license_is(
	't/grant/Apache_and_more/test_run.py',
	'Apache-2.0 or BSD-3-clause'
);

# CC-BY-SA
license_is(
	't/grant/CC-BY-SA_and_more/WMLA',
	'CC-BY-SA-3.0 and/or GFDL-1.2'
);
license_is( 't/grant/CC-BY-SA_and_more/cewl.rb', 'CC-BY-SA-2.0 or GPL-3' );
license_is(
	't/grant/CC-BY-SA_and_more/utilities.scad',
	'CC-BY-SA-3.0 or LGPL-2'
);

# EPL
license_is(
	't/grant/EPL_and_more/Base64Coder.java',
	[   'AGPL-3+ and/or EPL-1.0+ and/or LGPL-2.1+ or GPL-3+',
		'AGPL-3+ or Apache-2.0+ or EPL-1.0+ or GPL-3+ or LGPL-2.1+'
	]
);

# LGPL
license_is( 't/grant/LGPL/Model.pm', 'LGPL-2.1' );
license_is( 't/grant/LGPL/PKG-INFO', [ '', 'LGPL' ] );

license_is( 't/grant/LGPL/criu.h',          'LGPL-2.1' );
license_is( 't/grant/LGPL/dqblk_xfs.h',     'LGPL' );
license_is( 't/grant/LGPL/exr.h',           'LGPL' );
license_is( 't/grant/LGPL/gnome.h',         'LGPL-2.1' );
license_is( 't/grant/LGPL/jitterbuf.h',     'LGPL' );
license_is( 't/grant/LGPL/libotr.m4',       'LGPL-2.1' );
license_is( 't/grant/LGPL/pic.c',           'LGPL-3' );
license_is( 't/grant/LGPL/strv.c',          'LGPL-2.1+' );
license_is( 't/grant/LGPL/table.py',        'LGPL-2+' );
license_is( 't/grant/LGPL/videoplayer.cpp', 'LGPL-2.1 or LGPL-3' );
license_is(
	't/grant/LGPL_and_more/colamd.c',
	'LGPL-2.1+ and/or LGPL-bdwgc'
);
license_is(
	't/grant/LGPL_and_more/da.aff',
	[ 'LGPL-2.1 or GPL-2.0 and/or MPL-1.1', 'GPL-2 or LGPL-2.1 or MPL-1.1' ]
);

# MPL
license_is(
	't/grant/MPL_and_more/symbolstore.py',
	[   'GPL-2+ or LGPL-2.1+ and/or MPL-1.1',
		'GPL-2+ or LGPL-2.1+ or MPL-1.1'
	]
);

# misc
license_is(
	't/grant/misc/rpplexer.h',
	[   'GPL-3 and/or LGPL-2.1 or LGPL-3',
		'GPL-3 or LGPL-2.1 with Qt exception or LGPL-3 with Qt exception or Qt'
	]
);

# MIT
license_like( 't/grant/MIT/gc.h', qr/MIT~Boehm|bdwgc/ );
license_is( 't/grant/MIT/old_colamd.c',    'bdwgc-matlab' );
license_is( 't/grant/MIT/harfbuzz-impl.c', 'MIT~old' );
license_is( 't/grant/MIT/spaces.c',        'MIT~oldstyle~permission' );

# NTP
license_is(
	[   qw(
			t/grant/NTP/helvO12.bdf
			t/grant/NTP/install.sh
			t/grant/NTP/directory.h
			t/grant/NTP/map.h
			t/grant/NTP/monlist.c
			)
	],
	'NTP'
);
license_is( 't/grant/NTP/gslcdf-module.c', 'NTP~disclaimer' );

# WTFPL
license_is( 't/grant/WTFPL/COPYING.WTFPL', 'WTFPL-1.0' );

done_testing;
