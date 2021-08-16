use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.5.0';

use lib 't/lib';
use Test2::Licensecheck;

plan 45;

# Autotools
license_is(
	't/exception/Autoconf/autotroll.m4',
	'GPL-2+ with Autoconf-2.0~AutoTroll exception'
);
license_is(
	't/exception/Autoconf/ax_pthread.m4',
	'GPL-3+ with Autoconf-2.0~Archive exception'
);
license_is(
	't/exception/Autoconf/m4_ax_func_getopt_long.m4',
	'GPL-2+ with Autoconf-2.0~Archive exception'
);
license_is(
	't/exception/Autoconf/mkerrcodes1.awk',
	'GPL-2+ with Autoconf-2.0~g10 exception'
);
license_is(
	't/exception/Autoconf/pkg.m4',
	'GPL-2+ with Autoconf-data exception'
);

# Bison
license_is(
	't/exception/Bison/grammar.cxx',
	[   '(Apache-2.0 and/or GPL-2+ and/or MPL-2.0) with Bison-1.24 exception',
		'Apache-2.0 and/or GPL-2+ with Bison-1.24 exception and/or MPL-2.0'
	]
);
license_is(
	't/exception/Bison/parse-date.c',
	'GPL-3+ with Bison-2.2 exception'
);

# Classpath
license_is(
	't/exception/Classpath/CDDL-GPL-2-CP',
	[   '(CDDL-1.0 and/or GPL-2) with Classpath-2.0 exception',
		'CDDL-1.0 and/or GPL-2 with Classpath-2.0 exception'
	]
);
license_is(
	't/exception/Classpath/GPL-2-CP',
	'GPL-2 with Classpath-2.0 exception'
);
license_is(
	't/exception/Classpath/LICENSE',
	'GPL-2 with Classpath-2.0 exception'
);

# EPL
license_is(
	't/exception/EPL/mdb_bot_sup.erl',
	'(EPL and/or GPL-2+) with EPL-library exception'
);
license_is(
	't/exception/EPL/ts_proxy_http.erl',
	'(EPL and/or GPL-2+) with EPL-MPL-library exception'
);

# FAUST
license_is(
	't/exception/FAUST/alsa-dsp.h',
	'GPL-3+ with FAUST exception'
);

# Font
my $todo = todo 'not yet supported by Regexp::Pattern::License';
license_is(
	't/exception/Font/LICENSE',
	'AGPL-3 with PS-or-PDF-font exception'
);
$todo = undef;

# GCC
license_is(
	't/exception/GCC/unwind-cxx.h',
	'GPL-2+ with mif exception'
);

# GStreamer
license_is(
	't/exception/GStreamer/ev-properties-main.c',
	'GPL-2+ with GStreamer exception'
);
license_is(
	't/exception/GStreamer/hwp-properties-main.c',
	'GPL-2+ with GStreamer exception'
);
license_is(
	't/exception/GStreamer/totem-object.c',
	'GPL-2+ with GStreamer exception'
);

# Libtool
license_is(
	't/exception/Libtool/lt__dirent.h',
	'LGPL-2+ with Libtool exception'
);

# non-GPL
license_is(
	't/exception/non-GPL/buildnum.pl',
	'GPL-2 with 389 exception'
);

# OCaml
license_is(
	't/exception/OCaml/LICENSE.txt',
	'LGPL-2 with OCaml-LGPL-linking exception'
);

# OpenSSL
license_is(
	't/exception/OpenSSL/LICENSE',
	'GPL-2 with OpenSSL~s3 exception'
);
license_is(
	't/exception/OpenSSL/crypto_openssl.c',
	'LGPL-2.1+ with OpenSSL~LGPL exception'
);
license_is(
	't/exception/OpenSSL/pokerth.cpp',
	[   '(AGPL-3+ and/or OpenSSL) with OpenSSL exception',
		'AGPL-3+ with OpenSSL exception'
	]
);
license_is(
	't/exception/OpenSSL/retr.h',
	[   '(GPL-3+ and/or OpenSSL) with OpenSSL exception',
		'GPL-3+ with OpenSSL exception'
	]
);
license_is(
	't/exception/OpenSSL/simplexml.h',
	'GPL-3 with OpenSSL~s3 exception'
);

# Proguard
license_is(
	't/exception/Proguard/GPL-with-Proguard-exception',
	'GPL-2+ with Proguard exception'
);
license_is(
	't/exception/Proguard/LICENSE_exception.md',
	'GPL-2+ with Proguard exception'
);

# Qt
license_is(
	't/exception/Qt/kcmaudiocd.h',
	'GPL-2+ with Qt-kernel exception'
);
license_is(
	't/exception/Qt/konsolekalendaradd.h',
	'GPL-2+ with Qt-no-source exception'
);
license_is(
	't/exception/Qt/main.cpp',
	[   'GPL with Qt-GPL-Eclipse exception',
		'(GPL-2 or GPL-3) with Qt-GPL-Eclipse exception'
	]
);
license_is(
	't/exception/Qt/qatomic_aarch64.h',
	[   '(GPL-3 and/or LGPL-2.1) with Qt-LGPL-1.1 exception',
		'GPL-3 or LGPL-2.1 with Qt-LGPL-1.1 exception'
	]
);
license_is(
	't/exception/Qt/qsslconfiguration.h',
	[   '(GPL-3 and/or LGPL-2.1 or LGPL-3) with Qt-GPL-OpenSSL_AND_Qt-LGPL-1.1 exception',
		'GPL-3 with Qt-GPL-OpenSSL exception OR LGPL-2.1 with Qt-LGPL-1.1 exception'
	]
);

# SDC
license_is(
	't/exception/SDC/sdc.py',
	[   '(GPL-2+ and/or LGPL-2.1+) with SDC exception',
		'GPL-2+ with SDC exception'
	]
);

# Sollya
license_is(
	't/exception/Cecill/tv_implementpoly.reference',
	'CECILL-C with Sollya-4.1 exception'
);

# Warzone
license_is(
	't/exception/Warzone/COPYING.README',
	'GPL-2+ with Warzone exception'
);

# Xerces
license_is(
	't/exception/Xerces/generator.cxx',
	'GPL-2 with Xerces exception'
);

done_testing;
