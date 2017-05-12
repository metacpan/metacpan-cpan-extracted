package ArangoDB::Connection;
use strict;
use warnings;
use utf8;
use 5.008001;
use JSON ();
use Furl::HTTP;
use MIME::Base64;
use ArangoDB::ConnectOptions;
use ArangoDB::ServerException;
use Class::Accessor::Lite ( ro => [qw/options/] );

my $JSON = JSON->new->utf8;

sub new {
    my ( $class, $options ) = @_;
    my $opts = ArangoDB::ConnectOptions->new($options);
    my $headers = [ Host => $opts->host, Connection => $opts->keep_alive ? 'Keep-Alive' : 'Close', ];
    if ( $opts->auth_type && $opts->auth_user ) {
        push @$headers, Authorization =>
            sprintf( '%s %s', $opts->auth_type, encode_base64( $opts->auth_user . ':' . $opts->auth_passwd ) );
    }
    my %furl_args = (
        timeout => $opts->timeout,
        headers => $headers,
        proxy   => $opts->proxy,
    );
    if( $opts->inet_aton ){
        $furl_args{inet_aton} = $opts->inet_aton;
    }
    my $furl = Furl::HTTP->new(%furl_args);

    my $self = bless {
        options   => $opts,
        _req_args => {
            scheme => 'http',
            host   => $opts->host,
            port   => $opts->port,
        },
        _http_agent => $furl,
    }, $class;

    return $self;
}

sub http_get {
    my ( $self, $path, $additional_headers ) = @_;
    my $headers = $self->_build_headers(undef, $additional_headers );
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'GET',
        path_query => $path,
        headers    => $headers,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub http_post {
    my ( $self, $path, $data, $raw, $additional_headers ) = @_;
    if( !$raw ){
        $data = $JSON->encode( defined $data ? $data : {} );
    }
    my $headers = $self->_build_headers($data, $additional_headers);
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'POST',
        path_query => $path,
        headers    => $headers,
        content    => $data,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub http_put {
    my ( $self, $path, $data, $raw, $additional_headers ) = @_;
    if( !$raw ){
        $data = $JSON->encode( defined $data ? $data : {} );
    }
    my $headers = $self->_build_headers($data, $additional_headers);
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'PUT',
        path_query => $path,
        headers    => $headers,
        content    => $data,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub http_delete {
    my ( $self, $path, $additional_headers ) = @_;
    my $headers = $self->_build_headers(undef, $additional_headers);
    my ( undef, $code, $msg, undef, $body ) = $self->{_http_agent}->request(
        %{ $self->{_req_args} },
        method     => 'DELETE',
        path_query => $path,
        headers    => $headers,
    );
    return $self->_parse_response( $code, $msg, $body );
}

sub _build_headers {
    my ( $self, $body, $additional_headers ) = @_;
    my $content_length = length( $body || q{} );
    my @headers = ();
    if ( $content_length > 0 ) {
        push @headers, 'Content-Type' => 'application/json';
    }
    if( $additional_headers ){
        push @headers, @{ $additional_headers };
    }
    return \@headers;
}

sub _parse_response {
    my ( $self, $code, $status, $body ) = @_;
    if ( $code < 200 || $code >= 400 ) {
        if ( $body ne q{} ) {
            my $details = $JSON->decode($body);
            my $exception = ArangoDB::ServerException->new( code => $code, status => $status, detail => $details );
            die $exception;
        }
        die ArangoDB::ServerException->new( code => $code, status => $status, detail => {} );
    }
    my $data = $JSON->decode($body);
    return $data;
}

1;
__END__
