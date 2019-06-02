package StatsApp::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $stats = $c->stats;

    $stats->profile( begin => 'rootx.foo-bar_baz' );

    $c->res->body('Ok');
    $c->res->content_type('text/plain');

    $stats->profile( end => 'rootx.foo-bar_baz' );

}

1;
