package Rose::Object;

use strict;

our $VERSION = '0.860';

sub new
{
  my($class) = shift;

  my $self = bless {}, $class;

  $self->init(@_);

  return $self;
}

sub init
{
  my($self) = shift;

  while(@_)
  {
    my $method = shift;
    $self->$method(shift);
  }
}

1;

__END__

=head1 NAME

Rose::Object - A simple object base class.

=head1 SYNOPSIS

    package MyObject;

    use Rose::Object;
    our @ISA = qw(Rose::Object);

    sub foo { ... }
    sub bar { ... }
    ...

    my $o = MyObject->new(foo => 'abc', bar => 5);
    ...

=head1 DESCRIPTION

L<Rose::Object> is a generic object base class.  It provides very little
functionality, but a healthy dose of convention.

=head1 METHODS

=over 4

=item B<new PARAMS>

Constructs a new, empty, hash-based object based on PARAMS, where PARAMS
are name/value pairs, and then calls L<init|/init> (see below), passing
PARAMS to it unmodified.

=item B<init PARAMS>

Given a list of name/value pairs in PARAMS, calls the object method of
each name, passing the corresponding value as an argument.  The methods
are called in the order that they appear in PARAMS.  For example:

    $o->init(foo => 1, bar => 2);

is equivalent to the sequence:

    $o->foo(1);
    $o->bar(2);

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
