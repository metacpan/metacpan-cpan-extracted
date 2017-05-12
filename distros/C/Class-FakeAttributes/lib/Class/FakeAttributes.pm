package Class::FakeAttributes;
our $VERSION = 0.01;

=head1 NAME

Class::FakeAttributes - Provide fake attributes for non-hash-based objects

=head1 SYNOPSIS

  use base qw<Class::FakeAttributes Some::Other::Module>;
  
  sub something
  {
    my ($self, $whatever) = @_;

    $self->set_attribute(motto => $whatever);
    my $size = $self->get_attribute('size');
    # etc

=head1 WARNING

This is version 0.01.  It exists for discussion.  Do not rely on it.
Everything is subject to change, including the module's functionality, API,
name, and even its existence.  Comments are welcome on the
S<module-authors@perl.org> mailing list.

=head1 DESCRIPTION

Most Perl classes use hash-based objects, and subclasses can easily add more
attributes (instance data) with new hash keys.  But some classes are not based
on hashes.  A subclass of such a class can use C<Class::FakeAttributes> to add
attributes (or at least to emulate doing so).

C<Class::FakeAttributes> is a mixin class: the only sensible use is to inherit
from it, and it only makes sense to do that when also inheriting from something
else as well.

=cut

use strict;
use warnings;

use NEXT;


# global hash for all attributes of all objects that use this (regardless of
# their class), keyed by the stringification of objects' blessed references:
our %attribute;

=head1 METHODS

=head2 C<set_attribute()>

Use C<set_attribute()> to set an attribute on an object.  Where with a
hash-based object you would have written:

  $self->{key} = $value;

instead write:

  $self->set_attribute(key => $value);

=cut

sub set_attribute
{
  my ($self, $key, $val) = @_;

  $attribute{$self}{$key} = $val;

}

=head2 C<get_attribute()>

Get the value of an attribute (set by C<set_attribute()>) with
C<get_attribute()>.  Instead of this hash-based code:

  my $value = $self->{key};

do:

  my $value = $self->get_attribute('key');

=cut

sub get_attribute
{
  my ($self, $key) = @_;

  $attribute{$self}{$key};
}

=head2 C<push_attribute()>

For an attribute that has a list of values, append to that list with
C<push_attribute()>.  Instead of this hash-based code:

  push @{$self->{key}}, $value;

do:

  $self->push_attribute(key => $value);

Multiple values can be pushed at once:

  $self->push_attribute(food => @fruit);

=cut

sub push_attribute
{
  my ($self, $key, @val) = @_;

  push @{$attribute{$self}{$key}}, @val;

}

=head2 C<attribute_list()>

Retrieve the list of all values for a key with C<attribute_list>.  Instead of
this hash-based code:

  foreach (@{$self->{key})

do:

  foreach ($self->attribute_list('key'))

=cut

sub attribute_list
{
  my ($self, $key) = @_;

  # If $self doesn't have any attributes then don't complain, just return an
  # empty list (same as if it has some attributes but just not any with key
  # $key):
  no warnings 'uninitialized';
  @{$attribute{$self}{$key}};
}

=head1 MEMORY LEAKAGE

The memory used to store an object's attributes is freed in a C<DESTROY> method
provided by C<Class::FakeAttributes>.  If C<DESTROY> doesn't get called then
memory will be leaked.  The best way to ensure memory gets freed up properly is
to put C<Class::FakeAttributes> at the start of the inheritance list.  That is,
don't do this:

  use base qw<Class::FakeAttributes Some::Other::Module>;

do this:

  use base qw<Some::Other::Module Class::FakeAttributes>;

C<Class::FakeAttributes> uses L<the C<NEXT> module|NEXT> to ensure that, so
long as it is listed first, any C<DESTROY> method in other superclasses will
also be invoked.

=cut

sub DESTROY
{
  my ($self) = @_;

  # Free up the memory used for the attributes of this object:
  delete $attribute{$self};

  # Invoke any other DESTROY() method that would've been called had this class
  # not existed:
  $self->NEXT::DISTINCT::DESTROY;

}


1;

=head1 AUTHOR

Smylers <smylers@cpan.org>

=head1 COPYRIGHT

E<169> Copyright Smylers 2003.  All rights reserved.  This module is software
libre.  It may be used, redistributed, or modified under the terms of the
Artistic License (the unnumbered version that comes with Perl 5.6.1, among
others) or the GNU General Public License version 2.
