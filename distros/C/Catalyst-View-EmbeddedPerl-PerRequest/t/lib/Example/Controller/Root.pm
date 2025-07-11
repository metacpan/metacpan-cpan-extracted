package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;


extends 'Catalyst::Controller';

sub hello :Local  {
  my ($self, $c) = @_;
  return $c->view('Hello')->http_ok;
}

sub hello_name :Local  {
  my ($self, $c) = @_;
  return $c->view('HelloName', name=>'john')->http_ok;
}

sub wrap :Local  {
  my ($self, $c) = @_;
  return $c->view('TestSubs', name=>'joe')->http_ok;
} 

sub captures :Local  {
  my ($self, $c) = @_;
  return $c->view('Captures')->http_ok;
}

sub no_escape :Local  {
  my ($self, $c) = @_;
  return $c->view('NoEscape')->http_ok;
} 

sub escape :Local  {
  my ($self, $c) = @_;
  return $c->view('Escape')->http_ok;
}

sub inherit :Local  {
  my ($self, $c) = @_;
  return $c->view('Inherit', aaa=>1)->http_ok;
} 

sub attributes :Local  {
  my ($self, $c) = @_;
  return $c->view('Attributes', aaa=>1)->http_ok;
}

sub stringification :Local  {
  my ($self, $c) = @_;
  my $object = $c->model('Stringification')->new;
  return $c->view('Stringification', object => $object)->http_ok;
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(namespace => '');
