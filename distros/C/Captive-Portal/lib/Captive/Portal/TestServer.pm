package Captive::Portal::TestServer;

use strict;
use warnings;

=head1 NAME

Captive::Portal::TestServer - simple HTTP Server for Captive::Portal tests

=cut

our $VERSION = '4.10';

use parent 'HTTP::Server::Simple::CGI';
use HTTP::Server::Simple::Static qw(serve_static);
use CGI qw();

sub new {
    my ($class, $ssl) = @_;

    my $self = $class->SUPER::new();

    # build accept_hook on demand for SSL request
    # see perldoc HTTP::Server::Simple and below for the hook definition
    if ($ssl) {
        require IO::Socket::SSL;
	#IO::Socket::SSL->import('debug3');

        {
            no strict 'refs';
            *{ __PACKAGE__ . '::accept_hook' } = \&_ssl_accept_hook;
        }
    }

    return $self;
}

=head1 METHODS

=over

=item handle_request

Simple wrapper to mix static and dynamic requests in one handler.

=cut

sub handle_request {
    my $self = shift;
    my $cgi = shift or die 'param CGI missing, stopped';

    $cgi->nph(1);

    # no setters/getters for this simple wrapper defined
    my $capo = $self->{capo} or die 'capo undefined, stopped';
    my $static_root = $self->{static_root}
      or die 'static_root undefined, stopped';

    # handle static if found
    return if $self->serve_static( $cgi, $static_root );

    # no static file found, handle via CaPo
    return $capo->run($cgi);
}

# to noisy
sub print_banner { }

# private methods

sub _ssl_accept_hook {

    my $self = shift;
    my $fh   = $self->stdio_handle;

    $self->SUPER::accept_hook(@_);

    my $newfh = IO::Socket::SSL->start_SSL(
        $fh,
        SSL_server    => 1,
        SSL_cert_file => './etc/test-cert.pem',
        SSL_key_file  => './etc/test-priv-key.pem',
      )
      or die "problem setting up SSL socket: "
      . IO::Socket::SSL::errstr();

    if ($newfh) {
	# help HTTP::Server::Simple::CGI with ENV setup()
	$ENV{HTTPS} = 'on';

	# switch to ssl-ified fh
	$self->stdio_handle($newfh);
    }
}

1;

=back

=head1 AUTHOR

Karl Gaissmaier, C<< <gaissmai at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Karl Gaissmaier, all rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

=cut

# vim: sw=4
