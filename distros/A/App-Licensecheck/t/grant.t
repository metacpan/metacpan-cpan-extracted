#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck tests => 44;

# AFL
is_licensed(
	't/grant/AFL_and_more/xdgmime.c',
	[ 'AFL-2.0 and/or LGPL-2+', 'AFL-2.0 or LGPL-2+' ]
);

# AGPL
is_licensed(
	[   qw(
			t/grant/AGPL/fastx.c
			t/grant/AGPL/fet.cpp
			t/grant/AGPL/setup.py
			)
	],
	'AGPL-3+'
);

# Apache
is_licensed( 't/grant/Apache_and_more/PIE.htc', 'Apache-2.0 or GPL-2' );
is_licensed(
	't/grant/Apache_and_more/rust.lang',
	'Apache-2.0 or MIT~unspecified'
);
is_licensed( 't/grant/Apache_and_more/select2.js', 'Apache-2.0 or GPL-2' );
is_licensed(
	't/grant/Apache_and_more/test_run.py',
	'Apache-2.0 or BSD-3-clause'
);

# CC-BY-SA
is_licensed(
	't/grant/CC-BY-SA_and_more/WMLA',
	'CC-BY-SA-3.0 and/or GFDL-1.2'
);
is_licensed( 't/grant/CC-BY-SA_and_more/cewl.rb', 'CC-BY-SA-2.0 or GPL-3' );
is_licensed(
	't/grant/CC-BY-SA_and_more/utilities.scad',
	'CC-BY-SA-3.0 or LGPL-2'
);

# EPL
is_licensed(
	't/grant/EPL_and_more/Base64Coder.java',
	[   'AGPL-3+ and/or Apache-2.0+ and/or EPL-1.0+ and/or LGPL-2.1+ or GPL-3+',
		'AGPL-3+ or Apache-2.0+ or EPL-1.0+ or GPL-3+ or LGPL-2.1+'
	]
);

# LGPL
is_licensed( 't/grant/LGPL/Model.pm', 'LGPL-2.1' );
is_licensed( 't/grant/LGPL/PKG-INFO', [ '', 'LGPL' ] );

is_licensed( 't/grant/LGPL/criu.h',          'LGPL-2.1' );
is_licensed( 't/grant/LGPL/dqblk_xfs.h',     'LGPL' );
is_licensed( 't/grant/LGPL/exr.h',           'LGPL' );
is_licensed( 't/grant/LGPL/gnome.h',         'LGPL-2.1' );
is_licensed( 't/grant/LGPL/jitterbuf.h',     'LGPL' );
is_licensed( 't/grant/LGPL/libotr.m4',       'LGPL-2.1' );
is_licensed( 't/grant/LGPL/pic.c',           'LGPL-3' );
is_licensed( 't/grant/LGPL/strv.c',          'LGPL-2.1+' );
is_licensed( 't/grant/LGPL/table.py',        'LGPL-2+' );
is_licensed( 't/grant/LGPL/videoplayer.cpp', 'LGPL-2.1 or LGPL-3' );
is_licensed(
	't/grant/LGPL_and_more/colamd.c',
	'LGPL-2.1+ and/or LGPL-bdwgc'
);
is_licensed(
	't/grant/LGPL_and_more/da.aff',
	[ 'LGPL-2.1 or GPL-2.0 and/or MPL-1.1', 'GPL-2 or LGPL-2.1 or MPL-1.1' ]
);

# MPL
is_licensed(
	't/grant/MPL_and_more/symbolstore.py',
	[   'GPL-2+ or LGPL-2.1+ and/or MPL-1.1',
		'GPL-2+ or LGPL-2.1+ or MPL-1.1'
	]
);

# misc
is_licensed(
	't/grant/misc/rpplexer.h',
	[   'GPL-3 and/or LGPL-2.1 or LGPL-3',
		'GPL-3 or LGPL-2.1 with Qt exception or LGPL-3 with Qt exception or Qt'
	]
);

# MIT
is_licensed( 't/grant/MIT/gc.h',            'bdwgc' );
is_licensed( 't/grant/MIT/old_colamd.c',    'bdwgc-matlab' );
is_licensed( 't/grant/MIT/harfbuzz-impl.c', 'MIT~old' );
is_licensed( 't/grant/MIT/spaces.c',        'MIT~oldstyle~permission' );

# NTP
is_licensed(
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
is_licensed( 't/grant/NTP/gslcdf-module.c', 'NTP~disclaimer' );

# WTFPL
is_licensed( 't/grant/WTFPL/COPYING.WTFPL', 'WTFPL-1.0' );

done_testing;
