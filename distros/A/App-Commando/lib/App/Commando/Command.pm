package App::Commando::Command;

use strict;
use warnings;

use Carp;
use Getopt::Long;
use Moo;

use App::Commando::Logger;
use App::Commando::Option;
use App::Commando::Presenter;

has 'actions'       => ( is => 'rw' );
has 'aliases'       => ( is => 'ro' );
has 'commands'      => ( is => 'rw' );
has 'description'   => ( is => 'rw' );
has 'map'           => ( is => 'ro' );
has 'name'          => ( is => 'ro' );
has 'options'       => ( is => 'rw' );
has 'parent'        => ( is => 'rw' );

sub BUILDARGS {
    my ($class, $name, $parent) = @_;

    return {
        actions     => [],
        aliases     => [],
        commands    => {},
        map         => {},
        name        => $name,
        options     => [],
        parent      => $parent,
    };
}

# Gets or sets the command version
sub version {
    my ($self, $version) = @_;

    $self->{_version} = $version if defined $version;
    return $self->{_version};
}

sub syntax {
    my ($self, $syntax) = @_;

    $self->{_syntax} = $syntax if defined $syntax;

    my @syntax_list = ();

    if ($self->parent) {
        my $parent_syntax = $self->parent->syntax;
        $parent_syntax =~ s/<[\w\s-]+>|\[[\w\s-]+\]//g;
        $parent_syntax =~ s/^\s+|\s+$//g;
        push @syntax_list, $parent_syntax;
    }
    push @syntax_list, ($self->{_syntax} || $self->name);

    return join ' ', @syntax_list;
}

sub default_command {
    my ($self, $command_name) = @_;

    if ($command_name) {
        if (exists $self->commands->{$command_name}) {
            return $self->{_default_command} = $self->commands->{$command_name};
        }
        else {
            croak "$command_name couldn't be found in this command's list of " .
                "commands.";
        }
    }
    else {
        return $self->{_default_command};
    }
}

sub option {
    my ($self, $config_key, @info) = @_;

    my $option = App::Commando::Option->new($config_key, @info);
    push @{$self->options}, $option;
    $self->map->{$option} = $config_key;

    return $option;
}

sub command {
    my ($self, $command_name) = @_;

    my $cmd = App::Commando::Command->new($command_name, $self);
    $self->commands->{$command_name} = $cmd;

    return $cmd;
}

sub alias {
    my ($self, $command_name) = @_;

    $self->logger->debug("adding alias to parent for self: $command_name");
    push @{$self->aliases}, $command_name;
    $self->parent->commands->{$command_name} = $self if defined $self->parent;
}

sub action {
    my ($self, $code) = @_;

    push @{$self->actions}, $code;
}

sub logger {
    my ($self) = @_;

    unless ($self->{_logger}) {
        $self->{_logger} = App::Commando::Logger->new(*STDOUT);
        $self->{_logger}->level('info');
        $self->{_logger}->formatter(sub {
            my ($level, $message) = @_;

            return $self->identity . ' | ' .
                sprintf("%-7s", ucfirst lc $level) . ": $message\n";
        });
    }

    return $self->{_logger};
}

sub go {
    my ($self, $argv, $config) = @_;

    if (defined $argv->[0] && exists $self->commands->{$argv->[0]}) {
        my $cmd = $self->commands->{$argv->[0]};
        $self->logger->debug("Found subcommand " . $cmd->name);
        shift @$argv;
        $cmd->go($argv, $config);
    }
    else {
        $self->logger->debug('No additional command found, time to exec');
        $self->process_options($config);
        return $self;
    }
}

sub process_options {
    my ($self, $config) = @_;

    my %options_spec = ();

    for my $option (@{$self->options}) {
        $options_spec{$option->for_get_options} = sub {
            my ($name, $value) = @_;
            $config->{$self->map->{$option}} = $value;
        };
    }

    %options_spec = $self->add_default_options(%options_spec);

    Getopt::Long::Configure('pass_through');
    GetOptions(%options_spec);
}

sub add_default_options {
    my ($self, %options_spec) = @_;

    my $option;

    $option = $self->option('show_help', '-h', '--help', 'Show this message');
    $options_spec{$option->for_get_options} = sub {
        print $self->as_string . "\n";
        exit(0);
    };

    $option = $self->option('show_version', '-v', '--version',
        'Print the name and version');
    $options_spec{$option->for_get_options} = sub {
        print(($self->name || '') . " " . ($self->version || '') . "\n");
        exit(0);
    };

    return %options_spec;
}

sub execute {
    my ($self, $argv, $config) = @_;

    $argv //= [];
    $config //= {};

    if (!@{$self->actions} && defined $self->default_command) {
        $self->default_command->execute;
    }
    else {
        for my $action (@{$self->actions}) {
            &$action($argv, $config);
        }
    }
}

sub identity {
    my ($self) = @_;

    return $self->full_name .
        (defined $self->version ? ' ' . $self->version : '');
}

sub full_name {
    my ($self) = @_;

    return
        ($self->parent && $self->parent->full_name ?
            $self->parent->full_name . ' ' : '') .
        $self->name;
}

sub names_and_aliases {
    my ($self) = @_;

    return join ', ', $self->name, @{$self->aliases};
}

sub summarize {
    my ($self) = @_;

    return sprintf "  %-20s  %s", $self->names_and_aliases,
        ($self->description || '');
}

sub as_string {
    my ($self) = @_;

    return App::Commando::Presenter->new($self)->command_presentation;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Commando::Command

=head1 VERSION

version 0.012

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
