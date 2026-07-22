use strict;
use warnings;
use Test::More tests => 2;
use Alien::SNMP;

# The distribution version encodes the bundled Net-SNMP version as zero-padded
# two-digit components after the leading series digit, e.g. Net-SNMP 5.9.5.2 is
# encoded as "05090502" inside $VERSION 4.0509050200.  These two must be bumped
# in lockstep (the alienfile `gather` version and the module $VERSION); this
# test fails if only one of them is updated.

my $netsnmp_version = Alien::SNMP->version;

like $netsnmp_version, qr/^[0-9]+(?:\.[0-9]+)+$/,
  'reported_netsnmp_version__share_build__is_a_dotted_version';

my $encoded = join '', map { sprintf '%02d', $_ } split /\./, $netsnmp_version;

# Anchor the encoding immediately after the leading series digit.  (This cannot
# distinguish a proper prefix such as 5.9.5 from 5.9.5.2, because the trailing
# serial width is not fixed -- but it reliably catches a changed component, the
# lockstep failure mode that actually occurs on a version bump.)
like $Alien::SNMP::VERSION, qr/^[0-9]+\.\Q$encoded\E/,
  'module_version__share_build__encodes_reported_netsnmp_version';
