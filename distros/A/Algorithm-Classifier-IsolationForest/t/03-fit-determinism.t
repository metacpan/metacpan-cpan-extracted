#!perl
# 03-fit-determinism.t
#
# Verifies that fit() with a given `seed` produces reproducible trees,
# across every tree-building backend the module can select:
#
#   * pure Perl            (use_c => 0)
#   * serial C             (use_c => 1)
#   * OpenMP-parallel C    (use_c => 1, use_openmp_fit => 1)
#
# Covers:
#   1. Each backend, run twice with the same seed, builds bit-identical
#      trees (not just bit-identical scores -- the actual tree structure).
#   2. Pure-Perl and serial-C build BIT-IDENTICAL trees for the same seed,
#      in both axis and extended mode, and across every `missing`
#      strategy -- because the serial C builder draws randomness through
#      Drand01(), the same generator Perl's own rand()/srand() use.
#   3. use_openmp_fit is reproducible for a fixed seed + n_trees
#      regardless of OMP_NUM_THREADS (checked across separate
#      subprocesses, since that's the only way to force a different
#      thread count) -- it deliberately does NOT match the Drand01-based
#      backends (documented behaviour: it uses its own thread-safe PRNG),
#      so that's checked as a "differs, but each is internally consistent"
#      property rather than cross-backend equality.
#   4. use_openmp_fit + parallel_fit together is still safe and
#      reproducible -- but does NOT actually run forked workers in
#      OpenMP.  A forked child starting its own OpenMP region after
#      the parent process has used OpenMP for anything (including
#      plain score_samples()) can hang -- a general fork()+libgomp
#      limitation -- so parallel_fit's workers always use the
#      single-threaded C builder regardless of use_openmp_fit.  This
#      was caught by an earlier version of this test hanging.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Config;
use JSON::PP ();

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

my $HAS_C      = $Algorithm::Classifier::IsolationForest::HAS_C      ? 1 : 0;
my $HAS_OPENMP = $Algorithm::Classifier::IsolationForest::HAS_OPENMP ? 1 : 0;
my $can_fork   = ( $Config{d_fork} || '' ) eq 'define';

# ------------------------------------------------------------------------
# Shared deterministic dataset.  A few obvious outliers keep both axis
# and extended splits from degenerating on featureless data.
# ------------------------------------------------------------------------
srand(20260701);
my @data;
push @data, [ rand(), rand(), rand() ] for 1 .. 150;
push @data, [ 9, 9, 9 ], [ -9, -9, -9 ], [ 8, -9, 8 ];

# A copy with a few undef cells, for the missing-strategy comparisons.
my @data_nan = map { [@$_] } @data;
$data_nan[3][1]  = undef;
$data_nan[40][0] = undef;

sub trees_json {
	my ($f) = @_;
	return JSON::PP->new->canonical(1)->encode( $f->{trees} );
}

sub fit_trees {
	my (%opts) = @_;
	my $data = delete $opts{data} // \@data;
	return trees_json( $CLASS->new(%opts)->fit($data) );
}

# Bounds a block with alarm() so a regression of the fork()+libgomp
# hazard documented below fails this one assertion instead of hanging
# the whole test run (and anything waiting on it, e.g. CI) forever.
sub with_timeout {
	my ( $secs, $code ) = @_;
	my $result;
	eval {
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm($secs);
		$result = $code->();
		alarm(0);
	};
	alarm(0);
	return ( $result, $@ );
} ## end sub with_timeout

# ------------------------------------------------------------------------
# 1. Same seed, same backend, twice => identical trees.
# ------------------------------------------------------------------------
subtest 'pure-Perl backend is reproducible for a fixed seed' => sub {
	for my $mode (qw(axis extended)) {
		my %opts = (
			n_trees     => 25,
			sample_size => 40,
			seed        => 31,
			mode        => $mode,
			use_c       => 0,
		);
		is( fit_trees(%opts), fit_trees(%opts), "[$mode] two pure-Perl fits with the same seed match" );
	} ## end for my $mode (qw(axis extended))
}; ## end 'pure-Perl backend is reproducible for a fixed seed' => sub

