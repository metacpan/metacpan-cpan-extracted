#!/usr/bin/perl

use strict;
use warnings;

use App::PTP::Util::Semver;
use Test::More;

sub cmp_ok_sign {
  my ($left, $right, $expected, $name) = @_;
  my $got = App::PTP::Util::Semver::compare($left, $right);
  my $sign = $got <=> 0;
  is($sign, $expected, $name);
}

# Numeric core comparison (the part that a lexicographic sort gets wrong).
cmp_ok_sign('1.9.0', '1.10.0', -1, '1.9.0 before 1.10.0');
cmp_ok_sign('1.1', '1.1.0', 0, '1.1 equals 1.1.0');

# Pre-release precedence.
cmp_ok_sign('1.0.0-alpha', '1.0.0', -1, 'pre-release before release');
cmp_ok_sign('1.1-alpha1', '1.1', -1, '1.1-alpha1 before 1.1');
cmp_ok_sign('1.0.0-alpha', '1.0.0-beta', -1, 'alpha before beta');
cmp_ok_sign('1.0.0-1', '1.0.0-alpha', -1, 'numeric identifier before alphanumeric');

# Optional leading 'v' and path-like prefix.
cmp_ok_sign('ptp/v1.0', 'ptp/v2.0', -1, 'major version is honored with a prefix');
cmp_ok_sign('abc/v9.0', 'ptp/v1.0', -1, 'prefixes are compared as strings first');
cmp_ok_sign('v1.2', '1.2', 0, 'a leading v is ignored');

# A dot before the first slash means the slash is not a prefix separator.
my $dotted = App::PTP::Util::Semver::parse('1.2/3');
is($dotted->{prefix}, '', 'no prefix when a dot precedes the slash');

# A multi-segment path-like prefix is recognized in full (the version part is
# the trailing 'v1.0.0', not 0 because of an over-eager dot split).
my $nested = App::PTP::Util::Semver::parse('refs/tags/projectname/v1.0.0');
is($nested->{prefix}, 'refs/tags/projectname', 'the full multi-segment prefix is captured');
is_deeply($nested->{core}, [1, 0, 0], 'the version core follows the multi-segment prefix');
is_deeply($nested->{warnings}, [], 'a multi-segment prefix produces no warning');
cmp_ok_sign('refs/tags/p/v1.9.0', 'refs/tags/p/v1.10.0', -1,
  'nested prefixes are grouped and ordered by version');

# Parsing warnings for non-numeric core components.
is_deeply(App::PTP::Util::Semver::parse('1.2.3')->{warnings}, [],
  'a clean version produces no warning');
my $warnings = App::PTP::Util::Semver::parse('abc')->{warnings};
is(scalar @$warnings, 1, 'a non-numeric core component produces one warning');
like($warnings->[0], qr/non-numeric component 'abc'/, 'the warning names the component');

done_testing;
