package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) {} 

  sub not_found :Chained(root) PathPart('') Args {
    my ($self, $c, @args) = @_;
    $c->detach_error(404);
  }

  sub die :Chained(root) PathPart(die) Args(0) {
    die "saefdsdfsfs";
  }

sub end :Does(RenderErrors) { }

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;

