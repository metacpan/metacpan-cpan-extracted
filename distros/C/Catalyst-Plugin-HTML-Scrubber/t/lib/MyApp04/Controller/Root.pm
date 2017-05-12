package MyApp04::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(namespace => '');

sub index : Path : Args(0) {
    my ($self, $c) = @_;
    
    $c->res->body('index');
}

sub scrub : Local {
    my ($self, $c) = @_;
    $c->html_scrub; 
    $c->res->body('scrub');
}

1;

