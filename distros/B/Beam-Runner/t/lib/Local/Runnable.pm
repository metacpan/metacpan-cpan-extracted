package Local::Runnable;

=head1 NAME

Local::Runnable - A test runnable module

=head1 SYNOPSIS

    use Test::Lib;
    use Local::Runnable;

=head1 DESCRIPTION

This is a small test class to ensure that runnable objects can be run,
and their documentation is found correctly.

=head1 ARGUMENTS

=head2 <arg>

Any arguments are allowed and will be saved in the C<got_args> class
variable.

=head1 OPTIONS

There are no options here, but I'm explicitly saying that to ensure this
section shows up in documentation.

=head1 ENVIRONMENT

This module uses no environment variables, but I'm saying that to ensure
this section shows up in documentation.

=head1 SEE ALSO

L<Test::Lib>, L<beam>

=cut

use Moo;
with 'Beam::Runnable';

=attr $Local::Runnable::got_args

The arguments we got to the C<run()> method

=cut

our $got_args = [];

=attr exit

The exit value to return from C<run()>

=cut

has exit => ( is => 'rw' );

=method run

Called by the C<run> command. Saves the arguments in the C<got_args>
attribute and returns the C<exit> value.

=cut

sub run {
    my ( $self, @args ) = @_;
    $got_args = \@args;
    return $self->exit;
}

1;
