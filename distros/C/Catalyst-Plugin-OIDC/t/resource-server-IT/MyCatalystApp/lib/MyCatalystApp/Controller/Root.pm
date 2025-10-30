package MyCatalystApp::Controller::Root;
use utf8;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

# ----------------------
# resource server routes
# ----------------------
sub my_resource :Path('my-resource') :Args(0) {
  my ( $self, $c ) = @_;

  my $user = try {
    my $access_token = $c->oidc->verify_token();
    return $c->oidc->build_user_from_claims($access_token->claims);
  }
  catch {
    $c->log->warn("Token/User validation : $_");
    $c->stash->{expose_stash}{error} = 'Unauthorized';
    $c->forward('View::JSON');
    $c->response->status(401);
    return;
  } or return;

  unless ($user->has_role('role2')) {
    $c->log->warn("Insufficient roles");
    $c->stash->{expose_stash}{error} = 'Forbidden';
    $c->forward('View::JSON');
    $c->response->status(403);
    return;
  }

  $c->stash->{expose_stash}{user_login} = $user->login;
  $c->forward('View::JSON');
}
# ----------------------

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
