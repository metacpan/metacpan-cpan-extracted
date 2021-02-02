package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use CatalystX::Utils::HttpException;

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) {} 

  sub not_found :Chained(root) PathPart('') Args {
    my ($self, $c, @args) = @_;
    $c->detach_error(404);
  }

  sub die :Chained(root) PathPart(die) Args(0) {
    die "saefdsdfsfs";
  }

  sub throw :Chained(root) PathPart(throw) Args(0) {
    throw_http 400, errors=>[1,2,3],  
  }

sub end :Does(RenderErrors) { }

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;

