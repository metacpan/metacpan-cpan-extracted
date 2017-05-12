package CLI::Framework::Command::Help;
use base qw( CLI::Framework::Command::Meta );

use strict;
use warnings;

our $VERSION = 0.01;

#-------

sub usage_text {
    q{
    help [command name]: usage information for an individual command or the application itself
    }
}

sub run {
    my ($self, $opts, @args) = @_;

    my $app = $self->get_app(); # metacommand is app-aware

    my $usage;
    my $command_name = shift @args;

    # Recognize help requests that refer to the target command by an alias...
    my %alias = $app->command_alias();
    $command_name = $alias{$command_name} if $command_name && exists $alias{$command_name};

    # First, attempt to get command-specific usage message...
    if( $command_name ) {
        # (do not show command-specific usage message for non-interactive
        # commands when in interactive mode)
        $usage = $app->usage( $command_name, @args )
            unless( $app->get_interactivity_mode() && ! $app->is_interactive_command($command_name) );
    }
    # Fall back to application usage message...
    $usage ||= $app->usage();
    return $usage;
}

#-------
1;

__END__

=pod

=head1 NAME

CLI::Framework::Command::Help - CLIF built-in command to print application or
command-specific usage messages

=head1 SEE ALSO

L<Command usage()|CLI::Framework::Command/usage( $subcommand_name, @subcommand_chain )>

L<Application usage()|CLI::Framework::Application/usage( $command_name, @subcommand_chain )>

L<CLI::Framework::Command>

=cut
