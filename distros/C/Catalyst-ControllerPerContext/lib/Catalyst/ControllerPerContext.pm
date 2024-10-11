package Catalyst::ControllerPerContext;

our $VERSION = '0.008';

use Moose;
extends 'Catalyst::Controller';

has 'ctx' => (is=>'ro', required=>1);

sub COMPONENT {
  my ($class, $app, $args) = @_;
  $args = $class->merge_config_hashes($args, $class->_config);
  $args = $class->process_component_args($app, $args) if $class->can('process_component_args');

  ## All this crazy will probably break if you do even more insane things
  my $application_self = bless $args, $class;
  $application_self->{_application} = $app;

  my $action  = delete $args->{action}  || {};
  my $actions = delete $args->{actions} || {};
  $application_self->{actions} = $application_self->merge_config_hashes($actions, $action);
  $application_self->{_all_actions_attributes} = delete $application_self->{actions}->{'*'} || {};
  $application_self->{_action_role_args} =  delete($application_self->{action_roles}) || [];
  $application_self->{path_prefix} =  delete $application_self->{path} if exists $application_self->{path};
  $application_self->{_action_roles} = $application_self->_build__action_roles;
  $application_self->{action_namespace} = $application_self->{namespace} if exists $application_self->{namespace};

  return $application_self;
}

sub ACCEPT_CONTEXT {
  my $application_self = shift;
  my $c = shift;

  my $class = ref($application_self);
  my $self = $c->stash->{"__ControllerPerContext_${class}"} ||= do {
    my %args = (%$application_self, ctx=>$c, @_);  
    $class->new($c, \%args);
  };

  return $self;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME
 
Catalyst::ControllerPerContext - Context Scoped Controlelrs

=head1 SYNOPSIS

    package Example::Controller::Register;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::ControllerPerRequest';

    has registration => (
      is => 'ro',
      lazy => 1,
      required => 1,
      default => sub($self) { $self->ctx->Model('Users')->registration },
    );

    sub root :Chained(/root) PathPart(register) Args(0) {
      my ($self, $c) = @_;
      $self->registration;
    }

    __PACKAGE__->meta->make_immutable;  

=head1 DESCRIPTION

Classic L<Catalyst::Controller>s are application scoped, which means we create an instance of the
controller when the application starts as a singleton instance, which is reused for all request
going forward.  This has the lowest overhead.   However it makes it hard to do things like use
controller attributes since those attributes get shared for all requests.  By changing to creating
a new controller for each request you can then use those attributes.

This for the most part is nothing you couldn't do with the stash but has the upside of avoiding
the stash typo bugs you see a lot and also the stash is shared for the entire context so stuff
you stuff in there might be too broadly accessible, whereas data in controller attributes is 
scoped to the controller only.

I consider this an experimental release to let interested people (including myself) to play with 
the idea of per context controllers and see if it leads to new approaches and better code.  Please
be warned that the code under the hood here is a bit of a hack up due to how we added some features
to Controller over time that made the assumption that an attribute is application scoped (such as
how we merged the action role support many years ago).  If this turns out to be a good idea we'll
need to make deeper fixes to the base L<Catalyst::Controller> to make this right.   As a result of
this hacking I can't be sure this controller will be a drop in replacement everywhere, especially
if you've doing a ton of customization to the base controller code in a custom controller subclass.

In order to emphasize the magnitude of this crime / hack there's not really many test cased ;)

Some of the things I'm using this to experiement with is using controller attributes to define
a stronger API between the controller and its views and using controller attributes as proxies
for the models a controller works with.

=head1 ALSO SEE
 
L<Catalyst::Runtime>, L<Catalyst::Controller>

=head1 AUTHOR

    John Napiorkowski <jjnapiork@cpan.org>

=head1 COPYRIGHT
 
    2023

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
