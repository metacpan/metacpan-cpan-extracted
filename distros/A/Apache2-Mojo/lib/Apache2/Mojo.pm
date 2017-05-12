package Apache2::Mojo;
our $VERSION = '0.004';


use strict;
use warnings;

use Apache2::Connection;
use Apache2::Const -compile => qw(OK);
use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::URI;
use APR::SockAddr;
use APR::Table;
use APR::URI;

use Mojo::Loader;


eval "use Apache2::ModSSL";
if ($@) {
    *_is_https = \&_is_https_fallback;
} else {
    *_is_https = \&_is_https_modssl;
}

my $_app = undef;


sub _app {
    if ($ENV{MOJO_RELOAD} and $_app) {
        Mojo::Loader->reload;
        $_app = undef;
    }
    $_app ||= Mojo::Loader->load_build($ENV{MOJO_APP} || 'Mojo::HelloWorld');
    return $_app;
}

sub handler {
    my $r = shift;

    # call _app() only once (because of MOJO_RELOAD)
    my $app = _app;
    my $tx  = $app->build_tx;

    # Transaction
    _transaction($r, $tx);

    # Request
    _request($r, $tx->req);

    # Handler
    $app->handler($tx);

    my $res = $tx->res;

    # Response
    _response($r, $res);

    return Apache2::Const::OK;
}

sub _transaction {
    my ($r, $tx) = @_;

    # local and remote address (needs Mojo 0.9002)
    if ($tx->can('remote_address')) {
        my $c = $r->connection;
        my $local_sa = $c->local_addr;
        $tx->local_address($local_sa->ip_get);
        $tx->local_port($local_sa->port);
        my $remote_sa = $c->remote_addr;
        $tx->remote_address($remote_sa->ip_get);
        $tx->remote_port($remote_sa->port);
    }
}

sub _request {
    my ($r, $req) = @_;

    my $url  = $req->url;
    my $base = $url->base;

    # headers
    my $headers = $r->headers_in;
    foreach my $key (keys %$headers) {
        $req->headers->header($key, $headers->get($key));
    }

    # path
    if ($r->location eq '/') {
        # bug in older mod_perl (e. g. 2.0.3 in Ubuntu Hardy LTS)
        $url->path->parse($r->uri);
    } else {
        $url->path->parse($r->path_info);
    }

    # query
    $url->query->parse($r->parsed_uri->query);

    # method
    $req->method($r->method);

    # base path
    $base->path->parse($r->location);

    # host/port
    my $host = $r->get_server_name;
    my $port = $r->get_server_port;
    $url->host($host);
    $url->port($port);
    $base->host($host);
    $base->port($port);

    # scheme
    my $scheme = _is_https($r) ? 'https' : 'http';
    $url->scheme($scheme);
    $base->scheme($scheme);

    # version
    if ($r->protocol =~ m|^HTTP/(\d+\.\d+)$|) {
        $req->version($1);
    } else {
        $req->version('0.9');
    }

    # body
    $req->state('content');
    $req->content->state('body');
    my $offset = 0;
    while (!$req->is_finished) {
        last unless (my $read = $r->read(my $buffer, 4096, $offset));
        $offset += $read;
        $req->parse($buffer);
    }
}

sub _response {
    my ($r, $res) = @_;

    # status
    $r->status($res->code);

    # headers
    $res->fix_headers;
    my $headers = $res->headers;
    foreach my $key (@{$headers->names}) {
        my @value = $headers->header($key);
        next unless @value;

        # special treatment for content-type
        if ($key eq 'Content-Type') {
            $r->content_type($value[0]);
        } else {
            $r->headers_out->set($key => shift @value);
            $r->headers_out->add($key => $_) foreach (@value);
        }
    }

    # body
    my $offset = 0;
    while (1) {
        my $chunk = $res->get_body_chunk($offset);

        # No content yet, try again
        unless (defined $chunk) {
            sleep 1;
            next;
        }

        # End of content
        last unless length $chunk;

        # Content
        my $written = $r->print($chunk);
        $offset += $written;
    }
}

sub _is_https_modssl {
    my ($r) = @_;

    return $r->connection->is_https;
}

sub _is_https_fallback {
    my ($r) = @_;

    return $r->get_server_port == 443;
}


1;

__END__

=pod

=head1 NAME

Apache2::Mojo - mod_perl2 handler for Mojo

=head1 VERSION

version 0.004

=head1 SYNOPSIS

in httpd.conf:

  <Perl>
    use lib '...';
    use Apache2::Mojo;
    use TestApp;
  </Perl>

  <Location />
     SetHandler  perl-script
     PerlSetEnv  MOJO_APP TestApp
     PerlHandler Apache2::Mojo
  </Location>

=head1 DESCRIPTION

This is a mod_perl2 handler for L<Mojo>/L<Mojolicious>.

Set the application class with the environment variable C<MOJO_APP>.

C<MOJO_RELOAD> is also supported (e. g. C<PerlSetEnv MOJO_RELOAD 1>).

=head1 SEE ALSO

L<Apache2>, L<Mojo>, L<Mojolicious>.

=head1 AUTHOR

Uwe Voelker, <uwe.voelker@gmx.de>

=cut