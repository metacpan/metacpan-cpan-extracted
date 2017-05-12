package Apache::Mojo;
our $VERSION = '0.003';


use strict;
use warnings;

use Apache::Constants qw(OK);
use Apache::URI;

use Mojo::Loader;


my $_app = undef;

sub _app {
    if($ENV{MOJO_RELOAD} and $_app) {
        Mojo::Loader->reload;
        $_app = undef;
    }
    $_app ||= Mojo::Loader->load_build($ENV{MOJO_APP} || 'Mojo::HelloWorld');
    return $_app;
}

sub handler {
    my $r = shift;

    chdir($ENV{MOJO_PATH}) if $ENV{MOJO_PATH};

    my $app = _app;
    my $tx  = $app->build_tx;
    my $req = $tx->req;

    # Request
    _request($r, $req);

    # Handler
    $app->handler($tx);

    my $res = $tx->res;

    # Response
    _response($r, $res);

    return OK;
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
    $url->path->parse($r->path_info);

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
    $url->scheme($r->parsed_uri->scheme);
    $base->scheme($r->parsed_uri->scheme);

    # version
    if ($r->protocol =~ m|^HTTP/(\d+\.\d+)$|) {
        $req->version($1);
    } else {
        $req->version('0.9');
    }

    # body
    $req->state('content');
    $req->content->state('body');

    # handle application/x-www-form-encoded content
    my $post_params = $r->content;
    $req->parse($post_params) if $post_params;

    # handle any body content that isn't application/x-www-form-encoded
    my $offset = 0;
    while (!$req->is_state(qw/done error/)) {
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
    my $headers = $res->headers;
    foreach my $key (@{$headers->names}) {
        my @value = $headers->header($key);
        next unless @value;
        $r->headers_out->set($key => shift @value);
        $r->headers_out->add($key => $_) foreach (@value);
    }

    # content-type gets ignored in headers_out()
    $r->content_type($headers->header('Content-Type'));

    # Response body
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
        my $written = STDOUT->syswrite($chunk);
        $offset += $written;
    }
}


1;

__END__

=pod

=head1 NAME

Apache::Mojo - mod_perl handler for Mojo

=head1 VERSION

version 0.003

=head1 SYNOPSIS

in httpd.conf:

  <Perl>
    use lib '...';
    use Apache::Mojo;
    use TestApp;
  </Perl>

  <Location />
     SetHandler  perl-script
     PerlSetEnv  MOJO_APP TestApp
     PerlSetEnv  MOJO_PATH /path/to/testapp/
     PerlHandler Apache::Mojo
  </Location>

=head1 DESCRIPTION

This is a mod_perl handler for L<Mojo>/L<Mojolicious> and Apache.  For
mod_perl2, use L<Apache2::Mojo>.

Set the application class with the environment variable C<MOJO_APP>.

If you use relative filesystem paths for templates, etc., set the environment
variable C<MOJO_PATH> to your base application path.

C<MOJO_RELOAD> is also supported (e. g. C<PerlSetEnv MOJO_RELOAD 1>).

=head1 SEE ALSO

L<Apache>, L<Mojo>, L<Mojolicious>.

=head1 AUTHOR

Apache2::Mojo by Uwe Voelker, <uwe.voelker@gmx.de>

Ported to mod_perl 1 by Dave Sherohman, <dave@sherohman.org>

=cut
