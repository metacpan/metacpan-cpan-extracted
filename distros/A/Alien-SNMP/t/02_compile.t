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
  ok $version = SNMP::netsnmp_get_version(), 'netsnmp_get_version returns a value';
  note "version = $version";

  # Guards the "system libnetsnmp silently masks our build" class of bug: the
  # version reported by the library we actually compiled+linked against must be
  # the one this Alien declares.  If the loader resolved a system libnetsnmp of
  # a different version instead, this fails.
  is $version, Alien::SNMP->version,
    'netsnmp_version__compiled_against_alien_share__matches_declared_version';
};

done_testing;
