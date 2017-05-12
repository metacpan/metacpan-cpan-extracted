package MyApp::Controller::User;

use Moose;
use MooseX::MethodAttributes;
extends 'Catalyst::Controller';

sub display :Path('') {
  my ($self, $c) = @_;
  $c->stash(
    name => 'John',
    age => 42,
    motto => 'Why Not?');
  $c->view('User')
    ->overlay_view(
      'Master', sub {
        title => $_->at('title')->content,
        css => $_->find('link'),
        meta => $_->find('meta'),
        body => $_->at('body')->content})
    ->http_ok;
}

__PACKAGE__->meta->make_immutable;
