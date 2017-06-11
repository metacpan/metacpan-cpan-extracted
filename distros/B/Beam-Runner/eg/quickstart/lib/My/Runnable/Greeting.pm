package My::Runnable::Greeting;
use Moo;
with 'Beam::Runnable';
sub run {
    my ( $self, @args ) = @_;
    print "Hello, World!\n";
}
1;

=head1 NAME

My::Runnable::Greeting - Greet the user

=head1 SYNOPSIS

    beam run greet hello

=head1 DESCRIPTION

This task greets the user warmly and then exits.

=head1 ARGUMENTS

No arguments are allowed during a greeting.

=head1 OPTIONS

Greeting warmly is the only option.

=head1 SEE ALSO

L<Beam::Runnable>
