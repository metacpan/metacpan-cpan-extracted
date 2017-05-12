
=head1 DESCRIPTION

This file tests the L<Beam::Minion::Command::run> class to ensure that it
loads the correct L<Minion> instance and enqueues the correct job.

=head1 SEE ALSO

L<Beam::Minion::Command::run>

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Beam::Minion::Command::run;
use File::Temp;
my $tmp = File::Temp->new( EXLOCK => 0 );

subtest 'BEAM_MINION must be set' => sub {
    like
        exception {
            Beam::Minion::Command::run->run( container => 'ping', 'foo' );
        },
        qr{You must set the BEAM_MINION environment variable},
        'BEAM_MINION missing raises exception';
};

{
    my $class = 'Beam::Minion::Command::run';
    $ENV{BEAM_MINION} = 'sqlite:' . $tmp->filename;
    $class->run( container => 'ping', 'foo' );
}

my $minion = Minion->new( SQLite => 'sqlite:' . $tmp->filename );
$minion->add_task( ping => sub {
    # This sub runs in a fork, so we pass out the args via the job's
    # "result"
    my ( $job, @args ) = @_;
    $job->finish( \@args );
} );

is $minion->stats->{inactive_jobs}, 1, '1 pending job';

my $job = $minion->worker->register->dequeue( 0.5, { queues => ['container'] } );
ok $job, 'job exists';

$job->perform;
my @got_args = @{ $job->info->{result} };
is $got_args[0], 'foo', 'job args are correct';

$minion->worker->unregister;

done_testing;
