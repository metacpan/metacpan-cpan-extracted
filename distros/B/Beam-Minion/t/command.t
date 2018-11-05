
=head1 DESCRIPTION

This test ensures that L<Beam::Runner::Command::minion> correctly delegates
to the correct C<Beam::Minion::Command> module.

=head1 SEE ALSO

L<Beam::Runner::Command::minion>, L<Beam::Runner::Command>

=cut

use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::Fatal;
use Beam::Runner::Command;

subtest 'delegates to correct module' => sub {
    local @Beam::Minion::Command::test::ARGS;
    ok !exception { Beam::Runner::Command->run( 'minion', 'test', 1, 2, 3 ) },
        'command is run successfully'
            or diag $@;
    my $obj = shift @Beam::Minion::Command::test::ARGS;
    isa_ok $obj, 'Beam::Minion::Command::test', 'object is created';
    is_deeply \@Beam::Minion::Command::test::ARGS,
        [qw( 1 2 3 )],
        'arguments to command are correct';
};

subtest 'error if no module specified' => sub {
    is exception { Beam::Runner::Command->run( 'minion' ) },
        "ERROR: No 'beam minion' sub-command specified\n";
};

subtest 'error if module does not exist' => sub {
    is exception { Beam::Runner::Command->run( 'minion', 'DOES_NOT_EXIST' ) },
        "ERROR: No such sub-command: DOES_NOT_EXIST\n";
};

done_testing;
