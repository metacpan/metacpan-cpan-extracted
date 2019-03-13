package Data::Object::Role::Proxyable;

use strict;
use warnings;

use Data::Object::Role;

use Carp ();

# BUILD

sub AUTOLOAD {
  my ($self) = @_;

  my (@namespace) = our $AUTOLOAD =~ /^(.+)::(.+)$/;

  my ($package, $method) = @namespace;

  my $build = $package->can('BUILDPROXY');

  my $error = qq(Can't locate object method "$method" via package "$package");

  Carp::croak($error) unless $build && ref($build) eq 'CODE';

  my $proxy = $build->($package, $method, @_);

  Carp::croak($error) unless $proxy && ref($proxy) eq 'CODE';

  goto &$proxy;
}

sub DESTROY {
  return;
}

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Proxyable

=cut

=head1 ABSTRACT

Data-Object Proxyable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Proxyable';

  sub BUILDPROXY {

    my ($class, $method, @args) = @_;

    return if $method eq 'execute'; # die with method missing error

    return sub { time }; # process method call

  }

=cut

=head1 DESCRIPTION

Data::Object::Role::Proxyable provides a mechanism for operating on Perl 5
data objects which meet the criteria for being proxyable. This role provides a
wrapper around the AUTOLOAD routine which processes calls to routines which
don't exist.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 autoload

  $self->AUTOLOAD($class, $method, @args);

The AUTOLOAD method is called when the object doesn't have the method being
called. This method is called and handled automatically.

=cut

=head2 destroy

  $self->DESTROY();

The DESTROY method is called when the object goes out of scope. This method is
called and handled automatically.

=cut
