package TestWorker;
use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($DEBUG);

use AnyEvent;
use Moose;

extends 'AnyEvent::Gearman::WorkerPool::Worker';

my $t;
sub slowreverse{
    DEBUG 'slowreverse';
    my $self = shift;
    my $job = shift;
    $t = AE::timer 1,0, sub{
        my $res = reverse($job->workload);
        $job->complete( $res );
        undef($t);
    };
}

sub reverse{
    DEBUG 'reverse';
    my $self = shift;
    my $job = shift;
    my $res = reverse($job->workload);
    DEBUG $res;
    $job->complete( $res );
}

sub _private{
    my $self = shift;
    my $job = shift;
    DEBUG "_private:".$job->workload;
    $job->complete();
}

1;
