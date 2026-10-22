use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(alarm sleep time);
use Data::PubSub::Shared;

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

for my $variant (qw(Int Int32 Int16 Str)) {
    for my $method (qw(poll_wait poll_wait_multi)) {
        for my $destroy_parent (0, 1) {
            check_destroy("$variant $method revalidates subscriber and channel ($destroy_parent)", sub {
                my $h = "Data::PubSub::Shared::$variant"->new(undef, 16);
                my $sub = $h->subscribe;
                my @args = $method eq 'poll_wait_multi' ? (2) : ();
                return ($destroy_parent ? $h : $sub, sub { $sub->$method(@args) });
            });
        }
    }
}
for my $method (qw(publish publish_notify publish_multi clear)) {
    check_destroy("Str $method revalidates after a mutex wait", sub {
        my $h = Data::PubSub::Shared::Str->new_memfd('signal-destroy', 16);
        open my $fh, '+<&', $h->memfd or die $!;
        sysseek($fh, 72, 0) // die $!;
        syswrite($fh, pack('L', getppid() | 0x80000000)) == 4 or die $!;
        my @args = $method eq 'clear' ? () : ('value');
        return ($h, sub { $h->$method(@args); close $fh });
    });
}

done_testing;
