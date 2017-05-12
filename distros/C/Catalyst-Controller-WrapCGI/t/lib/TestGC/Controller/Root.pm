package TestGC::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use CatalystX::GlobalContext ();
use Dongs ();

__PACKAGE__->config->{namespace} = '';

sub auto : Private {
    my ($self, $c) = @_;
    CatalystX::GlobalContext->set_context($c);
    1;
}

sub dummy : Local {
    my ($self, $c) = @_;
    $c->res->body(Dongs->foo);
}

1;
