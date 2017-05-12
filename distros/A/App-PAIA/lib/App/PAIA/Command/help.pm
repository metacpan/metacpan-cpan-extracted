package App::PAIA::Command::help;
use strict;
use v5.10;
use parent 'App::Cmd::Command::help';

our $VERSION = '0.30';

sub execute {
    my ($self, $opts, $args) = @_;

    if ($self->app->global_options->version) {
        $self->app->execute_command( $self->app->prepare_command('version') );
        exit;
    }

    if (@$args) {
        my $command = $args->[0];
        my ($cmd, $opt, $args) = $self->app->prepare_command(@$args);
        
        if (ref($cmd) =~ /::commands$/) { # unrecognized command
            say $self->app->usage->leader_text;
            return;
        }

        require Getopt::Long::Descriptive;
        Getopt::Long::Descriptive->VERSION(0.084);

        my (undef, $usage) = Getopt::Long::Descriptive::describe_options(
            $cmd->usage_desc, $cmd->opt_spec, App::PAIA->global_opt_spec
        );

        my $desc = $cmd->description; chomp $desc;
        say join "\n\n", grep { defined $_ } 
            eval { $usage->leader_text }, 
            length $desc ? $desc : undef,
            "Global options:\n".$self->app->usage->option_text;

        if ($cmd->usage->option_text) {
            say "Command options:";
            say eval { $cmd->usage->option_text };
        }

    } else {
        say $self->app->usage->leader_text;
        say;

        my @cmd_groups = (
            "PAIA auth commands" => [qw(login logout change)],
            "PAIA core commands" => [qw(patron items request renew cancel fees)],
            "client commands"    => [qw(config session help)]
        );

        while (@cmd_groups) {
            say shift(@cmd_groups) . ":";
            for my $command (@{ shift @cmd_groups }) {
                my $abstract = $self->app->plugin_for($command)->abstract;
                printf "%9s: %s\n", $command, $abstract;
            }
            say;
        }    

        say "call 'paia help <command>' or 'perldoc paia' for more details.";
    }
}

1;
__END__

=head1 NAME

App::PAIA::Command::help - show help

=cut
