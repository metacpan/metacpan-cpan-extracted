package CatalystX::Controller::PSGI;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

our $VERSION = '0.001002';
$VERSION = eval $VERSION;

my @_psgi_actions;
after 'register_actions' => sub {
    my ( $self, $c ) = @_;

    my $class = $self->catalyst_component_name;
    my $namespace = $self->action_namespace( $c );

    if ( my $app = $self->can('call') ){
        push @_psgi_actions, {
            name    => 'call',
            path    => '',
            class   => ref $self,
            app     => $app,
        };
    }

    foreach my $psgi_action ( @_psgi_actions ){
        next if ( $psgi_action->{class} ne $class ) || $psgi_action->{registered};

        my $reverse = "${namespace}/" . $psgi_action->{path};

        my $action = $self->create_action(
            name        => $psgi_action->{name},
            reverse     => $reverse,
            namespace   => $namespace,
            class       => $class,
            attributes  => {Path => [$reverse]},
            code        => sub {
                my ( $self, $c ) = @_;

                my $env = $c->req->env;

                $env->{PATH_INFO} =~ s|^/$namespace||g;
                $env->{SCRIPT_NAME} = "/$namespace";

                $c->res->from_psgi_response(
                    $psgi_action->{app}->( $self, $env )
                );
            },
        );

        $c->dispatcher->register( $c, $action );
        $psgi_action->{registered} = 1;
    }
};

sub mount {
    my ( $class, $path, $app ) = @_;

    $path =~ s|^/||g;
    my $name = $path;

    push @_psgi_actions, {
        name        => $name,
        class       => $class,
        path        => $path,
        app         => $app,
    };
}

=head1 NAME

CatalystX::Controller::PSGI - use a PSGI app in a Catalyst Controller

=head1 SYNOPSIS

    package TestApp::Controller::File;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'CatalystX::Controller::PSGI'; }

    use Plack::App::File;
    use Plack::Response;

    has 'app_file' => (
        is      => 'ro',
        default => sub {
            return Plack::App::File->new(
                file            => __FILE__,
                content_type    => 'text/plain',
            )->to_app;
        },
    );

    sub call {
        my ( $self, $env ) = @_;

        $self->app_file->( $env );
    }

    my $hello_app = sub {
        my ( $self, $env ) = @_;

        my $res = Plack::Response->new(200);
        $res->content_type('text/plain');
        $res->body("hello world");

        return $res->finalize;
    };

    __PACKAGE__->mount( '/hello/world' => $hello_app );

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Use PSGI apps inside Catalyst Controllers.

Combine this with L<Catalyst::Component::InstancePerContext> if you want to access $c in your psgi app

=head1 Usage

=head2 call method

If this method is provided, it will be called as the root action of that controller.

    package TestApp::Controller::File;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'CatalystX::Controller::PSGI'; }

    use Plack::App::File;

    has 'app_file' => (
        is      => 'ro',
        default => sub {
            return Plack::App::File->new(
                file            => __FILE__,
                content_type    => 'text/plain',
            )->to_app;
        },
    );

    sub call {
        my ( $self, $env ) = @_;

        $self->app_file->( $env );
    }

    __PACKAGE__->meta->make_immutable;

E.g. in the above example it will be /file/

Works similar to L<Plack::Component>, except that as well as $env being passed in, $self is as well. Where $env is the psgi env, and $self is the Catalyst Controller.

=head2 mount

Mount a path within the controller to an app.

    package TestApp::Controller::Hello;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'CatalystX::Controller::PSGI'; }

    use Plack::Response;

    my $hello_app = sub {
        my ( $self, $env ) = @_;

        my $res = Plack::Response->new(200);
        $res->content_type('text/plain');
        $res->body("hello world");

        return $res->finalize;
    };

    __PACKAGE__->mount( '/world' => $hello_app );

    __PACKAGE__->meta->make_immutable;

In the above example the url /hello/world will be bound to the $hello_app. As with call, $self and $env will be passed in.

=head1 EXAMPLES

L<http://www.catalystframework.org/calendar/2013/16>
L<http://www.catalystframework.org/calendar/2013/17>

There is also an example app in the test suite

=head1 AUTHOR

Mark Ellis E<lt>markellis@cpan.orgE<gt>

=head1 SEE ALSO

L<Catalyst::Component::InstancePerContext>

=head1 LICENSE

Copyright 2014 by Mark Ellis E<lt>markellis@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
