package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

# your actions replace this one
sub default : Private { 
    my ($self, $c) = @_;
    my $body = '';
    if ($c->authenticate({ username => 'testuser', password => 'testpass' })) {
        $body .= "Authenticated:";
        $body .= $c->user->id;
        $body .= ". Roles: " . join(', ', $c->user->roles);
    }
    $c->res->body($body);
}

1;
