#!/usr/bin/env perl

# The light and dark themes, and the preferences page that chooses between them.
#
# Test::Mojo cannot run a page's script, so the switching itself was checked in
# a browser (see "To check downloads for real" in CLAUDE.md).  What these tests
# hold is the structure that keeps it working:
#
#   - every page loads the theme before it is drawn, so dark never flashes light;
#   - every themed colour in the templates goes through a token that the dark
#     theme defines, so a new rule cannot leave pale text on a pale panel;
#   - saved charts read their colours as light, whichever theme is showing.

use strict;
use warnings;

use File::Find;
use File::Temp;
use FindBin qw($Bin);
use Mojo::DOM;
use Mojo::File qw(path);
use Test::Mojo;
use Test::Most;

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = File::Temp::tempdir(CLEANUP => 1);

my $TEMPLATES = "$Bin/../templates";
my $THEME     = path("$TEMPLATES/web/en/layouts/theme.html.tt")->slurp;

# The properties the themes colour.  fill and stroke are not among them: in the
# templates they belong to chart export code, which is the same in both themes.
my $THEMED = qr/(?<![-\w])(?:color|background(?:-color)?|border(?:-(?:top|bottom|left|right))?(?:-color)?)/;

sub _templates {
	my @files;
	find(sub { push @files, $File::Find::name if /\.html\.tt\z/ }, $TEMPLATES);
	return sort @files;
}

# How bright a colour is, from 0 (black) to 1 (white).
sub _lightness {
	my ($hex) = @_;
	$hex =~ s/\A#//;
	$hex = join '', map { "$_$_" } split //, $hex if length($hex) == 3;
	my ($r, $g, $b) = map { hex } substr($hex, 0, 6) =~ /(..)(..)(..)/;
	return (0.299 * $r + 0.587 * $g + 0.114 * $b) / 255;
}

subtest 'the preferences page' => sub {
	$t->get_ok('/preferences')->status_is(200)->content_type_like(qr{\Atext/html});

	my $dom = $t->tx->res->dom;
	my @values = map { $_->attr('value') } $dom->find('input[type=radio][name=theme]')->each;

	is_deeply [ sort @values ], [ qw(dark light system) ], 'it offers the three choices';
	is $dom->at('title')->text =~ s/\s.*//sr, 'Preferences', 'it has its own title';
	ok $dom->at('nav.back-link a[href="/"]'), 'the breadcrumb leads home';
	like $dom->at('nav.back-link')->all_text, qr/Preferences/, 'and names this page';
	ok $dom->at('#pref-status[role=status]'), 'a failure to save is announced';
	is $dom->at('#site-nav-help')->attr('href'), '/tutorial#preferences', 'Help opens its chapter';
	ok !$dom->at('input[name=theme][checked]'), 'the choice comes from the browser, not the server';
};

subtest 'every page can reach it and loads the theme first' => sub {
	for my $page ('/', '/view/sales', '/bar?l=table:sales&cat=region&val=amount', '/catalog',
		'/tutorial', '/preferences', '/view/no_such_table') {
		my $res  = $t->get_ok($page)->tx->res;
		my $body = $res->body;
		my $dom  = $res->dom;

		ok $dom->at('nav.site-nav a[href^="/preferences"]'), "$page links to the preferences";

		my $script = index $body, 'bi-pref:theme';
		my $body_at = index $body, '<body';
		my $first_rule = index $body, 'box-sizing';
		ok $script >= 0, "$page loads the theme";
		ok $script < $first_rule, "$page sets the theme before its first style rule";
		ok $script < $body_at, "$page sets it before the body exists, so nothing flashes";
	}
};

