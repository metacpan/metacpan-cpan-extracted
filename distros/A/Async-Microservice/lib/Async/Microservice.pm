package Async::Microservice;

use strict;
use warnings;
use 5.010;
use utf8;

our $VERSION = '0.03';

use Moose::Role;
requires qw(get_routes service_name);

use Plack::Request;
use Try::Tiny;
use Path::Class qw(dir file);
use MooseX::Types::Path::Class;
use Path::Router;
use FindBin qw($Bin);
use Async::MicroserviceReq;
use Log::Any qw($log);

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
        my $static_dir = $ENV{STATIC_DIR} // dir($Bin, '..', 'root', 'static');
        die 'static dir "' . $static_dir . '" not found (check $ENV{STATIC_DIR})'
            if !$static_dir || !-d $static_dir;
        return $static_dir;
    },
    lazy => 1,
);

has 'router' => (
    is      => 'ro',
    isa     => 'Path::Router',
    lazy    => 1,
    builder => '_build_router'
);

our $start_time = time();
our $req_count  = 0;

sub _build_router {
    my ($self) = @_;

    my $router = Path::Router->new;
    my @routes = $self->get_routes();
    while (@routes) {
        my ($path, $opts) = splice(@routes, 0, 2);
        $router->add_route($path, %$opts);
    }

    return $router;
}

sub plack_handler {
    my ($self, $env) = @_;

    $req_count++;

    my $plack_req = Plack::Request->new($env);
    my $this_req  = Async::MicroserviceReq->new(
        method     => $plack_req->method,
        headers    => $plack_req->headers,
        content    => $plack_req->content,
        path       => $plack_req->path_info,
        params     => $plack_req->parameters,
        static_dir => $self->static_dir,
        jsonp      => $self->jsonp,
    );

    # set process name and last requested path for debug/troubleshooting
    $0 = $self->service_name . ' ' . $this_req->path;

    my $plack_handler_sub = sub {
        my ($plack_respond) = @_;
        $this_req->plack_respond($plack_respond);

        # API version
        my ($version, $sub_path_info);
        if ($this_req->path =~ qr{^/v(\d+?)(/.*)$}) {
            $version       = $1;
            $sub_path_info = $2;
        }

        # without version path redirect to the latest version
        return $this_req->redirect('/v' . $self->api_version . '/')
            unless $version;

        # handle static/
        return $this_req->static($1)
            if ($sub_path_info =~ qr{^/static(/.+)$});

        # dispatch request
        state $path_dispatch = {
            '/' => sub {
                $this_req->static('index.html', sub {$self->_update_openapi_html(@_)});
            },
            '/edit' => sub {
                $this_req->static('edit.html', sub {$self->_update_openapi_html(@_)});
            },
            '/hcheck' => sub {
                $this_req->text_plain(
                    'Service-Name: ' . $self->service_name,
                    "API-Version: " . $self->api_version,
                    'Uptime: ' . (time() - $start_time),
                    'Request-Count: ' . $req_count,
                    'Pending-Requests: ' . Async::MicroserviceReq->get_pending_req,
                );
            },
            '' => sub {
                if (my $match = $self->router->match($sub_path_info)) {
                    my $func = $match->{mapping}->{$this_req->method};
                    if ($func && (my $misc_fn = $self->can($func))) {
                        %{$this_req->params} = (
                            %{$this_req->params},
                            %{$match->{mapping}}
                        );
                        my $resp = $misc_fn->($self, $this_req, $match);
                        if (blessed($resp) && $resp->isa('Future')) {
                            $resp->retain;
                            $resp->on_done(
                                sub {
                                    my ($resp_data) = @_;
                                    if ( ref($resp_data) eq 'ARRAY' ) {
                                        $this_req->respond(@$resp_data);
                                    }
                                    else {
                                        $this_req->respond( 200,
                                            [], $resp_data );
                                    }
                                }
                            );
                            $resp->on_fail(sub {
                                my ($err_msg) = @_;
                                $err_msg ||= 'unknown';
                                $log->errorf('exception while calling "%s": %s', $plack_req->path_info, $err_msg);
                                $this_req->respond(
                                    503, [], 'internal server error calling '.$func.': ' . $err_msg
                                );
                            });
                            $resp->on_cancel(sub {
                                $this_req->respond(
                                    429, [], 'request for '.$func.' canceled'
                                );
                            });
                        }
                        elsif (ref($resp) eq 'ARRAY') {
                            $this_req->respond(@$resp);
                        }
                        return;
                    }
                }
                return $this_req->respond(404, [], 'not found');
            },
        };
        my $dispatch_fn = $path_dispatch->{$sub_path_info} // $path_dispatch->{''};

        return $dispatch_fn->();
    };

    return sub {
        my $respond  = shift;
        my $response = try {
            $plack_handler_sub->($respond);
        }
        catch {
            $this_req->respond(503, [], 'internal server error: ' . $_);
        };
        return $response;
    };
}

sub _update_openapi_html {
    my ($self, $content) = @_;
    my $service_name = $self->service_name;
    $content =~ s/ASYNC-SERVICE-NAME/$service_name/g;
    return $content;
}

1;

__END__

=head1 NAME

Async::Microservice - Async HTTP Microservice Moose Role

=head1 SYNOPSYS

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

This L<Moose::Role> helps to quicly bootstrap async http service that is
including OpenAPI documentation.

See L<https://time.meon.eu/> and L<Async::Microservice::Time> code.

=head2 To bootstrap new async service

Create new package for your APIs from current examples
C<lib/Async/Microservice/*>. Inside set return value of C<service_name>.
This string will be used to set process name and to read/locate
OpenAPI yaml definition for the documentation. Any GET/POST processing
funtions must be defined in C<get_routes> funtion.

Copy one of the C<bin/*.psgi> update it with your new package name.

Copy one of the C<root/static/*.yaml> to have the same name as
C<service_name>.

Now you are able to lauch the http service with:

    plackup -Ilib --port 8089 --server Twiggy bin/async-microservice-YOURNAME.psgi

In your browser you can read the OpenAPI documentation: L<http://0.0.0.0:8089/v1/>
and also use editor to extend it: L<http://0.0.0.0:8089/v1/edit>

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
