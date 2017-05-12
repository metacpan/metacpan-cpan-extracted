
=head1 DESCRIPTION

This file tests the L<Beam::Runner::Command> class to ensure it loads
command classes correctly and passes in the right arguments.

This file uses the C<t/lib/Beam/Runner/Command/test.pm> file as a test
command named C<test>.

=head1 SEE ALSO

L<Beam::Runner::Command>

=cut

use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::Fatal;
use Beam::Runner::Command;

subtest 'load and run a command' => sub {
    my $exit;
    ok !exception { $exit = Beam::Runner::Command->run( test => 1 ) },
        'test command run successfully';
    is $exit, 0, 'exit code correct';
    no warnings 'once';
    is_deeply $Beam::Runner::Command::test::got_args, [ 1 ], 'args correct';
};

done_testing;
