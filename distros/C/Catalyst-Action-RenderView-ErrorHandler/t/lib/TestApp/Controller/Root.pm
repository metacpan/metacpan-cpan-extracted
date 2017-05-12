package TestApp::Controller::Root;

use base qw(Catalyst::Controller);

__PACKAGE__->config->{namespace} = '';


sub test_ok : Global {
    my( $self, $c ) = @_;
    return 1;
}

sub test_die : Global {
    my ( $self, $c ) = @_;
    die "Death by action";
}

sub test_view_death : Global {
    my ( $self, $c ) = @_;
    $c->stash->{'view_death'} = 1;
}

sub test_4xx : Global {
    my ( $self, $c ) = @_;
    $c->res->status(401);
}

sub test_404 : Global {
    my ( $self, $c ) = @_;
    $c->stash->{'key'}   = qq{Page not found};
    $c->stash->{'other'} = qq{555};
    $c->res->status(404);
}

sub test_redirect_then_die : Global {
    my ( $self, $c ) = @_;
    $c->res->redirect($c->uri_for('/'));
    die "Death by action";
}
sub end : ActionClass('RenderView::ErrorHandler') {}



1;
