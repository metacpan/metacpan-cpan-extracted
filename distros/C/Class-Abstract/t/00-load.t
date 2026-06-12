#!/usr/bin/perl
# t/00-load.t -- verify the module loads and exports the expected interface.

use strict;
use warnings;

BEGIN { unshift @INC, 'lib' }

use Test::Most;

# Module must load cleanly.
use_ok('Class::Abstract');

# $VERSION must be defined and look like a version string.
ok defined($Class::Abstract::VERSION),
	'$VERSION is defined';
like $Class::Abstract::VERSION, qr/\A\d+\.\d+/,
	'$VERSION looks like a version number';

# Public variables must exist with correct defaults.
is $Class::Abstract::BYPASS, 0,
	'$BYPASS defaults to 0';
is $Class::Abstract::config{harness_bypass}, 1,
	'$config{harness_bypass} defaults to 1';

# Public methods must be present.  Parentheses required: without them Perl
# parses "ok CLASS->can(...)" as CLASS->can()->ok(...), not ok(CLASS->can(...)).
ok( Class::Abstract->can('new'),            'Class::Abstract->can("new")' );
ok( Class::Abstract->can('import'),         'Class::Abstract->can("import")' );
ok( Class::Abstract->can('is_abstract'),    'Class::Abstract->can("is_abstract")' );
ok( Class::Abstract->can('check_abstract'), 'Class::Abstract->can("check_abstract")' );

# Class::Abstract itself must be abstract (cannot be instantiated).
{
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;

	throws_ok { Class::Abstract->new }
		qr/Cannot instantiate abstract class Class::Abstract directly/,
		'Class::Abstract itself cannot be instantiated';
}

done_testing;
