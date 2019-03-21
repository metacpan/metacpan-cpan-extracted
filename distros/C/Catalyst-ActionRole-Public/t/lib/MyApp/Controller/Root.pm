package MyApp::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends  'Catalyst::Controller';

sub welcome :Path('welcome.txt') Args(0) Does(Public) Serves('/welcome.txt') {
  my ($self, $c) = @);
}

sub root :Chained(/) PathPart('') CaptureArgs(0) { }

sub one_file :Chained(root) 
  PathPart('one.txt') 
  Args(0)
  Does(Public)
  Serves('/one.txt') { }

sub not_found :Chained(root) PathPart('static') Args {
  my ($self, $c, @args) = @_;
  my $path = join('/', @args);  # Don't do this in real life
  $c->res->body("static not found for $path");
}

sub static :Chained(root) Args Does(Public) { }

sub files :Local Does(Public) { }


__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
