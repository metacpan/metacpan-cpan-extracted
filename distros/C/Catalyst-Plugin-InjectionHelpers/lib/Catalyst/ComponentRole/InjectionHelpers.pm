package Catalyst::ComponentRole::InjectionHelpers;

use Moose::Role;
use Moose::Util;

#requires 'ACCEPT_CONTEXT';

has application => (is=>'ro', required=>1);
has from => (is=>'ro', isa=>'ClassName|CodeRef', required=>1);
has method => (is=>'ro', required=>1, default=>'new');
has injected_component_name => (is=>'ro', isa=>'Str', required=>1);
has injection_parameters => (is=>'ro', isa=>'HashRef', required=>1);
has get_config => (is=>'ro', isa=>'CodeRef', required=>1, default=>sub {sub { +{} }});
has roles => (is=>'ro', isa=>'ArrayRef', required=>1, default=>sub { +[] });
has transform_args => (is=>'ro', isa=>'CodeRef', predicate=>'has_transform_args');
has composed_class => (
  is=>'ro',
  init_arg=>undef,
  required=>1,
  lazy=>1,
  default=>sub { Moose::Util::with_traits($_[0]->from, @{$_[0]->roles}) });

sub merge_args {
  my ($self, $app_or_c, @args) = @_;
  my %global_config_args = %{ $self->get_config->($app_or_c) };

  # Ok, so if @args are a hash, it just gets combined, no harm at
  # all as long as you expect a hash.  But is @args is an array,
  # we want it FIRST, because we will assume the @args are intended to
  # be positional.

  # Remember @args only comes from $c->model($model, @args).
  # So here you can override global args from the call to model, and for
  # now we just do the dumbest possible merge type.
  return (%global_config_args, @args);
}

sub transform_args_if_needed {
  my ($self, $composed_class, $app_or_c, @merged_args) = @_;
  if($self->has_transform_args) {
    @merged_args = $self->transform_args->($self, $composed_class, $app_or_c, @merged_args);
  }
  return @merged_args;
}

sub build_new_instance {
  my ($self, $app_or_c, @args) = @_;
  my @merged_args = $self->merge_args($app_or_c, @args);
  my $method = $self->method;
  my $composed_class = ref($self->from)||'' eq "CODE" ?
    $self->from : $self->composed_class;

  @merged_args = $self->transform_args_if_needed($composed_class, $app_or_c, @merged_args);

  if((ref($method)||'') eq 'CODE') {
    return $self->$method($composed_class, $app_or_c, @merged_args)
  } else {
    return $composed_class->$method(@merged_args);
  }
}

=head1 NAME

Catalyst::ComponentRole::InjectionHelpers; - Common role for adaptors

=head1 SYNOPSIS

    package MyApp::MySpecialAdaptor

    use Moose;
    with 'Catalyst::ComponentRole::InjectionHelpers';

    sub ACCEPT_CONTEXT { ... }

=head1 DESCRIPTION

Common functionality and interface inforcement for injection helper adaptors.
You should see L<Catalyst::Plugin::InjectionHelpers> for more.

=head1 ATTRIBUTES

This role defines the following attributes

=head2 application

Your L<Catalyst> application

=head2 from

A class name or coderef that is being adapted to run under L<Catalyst>

=head2 method

The name of the method in your 'from' class that is used to create a new
instance  OR a coderef that is used to return an instance.  Defaults to 'new'.

=head2 roles

A list of L<Moose::Role>s to be composed into your class

=head2 transform_args

A coderef that you can use to transform configuration arguments into something
more suitable for your class.  For example, the configuration args is typically
a hash, but your object class may require some positional arguments.

    MyApp->inject_components(
      'Model::Foo' => {
        from_class = 'Foo',
        transform_args => sub {
          my ($adaptor_instance, $coderef, $app, %args) = @_;
          my $path = delete $args{path},
          return ($path, %args);
        },
      },
    );

Should return the args as they as used by the initialization method of the
'from_class'.

=head2 get_config

=head2 injection_parameters

=head2 injected_component_name

TBD

=head1 METHODS

This role exposes the following public methods

=head2 merge_args

Responsible for merging global configuration and anything passed in at call
time

=head2 transform_args_if_needed

Perform any programmatic argument transformation

=head2 build_new_instance

Responsible for returning a new instance of the component.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst::Plugin::InjectionHelpers>
L<Catalyst>, L<Catalyst::Model::InjectionHelpers::Application>,
L<Catalyst::Model::InjectionHelpers::Factory>, L<Catalyst::Model::InjectionHelpers::PerRequest>
L<Catalyst::ModelRole::InjectionHelpers>

=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
1;
