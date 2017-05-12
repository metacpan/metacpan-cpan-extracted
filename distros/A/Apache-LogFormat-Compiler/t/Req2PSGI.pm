package t::Req2PSGI;

use strict;
use warnings;
use URI::Escape ();
use Try::Tiny;

my $TRUE  = (1 == 1);
my $FALSE = !$TRUE;

## copy from HTTP::Message::PSGI
## for remove Plack dependency fro ALFC
sub req_to_psgi {
    my $req = shift;

    unless (try { $req->isa('HTTP::Request') }) {
        Carp::croak("Request is not HTTP::Request: $req");
    }

    # from HTTP::Request::AsCGI
    my $host = $req->header('Host');
    my $uri  = $req->uri->clone;
    $uri->scheme('http')    unless $uri->scheme;
    $uri->host('localhost') unless $uri->host;
    $uri->port(80)          unless $uri->port;
    $uri->host_port($host)  unless !$host || ( $host eq $uri->host_port );

    my $input;
    my $content = $req->content;
    open $input, "<", \$content;
    $req->content_length(length $content)
        unless defined $req->content_length;

    my $env = {
        PATH_INFO         => URI::Escape::uri_unescape($uri->path || '/'),
        QUERY_STRING      => $uri->query || '',
        SCRIPT_NAME       => '',
        SERVER_NAME       => $uri->host,
        SERVER_PORT       => $uri->port,
        SERVER_PROTOCOL   => $req->protocol || 'HTTP/1.1',
        REMOTE_ADDR       => '127.0.0.1',
        REMOTE_HOST       => 'localhost',
        REMOTE_PORT       => int( rand(64000) + 1000 ),                   # not in RFC 3875
        REQUEST_URI       => $uri->path_query || '/',                     # not in RFC 3875
        REQUEST_METHOD    => $req->method,
        'psgi.version'      => [ 1, 1 ],
        'psgi.url_scheme'   => $uri->scheme eq 'https' ? 'https' : 'http',
        'psgi.input'        => $input,
        'psgi.errors'       => *STDERR,
        'psgi.multithread'  => $FALSE,
        'psgi.multiprocess' => $FALSE,
        'psgi.run_once'     => $TRUE,
        'psgi.streaming'    => $TRUE,
        'psgi.nonblocking'  => $FALSE,
        @_,
    };

    for my $field ( $req->headers->header_field_names ) {
        my $key = uc("HTTP_$field");
        $key =~ tr/-/_/;
        $key =~ s/^HTTP_// if $field =~ /^Content-(Length|Type)$/;

        unless ( exists $env->{$key} ) {
            $env->{$key} = $req->headers->header($field);
        }
    }

    if ($env->{SCRIPT_NAME}) {
        $env->{PATH_INFO} =~ s/^\Q$env->{SCRIPT_NAME}\E/\//;
        $env->{PATH_INFO} =~ s/^\/+/\//;
    }

    if (!defined($env->{HTTP_HOST}) && $req->uri->can('host')) {
        $env->{HTTP_HOST} = $req->uri->host;
        $env->{HTTP_HOST} .= ':' . $req->uri->port
            if $req->uri->port ne $req->uri->default_port;
    }

    return $env;
}

1;

