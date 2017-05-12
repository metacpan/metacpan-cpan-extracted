package CLI::Framework::Command::Alias;
use base qw( CLI::Framework::Command::Meta );

use strict;
use warnings;

our $VERSION = 0.01;

#-------

sub usage_text {
    q{
    alias [<cmd-name>]: show command aliases
                        [and subcommand aliases for <cmd-name>, if given]

    ARGUMENTS
        <cmd-name>: if specified, show aliases for this command only and show
                    its subcommand aliases
    }
}

sub run {
    my ($self, $opts, @args) = @_;

    my $app = $self->get_app();
    my %cmd_alias_to_name = $app->command_alias();
    my $cmd = shift @args;

    # Ignore non-interactive commands while in interactive mode...
    if( $app->get_interactivity_mode() ) {
        while( my ($k,$v) = each %cmd_alias_to_name ) {
            if( ! $app->is_interactive_command( $v ) ) {
                delete $cmd_alias_to_name{ $k };
            }
        }
    }
    # Alias command only recognizes one argument: a top-level command...
    if( $cmd ) {
        # Recognize alias requests by alias...
        $cmd = $cmd_alias_to_name{$cmd} if exists $cmd_alias_to_name{$cmd};

        # Silently pass if invalid command...
        return unless $app->is_valid_command_name( $cmd );

        # Formatted display of aliases to specific command...
        my $summary = $self->_cmd_alias_hash_to_summary(
            \%cmd_alias_to_name,
            target => $cmd
        );
        # Formatted display of aliases to subcommand...
        my $cmd_object = $app->registered_command_object( $cmd )
            || $app->register_command( $cmd );
        my %subcommand_alias = $cmd_object->subcommand_alias();
        my $subcommand_summary = $self->_cmd_alias_hash_to_summary(
            \%subcommand_alias,
        );
        if( $subcommand_summary ) {
            $summary .= sprintf( "\n%15s '%s':\n", 'SUBCOMMANDS of command', $cmd );
            $summary .= sprintf( "\n%s", $subcommand_summary );
        }
        return $summary;
    }
    else {
        # Formatted display of all aliases...
        my $summary = $self->_cmd_alias_hash_to_summary(
            \%cmd_alias_to_name,
        );
        return $summary;
    }
}

sub _cmd_alias_hash_to_summary {
    my ($self, $aliases, %param) = @_;

    my $target = $param{target};

    my %name_to_alias_set;
    while( my ($alias, $name) = each %$aliases ) {
        next if $alias =~ /^\d+$/;  # ignore numerical aliases
        next if $target && $name ne $target;
        push @{ $name_to_alias_set{$name} }, $alias;
    }
    return $self->format_name_to_aliases_hash( \%name_to_alias_set );
}

sub format_name_to_aliases_hash {
    my ($self, $h, $indent) = @_;

    $indent ||= 10;
    my $format = '%'.$indent."s: %s\n";

    my @output;
    for my $command (keys %$h) {
        push @output, sprintf
            $format, $command, join( ', ', @{$h->{$command}} );
    }
    my @output_sorted = sort {
        my $name_a = substr( $a, index($a, ':') );
        my $name_b = substr( $b, index($b, ':') );
        $name_a cmp $name_b;
    } @output;
    return join( '', @output );
}

__END__

=pod

=head1 NAME

CLI::Framework::Command::Alias - CLIF built-in command to display the command
aliases that are in effect for the running application and its commands

=head1 SEE ALSO

L<command_alias|CLI::Framework::Application/command_alias()>

L<CLI::Framework::Command>

=cut
