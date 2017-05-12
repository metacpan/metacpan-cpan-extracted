package MultiModuleTest::OtherExternalModule;
$MultiModuleTest::OtherExternalModule::VERSION = '1.143160';
use strict;use warnings;
use Data::Dumper;
use Message::Transform qw(mtransform);
use IPC::Transit;

use parent 'App::MultiModule::Task';

my @leaked_memory = ();

=head2 is_stateful

=cut
sub is_stateful {
    return 'yes!';
}

=head2 message

=cut
sub message {
    my $self = shift;
    my $message = shift;
    if($message->{crash_me}) {
        print STDERR "OtherExternalModule: I have been commanded to crash\n";
        kill 9, $$; #!!!
    }
    if($message->{uncaught_exception}) {
        my $a = 0;
        my $b = 1;
        my $c = $b / $a;
        #Oddly, I felt some kind of crazy thrill writing the above three lines
    }
    if($message->{leak_memory}) {
        #print STDERR "OtherExternalModule leaking $message->{leak_memory} bytes of memory\n";
        push @leaked_memory, 'h' x $message->{leak_memory};
    }
    if($message->{spin_cpu}) {
        #print STDERR "OtherExternalModule spinning CPU for $message->{spin_cpu} seconds\n";
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm $message->{spin_cpu};
        eval {
            while(1) {
                my $a = 'wtf';
            }
        };
    }
    if($message->{fill_queue}) {
        my $bytes = $message->{fill_queue_bytes} || 1024;
        IPC::Transit::send(
            qname => $message->{fill_queue},
            message => { junk => 'h' x $bytes },
            nonblock => 1,
        );
    }
#    my $ct = 0;
#    while(1) {
#        $ct++;
#    }
#    unlink 'thing.out';
#    while(1) {
#        {   open my $fh, '>>', 'thing.out';
#            print $fh 'h' x 1023 for (1..2);
#            close $fh;
#        }
#        my $sys = "cat /proc/$$/io";
#        system $sys;
#        sleep 1;
#    }
=head1 out
    my @fh;
    my @mem;
    while(1) {
        for(1..20) {
            open my $fh, '<', 'thing.out';
            push @fh, $fh;
            IPC::Transit::send(qname => 'test', message => { junk => 'hsddddddddddddddddddddddddddddddddddd' });
        }
        push @mem, 'h' x (1024 * 1024) for (1..300);
        print 'scalar @fh=' . scalar @fh . "\n";
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 1;
        my $ct = 0;
        eval {
            while(1) {
                $ct++;
            }
        };
        sleep 1;
    }
=cut
    if($message->{oob_testing}) {
        $self->oob_testing($message);
        return;
    }
    if($self->{config}->{transform}) {
        mtransform  $message,
                    $self->{config}->{transform};
    }
    my $incr = $self->{config}->{increment_by};
    my $ct = $message->{ct};
    $self->debug('OtherExternalModule.pm: (message)', message => $message)
        if $self->{debug} > 5;
    $self->debug('OtherExternalModule.pm: (config)', config => $self->{config})
        if $self->{debug} > 5;
    $message->{my_ct} = $ct + $incr;
    $self->{state}->{sum_increment_by} = 0 unless $self->{state}->{sum_increment_by};
    $self->{state}->{sum_increment_by} += $incr;
    $message->{sum_increment_by} = $self->{state}->{sum_increment_by};
    $message->{module_pid} = $$;
#    $self->debug("$$: OtherExternalModule message: " . Data::Dumper::Dumper $message) if $self->{debug};
    $self->{state}->{most_recent} = $message->{my_ct};
    $self->emit($message);
}

=head2 oob_testing

=cut
sub oob_testing {
    my $self = shift;
    my $message = shift;

    $self->send_oob($message->{oob_testing}->{type}, $message);
}

1;
