use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use App::Licensecheck;

plan 50;

my $app = App::Licensecheck->new(
	shortname_scheme => 'debian,spdx',
	top_lines        => 0,
);

my $todo;

# AFL
like [ $app->parse('t/grant/AFL_and_more/xdgmime.c') ], array {
	item 'AFL-2.0 and/or LGPL-2+';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/grant/AFL_and_more/xdgmime.c') ], array {
	item 'AFL-2.0 or LGPL-2+';
};
$todo = undef;

# AGPL
like [ $app->parse('t/grant/AGPL/fastx.c') ], array {
	item 'AGPL-3+';
};
like [ $app->parse('t/grant/AGPL/fet.cpp') ], array {
	item 'AGPL-3+';
};
like [ $app->parse('t/grant/AGPL/setup.py') ], array {
	item 'AGPL-3+';
};

# Apache
like [ $app->parse('t/grant/Apache_and_more/PIE.htc') ], array {
	item 'Apache-2.0 or GPL-2';
};
like [ $app->parse('t/grant/Apache_and_more/rust.lang') ], array {
	item 'Apache-2.0 or MIT~unspecified';
};
like [ $app->parse('t/grant/Apache_and_more/select2.js') ], array {
	item 'Apache-2.0 or GPL-2';
};
like [ $app->parse('t/grant/Apache_and_more/test_run.py') ], array {
	item 'UNKNOWN';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/grant/Apache_and_more/test_run.py') ], array {
	item 'Apache-2.0 or BSD-3-clause';
};
$todo = undef;

# CC-BY-SA
like [ $app->parse('t/grant/CC-BY-SA_and_more/WMLA') ], array {
	item 'UNKNOWN';
};
like [ $app->parse('t/grant/CC-BY-SA_and_more/cewl.rb') ], array {
	item 'CC-BY-SA-2.0';
};
like [ $app->parse('t/grant/CC-BY-SA_and_more/utilities.scad') ], array {
	item 'CC-BY-SA-3.0';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/grant/CC-BY-SA_and_more/WMLA') ], array {
	item 'CC-BY-SA-3.0 and/or GFDL-1.2';
};
like [ $app->parse('t/grant/CC-BY-SA_and_more/cewl.rb') ], array {
	item 'CC-BY-SA-2.0 or GPL-3';
};
like [ $app->parse('t/grant/CC-BY-SA_and_more/utilities.scad') ], array {
	item 'CC-BY-SA-3.0 or LGPL-2';
};
$todo = undef;

# EPL
like [ $app->parse('t/grant/EPL_and_more/Activator.java') ], array {
	item 'EPL-1.0';
};
like [ $app->parse('t/grant/EPL_and_more/Base64Coder.java') ], array {
	item 'UNKNOWN';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/grant/EPL_and_more/Activator.java') ], array {
	item 'BSD-3-clause~Refractions or EPL-1.0';
};
like [ $app->parse('t/grant/EPL_and_more/Base64Coder.java') ], array {
	item 'AGPL-3+ or Apache-2.0+ or EPL-1.0+ or GPL-3+ or LGPL-2.1+';
};
$todo = undef;

# LGPL
like [ $app->parse('t/grant/LGPL/Model.pm') ], array {
	item 'LGPL-2.1';
};
like [ $app->parse('t/grant/LGPL/PKG-INFO') ], array {
	item 'LGPL';
};
like [ $app->parse('t/grant/LGPL/criu.h') ], array {
	item 'LGPL-2.1';
};
like [ $app->parse('t/grant/LGPL/dqblk_xfs.h') ], array {
	item 'LGPL';
};
like [ $app->parse('t/grant/LGPL/exr.h') ], array {
	item 'LGPL';
};
like [ $app->parse('t/grant/LGPL/gnome.h') ], array {
	item 'LGPL-2.1';
};
like [ $app->parse('t/grant/LGPL/jitterbuf.h') ], array {
	item 'LGPL';
};
like [ $app->parse('t/grant/LGPL/libotr.m4') ], array {
	item 'LGPL-2.1';
};
like [ $app->parse('t/grant/LGPL/pic.c') ], array {
	item 'LGPL-3';
};
like [ $app->parse('t/grant/LGPL/strv.c') ], array {
	item 'LGPL-2.1+';
};
like [ $app->parse('t/grant/LGPL/table.py') ], array {
	item 'LGPL-2+';
};
like [ $app->parse('t/grant/LGPL/videoplayer.cpp') ], array {
	item 'LGPL-2.1 or LGPL-3';
};
like [ $app->parse('t/grant/LGPL_and_more/colamd.c') ], array {
	item 'LGPL-2.1+ and/or LGPL-bdwgc';
};
like [ $app->parse('t/grant/LGPL_and_more/da.aff') ], array {
	item 'UNKNOWN';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/grant/LGPL_and_more/da.aff') ], array {
	item 'GPL-2 or LGPL-2.1 or MPL-1.1';
};
$todo = undef;

# MPL
like [ $app->parse('t/grant/MPL_and_more/symbolstore.py') ], array {
	item 'GPL-2+ and/or GPL-2+ or LGPL-2.1+ and/or MPL-1.1';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/grant/MPL_and_more/symbolstore.py') ], array {
	item 'GPL-2+ or LGPL-2.1+ or MPL-1.1';
};
$todo = undef;

# misc
like [ $app->parse('t/grant/misc/rpplexer.h') ], array {
	item '(GPL-3 and/or LGPL-2.1 or LGPL-3) with Qt-LGPL-1.1 exception';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/grant/misc/rpplexer.h') ], array {
	item
		'GPL-3 or LGPL-2.1 with Qt exception or LGPL-3 with Qt-LGPL-1.1 exception or Qt';
};
$todo = undef;

# MIT
like [ $app->parse('t/grant/MIT/gc.h') ], array {
	item qr/MIT~Boehm|bdwgc/;
};
like [ $app->parse('t/grant/MIT/old_colamd.c') ], array {
	item 'bdwgc-matlab';
};
like [ $app->parse('t/grant/MIT/harfbuzz-impl.c') ], array {
	item 'MIT~old';
};
like [ $app->parse('t/grant/MIT/spaces.c') ], array {
	item 'MIT~oldstyle~permission';
};

# NTP
like [ $app->parse('t/grant/NTP/helvO12.bdf') ], array {
	item 'NTP';
};
like [ $app->parse('t/grant/NTP/directory.h') ], array {
	item 'NTP';
};
like [ $app->parse('t/grant/NTP/map.h') ], array {
	item 'NTP';
};
like [ $app->parse('t/grant/NTP/monlist.c') ], array {
	item 'NTP';
};
like [ $app->parse('t/grant/NTP/gslcdf-module.c') ], array {
	item 'NTP~disclaimer';
};
like [ $app->parse('t/grant/NTP/install.sh') ], array {
	item 'HPND-sell-variant';
};

# WTFPL
like [ $app->parse('t/grant/WTFPL/COPYING.WTFPL') ], array {
	item 'WTFPL-1.0';
};

done_testing;
