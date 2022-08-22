package Catalyst::View::BasePerRequest::Factory;

use warnings;
use strict;
use Scalar::Util ();
use Module::Runtime ();

sub ACCEPT_CONTEXT {
  my ($factory, $c, @args) = @_;
  my $key = Scalar::Util::refaddr($factory) || $factory;
  return $c->stash->{"__BasePerRequest_${key}"} ||= $factory->build($c, @args);
}

sub build {
  my ($factory, $c, @args) = @_;
  my $class = $factory->{class};
  @args = $class->prepare_build_args($c, @args) if $class->can('prepare_build_args');
  my %build_args = $factory->prepare_build_args($c, @args);
  my $view = eval {
    $class->build(%build_args);
  } || do {
    $factory->do_handle_build_view_exception($class, $@);
  };
  $c->stash(current_view_instance=>$view);
  return $view;
}

sub build_view_error_class { return 'Catalyst::View::BasePerRequest::Exception::BuildViewError' }

sub do_handle_build_view_exception {
  my ($factory, $class, $err) = @_;
  return $err->rethrow if Scalar::Util::blessed($err) && $err->can('rethrow');
  my $exception = Module::Runtime::use_module($factory->build_view_error_class);
  $exception->throw(class=>$class, build_error=>$err);
}

sub prepare_build_args {
  my ($factory, $c, @args) = @_;
  my %args = $factory->prepare_args(@args);
  my %merged_args = %{$factory->{merged_args}||+{}};

  return (%merged_args, %args, ctx=>$c);
}

sub prepare_args {
  my ($factory, @args) = @_;
  if( (ref($args[-1])||'') eq 'CODE' ) {
    my $code = pop @args;
    push @args, (code=>$code);
  }
  return @args;
}

1;

=head1 NAME
 
Catalyst::View::Template::BasePerRequest::Factory - Build a per request view

=head1 SYNOPSIS

    Not intended for standalone enduser use.

=head1 DESCRIPTION

This module is used by L<Catalyst::View::BasePerRequest> to encapsulate building the actual
view object on a per request basis.  Code here might be of interest to people building their
own view frameworks.  for example you might wish to override the exception handler or change
how the initialization arguments are made.

=head1 ALSO SEE
 
L<Catalyst::View::BasePerRequest>

=head1 AUTHORS & COPYRIGHT
 
See L<Catalyst::View::BasePerRequest>

=head1 LICENSE
 
See L<Catalyst::View::BasePerRequest>
 
=cut
