#!/usr/bin/env perl

# The browser fixture's own code, checked without starting a browser.
#
# The keyboard job on CI failed with
#
#   hash- or arrayref expected (not a simple scalar, use allow_nonref to allow this)
#   at t/lib/BI/Test/Browser.pm line 428.
#
# ...six times, each killing a different browser test file.  Line 428 was
# focus() building its script with encode_json($selector): a JSON encoder that
# does not allow non-reference values refuses a bare string, and the one
# JSON::MaybeXS re-exports depends on which backend the machine happens to have.
# It is lenient here and was not there, so no local run could have caught it.
#
# These checks are about the fixture in isolation, so they run in the ordinary
# suite rather than only under AUTHOR_TESTING: the quote rule is the kind of
# thing that is easy to undo when adding the next JavaScript helper.
#
#   prove -l t/browser-fixture.t

use strict;
use warnings;

use Test::Most;
use Cwd ();
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use lib 't/lib';
use BI::Test::Browser ();

# focus() puts a selector into a JavaScript string literal.  A selector may hold
# a quote or a backslash - an attribute selector is the obvious way - and either
# would end the literal early if it were copied through as it is.
subtest 'a selector becomes a JavaScript string literal' => sub {
	is BI::Test::Browser::_js_string('#btn-map'), '"#btn-map"',
		'a plain selector is quoted, not bare';

	is BI::Test::Browser::_js_string(q{a[href="x"]}), '"a[href=\"x\"]"',
		'a quote inside the selector is escaped';

	is BI::Test::Browser::_js_string('a\\b'), '"a\\\\b"',
		'a backslash is doubled, so the literal holds one backslash';

	is BI::Test::Browser::_js_string("a\nb"), '"a\nb"',
		'a newline becomes an escape rather than ending the line';

	is BI::Test::Browser::_js_string("a\tb"), '"a\tb"',
		'a tab is escaped too';

	is BI::Test::Browser::_js_string("\x{2028}"), '"\u2028"',
		'a line separator is escaped; it is legal JavaScript but not legal in every engine';
};

