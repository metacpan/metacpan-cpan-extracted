package TestAppAltRoot::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub main :Path {
    my ($self, $c) = @_;
    $c->stash( name => 'Dave' );
}

sub direct_render :Local {
    my ($self, $c) = @_;
    my $body = 
        $c->
        view('HTML')->
        render(
          $c, 
          \'<html><head><title>example</title></head><body>Hello <span id="name">Fred</span></body></html>',
          {name=>'Dave'},
        );

    $c->res->body($body);
}

sub name_zaction :Local {
    my ($self, $c) = @_;
    $c->stash(
      name => 'Dave',
      template => 'main',
      zoom_action => 'main',
    );
}
 
sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;
