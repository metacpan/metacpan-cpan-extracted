package Example::Controller::Root;

{
  package MyApp::Exception::Custom;

  use Moose;
  with 'CatalystX::Utils::DoesHttpException';

  has special_param => (is=>'ro', required=>1);

  sub status_code { 418 }

  sub additional_headers {
    return [
      'X-version' => '1.001',
    ];
  }

  sub error {
    return "Coffee not allowed! Also: @{[ $_[0]->special_param ]}"
  }

  __PACKAGE__->meta->make_immutable;
}

use Moose;
use MooseX::MethodAttributes;
use CatalystX::Utils::HttpException 'throw_http';
use MyApp::Exception::Custom;

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) {} 

  sub not_found :Chained(root) PathPart('') Args {
    my ($self, $c, @args) = @_;
    $c->detach_error(404, +{aaa=>111, error=>"Path '@{[ join '/', @args ]}' not found"});
  }

  sub die :Chained(root) PathPart(die) Args(0) {
    die "saefdsdfsfs";
  }

  sub throw :Chained(root) PathPart(throw) Args(0) {
    throw_http 400, error=>'one',  
  }

  sub server_error :Chained(root) PathPart(server_error) Args(0) {
    throw_http 500, error=>'one',  
  }

  sub teapot :Chained(root) PathPart(teapot) Args(0) {
    MyApp::Exception::Custom->throw(special_param=>'Only Green Tea!');  
  }


sub end :Does(RenderErrors) { }

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;

