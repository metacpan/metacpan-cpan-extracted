package Async::Microservice;

use strict;
use warnings;
use 5.010;
use utf8;

our $VERSION = '0.08';

use Moose::Role;
requires qw(get_routes service_name);

use Plack::Request;
use Try::Tiny;
use Path::Class qw(dir file);
use MooseX::Types::Path::Class;
use Path::Router;
use Async::MicroserviceReq;
use Log::Any qw($log);
use Future::AsyncAwait;

has 'api_version' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);
has 'jsonp' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);
has 'static_dir' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
    default  => sub {
        my $static_dir = $ENV{STATIC_DIR};
        die 'static dir "'
            . $static_dir
            . '" not found (check $ENV{STATIC_DIR})'
            if !$static_dir || !-d $static_dir;
        return $static_dir;
    },
    lazy => 1,
);
has 'static_path' => ( is => 'ro', isa => 'Str', default => 'static' );
has 'using_frontend_proxy' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'router' => (
    is      => 'ro',
    isa     => 'Path::Router',
    lazy    => 1,
    builder => '_build_router'
);
has 'start_time'  => ( is => 'ro', default => sub { time() } );
has 'req_count'   => ( is => 'rw', default => 0 );
has 'pending_req' => ( is => 'rw', default => 0 );

has 'request_timeout' => ( is => 'ro', isa => 'Num', default => 300 );
has 'max_concurrent_requests' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1000,
);

has 'file_placeholder' => ( is => 'ro', default => 'ASYNC-SERVICE-NAME' );

sub _build_router {
    my ($self) = @_;

    my $get_static_path = $self->static_path . '/:filename';
    my $router          = Path::Router->new;
    my @default_routes  = (
        ''               => { defaults => { GET => 'GET_root_index', }, },
        $get_static_path => { defaults => { GET => 'GET_static', }, },
        'edit'           => { defaults => { GET => 'GET_root_edit', }, },
        'hcheck'         => { defaults => { GET => 'GET_hcheck', }, },
    );
    my @routes = ( $self->get_routes() );
    while (@routes) {
        my ( $path, $opts ) = splice( @routes, 0, 2 );
        $router->add_route( $path, %$opts );
    }

    # skip default routes if they are already defined in get_routes
    while (@default_routes) {
        my ( $path, $opts ) = splice( @default_routes, 0, 2 );
        next if $router->match($path);
        $router->add_route( $path, %$opts );
    }

    return $router;
}

sub plack_handler {
    my ( $self, $env ) = @_;

    $self->req_count( $self->req_count + 1 );

    my $plack_req = Plack::Request->new($env);
    my $this_req  = Async::MicroserviceReq->new(
        method               => $plack_req->method,
        headers              => $plack_req->headers,
        content              => $plack_req->content,
        path                 => $plack_req->path_info,
        params               => $plack_req->parameters,
        static_dir           => $self->static_dir,
        jsonp                => $self->jsonp,
        using_frontend_proxy => $self->using_frontend_proxy,
        pending_ref          => \$self->{pending_req},
        request_timeout      => $self->request_timeout,
    );

    # set process name and last requested path for debug/troubleshooting
    $0 = sprintf( "%s %s (pending_req: %d)",
        $self->service_name, $this_req->path, $self->pending_req );

    my $plack_handler_sub = sub {
        my ($plack_respond) = @_;
        $this_req->plack_respond($plack_respond);

        # limit number of pending requests
        if ( $self->pending_req > $self->max_concurrent_requests ) {
            $log->errorf(
                'too many concurrent requests (%d), rejecting request for %s',
                $self->pending_req, $this_req->path
            );
            return $this_req->respond( 429, [], 'too many requests' );
        }

        # API version
        my ( $version, $sub_path_info );
        if ( $this_req->path =~ qr{^/v(\d+?)(/.*)$} ) {
            $version       = $1;
            $sub_path_info = $2;
        }

        # without version path redirect to the latest version
        return $this_req->redirect( '/v' . $self->api_version . '/' )
            unless $version;

        if ( my $match = $self->router->match($sub_path_info) ) {
            my $func = $match->{mapping}->{ $this_req->method };
            if ( $func && ( my $misc_fn = $self->can($func) ) ) {
                %{ $this_req->params } =
                    ( %{ $this_req->params }, %{ $match->{mapping} } );
                my $resp = $misc_fn->( $self, $this_req, $match );
                if ( blessed($resp) && $resp->isa('Future') ) {
                    $resp->retain;
                    $resp->on_done(
                        sub {
                            my ($resp_data) = @_;
                            if ( ref($resp_data) eq 'ARRAY' ) {
                                $this_req->respond(@$resp_data);
                            }
                            else {
                                $this_req->respond( 200, [], $resp_data );
                            }
                        }
                    );
                    $resp->on_fail(
                        sub {
                            my ($err_msg) = @_;
                            $err_msg ||= 'unknown';
                            $log->errorf( 'exception while calling "%s": %s',
                                $plack_req->path_info, $err_msg );
                            $this_req->respond( 503, [],
                                      'internal server error calling '
                                    . $func . ': '
                                    . $err_msg );
                        }
                    );
                    $resp->on_cancel(
                        sub {
                            $this_req->respond( 429, [],
                                'request for ' . $func . ' canceled' );
                        }
                    );
                    return $resp;
                }
                elsif ( ref($resp) eq 'ARRAY' ) {
                    $this_req->respond(@$resp);
                }
                return;
            }
            else {
                # Route exists but method not supported
                my @allowed = grep { defined $match->{mapping}->{$_} }
                    keys %{ $match->{mapping} };
                return $this_req->respond(
                    405,
                    [ "Allow" => join( ", ", sort @allowed ) ],
                    'method not allowed'
                );
            }
        }
        return $this_req->respond( 404, [],
            'path ' . $sub_path_info . ' not found' );
    };

    return sub {
        my $respond  = shift;
        my $response = try {
            $plack_handler_sub->($respond);
        }
        catch {
            $this_req->respond( 503, [], 'internal server error: ' . $_ );
        };
        if ( blessed($response) && $response->isa('Future') ) {
            $response->on_done( sub { $this_req->clear_plack_respond } );
        }
        else {
            $this_req->clear_plack_respond;
        }
        return $response;
    };
}

