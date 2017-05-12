use strict;
use warnings;

use Test::More;

BEGIN {
    if (!eval { require IO::Async; IO::Async->import; 1 }) {
        plan skip_all => "IO::Async is required for this test";
    }
}

use Continual::Process;
use IO::Async::Loop;
use IO::Async::Timer::Countdown;
use Continual::Process::Loop::IOAsync;
use Continual::Process::Helper qw(prepare_fork);
use File::Temp;

$ENV{C_P_DEBUG} = 1;

my $tmp = File::Temp->new;
my $tick = 1;

my $loop = IO::Async::Loop->new;
    
my $cp_loop = Continual::Process::Loop::IOAsync->new(
    instances => [
        Continual::Process->new(
            name => 'job1',
            code => prepare_fork(sub {
                my ($instance) = @_;

                print $tmp $instance->id . "\n";
            }),
            instances => 4,
        )->create_instance(),
        Continual::Process->new(
            name => 'job2',
            code => prepare_fork(sub {
                my ($instance) = @_;

                print $tmp $instance->id . "\n";
                exec {$^X} '-ne "sleep 1"';
            }),
        )->create_instance(),
    ],
    on_interval => sub {
        if (!$tick--) {
            $loop->loop_stop;
        }
    }
);
$cp_loop->run();

$loop->add( $cp_loop->timer );

my $timer = IO::Async::Timer::Countdown->new(
    delay     => 0,
    on_expire => sub {pass('IO::Async countdown tick')},
);
$timer->start;

$loop->add( $timer );

$loop->run;

sleep 4;

runs_check(
    $tmp,
    {
        'job2.1' => 1,
        'job1.1' => 2,
        'job1.2' => 2,
        'job1.3' => 2,
        'job1.4' => 2,
    }
);

done_testing(2);

sub runs_check {
    my ($tmp, $expected) = @_;

    close $tmp;

    open my $file, '<', $tmp;
    my @rows = <$file>;
    close $file;

    my %histo;
    foreach my $row (@rows) {
        chomp $row;
        $histo{$row}++;
    }

    is_deeply(\%histo, $expected, 'runs check');
}


