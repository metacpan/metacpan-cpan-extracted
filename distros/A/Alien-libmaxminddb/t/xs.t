#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Test::More;
use Test::Alien;
use Alien::libmaxminddb;

alien_ok 'Alien::libmaxminddb';
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my ($module) = @_;
  ok $module->version;
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <maxminddb.h>

const char *
version(const char *class)
{
  return MMDB_lib_version();
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
    const char *class;
