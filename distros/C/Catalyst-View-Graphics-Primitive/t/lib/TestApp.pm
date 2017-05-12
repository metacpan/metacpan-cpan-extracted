package # NO CPAN!
    TestApp;

use strict;
use warnings;

use Catalyst;
use Graphics::Primitive::Component;

our $VERSION = '0.01';

__PACKAGE__->config(
    name                  => 'TestApp',
    'View::GP' => {
        driver  => '+TestApp::Driver::Mock'
    },
);

__PACKAGE__->setup;

sub default : Private {
    my ($self, $c) = @_;

    my $comp = Graphics::Primitive::Component->new(
        width => 100,
        height => 100
    );
    $c->stash->{graphics_primitive} = $comp;
}

sub as_pdf : Local {
    my ($self, $c) = @_;

    my $comp = Graphics::Primitive::Component->new(
        width => 100,
        height => 100
    );
    $c->stash->{graphics_primitive} = $comp;
    $c->stash->{graphics_primitive_content_type} = 'application/pdf';
}

sub switch_driver : Local {
    my ($self, $c) = @_;

    my $comp = Graphics::Primitive::Component->new(
        width => 101,
        height => 101
    );
    $c->stash->{graphics_primitive} = $comp;
    $c->stash->{graphics_primitive_driver} = '+TestApp::Driver::Mock2';
    $c->stash->{graphics_primitive_driver_args} = { foobar => 'baz' };
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    $c->forward('View::GP');
}

1;