subtest 'serial-C backend is reproducible for a fixed seed' => sub {
	plan skip_all => 'no Inline::C backend compiled in' unless $HAS_C;

	for my $mode (qw(axis extended)) {
		my %opts = (
			n_trees     => 25,
			sample_size => 40,
			seed        => 32,
			mode        => $mode,
			use_c       => 1,
		);
		is( fit_trees(%opts), fit_trees(%opts), "[$mode] two serial-C fits with the same seed match" );
	} ## end for my $mode (qw(axis extended))
}; ## end 'serial-C backend is reproducible for a fixed seed' => sub

# ------------------------------------------------------------------------
# 2. Pure-Perl and serial-C agree bit-for-bit, same seed, same trees.
# ------------------------------------------------------------------------
subtest 'pure-Perl and serial-C build identical trees for the same seed' => sub {
	plan skip_all => 'no Inline::C backend compiled in' unless $HAS_C;

	for my $mode (qw(axis extended)) {
		my %opts = ( n_trees => 30, sample_size => 48, seed => 33, mode => $mode );
		is(
			fit_trees( %opts, use_c => 1 ),
			fit_trees( %opts, use_c => 0 ),
			"[$mode] use_c => 1 and use_c => 0 build the same trees"
		);
	}

	for my $missing (qw(zero impute nan)) {
		my %opts = (
			n_trees     => 20,
			sample_size => 40,
			seed        => 34,
			missing     => $missing,
			data        => \@data_nan,
		);
		is(
			fit_trees( %opts, use_c => 1 ),
			fit_trees( %opts, use_c => 0 ),
			"[missing=$missing] use_c => 1 and use_c => 0 build the same trees"
		);
	} ## end for my $missing (qw(zero impute nan))
}; ## end 'pure-Perl and serial-C build identical trees for the same seed' => sub

# ------------------------------------------------------------------------
# 3. use_openmp_fit: reproducible in-process for a fixed seed.
# ------------------------------------------------------------------------
subtest 'use_openmp_fit is reproducible in-process for a fixed seed' => sub {
	plan skip_all => 'OpenMP not linked in' unless $HAS_C && $HAS_OPENMP;

	for my $mode (qw(axis extended)) {
		my %opts = (
			n_trees        => 40,
			sample_size    => 48,
			seed           => 41,
			mode           => $mode,
			use_c          => 1,
			use_openmp_fit => 1,
		);
		is( fit_trees(%opts), fit_trees(%opts), "[$mode] two use_openmp_fit fits with the same seed match" );
	} ## end for my $mode (qw(axis extended))
}; ## end 'use_openmp_fit is reproducible in-process for a fixed seed' => sub

subtest 'use_openmp_fit trees are valid, but not required to match Drand01 backends' => sub {
	plan skip_all => 'OpenMP not linked in' unless $HAS_C && $HAS_OPENMP;

	# use_openmp_fit uses its own thread-safe PRNG (documented: Perl's
	# RNG state can't be shared across OpenMP threads), so it is NOT
	# expected to match the serial-C/pure-Perl trees for the same seed.
	# What matters is that it still produces a valid, usable model.
	my $f = $CLASS->new(
		n_trees        => 40,
		sample_size    => 48,
		seed           => 42,
		mode           => 'extended',
		use_c          => 1,
		use_openmp_fit => 1,
	)->fit( \@data );

	is( scalar @{ $f->{trees} }, 40, 'builds exactly n_trees trees' );
	my $s   = $f->score_samples( \@data );
	my $bad = grep { !defined $_ || $_ <= 0 || $_ > 1 } @$s;
	is( $bad, 0, 'every score is in (0, 1]' );
}; ## end 'use_openmp_fit trees are valid, but not required to match Drand01 backends' => sub

