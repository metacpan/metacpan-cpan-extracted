package Class::SingletonProxy;

our $VERSION = '0.01';

use 5.008;
use strict;
use warnings;
use Carp ();

our %target;

sub import {
    my $class = shift;
}

sub new { Carp::croak "new called on a singleton class" }

sub singleton {
    my $class = shift;
    @_ ? $target{$class} = shift : $target{$class}
}

sub SINGLETON {
    my $class = shift;
    Carp::croak("SINGLETON subroutine not defined in class $class");
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $class = $_[0];
    my ($method) = $AUTOLOAD =~ /([^:]*)$/;
    # print "autoloading ${class} -> ${method} ($AUTOLOAD)\n";
    no strict 'refs';
    *{$AUTOLOAD} =
	sub {
	    my $class = shift;
	    # print "class=$class target=$target{$class}\n";
	    my $self = $target{$class} ||=
		( $class->SINGLETON or Carp::croak "$class->SINGLETON returned undef" );
	    $self->$method(@_)
	};
    goto &{$AUTOLOAD};
}



1;
__END__


=head1 NAME

Class::SingletonProxy - proxy class methods to a singleton

=head1 SYNOPSIS

  package Foo;
  use base Class::SingletonProxy;

  sub SINGLETON {
      return Foo::Impl->new();
  }

  package main;

  Foo->hello;
  Foo->bar(1234);


=head1 DESCRIPTION

classes derived from Class::SingletonProxy redirect class methods to
(per class) singleton objects.

=head2 METHODS

=over 4

=item $class-E<gt>SINGLETON()

this method can be redefined on subclasses and is automatically called
to create the singleton when it has not been previously defined.

=item $class-E<gt>singleton()

=item $class-E<gt>singleton($singleton)

gets/sets the class singleton object.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
