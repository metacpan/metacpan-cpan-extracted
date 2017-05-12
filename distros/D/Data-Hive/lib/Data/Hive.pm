use strict;
use warnings;
package Data::Hive;
# ABSTRACT: convenient access to hierarchical data
$Data::Hive::VERSION = '1.013';
use Carp ();

#pod =head1 SYNOPSIS
#pod
#pod   use Data::Hive;
#pod
#pod   my $hive = Data::Hive->NEW(\%arg);
#pod
#pod   $hive->foo->bar->quux->SET(17);
#pod
#pod   print $hive->foo->bar->quux->GET;  # 17
#pod
#pod =head1 DESCRIPTION
#pod
#pod Data::Hive doesn't do very much.  Its main purpose is to provide a simple,
#pod consistent interface for accessing simple, nested data dictionaries.  The
#pod mechanism for storing or consulting these dictionaries is abstract, so it can
#pod be replaced without altering any of the code that reads or writes the hive.
#pod
#pod A hive is like a set of nested hash references, but with a few crucial
#pod differences:
#pod
#pod =begin :list
#pod
#pod * a hive is always accessed by methods, never by dereferencing with C<< ->{} >>
#pod
#pod For example, these two lines perform similar tasks:
#pod
#pod   $href->{foo}->{bar}->{baz}
#pod
#pod   $hive->foo->bar->baz->GET
#pod
#pod * every key may have a value as well as children
#pod
#pod With nested hashrefs, each entry is either another hashref (representing
#pod children in the tree) or a leaf node.  With a hive, each entry may be either or
#pod both.  For example, we can do this:
#pod
#pod   $hive->entry->SET(1);
#pod
#pod   $hive->entry->child->SET(1)
#pod
#pod This wouldn't be possible with a hashref, because C<< $href->{entry} >> could
#pod not hold both another node and a simple value.
#pod
#pod It also means that along the ways to existing values in a hive, there might be
#pod paths with no existing value.
#pod
#pod   $hive->NEW(...);                  # create a new hive with no entries
#pod
#pod   $hive->foo->bar->baz->SET(1);     # set a single value
#pod
#pod   $hive->foo->EXISTS;               # false!  no value exists here
#pod
#pod   grep { 'foo' eq $_ } $hive->KEYS; # true!   we can descent down this path
#pod
#pod   $hive->foo->bar->baz->EXISTS;     # true!   there is a value here
#pod
#pod * hives are accessed by path, not by name
#pod
#pod When you call C<< $hive->foo->bar->baz->GET >>, you're not accessing several
#pod substructures.  You're accessing I<one> hive.  When the C<GET> method is
#pod reached, the intervening names are converted into an entry path and I<that> is
#pod accessed.  Paths are made of zero or more non-empty strings.  In other words,
#pod while this is legal:
#pod
#pod   $href->{foo}->{''}->baz;
#pod
#pod It is not legal to have an empty part in a hive path.
#pod
#pod =end :list
#pod
#pod =head1 WHY??
#pod
#pod By using method access, the behavior of hives can be augmented as needed during
#pod testing or development.  Hives can be easily collapsed to single key/value
#pod pairs using simple notations whereby C<< $hive->foo->bar->baz->SET(1) >>
#pod becomes C<< $storage->{"foo.bar.baz"} = 1 >> or something similar.
#pod
#pod This, along with the L<Data::Hive::Store> API makes it very easy to swap out
#pod the storage and retrieval mechanism used for keeping hives in persistent
#pod storage.  It's trivial to persist entire hives into a database, flatfile, CGI
#pod query, or many other structures, without using weird tricks beyond the weird
#pod trick that is Data::Hive itself.
#pod
#pod =head1 METHODS
#pod
#pod =head2 hive path methods
#pod
#pod All lowercase methods are used to travel down hive paths.
#pod
#pod When you call C<< $hive->some_name >>, the return value is another Data::Hive
#pod object using the same store as C<$hive> but with a starting path of
#pod C<some_name>.  With that hive, you can descend to deeper hives or you can get
#pod or set its value.
#pod
#pod Once you've reached the path where you want to perform a lookup or alteration,
#pod you call an all-uppercase method.  These are detailed below.
#pod
#pod =head2 hive access methods
#pod
#pod These methods are thin wrappers around required modules in L<Data::Hive::Store>
#pod subclasses.  These methods all basically call a method on the store with the
#pod same (but lowercased) name and pass it the hive's path.
#pod
#pod =head3 NEW
#pod
#pod This constructs a new hive object.  Note that the name is C<NEW> and not
#pod C<new>!  The C<new> method is just another method to pick a hive path part.
#pod
#pod The following are valid arguments for C<NEW>.
#pod
#pod =begin :list
#pod
#pod = store
#pod
#pod a L<Data::Hive::Store> object, or one with a compatible interface; this will be
#pod used as the hive's backend storage driver;  do not supply C<store_class> or
#pod C<store_args> if C<store> is supplied
#pod
#pod = store_class
#pod
#pod This names a class from which to instantiate a storage driver.  The classname
#pod will have C<Data::Hive::Store::> prepended; to avoid this, prefix it with a '='
#pod (C<=My::Store>).  A plus sign can be used instead of an equal sign, for
#pod historical reasons.
#pod
#pod = store_args
#pod
#pod If C<store_class> has been provided instead of C<store>, this argument may be
#pod given as an arrayref of arguments to pass (dereferenced) to the store class's
#pod C<new> method.
#pod
#pod =end :list
#pod
#pod =cut

