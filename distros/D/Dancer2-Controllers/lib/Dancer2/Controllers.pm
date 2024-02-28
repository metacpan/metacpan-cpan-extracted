package Dancer2::Controllers;

use strict;
use warnings;

use Carp     qw(croak);
use Exporter qw(import);
use MooseX::MethodAttributes;
use Data::Dumper;

our $VERSION = '1.1';
our @EXPORT  = qw(controllers);

my %dsl;
@dsl{qw(get post put patch del any)} = qw(1 1 1 1 1 1);

sub controllers {
    my $classes = shift;

    croak
qq{Dancer2::Controllers::controllers expects a single, array-ref as it's argument, instead got $classes}
      unless ref($classes) && ref($classes) eq 'ARRAY';

    my ($pkg) = caller;

    for (@$classes) {
        my $class   = $_;
        my $meta    = $class->meta;
        my @methods = $meta->get_method_list;
        for (@methods) {
            my $method = $meta->get_method($_);
            next unless $method->can('attributes');
            for ( @{ $method->attributes } ) {
                my $method_name = $method->fully_qualified_name();

                if (/^Route$/x) {
                    croak
qq{Empty route declared, $method_name, did you mean to provide arguments?};
                }

                next unless /^Route\(.*/x;
                my ( $action, $location ) =
/^Route\((get|put|post|patch|del|any)\s=>\s'?"?([\w\/:_\-\[\]{}?]+)'?"?\)/x;

                croak
qq{Location is undefined for route attribute on method '$method_name'}
                  unless $location;
                croak
qq{Invalid action $action for route attribute on method '$method_name' should be get, put, post, patch, del, any}
                  unless exists $dsl{$action};

                $pkg->can($action)
                  ->( $location, sub { $class->can( $method->name() )->(@_) } );
            }
        }
    }
}

1;

=encoding utf8

=head1 NAME

Dancer2::Controllers

=head1 SYNOPSIS

Dancer2::Controllers is a Spring-Boot esq wrapper for defining Dancer2 routes, it allows you to define
routes inside of modules using method attributes.

=head1 EXAMPLE

    package MyApp::Controller;

    use Moose;

    BEGIN { extends 'Dancer2::Controllers::Controller' }

    sub hello_world : Route(get => /) {
        "Hello World!";
    }

    1;

    package main;

    use Dancer2;
    use Dancer2::Controllers;

    controllers( ['MyApp::Controller'] );

    dance;

=head1 API

=head2 controllers

    controllers( [
        'MyApp::Controller::Foo',
        'MyApp::Controller::Bar'
    ] );

A subroutine that takes a list of controller module names, and registers their routes methods, annotated by the C<Route> attribute.
