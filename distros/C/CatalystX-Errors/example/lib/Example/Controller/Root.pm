package Example::Controller::Root;

{
  package MyApp::Exception::Custom;

  use Moose;
  extends 'CatalystX::Utils::HttpException';

  has '+status' => (init_arg=>undef, default=>sub {418});
  has '+errors' => (init_arg=>undef, default=>sub { ["Coffee not allowed! Also: @{[ $_[0]->special_param ]}"] });
  has special_param => (is=>'ro', required=>1);

  __PACKAGE__->meta->make_immutable;
}

use Moose;
use MooseX::MethodAttributes;
use CatalystX::Utils::HttpException;
use MyApp::Exception::Custom;

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

  sub teapot :Chained(root) PathPart(teapot) Args(0) {
    MyApp::Exception::Custom->throw(special_param=>'Only Green Tea!');  
  }


sub end :Does(RenderErrors) { }

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;

