package Catalyst::Model::DataHash;

use Moo;
our $VERSION = '0.001';

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';
with 'Data::Perl::Role::Collection::Hash';

sub build_per_context_instance {
  my ($self, $c, %args) = @_;
  return $self->new(%args);
}

around 'set', sub {
  my ($orig, $self, %args) = @_;
  foreach my $key (keys %args) {
    die "'$key' already has a value: Can't set it again!"
      if $self->exists($key);
  }

  return $self->$orig(%args);
};

around 'get', sub {
  my ($orig, $self, @args) = @_;
  foreach my $arg(@args) {
    die "'$arg' has not yet been set: Can't get it!"
      unless $self->exists($arg);
  }

  return $self->$orig(@args);
};

around 'delete', sub {
  my ($orig, $self, @args) = @_;
  foreach my $arg(@args) {
    die "'$arg' has not yet been set: Can't delete it!"
      unless $self->exists($arg);
  }

  return $self->$orig(@args);
};

around 'accessor', sub {
  my ($orig, $self, $key, $maybe_value) = @_;
  if(defined($key) && defined($maybe_value)) {
    # attempt to set.  Make sure doesn't already exist
    die "'$key' already has a value"
      if $self->exists($key);
  } elsif(defined($key)) {
    # attempt to get. Make sure there really is a value.
    die "'$key' has not yet been set: Can't get it!"
      unless $self->exists($key);
  }

  return $self->$orig($key, $maybe_value);
};

sub TO_JSON { +{shift->elements} }

sub AUTOLOAD {
  my ($self, @args) = @_;
  my $key = our $AUTOLOAD;
  $key =~ s/.*:://;
  return $self->get($key);
}
 
sub DESTROY {}

1;

=head1 NAME

Catalyst::Model::DataHash - Expose Perl::Data::Collection::Hash as a Per Request Model

=head1 SYNOPSIS

Create a Model Subclass:

    package MyApp::Model::Foo;

    use Moose;
    extends 'Catalyst::Model::DataHash';

    __PACKAGE__->meta->make_immutable;

Use it in a controller:

    sub myaction :Local {
      my ($self, $c) = @_;

      # Default API
      $c->model('DataHash')->set(a=>1, b=>2);
      $c->model('DataHash')->get('a'); # 1
      $c->model('DataHash')->get('b'); # 2

      # Alternative accessors
      $c->model('DataHash')->a; # 1

      # RAISES AN EXCEPTION
      $c->model('DataHash')->not_yet_set;
      $c->model('DataHash')->set(a=>'already set...');
    }

You might find it useful to make this your default model:

    MyApp->config(default_model=>'DataHash');

So that you can use this without naming the model:

    sub myaction :Local {
      my ($self, $c) = @_;
      $c->model->set(a=>1, b=>2);
      $c->model->get('a'); # 1
      $c->model->get('b'); # 2

      #alternative accessors
      $c->model->a; # 1
    }

Which makes it less verbose.  Alternatively you can use the included plugin
L<Catalyst::Plugin::DataHash> which injects a DataHash model for you into your
application, and sets it to be the default model:

    package MyApp;

    use Catalyst qw/DataHash/;

    MyApp->setup;

Then you can just do (in an action):

    sub myaction :Local {
      my ($self, $c) = @_;
      $c->model->set(a=>1);
    }

=head1 DESCRIPTION

The most common way that a controller shares information between actions and the
view is to set key / values in the stash:

    $c->stash(a=>1, b=>2);

The stash suffers from several downsides, some of which include the fact it is
a global hash and is prone to typos and related confusion, like how it can auto-vivify
a stash key when a value does not already exist.  This L<Catalyst>
model offers an approach to providing stash-like features with a slightly less
error prone interface.  It is also hoped that it might inspire you to think about
how to better use models in your L<Catalyst> application to properly type your
interfaces.  It wraps L<Perl::Data>, specifically L<Data::Perl::Collection::Hash>
and addes a bit of error checking and a method it ease integration with JSON encoders.

This is a 'per-request' Catalyst model, which means that each new request can get one
model for use during the request duration.

=head1 METHODS

This model provides the following methods, most of which are delegated to 
L<Data::Perl::Collection::Hash>. Most of this documention following is copied verbosely
from that distribution.  When we'd adapted functionality, this is noted.

=head2 set($key => $value, $key2 => $value2...)

Sets the elements in the hash to the given values. It returns the new values set for each
key, in the same order as the keys passed to the method.

This method requires at least two arguments, and expects an even number of arguments.

B<Added Behavior>: If you try to set a key that already exists, this will raise an exception.

=head2 get($key1, $key2, ...)

Returns a list of values in the hash for the given keys.

This method requires at least one argument.

B<Added Behavior>: If you try to get a key that has not already been set, this will raise an
exception.

=head2 keys

Returns the list of keys in the hash.

This method does not accept any arguments.

=head2 delete($key, $key2, $key3...)
Removes the elements with the given keys.

Returns a list of values in the hash for the deleted keys.

B<Added Behavior>: If you try to delete a key that has not already been set, this will raise an
exception.

=head2 exists($key)

Returns true if the given key is present in the hash.

This method requires a single argument.

=head2 defined($key)

Returns true if the value of a given key is defined.

This method requires a single argument.

=head2 values

Returns the list of values in the hash.

This method does not accept any arguments.

=head2 kv

Returns the key/value pairs in the hash as an array of array references.

    for my $pair ( $object->option_pairs ) {
        print "$pair->[0] = $pair->[1]\n";
    }

This method does not accept any arguments.

=head2 elements/all

Returns the key/value pairs in the hash as a flattened list..

This method does not accept any arguments.

=head2 clear

Resets the hash to an empty value, like %hash = ().

This method does not accept any arguments.

=head2 count

Returns the number of elements in the hash.

This method does not accept any arguments.

=head2 accessor($key)

=head2 accessor($key, $value)

If passed one argument, returns the value of the specified key. 
If passed two arguments, sets the value of the specified key.

B<Added Behavior>: If you try to get a key that has not already been set, this will raise an
exception.  If you try to set a key that has already been set, it will raise an exception.

=head2 shallow_clone
This method returns a shallow clone of the hash reference. The return value is a 
reference to a new hash with the same keys and values. It is shallow because any values
that were references in the original will be the same references in the clone.

=head2 TO_JSON

Returns a hashref of all the existing data suitable to send to a JSON serializer.

=head1 SEE ALSO

L<Catalyst>, L<Data::Perl>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
