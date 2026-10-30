use v5.40;
use Test2::V1 -ipP;
use blib;
use File::Temp      ();
use Acme::Parataxis qw[:all];
#
sub run_child ($body) {
    my $log  = File::Temp->new( SUFFIX => '.log' );
    my $code = join "\n", 'use v5.40;', 'use blib;', 'use Acme::Parataxis qw[:all];', '$|++;', $body, '';
    my $status;
    {
        open my $saved_out, '>&', \*STDOUT or die "dup stdout: $!";
        open my $saved_err, '>&', \*STDERR or die "dup stderr: $!";
        open STDOUT,        '>',  "$log"   or die "open log: $!";
        open STDERR,        '>&', \*STDOUT or die "dup stderr: $!";
        $status = system $^X, '-Mblib', '-e', $code;
        open STDOUT, '>&', $saved_out or die "restore stdout: $!";
        open STDERR, '>&', $saved_err or die "restore stderr: $!";
    }
    open my $fh, '<', "$log" or die "read log: $!";
    my $out = do { local $/; <$fh> };
    return ( $out, $status );
}

# The shared assertion. Returns nothing; the three checks are the contract.
sub check_clean {
    my ( $out, $status, $label ) = @_;
    like( $out, qr/\bWORKED\b/, "$label: the work completed" );
    is( $status, 0, "$label: the process exited 0" )                                         or diag "child output was:\n$out";
    unlike( $out, qr/Can't undef active subroutine/, "$label: no global-destruction croak" ) or diag "child output was:\n$out";
}
subtest 'one fiber parked in the shared CV is clean' => sub {
    my ( $out, $status ) = run_child(<<'CHILD');
async {
    my @f = map { fiber { await_sleep(0.001); 1 } } 1;
    say 'ok ' . scalar await $_ for @f;
    say 'WORKED';
};
CHILD
    check_clean( $out, $status, 'one parker' );
};
subtest 'four fibers that never park are clean' => sub {
    my ( $out, $status ) = run_child(<<'CHILD');
async {
    my @f = map { fiber { 1 + 1 } } 1 .. 4;
    say 'ok ' . scalar await $_ for @f;
    say 'WORKED';
};
CHILD
    check_clean( $out, $status, 'no parker' );
};
subtest 'two parkers that never overlap are clean' => sub {
    my ( $out, $status ) = run_child(<<'CHILD');
async {
    say 'ok ' . scalar await fiber { await_sleep(0.001); 1 };
    say 'ok ' . scalar await fiber { await_sleep(0.001); 2 };
    say 'WORKED';
};
CHILD
    check_clean( $out, $status, 'sequential parkers' );
};
subtest 'two fibers parked concurrently in the same CV' => sub {
    my ( $out, $status ) = run_child(<<'CHILD');
async {
    my @f = map { fiber { await_sleep(0.001); 1 } } 1 .. 2;
    say 'ok ' . scalar await $_ for @f;
    say 'WORKED';
};
CHILD
    check_clean( $out, $status, 'two concurrent parkers' );
};
subtest 'a shared closure called from many fibers, as eg/affinity.pl does' => sub {

    # The shape a committed demo actually uses, and the one a user writes by accident. The fiber body is
    # hoisted into a named closure so the park happens inside one shared CV.
    my ( $out, $status ) = run_child(<<'CHILD');
my $body = sub { return await_core_id() };
async {
    my @f = map { fiber { $body->() } } 1 .. 20;
    my %seen;
    $seen{ scalar await $_ }++ for @f;
    say 'WORKED';
};
CHILD
    check_clean( $out, $status, 'shared closure' );
};
#
done_testing();
