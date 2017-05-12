package App::Docker::Client;

=head1 NAME

App::Docker::Client - Simple and plain Docker client!

=head1 VERSION

Version 0.010300

=cut

our $VERSION = '0.010300';

use 5.16.0;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Socket 'tcp_connect';
use AnyEvent::HTTP;
use LWP::UserAgent;
use JSON;
use LWP::Protocol::http::SocketUnixAlt;

=head2 new

Constructor

=cut

sub new {
    my $class = shift;
    my $self  = {@_};
    $self->{_scheme_postfixes} = { file => ':', http => '://', https => '://', };
    $self->{_valid_codes}      = { 200  => 1,   201  => 1,     204   => 1 };
    bless $self, $class;
    return $self;
}

=head1 SUBROUTINES/METHODS

=head2 with_valid_code

=cut

sub with_valid_code {
    my ( $self, $code ) = @_;
    return if $code !~ m/^(\d{3})$/;
    $self->{_valid_codes}->{$code} = 1;
    return $self;
}

=head2 without_valid_code

=cut

sub without_valid_code {
    my ( $self, $code ) = @_;
    return if $code !~ m/^(\d{3})$/;
    $self->{_valid_codes}->{$code} = 0;
    return $self;
}

=head2 show_progress

=cut

sub show_progress {
    my ( $self, $show_progress ) = @_;
    $self->{show_progress} = $show_progress ? $show_progress == 0 ? () : 1 : 1;
    return $self;
}

=head2 attach

=cut

sub attach {
    my ( $self, $path, $query, $input, $output ) = @_;
    my $cv       = AnyEvent->condvar;
    my $callback = sub {
        my ( $fh, $headers ) = @_;

        $fh->on_error( sub { $cv->send } );
        $fh->on_eof( sub   { $cv->send } );

        my $out_hndl = AnyEvent::Handle->new( fh => $output );
        $fh->on_read(
            sub {
                my ($handle) = @_;
                $handle->unshift_read(
                    sub {
                        my ($h) = @_;
                        my $length = length $h->{rbuf};
                        $out_hndl->push_write( $h->{rbuf} );
                        substr $h->{rbuf}, 0, $length, '';
                    }
                );
            }
        );

        my $in_hndl = AnyEvent::Handle->new( fh => $input );
        $in_hndl->on_read(
            sub {
                my ($h) = @_;
                $h->push_read(
                    line => sub {
                        my ( $h2, $line, $eol ) = @_;
                        $fh->push_write( $line . $eol );
                    }
                );
            }
        );
        $in_hndl->on_eof( sub { $cv->send } );
    };

    http_request(
        POST => $self->uri( $path, %$query )->as_string,
        (
            want_body_handle => 1,
            (
                $self->ssl_opts
                ? (
                    tls_ctx => {
                        verify          => 1,
                        verify_peername => "https",
                        ca_file         => $self->{ssl_opts}->{SSL_ca_file},
                        cert_file       => $self->{ssl_opts}->{SSL_cert_file},
                        key_file        => $self->{ssl_opts}->{SSL_key_file},
                    }
                  )
                : ()
            ),
        ),
        $callback
    );
    return $cv;
}

=head2 authority

Getter/Setter for internal hash key authority.

=cut

sub authority {
    return $_[0]->{authority} || '/var/run/docker.sock' unless $_[1];
    $_[0]->{authority} = $_[1];
    return $_[0]->{authority};
}

=head2 scheme

Getter/Setter for internal hash key scheme.

=cut

sub scheme {
    return $_[0]->{scheme} || 'http' unless $_[1];
    $_[0]->{scheme} = $_[1];
    return $_[0]->{scheme};
}

=head2 ssl_opts

Getter/Setter for internal hash key ssl_opts.

=cut

sub ssl_opts {
    return $_[0]->{ssl_opts} unless $_[1];
    $_[0]->{ssl_opts} = $_[1];
    return $_[0]->{ssl_opts};
}

=head2 json

Getter/Setter for internal hash key json.

=cut

sub json {
    return $_[0]->{json} || JSON->new->utf8() unless $_[1];
    $_[0]->{json} = $_[1];
    return $_[0]->{json};
}

=head2 user_agent

Getter/Setter for internal hash key UserAgent.

=cut

sub user_agent {
    my ( $self, $user_agent ) = @_;
    if ($user_agent) {
        $self->{UserAgent} = $user_agent;
        return $self->{UserAgent};
    }
    return $self->{UserAgent} if $self->{UserAgent};

    if ( -S $self->authority() ) {
        LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocketUnixAlt' );
    }
    $self->{UserAgent} = LWP::UserAgent->new(
        (
            $self->{show_progress} ? ( show_progress => 1 ) : (),
            $self->ssl_opts ? ( ssl_opts => $self->ssl_opts ) : (),
        )
    );
    return $self->{UserAgent};

}

