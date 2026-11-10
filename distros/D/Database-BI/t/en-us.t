#!/usr/bin/env perl

# American English: templates/<platform>/en-us/ is templates/<platform>/en/ in
# American spelling, made by author/make-en-us from the word list in
# t/lib/BI/Test/EnUS.pm.  This file checks
#   * the respelling rule itself: prose changes, names the code reads do not;
#   * that en-us is what the generator makes of en today, file for file, so a
#     change to an en page that was not carried over fails here;
#   * that a browser asking for en-US gets those pages, and every other
#     English (en-GB, en-CA, plain en) and no header get en.
#
#   prove -l t/en-us.t

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Find ();
use File::Spec ();
use File::Temp ();
use Test::Most;
use Test::Mojo;

use BI::Test::EnUS qw(americanize expected_tree target_language);

subtest 'the rule: prose is respelled' => sub {
	is(americanize('Colour scheme'), 'Color scheme', 'a capital stays a capital');
	is(americanize('the first colour, then colours'), 'the first color, then colors', 'every word');
	is(americanize('COLOUR'), 'COLOR', 'capitals stay capitals');
	is(americanize('Show a hole in the centre'), 'Show a hole in the center', 'centre');
	is(americanize('Summarise the data'), 'Summarize the data', '-ise verbs');
	is(americanize('10 rows analysed'), '10 rows analyzed', 'analysed');
	is(americanize("'Cancelled; drawing'"), "'Canceled; drawing'", 'a sentence in a script string');
	is(americanize('data-label="Colours"'), 'data-label="Colors"', 'a label in an attribute, however short');
	is(americanize('the light colours: a browser'), 'the light colors: a browser', 'a colon in prose');
	is(americanize('<html lang="en">'), '<html lang="en-us">', 'the embed page names its language');
	is(americanize('analyses'), 'analyses', 'a word spelled the same in both is left');
};

subtest 'the rule: names the code reads are not' => sub {
	for my $name (
		'txColour', 'syncTreemapColour', 'o.colour', 'tx-colour', 'id="tx-colour-auto"',
		q{field('colour')}, 'field("colour")', '{ colour: x }', 'a, colour: b',
		'aria-labelledby', 'colour_auto', '#colour', '$colour', 'path/centre',
		'Colour-coding', 're-serialises',
	) {
		is(americanize($name), $name, "$name is unchanged");
	}
};

my $templates = File::Spec->catdir($Bin, '..', 'templates');
my $want      = expected_tree($templates);
my $us        = target_language();

ok(scalar(keys %{$want}) > 20, 'the en templates were found');

subtest 'en-us is what author/make-en-us makes of en' => sub {
	my %have;
	opendir(my $dh, $templates) or BAIL_OUT("cannot read $templates: $!");
	for my $platform (grep { !/\A\./ } readdir $dh) {
		my $dir = File::Spec->catdir($templates, $platform, $us);
		next unless -d $dir;
		File::Find::find({
			no_chdir => 1,
			wanted   => sub {
				return unless -f $_;
				my $rel = File::Spec->abs2rel($_, $dir);
				$rel =~ s{\\}{/}g;
				open(my $fh, '<:raw', $_) or BAIL_OUT("cannot read $_: $!");
				local $/;
				$have{"$platform/$us/$rel"} = <$fh>;
				close $fh;
			},
		}, $dir);
	}
	closedir $dh;

	is_deeply([ sort keys %have ], [ sort keys %{$want} ],
		'the same files as en') or diag('Run: perl author/make-en-us');

	for my $rel (sort keys %{$want}) {
		next unless defined $have{$rel};
		ok($have{$rel} eq $want->{$rel}, "templates/$rel is up to date")
			or diag('Run: perl author/make-en-us');
	}

	# Something did change, or this checks a copy and proves nothing.
	my $dashboard = "web/$us/dashboard.html.tt";
	like($have{$dashboard} // '', qr/Color scheme/, 'the American pages are respelled');
	unlike($have{$dashboard} // '', qr/>Colour scheme</, 'everywhere');
	like($have{$dashboard} // '', qr/syncTreemapColour/, 'but keep their names');
};

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = File::Temp::tempdir(CLEANUP => 1);

subtest 'a browser asking for en-US gets the American pages' => sub {
	for my $header ('en-US', 'en-us', 'en-US,en;q=0.9') {
		$t->get_ok('/view/sales', { 'Accept-Language' => $header })->status_is(200)
			->content_like(qr/<html lang="en-us">/, "$header: the page says so")
			->content_like(qr/Color scheme/, "$header: Color")
			->content_unlike(qr/Colour scheme/, "$header: not Colour");
	}
};

subtest 'every other English gets en' => sub {
	for my $header ('en-GB', 'en', 'en-CA', 'fr', undef) {
		my $name = $header // 'no header';
		$t->get_ok('/view/sales', defined $header ? { 'Accept-Language' => $header } : {})
			->status_is(200)
			->content_like(qr/<html lang="en">/, "$name: en")
			->content_like(qr/Colour scheme/, "$name: Colour");
	}
};

subtest 'language => "en-us" in the config chooses it without a header' => sub {
	local $t->app->config->{language} = 'en-us';
	$t->get_ok('/view/sales')->status_is(200)
		->content_like(qr/<html lang="en-us">/, 'the configured variant');
	$t->get_ok('/view/sales', { 'Accept-Language' => 'en-GB' })->status_is(200)
		->content_like(qr/<html lang="en">/, 'and a browser asking for en-GB still gets en');
};

done_testing();
