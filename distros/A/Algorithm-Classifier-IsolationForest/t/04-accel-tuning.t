#!perl
# 04-accel-tuning.t
#
# Verifies the C-build tuning environment variables (read once, at
# module load, in the block that compiles the Inline::C backend):
#
#   * IF_NO_C=1      -- skips building the C backend entirely
#   * IF_OPT=<level>  -- overrides the default -O3
#   * IF_ARCH=<value> -- adds -march=<value>
#   * IF_NATIVE=1     -- shorthand for IF_ARCH=native, superseded by IF_ARCH
#
# Since these are read once at load time, each combination needs its own
# fresh perl process -- this spawns one per case and inspects
# $Algorithm::Classifier::IsolationForest::{HAS_C,OPT_LEVEL} from its
# output, the same technique t/03-fit-determinism.t uses for
# OMP_NUM_THREADS.  Also checks that IF_OPT/IF_ARCH validate their input
# rather than passing it through to a compiler command line unchecked.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Algorithm::Classifier::IsolationForest;

my $HAS_C = $Algorithm::Classifier::IsolationForest::HAS_C ? 1 : 0;

plan skip_all => 'no Inline::C backend compiled in on this machine'
	unless $HAS_C;

my ( $fh, $path ) = tempfile( SUFFIX => '.pl', UNLINK => 1 );
print $fh <<'END_CHILD';
use Algorithm::Classifier::IsolationForest;
print "HAS_C=$Algorithm::Classifier::IsolationForest::HAS_C\n";
print "OPT_LEVEL=$Algorithm::Classifier::IsolationForest::OPT_LEVEL\n";
END_CHILD
close $fh;

# Runs the child with the given %ENV additions layered over a clean
# copy of the current environment (so leftover IF_* vars from one
# subtest can't bleed into the next), returns (out, exit_status).
sub run_child {
	my (%env) = @_;
	local %ENV = %ENV;
	delete @ENV{
		qw(IF_NO_C IF_OPT IF_ARCH IF_NATIVE
			IF_NO_OPENMP IF_RUNTIME_BUILD IF_INSTALL_BUILD)
	};
	@ENV{ keys %env } = values %env;
	my $out = `$^X -Ilib "$path" 2>&1`;
	return ( $out, $? );
} ## end sub run_child

# Expected flag composition mirrors the module's: the *defaults* come
# from the generated BuildFlags module when present (a tree configured
# with `IF_ARCH=... perl Makefile.PL` has that arch baked in as the
# default, and invalid runtime values must fall back to it, not to a
# hard-coded -O3), and any -march is always accompanied by
# -ffp-contract=off so FMA contraction can't break the C-vs-Perl
# bit-parity guarantees.
my ( $DEF_OPT, $DEF_ARCH ) = ( '-O3', '' );
{
	local $@;
	my $rec = eval {
		require Algorithm::Classifier::IsolationForest::BuildFlags;
		Algorithm::Classifier::IsolationForest::BuildFlags::flags();
	};
	if ( ref $rec eq 'HASH' ) {
		$DEF_OPT  = $rec->{opt}  if defined $rec->{opt};
		$DEF_ARCH = $rec->{arch} if defined $rec->{arch};
	}
}

sub compose_flags {
	my ( $opt, $arch ) = @_;
	return $opt . ( length $arch ? " -march=$arch -ffp-contract=off" : '' );
}

subtest 'IF_NO_C=1 skips the C backend entirely' => sub {
	my ( $out, $status ) = run_child( IF_NO_C => 1 );
	is( $status, 0, 'child exits cleanly' ) or diag($out);
	like( $out, qr/HAS_C=0/,         'HAS_C is 0' );
	like( $out, qr/OPT_LEVEL=\s*$/m, 'OPT_LEVEL is empty' );
};