# ------------------------------------------------------------------------
# 4. use_openmp_fit: reproducible regardless of OMP_NUM_THREADS.
#
# Thread count can't be changed mid-process reliably (OpenMP's runtime
# is normally set up once), so this spawns two subprocesses that build
# an identical dataset and fit with an identical seed, differing only in
# OMP_NUM_THREADS, and compares their tree JSON byte-for-byte.
# ------------------------------------------------------------------------
subtest 'use_openmp_fit reproducibility does not depend on OMP_NUM_THREADS' => sub {
	plan skip_all => 'OpenMP not linked in' unless $HAS_C && $HAS_OPENMP;

	my ( $fh, $path ) = tempfile( SUFFIX => '.pl', UNLINK => 1 );
	print $fh <<'END_CHILD';
use strict;
use warnings;
use Algorithm::Classifier::IsolationForest;
use JSON::PP ();

srand(20260701171717);
my @data;
push @data, [ rand(), rand(), rand() ] for 1 .. 150;
push @data, [ 9, 9, 9 ], [ -9, -9, -9 ], [ 8, -9, 8 ];

my $f = Algorithm::Classifier::IsolationForest->new(
    n_trees        => 60,
    sample_size    => 48,
    seed           => 99,
    mode           => 'extended',
    use_c          => 1,
    use_openmp_fit => 1,
);
$f->fit( \@data );
print JSON::PP->new->canonical(1)->encode( $f->{trees} );
END_CHILD
	close $fh;

	my $out1 = do {
		local $ENV{OMP_NUM_THREADS} = 1;
		`$^X -Ilib "$path" 2>&1`;
	};
	my $exit1 = $?;
	my $out4  = do {
		local $ENV{OMP_NUM_THREADS} = 4;
		`$^X -Ilib "$path" 2>&1`;
	};
	my $exit4 = $?;

	is( $exit1, 0, 'OMP_NUM_THREADS=1 child exits cleanly' )
		or diag("child output:\n$out1");
	is( $exit4, 0, 'OMP_NUM_THREADS=4 child exits cleanly' )
		or diag("child output:\n$out4");

	is( $out1, $out4, 'same seed + n_trees builds identical trees under OMP_NUM_THREADS=1 vs 4' );
}; ## end 'use_openmp_fit reproducibility does not depend on OMP_NUM_THREADS' => sub

# ------------------------------------------------------------------------
# 5. use_openmp_fit + parallel_fit together: must not hang, and must
# still be reproducible -- but see the file-top comment: parallel_fit's
# forked workers ignore use_openmp_fit and always use the
# single-threaded C builder, specifically BECAUSE a forked child
# starting its own OpenMP region after this same process has already
# run OpenMP (subtests 3/4 above did, via use_openmp_fit) can hang.
# This subtest runs deliberately late in the file, after use_openmp_fit
# has already executed in-process above, to exercise exactly that
# ordering.
# ------------------------------------------------------------------------
subtest 'use_openmp_fit + parallel_fit does not hang and is reproducible' => sub {
	plan skip_all => 'no fork() on this platform'
		unless $can_fork && $HAS_C && $HAS_OPENMP;

	my %opts = (
		n_trees        => 60,
		sample_size    => 48,
		seed           => 51,
		use_c          => 1,
		use_openmp_fit => 1,
		parallel_fit   => 3,
	);

	# A regression of the fork()+libgomp hazard would hang fit() itself,
	# not just fail an assertion -- with_timeout() bounds that so it
	# fails this test instead of stalling the whole run.
	my ( $r1, $err1 ) = with_timeout( 20, sub { fit_trees(%opts) } );
	my ( $r2, $err2 ) = with_timeout( 20, sub { fit_trees(%opts) } );
	is( $err1, '', 'first parallel_fit + use_openmp_fit run does not hang' )
		or diag("error: $err1");
	is( $err2, '', 'second parallel_fit + use_openmp_fit run does not hang' )
		or diag("error: $err2");
	is( $r1, $r2, 'two parallel_fit + use_openmp_fit runs with the same seed and ' . 'worker count match' );
}; ## end 'use_openmp_fit + parallel_fit does not hang and is reproducible' => sub

done_testing;
