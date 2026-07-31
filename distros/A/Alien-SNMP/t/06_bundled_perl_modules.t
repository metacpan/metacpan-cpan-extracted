use strict;
use warnings;
use Test::More;
use Alien::SNMP;

# The Net-SNMP source bundles the SNMP and NetSNMP::* XS modules.  The alienfile
# builds them and hands them to this distribution's blib, so they install with
# Alien::SNMP itself.  They used to be copied straight into the running perl's
# site_lib from the *build* phase, which
#
#   * wrote outside $DESTDIR, failing wherever that target is not writable at build
#     time (CPAN smokers on system perl, root-owned site perl, packaging roots), and
#   * targeted whichever perl was first on PATH -- net-snmp finds its perl with
#     AC_PATH_PROG -- so on a smoker the modules were built for, and installed into,
#     an unrelated perl and the perl under test could not see them at all.
#
# Both failure modes are invisible on a developer box whose active perl is first on
# PATH, so these assertions are what stands in for that environment.

# Only modules whose shared libraries are covered by Alien::SNMP's use-time preload
# of libnetsnmp are exercised here.  NetSNMP::agent and NetSNMP::TrapReceiver also
# need libnetsnmpagent/libnetsnmptrapd, which resolve through the baked-in RUNPATH
# only once `make install` has populated the final share dir -- not during `make
# test`.
my @bundled_modules = qw(
  SNMP
  NetSNMP::OID
  NetSNMP::ASN
  NetSNMP::default_store
);

# Checked before the modules that depend on it: the preload matches libnetsnmp by
# a platform-specific filename pattern, and a pattern that matches nothing fails
# silently because the preload is deliberately best-effort.  An ELF-only pattern
# is what left macOS unable to load any of the modules below.
ok scalar(Alien::SNMP->_netsnmp_dynamic_libs),
  'preload_netsnmp__share_build__matches_the_dynamic_libnetsnmp'
  or diag "dynamic_libs:\n" . join '', map "  $_\n", Alien::SNMP->dynamic_libs;

require_ok $_ for @bundled_modules;

my $alien_lib_root   = _inc_root('Alien/SNMP.pm');
my $bundled_lib_root = _inc_root('SNMP.pm');

is $bundled_lib_root, $alien_lib_root,
  'bundled_snmp_module__built_distribution__loads_from_the_same_lib_root_as_the_alien'
  or diag "Alien::SNMP: $INC{'Alien/SNMP.pm'}\nSNMP:        $INC{'SNMP.pm'}";

done_testing;

# Which @INC entry a loaded module was found under.  Falls back to the full path so a
# mismatch is still reported usefully rather than as undef vs undef.
sub _inc_root {
    my ($file) = @_;
    my $path = $INC{$file};
    return "<$file not loaded>" unless defined $path;
    for my $dir (@INC) {
        next if ref $dir;
        return $dir if index($path, "$dir/") == 0;
    }
    return $path;
}
