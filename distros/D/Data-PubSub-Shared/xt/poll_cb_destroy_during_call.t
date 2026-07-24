use strict;
use warnings;
use Test::More;
use Config;
use Data::PubSub::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# poll_cb dispatches each message via call_sv -- arbitrary Perl -- and then
# loops back into pubsub_<variant>_poll(sub, ...).  Two ways the callback
# can invalidate the C subscriber that the loop is about to reuse:
#
# 1. $sub->DESTROY explicitly: pubsub_sub_destroy() frees the PubSubSub and
#    zeroes the IV.  The EXTRACT_SUB/psx_guard pins only block
#    refcount-driven destruction, not an explicit DESTROY, so the loop's
#    `sub` pointer dangles.
# 2. $sub = 42: the callback closure mutates the same SV that ST(0)
#    aliases (Perl passes aliases), so the invocant is no longer a
#    reference and SvRV on it is a wild read.
#
# After every callback return poll_cb must REEXTRACT_SUB and croak
# "... object destroyed during the call" / "... object was replaced during
# the call" instead of dereferencing the freed pointer.  Without the guard
# the next loop iteration reads/writes freed heap: it either segfaults
# (caught as a signal below) or, if the freed memory is still mapped,
# silently runs on through it and poll_cb returns normally (exit 7 below).
# Both are failures; only the specific croak is a pass.
#
# Each child publishes 3 messages and destroys/replaces on the FIRST
# callback, so the defect window (second and later loop iterations) is
# always exercised.  alarm is a backstop against a garbage-cursor spin in
# the unfixed code.

my @cases;

for my $variant (qw(Int Str Int32 Int16)) {
    push @cases, ["Data::PubSub::Shared::${variant}::Sub (destroy in callback)" => sub {
        my $ps = "Data::PubSub::Shared::$variant"->new(undef, 32);
        $ps->publish($variant eq 'Str' ? "msg$_" : $_) for 1..3;
        my $sub = $ps->subscribe_all;
        my $n = 0;
        my $ok = eval {
            $sub->poll_cb(sub { $n++; $sub->DESTROY if $n == 1 });
            1;
        };
        my $err = $@;
        exit 0 if !$ok && $err =~ /destroyed during the call/;
        exit 7;
    }];
}

push @cases, ['Data::PubSub::Shared::Int::Sub (replace invocant in callback)' => sub {
    my $ps = Data::PubSub::Shared::Int->new(undef, 32);
    $ps->publish($_) for 1..3;
    my $sub = $ps->subscribe_all;
    my $n = 0;
    my $ok = eval {
        $sub->poll_cb(sub { $n++; $sub = 42 if $n == 1 });
        1;
    };
    my $err = $@;
    exit 0 if !$ok && $err =~ /replaced during the call/;
    exit 7;
}];

for my $case (@cases) {
    my ($name, $code) = @$case;
    my $pid = fork();
    unless ($pid) {
        alarm 10;
        $code->();
        exit 7;   # unreachable unless the child forgot to exit
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$name: no crash when the callback invalidates the subscriber"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$name: poll_cb croaks instead of reusing the freed subscriber";
}

done_testing;
