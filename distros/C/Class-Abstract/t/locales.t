#!/usr/bin/perl
# t/locales.t -- Class::Abstract must behave identically under any locale.
#
# The module raises plain English messages built by sprintf from constant
# templates, and never reads $! or calls into the C library for text.  These
# tests pin that down: under en_US, de_DE and ja_JP the messages are
# byte-identical, results are unchanged, and $! (errno) is never clobbered.
#
# There is no GeoIP section: the module has no country- or region-dependent
# behaviour, so such tests would assert nothing.

use strict;
use warnings;

use Errno  qw(ENOENT);
use POSIX  qw(setlocale LC_ALL);
use Readonly;
use Test::Most;

use Class::Abstract ();

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Locales under test: Western European (English, German) and East Asian.
# Any that are not installed are still exercised (Perl falls back to "C");
# a diag says so, because the guarantee under test is locale-independence.
Readonly::Array my @LOCALES => qw(en_US.UTF-8 de_DE.UTF-8 ja_JP.UTF-8);

# Exact expected messages -- the public contract in the POD's MESSAGES tables
Readonly::Hash my %EXPECT => (
	abstract  => 'Cannot instantiate abstract class LT::Abstract directly',
	new_ref   => 'new() invocant must be a class name or blessed object, got ARRAY',
	new_undef => 'new() requires a defined class name as invocant',
	chk_undef => 'check_abstract() requires a defined class name',
	isa_ref   => 'is_abstract() requires a class name or object invocant, got HASH',
);

# Strip Carp's " at FILE line N.\n" so only the message itself is compared
sub message_of {
	my ($err) = @_;
	$err =~ s/ at \S+ line \d+\.?\n\z//;
	return $err;
}

# Run a block with enforcement switched on (see CLAUDE.md, "Testing patterns")
sub enforcement_on (&) {
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

{
	package LT::Abstract;
	our @ISA = ('Class::Abstract');
}
{
	package LT::Concrete;
	our @ISA = ('LT::Abstract');
}

# Remember the starting locale so each subtest can restore it
my $original_locale = setlocale(LC_ALL);

# ---------------------------------------------------------------------------
# In-process: switch locale with setlocale() and exercise every error path
# ---------------------------------------------------------------------------

foreach my $locale (@LOCALES) {
	subtest "in-process, LC_ALL=$locale" => sub {
		plan tests => 9;

		local $ENV{LC_ALL} = $locale;
		note "locale $locale not installed; testing under the C fallback"
			unless defined setlocale(LC_ALL, $locale);

		# Source the OS text for ENOENT from Perl's own layer (not
		# POSIX::strerror) so it matches whatever this locale produces.
		local $! = ENOENT;
		my $os_text = "$!";

		# Every error path yields the exact English message ...
		my %got;
		enforcement_on {
			eval { LT::Abstract->new };                     $got{abstract}  = message_of($@);
			eval { Class::Abstract::new([]) };              $got{new_ref}   = message_of($@);
			eval { Class::Abstract::new(undef) };           $got{new_undef} = message_of($@);
			eval { Class::Abstract::check_abstract('') };   $got{chk_undef} = message_of($@);
			eval { Class::Abstract::is_abstract({}) };      $got{isa_ref}   = message_of($@);
		};
		is( $got{$_}, $EXPECT{$_}, "$_ message is locale-independent" ) for sort keys %EXPECT;

		# ... with no OS error text leaking into it
		ok( !grep({ index($_, $os_text) >= 0 } values %got), 'no strerror text in any message' );

		# Successful paths are unaffected, and errno survives all of the above
		local $! = ENOENT;
		my $obj = enforcement_on { LT::Concrete->new };
		is( ref($obj), 'LT::Concrete', 'concrete construction works' );
		is( LT::Abstract->is_abstract, 1, 'is_abstract result unchanged' );
		is( 0 + $!, ENOENT, '$! is not clobbered by Class::Abstract' );

		setlocale(LC_ALL, $original_locale);
	};
}

# ---------------------------------------------------------------------------
# Child process: LC_ALL in the environment is applied by perl at start-up,
# which is how a real program meets it.
# ---------------------------------------------------------------------------

SKIP: {
	skip 'list-form pipe open is not portable to this platform', scalar @LOCALES
		if $^O eq 'MSWin32';

	# The child croaks on the abstract class and prints the message
	my $child_code = q{
		use Class::Abstract ();
		@LT::Abstract::ISA = ('Class::Abstract');
		local $Class::Abstract::config{harness_bypass} = 0;
		eval { LT::Abstract->new };
		print $@;
	};

	foreach my $locale (@LOCALES) {
		local $ENV{LC_ALL} = $locale;

		# Silence perl's start-up "Setting locale failed" warning when the
		# locale is not installed; the fallback is still a valid test.
		local $ENV{PERL_BADLANG} = 0;

		# Pass our @INC so the child loads the same Class::Abstract
		open(my $fh, '-|', $^X, (map { "-I$_" } grep { !ref } @INC), '-e', $child_code)
			or die "Cannot run $^X: $!";
		my $out = do { local $/; <$fh> };
		close $fh;

		is( message_of($out), $EXPECT{abstract}, "child process, LC_ALL=$locale" );
	}
}

done_testing();
