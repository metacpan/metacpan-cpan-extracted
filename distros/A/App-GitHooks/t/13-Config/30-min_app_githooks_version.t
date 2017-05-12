#!perl

use strict;
use warnings;

use App::GitHooks;
use App::GitHooks::Test;
use App::GitHooks::Utils;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;

plan(tests => 6);

# Require git.
test_requires_git( '1.7.4.1' );

App::GitHooks::Test::ok_reset_githooksrc(
	content => ''
);

lives_ok(
	sub {
		my $app = App::GitHooks->new(
			arguments => [],
			name      => 'commit-msg'
		);
	},
	'config is retrieved when no min_app_githooks_version is specified'
);

App::GitHooks::Test::ok_reset_githooksrc(
	content => "min_app_githooks_version = 10000000\n"
);

throws_ok(
	sub {
		my $app = App::GitHooks->new(
			arguments => [],
			name      => 'commit-msg'
		);
	},
	qr/Requires at least App::Githooks version 10000000/i,
	'throws expected error when min_app_githooks_version is greater than version'
);

App::GitHooks::Test::ok_reset_githooksrc(
	content => "min_app_githooks_version = 1.0.0\n"
);

lives_ok(
	sub {
		my $app = App::GitHooks->new(
			arguments => [],
			name      => 'commit-msg',
		);
	},
	'config is retrieved when min_app_githooks_version is less than version'
);
