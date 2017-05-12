package Dancer::Logger::PSGI;

use v5.10;
use strict;
use warnings;
use Dancer::SharedData;
use parent qw(Dancer::Logger::Abstract);

our $VERSION = 'v1.0.1'; # VERSION
# ABSTRACT: PSGI Log handler for Dancer

sub init { }

sub _log {
    my ($self, $level, $message) = @_;
    my $full_message = $self->format_message($level => $message);
    chomp $full_message;

    my $request = Dancer::SharedData->request;
    if ( $request->{env}{'psgix.logger'} ) {
        $request->{env}{'psgix.logger'}->(
            {   level   => $level,
                message => $full_message,
            }
        );
    }
    return;
}

1;
=encoding utf8

=head1 NAME

Dancer::Logger::PSGI - PSGI Log handler for Dancer

=head1 SYNOPSIS

In your Dancer's environment file:

    logger: PSGI
    - plack_middlewares:
      -
        - ConsoleLogger

In your application:

    warning 'this is a warning';

With L<Plack::Middleware::ConsoleLogger>, all your log will be send to the JavaScript console of your browser.

=head1 DESCRIPTION

This class is an interface between your Dancer's application and B<psgix.logger>. Message will be logged in whatever logger you decided to use in your L<Plack> handler. If no logger is defined, nothing will be logged.

=head1 AUTHOR

Franck Cuny

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Richard Simões <rsimoes AT cpan DOT com>.
It is released under the terms of the B<MIT (X11) License> and may be modified
and/or redistributed under the same or any compatible license.
