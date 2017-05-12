package TestApp::Model::Foo;

use Moose;

our @data;

extends 'Catalyst::Model';

with 'Catalyst::Model::Role::RunAfterRequest';

sub demonstrate {
    my $self = shift;
    $self->_run_after_request(
        sub { push( @data, "one" ); },
        sub { push( @data, "two" ); },
        sub { push @data, ref shift },
    );
}

1;
