package Data::DeepAccess;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Scalar::Util 'blessed';
use Sentinel 'sentinel';

our $VERSION = '0.002';

our @EXPORT_OK = qw(deep_exists deep_get deep_set deep_val);

sub deep_exists {
  croak 'deep_exists called with no arguments' unless @_;
  my ($parent, @keys) = @_;
  return !!1 unless @keys;
  foreach my $key_i (0..$#keys) {
    return !!0 unless defined $parent;
    my $reftype = ref $parent;
    my $blessed = blessed $parent;
    my $type = defined $blessed ? 'method' : lc $reftype;
    my $type_str = length $reftype ? "$reftype ref" : 'scalar value';
    my $key = $keys[$key_i];
    my $lvalue;
    if (ref $key eq 'HASH') {
      if (exists $key->{key}) {
        ($type, $key) = ('hash', $key->{key});
      } elsif (exists $key->{index}) {
        ($type, $key) = ('array', $key->{index});
      } elsif (exists $key->{method}) {
        ($type, $key) = ('method', $key->{method});
      } elsif (exists $key->{lvalue}) {
        ($type, $key, $lvalue) = ('method', $key->{lvalue}, 1);
      } else {
        croak q{Traversal key hashref must contain "key", "index", "method", or "lvalue"};
      }
    }
    if ($type eq 'hash') {
      croak qq{Can't dereference $type_str as HASH to access key "$key"} if !defined $blessed and $reftype ne 'HASH';
      return !!0 unless exists $parent->{$key};
      return !!1 if $key_i == $#keys;
      $parent = $parent->{$key};
    } elsif ($type eq 'array') {
      croak qq{Can't dereference $type_str as ARRAY to access index $key} if !defined $blessed and $reftype ne 'ARRAY';
      return !!0 unless exists $parent->[$key];
      return !!1 if $key_i == $#keys;
      $parent = $parent->[$key];
    } elsif ($type eq 'method') {
      croak qq{Can't call method "$key" on unblessed reference} if length $reftype and !defined $blessed;
      return !!0 unless my $sub = $parent->can($key);
      return !!1 if $key_i == $#keys;
      $parent = $parent->$sub;
    } else {
      croak qq{Can't traverse $type_str with key "$key"};
    }
  }
}

sub deep_get {
  my ($parent, @keys) = @_;
  return $parent unless @keys;
  foreach my $key_i (0..$#keys) {
    return undef unless defined $parent;
    my $reftype = ref $parent;
    my $blessed = blessed $parent;
    my $type = defined $blessed ? 'method' : lc $reftype;
    my $type_str = length $reftype ? "$reftype ref" : 'scalar value';
    my $key = $keys[$key_i];
    my $lvalue;
    if (ref $key eq 'HASH') {
      if (exists $key->{key}) {
        ($type, $key) = ('hash', $key->{key});
      } elsif (exists $key->{index}) {
        ($type, $key) = ('array', $key->{index});
      } elsif (exists $key->{method}) {
        ($type, $key) = ('method', $key->{method});
      } elsif (exists $key->{lvalue}) {
        ($type, $key, $lvalue) = ('method', $key->{lvalue}, 1);
      } else {
        croak q{Traversal key hashref must contain "key", "index", "method", or "lvalue"};
      }
    }
    if ($type eq 'hash') {
      croak qq{Can't dereference $type_str as HASH to access key "$key"} if !defined $blessed and $reftype ne 'HASH';
      return undef unless exists $parent->{$key};
      return $parent->{$key} if $key_i == $#keys;
      $parent = $parent->{$key};
    } elsif ($type eq 'array') {
      croak qq{Can't dereference $type_str as ARRAY to access index $key} if !defined $blessed and $reftype ne 'ARRAY';
      return undef unless exists $parent->[$key];
      return $parent->[$key] if $key_i == $#keys;
      $parent = $parent->[$key];
    } elsif ($type eq 'method') {
      croak qq{Can't call method "$key" on unblessed reference} if length $reftype and !defined $blessed;
      return undef unless my $sub = $parent->can($key);
      return $parent->$sub if $key_i == $#keys;
      $parent = $parent->$sub;
    } else {
      croak qq{Can't traverse $type_str with key "$key"};
    }
  }
}

sub deep_set {
  croak 'deep_set called with no arguments' unless @_;
  croak 'deep_set requires a value to set' unless @_ > 1;
  my $parent_ref = \$_[0];
  my @keys = @_[1..$#_-1];
  my $value = $_[-1];
  return $$parent_ref = $value unless @keys;
  foreach my $key_i (0..$#keys) {
    my $reftype = ref $$parent_ref;
    my $blessed = blessed $$parent_ref;
    my $type = defined $blessed ? 'method' : lc $reftype;
    my $type_str = length $reftype ? "$reftype ref" : 'scalar value';
    $type = 'hash' if !length $type and !defined $$parent_ref;
    my $key = $keys[$key_i];
    my $lvalue;
    if (ref $key eq 'HASH') {
      if (exists $key->{key}) {
        ($type, $key) = ('hash', $key->{key});
      } elsif (exists $key->{index}) {
        ($type, $key) = ('array', $key->{index});
      } elsif (exists $key->{method}) {
        ($type, $key) = ('method', $key->{method});
      } elsif (exists $key->{lvalue}) {
        ($type, $key, $lvalue) = ('method', $key->{lvalue}, 1);
      } else {
        croak q{Traversal key hashref must contain "key", "index", "method", or "lvalue"};
      }
    }
    if ($type eq 'hash') {
      if (defined $$parent_ref) {
        croak qq{Can't dereference $type_str as HASH to access key "$key"} if !defined $blessed and $reftype ne 'HASH';
      } else {
        $$parent_ref = {};
      }
      return $$parent_ref->{$key} = $value if $key_i == $#keys;
      $parent_ref = \$$parent_ref->{$key};
    } elsif ($type eq 'array') {
      if (defined $$parent_ref) {
        croak qq{Can't dereference $type_str as ARRAY to access index $key} if !defined $blessed and $reftype ne 'ARRAY';
      } else {
        $$parent_ref = [];
      }
      return $$parent_ref->[$key] = $value if $key_i == $#keys;
      $parent_ref = \$$parent_ref->[$key];
    } elsif ($type eq 'method') {
      croak qq{Can't call method "$key" on an undefined value} unless defined $$parent_ref;
      croak qq{Can't call method "$key" on unblessed reference} if !defined $blessed and length $reftype;
      my $package = length $reftype ? $reftype : $$parent_ref;
      croak qq{Can't locate object method "$key" via package "$package"} unless my $sub = $$parent_ref->can($key);
      if ($key_i == $#keys) {
        $lvalue ? $$parent_ref->$sub = $value : $$parent_ref->$sub($value);
        return $value;
      }
      $parent_ref = \$$parent_ref->$sub;
    } else {
      croak qq{Can't traverse $type_str with key "$key"};
    }
  }
}

sub deep_val :lvalue {
  croak 'deep_val called with no arguments' unless @_;
  my $parent_ref = \$_[0];
  my @keys = @_[1..$#_];
  sentinel get => sub { deep_get $$parent_ref, @keys },
           set => sub { deep_set $$parent_ref, @keys, $_[0] };
}

1;

=head1 NAME

Data::DeepAccess - Access or set data in deep structures

=head1 SYNOPSIS

  use Data::DeepAccess qw(deep_exists deep_get deep_set);

  my %things;
  deep_set(\%things, qw(foo bar), 42);
  say $things{foo}{bar}; # 42

  $things{foo}{baz} = ['a'..'z'];
  say deep_get(\%things, qw(foo baz 5)); # f

  deep_set(\%things, qw(foo foo), undef);
  say deep_exists(\%things, qw(foo foo)); # 1

  deep_val(\%things, qw(bar bar)) = 'lvalue';
  say deep_val(\%things, qw(bar bar)); # lvalue

=head1 DESCRIPTION

Provides the functions L</"deep_exists">, L</"deep_get">, L</"deep_set">, and
L</"deep_val"> that traverse nested data structures to retrieve or set the
value located by a list of keys.

When traversing, keys are applied according to the type of referenced data
structure. A hash will be traversed by hash key, an array by array index, and
an object by method call (scalar context with no arguments). If the data
structure is not defined, it will be traversed as a hash by default (but not
vivified unless in a set operation).

You can override how a key is applied, and thus what type of structure is
vivified if necessary, by passing the key in a hashref as the value of C<key>
(hash) or C<index> (array).

  deep_set(my $structure, 'foo', 42); # {foo => 42}
  deep_set(my $structure, {index => 1}, 42); # [undef, 42]
  deep_set($object, {key => 'foo'}, 42); # sets $object->{foo} directly

For the rare case it's needed, you can also use one of the keys C<method> or
C<lvalue>.

  deep_set($object, {method => 'foo'}, 42); # $object->foo(42)
  deep_set($object, {lvalue => 'foo'}, 42); # $object->foo = 42

Attempting to traverse intermediate structures that are defined and not a
reference to a hash, array, or object will result in an exception.

If an object method call is the last key in a set operation or the next
structure must be vivified, the method will be called passing the new value as
an argument or assigned if it is treated as an lvalue. Attempting to call a
method on an undefined value or unblessed ref in a set operation will result in
an exception.

Currently, undefined results from non-lvalue method calls are not vivified back
to the object to support setting a further nested value. This may be supported
in the future.

=head1 FUNCTIONS

All functions are exported individually.

=head2 deep_exists

  my $bool = deep_exists($structure, @keys);

Returns a true value if the value exists in the referenced structure located by
the given keys. No intermediate structures will be altered or vivified; a
missing structure will result in a false return value.

Array indexes are tested for existence with L<perlfunc/exists>, like hash
keys, which may have surprising results in sparse arrays. Avoid this situation.

Object methods are tested for existence with C<< $object->can($method) >>.

If no keys are passed, returns true.

=head2 deep_get

  my $value = deep_get($structure, @keys);

Retrieves the value from the referenced structure located by the given keys. No
intermediate structures will be altered or vivified; a missing structure will
result in C<undef>.

If no keys are passed, returns the original structure.

=head2 deep_set

  $new_value = deep_set($structure, @keys, $new_value);

Sets the value in the referenced structure located by the given keys. Missing
intermediate structures will be vivified to hashrefs by default. If the
structure is undefined, it must be an assignable lvalue to be vivified.

If no keys are passed, the structure must be an assignable lvalue and will be
assigned the value directly.

=head2 deep_val

  my $value = deep_val($structure, @keys);
  deep_val($structure, @keys) = $new_value;

L<Lvalue|perlsub/"Lvalue subroutines"> accessor that is equivalent to
L</"deep_get"> when a value is retrieved from it, or L</"deep_set"> when a
value is assigned to it (passing the assigned value as the final argument).

The passed keys are used to traverse the structure at the time of retrieval or
assignment, not when the function is called. This subtle difference may matter
if the lvalue is preserved for later access, such as via reference.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 CONTRIBUTORS

=over

=item Matt S Trout (mst)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

Many prior modules for accessing specific items within a deep structure, which
the author determined were either insufficient or overcomplex.

=over

=item * L<Hash::DeepAccess>

=item * L<Data::Deep>

=item * L<Data::Diver>

=item * L<Data::DPath>

=item * L<JSON::Pointer>

=back
