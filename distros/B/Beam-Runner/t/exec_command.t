
=head1 DESCRIPTION

This tests the L<Beam::Runner::ExecCommand> module.

=cut

use strict;
use warnings;
use Test::More;
use Capture::Tiny qw( capture );
use Beam::Runner::ExecCommand;

subtest 'string script' => sub {
    my $cmd = Beam::Runner::ExecCommand->new(
        command => 'echo "Hello, World"',
    );
    my ( $stdout, $stderr, $exit ) = capture {
        $cmd->run();
    };
    is $stdout, "Hello, World\n", 'stdout is correct';
    ok !$stderr, 'nothing on stderr';
    is $exit, 0, 'exit code 0';
};

subtest 'array of arguments' => sub {
    my $cmd = Beam::Runner::ExecCommand->new(
        command => [ 'echo', 'Hello, World' ],
    );
    my ( $stdout, $stderr, $exit ) = capture {
        $cmd->run();
    };
    is $stdout, "Hello, World\n", 'stdout is correct';
    ok !$stderr, 'nothing on stderr';
    is $exit, 0, 'exit code 0';
};

done_testing;
