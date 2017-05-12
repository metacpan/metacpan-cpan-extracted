package App::Commando::Program;

use strict;
use warnings;

use Carp;
use Getopt::Long qw( GetOptionsFromArray );
use Moo;

extends 'App::Commando::Command';

has 'config' => ( is => 'ro' );

around BUILDARGS => sub {
    my ($orig, $self, $name) = @_;

    return {
        config => {},
        %{$self->$orig($name)}
    };
};

around go => sub {
    my ($orig, $self, $argv) = @_;

    if (!defined $argv) {
        $argv = \@ARGV;
    }

    my $cmd = $self->$orig($argv, $self->config);

    # Run through all options again in case there are any unknown ones
    Getopt::Long::Configure('no_pass_through');
    {
        # Treat Getopt::Long warnings as fatal errors
        local $SIG{__WARN__} = sub {
            croak @_;
        };
        GetOptionsFromArray($argv,
            { map { $_->for_get_options => undef } @{$self->options} });
    }

    $cmd->execute($argv, $self->config);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Commando::Program

=head1 VERSION

version 0.012

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
