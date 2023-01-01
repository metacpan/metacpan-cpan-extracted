package Example::Controller::Login;

use Moose;
use MooseX::MethodAttributes;
use Data::Dumper;

extends 'Catalyst::Controller';

sub login :POST Chained(/) Args(0) Does(RequestModel) RequestModel(LoginRequest)  {
  my ($self, $c, $request) = @_;
  $c->res->body(Dumper $request->nested_params);
}

sub info :Chained(/) Args(0) Does(RequestModel) RequestModel(InfoQuery)  {
  my ($self, $c, $request) = @_;
  $c->res->body(Dumper $request->nested_params);
}

sub postinfo :Chained(/) Args(0) Does(RequestModel) RequestModel(LoginRequest) RequestModel(InfoQuery)  {
  my ($self, $c, $post, $get) = @_;
  $c->res->body(Dumper {
    get => $get->nested_params,
    post => $post->nested_params,
  });
}

sub info2 :Chained(/) Args(0) Does(RequestModel) QueryModel(InfoQuery2)  {
  my ($self, $c, $request) = @_;
  $c->res->body(Dumper $request->nested_params);
}

sub postinfo2 :Chained(/) Args(0) Does(RequestModel) RequestModel(LoginRequest) QueryModel(InfoQuery2)   {
  my ($self, $c, $post, $get) = @_;

  $c->res->body(Dumper {
    get => $get->nested_params,
    post => $post->nested_params,
  });
}

sub info3 :Chained(/) Args(0) Does(RequestModel) QueryModel(InfoQuery3)  {
  my ($self, $c, $request) = @_;
  $c->res->body(Dumper $request->nested_params);
}


__PACKAGE__->meta->make_immutable;