subtest 'the theme script' => sub {
	like $THEME, qr/localStorage\.getItem\(KEY\)/, 'reads the preference from local storage';
	like $THEME, qr/localStorage\.setItem\(KEY/, 'and writes it there';
	unlike $THEME, qr/['"]bi:theme['"]/, 'the key cannot collide with the layout of a table called theme';
	like $THEME, qr/addEventListener\('storage'/, 'follows a change made in another tab';
	like $THEME, qr/\@media screen \{\s*:root\[data-theme="dark"\]/,
		'dark is for the screen only: a print has no page background to sit on';

	for my $call ($THEME =~ /(window\.localStorage\.\w+\([^)]*\))/g) {
		like $THEME, qr/try \{\s*(?:var value = )?\Q$call\E/, "$call is guarded: storage can refuse";
	}
};

subtest 'one place decides what is dark' => sub {
	for my $file (_templates()) {
		next if $file =~ m{/layouts/theme\.html\.tt\z};
		my $text = path($file)->slurp;
		unlike $text, qr/prefers-color-scheme/, "$file does not ask the device itself";
		unlike $text, qr/data-theme/, "$file has no dark rules of its own";
	}
};

subtest 'every token a template uses has a dark value' => sub {
	my %defined = map { $_ => 1 } $THEME =~ /(--[a-z-]+)\s*:/g;
	ok $defined{'--page-bg'}, 'the dark values were found';

	for my $file (_templates()) {
		next if $file =~ m{/embed\.html\.tt\z};
		next if $file =~ m{/layouts/theme\.html\.tt\z}; # its comment names var(--token, ...)
		my $text = path($file)->slurp;
		my %used = map { $_ => 1 } $text =~ /var\((--[a-z-]+)/g;
		ok $defined{$_}, "$file: $_ is defined for dark" for sort keys %used;
	}
};

# A colour left bare is the same in both themes, which is right only for a part
# of the page that is dark in both: a filled button, a table head, a tooltip.  A
# bare pale background, or bare dark text, would be unreadable beside the dark
# theme's panels.
subtest 'every bare colour is one that works in both themes' => sub {
	for my $file (_templates()) {
		next if $file =~ m{/embed\.html\.tt\z}; # always light; see theme.html.tt
		next if $file =~ m{/layouts/theme\.html\.tt\z};
		my @bad;
		my $n = 0;
		for my $line (split /\n/, path($file)->slurp) {
			$n++;
			while ($line =~ /($THEMED)\s*:\s*([^;{}"'\n]*)/g) {
				my ($prop, $value) = ($1, $2);
				next if $value =~ /var\(/;
				for my $hex ($value =~ /(#[0-9a-fA-F]{3,8})\b/g) {
					my $pale = _lightness($hex) > 0.5;
					push @bad, "line $n: $prop: $hex"
						if $prop eq 'color' ? !$pale : $pale;
				}
			}
		}
		ok !@bad, "$file has none that would disappear" or diag join "\n", @bad;
	}
};

subtest 'saved charts stay light' => sub {
	my $export = path("$TEMPLATES/web/en/layouts/chart_export.html.tt")->slurp;
	like $export, qr/biChartExportClone = function \(svg\) \{\s*return window\.biTheme\.asLight\(/,
		'the copy of a chart reads its colours as they are in light';
	like $THEME, qr/asLight:.*setAttribute\('data-theme', 'light'\).*finally.*setAttribute\('data-theme', current\)/s,
		'and the page goes back to its theme, even after an error';

	my @chart_pages = grep { path($_)->slurp =~ /chart_export\.html\.tt/ } _templates();
	ok scalar(@chart_pages), 'the chart pages were found';
	for my $file (@chart_pages) {
		next if $file =~ /chart_export/;
		like path($file)->slurp, qr/layouts\/default\.html\.tt/,
			"$file has the layout that defines biTheme";
	}
};

subtest 'an embedded canvas keeps to the light colours' => sub {
	my $embed = path("$TEMPLATES/web/en/embed.html.tt")->slurp;
	unlike $embed, qr/theme\.html\.tt|data-theme|var\(--/,
		'it sits on a page whose colours it cannot know';
};

done_testing();
