package App::Commando::Presenter;

use strict;
use warnings;

use Moo;
use Scalar::Util qw(refaddr);

has 'command' => ( is => 'rw' );

sub BUILDARGS {
    my ($class, $command) = @_;

    return {
        command => $command,
    };
}

sub usage_presentation {
    my ($self) = @_;

    return '  ' . $self->command->syntax;
}

sub options_presentation {
    my ($self) = @_;

    return if !@{$self->command->options};

    return join "\n", map { $_->as_string } @{$self->command->options};
}

sub subcommands_presentation {
    my ($self) = @_;

    return if !%{$self->command->commands};

    return join "\n", map { $_->summarize }
        # Remove duplicate commands
        values %{{
            map { refaddr($_) => $_ } values %{$self->command->commands}
        }};
}

sub command_header {
    my ($self) = @_;

    my $header = $self->command->identity;
    $header .= " -- " . $self->command->description
        if $self->command->description;

    return $header;
}

sub command_presentation {
    my ($self) = @_;

    my @msg = ();

    push @msg,
        $self->command_header,
        'Usage:',
        $self->usage_presentation;

    if (my $options = $self->options_presentation) {
        push @msg, "Options:\n" . $options;
    }

    if (my $subcommands = $self->subcommands_presentation) {
        push @msg, "Subcommands:\n" . $subcommands;
    }

    return join "\n\n", @msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Commando::Presenter

=head1 VERSION

version 0.012

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
