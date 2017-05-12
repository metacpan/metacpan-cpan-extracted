package Articulate::Syntax;
use strict;
use warnings;

use Scalar::Util qw(blessed);
use Module::Load ();

use Exporter::Declare;
default_exports qw(
  instantiate instantiate_array instantiate_selection instantiate_array_selection
  new_response    new_request
  new_credentials new_permission
  new_location    new_location_specification
  dpath_get   dpath_set
  hash_merge
  throw_error
  select_from
  is_single_key_hash
);

use Articulate::Error;
use Data::DPath qw(dpath dpathr);
use Hash::Merge ();

use Articulate::Error;
use Articulate::Credentials;
use Articulate::File;
use Articulate::Item;
use Articulate::Location;
use Articulate::LocationSpecification;
use Articulate::Permission;
use Articulate::Request;
use Articulate::Response;

# sub throw_error { Articulate::Error::throw_error(@_) };
# sub new_location         { Articulate::Location::new_location(@_) };

=head1 NAME

Articulate::Syntax - Common functions and syntactic sugar for
Articulate

=head1 FUNCTIONS

=head3 new_response

See L<Artciulate::Response>.

=head3 new_request

See L<Artciulate::Request>.

=head3 new_credentials

See L<Artciulate::Credentials>.

=head3 new_permission

See L<Artciulate::Permission>.

=head3 new_location

See L<Artciulate::Location>.

=head3 new_location_specification

See L<Artciulate::LocationSpecification>.

=cut

=head3 instantiate_array

C<instantiate_array> accepts an arrayref of values which represent
objects. For each value, if it is not an object, it will attempt to
instantiate one using C<instantiate>.

If you pass C<instantiate_array> a value which is not an arrayref, it
will assume you meant to give it an arrayref with a single item; or, if
you pass it C<undef>, it will return an empty arrayref.

The purpose of this function is to enable the following:

    package Articulate::SomeDelegatingComponent;
    use Moo;
    has delegates_to =>
      is      => 'rw',
      default => sub { [] },
      coerce  => sub{ instantiate_array(@_) };

Which means given config like the following:

    Articulate::SomeDelegatingComponent:
      delegates_to:
        - My::Validation::For::Articles
        - class: My::Validation::For::Images
          args:
            - max_width: 1024
              max_height: 768
        - class: My::Validation::For::Documents
          constructor: preset
          args: pdf

You can be guaranteed that looping through C<< @{ $self->delegates_to }
>> will always produce objects.

=head3 instantiate

Attempts to create an object from the hashref or class name provided.

If the value is a string, it will treat as a class name, and perform
C<< $class->new >>, or, if the method exists, C<< $class->instance >>
will be preferred (for instance, as provided by C<MooX::Singleton>).

If the value is a hashref, it will look at the values for the keys
C<class>, C<constructor>, and C<args>. It will then attempt to perform
C<< $class->$constructor(@$args) >>, unless the constructor is absent
(in which case C<instance> or C<new> will be supplied), or if C<args>
is not an arrayref, in which case it will be passed to the constructor
as a single argument (or the empty list will be passed if C<args> is
undefined).

If the value is an object, the object will simply be returned.

=cut

sub instantiate {
  my $original = shift;
  if ( blessed $original ) {
    return $original;
  }
  elsif ( !ref $original ) {
    Module::Load::load($original);
    if ( $original->can('instance') ) {
      return $original->instance();
    }
    else {
      return $original->new();
    }
  }
  elsif ( ref $original eq ref {} ) {
    my $class = $original->{class};
    my $args  = $original->{args};
    if ( 1 == keys %$original and join( '', keys %$original ) !~ /^[a-z_]/ )
    { # single key that looks like a class
      $class = join '', keys %$original;
      $args = $original->{$class};
    }
    throw_error Internal => 'Instantiation failed: expecting key class, got '
      . ( join ', ', keys %$original )
      unless defined $class;
    Module::Load::load($class);
    my $constructor = $original->{constructor}
      // ( $class->can('instance') ? 'instance' : 'new' );
    my @args = (
        ( defined $args )
      ? ( ref $args eq ref [] )
          ? @$args
          : $args
      : ()
    );
    return $class->$constructor(@args);
  }
}

sub instantiate_array {
  my $arrayref = shift;
  return [] unless defined $arrayref;

# delegates_to => "Class::Name" should be interpreted as delegates_to => ["Class::Name"]
  $arrayref = [$arrayref] unless ref $arrayref and ref $arrayref eq ref [];
  return [ map { instantiate $_ } @$arrayref ];
}

=head3 from_meta

  sub email_address { from_meta (shift, 'schema/user/email_address'); }

This method uses Data::DPath to retrieve a field from the metadata
structure.

=cut

sub from_meta {
  my $structure = shift;
  my $item      = shift;
  my @results   = dpath( $item->meta )->match($structure);
  return shift @results;
}

