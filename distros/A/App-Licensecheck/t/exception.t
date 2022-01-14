use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.5.0';

use App::Licensecheck;

plan 47;

my $app = App::Licensecheck->new(
	shortname_scheme => 'debian,spdx',
	top_lines        => 0,
);

my $todo;

# Autotools
like [ $app->parse('t/exception/Autoconf/autotroll.m4') ], array {
	item 'GPL-2+ with Autoconf-2.0~AutoTroll exception';
};
like [ $app->parse('t/exception/Autoconf/ax_pthread.m4') ], array {
	item 'GPL-3+ with Autoconf-2.0~Archive exception';
};
like [ $app->parse('t/exception/Autoconf/m4_ax_func_getopt_long.m4') ],
	array {
	item 'GPL-2+ with Autoconf-2.0~Archive exception';
	};
like [ $app->parse('t/exception/Autoconf/mkerrcodes1.awk') ], array {
	item 'GPL-2+ with Autoconf-2.0~g10 exception';
};
like [ $app->parse('t/exception/Autoconf/pkg.m4') ], array {
	item 'GPL-2+ with Autoconf-data exception';
};

# Bison
like [ $app->parse('t/exception/Bison/grammar.cxx') ], array {
	item
		'(Apache-2.0 and/or GPL-2+ and/or MPL-2.0) with Bison-1.24 exception';
};
like [ $app->parse('t/exception/Bison/parse-date.c') ], array {
	item 'GPL-3+ with Bison-2.2 exception';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/exception/Bison/grammar.cxx') ], array {
	item 'Apache-2.0 and/or GPL-2+ with Bison-1.24 exception and/or MPL-2.0';
};
$todo = undef;

# Classpath
like [ $app->parse('t/exception/Classpath/CDDL-GPL-2-CP') ], array {
	item '(CDDL-1.0 and/or GPL-2) with Classpath-2.0 exception';
};
like [ $app->parse('t/exception/Classpath/GPL-2-CP') ], array {
	item 'GPL-2 with Classpath-2.0 exception';
};
like [ $app->parse('t/exception/Classpath/LICENSE') ], array {
	item 'GPL-2 with Classpath-2.0 exception';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/exception/Classpath/CDDL-GPL-2-CP') ], array {
	item 'CDDL-1.0 and/or GPL-2 with Classpath-2.0 exception';
};
$todo = undef;

# EPL
like [ $app->parse('t/exception/EPL/mdb_bot_sup.erl') ], array {
	item '(EPL and/or GPL-2+) with EPL-library exception';
};
like [ $app->parse('t/exception/EPL/ts_proxy_http.erl') ], array {
	item '(EPL and/or GPL-2+) with EPL-MPL-library exception';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/exception/EPL/mdb_bot_sup.erl') ], array {
	item 'EPL with EPL-library exception and/or GPL-2+';
};
like [ $app->parse('t/exception/EPL/ts_proxy_http.erl') ], array {
	item 'EPL with EPL-MPL-library exception and/or GPL-2+';
};
$todo = undef;

# FAUST
like [ $app->parse('t/exception/FAUST/alsa-dsp.h') ], array {
	item 'GPL-3+ with FAUST exception';
};

# Font
$todo = todo 'not yet supported by Regexp::Pattern::License';
like [ $app->parse('t/exception/Font/LICENSE') ], array {
	item 'AGPL-3 with PS-or-PDF-font exception';
};
$todo = undef;

# GCC
like [ $app->parse('t/exception/GCC/unwind-cxx.h') ], array {
	item 'GPL-2+ with mif exception';
};

# GStreamer
like [ $app->parse('t/exception/GStreamer/ev-properties-main.c') ], array {
	item 'GPL-2+ with GStreamer exception';
};
like [ $app->parse('t/exception/GStreamer/hwp-properties-main.c') ], array {
	item 'GPL-2+ with GStreamer exception';
};
like [ $app->parse('t/exception/GStreamer/totem-object.c') ], array {
	item 'GPL-2+ with GStreamer exception';
};

# Libtool
like [ $app->parse('t/exception/Libtool/lt__dirent.h') ], array {
	item 'LGPL-2+ with Libtool exception';
};

