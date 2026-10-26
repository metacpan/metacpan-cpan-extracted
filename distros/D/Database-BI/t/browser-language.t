#!/usr/bin/env perl

# The language config key, in a running application.
#
# t/browser-config.t proves the app holds the value it was given, and
# t/browser-fixture.t proves the fixture writes it into the config file.  Neither
# answers the question an operator asks when they set language => 'fr': does the
# application serve pages in it?
#
# Setting the key is not enough to serve a language, which is why this needed the
# fixture to do more than write a value.  The controller resolves a language code
# and then renders templates/<platform>/<code>/, so a code with no directory
# behind it is a page that cannot be found, not a translation, and the
# distribution ships templates/web/en only.  BI::Test::Browser therefore gives the
# app a home for a non-default language: a copy of the templates, with the
# default language copied as the named one, whose pages say which directory they
# came from.
#
# The browser is told to ask for a language the deployment does not ship ('de').
# Accept-Language is tried first and the configured language is what answers when
# the browser names nothing available, so 'fr' on the page can only have come
# from the config key - asking for 'fr' would prove nothing, because the header
# alone would produce it.
#
# The control is the same page with the default language: it must say 'en' and
# carry no marker, or the assertions above would be true of any page at all.
#
# Two of the pages in the configured language are not the home page.  /view is a
# route of its own that renders its own template, so <html lang> there can only
# be the value that action handed to the layout; /bar is that page with a body
# the template does not contain - the chart's SVG and script come from
# HTML::D3 - so the attribute is written before the page's body exists.  A home
# page alone would notice neither an action that forgot to - and 35 of them did
# until every render was given it.
#
# The last part is the other state an operator reaches, and the one the POD says
# the fallback is for: language => 'de' with no templates/web/de/.  The fixture
# runs the app on the templates it ships for that (language_templates => 0), the
# config still says 'de', and the browser asks for German in Accept-Language as
# well - so an 'en' page can only be the fallback and not a request that happened
# to ask for English.  Before the controller checked the configured language for
# a directory this was a 500 rather than a page.
#
# That last state ends on the chart page too, and for the reason the fr part
# uses it: the home page and the tutorial are templates written out by hand,
# while the chart page's body is generated, so only there is the fallback
# proven against the HTML::D3 the app inserted rather than against a file.
#
#   AUTHOR_TESTING=1 prove -l t/browser-language.t
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

BI::Test::Browser->plan_browser_tests(required_files => ['templates/web/en/layouts/default.html.tt']);

my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'probe_table.csv');
path($csv)->spurt("id,name\n1,Alpha\n");

# What the app in the child ended up with, read back below.  The home is
# reported because the templates for 'fr' have to be in it for the page to
# render at all - the checkout has no such directory.
my $dump_file = File::Spec->catfile(tempdir(CLEANUP => 1), 'config.json');

my $browser = BI::Test::Browser->new(
	data_dir  => $dir,
	language  => 'fr',
	prefs     => { 'intl.accept_languages' => 'de' },
	app_setup => sub {
		my $app = shift;
		path($dump_file)->spurt(encode_json({
			language => $app->config->{language},
			home     => $app->home->to_string,
			has_templates => (-d $app->home->child('templates/web/fr')->to_string ? 1 : 0),
		}));
	},
);

subtest 'the app runs in the language the test named' => sub {
	ok -f $dump_file, 'the app was built (it wrote its configuration down)';
	my $config = decode_json(path($dump_file)->slurp);

	is $config->{language}, 'fr', 'the app holds the language from its config';
	is $config->{has_templates}, 1,
		'and has a template directory for it, without which every page would be a missing template';
	like $config->{home}, qr{/home\z},
		'from a home the fixture built for it rather than the checkout';

	ok !-d 'templates/web/fr',
		'and nothing was written into the checkout to get there';
};

subtest 'a page is rendered from that language, not the default one' => sub {
	$browser->navigate('/');

	ok $browser->wait_for(sub { $browser->find('.db-card .db-name') }, timeout => 10),
		'the home page renders';

	is $browser->js('return document.documentElement.getAttribute("data-language-dir");'),
		'fr', 'and comes from the fr template directory';

	is $browser->js('return document.documentElement.lang;'), 'fr',
		'and the home page declares that language in <html lang>, as the tutorial does';

	like $browser->js(
		'return Array.prototype.map.call('
		. 'document.querySelectorAll(".db-card .db-name"),'
		. 'function (n) { return n.textContent.trim(); }).join("|");'
	) // '', qr/probe_table/,
		'with the tables of the directory the test named, so the page is a real one';
};

