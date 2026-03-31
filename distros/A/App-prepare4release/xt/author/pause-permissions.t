#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
	my $ok = eval {
		require Test::PAUSE::Permissions;
		Test::PAUSE::Permissions->import('all_permissions_ok');
		1;
	};
	$ok
		or plan skip_all =>
		'Test::PAUSE::Permissions is required for this author test ($^X): '
		. ( $@ || 'unknown error' );
}

# Network / PAUSE; skips unless RELEASE_TESTING=1 (see perldoc Test::PAUSE::Permissions).
all_permissions_ok();
