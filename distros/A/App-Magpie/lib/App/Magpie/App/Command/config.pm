#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::config;
# ABSTRACT: update a spec file to match some policies
$App::Magpie::App::Command::config::VERSION = '2.010';
use App::Magpie::App -command;

use App::Magpie::Config;


# -- public methods

sub description {
"Store some configuration items, to avoid repeating them over and over
as command-line options."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ "dump|D", "dump whole configuration" ],
        [],
        [ "Available configuration items" ],
        [ "log-level|l=i", "default logging level", ]
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $config = App::Magpie::Config->instance;

    if ( $opts->{dump} ) {
        say $config->dump;
        exit;
    }

    if ( exists $opts->{log_level} ) {
        $config->set( "log", "level", $opts->{log_level} );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command::config - update a spec file to match some policies

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    # to always be verbose
    $ magpie config -l 2

    # to get list of available options
    $ magpie help config

=head1 DESCRIPTION

This command allows to store some general configuration items to change
the behaviour of magpie, instead of having to repeat them over & over
again as command-line arguments. Classical example: log level.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
