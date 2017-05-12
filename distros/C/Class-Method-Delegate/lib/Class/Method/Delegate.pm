package Class::Method::Delegate;

use 5.010000;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

our $VERSION = '1.03';

sub import {
  my $class = shift;
  no strict 'refs';

  my $caller = caller;
  # Wants delegate
  *{"${caller}::delegate"} = sub { delegate($caller, @_) };

  strict->import;
}

sub delegate {
  my $class = shift;
  my $options = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
  my ($methods, $object, $handlers);

  if (exists $options->{'methods'}) {
    $methods = $options->{'methods'};
    croak 'methods undefined' unless $methods;
    croak 'methods not arrayref' unless ref($methods) eq 'ARRAY';
    croak 'methods empty' if 0 == @$methods;
  } else {
    croak "Can't delegate without methods";
  }
  if (exists $options->{'to'}) {
      $object = $options->{'to'};
      croak 'to undefined' unless $object;
      croak 'to not coderef' unless ref($object) eq 'CODE';
  } else {
      croak "Can't delegate without an object";
  }
  if (exists $options->{'class'}) {
    $class = $options->{'class'};
    croak 'class undefined or empty' unless $class;
  }
  if (exists $options->{'handlers'}) {
      $handlers = $options->{'handlers'};
      croak 'handlers undefined' unless $handlers;
      croak 'handlers not arrayref' unless ref($handlers) eq 'ARRAY';
      croak 'too few handlers' if @$handlers < @$methods;
      croak 'too many handlers' if @$handlers > @$methods;
  } else {
      $handlers = $methods;
  }

  no strict 'refs';
  #Inject a method 
  my $i = 0;
  for my $method (@$methods) {
    my $handler = $handlers->[$i++];
    *{"${class}::$method"} = sub {
      my $self = shift;
      my $delegation_object = &$object($self);
      croak "You are trying to delegate to something that is not an object" unless blessed( $delegation_object );
      if($delegation_object->can('delegated_by')) {
        $delegation_object->delegated_by($self);
      }
      $delegation_object->$handler(@_);
    }
  }
  strict->import;
}

1;
__END__

=head1 NAME

Class::Method::Delegate - Perl extension to help you add delegation to your classes

=head1 SYNOPSIS

  use Class::Method::Delegate;
  use Package::To::Delegate::To;
  delegate methods => [ 'hello', 'goodbye' ], to => sub { Package::To::Delegate::To->new() };
  delegate methods => [ 'wave' ], to => sub { shift->{gestures} };
  delegate methods => [ 'walk', 'run' ], to => sub { self->{movements} ||= Package::To::Delegate::To->new() };

  delegate methods => [ 'walk', 'run' ], to => \&some_subroutine, handlers => [ 'slow', 'fast' ];

=head1 DESCRIPTION

Creates methods on the current class which delegate to an object.

delegate takes a hash or hashref with the following keys.

methods

Takes an array ref of strings that represent the name of the method to be delegated.

to

a sub block that returns an object, which the method calls will be sent to.

=head2 Accessing the parent from inside the delegated class.

If the object you are delegating to has a method called delegated_by, then this will be called when delegating.
The $self of the package doing the delegating will be passed in, so you can then store it.

=head2 EXPORT

delegate

=head1 SEE ALSO

Check out Class:Delegator and Class::Delegation for alternatives.

=head1 AUTHOR

Jonathan Taylor, E<lt>jon@stackhaus.comE<gt>

Version 1.03 contributed by James Buster

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jonathan Taylor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
