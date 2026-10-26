#!/usr/bin/env perl

# Configuration a browser test names is the configuration the application has.
#
# The fixture used to pass data_dir, platform and language to
# Database::BI->new, where they are not attributes at all: the store, the
# scanners and the template resolver read config('data_dir'),
# config('platform') and config('language').  A test could therefore fill a
# temporary directory with fixtures and still be shown the checkout's own data/
# - both a false sense of isolation and a trap for the next test that relies on
# it - and app_config was copied onto the app after startup(), so a value that
# startup() had already read once was ignored too.
#
# So the fixture writes every value a test names into the config file the app
# reads at startup.  This asserts both halves.  The table in the named directory
# is on the home page and opens through /view, which only works if the directory
# reached the app before startup() resolved it.  And the app's own config holds
# each named value - a platform and app_config keys the app could not have got
# any other way - so a value the fixture supplies late, or does not supply at
# all, shows up here instead of being silently ignored.  What the fixture writes
# for each key is checked in t/browser-fixture.t, and the language key in a
# running app - which needs a template tree behind it - in t/browser-language.t.
#
#   AUTHOR_TESTING=1 prove -l t/browser-config.t
#
# It skips without AUTHOR_TESTING or without Firefox, like the other
# t/browser-*.t files.

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(encode_json decode_json);
use Mojo::File qw(path);
use Mojo::Util qw(url_escape);
use lib 't/lib';
use BI::Test::Browser ();

# data/sales.csv is what makes the negative assertion meaningful: the file the
# suite ships must exist, or "not listed" would be true for the wrong reason.
BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $dir = tempdir(CLEANUP => 1);
path(File::Spec->catfile($dir, 'probe_table.csv'))->spurt("id,name\n1,Alpha\n");

# Where the child writes the configuration it ended up with, read back below.
# The keys are named one by one rather than dumping the whole hash: config holds
# plugin options that are not JSON, and the question here is only whether the
# values this test named arrived.
my $dump_file = File::Spec->catfile(tempdir(CLEANUP => 1), 'config.json');

my $browser = BI::Test::Browser->new(
	data_dir   => $dir,
	platform   => 'mobile',
	app_config => {
		probe_note      => 'named-value',
		probe_structure => { header => [ 'a', 'b' ] },
	},
	app_setup  => sub {
		my $app    = shift;
		my $config = $app->config;
		path($dump_file)->spurt(encode_json({
			data_dir        => $config->{data_dir},
			model_dir       => $config->{model_dir},
			platform        => $config->{platform},
			language        => $config->{language},
			probe_note      => $config->{probe_note},
			probe_structure => $config->{probe_structure},
		}));
	},
);

subtest 'the app starts with the configuration the test named' => sub {
	ok -f $dump_file, 'the app was built (it wrote its configuration down)';
	my $config = decode_json(path($dump_file)->slurp);

	is $config->{data_dir}, $dir,
		'data_dir is the directory the test named, absolute as the app resolves it';
	is $config->{platform}, 'mobile',
		'a platform that is not the default reaches the app';
	isnt $config->{model_dir}, '.bi',
		'model_dir is not the checkout\'s shared store';
	like $config->{model_dir}, qr{\bmodels\z},
		'model_dir is the fixture\'s own directory';
	is $config->{probe_note}, 'named-value',
		'an app_config value reaches the app';
	is_deeply $config->{probe_structure}, { header => [ 'a', 'b' ] },
		'an app_config value keeps its structure';

	# This app is the default language.  A test that names another one gets a
	# template tree for it and checks what the pages then say: see
	# t/browser-language.t.
	is $config->{language}, 'en',
		'language is configuration the app holds, not an ignored attribute';
};

subtest 'the named directory is the one the app reads' => sub {
	$browser->navigate('/');

	ok $browser->wait_for(sub { $browser->find('.db-card .db-name') }, timeout => 10),
		'the home page lists its tables';

	my $listed = $browser->js(
		'return Array.prototype.map.call('
		. 'document.querySelectorAll(".db-card .db-name"),'
		. 'function (name) { return name.textContent.trim(); }).join("|");'
	);
	$listed = '' unless defined $listed;

	like $listed, qr/probe_table/,
		'the table in the directory the test named is offered';
	unlike $listed, qr/\bsales\b/,
		"a table that exists only in the checkout's data/ is not offered";

	$browser->navigate('/view/' . url_escape('probe_table'));

	ok $browser->wait_for(sub { $browser->find('table') }, timeout => 10),
		'/view opens the table from the named directory';
	like $browser->js(
		'var table = document.querySelector("table"); return table ? table.textContent : "";'
	), qr/Alpha/, 'and shows the fixture row';
};

# What this run established, for the job summary: a value the fixture names is
# the value the running application has, for the keys that used to be ignored.
$browser->proved(
	'GET / and /view reading the directory the test named: only its table is'
	. ' offered and it opens, while the app\'s own config holds the data_dir,'
	. ' platform and app_config values it could not have got any other way'
);

done_testing();
