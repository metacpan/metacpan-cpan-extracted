
=head1 DESCRIPTION

This tests the L<Beam::Runner::ExecCommand> module.

=cut

use strict;
use warnings;
use Test::More;
use Beam::Runner::Steps;

{   package Local::Step;
    use Moo;
    with 'Beam::Runnable';
    has args => ( is => 'rw' );
    sub run {
        my ( $self, @args ) = @_;
        $self->args( \@args );
        return 0;
    }
}
{   package Local::Foo;
    use Moo;
    extends 'Local::Step';
}
{   package Local::Bar;
    use Moo;
    extends 'Local::Step';
}
{   package Local::Fail;
    use Moo;
    extends 'Local::Step';
    around run => sub {
        my ( $orig, $self, @args ) = @_;
        $self->$orig( @args );
        return 1;
    }
}

subtest 'steps' => sub {
    my $cmd = Beam::Runner::Steps->new(
        steps => [
            Local::Foo->new,
            Local::Bar->new,
        ],
    );
    my @args = qw( 1 2 3 );
    my $exit = $cmd->run( @args );
    is $exit, 0, 'exit from last step';
    is_deeply $cmd->steps->[0]->args, \@args, 'args to step 0 correct';
    is_deeply $cmd->steps->[1]->args, \@args, 'args to step 1 correct';
};

subtest 'failure stops steps' => sub {
    my $cmd = Beam::Runner::Steps->new(
        steps => [
            Local::Foo->new,
            Local::Fail->new,
            Local::Bar->new,
        ],
    );
    my @args = qw( 1 2 3 );
    my $exit = $cmd->run( @args );
    is $exit, 1, 'exit from last step executed';
    is_deeply $cmd->steps->[0]->args, \@args, 'args to step 0 correct';
    is_deeply $cmd->steps->[1]->args, \@args, 'args to step 1 correct';
    is_deeply $cmd->steps->[2]->args, undef, 'step 2 has no args (not executed)';
};

done_testing;
