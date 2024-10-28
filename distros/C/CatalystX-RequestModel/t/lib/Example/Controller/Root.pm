package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Data::Dumper;

extends 'Catalyst::Controller';

sub test1 :Local Does(RequestModel) BodyModel {
  my ($self, $c, $body) = @_;
  $c->response->body(Dumper($body->nested_params));
}

sub test2 :Local Does(RequestModel) BodyModel('~Login') {
  my ($self, $c, $body) = @_;
  $c->response->body(Dumper($body->nested_params));
}

sub test22 :Local Does(RequestModel) BodyModel('~::Login') {
  my ($self, $c, $body) = @_;
  $c->response->body(Dumper($body->nested_params));
}

sub test222 :Local Does(RequestModel) BodyModelFor('test1') {
  my ($self, $c, $body) = @_;
  $c->response->body(Dumper($body->nested_params));
}

sub test3 :Local Does(RequestModel) QueryModel {
  my ($self, $c, $q) = @_;
  $c->response->body(Dumper($q->nested_params));
}

sub test4 :Local Does(RequestModel) QueryModel('~LoginQuery') {
  my ($self, $c, $q) = @_;
  $c->response->body(Dumper($q->nested_params));
}

sub test44 :Local Does(RequestModel) QueryModel('~::LoginQuery') {
  my ($self, $c, $q) = @_;
  $c->response->body(Dumper($q->nested_params));
}

sub test444 :Local Does(RequestModel) QueryModelFor('test3') {
  my ($self, $c, $q) = @_;
  $c->response->body(Dumper($q->nested_params));
}

sub omit :Post :Local Does(RequestModel) BodyModel() {
  my ($self, $c, $q) = @_;
  $c->response->body(Dumper($q->nested_params));
}

__PACKAGE__->meta->make_immutable;
