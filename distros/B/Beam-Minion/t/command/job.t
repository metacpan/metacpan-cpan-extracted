
=head1 DESCRIPTION

This file tests the L<Beam::Minion::Command::job> class to ensure
that it loads the correct L<Minion> instance and delegates to the correct
command.

This worker loads the container from C<t/share/container.yml> to access
the service from C<t/lib/Local/Stop.pm>.

=head1 SEE ALSO

L<Beam::Minion::Command::job>

=cut

use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::Fatal;
use Beam::Minion::Command::job;
use File::Temp;
use FindBin ();
use File::Spec::Functions qw( catdir );
use Mock::MonkeyPatch;
my $tmp = File::Temp->new( EXLOCK => 0 );

my $mock = Mock::MonkeyPatch->patch(
    'Minion::Command::minion::job::run',
    sub { },
);

my $class = 'Beam::Minion::Command::job';
$ENV{BEAM_MINION} = 'sqlite:' . $tmp->filename;
$ENV{BEAM_PATH} = catdir( $FindBin::Bin, '..', 'share' );
my $obj = $class->new;
$obj->run( '-w' );

ok $mock->called, 'Minion::Command::minion::job->run called';
is_deeply $mock->method_arguments, [qw( -w )], 'arguments are correct';
my $minion = $obj->app->minion;

subtest 'tasks are created' => sub {
    my $tasks = $minion->tasks;
    ok exists $tasks->{'container:success'}, 'success task exists';
    ok exists $tasks->{'container:failure'}, 'failure task exists';
    ok exists $tasks->{'container:exception'}, 'exception task exists';
    ok exists $tasks->{'container:consfail'}, 'consfail task exists';
};

subtest 'BEAM_MINION must be set' => sub {
    local $ENV{BEAM_MINION} = '';
    like
        exception {
            Beam::Minion::Command::job->new->run();
        },
        qr{You must set the BEAM_MINION environment variable},
        'BEAM_MINION missing raises exception';
};

done_testing;
