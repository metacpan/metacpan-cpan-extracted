package Catalyst::Engine::Zeus::Base;

use strict;
use base qw[Catalyst::Engine];

use Zeus::ModPerl            ();
use Zeus::ModPerl::Constants ();
use Zeus::ModPerl::File      ();

Zeus::ModPerl::Constants->import(':common');

use URI;
use URI::http;

__PACKAGE__->mk_accessors(qw/zeus/);

=head1 NAME

Catalyst::Engine::Zeus::Base - Base class for Zeus Engine

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

This class overloads some methods from C<Catalyst::Engine>.

=head1 METHODS

=over 4

=item $c->zeus

Returns an C<Zeus::ModPerl> object.

=back

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine>.

=over 4

=item $c->finalize_body

=cut

sub finalize_body {
    my $c = shift;
    $c->zeus->print( $c->response->body );
}

=item $c->finalize_headers

=cut

sub finalize_headers {
    my $c = shift;

    for my $name ( $c->response->headers->header_field_names ) {
        next if $name =~ /^Content-(Length|Type)$/i;
        my @values = $c->response->header($name);
        $c->zeus->headers_out->add( $name => $_ ) for @values;
    }

    if ( $c->response->header('Set-Cookie') && $c->response->status >= 300 ) {
        my @values = $c->response->header('Set-Cookie');
        $c->zeus->err_headers_out->add( 'Set-Cookie' => $_ ) for @values;
    }

    $c->zeus->status( $c->response->status );

    if ( my $type = $c->response->header('Content-Type') ) {
        $c->zeus->content_type($type);
    }

    if ( my $length = $c->response->content_length ) {
        $c->zeus->set_content_length($length);
    }

    $c->zeus->send_http_header;

    return 0;
}

=item $c->handler

=cut

sub handler ($$) {
    shift->SUPER::handler(@_);
}

=item $c->prepare_body

=cut

sub prepare_body {
    my $c = shift;
    
    my $body = undef;
    
    while ( read( STDIN, my $buffer, 8192 ) ) {
        $body .= $buffer;
    }
    
    $c->request->body($body);
}

=item $c->prepare_connection

=cut

sub prepare_connection {
    my $c = shift;
    $c->request->address( $c->zeus->connection->remote_ip );
    $c->request->hostname( $c->zeus->connection->remote_host );
    $c->request->protocol( $c->zeus->protocol );
    $c->request->user( $c->zeus->user );
    
    if ( $ENV{HTTPS} || $c->zeus->get_server_port == 443 ) {
        $c->request->secure(1);
    }
}

=item $c->prepare_headers

=cut

sub prepare_headers {
    my $c = shift;
    $c->request->method( $c->zeus->method );
    $c->request->header( %{ $c->zeus->headers_in } );
}

=item $c->prepare_path

=cut

sub prepare_path {
    my $c = shift;
    
    my $base;
    {
        my $scheme = $c->request->secure ? 'https' : 'http';
        my $host   = $c->zeus->hostname;
        my $port   = $c->zeus->get_server_port;
        my $path   = $c->zeus->location || '/';
        
        unless ( $path =~ /\/$/ ) {
            $path .= '/';
        }

        $base = URI->new;
        $base->scheme($scheme);
        $base->host($host);
        $base->port($port);
        $base->path($path);

        $base = $base->canonical->as_string;
    }
    
    my $location = $c->zeus->location || '/';
    my $path = $c->zeus->uri || '/';
    $path =~ s/^($location)?\///;
    $path =~ s/^\///;

    $c->req->base($base);
    $c->req->path($path);
}

=item $c->prepare_request($r)

=cut

sub prepare_request {
    my ( $c, $r ) = @_;
    $c->zeus($r);
}

=item $c->run

=cut

sub run { }

=back

=head1 SEE ALSO

L<Catalyst> L<Catalyst::Engine>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
