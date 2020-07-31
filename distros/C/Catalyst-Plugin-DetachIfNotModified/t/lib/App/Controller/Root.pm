package App::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }

use Time::Seconds qw/ ONE_DAY /;

sub base : Chained('/') PathPart('') Args(0) {
    my ($self, $c) = @_;

    $c->detach_if_not_modified_since( ONE_DAY );

    $c->res->body('Ok');
    $c->res->content_type('text/plain');

}

1;