subtest 'the language the controller resolved is the page\'s language' => sub {
	$browser->navigate('/tutorial');

	ok $browser->wait_for(sub { $browser->find('.tutorial') }, timeout => 10),
		'the tutorial renders';

	# The layout writes the resolved language into <html lang>, and this is the
	# page that passes it: an empty attribute would mean the controller
	# resolved nothing and the template said so.
	is $browser->js('return document.documentElement.lang;'), 'fr',
		'<html lang> is the configured language';

	is $browser->js('return document.documentElement.getAttribute("data-language-dir");'),
		'fr', 'and the page again came from the fr directory';
};

subtest 'a page that is not the home page declares it too' => sub {
	$browser->navigate('/view/' . url_escape('probe_table'));

	ok $browser->wait_for(sub { $browser->find('table') }, timeout => 10),
		'/view renders the table, so this is a page rather than an error';

	like $browser->js(
		'var table = document.querySelector("table"); return table ? table.textContent : "";'
	), qr/Alpha/, 'and shows the row from the directory the test named';

	# /view is a route of its own: it renders its own template through the same
	# layout, so the attribute here is the one that action passed.  The home page
	# proves nothing about it - and before every render was given the language,
	# this route served <html lang=""> while GET / was already correct.
	is $browser->js('return document.documentElement.lang;'), 'fr',
		'<html lang> is the configured language on a page reached by another action';

	is $browser->js('return document.documentElement.getAttribute("data-language-dir");'),
		'fr', 'and that page came from the fr directory too';
};

subtest 'a chart page declares the language around the chart it generated' => sub {
	$browser->navigate('/bar?l=' . url_escape("path:$csv") . '&cat=name');

	ok $browser->wait_for(sub { $browser->find('#bar_chart') }, timeout => 10),
		'the chart page renders';

	# This page's body is built rather than written in the template: the SVG
	# comes from HTML::D3, which the controller hands the column's categories
	# and the template inserts with the script that draws the bars.  The layout
	# writes <html lang> before any of that exists, so this is the page where it
	# could be lost - and the one no home page or table page stands in for.
	is $browser->js('return document.querySelector("#bar_chart").tagName.toLowerCase();'),
		'svg', 'and the chart it generated is on the page';

	# The generated snippet needs D3 from a CDN the fixture cannot reach, so the
	# bars are another test's business; the page's own script, which runs after
	# the snippet and creates the resize grip, proves the body around the chart
	# is live rather than an unrendered error.
	ok $browser->wait_for(sub { $browser->find('.chart-resize-handle') }, timeout => 10),
		'and the page script around the generated chart ran';

	is $browser->js('return document.documentElement.lang;'), 'fr',
		'<html lang> is the configured language on a page with generated chart HTML';

	is $browser->js('return document.documentElement.getAttribute("data-language-dir");'),
		'fr', 'and the page came from the fr directory too';
};

# What this app established, for the job summary: the configured language is
# what serves the pages, including the one whose body is generated.
$browser->proved(
	'GET /, /tutorial, /view and /bar with language fr configured and de asked'
	. ' for by the browser: every page comes from the fr template tree and'
	. ' declares <html lang>="fr"'
);

$browser->stop;

# ---------------------------------------------------------------------------
# The control: the same pages with the language the distribution ships.
# ---------------------------------------------------------------------------
my $default = BI::Test::Browser->new(data_dir => $dir);

$default->navigate('/');
ok $default->wait_for(sub { $default->find('.db-card .db-name') }, timeout => 10),
	'control: the home page renders in the default language';
is $default->js('return document.documentElement.lang;'), 'en',
	'control: its <html lang> is en, so the fr home page above is the config talking';

$default->navigate('/tutorial');
ok $default->wait_for(sub { $default->find('.tutorial') }, timeout => 10),
	'control: the tutorial renders in the default language';

is $default->js('return document.documentElement.lang;'), 'en',
	'control: <html lang> is en, so the assertion above is about the config value';
is $default->js('return document.documentElement.getAttribute("data-language-dir");'),
	undef, 'control: and the marker is only on the fixture\'s copy, so its presence means something';

$default->navigate('/view/' . url_escape('probe_table'));
ok $default->wait_for(sub { $default->find('table') }, timeout => 10),
	'control: /view renders in the default language too';
is $default->js('return document.documentElement.lang;'), 'en',
	'control: its <html lang> is en, so the fr /view page above is the config talking';