sub NEW {
  my ($invocant, $arg) = @_;
  $arg ||= {};

  my @path = @{ $arg->{path} || [] };

  my $class = ref $invocant ? ref $invocant : $invocant;
  my $self = bless { path => \@path } => $class;

  if ($arg->{store_class}) {
    die "don't use 'store' with 'store_class' and 'store_args'"
      if $arg->{store};

    $arg->{store_class} = "Data::Hive::Store::$arg->{store_class}"
      unless $arg->{store_class} =~ s/^[+=]//;

    $self->{store} = $arg->{store_class}->new(@{ $arg->{store_args} || [] });
  } elsif ($arg->{store}) {
    $self->{store} = $arg->{store};
  } else {
    Carp::croak "can't create a hive with no store";
  }

  return $self;
}

#pod =head3 GET
#pod
#pod   my $value = $hive->some->path->GET( $default );
#pod
#pod The C<GET> method gets the hive value.  If there is no defined value at the
#pod path and a default has been supplied, the default will be returned instead.
#pod
#pod C<$default> should be a simple scalar or a subroutine.  If C<$default> is a
#pod subroutine, it will be called to compute the default only if needed.  The
#pod behavior for other types of defaults is undefined.
#pod
#pod =head4 overloading
#pod
#pod Hives are overloaded for stringification and numification so that they behave
#pod like their value when used without an explicit C<GET>.  This behavior is
#pod deprecated and will be removed in a future release.  Always use C<GET> to get
#pod the value of a hive.
#pod
#pod =cut

use overload (
  q{""}    => sub {
    Carp::carp "using hive as string for implicit GET is deprecated";
    shift->GET(@_);
  },
  q{0+}    => sub {
    Carp::carp "using hive as number for implicit GET is deprecated";
    shift->GET(@_);
  },
  fallback => 1,
);

sub GET {
  my ($self, $default) = @_;
  my $value = $self->STORE->get($self->{path});
  return defined $value     ? $value
       : ! defined $default ? undef
       : ref $default       ? $default->()
       :                      $default;
}

#pod =head3 SET
#pod
#pod   $hive->some->path->SET(10);
#pod
#pod This method sets (replacing, if necessary) the hive value.
#pod
#pod Data::Hive was built to store simple scalars as values.  Although it
#pod I<probably> works just fine with references in the hive, it has not been
#pod tested for such use, and there may be bugs lurking in there.
#pod
#pod C<SET>'s return value is not defined.
#pod
#pod =cut

sub SET {
  my $self = shift;
  return $self->STORE->set($self->{path}, @_);
}

#pod =head3 EXISTS
#pod
#pod   if ($hive->foo->bar->EXISTS) { ... }
#pod
#pod This method tests whether a value (even an undefined one) exists for the hive.
#pod
#pod =cut

sub EXISTS {
  my $self = shift;
  return $self->STORE->exists($self->{path});
}

#pod =head3 DELETE
#pod
#pod   $hive->foo->bar->DELETE;
#pod
#pod This method deletes the hive's value.  The deleted value is returned.  If no
#pod value had existed, C<undef> is returned.
#pod
#pod =cut

sub DELETE {
  my $self = shift;
  return $self->STORE->delete($self->{path});
}

