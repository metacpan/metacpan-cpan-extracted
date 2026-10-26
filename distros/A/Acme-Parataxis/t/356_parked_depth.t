use v5.40;
use Test2::V1 -ipP;
use blib;
use File::Temp      ();
use Acme::Parataxis qw[:all];

# Regression test. Two or more fibers parked concurrently in the *same* CV used to leave that CV with a
# fabricated CvDEPTH that nothing ever withdrew, and perl then croaked "Can't undef active subroutine during
# global destruction" and exited 22. One fiber was fine. eg/affinity.pl -- a committed demo -- exited 22
# because of it, having printed a complete report first.
#
#   use v5.40;
#   use blib;
#   use Acme::Parataxis qw[:all];
#   async {
#       my @f = map { fiber { await_sleep(0.001); 1 } } 1 .. 2;
#       say 'ok ' . scalar await $_ for @f;
#   };
#
# The cause was Pass 1b's pin. Pinning a CV's CvDEPTH above its live frame count is a loan: it makes the next
# ++CvDEPTH land on a pad of its own instead of aliasing a parked one, but the borrower only repays it by
# popping, and a pop restores CvDEPTH to that frame's own olddepth -- one level higher than it would have
# been without the pin. Each pop was individually correct, yet the counter settled one level too high per
# parker, so two parkers finished at 1 and twenty at 19. Pass 1c now hands the level back at the swap
# boundary, once no fiber claims the CV and no frame of it is live on the resuming stack.
#
# Every subtest below runs a child perl, because the croak happens during global destruction -- after
# done_testing, after the last assertion, once the test file itself is being finalised. There is no way
# to observe it from inside the test process, so the exit status of a real child is the only honest
# witness. Each case asserts the three things that together mean "clean": the work completed, the
# process exited 0, and the teardown croak is absent from the output.
#
# The three controls -- one parker, no parker, and two parkers that never overlap -- passed before the fix
# and pass after it, so a regression that only broke the concurrent case would still be caught. The two
# defect cases failed 4/4 before the fix and are what this file exists to keep failing if the pin ever
# stops being repaid.
#
# The unwound-path residual this file's original note called "still unfixed" is closed: a torn fiber's
# claims are purged by destroy_coro and settled by the next swap's Pass 1c, and the never-destroyed-fiber
# case is covered by para_cvreg_purge_fiber() at the deadlock and failed-run epilogue points (56b956e).
# This file now only guards the two original defect cases above.
sub run_child {
    my ($body) = @_;
    my $log    = File::Temp->new( SUFFIX => '.log' );
    my $code   = join "\n", 'use v5.40;', 'use blib;', 'use Acme::Parataxis qw[:all];', '$|++;', $body, '';
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
done_testing();
