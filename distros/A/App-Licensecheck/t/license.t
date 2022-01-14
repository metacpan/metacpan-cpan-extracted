use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use App::Licensecheck;

plan 36;

my $app = App::Licensecheck->new(
	shortname_scheme => 'debian,spdx',
	top_lines        => 0,
);

like [ $app->parse('t/devscripts/academic.h') ], array {
	item 'AFL-3.0';
};

like [ $app->parse('t/grant/Apache/one_helper.rb') ], array {
	item 'Apache-2.0';
};

like [ $app->parse('t/devscripts/artistic-2-0-modules.pm') ], array {
	item 'Artistic-2.0';
};
like [ $app->parse('t/devscripts/artistic-2-0.txt') ], array {
	item 'Artistic-2.0';
};

like [ $app->parse('t/devscripts/beerware.cpp') ], array {
	item 'Beerware';
};

like [ $app->parse('t/devscripts/bsd-1-clause-1.c') ], array {
	item 'BSD-1-Clause';
};

like [ $app->parse('t/devscripts/bsd.f') ], array {
	item 'BSD-2-clause';
};

like [ $app->parse('t/devscripts/bsd-3-clause.cpp') ], array {
	item 'BSD-3-clause';
};
like [ $app->parse('t/devscripts/bsd-3-clause-authorsany.c') ], array {
	item 'BSD-3-clause';
};
like [ $app->parse('t/devscripts/bsd-regents.c') ], array {
	item 'BSD-3-clause';
};
like [ $app->parse('t/devscripts/mame-style.c') ], array {
	item 'BSD-3-clause';
};

like [ $app->parse('t/devscripts/boost.h') ], array {
	item 'BSL-1.0';
};

like [ $app->parse('t/devscripts/epl.h') ], array {
	item 'EPL-1.0';
};

# Lisp Lesser General Public License (BTS #806424)
# see http://opensource.franz.com/preamble.html
like [ $app->parse('t/devscripts/llgpl.lisp') ], array {
	item 'LLGPL';
};

like [ $app->parse('t/devscripts/gpl-no-version.h') ], array {
	item 'GPL';
};

like [ $app->parse('t/devscripts/gpl-1') ], array {
	item 'GPL-1+';
};

like [ $app->parse('t/devscripts/gpl-2') ], array {
	item 'GPL-2';
};
like [ $app->parse('t/devscripts/bug-559429') ], array {
	item 'GPL-2';
};
like [ $app->parse('t/devscripts/gpl-2-comma.sh') ], array {
	item 'GPL-2';
};
like [ $app->parse('t/devscripts/gpl-2-incorrect-address') ], array {
	item 'GPL-2';
};

like [ $app->parse('t/devscripts/gpl-2+') ], array {
	item 'GPL-2+';
};
like [ $app->parse('t/devscripts/gpl-2+.scm') ], array {
	item 'GPL-2+';
};

like [ $app->parse('t/devscripts/gpl-3.sh') ], array {
	item 'GPL-3';
};
like [ $app->parse('t/devscripts/gpl-3-only.c') ], array {
	item 'GPL-3';
};

like [ $app->parse('t/devscripts/gpl-3+') ], array {
	item 'GPL-3+';
};
like [ $app->parse('t/devscripts/gpl-3+-with-rem-comment.xml') ], array {
	item 'GPL-3+';
};
like [ $app->parse('t/devscripts/gpl-variation.c') ], array {
	item 'GPL-3+';
};

like [ $app->parse('t/devscripts/gpl-3+.el') ], array {
	item 'GPL-3+';
};
like [ $app->parse('t/devscripts/comments-detection.h') ], array {
	item 'GPL-3+';
};

like [ $app->parse('t/devscripts/mpl-1.1.sh') ], array {
	item 'MPL-1.1';
};

like [ $app->parse('t/devscripts/mpl-2.0.sh') ], array {
	item 'MPL-2.0';
};
like [ $app->parse('t/devscripts/mpl-2.0-comma.sh') ], array {
	item 'MPL-2.0';
};

like [ $app->parse('t/devscripts/freetype.c') ], array {
	item 'FTL';
};

like [ $app->parse('t/devscripts/cddl.h') ], array {
	item 'CDDL';
};

like [ $app->parse('t/devscripts/libuv-isc.am') ], array {
	item 'ISC';
};

like [ $app->parse('t/devscripts/info-at-eof.h') ], array {
	item 'Expat';
};

done_testing;
