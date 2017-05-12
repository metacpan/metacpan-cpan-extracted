
=head1 DESCRIPTION

This file tests the L<Beam::Minion::Command::worker> class to ensure
that it loads the correct L<Minion> instance and registers
a fully-functional worker.

This worker loads the container from C<t/share/container.yml> to access
the service from C<t/lib/Local/Stop.pm>.

=head1 SEE ALSO

L<Beam::Minion::Command::worker>

=cut

use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::Fatal;
use Beam::Minion::Command::worker;
use File::Temp;
use FindBin ();
use File::Spec::Functions qw( catdir );
use Mock::MonkeyPatch;
my $tmp = File::Temp->new( EXLOCK => 0 );

my $mock = Mock::MonkeyPatch->patch(
    'Minion::Command::minion::worker::run',
    sub { },
);

my $class = 'Beam::Minion::Command::worker';
$ENV{BEAM_MINION} = 'sqlite:' . $tmp->filename;
$ENV{BEAM_PATH} = catdir( $FindBin::Bin, '..', 'share' );
$class->run( 'container' );

ok $mock->called, 'Minion::Command::minion::worker->run called';
is_deeply $mock->method_arguments, [qw( -q container )], 'correct queue is used';

my $invocant = $mock->arguments->[0];
my $minion = $invocant->app->minion;

subtest 'tasks are created' => sub {
    my $tasks = $minion->tasks;
    ok exists $tasks->{success}, 'success task exists';
    ok exists $tasks->{failure}, 'failure task exists';
};

subtest 'success job' => sub {
    my $id = $minion->enqueue( 'success', [], { queue => 'container' } );
    $minion->perform_jobs( { queues => ['container'] } );
    my $job = $minion->job( $id );
    is_deeply $job->info->{result}, { exit => 0 }, 'job result is correct';
    is $job->info->{state}, 'finished', 'job finished successfully';
};

subtest 'failure job' => sub {
    my $id = $minion->enqueue( 'failure', [], { queue => 'container' } );
    $minion->perform_jobs( { queues => ['container'] } );
    my $job = $minion->job( $id );
    is_deeply $job->info->{result}, { exit => 1 }, 'job result is correct';
    is $job->info->{state}, 'failed', 'job failed';
};

subtest 'BEAM_MINION must be set' => sub {
    local $ENV{BEAM_MINION} = '';
    like
        exception {
            Beam::Minion::Command::worker->run( 'container' );
        },
        qr{You must set the BEAM_MINION environment variable},
        'BEAM_MINION missing raises exception';
};

done_testing;
