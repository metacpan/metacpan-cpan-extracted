package Dancer2::Controllers::Controller;

use Moose;
use MooseX::MethodAttributes;
use namespace::clean;
use Dancer2;

__PACKAGE__->meta->make_immutable();

1;

=encoding utf8

=head1 NAME

Dancer2::Controllers::Controller

=head1 SYNOPSIS

L<Moose> base class for creating controllers.

=head1 EXAMPLE

    package MyApp::Controller;

    use Moose;

    BEGIN { extends 'Dancer2::Controllers::Controller' }

    sub hello_world : Route(get => /) {
        "Hello World!";
    }

    1;

=head1 API

=head2 Route attribute

    package MyApp::Controller;

    use Moose;

    BEGIN { extends 'Dancer2::Controllers::Controller' }

    sub hello_world : Route(get => /) {
        "Hello World!";
    }

    sub foo : Route(get => /foo/bar/:id[Int]) {
        shift->request->params->{id};
    }

The route attribute is used to defined Dancer2 routes.

