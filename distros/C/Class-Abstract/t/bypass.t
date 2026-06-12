#!/usr/bin/perl
# t/bypass.t -- bypass mechanics for Class::Abstract.

use strict;
use warnings;

BEGIN { unshift @INC, 'lib' }

use Test::Most;
use Readonly;
use Scalar::Util qw(blessed);

my %config = (
	abstract_pkg => 'BY::Abstract',
);

use Class::Abstract;

{
	package BY::Abstract;
	use parent -norequire, 'Class::Abstract';
}

diag 'Bypass mechanics' if $ENV{TEST_VERBOSE};

# ---------------------------------------------------------------------------
# Baseline: enforcement is on by default (inside the harness we must clear
# both bypass paths to trigger the croak).
# ---------------------------------------------------------------------------

subtest 'enforcement fires when both bypass paths are disabled' => sub {
	plan tests => 1;

	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;

	throws_ok { BY::Abstract->new }
		qr/Cannot instantiate abstract class BY::Abstract directly/,
		'croak fires when enforcement is on';
};

# ---------------------------------------------------------------------------
# $BYPASS = 1 suppresses the croak.
# ---------------------------------------------------------------------------

subtest '$BYPASS = 1 suppresses the croak' => sub {
	plan tests => 2;

	local $Class::Abstract::BYPASS                 = 1;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;

	my $obj;
	lives_ok { $obj = BY::Abstract->new }
		'$BYPASS=1 suppresses enforcement';

	ok blessed($obj) && ref($obj) eq $config{abstract_pkg},
		'returned object is blessed into the abstract class (bypass active)';
};

# ---------------------------------------------------------------------------
# $BYPASS = 1 takes precedence over harness_bypass = 0.
# ---------------------------------------------------------------------------

subtest '$BYPASS=1 short-circuits even with harness_bypass=0' => sub {
	plan tests => 1;

	local $Class::Abstract::BYPASS                 = 1;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 1;

	lives_ok { BY::Abstract->new }
		'$BYPASS=1 wins regardless of harness_bypass setting';
};

# ---------------------------------------------------------------------------
# harness_bypass + HARNESS_ACTIVE suppresses the croak.
# ---------------------------------------------------------------------------

subtest 'HARNESS_ACTIVE + harness_bypass=1 suppresses the croak' => sub {
	plan tests => 1;

	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 1;
	local $ENV{HARNESS_ACTIVE}                     = 1;

	lives_ok { BY::Abstract->new }
		'harness_bypass+HARNESS_ACTIVE suppresses enforcement';
};

# ---------------------------------------------------------------------------
# harness_bypass=0 + HARNESS_ACTIVE does NOT suppress the croak.
# ---------------------------------------------------------------------------

subtest 'harness_bypass=0 re-enables enforcement even with HARNESS_ACTIVE' => sub {
	plan tests => 1;

	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 1;

	throws_ok { BY::Abstract->new }
		qr/Cannot instantiate abstract class/,
		'enforcement fires when harness_bypass=0 even with HARNESS_ACTIVE';
};

# ---------------------------------------------------------------------------
# Truthy strings for $BYPASS ('false', '0E0', 'no') enable bypass.
# This is a Perl truthiness gotcha -- any non-zero, non-empty, non-undef
# string is true in Perl, regardless of its English meaning.
# ---------------------------------------------------------------------------

subtest 'truthy strings enable $BYPASS (Perl truthiness gotcha)' => sub {
	plan tests => 3;

	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;

	for my $truthy_val ('false', '0E0', 'no') {
		local $Class::Abstract::BYPASS = $truthy_val;

		lives_ok { BY::Abstract->new }
			qq{\$BYPASS = "$truthy_val" (truthy in Perl) suppresses enforcement};
	}
};

# ---------------------------------------------------------------------------
# local $BYPASS is scoped -- outer scope is unaffected.
# ---------------------------------------------------------------------------

subtest 'local $BYPASS is properly scoped' => sub {
	plan tests => 2;

	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;

	{
		local $Class::Abstract::BYPASS = 1;
		lives_ok { BY::Abstract->new }
			'inside local block: bypass suppresses enforcement';
	}

	# After the local block, $BYPASS is restored to 0.
	throws_ok { BY::Abstract->new }
		qr/Cannot instantiate abstract class/,
		'outside local block: enforcement is restored';
};

done_testing;