#pod =head3 DELETE_ALL
#pod
#pod This method behaves like C<DELETE>, but all values for paths below the current
#pod one will also be deleted.
#pod
#pod =cut

sub DELETE_ALL {
  my $self = shift;
  return $self->STORE->delete_all($self->{path});
}

#pod =head3 KEYS
#pod
#pod   my @keys = $hive->KEYS;
#pod
#pod This returns a list of next-level path elements that exist.  For example, given
#pod a hive with values for the following paths:
#pod
#pod   foo
#pod   foo/bar
#pod   foo/bar/baz
#pod   foo/xyz/abc
#pod   foo/xyz/def
#pod   foo/123
#pod
#pod This shows the expected results:
#pod
#pod   keys of      | returns
#pod   -------------+------------
#pod   foo          | bar, xyz, 123
#pod   foo/bar      | baz
#pod   foo/bar/baz  |
#pod   foo/xyz      | abc, def
#pod   foo/123      |
#pod
#pod =cut

sub KEYS {
  my ($self) = @_;
  return $self->STORE->keys($self->{path});
}

#pod =head3 COPY_ONTO
#pod
#pod   $hive->foo->COPY_ONTO( $another_hive->bar );
#pod
#pod This method copies all the existing values found at or under the current path
#pod to another Data::Hive, using either the same or a different store.
#pod
#pod Currently, this will set each found value individually.  In the future, store
#pod classes should have the ability to receive a bulk-set message to operate in a
#pod transaction, if appropriate.
#pod
#pod =cut

sub COPY_ONTO {
  my ($self, $target) = @_;

  $target->SET( $self->GET ) if $self->EXISTS;

  for my $key ($self->KEYS) {
    $self->HIVE($key)->COPY_ONTO( $target->HIVE($key) );
  }
}

#pod =head3 HIVE
#pod
#pod   $hive->HIVE('foo');          #  equivalent to $hive->foo
#pod
#pod   $hive->HIVE('foo', 'bar');   #  equivalent to $hive->foo->bar
#pod
#pod This method returns a subhive of the current hive.  In most cases, it is
#pod simpler to use the lowercase hive access method.  This method is useful when
#pod you must, for some reason, access an entry whose name is not a valid Perl
#pod method name.
#pod
#pod It is also needed if you must access a path with the same name as a method in
#pod C<UNIVERSAL>.  In general, only C<import>, C<isa>, and C<can> should fall into
#pod this category, but some libraries unfortunately add methods to C<UNIVERSAL>.
#pod Common offenders include C<moniker>, C<install_sub>, C<reinstall_sub>.
#pod
#pod This method should be needed fairly rarely.  It may also be called as C<ITEM>
#pod for historical reasons.
#pod
#pod =cut

sub ITEM {
  my ($self, @rest) = @_;
  return $self->HIVE(@rest);
}

sub HIVE {
  my ($self, @keys) = @_;

  my @illegal = map  { $_ = '(undef)' if ! defined }
                grep { ! defined or ! length or ref } @keys;

  Carp::croak "illegal hive path parts: @illegal" if @illegal;

  return $self->NEW({
    %$self,
    path => [ @{$self->{path}}, @keys ],
  });
}

#pod =head3 NAME
#pod
#pod This method returns a name that can be used to represent the hive's path.  This
#pod name is B<store-dependent>, and should not be relied upon if the store may
#pod change.  It is provided primarily for debugging.
#pod
#pod =cut

sub NAME {
  my $self = shift;
  return $self->STORE->name($self->{path});
}

#pod =head3 ROOT
#pod
#pod This returns a Data::Hive object for the root of the hive.
#pod
#pod =cut

sub ROOT {
  my $self = shift;

  return $self->NEW({
    %$self,
    path => [ ],
  });
}

#pod =head3 SAVE
#pod
#pod This method tells the hive store to save the value (or lack thereof) for the
#pod current path.  For many stores, this does nothing.  For hive stores that are
#pod written out only on demand, this method must be called.
#pod
#pod =cut

sub SAVE {
  my ($self) = @_;

  $self->STORE->save($self->{path});
}

#pod =head3 SAVE_ALL
#pod
#pod This method tells the hive store to save the value (or lack thereof) for the
#pod current path and all paths beneath it.  For many stores, this does nothing.
#pod For hive stores that are written out only on demand, this method must be
#pod called.
#pod
#pod =cut

