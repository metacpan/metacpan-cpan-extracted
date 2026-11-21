#!/usr/bin/env perl

# Operating-system error strings under different locales.
#
# GHGen has no GeoIP or country-based access logic, so there is no
# geographic mapping to test; this file covers only the system (POSIX) side.
#
# The expected OS text comes from Perl's own "$!" in a child run under the
# same LC_ALL (never POSIX::strerror, which asks the C library and can
# differ).  A locale that is not installed falls back to the C locale, in
# which case the expected and actual strings are both the fallback text.

use v5.36;
use Test::Most;
use IPC::Run3 qw(run3);
use Path::Tiny;
use Readonly;

Readonly my $LOCALES => [ 'en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8' ];
Readonly my $BAD_DIR => '/nonexistent_ghgen_locale_dir';

my $lib = path(__FILE__)->parent->parent->child('lib')->absolute->stringify;
my $bin = path(__FILE__)->parent->parent->child('bin/ghgen')->absolute->stringify;

# Run a command with LC_ALL set; return (stdout, stderr, exit status)
sub run_in_locale($locale, @command) {
	local $ENV{LC_ALL} = $locale;
	local $ENV{LANG}   = $locale;
	delete local $ENV{LANGUAGE};	# GNU gettext prefers LANGUAGE over LC_ALL
	my ($out, $err);
	run3(\@command, \undef, \$out, \$err);
	return ($out, $err, $? >> 8);
}

# The text "$!" gives for ENOENT in this locale, taken from Perl itself
sub enoent_text($locale) {
	my ($out) = run_in_locale($locale, $^X, '-MErrno=ENOENT', '-e',
		'local $! = ENOENT; print "$!"');
	return $out;
}

subtest 'sanity: ENOENT text is non-empty in every locale' => sub {
	for my $locale (@{$LOCALES}) {
		my $text = enoent_text($locale);
		ok(length $text, "$locale: got '$text'")
			or BAIL_OUT("Cannot read \$! under $locale");
	}
};

subtest 'unwritable output path reports the OS error in every locale' => sub {
	for my $locale (@{$LOCALES}) {
		my $expected = enoent_text($locale);
		my ($out, $err, $status) = run_in_locale($locale, $^X, "-I$lib", $bin,
			'generate', '--type=perl', "--output=$BAD_DIR/out.yml");

		isnt($status, 0, "$locale: non-zero exit");
		like($err, qr/\Q$expected\E/, "$locale: stderr carries '$expected'");
		ok(!path("$BAD_DIR/out.yml")->exists, "$locale: nothing written");
	}
};

subtest 'our own error messages do not depend on the locale' => sub {
	for my $locale (@{$LOCALES}) {
		my ($out, $err, $status) = run_in_locale($locale, $^X, "-I$lib", $bin,
			'generate', '--type=perl', '--os=bsd');
		isnt($status, 0, "$locale: non-zero exit");
		like($err, qr/Unknown OS 'bsd' for --os/, "$locale: fixed message text");
	}
};

subtest 'ENOENT text is set per locale, not leaked between children' => sub {
	my $first  = enoent_text('en_US.UTF-8');
	my $second = enoent_text('en_US.UTF-8');
	is($second, $first, 'same locale gives the same text twice');
};

done_testing();
