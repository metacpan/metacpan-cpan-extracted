#!/usr/bin/env perl

use Test2::V0;
use Test::Alien;
use Alien::FontForge;

subtest 'FontForge version' => sub {
	alien_ok 'Alien::FontForge';

	my $xs = do { local $/; <DATA> };
	xs_ok {
		xs => $xs,
		verbose => 0,
		cbuilder_link => {
			extra_linker_flags =>
				# add -dylib_file since during test, the dylib is under blib/
				$^O eq 'darwin'
					? ' -dylib_file ' . join ":", map {
						"$_/lib/libfontforge.2.dylib"
					} (@{Alien::FontForge->runtime_prop}{qw(prefix distdir)}),
					: ' '
		},
	}, with_subtest {
		my($module) = @_;
		is $module->version, Alien::FontForge->version,
			"Got FontForge version @{[ Alien::FontForge->version ]}";
	};

};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef _

#include "fontforge.h"

const char *
version(const char *class)
{
	return PACKAGE_VERSION;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
	const char *class;