sub SAVE_ALL {
  my ($self) = @_;

  $self->STORE->save_all($self->{path});
}

#pod =head3 STORE
#pod
#pod This method returns the storage driver being used by the hive.
#pod
#pod =cut

sub STORE {
  return $_[0]->{store}
}

sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;

  (my $method = $AUTOLOAD) =~ s/.*:://;
  die "AUTOLOAD for '$method' called on non-object" unless ref $self;

  return if $method eq 'DESTROY';

  if ($method =~ /^[A-Z_]+$/) {
    Carp::croak("all-caps method names are reserved: '$method'");
  }

  Carp::cluck("arguments passed to autoloaded Data::Hive descender") if @_;

  return $self->HIVE($method);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Hive - convenient access to hierarchical data

=head1 VERSION

version 1.013

=head1 SYNOPSIS

  use Data::Hive;

  my $hive = Data::Hive->NEW(\%arg);

  $hive->foo->bar->quux->SET(17);

  print $hive->foo->bar->quux->GET;  # 17

=head1 DESCRIPTION

Data::Hive doesn't do very much.  Its main purpose is to provide a simple,
consistent interface for accessing simple, nested data dictionaries.  The
mechanism for storing or consulting these dictionaries is abstract, so it can
be replaced without altering any of the code that reads or writes the hive.

A hive is like a set of nested hash references, but with a few crucial
differences:

=over 4

=item *

a hive is always accessed by methods, never by dereferencing with C<< ->{} >>

For example, these two lines perform similar tasks:

  $href->{foo}->{bar}->{baz}

  $hive->foo->bar->baz->GET

=item *

every key may have a value as well as children

With nested hashrefs, each entry is either another hashref (representing
children in the tree) or a leaf node.  With a hive, each entry may be either or
both.  For example, we can do this:

  $hive->entry->SET(1);

  $hive->entry->child->SET(1)

This wouldn't be possible with a hashref, because C<< $href->{entry} >> could
not hold both another node and a simple value.

It also means that along the ways to existing values in a hive, there might be
paths with no existing value.

  $hive->NEW(...);                  # create a new hive with no entries

  $hive->foo->bar->baz->SET(1);     # set a single value

  $hive->foo->EXISTS;               # false!  no value exists here

  grep { 'foo' eq $_ } $hive->KEYS; # true!   we can descent down this path

  $hive->foo->bar->baz->EXISTS;     # true!   there is a value here

=item *

hives are accessed by path, not by name

When you call C<< $hive->foo->bar->baz->GET >>, you're not accessing several
substructures.  You're accessing I<one> hive.  When the C<GET> method is
reached, the intervening names are converted into an entry path and I<that> is
accessed.  Paths are made of zero or more non-empty strings.  In other words,
while this is legal:

  $href->{foo}->{''}->baz;

It is not legal to have an empty part in a hive path.

=back

=head1 WHY??

By using method access, the behavior of hives can be augmented as needed during
testing or development.  Hives can be easily collapsed to single key/value
pairs using simple notations whereby C<< $hive->foo->bar->baz->SET(1) >>
becomes C<< $storage->{"foo.bar.baz"} = 1 >> or something similar.

This, along with the L<Data::Hive::Store> API makes it very easy to swap out
the storage and retrieval mechanism used for keeping hives in persistent
storage.  It's trivial to persist entire hives into a database, flatfile, CGI
query, or many other structures, without using weird tricks beyond the weird
trick that is Data::Hive itself.

=head1 METHODS

=head2 hive path methods

All lowercase methods are used to travel down hive paths.

When you call C<< $hive->some_name >>, the return value is another Data::Hive
object using the same store as C<$hive> but with a starting path of
C<some_name>.  With that hive, you can descend to deeper hives or you can get
or set its value.

Once you've reached the path where you want to perform a lookup or alteration,
you call an all-uppercase method.  These are detailed below.

=head2 hive access methods

These methods are thin wrappers around required modules in L<Data::Hive::Store>
subclasses.  These methods all basically call a method on the store with the
same (but lowercased) name and pass it the hive's path.

=head3 NEW

This constructs a new hive object.  Note that the name is C<NEW> and not
C<new>!  The C<new> method is just another method to pick a hive path part.

The following are valid arguments for C<NEW>.

=over 4

=item store