$default->navigate('/bar?l=' . url_escape("path:$csv") . '&cat=name');
ok $default->wait_for(sub { $default->find('#bar_chart') }, timeout => 10),
	'control: the chart page renders in the default language';
is $default->js('return document.documentElement.lang;'), 'en',
	'control: its <html lang> is en, so the fr chart page above is the config talking';

$default->proved(
	'the same four pages with the default language: <html lang>="en" and no fr'
	. ' marker, so the assertions above are about the config and not about any page'
);

$default->stop;

# ---------------------------------------------------------------------------
# A configured language with no template tree behind it: the fallback.
# ---------------------------------------------------------------------------
my $fallback_dump = File::Spec->catfile(tempdir(CLEANUP => 1), 'config.json');

my $fallback = BI::Test::Browser->new(
	data_dir           => $dir,
	language           => 'de',
	language_templates => 0,
	prefs              => { 'intl.accept_languages' => 'de' },
	app_setup          => sub {
		my $app = shift;
		path($fallback_dump)->spurt(encode_json({
			language      => $app->config->{language},
			home          => $app->home->to_string,
			has_templates => (-d $app->home->child('templates/web/de')->to_string ? 1 : 0),
			has_default   => (-d $app->home->child('templates/web/en')->to_string ? 1 : 0),
		}));
	},
);

subtest 'a language with no template directory falls back to the default' => sub {
	ok -f $fallback_dump, 'the app was built (it wrote its configuration down)';
	my $config = decode_json(path($fallback_dump)->slurp);

	is $config->{language}, 'de', 'the config names a language the distribution does not ship';
	is $config->{has_templates}, 0, 'with no template directory behind it';
	is $config->{has_default}, 1, 'while the default language is the one the app does ship';

	$fallback->navigate('/');

	ok $fallback->wait_for(sub { $fallback->find('.db-card .db-name') }, timeout => 10),
		'the home page renders, rather than failing on a template that is not there';

	# Both the config and the browser's Accept-Language ask for 'de', so 'en'
	# here is the fallback and cannot be a request that happened to ask for it.
	is $fallback->js('return document.documentElement.lang;'), 'en',
		'and the page says it is in the default language, though de was asked for twice';

	is $fallback->js('return document.documentElement.getAttribute("data-language-dir");'),
		undef, 'from the shipped templates: there is no copy of them under de';

	like $fallback->js(
		'return Array.prototype.map.call('
		. 'document.querySelectorAll(".db-card .db-name"),'
		. 'function (n) { return n.textContent.trim(); }).join("|");'
	) // '', qr/probe_table/,
		'with the tables of the directory the test named, so the page is a real one';

	$fallback->navigate('/tutorial');

	ok $fallback->wait_for(sub { $fallback->find('.tutorial') }, timeout => 10),
		'a second route falls back the same way';

	is $fallback->js('return document.documentElement.lang;'), 'en',
		'and the tutorial declares the default language too';
};

subtest 'the fallback holds on a page whose body is generated' => sub {
	$fallback->navigate('/bar?l=' . url_escape("path:$csv") . '&cat=name');

	ok $fallback->wait_for(sub { $fallback->find('#bar_chart') }, timeout => 10),
		"the chart page renders in the default language rather than failing on a template that is not there";

	# The same page as the fr chart above, but reached through the fallback: its
	# SVG comes from HTML::D3 and the template inserts the script that fills it,
	# so the body is built rather than written out.  The home page and the
	# tutorial are both written templates, so neither says this survives.
	is $fallback->js('return document.querySelector("#bar_chart").tagName.toLowerCase();'),
		'svg', 'and the chart it generated is on the page, so this is that page and not an error';

	ok $fallback->wait_for(sub { $fallback->find('.chart-resize-handle') }, timeout => 10),
		'and the page script around the generated chart ran';

	# Both the config and the browser's Accept-Language ask for 'de', so 'en'
	# here is the fallback and cannot be a request that happened to ask for it.
	is $fallback->js('return document.documentElement.lang;'), 'en',
		'<html lang> is the default language, though de was asked for twice';

	is $fallback->js('return document.documentElement.getAttribute("data-language-dir");'),
		undef, 'from the shipped templates: there is no copy of them under de';
};

# What this app established, for the job summary: a language with no template
# tree behind it serves the default one instead of failing.
$fallback->proved(
	'GET /, /tutorial and /bar with language de configured and no de template'
	. ' tree: the pages render from the shipped templates and declare'
	. ' <html lang>="en", with no de marker'
);

$fallback->stop;

done_testing();
