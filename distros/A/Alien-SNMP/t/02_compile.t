use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::SNMP;

alien_ok 'Alien::SNMP';

xs_ok <<'XS_CODE'
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <net-snmp/net-snmp-config.h>
#include <net-snmp/version.h>

MODULE = SNMP PACKAGE = SNMP

const char *
netsnmp_get_version()

XS_CODE
, with_subtest {
  my $version;
  ok $version = SNMP::netsnmp_get_version();
  note "version = $version";
};

done_testing;
