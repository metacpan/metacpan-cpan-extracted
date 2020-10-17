#!/usr/bin/env perl

use Test2::V0;
use Test::Alien;
use Alien::Graphene;

use lib 't/lib';

subtest "Check flags" => sub {
	alien_ok 'Alien::Graphene';

	my $xs = do { local $/; <DATA> };
	xs_ok $xs, with_subtest {
		my($module) = @_;
		my @version_parts = (
			$module->major_version,
			$module->minor_version,
			$module->micro_version,
		);
		my $version = join ".", @version_parts;
		is $version, Alien::Graphene->version,
			"Got graphene version @{[ Alien::Graphene->version ]}";
	};
};

done_testing;
__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "graphene.h"

int
major_version(const char *class) { return GRAPHENE_MAJOR_VERSION; }

int
minor_version(const char *class) { return GRAPHENE_MINOR_VERSION; }

int
micro_version(const char *class) { return GRAPHENE_MICRO_VERSION; }

MODULE = TA_MODULE PACKAGE = TA_MODULE

int major_version(class);
	const char *class;

int minor_version(class);
	const char *class;

int micro_version(class);
	const char *class;
