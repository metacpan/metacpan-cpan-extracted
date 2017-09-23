
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
    local $ENV{BEAM_MINION} = '';
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
$minion->add_task( 'container:ping' => sub {
    # This sub runs in a fork, so we pass out the args via the job's
    # "result"
    my ( $job, @args ) = @_;
    $job->finish( \@args );
} );

is $minion->stats->{inactive_jobs}, 1, '1 pending job';

my $job = $minion->worker->register->dequeue( 0.5 );
ok $job, 'job exists';

$job->perform;
my @got_args = @{ $job->info->{result} };
is $got_args[0], 'foo', 'job args are correct';

$minion->worker->unregister;

subtest 'job options' => sub {
    my $class = 'Beam::Minion::Command::run';
    $ENV{BEAM_MINION} = 'sqlite:' . $tmp->filename;
    $class->run( container => 'ping', 'foo', '--delay', 1, '--attempts', 2, '--priority', 3 );

    my $job = $minion->worker->register->dequeue( 1.5 );
    ok $job, 'job exists';

    $job->perform;
    my @got_args = @{ $job->info->{result} };
    is $got_args[0], 'foo', 'job args are correct';
    is $job->info->{attempts}, 2, 'correct number of attempts set in job';
    is $job->info->{priority}, 3, 'correct priority set';
    cmp_ok $job->info->{created}, '<', $job->info->{delayed}, 'job was delayed by 1 second';

    $minion->worker->unregister;
};

done_testing;