a L<Data::Hive::Store> object, or one with a compatible interface; this will be
used as the hive's backend storage driver;  do not supply C<store_class> or
C<store_args> if C<store> is supplied

=item store_class

This names a class from which to instantiate a storage driver.  The classname
will have C<Data::Hive::Store::> prepended; to avoid this, prefix it with a '='
(C<=My::Store>).  A plus sign can be used instead of an equal sign, for
historical reasons.

=item store_args

If C<store_class> has been provided instead of C<store>, this argument may be
given as an arrayref of arguments to pass (dereferenced) to the store class's
C<new> method.

=back

=head3 GET

  my $value = $hive->some->path->GET( $default );

The C<GET> method gets the hive value.  If there is no defined value at the
path and a default has been supplied, the default will be returned instead.

C<$default> should be a simple scalar or a subroutine.  If C<$default> is a
subroutine, it will be called to compute the default only if needed.  The
behavior for other types of defaults is undefined.

=head4 overloading

Hives are overloaded for stringification and numification so that they behave
like their value when used without an explicit C<GET>.  This behavior is
deprecated and will be removed in a future release.  Always use C<GET> to get
the value of a hive.

=head3 SET

  $hive->some->path->SET(10);

This method sets (replacing, if necessary) the hive value.

Data::Hive was built to store simple scalars as values.  Although it
I<probably> works just fine with references in the hive, it has not been
tested for such use, and there may be bugs lurking in there.

C<SET>'s return value is not defined.

=head3 EXISTS

  if ($hive->foo->bar->EXISTS) { ... }

This method tests whether a value (even an undefined one) exists for the hive.

=head3 DELETE

  $hive->foo->bar->DELETE;

This method deletes the hive's value.  The deleted value is returned.  If no
value had existed, C<undef> is returned.

=head3 DELETE_ALL

This method behaves like C<DELETE>, but all values for paths below the current
one will also be deleted.

=head3 KEYS

  my @keys = $hive->KEYS;

This returns a list of next-level path elements that exist.  For example, given
a hive with values for the following paths:

  foo
  foo/bar
  foo/bar/baz
  foo/xyz/abc
  foo/xyz/def
  foo/123

This shows the expected results:

  keys of      | returns
  -------------+------------
  foo          | bar, xyz, 123
  foo/bar      | baz
  foo/bar/baz  |
  foo/xyz      | abc, def
  foo/123      |

=head3 COPY_ONTO

  $hive->foo->COPY_ONTO( $another_hive->bar );

This method copies all the existing values found at or under the current path
to another Data::Hive, using either the same or a different store.

Currently, this will set each found value individually.  In the future, store
classes should have the ability to receive a bulk-set message to operate in a
transaction, if appropriate.

=head3 HIVE

  $hive->HIVE('foo');          #  equivalent to $hive->foo

  $hive->HIVE('foo', 'bar');   #  equivalent to $hive->foo->bar

This method returns a subhive of the current hive.  In most cases, it is
simpler to use the lowercase hive access method.  This method is useful when
you must, for some reason, access an entry whose name is not a valid Perl
method name.

It is also needed if you must access a path with the same name as a method in
C<UNIVERSAL>.  In general, only C<import>, C<isa>, and C<can> should fall into
this category, but some libraries unfortunately add methods to C<UNIVERSAL>.
Common offenders include C<moniker>, C<install_sub>, C<reinstall_sub>.

This method should be needed fairly rarely.  It may also be called as C<ITEM>
for historical reasons.

=head3 NAME

This method returns a name that can be used to represent the hive's path.  This
name is B<store-dependent>, and should not be relied upon if the store may
change.  It is provided primarily for debugging.

=head3 ROOT

This returns a Data::Hive object for the root of the hive.

=head3 SAVE

This method tells the hive store to save the value (or lack thereof) for the
current path.  For many stores, this does nothing.  For hive stores that are
written out only on demand, this method must be called.

=head3 SAVE_ALL

This method tells the hive store to save the value (or lack thereof) for the
current path and all paths beneath it.  For many stores, this does nothing.
For hive stores that are written out only on demand, this method must be
called.

=head3 STORE

This method returns the storage driver being used by the hive.

=head1 AUTHORS

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords hdp rjbs

=over 4

=item *

hdp <hdp@1bcdbe44-fcfd-0310-b51b-975661d93aa0>

=item *

rjbs <rjbs@1bcdbe44-fcfd-0310-b51b-975661d93aa0>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
