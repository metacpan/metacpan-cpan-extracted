package Example::Controller::Account;

use Moose;
use MooseX::MethodAttributes;
use Data::Dumper;

extends 'Catalyst::Controller';

sub root :Chained('/') PathPart('account') CaptureArgs(0) { }

  sub one :Chained(root) PathPart('one') Args(0) Does(RequestModel) BodyModel(AccountRequest) {
    my ($self, $c, $request) = @_;
    $c->res->body(Dumper $request->nested_params);
  }

  sub json :Chained(root) PathPart('json') Args(0) Does(RequestModel) RequestModel(API::AccountRequest) {
    my ($self, $c, $request) = @_;
    $c->res->body(Dumper $request->nested_params);
  }

  sub jsonquery :Chained(root) PathPart('jsonquery') Args(0) Does(RequestModel) RequestModel(InfoRequest) RequestModel(InfoQuery)  {
    my ($self, $c, $post, $get) = @_;
    $c->res->body(Dumper {
      get => $get->nested_params,
      post => $post->nested_params,
    });
  }

sub end :Action {
  my ($self, $c) = @_;
  if($c->error) {
    my $e = $c->error->[-1];
    if(ref $e eq 'CatalystX::RequestModel::Utils::InvalidJSON') {
      $c->error(0);
      $c->res->code($e->status_code);
    }
  }
}

__PACKAGE__->meta->make_immutable;

