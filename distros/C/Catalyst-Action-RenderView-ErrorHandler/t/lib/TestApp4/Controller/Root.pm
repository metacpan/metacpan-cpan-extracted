package TestApp4::Controller::Root;

use base qw(Catalyst::Controller);

__PACKAGE__->config->{namespace} = '';


sub test_ok : Global {
    my( $self, $c ) = @_;
    $c->res->body('Everything is OK');
}

sub test_die : Global {
    my ( $self, $c ) = @_;
    die "Death by action";
}

sub test_404 : Global {
    my ( $self, $c ) = @_;
    $c->stash->{'regexkey'} = qq{Page not found};
    $c->stash->{'other'}    = qq{555};
    $c->res->status(404);
}

sub end : ActionClass('RenderView::ErrorHandler') {}

1;
