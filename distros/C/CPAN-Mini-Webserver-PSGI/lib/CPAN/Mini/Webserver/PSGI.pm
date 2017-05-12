package CPAN::Mini::Webserver::PSGI;
BEGIN {
  $CPAN::Mini::Webserver::PSGI::VERSION = '0.01';
}

use Moose;

use CGI;
use CGI::Emulate::PSGI;

extends 'CPAN::Mini::Webserver';

sub to_app {
    my ( $self ) = @_;

    $self = $self->new unless ref($self);

    $self->after_setup_listener;

    return CGI::Emulate::PSGI->handler(sub {
        CGI::initialize_globals();
        my $cgi = CGI->new;
        return $self->handle_request($cgi);
    });
}

around send_http_header => sub {
    my ( $orig, $self, $code, %params ) = @_;

    $params{'-status'} = $code;
    return $self->$orig($code, %params);
};

1;



=pod

=head1 NAME

CPAN::Mini::Webserver::PSGI - Use CPAN::Mini::Webserver as a PSGI application

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  # in your app.psgi file
  use strict;
  use warnings;
  use CPAN::Mini::Webserver::PSGI;

  CPAN::Mini::Webserver::PSGI->new->to_app;
  # or CPAN::Mini::Webserver::PSGI->to_app as a shortcut

=head1 DESCRIPTION

CPAN::Mini::Webserver::PSGI is a simple extension of L<CPAN::Mini::Webserver>
that allows you to use L<CPAN::Mini::Webserver>'s functionality in a L<PSGI>
application.

CPAN::Mini::PSGIApp might be a better name for this module, but I wanted to
reflect its relationship to L<CPAN::Mini::Webserver>.

=head1 METHODS

This is a subclass of <CPAN::Mini::Webserver>, so it inherits all of its
methods.

=head2 to_app

Returns the L<PSGI> application for this CPAN::Mini::Webserver::PSGI instance.

=head1 SEE ALSO

L<CPAN::Mini::Webserver>, L<PSGI>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

# ABSTRACT: Use CPAN::Mini::Webserver as a PSGI application