# The rule that line 428 broke, stated once: only a data structure may be handed
# to the JSON encoder, because a scalar depends on the backend's allow_nonref.
subtest 'the fixture never asks a JSON backend to encode a bare scalar' => sub {
	my $file = 't/lib/BI/Test/Browser.pm';

	open my $fh, '<', $file or die "Cannot read $file: $!";
	my $source = do { local $/; <$fh> };
	close $fh;

	# The first thing after the parenthesis says what is being encoded.  A brace
	# or a bracket is a structure; anything else - a variable, a quote, a digit -
	# is a bare value the backend is free to refuse.
	my @bare;
	while ($source =~ /encode_json\s*\(\s*([^{\[\s])/g) {
		my $offset = $-[1];
		my $line   = 1 + (substr($source, 0, $offset) =~ tr/\n//);
		push @bare, "line $line";
	}

	is_deeply \@bare, [], 'every encode_json() call in the fixture is given a structure';

	like $source, qr/sub focus \{\s*my \(\$self, \$selector\) = \@_;\s*my \$quoted = _js_string\(\$selector\);/,
		'focus() quotes its selector with the fixture helper, not a JSON encoder';
};

# Every value a test names goes into the config file the app reads at startup -
# including the ones that are not directories.  platform and language used to be
# constructor arguments that nothing read, and app_config used to be copied onto
# the app after startup().  The source is checked here, without starting
# anything, because it is what the app will be given: a value that fails to reach
# this file is invisible to the app however carefully the rest is written.
subtest 'the config file carries every value a test names' => sub {
	my $source = BI::Test::Browser::_config_source({
		data_dir  => '/tmp/fixture/data',
		model_dir => '/tmp/fixture/models',
		platform  => 'mobile',
		language  => 'fr',
		app_config => {
			d3_url          => '/self-hosted/d3.js',
			probe_structure => { header => [ 'a', 'b' ] },
			probe_empty     => '',
			probe_undef     => undef,
		},
	});

	my $config = eval $source;
	is $@, '', 'the file is valid Perl';
	is ref $config, 'HASH', 'and returns the hash reference the Config plugin expects';

	is_deeply $config, {
		data_dir  => '/tmp/fixture/data',
		model_dir => '/tmp/fixture/models',
		platform  => 'mobile',
		language  => 'fr',
		d3_url          => '/self-hosted/d3.js',
		probe_structure => { header => [ 'a', 'b' ] },
		probe_empty     => '',
		probe_undef     => undef,
	}, 'a non-default platform and language, and app_config values and structures, all arrive';

	# A value is whatever the test wrote, so it is quoted: a bare 007 would be
	# read as octal and a bare TRUE as a bareword.
	like $source, qr/\A\{ .*language => 'fr'/,
		'a value is written as a quoted string';
};

subtest 'a value cannot break out of its literal' => sub {
	my $awkward = q{a\b'c"d} . "\n\te";

	my $config = eval BI::Test::Browser::_config_source({
		data_dir   => $awkward,
		platform   => 'web',
		language   => 'en',
		app_config => {},
	});
	is $@, '', 'a value with a backslash, quotes, a newline and a tab still compiles';
	is $config->{data_dir}, $awkward, 'and reads back unchanged';
};

subtest 'a value the config file cannot carry is named, not dropped' => sub {
	my $source = eval {
		BI::Test::Browser::_config_source({
			data_dir   => '/tmp/fixture/data',
			platform   => 'web',
			language   => 'en',
			app_config => { probe_callback => sub { 1 } },
		});
	};
	is $source, undef, 'a code reference is refused';
	like $@, qr/probe_callback/, 'and the message names the key';

	eval {
		BI::Test::Browser::_config_source({
			data_dir   => '/tmp/fixture/data',
			platform   => 'web',
			language   => 'en',
			app_config => { 'not a key' => 1 },
		});
	};
	like $@, qr/not a key/, 'a key that is not an identifier is refused too, rather than breaking in a child';
};

# A language needs a template directory, and the distribution ships one: 'en'.
# The tree the fixture builds for any other code is what makes the app able to
# run in it at all, so its shape is checked here, without starting anything.
subtest 'a language the distribution does not ship gets a template tree of its own' => sub {
	my $home = BI::Test::Browser::_home_for_language({
		tmp      => tempdir(CLEANUP => 1),
		language => 'fr',
	});

	ok -d "$home/templates/web/fr", 'the language has a directory under the platform';
	ok -f "$home/templates/web/fr/home.html.tt", 'holding the pages the routes render';
	ok -d "$home/templates/web/en", 'and the default language is still there, so nothing is lost';

	like path("$home/templates/web/fr/home.html.tt")->slurp,
		qr{WRAPPER 'web/fr/layouts/default\.html\.tt'},
		'the copy wraps its own layout, as a translation would, not the default language one';
	like path("$home/templates/web/fr/layouts/default.html.tt")->slurp,
		qr{<html\b[^>]*data-language-dir="fr"},
		'and its layout says which language directory the page came from';

	unlike path('templates/web/en/home.html.tt')->slurp, qr{web/fr/},
		'the templates in the checkout are not rewritten';
	unlike path('templates/web/en/layouts/default.html.tt')->slurp, qr{data-language-dir},
		'so the marker the browser test looks for cannot come from the shipped ones';
	ok !-d 'templates/web/fr', 'and no language directory was created in the checkout';
};

# Building a tree for the language is the usual case, but not the only state
# worth reaching: an operator who sets language => 'de' before adding
# templates/web/de/ has a configured language the app cannot serve, and the
# documented answer is the default language.  That needs the app to run on the
# templates it ships with the config still naming 'de', so the fixture has to be
# able to build no home at all.  The decision is checked here, without starting
# anything; t/browser-language.t checks what the page then says.
subtest 'a language can be named without a template tree behind it' => sub {
	my $tmp = tempdir(CLEANUP => 1);

	is BI::Test::Browser::_language_home({
		tmp                => $tmp,
		language           => 'de',
		language_templates => 0,
	}), undef, 'asking for no tree builds no home';

	ok !-d "$tmp/home",
		'so nothing is copied and the app keeps the templates it ships';
	ok !-d 'templates/web/de', 'and nothing is written into the checkout';

	my $home = BI::Test::Browser::_language_home({
		tmp                => $tmp,
		language           => 'de',
		language_templates => 1,
	});
	ok defined $home && -d "$home/templates/web/de",
		'while the default still builds one, so the flag is the only difference';

	is BI::Test::Browser::_language_home({ tmp => tempdir(CLEANUP => 1), language => 'en' }),
		undef, 'and the default language needs no home of its own';
};

# The report the browser jobs publish.  A summary that named the wrong file, or
# that let a second application overwrite the first one's pages, would be worse
# than no summary: it is the one place a reader looks to see what a green run
# actually drove.  The writer is checked here, without a browser, because it only
# touches what the fixture has already collected.
subtest 'the report names the test file and each of its fixtures' => sub {
	my $dir = tempdir(CLEANUP => 1);
	local $ENV{BI_BROWSER_REPORT_DIR} = $dir;

	my $fixture = sub {
		my ($index, %arg) = @_;

		return bless {
			report_index => $index,
			proved       => $arg{proved} || [],
			pages        => $arg{pages}  || {},
		}, 'BI::Test::Browser';
	};

	$fixture->(1, proved => ['GET /: the first claim'], pages => { '/' => [] })->_write_report;

	my $first = path("$dir/browser-fixture.t.md")->slurp;
	like $first, qr/^### browser-fixture\.t$/m,
		'the report is headed with the test file it came from';
	like $first, qr/^- proved: GET \/: the first claim$/m,
		'and carries the claim the test made';
	like $first, qr/^- pages loaded: \/$/m, 'and the pages it loaded';

	# A test that opens a second application has a second set of pages, and one
	# file per test file would have the later fixture erase the earlier one.
	$fixture->(2, pages => { '/' => ['North (chart)'] })->_write_report;

	is path("$dir/browser-fixture.t.md")->slurp, $first,
		'the second fixture does not overwrite the first fixture\'s report';

	my $second = path("$dir/browser-fixture.t.2.md")->slurp;
	like $second, qr/^### browser-fixture\.t \(fixture 2\)$/m, 'it has a file of its own';
	like $second, qr/^- cards on \/: North \(chart\)$/m, 'carrying the cards on its pages';
	like $second, qr/^- proved: no claim made/m,
		'and says no claim was made rather than leaving the report silent about it';

	# A local run sets no directory, and must leave nothing behind: the check is
	# made from inside a directory of its own, so a file written anywhere the test
	# can see is found rather than assumed absent.
	my $elsewhere = tempdir(CLEANUP => 1);
	my $was       = Cwd::getcwd();
	chdir $elsewhere or die "chdir $elsewhere: $!";
	my @written;
	{
		local $ENV{BI_BROWSER_REPORT_DIR};
		$fixture->(3, pages => { '/x' => [] })->_write_report;
		@written = glob('*.md');
	}
	chdir $was or die "chdir $was: $!";
	is_deeply \@written, [], 'nothing is written when the job asked for no report';
};

done_testing();
