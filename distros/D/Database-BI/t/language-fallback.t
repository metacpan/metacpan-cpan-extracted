#!/usr/bin/env perl

# A language with no template directory falls back to the default one.
#
# Database::BI's POD says so: setting language => 'de' tells the controller to
# look in templates/web/de/, and if that directory does not exist it falls back
# to the default language.  It did not.  _resolve_language only looked for the
# directory when the code it had resolved differed from the configured one, so
# the usual case - the operator's own setting, with the header absent or asking
# for the same language - was never checked, and the renderer was handed
# templates/web/de/tutorial.html.tt, which is not there: a 500, not a page.
#
# Both halves are covered here.  A language that has a directory is the one
# served, whatever the configuration; one that does not is replaced by the
# default language, for the configured code and for a code Accept-Language
# produced.
#
# The app is given a home of its own (MOJO_HOME) holding the checkout's
# templates plus 'fr' as a language that exists, built by the browser fixture's
# helper, so nothing is written into the checkout and 'de' is a language this
# application genuinely cannot serve.
#
#   prove -l t/language-fallback.t

use strict;
use warnings;

use Test::Most;
use File::Copy ();
use File::Path ();
use File::Spec ();
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Test::Mojo;

sub _copy_tree {
	my ($source, $target) = @_;

	File::Path::make_path($target) unless -d $target;

	opendir my $dh, $source or die "opendir $source: $!\n";
	my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	for my $entry (@entries) {
		my $from = File::Spec->catfile($source, $entry);
		my $to   = File::Spec->catfile($target, $entry);

		if (-d $from) {
			_copy_tree($from, $to);
			next;
		}

		File::Copy::copy($from, $to) or die "copy $from to $to: $!\n";
	}

	return $target;
}

sub _own_language_templates {
	my ($dir, $platform, $language) = @_;

	opendir my $dh, $dir or die "opendir $dir: $!\n";
	my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	for my $entry (@entries) {
		my $file = File::Spec->catfile($dir, $entry);

		if (-d $file) {
			_own_language_templates($file, $platform, $language);
			next;
		}
		next unless $file =~ /\.tt\z/;

		open my $in, '<', $file or die "read $file: $!\n";
		my $source = do { local $/; <$in> };
		close $in;

		$source =~ s{(\Q$platform\E)/en/}{$1/$language/}g;
		$source =~ s{<html\b}{<html data-language-dir="$language"}
			if $file =~ m{layouts[\\/]default\.html\.tt\z};

		open my $out, '>', $file or die "write $file: $!\n";
		print {$out} $source;
		close $out;
	}
}

sub _home_for_language {
	my ($args) = @_;

	my $language  = $args->{language};
	my $home      = File::Spec->catdir($args->{tmp}, 'home');
	my $templates = File::Spec->catdir($home, 'templates');

	_copy_tree('templates', $templates);

	for my $platform_dir (glob "$templates/*") {
		next unless -d $platform_dir;

		my $default = File::Spec->catdir($platform_dir, 'en');
		next unless -d $default;

		my $platform = path($platform_dir)->basename;
		my $target   = File::Spec->catdir($platform_dir, $language);

		_copy_tree($default, $target);
		_own_language_templates($target, $platform, $language);
	}

	return $home;
}

my $home = _home_for_language({
	tmp      => tempdir(CLEANUP => 1),
	language => 'fr',
});

# Before the application is built: Mojo::Home->detect() reads MOJO_HOME ahead of
# the location of the class, so every template directory lookup - the
# controller's checks and the renderer's paths - sees this tree.
$ENV{MOJO_HOME} = $home;

my $t = Test::Mojo->new('Database::BI');

# A request with no Accept-Language header is the ordinary case, and the one
# that was broken: the header is absent, so the configured language was returned
# without ever being looked for.
sub _page {
	my ($path, $headers) = @_;

	return $t->get_ok($path, $headers || {})->status_is(200)->tx->res->body;
}

subtest 'a language with a template directory is served' => sub {
	$t->app->config->{language} = 'fr';

	my $body = _page('/tutorial');
	like $body, qr/<html[^>]*lang="fr"/,
		'the page is in the configured language';
	like $body, qr/data-language-dir="fr"/,
		'and comes from its template directory, not the default one';
};

subtest 'a configured language with no directory falls back' => sub {
	# templates/web/de was never created; this is the operator in the POD.
	$t->app->config->{language} = 'de';

	my $body = _page('/tutorial');
	like $body, qr/<html[^>]*lang="en"/,
		'the page renders in the default language instead of failing';
	unlike $body, qr/data-language-dir/,
		'from the default language templates';

	_page('/');
	pass('the home page renders too, so every route gets the same answer');
};

subtest 'a browser asking for the unservable language falls back as well' => sub {
	$t->app->config->{language} = 'de';

	# CGI::Lingua is offered the configured language, so it can return it; the
	# directory check is what turns that into a page.
	my $body = _page('/tutorial', { 'Accept-Language' => 'de-DE,de;q=0.9' });
	like $body, qr/<html[^>]*lang="en"/,
		'a header naming the language that cannot be served still gets a page';
	unlike $body, qr/data-language-dir/,
		'from the default language templates';
};

subtest 'a browser asking for a servable language gets it' => sub {
	# The configured language is unservable, but the request names one that is:
	# the fallback must not override a language that can actually render.
	$t->app->config->{language} = 'de';

	my $body = _page('/tutorial', { 'Accept-Language' => 'fr-FR,fr;q=0.9' });
	like $body, qr/<html[^>]*lang="fr"/,
		'the language the browser asked for is used';
	like $body, qr/data-language-dir="fr"/,
		'from its template directory';
};

done_testing();