# non-GPL
like [ $app->parse('t/exception/non-GPL/buildnum.pl') ], array {
	item 'GPL-2 with 389 exception';
};

# OCaml
like [ $app->parse('t/exception/OCaml/LICENSE.txt') ], array {
	item 'LGPL-2 with OCaml-LGPL-linking exception';
};

# OpenSSL
like [ $app->parse('t/exception/OpenSSL/LICENSE') ], array {
	item 'GPL-2 with OpenSSL~s3 exception';
};
like [ $app->parse('t/exception/OpenSSL/crypto_openssl.c') ], array {
	item 'LGPL-2.1+ with OpenSSL~LGPL exception';
};
like [ $app->parse('t/exception/OpenSSL/pokerth.cpp') ], array {
	item '(AGPL-3+ and/or OpenSSL) with OpenSSL exception';
};
like [ $app->parse('t/exception/OpenSSL/retr.h') ], array {
	item '(GPL-3+ and/or OpenSSL) with OpenSSL exception';
};
like [ $app->parse('t/exception/OpenSSL/simplexml.h') ], array {
	item 'GPL-3 with OpenSSL~s3 exception';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/exception/OpenSSL/pokerth.cpp') ], array {
	item 'AGPL-3+ with OpenSSL exception';
};
like [ $app->parse('t/exception/OpenSSL/retr.h') ], array {
	item 'GPL-3+ with OpenSSL exception';
};
$todo = undef;

# Proguard
like [ $app->parse('t/exception/Proguard/GPL-with-Proguard-exception') ],
	array {
	item 'GPL-2+ with Proguard exception';
	};
like [ $app->parse('t/exception/Proguard/LICENSE_exception.md') ], array {
	item 'GPL-2+ with Proguard exception';
};

# Qt
like [ $app->parse('t/exception/Qt/kcmaudiocd.h') ], array {
	item 'GPL-2+ with Qt-kernel exception';
};
like [ $app->parse('t/exception/Qt/konsolekalendaradd.h') ], array {
	item 'GPL-2+ with Qt-no-source exception';
};
like [ $app->parse('t/exception/Qt/main.cpp') ], array {
	item 'GPL with Qt-GPL-Eclipse exception';
};
like [ $app->parse('t/exception/Qt/qatomic_aarch64.h') ], array {
	item '(GPL-3 and/or LGPL-2.1) with Qt-LGPL-1.1 exception';
};
like [ $app->parse('t/exception/Qt/qsslconfiguration.h') ], array {
	item
		'(GPL-3 and/or LGPL-2.1 or LGPL-3) with Qt-GPL-OpenSSL_AND_Qt-LGPL-1.1 exception';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/exception/Qt/main.cpp') ], array {
	item '(GPL-2 or GPL-3) with Qt-GPL-Eclipse exception';
};
like [ $app->parse('t/exception/Qt/qatomic_aarch64.h') ], array {
	item 'GPL-3 or LGPL-2.1 with Qt-LGPL-1.1 exception';
};
like [ $app->parse('t/exception/Qt/qsslconfiguration.h') ], array {
	item
		'GPL-3 with Qt-GPL-OpenSSL exception or LGPL-2.1 with Qt-LGPL-1.1 exception';
};
$todo = undef;

# SDC
like [ $app->parse('t/exception/SDC/sdc.py') ], array {
	item '(GPL-2+ and/or LGPL-2.1+) with SDC exception';
};

$todo = todo 'not yet supported';
like [ $app->parse('t/exception/SDC/sdc.py') ], array {
	item 'GPL-2+ with SDC exception';
};
$todo = undef;

# Sollya
like [ $app->parse('t/exception/Cecill/tv_implementpoly.reference') ], array {
	item 'CECILL-C with Sollya-4.1 exception';
};

# Warzone
like [ $app->parse('t/exception/Warzone/COPYING.README') ], array {
	item 'GPL-2+ with Warzone exception';
};

# Xerces
like [ $app->parse('t/exception/Xerces/generator.cxx') ], array {
	item 'GPL-2 with Xerces exception';
};

done_testing;
