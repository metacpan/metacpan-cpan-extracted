package Algorithm::Classifier::IsolationForest::App::Command::accel;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;

sub opt_spec { () }

sub abstract { 'Report which (if any) native acceleration backend is active' }

sub description {
	'Initialises Algorithm::Classifier::IsolationForest, fits
a tiny synthetic dataset to exercise the optional native code path, then
reports which acceleration (if any) is wired up:

  * Inline::C  -- C scoring backend compiled at module load
  * OpenMP     -- parallel tree-walk across CPU cores (requires libgomp)
  * SIMD       -- vectorised oblique dot product in extended mode
                  (gated on OpenMP 4.0+; relies on `#pragma omp simd`)

The detection happens automatically the first time the module is loaded.
When the distribution was installed with Inline::C available, a prebuilt
object compiled at `make` time is loaded directly; otherwise the backend
is compiled on first load and cached under _Inline/.  If no backend is
active the module falls back to a pure-Perl implementation.

Build flags are tunable via environment variables set before first load
(and, to pick what gets baked into the prebuilt object, before
`perl Makefile.PL`):

  * IF_ARCH=<value>     -- -march=<value> (e.g. x86-64-v3, skylake, znver3)
  * IF_NATIVE=1         -- shorthand for IF_ARCH=native; ignored if IF_ARCH is set
  * IF_OPT=<-Olevel>    -- override the default -O3
  * IF_NO_OPENMP=1      -- serial C backend: no libgomp linkage at all
  * IF_RUNTIME_BUILD=1  -- ignore the prebuilt object, compile at first load
  * IF_NO_C=1           -- skip the C backend entirely

See "NATIVE ACCELERATION" in perldoc Algorithm::Classifier::IsolationForest
for details and tradeoffs (in particular, why IF_NATIVE is not always a
safe default choice).
';
} ## end sub description

sub validate { 1 }

sub execute {
	my ( $self, $opt, $args ) = @_;

	# Tiny deterministic dataset.  Fitting + scoring confirms the chosen
	# backend is callable end-to-end, not merely that it compiled.  We
	# exercise both axis mode (covers score_all_xs's axis branch) and
	# extended mode (covers the oblique branch -- where the
	# `#pragma omp simd` reduction lives, so this is the only path
	# SIMD actually matters for).
	srand(1);
	my @data = map { [ rand(), rand(), rand() ] } 1 .. 30;
	push @data, [ 10, 10, 10 ], [ -10, -10, -10 ];

	my $axis = Algorithm::Classifier::IsolationForest->new(
		n_trees     => 10,
		sample_size => 32,
		seed        => 1,
	);
	$axis->fit( \@data );
	$axis->score_samples( [ [ 0.5, 0.5, 0.5 ] ] );

	my $ext = Algorithm::Classifier::IsolationForest->new(
		n_trees     => 10,
		sample_size => 32,
		seed        => 1,
		mode        => 'extended',
	);
	$ext->fit( \@data );
	$ext->score_samples( [ [ 0.5, 0.5, 0.5 ] ] );

	my $has_c      = $Algorithm::Classifier::IsolationForest::HAS_C      ? 1 : 0;
	my $has_openmp = $Algorithm::Classifier::IsolationForest::HAS_OPENMP ? 1 : 0;
	my $has_simd   = $Algorithm::Classifier::IsolationForest::HAS_SIMD   ? 1 : 0;

	my $c_source = $Algorithm::Classifier::IsolationForest::C_SOURCE;

	# Whether a prebuilt object was installed with the dist at all --
	# independent of whether this process ended up using it.
	my $prebuilt_installed = 0;
	{
		local $@;
		my $bf = eval {
			require Algorithm::Classifier::IsolationForest::BuildFlags;
			Algorithm::Classifier::IsolationForest::BuildFlags::flags();
		};
		$prebuilt_installed = 1 if ref $bf eq 'HASH' && $bf->{prebuilt};
	}

	my $source_desc
		= $c_source eq 'prebuilt' ? 'prebuilt at install time'
		: $c_source eq 'runtime'  ? 'compiled at run time (cached under _Inline/)'
		:                           'none (pure-Perl fallback)';

	print "Algorithm::Classifier::IsolationForest acceleration status\n";
	print "  Inline::C : ", ( $has_c      ? "available\n" : "not available\n" );
	print "  OpenMP    : ", ( $has_openmp ? "available\n" : "not available\n" );
	print "  SIMD      : ", ( $has_simd   ? "available\n" : "not available\n" );
	print "  C object  : $source_desc\n";
	if ( $c_source ne 'prebuilt' && $prebuilt_installed ) {
		my @why;
		push @why, 'IF_RUNTIME_BUILD' if $ENV{IF_RUNTIME_BUILD};
		push @why, 'IF_NO_C'          if $ENV{IF_NO_C};
		push @why, grep { defined $ENV{$_} } qw(IF_OPT IF_ARCH IF_NATIVE IF_NO_OPENMP);
		print "              (a prebuilt object is installed but was not used",
			(
				@why
				? '; runtime overrides active: ' . join( ', ', @why )
				: '; it failed to load'
			),
			")\n";
	} ## end if ( $c_source ne 'prebuilt' && $prebuilt_installed)
	if ($has_c) {
		printf "  Build flags: %s\n", $Algorithm::Classifier::IsolationForest::OPT_LEVEL;
	}
	print "\n";

	# Build a one-line backend summary that lists every active feature
	# and where the C object came from.
	my @features;
	push @features, 'OpenMP' if $has_openmp;
	push @features, 'SIMD'   if $has_simd;

	my $suffix
		= $c_source eq 'prebuilt' ? ' -- prebuilt at install time'
		: $c_source eq 'runtime'  ? ' -- compiled at run time'
		:                           '';

	if ( $has_c && @features ) {
		printf "Active backend: Inline::C with %s%s\n", join( ' + ', @features ), $suffix;
	} elsif ($has_c) {
		print "Active backend: Inline::C (serial, scalar)$suffix\n";
	} else {
		print "Active backend: pure Perl (no native acceleration)\n";
	}

	return 1;
} ## end sub execute

return 1;