subtest 'IF_OPT overrides the optimisation level' => sub {
	my ( $out, $status ) = run_child( IF_OPT => '-O2' );
	is( $status, 0, 'child exits cleanly' ) or diag($out);
	like( $out, qr/HAS_C=1/, 'HAS_C is 1' );
	my $want = compose_flags( '-O2', $DEF_ARCH );
	like( $out, qr/OPT_LEVEL=\Q$want\E\s*$/m, 'OPT_LEVEL reflects -O2' );
};

subtest 'IF_OPT rejects an invalid value instead of passing it through' => sub {
	my ( $out, $status ) = run_child( IF_OPT => '-O3; touch /tmp/pwned-opt' );
	is( $status, 0, 'child exits cleanly despite the bad value' )
		or diag($out);
	ok( !-e '/tmp/pwned-opt', 'no injected command executed' );
	like( $out, qr/ignoring invalid IF_OPT/, 'warns about the bad value' );
	my $want = compose_flags( $DEF_OPT, $DEF_ARCH );
	like( $out, qr/OPT_LEVEL=\Q$want\E\s*$/m, 'falls back to the configured default opt level' );
	unlink '/tmp/pwned-opt' if -e '/tmp/pwned-opt';
}; ## end 'IF_OPT rejects an invalid value instead of passing it through' => sub

subtest 'IF_ARCH adds -march=<value>' => sub {
	my ( $out, $status ) = run_child( IF_ARCH => 'x86-64-v2' );
	is( $status, 0, 'child exits cleanly' ) or diag($out);
	like( $out, qr/HAS_C=1/, 'HAS_C is 1' );
	my $want = compose_flags( $DEF_OPT, 'x86-64-v2' );
	like( $out, qr/OPT_LEVEL=\Q$want\E\s*$/m, 'OPT_LEVEL includes -march=x86-64-v2 (with -ffp-contract=off)' );
};

subtest 'IF_ARCH rejects an invalid value instead of passing it through' => sub {
	my ( $out, $status ) = run_child( IF_ARCH => 'native; touch /tmp/pwned-arch' );
	is( $status, 0, 'child exits cleanly despite the bad value' )
		or diag($out);
	ok( !-e '/tmp/pwned-arch', 'no injected command executed' );
	like( $out, qr/ignoring invalid IF_ARCH/, 'warns about the bad value' );
	my $want = compose_flags( $DEF_OPT, $DEF_ARCH );
	like( $out, qr/OPT_LEVEL=\Q$want\E\s*$/m, 'falls back to the configured default arch' );
	unlink '/tmp/pwned-arch' if -e '/tmp/pwned-arch';
}; ## end 'IF_ARCH rejects an invalid value instead of passing it through' => sub

subtest 'IF_ARCH=none opts out of any configured default arch' => sub {
	my ( $out, $status ) = run_child( IF_ARCH => 'none' );
	is( $status, 0, 'child exits cleanly' ) or diag($out);
	my $want = compose_flags( $DEF_OPT, '' );
	like( $out, qr/OPT_LEVEL=\Q$want\E\s*$/m, 'OPT_LEVEL has no -march at all' );
};

subtest 'IF_NATIVE is shorthand for -march=native' => sub {
	my ( $out, $status ) = run_child( IF_NATIVE => 1 );
	is( $status, 0, 'child exits cleanly' ) or diag($out);
	my $want = compose_flags( $DEF_OPT, 'native' );
	like( $out, qr/OPT_LEVEL=\Q$want\E\s*$/m, 'OPT_LEVEL includes -march=native' );
};

subtest 'IF_ARCH takes precedence over IF_NATIVE when both are set' => sub {
	my ( $out, $status ) = run_child( IF_NATIVE => 1, IF_ARCH => 'x86-64-v2' );
	is( $status, 0, 'child exits cleanly' ) or diag($out);
	my $want = compose_flags( $DEF_OPT, 'x86-64-v2' );
	like( $out, qr/OPT_LEVEL=\Q$want\E\s*$/m, 'OPT_LEVEL uses IF_ARCH, not native' );
};

done_testing;
