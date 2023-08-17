#!/usr/bin/env perl

use strict;
use warnings;

use Alien::librpm;
use Test::Alien;
use Test::Alien::Diag;
use Test::More;

alien_diag 'Alien::librpm';
alien_ok 'Alien::librpm';
my $xs = do { local $/; <DATA> };
xs_ok {
	xs => $xs,
	verbose => 0,
}, with_subtest {
	my ($module) = @_;
	my $version = $module->version;
	ok $version;
	note "version = $version";
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <rpm/rpmlib.h>

const char *
version(const char *class)
{
	printf("RPM version is '%s'.\n", rpmEVR);
	return rpmEVR;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
	const char *class;
