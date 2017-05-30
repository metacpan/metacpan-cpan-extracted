package CPAN::Testers::API;
our $VERSION = '0.014';
# ABSTRACT: REST API for CPAN Testers data

#pod =head1 SYNOPSIS
#pod
#pod     $ cpantesters-api daemon
#pod     Listening on http://*:5000
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a REST API on to the data contained in the CPAN Testers
#pod database. This data includes test reports, CPAN distributions, and
#pod various aggregate test reporting.
#pod
#pod =head1 CONFIG
#pod
#pod This application can be configured by setting the C<MOJO_CONFIG>
#pod environment variable to the path to a configuration file. The
#pod configuration file is a Perl script containing a single hash reference,
#pod like:
#pod
#pod     # api.conf
#pod     {
#pod         broker => 'ws://127.0.0.1:5000',
#pod     }
#pod
#pod The possible configuration keys are below:
#pod
#pod =head2 broker
#pod
#pod The URL to a L<Mercury> message broker, starting with C<ws://>. This
#pod broker is used to forward messages to every connected user.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious>, L<Mojolicious::Plugin::OpenAPI>,
#pod L<CPAN::Testers::Schema>,
#pod L<http://github.com/cpan-testers/cpantesters-project>,
#pod L<http://www.cpantesters.org>
#pod
#pod =cut

use Mojo::Base 'Mojolicious';
use CPAN::Testers::API::Base;
use File::Share qw( dist_dir dist_file );
use Log::Any::Adapter;
use Alien::SwaggerUI;
use File::Spec::Functions qw( catdir catfile );

#pod =method schema
#pod
#pod     my $schema = $c->schema;
#pod
#pod Get the schema, a L<CPAN::Testers::Schema> object. By default, the
#pod schema is connected from the local user's config. See
#pod L<CPAN::Testers::Schema/connect_from_config> for details.
#pod
#pod =cut

has schema => sub {
    require CPAN::Testers::Schema;
    return CPAN::Testers::Schema->connect_from_config;
};

#pod =method startup
#pod
#pod     # Called automatically by Mojolicious
#pod
#pod This method starts up the application, loads any plugins, sets up routes,
#pod and registers helpers.
#pod
#pod =cut

sub startup ( $app ) {
    unshift @{ $app->renderer->paths },
        catdir( dist_dir( 'CPAN-Testers-API' ), 'templates' );
    unshift @{ $app->static->paths },
        catdir( dist_dir( 'CPAN-Testers-API' ), 'public' );

    $app->moniker( 'api' );
    $app->plugin( Config => {
        default => { }, # Allow living without config file
    } );

    # Allow CORS for everyone
    $app->hook( after_build_tx => sub {
        my ( $tx, $app ) = @_;
        $tx->res->headers->header( 'Access-Control-Allow-Origin' => '*' );
        $tx->res->headers->header( 'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS' );
        $tx->res->headers->header( 'Access-Control-Max-Age' => 3600 );
        $tx->res->headers->header( 'Access-Control-Allow-Headers' => 'Content-Type, X-Requested-With' );
    } );

    my $r = $app->routes;
    $r->get( '/' => 'index' );
    $r->get( '/docs/*path' => { path => 'index.html' } )->to(
        cb => sub {
            my ( $c ) = @_;
            my $path = catfile( Alien::SwaggerUI->root_dir, $c->stash( 'path' ) );
            my $file = Mojo::Asset::File->new( path => $path );
            $c->reply->asset( $file );
        },
    );

    $r->websocket( '/v1/upload' )->to( 'Upload#feed' );
    $r->websocket( '/v1/upload/dist/:dist' )->to( 'Upload#feed' );
    $r->websocket( '/v1/upload/author/:author' )->to( 'Upload#feed' );

    $r->websocket( '/v3/upload' )->to( 'Upload#feed' );
    $r->websocket( '/v3/upload/dist/:dist' )->to( 'Upload#feed' );
    $r->websocket( '/v3/upload/author/:author' )->to( 'Upload#feed' );

    $app->plugin( OpenAPI => {
        url => dist_file( 'CPAN-Testers-API' => 'v1.json' ),
        allow_invalid_ref => 1,
    } );
    $app->plugin( OpenAPI => {
        url => dist_file( 'CPAN-Testers-API' => 'v3.json' ),
        allow_invalid_ref => 1,
    } );
    $app->helper( schema => sub { shift->app->schema } );
    $app->helper( render_error => \&render_error );

    Log::Any::Adapter->set( 'MojoLog', logger => $app->log );
}

#pod =method render_error
#pod
#pod     return $c->render_error( 400 => 'Bad Request' );
#pod     return $c->render_error( 400, {
#pod         path => '/since',
#pod         message => 'Invalid date/time',
#pod     } );
#pod
#pod Render an error in JSON like other OpenAPI errors. The first argument
#pod is the HTTP status code. The remaining arguments are a list of errors
#pod to report. Plain strings are turned into one-element hashrefs with a
#pod C<message> key. Hashrefs are used as-is.
#pod
#pod The resulting JSON looks like so:
#pod
#pod     {
#pod         "errors":  [
#pod             {
#pod                 "path": "/",
#pod                 "message": "Bad Request"
#pod             }
#pod         ]
#pod     }
#pod
#pod     {
#pod         "errors":  [
#pod             {
#pod                 "path": "/since",
#pod                 "message": "Invalid date/time"
#pod             }
#pod         ]
#pod     }
#pod
#pod =cut

sub render_error( $c, $status, @errors ) {
    return $c->render(
        status => $status,
        openapi => {
            errors => [
                map { !ref $_ ? { message => $_, path => '/' } : $_ } @errors,
            ],
        },
    );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::API - REST API for CPAN Testers data

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    $ cpantesters-api daemon
    Listening on http://*:5000

=head1 DESCRIPTION

This is a REST API on to the data contained in the CPAN Testers
database. This data includes test reports, CPAN distributions, and
various aggregate test reporting.

=head1 METHODS

=head2 schema

    my $schema = $c->schema;

Get the schema, a L<CPAN::Testers::Schema> object. By default, the
schema is connected from the local user's config. See
L<CPAN::Testers::Schema/connect_from_config> for details.

=head2 startup

    # Called automatically by Mojolicious

This method starts up the application, loads any plugins, sets up routes,
and registers helpers.

=head2 render_error

    return $c->render_error( 400 => 'Bad Request' );
    return $c->render_error( 400, {
        path => '/since',
        message => 'Invalid date/time',
    } );

Render an error in JSON like other OpenAPI errors. The first argument
is the HTTP status code. The remaining arguments are a list of errors
to report. Plain strings are turned into one-element hashrefs with a
C<message> key. Hashrefs are used as-is.

The resulting JSON looks like so:

    {
        "errors":  [
            {
                "path": "/",
                "message": "Bad Request"
            }
        ]
    }

    {
        "errors":  [
            {
                "path": "/since",
                "message": "Invalid date/time"
            }
        ]
    }

=head1 CONFIG

This application can be configured by setting the C<MOJO_CONFIG>
environment variable to the path to a configuration file. The
configuration file is a Perl script containing a single hash reference,
like:

    # api.conf
    {
        broker => 'ws://127.0.0.1:5000',
    }

The possible configuration keys are below:

=head2 broker

The URL to a L<Mercury> message broker, starting with C<ws://>. This
broker is used to forward messages to every connected user.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin::OpenAPI>,
L<CPAN::Testers::Schema>,
L<http://github.com/cpan-testers/cpantesters-project>,
L<http://www.cpantesters.org>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Breno G. de Oliveira

Breno G. de Oliveira <garu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
