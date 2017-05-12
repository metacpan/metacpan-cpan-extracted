package App::MultiModule::Test;
$App::MultiModule::Test::VERSION = '1.143160';
use strict;use warnings;
use POSIX ":sys_wait_h";
use IPC::Transit;
use Test::More;
use Message::Match qw(mmatch);

my @test_queues = qw/test_queue_full tqueue tqueue_out OtherModule Router OtherExternalModule tqueue_out_alt OtherModule_out YetAnotherExternalModule_out OtherExternalModule OtherModule YetAnotherExternalModule tqueue_out_secondary tqueue_out_tertiary OutOfBand MultiModule OtherExternalModule OtherModule Router test_alert_queue OtherExternalModule_out OtherModule_out Incrementer StatelessProducer Incrementer_out TaskDoesNotCompile/;

=head2 begin
=cut
sub begin {
    if($^O !~ /linux/i) {
        ok 1, 'this only works on Linux, so we are just going to pass';
        done_testing();
        exit 0;
    }
#    $IPC::Transit::config_dir = "/tmp/app_multimodule_transit_$$";
    unlink 'test.conf' if -e 'test.conf';
    system 'rm -rf state';
    clear_queue($_) for @test_queues;
    unlink 'debug.out';
}

my $program_pid;

=head2 finish
=cut
sub finish {
    unlink 'test.conf' if -e 'test.conf';
    system 'rm -rf state';
    clear_queue($_) for @test_queues;
    unlink 'debug.out';
    system "rm -rf /tmp/app_multimodule_transit_$$";
}


=head2 run_program
=cut
sub run_program {
    my $args = shift or die "App::MultiModule::Test::run_program: args required";
    my @args = split /\s+/, $args;

#    unshift @args, '-Ilib', 'bin/MultiModule'; #, '-T';
#    push @args, "/tmp/app_multimodule_transit_$$";
    my $new_pid = fork;
    die "App::MultiModule::Test::run_program: fork failed: $!"
        if not defined $new_pid;
    if(not $new_pid) {
        $ENV{PATH}="bin/:$ENV{PATH}";
        exec 'bin/MultiModule', @args;
        exit;
    }
    sleep 1;
    eval {
        open my $fh, '<', "/proc/$new_pid/cmdline"
            or die "failed to open /proc/$new_pid/cmdline for reading: $!\n";
        read $fh, my $cmdline, 1024
            or die "failed to read from /proc/$new_pid/cmdline: $!\n";;
        close $fh
            or die "failed to close /proc/$new_pid/cmdline: $!\n";
    };
    if($@) {
        die "App::MultiModule::Test::run_program: failed: $@\n";
    }
    $program_pid = $new_pid;
    return $program_pid;
}

=head2 cleanly_exit
=cut
sub cleanly_exit {
    my $qname = shift;
    ok IPC::Transit::send(qname => 'tqueue', message => {
        '.multimodule' => {
            control => [
                {   type => 'cleanly_exit',
                    exit_externals => 1,
                }
            ],
        }
    });
    sleep 6;
}

=head2 term_program
=cut
sub term_program {
    kill 15, $program_pid;
    sleep 4;
    kill 9, $program_pid;
    sleep 2;
    waitpid($program_pid, WNOHANG);
}

=head2 fetch_alerts
=cut
sub fetch_alerts {
    my $qname = shift;
    my $match = shift;
    my $got_levels = shift;
    my $how_long = shift;
    my %args = @_;
    my $founds = [];
    $got_levels = {} unless $got_levels;
    local $SIG{ALRM} = sub { die "timed out\n"; };
    alarm $how_long;
    eval {
        while(1) {
            while(my $message = IPC::Transit::receive(qname => $qname)) {
                if(     $message->{messages} and
                        ref $message->{messages} eq 'ARRAY' and
                        $message->{messages}->[0] and
                        $message->{messages}->[0]->{args} and
                        $message->{messages}->[0]->{args}->{message}) {
                    my $m = $message->{messages}->[0]->{args}->{message};
#                    print STDERR '$m=' . Data::Dumper::Dumper $m;
                    if(mmatch($m, $match)) {
                        $got_levels->{$m->{level}} = 0
                            unless $got_levels->{$m->{level}};
                        $got_levels->{$m->{level}}++;
                        push @{$founds}, $m;
                    }
                }
            }
        }
    };
    return ($got_levels, $founds);
}

=head2 clear_queue
=cut
sub clear_queue {
    my $qname = shift;
    IPC::Transit::receive(qname => $qname, nonblock => 1) for (1..100);
}

1;

