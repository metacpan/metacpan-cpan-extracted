package DBIx::Class::QueryLog::WithStackTrace::Query;

use Moose;

our $VERSION = '1.0';

extends 'DBIx::Class::QueryLog::Query';

has stacktrace => (
  is  => 'rw',
  isa => 'Devel::StackTrace',
);

=head1 NAME

DBIx::Class::QueryLog::WithStackTrace::Query

=head1 DESCRIPTION

A trivial subclass of DBIx::Class::QueryLog::Query that allows for
the storing of a stacktrace as well as everything that the parent
class handles.

=head1 METHODS

The only extra method compared to the parent is:

=head2 stacktrace

a Devel::StackTrace object

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2012 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
