package Data::Object::Config::Signatures;

use strict;
use warnings;

use Function::Parameters;

use Data::Object::Export 'namespace', 'reify';

# BUILD

sub import {
  return Function::Parameters->import(settings(@_));
}

sub settings {
  my ($class, @args) = @_;

  # reifier config
  my $caller = caller(1);
  my @config = ($class, sub { unshift @_, $caller; goto \&reify });

  # for backwards compat
  @args = grep !/^:/, @args;
  namespace($caller, pop(@args)) if @args;

  # keyword config
  my %settings;

  %settings = (func_settings(@config), %settings);
  %settings = (meth_settings(@config), %settings);
  %settings = (befr_settings(@config), %settings);
  %settings = (aftr_settings(@config), %settings);
  %settings = (arnd_settings(@config), %settings);

  return {%settings};
}

sub func_settings {
  my ($class, $reifier) = @_;

  return (fun => {
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'function',
    invocant             => 1,
    name                 => 'optional',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    types                => 1,
  });
}

sub meth_settings {
  my ($class, $reifier) = @_;

  return (method => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    invocant             => 1,
    name                 => 'optional',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => '$self',
    types                => 1,
  });
}

sub aftr_settings {
  my ($class, $reifier) = @_;

  return (after => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'after',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => '$self',
    types                => 1,
  });
}

sub befr_settings {
  my ($class, $reifier) = @_;

  return (before => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'before',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => '$self',
    types                => 1,
  });
}

sub arnd_settings {
  my ($class, $reifier) = @_;

  return (around => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'around',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => ['$orig', '$self'],
    types                => 1,
  });
}

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Config::Signatures

=cut

=head1 ABSTRACT

Data-Object Signatures Configuration

=cut

=head1 SYNOPSIS

  use Data::Object::Config::Signatures;

  fun hello (Str $name) {
    return "Hello $name, how are you?";
  }

=cut

=head1 DESCRIPTION

Data::Object::Config::Signatures is a subclass of L<Type::Tiny::Signatures> providing
method and function signatures supporting all the type constraints provided by
L<Data::Object::Config::Type>.

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 settings

  my $settings = settings();

The settings function returns the settings for Function::Parameters
configuration.

=cut

=head2 func_settings

  my $func_settings = func_settings();

The func_settings function returns the fun-keyword configuration.

=cut

=head2 meth_settings

  my $meth_settings = meth_settings();

The meth_settings function returns the method-keyword configuration.

=cut

=head2 aftr_settings

  my $aftr_settings = aftr_settings();

The aftr_settings function returns the after-keyword configuration.

=cut

=head2 befr_settings

  my $befr_settings = befr_settings();

The befr_settings function returns the before-keyword configuration.

=cut

=head2 arnd_settings

  my $arnd_settings = arnd_settings();

The arnd_settings function returns the around-keyword configuration.

=cut
