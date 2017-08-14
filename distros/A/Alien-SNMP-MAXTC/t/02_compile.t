use strict;
use warnings;
use Test::More;
use Test::CChecker;
use Alien::SNMP::MAXTC;

plan tests => 1;

compile_output_to_note;

compile_with_alien 'Alien::SNMP::MAXTC';

compile_run_ok <<'C_CODE', "basic compile test";
#include <net-snmp/net-snmp-config.h>
#include <net-snmp/version.h>

int
main(int argc, char *argv[])
{
  const char *version;
  version = netsnmp_get_version();
  return 0;
}
C_CODE

1;
