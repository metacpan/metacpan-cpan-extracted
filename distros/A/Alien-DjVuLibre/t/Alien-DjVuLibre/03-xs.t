#!/usr/bin/env perl

use strict;
use warnings;

use Alien::DjVuLibre;
use Test::Alien;
use Test::Alien::Diag;
use Test::More;

alien_diag 'Alien::DjVuLibre';
alien_ok 'Alien::DjVuLibre';
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

#include <libdjvu/ddjvuapi.h>

const char *
version(const char *class)
{
	printf ("version: %s\n", ddjvu_get_version_string());
	return ddjvu_get_version_string();
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
	const char *class;
