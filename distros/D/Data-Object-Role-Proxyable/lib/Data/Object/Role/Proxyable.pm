package Data::Object::Role::Proxyable;

use 5.014;

use strict;
use warnings;

use Moo::Role;

our $VERSION = '2.03'; # VERSION

# METHODS

sub AUTOLOAD {
  require Carp;

  my ($package, $method) = our $AUTOLOAD =~ m[^(.+)::(.+)$];

  my $build = $package->can('BUILDPROXY');

  my $error = qq(Can't locate object method "$method" via package "$package");

  Carp::confess($error) unless $build && ref($build) eq 'CODE';

  my $proxy = $build->($package, $method, @_);

  Carp::confess($error) unless $proxy && ref($proxy) eq 'CODE';

  goto &$proxy;
}

sub BUILDPROXY {
  my ($package, $method, $self, @args) = @_;

  require Carp;

  my $build = $self->can('build_proxy');

  return $build->($self, $package, $method, @args) if $build;

  Carp::confess(qq(Can't locate object method "build_proxy" via package "$package"));
}

sub DESTROY {

  return;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Proxyable

=cut

=head1 ABSTRACT

Proxyable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Proxyable';

  sub build_proxy {
    my ($self, $package, $method, @args) = @_;

    if ($method eq 'true') {
      return sub {
        return 1;
      }
    }

    if ($method eq 'false') {
      return sub {
        return 0;
      }
    }

    return undef;
  }

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides a wrapper around the C<AUTOLOAD> routine which processes
calls to routines which don't exist. Adding a C<build_proxy> method to the
consuming class acts as a hook into routine dispatching, which processes calls
to routines which don't exist. The C<build_proxy> routine is called as a method
and receives C<$self>, C<$package>, C<$method>, and any arguments passed to the
method as a list of arguments, e.g. C<@args>. The C<build_proxy> method must
return a routine (i.e. a callback) or the undefined value which results in a
"method missing" error.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-proxyable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-proxyable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-proxyable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-proxyable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-proxyable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-proxyable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-proxyable/issues>

=cut
