package Rose::Class;

use strict;

our $VERSION = '0.81';

use Rose::Class::MakeMethods::Generic
(
  scalar => 'error',
);

1;

__END__

=head1 NAME

Rose::Class - A very simple class base class.

=head1 SYNOPSIS

    package MyClass;

    use Rose::Class;
    our @ISA = qw(Rose::Class);

    sub foo { ... }
    ...

    MyClass->foo(...) or die MyClass->error;
    ...

=head1 DESCRIPTION

L<Rose::Class> is a generic base class for classes.  It provides a
single class method (C<error>), but may be expanded further in the
future.

A class that inherits from L<Rose::Class> is not expected to allow
objects of that class to be instantiated, since the namespace for class
and object methods is shared.  For example, it is common for
L<Rose::Object>-derived classes to have C<error> methods, but this would
conflict with the L<Rose::Class> method of the same name.

=head1 CLASS METHODS

=over 4

=item B<error [ERROR]>

Get or set the class-wide error.  By convention, this should be a scalar
that stringifies to an error message.  A simple scalar containing a
string is the most commonly used value.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
