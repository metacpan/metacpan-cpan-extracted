use strict; use warnings; use Test::More; use Config; use POSIX (); use File::Temp 'tempdir';
use Data::PerfectHash::Shared;

# Adversarial cross-bless coverage for the type_tag guard on PhSet/PhBuilder
# (SEXTRACT/BEXTRACT and both DESTROYs in Shared.xs). bless() only repoints
# an RV's stash; it never touches the underlying C struct, so
# sv_derived_from() alone cannot tell a Set reblessed as ::Builder (or vice
# versa) from the real thing -- the method call proceeds and, without a
# type_tag, reinterprets the wrong struct: a hard crash (ASAN: allocation-
# size-too-big), not a Perl exception. Isolated in a forked child, same as
# xt/destroy_during_call.t and t/02_corrupt.t's each_key case: a signal
# death is a crash the guard failed to prevent, a croak with the wrong
# message means the wrong guard (or none) fired.
#
# Each case is a single sub that (1) cross-blesses a handle, (2) calls a
# method on it -- expected to croak -- and (3) lets that handle go out of
# scope via the exception unwind, which is a genuine scope exit and fires
# DESTROY right there, inside the same eval, before the child ever reaches
# _exit. A crash in either the method call or that DESTROY is caught the
# same way: the process dies by signal and waitpid sees it below.
plan skip_all => 'fork required' unless $Config{d_fork};

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/x.phs";
Data::PerfectHash::Shared->build_int($path, [1 .. 10]);

my @cases = (
    ['Set blessed as Builder: method call croaks, scope-exit DESTROY does not crash',
     qr/not a .*handle|Builder/,
     sub {
         my $s = Data::PerfectHash::Shared->load($path);
         bless $s, 'Data::PerfectHash::Shared::Builder';
         $s->count;
     }],
    ['Builder blessed as Set: method call croaks, scope-exit DESTROY does not crash',
     qr/not a .*handle|Shared/,
     sub {
         my $b = Data::PerfectHash::Shared->new_builder(type => 'int');
         $b->add(1);
         bless $b, 'Data::PerfectHash::Shared';
         $b->count;
     }],
);

for my $c (@cases) {
    my ($name, $want, $call) = @$c;
    my $pid = fork;
    unless (defined $pid) { plan skip_all => "fork: $!" }
    unless ($pid) {
        my $ok = eval { $call->(); 1 };
        my $err = $@ // '';
        POSIX::_exit($ok ? 9 : ($err =~ $want ? 0 : 8));
    }
    waitpid $pid, 0;
    my $st = $?;
    ok !($st & 127), "no crash: $name" or diag "died from signal " . ($st & 127);
    is $st >> 8, 0, "clean croak with the expected message: $name";
}
done_testing;
