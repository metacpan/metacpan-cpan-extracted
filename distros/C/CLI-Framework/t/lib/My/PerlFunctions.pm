package My::PerlFunctions;
use base qw( CLI::Framework );

use strict;
use warnings;

sub option_spec {
    (
        [ 'verbose|v' => 'be noisy' ],
    )
}

sub init {
    my ($self, $opts) = @_;

    # Store App's verbose setting where it will be accessible to commands...
    $self->cache->set( 'verbose' => $opts->{verbose} );

}

sub usage_text {
    q{
    OPTIONS
        -v --verbose:   running commentary about actions

    COMMANDS
        summary:        show perl functions by name
    }
}

sub command_map {
    summary => 'My::PerlFunctions::Command::Summary',
    console => 'CLI::Framework::Command::Console',
    menu    => 'CLI::Framework::Command::Menu',
}

#-------
1;

__END__

=pod

=head1 PURPOSE

The Application class for a very simple CLIF app demo.

This is a contrived example that has only one command to print a one-line
summary of the purpose of the Perl built-in function by the given name.  It is
meant only as a demonstration of how to create a minimal CLI::Framework
application.

=cut