=head2 get

=cut

sub get {
    my ( $self, $path, $options, $callback ) = @_;
    return $self->_hande_response( $self->user_agent->get( $self->uri( $path, %$options ) ) );
}

=head2 delete

=cut

sub delete {
    my ( $self, $path, $options, $callback ) = @_;
    return $self->_hande_response( $self->user_agent->delete( $self->uri( $path, %$options ) ) );
}

=head2 request

=cut

sub request {
    my ( $self, $request, $callback ) = @_;
    return $self->_hande_response( $self->user_agent->request( $request, $callback ) );
}

=head2 post

=cut

sub post {
    my ( $self, $path, $query, $body, $options, $callback ) = @_;
    return $self->request( $self->_http_request( $path, $query ), $callback ) unless $body;
    return $self->request( $self->_handle_json( $path, $query, $body ), $callback )
      unless ($options);
    return $self->request( $self->_handle_custom( $path, $query, $body, $options ), $callback );
}

=head2 uri

Creating a new URI object.

Internal varibales:
    
 * scheme
    
 * authority

Given varibales:
 
 * path
 
 * query options

=cut

sub uri {
    my ( $self, $path, %opts ) = @_;
    require URI;
    my $uri =
      URI->new(
        $self->scheme() . $self->{_scheme_postfixes}->{ lc $self->scheme() } . $self->authority() . '/' . $path );
    $uri->query_form(%opts);
    return $uri;
}

=head2 to_hashref

Getter/Setter for internal hash key ua.

=cut

sub to_hashref {
    my ( $self, $content ) = @_;
    return if !$content;
    my $data = eval { $self->json->decode($content) };
    return $@ ? $content : $data;
    require Carp;
    Carp::cluck;
    Carp::croak "JSON ERROR: $@";
}

{

=head2 post

=cut

    sub _handle_json {
        my ( $self, $path, $query, $body ) = @_;
        my $req = $self->_http_request( $path, $query );
        $req->content_type('application/json');
        my $json = $self->json->encode($body);
        $json =~ s/"(false|true)"/$1/g;
        $req->content($json);
        return $req;
    }

=head2 post

=cut

    sub _handle_custom {
        my ( $self, $path, $query, $body, $options ) = @_;
        my $req = $self->_http_request( $path, $query );
        $req->content_type( $options->{content_type} );
        $req->content_length(
            do { use bytes; length $body }
        );
        $req->content($body);
        return $req;
    }

=head2 _http_request

create HTTP::Request by uri params

=cut

    sub _http_request {
        my ( $self, $path, $query ) = @_;
        require HTTP::Request;
        return HTTP::Request->new( POST => $self->uri( $path, %$query ) );
    }

=head2 _hande_response

=cut

    sub _hande_response {
        my ( $self, $response ) = @_;
        $self->_error_code( $response->code, $response->message, $response->content );
        my $content = $response->content();
        return $self->to_hashref($content);
    }

=head2 _error_code

Simple error handler returns undef if everything is ok dies on error.

=cut

    sub _error_code {
        my ( $self, $code, $message, $content ) = @_;
        return $code if $self->{_valid_codes}->{$code};
        require Carp;
        Carp::cluck;
        Carp::croak "FAILURE: $code - " . qq~$message\n$content~;
    }
}

1;    # End of App::Docker::Client

__END__

=head1 SYNOPSIS

Sample to inspect a conatainer, for mor posibilities see at the Docker API
documentation L<https://docs.docker.com/engine/api/v1.25/>

    use App::Docker::Client;

    my $client = App::Docker::Client->new();

    my $hash_ref = $client->get('/containers/<container_id>/json');

Create a new container:
    
    $client->post('/containers/create', {}, {
        Name      => 'container_name',
        Tty       => 1,
        OpenStdin => 1,
        Image     => 'perl',
    });

For a remote authority engine use it like that:

    use App::Docker::Client;
    
    my %hash = ( authority => '0.0.0.0:5435' );

    my $client = App::Docker::Client->new( %hash );

    my $hash_ref = $client->get('/containers/<container_id>/json');

To follow logs

    *STDOUT->autoflush(1);

    my $cv = $client->attach(
        '/containers/<container_id>/attach',
        { stream => 1, logs => 1, stdin => 1, stderr => 1, stdout => 1, tail => 50 },
        \*STDIN,
        \*STDOUT
    );
    $cv->recv;

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-docker-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Docker-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Docker::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Docker-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Docker-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Docker-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Docker-Client/>

=back

=head1 SEE ALSO
 
This package was partly inspired by L<Net::Docker> by Peter Stuifzand and
L<WWW::Docker> by Shane Utt but everyone has his own client and is 
near similar.


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
