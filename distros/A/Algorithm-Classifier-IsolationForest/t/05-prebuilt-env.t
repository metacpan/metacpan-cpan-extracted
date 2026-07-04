#!perl
# 05-prebuilt-env.t
#
# Exercises the load-time environment knobs that arrived with install-time
# prebuilt object support:
#
#   * IF_NO_C=1          -- no C backend at all
#   * IF_NO_OPENMP=1     -- backend (C or not) must report no OpenMP
#   * IF_RUNTIME_BUILD=1 -- any C backend in use must be a runtime build,
#                           never the prebuilt object
#   * scoring parity     -- every variant scores the same data identically
#
# The IF_* environment is read once at first module load, so each scenario
# needs a fresh perl; we probe via subprocesses.  Nothing here asserts that
# a C backend is *available*: on a pure-Perl host every probe degrades to
# HAS_C=0 and the parity checks still apply.

use strict;
use warnings;
use Test::More;

# Under the harness blib/ exists and carries any prebuilt object; from a
# bare checkout fall back to lib/.
my @inc = -d 'blib/lib' ? ('-Mblib') : ('-Ilib');

my $probe_code = <<'CODE';
require Algorithm::Classifier::IsolationForest;
my @out = (
    $Algorithm::Classifier::IsolationForest::HAS_C,
    $Algorithm::Classifier::IsolationForest::HAS_OPENMP,
    $Algorithm::Classifier::IsolationForest::C_SOURCE,
);
srand(7);
my @data = map { [ rand(), rand() ] } 1 .. 40;
push @data, [ 8, 8 ];
my $f = Algorithm::Classifier::IsolationForest->new(
    n_trees     => 20,
    sample_size => 32,
    seed        => 5,
);
$f->fit( \@data );
my $scores = $f->score_samples( [ [ 0.5, 0.5 ], [ 8, 8 ] ] );
push @out, map { sprintf '%.12g', $_ } @$scores;
print join( '|', @out ), "\n";
CODE

# Runs a fresh perl with a scrubbed IF_* environment plus the requested
# overrides; returns (has_c, has_openmp, c_source, score1, score2).
sub load_probe {
	my (%env) = @_;
	local %ENV = %ENV;
	delete $ENV{$_} for grep { /^IF_/ } keys %ENV;
	$ENV{$_} = $env{$_} for keys %env;
	open my $fh, '-|', $^X, @inc, '-e', $probe_code
		or die "can't spawn $^X: $!";
	my $line = <$fh>;
	close $fh;
	chomp( $line //= '' );
	return split /\|/, $line, -1;
} ## end sub load_probe

my @baseline = load_probe();
is( scalar @baseline, 5, 'baseline probe produced all fields' )
	or BAIL_OUT("subprocess probe failed; output: @baseline");
my ( $has_c, $has_openmp, $c_source ) = @baseline;
ok( $has_c == 0 || $has_c == 1, "baseline HAS_C is 0/1 (got '$has_c')" );
if ($has_c) {
	ok( $c_source eq 'prebuilt' || $c_source eq 'runtime',
		"C_SOURCE is prebuilt/runtime when HAS_C (got '$c_source')" );
} else {
	is( $c_source, '', 'C_SOURCE empty without C backend' );
}
diag("baseline: HAS_C=$has_c HAS_OPENMP=$has_openmp C_SOURCE=$c_source");

my @no_c = load_probe( IF_NO_C => 1 );
is( $no_c[0], '0', 'IF_NO_C=1 disables the C backend' );
is( $no_c[2], '',  'IF_NO_C=1 leaves C_SOURCE empty' );

my @no_omp = load_probe( IF_NO_OPENMP => 1 );
is( $no_omp[1], '0', 'IF_NO_OPENMP=1 yields a backend without OpenMP' );

# A runtime C build demonstrably works here iff the baseline came from one,
# so only then may we insist the serial build also compiles.  (A prebuilt-
# only host without a compiler legitimately drops to pure Perl instead.)
if ( $has_c && $c_source eq 'runtime' ) {
	is( $no_omp[0], '1', 'IF_NO_OPENMP=1 still gets the serial C backend where runtime builds work' );
}

my @runtime = load_probe( IF_RUNTIME_BUILD => 1 );
if ( $runtime[0] ) {
	is( $runtime[2], 'runtime', 'IF_RUNTIME_BUILD=1 never reports the prebuilt object' );
} else {
	pass('IF_RUNTIME_BUILD=1 fell back to pure Perl (no runtime toolchain)');
}

# Scoring parity: same seed, same data => same model, and all backends and
# knob combinations must score it identically (within float noise).
my @variants = ( [ 'IF_NO_C', @no_c ], [ 'IF_NO_OPENMP', @no_omp ], [ 'IF_RUNTIME_BUILD', @runtime ], );
for my $v (@variants) {
	my ( $name, @fields ) = @$v;
	is( scalar @fields, 5, "$name probe produced all fields" ) or next;
	for my $i ( 0, 1 ) {
		my ( $got, $want ) = ( $fields[ 3 + $i ], $baseline[ 3 + $i ] );
		ok( abs( $got - $want ) < 1e-9, "$name score $i matches baseline ($got vs $want)" );
	}
}

done_testing;
