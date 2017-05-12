package    # hide from PAUSE
    TestApp;

use Moose;
use TestApp::User;
extends 'Catalyst::Component';
use namespace::autoclean;

has 'stash' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
    default  => sub { {} }
);
has 'user' => (
    isa      => 'TestApp::User',
    is       => 'rw',
    required => 1,
    default  => sub { TestApp::User->new }
);

sub user_exists {
    my $self = shift;
    return $self->user if $self->user;
    return 0;
}

1;

