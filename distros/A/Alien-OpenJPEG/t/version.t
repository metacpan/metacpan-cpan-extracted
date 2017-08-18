#!/usr/bin/env perl

use Test2::V0;
use Test::Alien;
use Alien::OpenJPEG;

subtest 'OpenJPEG version' => sub {
	alien_ok 'Alien::OpenJPEG';

	my $xs = do { local $/; <DATA> };
	xs_ok $xs, with_subtest {
		my($module) = @_;
		is $module->version, Alien::OpenJPEG->version,
			"Got openjp2 version @{[ Alien::OpenJPEG->version ]}";
	};
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "opj_config.h"
#include "openjpeg.h"

const char *
version(const char *class)
{
	return opj_version();
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
	const char *class;
