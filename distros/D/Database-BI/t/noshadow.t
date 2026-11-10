#!perl -w
#
# t/noshadow.t - check that this distribution's modules, and the modules it
# loads, are the copies you think they are.
#
# Written to be copied or symlinked into any distribution:
#
#     cp ../CGI-Info/t/noshadow.t t/
#     ln -s ../CGI-Info/t/noshadow.t t/noshadow.t
#
# Nothing here names a module, a distribution or a directory. The modules come
# from lib/, and the workspace scan only runs when you point it at a workspace:
#
#     NOSHADOW_WORKSPACE=/home/njh/src/njh prove -l t/noshadow.t
#
# Use $Bin and not $RealBin throughout: for a symlinked .t, $Bin is the
# directory the link lives in - the distribution under test - while $RealBin is
# the one it points into, which is the wrong distribution entirely.
#
# If you keep this file, add Test::NoShadow to TEST_REQUIRES; without it the
# whole file is skipped rather than failed.
#
# Test::NoShadow's two functions emit their own TAP through Test::Builder and
# return a boolean, so call them directly. Wrapping them in ok() double-counts
# the test and throws away the diagnostics they attach to the failure.

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::NoShadow';	# skip cleanly where it isn't installed
use Test::NoShadow qw(lib_ok find_shadows);

use Cwd qw(abs_path);
use File::Find ();
use File::Spec;
use FindBin;

my $root = abs_path(File::Spec->catdir($FindBin::Bin, File::Spec->updir));
my $lib = File::Spec->catdir($root, 'lib');

my @modules = _modules_in($lib);

# The shallowest module in lib/ is the one the distribution is named after.
my ($main) = sort {
	($a =~ tr/://) <=> ($b =~ tr/://) or $a cmp $b
} @modules;

subtest 'every module in this distribution was loaded from lib/' => sub {
	plan skip_all => "no .pm files found under $lib" unless @modules;

	# %INC is keyed by 'Foo/Bar.pm', so the modules have to be loaded by name;
	# require() on a file path would be recorded under the path instead and
	# lib_ok() would not find it.
	my @loaded;
	foreach my $module (@modules) {
		if(eval "require $module; 1") {
			push @loaded, $module;
		}
		else {
			# Not fatal: a module that cannot load standalone is a job for
			# Test::Compile, not for this test.
			(my $error = $@) =~ s/\s+\z//;
			diag("  $module did not load standalone, not checked: $error");
		}
	}

	plan skip_all => 'none of the modules under lib/ loaded' unless @loaded;

	# Fails if any of them came from site_perl or a sibling checkout instead of
	# this distribution's lib/ or blib/lib. Passes under prove -l and under
	# make test, which uses blib/lib.
	lib_ok(@loaded);
};

subtest 'the main module was loaded exactly once' => sub {
	plan skip_all => 'no modules found under lib/' unless defined($main);

	(my $rel = $main) =~ s/::/\//g;
	my @copies = grep { defined($_) && m{(?:\A|/)\Q$rel\E\.pm\z} } values %INC;

	is(scalar(@copies), 1, "exactly one $rel.pm is loaded");
	diag('  loaded from: ' . join(', ', @copies)) if @copies;
};

subtest 'nothing was loaded out of t/' => sub {
	# The other half of lib_ok()'s question: a copy vendored into t/ (or into
	# t/lib/, which many distributions put on @INC) must not win.
	my $tdir = File::Spec->catdir($root, 't');

	my @leaks = grep { _under($_, $tdir) } grep { defined } map { abs_path($_) || $_ } values %INC;

	is_deeply(\@leaks, [], 'no module was loaded out of t/')
		or diag(join("\n", map { "  $_" } @leaks));
};

SKIP: {
	my $workspace = _workspace();
	skip 'set NOSHADOW_WORKSPACE=<dir of checkouts> to scan a workspace', 1
		unless defined($workspace);

	subtest 'the workspace supplies no duplicate packages' => sub {
		# Any module this run pulled from inside the workspace but from
		# outside this distribution came from a sibling checkout: a stray -I
		# or a polluted PERL5LIB substituting a copy that is being edited for
		# the released version the tests are meant to exercise.
		my @leaks = grep {
			_under($_, $workspace) && !_under($_, $root)
		} grep { defined } map { abs_path($_) || $_ } values %INC;

		is_deeply(\@leaks, [], 'no module in this run came from a sibling checkout')
			or diag(join("\n", map { "  $_" } @leaks));

		# Backups and scratch copies of a repository are expected to provide
		# the same packages as the checkout they came from, so they are worth
		# filtering out. Providers are named by the first directory beneath the
		# scanned root; NOSHADOW_IGNORE is a colon-separated list of those
		# names, for example:
		#
		#     NOSHADOW_IGNORE=ged2ste-http-vwf:OHTTP_VWF:Nvwf
		my @ignore = map { qr{\A\Q$_\E/} }
			grep { length } split /:/, ($ENV{'NOSHADOW_IGNORE'} // '');

		my $all = find_shadows($workspace);
		my $real = find_shadows($workspace, { ignore => \@ignore });
		my ($before, $after) = (scalar(keys %$all), scalar(keys %$real));

		cmp_ok($after, '<=', $before, 'ignoring a provider cannot invent a shadow')
			or diag('NOSHADOW_IGNORE matched nothing - are those directories at the top level?');

		diag(sprintf '%d shadowed package(s) under %s, %d once %d provider(s) are ignored',
			$before, $workspace, $after, scalar(@ignore));

		# What is left is the interesting part: packages genuinely supplied by
		# two live checkouts.
		diag("still shadowed: $_") foreach (sort keys %$real);
	};
}

done_testing();

# Every module name under $lib, derived from the file layout.
sub _modules_in {
	my ($dir) = @_;

	return () unless -d $dir;

	my @modules;
	File::Find::find({
		no_chdir => 1,
		wanted => sub {
			return unless /\.pm\z/;
			my $rel = File::Spec->abs2rel($File::Find::name, $dir);
			$rel =~ s/\.pm\z//;
			$rel =~ s{[/\\]}{::}g;
			push @modules, $rel;
		},
	}, $dir);

	return sort @modules;
}

# The workspace to scan, or undef. NOSHADOW_WORKSPACE=1 means "the directory
# two levels up from this test", which is right for a checkout one level deep
# in a workspace of checkouts.
sub _workspace {
	my $dir = $ENV{'NOSHADOW_WORKSPACE'};

	return unless defined($dir);
	$dir = File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir) if $dir eq '1';

	$dir = abs_path($dir) || $dir;
	unless(-d $dir) {
		diag("NOSHADOW_WORKSPACE=$dir is not a directory, skipping the workspace scan");
		return;
	}

	return $dir;
}

# Is $path inside $dir? Both must be absolute.
sub _under {
	my ($path, $dir) = @_;

	return 0 unless defined($path) && defined($dir);

	my $rel = File::Spec->abs2rel($path, $dir);

	return 0 if $rel =~ /\A\.\.(?:[\/\\]|\z)/;

	return !File::Spec->file_name_is_absolute($rel);
}