sub _update_openapi_html {
    my ( $self, $content ) = @_;
    my $service_name             = $self->service_name;
    my $service_name_placeholder = $self->file_placeholder;
    $content =~ s/$service_name_placeholder/$service_name/g;
    return $content;
}

sub GET_root_index {
    my ( $self, $this_req ) = @_;
    return $this_req->static_ft( 'index.html',
        sub { $self->_update_openapi_html(@_) } );
}

sub GET_static {
    my ( $self, $this_req ) = @_;
    my $filename = $this_req->params->{filename};
    return $this_req->static_ft($filename);
}

sub GET_root_edit {
    my ( $self, $this_req ) = @_;
    return $this_req->static_ft( 'edit.html',
        sub { $self->_update_openapi_html(@_) } );
}

sub GET_hcheck {
    my ( $self, $this_req ) = @_;
    return $this_req->text_plain(
        'Service-Name: ' . $self->service_name,
        "API-Version: " . $self->api_version,
        'Uptime: ' . ( time() - $self->start_time ),
        'Request-Count: ' . $self->req_count,
        'Pending-Requests: ' . $self->pending_req,
    );
}

no Moose::Role;

1;

__END__

=head1 NAME

Async::Microservice - Async HTTP Microservice Moose Role

=head1 SYNOPSIS

    # lib/Async/Microservice/HelloWorld.pm
    package Async::Microservice::HelloWorld;
    use Moose;
    with qw(Async::Microservice);
    sub service_name {return 'asmi-helloworld';}
    sub get_routes {return ('hello' => {defaults => {GET => 'GET_hello'}});}
    sub GET_hello {
        my ( $self, $this_req ) = @_;
        return [ 200, [], 'Hello world!' ];
    }
    1;

    # bin/async-microservice-helloworld.psgi
    use Async::Microservice::HelloWorld;
    my $mise = Async::Microservice::HelloWorld->new();
    return sub { $mise->plack_handler(@_) };

    $ plackup -Ilib --port 8089 --server Twiggy bin/async-microservice-helloworld.psgi

    $ curl http://localhost:8089/v1/hello
    Hello world!

=head1 DESCRIPTION

This L<Moose::Role> helps quickly bootstrap an async HTTP service that
includes OpenAPI documentation.

See L<https://time.meon.eu/> and the code in L<Async::Microservice::Time>.

=head1 ATTRIBUTES

=head2 static_path

URL path prefix for OpenAPI files. Defaults to C<'static'>. Can be overridden
by passing it to the constructor.

=head2 file_placeholder

Placeholder string used in OpenAPI files (like C<index.html> and C<edit.html>)
that gets replaced with the service name. Defaults to C<'ASYNC-SERVICE-NAME'>.
Useful for templates that need to display the service name dynamically.

=head2 Overriding Predefined Paths

The following paths are provided by default:

=over 4

=item * C</> - Root index (OpenAPI documentation)

=item * C</static/:filename> - OpenAPI files

=item * C</edit> - OpenAPI editor

=item * C</hcheck> - Health check endpoint

=back

You can override any of these default routes by defining them in your
C<get_routes()> method. Your custom routes take precedence over the defaults.

=head2 To bootstrap a new async service

Create a new package for your APIs using the current examples in
C<lib/Async/Microservice/*>. Set the return value of C<service_name>.
This string is used to set the process name and to locate the OpenAPI YAML
definition for the documentation. Any GET/POST processing functions must be
defined via C<get_routes>.

Copy one of the C<bin/*.psgi> scripts and update it with your new package
name.

Copy one of C<root/static/*.yaml> and rename it to match C<service_name>.

You can now launch the HTTP service with:

    plackup -Ilib --port 8089 --server Twiggy bin/async-microservice-YOURNAME.psgi

In your browser, you can read the OpenAPI documentation:
L<http://0.0.0.0:8089/v1/> and use the editor to extend it:
L<http://0.0.0.0:8089/v1/edit>

=head1 SEE ALSO

OpenAPI Specification: L<https://github.com/OAI/OpenAPI-Specification/tree/master/versions>
or L<https://swagger.io/docs/specification/about/>

L<Async::MicroserviceReq>
L<Twiggy>

=head1 TODO

    - graceful termination (finish all requests before terminating on sigterm/hup)
    - systemd service file examples
    - static/index.html and static/edit.html are not really static, should be moved

=head1 CONTRIBUTORS & CREDITS

The following people have contributed to this distribution by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advice, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    AI
    you?

Also thanks to my current day-job-employer L<https://www.apa-it.at/>.

=head1 BUGS

Please report any bugs or feature requests via L<https://github.com/jozef/Async-Microservice/issues>.

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT & LICENSE

Copyright 2020 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
