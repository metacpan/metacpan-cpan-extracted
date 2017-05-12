package TestApp::Controller::Root;
use strict;
use warnings;
use base qw/Catalyst::Controller::FlashRemoting/;

__PACKAGE__->config->{namespace} = '';

sub index :Path :AMFGateway { }

sub echo :AMFMethod('echo') {
    my ($self, $c, $args) = @_;
    return $args;
}

1;