=head3 dpath_get

  my $value = dpath_get($structure, '/path/in/structure');

=cut

sub dpath_get {
  my $structure = shift;
  my $path      = shift;
  my @results   = dpath($path)->match($structure);
  return shift @results;
}

=head3 dpath_set

  dpath_set($structure, '/path/in/structure', $value);

=cut

sub dpath_set {
  my $structure = shift;
  my $path      = shift;
  my $value     = shift;
  my @results   = dpathr($path)->match($structure);
  map { $$_ = $value } @results;
  return $value if @results;
}

=head3 instantiate_selection

  # in config:

  rules:
    default:
      alias: main_schema
    main_schema:
      dsn: 'csv:main.csv'
      utf8: 1

  has schemata =>
    is      => 'rw',
    default => sub { {} },
    coerce  => sub { instantiate_selection @_ };

Expects a hash. If any of the values are single-key hashes with the key
'alias' then the alias is resolved. Otherwise the value is
instantiated.

If a value other than a hash is given, returns a hash with the key
'default' and the original value instantiated.

=cut

sub instantiate_selection {
  my $orig = shift;
  _instantiate_selection( $orig, \&instantiate );
}

=head3 instantiate_array_selection

  rules:
    default:
      alias: two_rules
    two_rules:
      - Some::Rule
      - Some::Other::Rule

  has rules =>
    is      => 'rw',
    default => sub { {} },
    coerce  => sub { instantiate_array_selection @_ };

Expects a hash. If any of the values are single-key hashes with the key
'alias' then the alias is resolved. Otherwise the value is instantiated
as an array (see C<instantiate_aray>).

If a value other than a hash is given, returns a hash with the key
'default' and the original value instantiated as an array.

=cut

sub instantiate_array_selection {
  my $orig = shift;
  _instantiate_selection( $orig, \&instantiate_array );
}

sub _instantiate_selection {
  my $orig        = shift;
  my $instantiate = shift;
  if ( ref $orig eq ref {} ) {
    for my $i ( 1 .. 5 ) {
      foreach my $this ( keys %$orig ) {
        my $got = $orig->{$this};
        if ( is_single_key_hash( $got, 'alias' ) ) {
          $orig->{$this} = $orig->{ $got->{alias} } if $i > 1;
        }
        else {
          $orig->{$this} = $instantiate->($got);
        }
      }
    }
    return $orig;
  }
  else {
    return { default => $instantiate->($orig) };
  }
}

=head3 select_from

  # given this config:

  schemata:
    default:
      "[Complicated] configuration: can_be->[string, hash, whatever]"
    schema_generic:
      alias: default

  # if your class has
  sub schema { select_from schemata => @_ }

  # then you can do
  $self->schema;
  $self->schema('default'); # same thing
  $self->schema('schema_generic'); # same thing, because of alias
  $self->schemata->{default}; # This is what they all do in practice

Implements a user-friendly selection mechanism like the one implemented
by C<Dancer::Plugin::DBIC::schema>.

=cut

sub select_from {
  my ( $attribute, $self, $which ) = @_;
  $which //= 'default';
  my $this        = $which;
  my $selectables = $self->$attribute;
  for ( 1 .. 5 ) { # if more than this then you probably have recusion
    my $got = $selectables->{$this};
    if ( is_single_key_hash( $got, 'alias' ) ) {
      $this = $got->{alias};
      next;
    }
    return $got;
  }
}

=head3 is_single_key_hash

  is_single_key_hash ( { foo => 123 } ); # returns 1
  is_single_key_hash ( { foo => 123 }, 'foo' ); # returns 1
  is_single_key_hash ( { foo => 123 }, 'bar' ); # returns 0

Returns 1 if the first argument is a hashref with exactly one key. If a
second argument is provided, then the key, if it exists, must be equal
to that argument, or the return value will be 0.

=cut

sub is_single_key_hash {
  my $got = shift;
  my $key = shift;
  return 1
    if (defined $key
    and ref $got eq ref {}
    and 1 == scalar keys %$got
    and $key eq [ keys %$got ]->[0] );
  return 1
    if ( !defined $key and ref $got eq ref {} and 1 == scalar keys %$got );
  return 0;
}

=head3 hash_merge

  my $merged = hash_merge ($parent, $child)

Returns a new hashref whose values represent a union of the parent's
and the child's. The child's values overwrite the parent, in case of
conflict. The merge is deep (i.e. it handles nested hashes), using
L<Hash::Merge> with right precedence.

=cut

my $hash_merger = Hash::Merge->new('RIGHT_PRECEDENT');

sub hash_merge { # very naive, will change to something like Hash::Merge
  my ( $parent, $child ) = @_;
  return $hash_merger->merge( $parent, $child ); # todo: more
}

1;
