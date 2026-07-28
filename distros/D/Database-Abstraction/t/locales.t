#!perl -w

# Locale tests: verify that our own error messages (from croak/carp)
# are invariant strings and do not accidentally embed OS-derived strings
# that would differ by $ENV{LC_ALL}.
#
# POSIX locale test methodology (per critique requirements):
#   - Do NOT use POSIX::strerror.
#   - Use  local $! = ENOENT; my $msg = "$!"  to capture the OS string
#     directly from Perl's locale layer.
#   - Verify that our croak messages are NOT the same as $! strings
#     (they must be constant, not OS-derived).

use strict;
use warnings;

use POSIX qw(ENOENT);
use File::Spec;
use FindBin qw($Bin);
use Test::Most tests => 10;
use Test::NoWarnings;

use lib 't/lib';
use Database::test1;

pass('Database::test1 loaded');
my $data_dir = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

# Strip the Carp-appended "at FILE line N.\n" so messages compare cleanly
sub trim_loc { my $m = shift // ''; $m =~ s/ at \S+ line \d+\.?.*$//s; $m }

my @locales = ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8');

for my $locale (@locales) {
	local $ENV{LC_ALL} = $locale;
	local $ENV{LANG}   = $locale;

	# Capture the OS "no such file" string in this locale via Perl's layer
	my $os_enoent;
	do { local $! = ENOENT; $os_enoent = "$!" };

	# Our croak message for a missing table must be a constant string
	my $t   = Database::test1->new($data_dir);
	my $our_msg = eval { $t->count('_unsafe; DROP TABLE--' => 'x'); '' } // $@;

	# The error must fire (unsafe column name)
	ok(length($our_msg) > 0, "locale $locale: error thrown for unsafe column");

	# Our message must not be the raw OS ENOENT string
	unlike($our_msg, qr/\Q$os_enoent\E/i, "locale $locale: croak message is not OS-locale-dependent");
}

# Sanity: confirm our constant error strings are stable across locales.
# Strip "at FILE line N" from both sides before comparing.

# Abstract class protection is a constant English string
{
	my $msg1 = trim_loc(eval { Database::Abstraction->new(directory => $data_dir); '' } // $@);
	my $msg2;
	do {
		local $ENV{LC_ALL} = 'de_DE.UTF-8';
		$msg2 = trim_loc(eval { Database::Abstraction->new(directory => $data_dir); '' } // $@);
	};
	is($msg1, $msg2, 'Abstract class error message is locale-invariant');
}

# Column validation croak is a constant English string
{
	my $t    = Database::test1->new($data_dir);
	my $msg1 = trim_loc(eval { $t->fetchrow_hashref('_unsafe; DROP TABLE--' => 'x') } // $@);
	my $msg2;
	do {
		local $ENV{LC_ALL} = 'de_DE.UTF-8';
		$msg2 = trim_loc(eval { $t->fetchrow_hashref('_unsafe; DROP TABLE--' => 'x') } // $@);
	};
	is($msg1, $msg2, 'Column-safety error message is locale-invariant');
}
