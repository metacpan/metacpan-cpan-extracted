use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(alarm sleep time);
use Data::Deque::Shared;

sub check_destroy {
    my ($label, $setup) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $ok = eval {
            my ($victim, $wait) = $setup->();
            local $SIG{ALRM} = sub { $victim->DESTROY };
            alarm 0.04;
            eval { $wait->() };
            my $error = $@;
            alarm 0;
            die "wait did not reject the destroyed handle: $error"
                unless $error =~ /replaced or destroyed/;
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    my $deadline = time + 3;
    my $status;
    while (time < $deadline) {
        if (waitpid($pid, WNOHANG) == $pid) { $status = $?; last }
        sleep 0.01;
    }
    if (!defined $status) { kill 'KILL', $pid; waitpid($pid, 0) }
    ok(defined($status) && $status == 0, $label);
}

for my $variant (qw(Int Str)) {
    for my $method (qw(push_back_wait push_front_wait pop_back_wait pop_front_wait)) {
        check_destroy("$variant $method revalidates after signal dispatch", sub {
            my $h = "Data::Deque::Shared::$variant"->new(undef, 2, ($variant eq q{Str} ? (32) : ()));
            if ($method =~ /^push/) {
                $h->push_back(1) for 1 .. $h->capacity;
                return ($h, sub { $h->$method(2) });
            }
            return ($h, sub { $h->$method() });
        });
    }
}

done_testing;
