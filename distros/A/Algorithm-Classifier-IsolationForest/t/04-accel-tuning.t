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
    delete @ENV{qw(IF_NO_C IF_OPT IF_ARCH IF_NATIVE)};
    @ENV{ keys %env } = values %env;
    my $out = `$^X -Ilib "$path" 2>&1`;
    return ( $out, $? );
}

subtest 'IF_NO_C=1 skips the C backend entirely' => sub {
    my ( $out, $status ) = run_child( IF_NO_C => 1 );
    is( $status, 0, 'child exits cleanly' ) or diag($out);
    like( $out, qr/HAS_C=0/,      'HAS_C is 0' );
    like( $out, qr/OPT_LEVEL=\s*$/m, 'OPT_LEVEL is empty' );
};

subtest 'IF_OPT overrides the optimisation level' => sub {
    my ( $out, $status ) = run_child( IF_OPT => '-O2' );
    is( $status, 0, 'child exits cleanly' ) or diag($out);
    like( $out, qr/HAS_C=1/,          'HAS_C is 1' );
    like( $out, qr/OPT_LEVEL=-O2\s*$/m, 'OPT_LEVEL reflects -O2' );
};

subtest 'IF_OPT rejects an invalid value instead of passing it through' =>
    sub {
    my ( $out, $status ) = run_child( IF_OPT => '-O3; touch /tmp/pwned-opt' );
    is( $status, 0, 'child exits cleanly despite the bad value' )
        or diag($out);
    ok( !-e '/tmp/pwned-opt', 'no injected command executed' );
    like( $out, qr/ignoring invalid IF_OPT/, 'warns about the bad value' );
    like( $out, qr/OPT_LEVEL=-O3\s*$/m,
        'falls back to the default -O3' );
    unlink '/tmp/pwned-opt' if -e '/tmp/pwned-opt';
    };

subtest 'IF_ARCH adds -march=<value>' => sub {
    my ( $out, $status ) = run_child( IF_ARCH => 'x86-64-v2' );
    is( $status, 0, 'child exits cleanly' ) or diag($out);
    like( $out, qr/HAS_C=1/, 'HAS_C is 1' );
    like( $out, qr/OPT_LEVEL=-O3 -march=x86-64-v2\s*$/m,
        'OPT_LEVEL includes -march=x86-64-v2' );
};

subtest 'IF_ARCH rejects an invalid value instead of passing it through' =>
    sub {
    my ( $out, $status )
        = run_child( IF_ARCH => 'native; touch /tmp/pwned-arch' );
    is( $status, 0, 'child exits cleanly despite the bad value' )
        or diag($out);
    ok( !-e '/tmp/pwned-arch', 'no injected command executed' );
    like( $out, qr/ignoring invalid IF_ARCH/, 'warns about the bad value' );
    like( $out, qr/OPT_LEVEL=-O3\s*$/m,
        'falls back to plain -O3 (no -march)' );
    unlink '/tmp/pwned-arch' if -e '/tmp/pwned-arch';
    };

subtest 'IF_NATIVE is shorthand for -march=native' => sub {
    my ( $out, $status ) = run_child( IF_NATIVE => 1 );
    is( $status, 0, 'child exits cleanly' ) or diag($out);
    like( $out, qr/OPT_LEVEL=-O3 -march=native\s*$/m,
        'OPT_LEVEL includes -march=native' );
};

subtest 'IF_ARCH takes precedence over IF_NATIVE when both are set' => sub {
    my ( $out, $status )
        = run_child( IF_NATIVE => 1, IF_ARCH => 'x86-64-v3' );
    is( $status, 0, 'child exits cleanly' ) or diag($out);
    like( $out, qr/OPT_LEVEL=-O3 -march=x86-64-v3\s*$/m,
        'OPT_LEVEL uses IF_ARCH, not native' );
};

done_testing;
