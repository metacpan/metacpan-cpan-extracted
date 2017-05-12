package TestApp::ModelBase::Foo;
use Moose;
extends 'Catalyst::Model';

has something => ( is => 'ro' );

has requested_traits => (
    isa => 'ArrayRef',
    is => 'ro',
);

sub new_with_traits {
    my ($class,$args) = @_;

    $args->{requested_traits} = delete $args->{traits};
    return $class->new($args);
}

1;
