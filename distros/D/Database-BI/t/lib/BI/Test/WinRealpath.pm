package BI::Test::WinRealpath;

use strict;
use warnings;

# ---------------------------------------------------------------------------
# Windows' symlink behaviour, on any platform that has symlinks.
#
# Cwd::realpath on Windows -- so Mojo::File's realpath -- leaves a symlink as
# it is, and the code that has to resolve one (canonical_spec, _canonical_path,
# _resolved_path) follows the links itself under $^O eq 'MSWin32'.  Loaded
# before a test, this module makes realpath behave that way and runs those
# subs down their Windows branch, so a test that takes its expected path from realpath through
# a link fails here as it does on Windows (t/path-spec.t did, on CPAN Testers
# with Strawberry Perl 5.42, while the code was right).
#
#   PERL5OPT='-Mlib=t/lib -MBI::Test::WinRealpath' prove -l t/path-spec.t
#
# Only $^O inside those subs is changed: setting it for the whole process
# would send every other platform check (paths, permissions, signals) the
# Windows way too, and the run would test nothing real.
# ---------------------------------------------------------------------------

use Cwd ();
use File::Basename ();
use File::Spec ();

# This checkout's lib/, found from this file (t/lib/BI/Test/WinRealpath.pm).
# PERL5OPT loads this module into every perl, prove's own among them, before
# prove -l has put lib/ on @INC, so the INIT below would otherwise find no
# Dashboard.pm (a fresh CI runner) or an older installed one (a machine with
# Database::BI installed, where it looked as if it worked).
BEGIN {
	my $here = File::Spec->rel2abs(File::Basename::dirname(__FILE__));
	my $lib  = File::Spec->catdir($here, (File::Spec->updir) x 4, 'lib');
	# Resolved, so the app's home (found from where its modules were loaded)
	# has no ../ in it.  Cwd's, not Mojo::File's realpath, replaced below.
	$lib = Cwd::abs_path($lib) if -d $lib;
	unshift @INC, $lib if defined $lib && -d $lib && !grep { !ref && $_ eq $lib } @INC;
}

use Mojo::File ();

our $VERSION = '0.021.0';

{
	no warnings 'redefine';
	# Absolute, with . and .. taken out as Windows' realpath does; only the
	# links are left as they are.
	my $real = \&Mojo::File::realpath;
	*Mojo::File::realpath = sub {
		my ($self) = @_;
		# A name the real one refuses, or cuts short at a NUL as the C library
		# does, is left to it.
		my $check = $real->($self);
		return $check unless defined $$check && length $$check && "$self" !~ /\0/;
		my ($vol, $dirs, $file) = File::Spec->splitpath(File::Spec->rel2abs("$self"));
		my @parts;
		for my $part (File::Spec->splitdir($dirs), $file) {
			next if !length $part || $part eq '.';
			if ($part eq '..') { pop @parts; next }
			push @parts, $part;
		}
		return Mojo::File->new(File::Spec->catpath($vol, File::Spec->catdir(File::Spec->rootdir, @parts), ''));
	};
}

# Loaded in INIT, after the compile phase, as the application is in a test
# or a server.  Loaded during it (straight from -M), Sub::Protected's CHECK
# block runs too, and that alone changes what some routes return (the SQL
# path's sums came back as strings, failing t/time-bucket.t), which is not
# what this module is here to show.
INIT {
	require Database::BI::Controller::Dashboard;
	for my $name (qw(canonical_spec _canonical_path _resolved_path)) {
		my $glob = "Database::BI::Controller::Dashboard::$name";
		no strict 'refs';
		my $orig = \&{$glob} or next;
		no warnings 'redefine';
		*{$glob} = sub {
			local $^O = 'MSWin32';
			return $orig->(@_);
		};
	}
}

1;
