package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});

sub auto : Private {
  my ( $self, $ctx ) = @_;
  $ctx->stash( current_view => 'HTML' );
  return 1;
}

sub base : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $ctx ) = @_;
}

sub test : Chained('base') PathPart('') Args(0) {
    my ( $self, $ctx ) = @_;
}

=head2 logout
=cut
sub logout : Local {
    my ( $self, $ctx ) = @_;
    $ctx->logout();
    $ctx->res->redirect(q{/});
}


=head2 end
Attempt to render a view, if needed.
=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    return 1 if $c->res->body;
}


__PACKAGE__->meta->make_immutable;

1;
