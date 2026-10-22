use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(alarm sleep time);
use Data::Pool::Shared;

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

for my $method (qw(alloc alloc_n alloc_set)) {
    check_destroy("$method revalidates after signal dispatch", sub {
        my $h = Data::Pool::Shared->new(undef, 2, 16);
        $h->alloc for 1 .. $h->capacity;
        my @args = $method eq 'alloc_n' ? (2) : $method eq 'alloc_set' ? ('value') : ();
        return ($h, sub { $h->$method(@args) });
    });
}

done_testing;
