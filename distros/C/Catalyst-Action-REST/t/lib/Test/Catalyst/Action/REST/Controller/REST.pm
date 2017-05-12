package Test::Catalyst::Action::REST::Controller::REST;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
  'map' => {
    'text/html'          => 'YAML::HTML',
    'text/x-yaml'        => 'YAML',
});

sub test : Local {
    my ( $self, $c ) = @_;
    $self->status_ok( $c,
        entity => { test => 'worked', data => $c->req->data } );
}

sub test_status_created : Local {
    my ( $self, $c ) = @_;
    $self->status_created(
        $c,
        location => '/rest',
        entity   => { status => 'created' }
    );
}

sub test_status_multiple_choices : Local {
    my ( $self, $c ) = @_;
    $self->status_multiple_choices(
        $c,
        location => '/rest/choice1',
        entity   => { choices => [qw(/rest/choice1 /rest/choice2)] }
    );
}

sub test_status_found : Local {
    my ( $self, $c ) = @_;
    $self->status_found(
        $c,
        location => '/rest',
        entity   => { status => 'found' },
    );
}

sub test_status_accepted : Local {
    my ( $self, $c ) = @_;
    $self->status_accepted(
        $c,
        location => '/rest',
        entity => { status => "queued", }
    );
}

sub test_status_no_content : Local {
    my ( $self, $c ) = @_;
    $self->status_no_content($c);
}

sub test_status_bad_request : Local {
    my ( $self, $c ) = @_;
    $self->status_bad_request( $c,
        message => "Cannot do what you have asked!", );
}

sub test_status_forbidden : Local {
    my ( $self, $c ) = @_;
    $self->status_forbidden ( $c,
        message => "access denied", );
}

sub test_status_not_found : Local {
    my ( $self, $c ) = @_;
    $self->status_not_found( $c,
        message => "Cannot find what you were looking for!", );
}

sub test_status_gone : Local {
    my ( $self, $c ) = @_;
    $self->status_gone( $c,
        message => "Document have been deleted by foo", );
}

sub test_status_see_other : Local {
    my ( $self, $c ) = @_;
    $self->status_see_other(
        $c,
        location => '/rest',
        entity   => { somethin => 'happenin' }
    );
}

sub opts : Local ActionClass('REST') {}

sub opts_GET {
    my ( $self, $c ) = @_;
    $self->status_ok( $c, entity => { opts => 'worked' } );
}

sub opts_not_implemented {
    my ( $self, $c ) = @_;
    $c->res->status(405);
    $c->res->header('Allow' => [qw(GET HEAD)]);
    $c->res->body('Not implemented');
}

1;
