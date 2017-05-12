use strict;
use warnings;
package App::Addex::AddressBook;
# ABSTRACT: the address book that addex will consult
$App::Addex::AddressBook::VERSION = '0.026';
use App::Addex::Entry;

use Carp ();

#pod =method new
#pod
#pod   my $addr_book = App::Addex::AddressBook->new(\%arg);
#pod
#pod This method returns a new AddressBook.  Its implementation details are left up
#pod to the subclasses, but it must accept a hashref as its first argument.
#pod
#pod Valid arguments are:
#pod
#pod   addex - required; the App::Addex object using this address book
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;
  Carp::croak "no addex argument provided" unless $arg->{addex};
  bless { addex => $arg->{addex} } => $class;
}

#pod =method addex
#pod
#pod   my $addex = $addr_book->addex;
#pod
#pod This returns the App::Addex object with which the address book is associated.
#pod
#pod =cut

sub addex { $_[0]->{addex} }

#pod =method entries
#pod
#pod   my @entries = $addex->entries;
#pod
#pod This method returns the entries in the address book as L<App::Addex::Entry>
#pod objects.  Its behavior in scalar context is not yet defined.
#pod
#pod This method should be implemented by a address-book-implementation-specific
#pod subclass.
#pod
#pod =cut

sub entries {
  Carp::confess "no behavior defined for virtual method entries";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::AddressBook - the address book that addex will consult

=head1 VERSION

version 0.026

=head1 METHODS

=head2 new

  my $addr_book = App::Addex::AddressBook->new(\%arg);

This method returns a new AddressBook.  Its implementation details are left up
to the subclasses, but it must accept a hashref as its first argument.

Valid arguments are:

  addex - required; the App::Addex object using this address book

=head2 addex

  my $addex = $addr_book->addex;

This returns the App::Addex object with which the address book is associated.

=head2 entries

  my @entries = $addex->entries;

This method returns the entries in the address book as L<App::Addex::Entry>
objects.  Its behavior in scalar context is not yet defined.

This method should be implemented by a address-book-implementation-specific
subclass.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
