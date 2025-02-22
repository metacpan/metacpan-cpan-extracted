package Rose::DB::Object::Metadata::Relationship;

use strict;

use Carp();

use Rose::DB::Object::Metadata::Util qw(:all);

use Rose::DB::Object::Metadata::MethodMaker;
our @ISA = qw(Rose::DB::Object::Metadata::MethodMaker);

our $VERSION = '0.780';

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(relationship hash_key)
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => 
  [
    'foreign_key',
    'deferred_make_method_args',
    id => { interface => 'get_set_init' },
    __PACKAGE__->common_method_maker_argument_names,
  ],
);

sub type { Carp::confess "Override in subclass" }

sub is_singular { Carp::confess "Override in subclass" }

sub relationship { $_[0] }

sub is_ready_to_make_methods { 1 }
sub sanity_check { 1 }

my $Id_Counter = 0;

sub init_id { ++$Id_Counter }

# Some object keys have different names when they appear
# in hashref-style relationship specs.  This hash maps
# between the two in the case where they differ.
sub spec_hash_key_map 
{
  {
    # object key    spec key
    method_name  => 'methods',
  }
}

sub spec_hash_method_map 
{
  {
    # object key    object method
    _share_db    => 'share_db',
    _key_columns => 'key_columns',
  }
}

# Return a hashref-style relationship spec
sub spec_hash
{
  my($self) = shift;

  my $key_map    = $self->spec_hash_key_map || {};
  my $method_map = $self->spec_hash_method_map || {};

  my %spec = (type => $self->type);

  foreach my $key (keys(%$self))
  {
    if(exists $key_map->{$key})
    {
      my $spec_key = $key_map->{$key} or next;
      $spec{$spec_key} = $self->{$key};
    }
    elsif(exists $method_map->{$key})
    {
      my $method = $method_map->{$key} or next;
      $spec{$method} = $self->$method();
    }
    else
    {
      $spec{$key} = $self->{$key};
    }
  }

  return wantarray ? %spec : \%spec;
}

our $DEFAULT_INLINE_LIMIT = 80;

sub perl_hash_definition
{
  my($self, %args) = @_;

  my $meta = $self->parent;

  my $name_padding = $args{'name_padding'};

  my $braces = $args{'braces'};
  my $indent = defined $args{'indent'} ? $args{'indent'} : 
                 ($meta ? $meta->default_perl_indent : undef);

  my $inline = defined $args{'inline'} ? $args{'inline'} : 0;
  my $inline_limit = defined $args{'inline'} ? $args{'inline_limit'} : $DEFAULT_INLINE_LIMIT;

  my %attrs = map { $_ => 1 } $self->perl_relationship_definition_attributes;
  my %hash = $self->spec_hash;

  my @delete_keys = grep { !$attrs{$_} } keys %hash;
  delete @hash{@delete_keys};

  $hash{'column_map'} = delete $hash{'key_columns'}  if(exists $hash{'key_columns'});

  my $max_len = 0;
  my $min_len = -1;

  foreach my $name (keys %hash)
  {
    $max_len = length($name)  if(length $name > $max_len);
    $min_len = length($name)  if(length $name < $min_len || $min_len < 0);
  }

  if(defined $name_padding && $name_padding > 0)
  {
    return sprintf('%-*s => ', $name_padding, perl_quote_key($self->name)) .
           perl_hashref(hash         => \%hash, 
                        braces       => $braces,
                        inline       => $inline, 
                        inline_limit => $inline_limit,
                        indent       => $indent,
                        key_padding  => hash_key_padding(\%hash));
  }
  else
  {
    return perl_quote_key($self->name) . ' => ' .
           perl_hashref(hash         => \%hash, 
                        braces       => $braces,
                        inline       => $inline,
                        inline_limit => $inline_limit,
                        indent       => $indent,
                        key_padding  => hash_key_padding(\%hash));
  }
}

sub perl_relationship_definition_attributes
{
  my($self) = shift;

  my @attrs;

  ATTR: foreach my $attr ('type', sort keys %$self)
  {
    if($attr =~ /^(?: id | name | method_name | method_code | auto_method_types |
                      deferred_make_method_args | parent )$/x)
    {
      next ATTR;
    }

    my $val = $self->can($attr) ? $self->$attr() : next ATTR;

    if(!defined $val)
    {
      next ATTR;
    }

    next ATTR  if($attr =~ /^_?share_db$/ && $self->share_db);

    if($attr =~ /^_(share_db|key_columns)$/)
    {
      $attr = $1;
    }
    elsif($attr eq 'method_name')
    {
      my $names = $self->{$attr} or next ATTR;
      my $custom = 0;

      while(my($type, $name) = each(%$names))
      {
        if($name ne $self->build_method_name_for_type($type))
        {
          $custom = 1;
          last;
        }
      }

      unless($custom)
      {
        my $def_types = $self->init_auto_method_types;

        TYPE: foreach my $def_type (@$def_types)
        {
          my $found = 0;

          foreach my $type ($self->auto_method_types)
          {
            if($type eq $def_type)
            {
              $found++;
              next TYPE;
            }
          }

          $custom = 1  if($found != @$def_types);
        }
      }

      next ATTR  unless($custom);
    }

    push(@attrs, $attr);
  }

  return @attrs;
}

sub object_has_related_objects
{
  my($self, $object) = @_;

  unless($object->isa($self->parent->class))
  {
    my $class = $self->parent->class;
    Carp::croak "Cannot check for items related through the ", $self->name,
                " relationship.  Object does not inherit from $class: $object";
  }

  my $related_objects = $object->{$self->hash_key};
  my $ref = ref $related_objects;

  if($ref eq 'ARRAY')
  {
    return @{$related_objects} ? $related_objects : 0;
  }

  return $ref ? [ $related_objects ] : undef;
}

sub hash_keys_used { shift->hash_key }

sub forget_related_objects
{
  my($self, $object) = @_;

  foreach my $key ($self->hash_keys_used)
  {
    $object->{$key} = undef;
  }
}

sub requires_preexisting_parent_object { } # override in subclass

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Relationship - Base class for table relationship metadata objects.

=head1 SYNOPSIS

  package MyRelationshipType;

  use Rose::DB::Object::Metadata::Relationship;
  our @ISA = qw(Rose::DB::Object::Metadata::Relationship);
  ...

=head1 DESCRIPTION

This is the base class for objects that store and manipulate database table relationship metadata.  Relationship metadata objects are responsible for creating object methods that fetch and/or manipulate objects from related tables.  See the L<Rose::DB::Object::Metadata> documentation for more information.

=head2 MAKING METHODS

A L<Rose::DB::Object::Metadata::Relationship>-derived object is responsible for creating object methods that manipulate objects in related tables.  Each relationship object can make zero or more methods for each available relationship method type.  A relationship method type describes the purpose of a method.  The default list of relationship method types contains only one type:

=over 4

=item C<get>

A method that returns one or more objects from the related table.

=back

Methods are created by calling L<make_methods|/make_methods>.  A list of method types can be passed to the call to L<make_methods|/make_methods>.  If absent, the list of method types is determined by the L<auto_method_types|/auto_method_types> method.  A list of all possible method types is available through the L<available_method_types|/available_method_types> method.

These methods make up the "public" interface to relationship method creation.  There are, however, several "protected" methods which are used internally to implement the methods described above.  (The word "protected" is used here in a vaguely C++ sense, meaning "accessible to subclasses, but not to the public.")  Subclasses will probably find it easier to override and/or call these protected methods in order to influence the behavior of the "public" method maker methods.

A L<Rose::DB::Object::Metadata::Relationship> object delegates method creation to a  L<Rose::Object::MakeMethods>-derived class.  Each L<Rose::Object::MakeMethods>-derived class has its own set of method types, each of which takes it own set of arguments.

Using this system, four pieces of information are needed to create a method on behalf of a L<Rose::DB::Object::Metadata::Relationship>-derived object:

=over 4

=item * The B<relationship method type> (e.g., C<get>)

=item * The B<method maker class> (e.g., L<Rose::DB::Object::MakeMethods::Generic>)

=item * The B<method maker method type> (e.g., L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>)

=item * The B<method maker arguments> (e.g., C<interface =E<gt> 'get'>)

=back

This information can be organized conceptually into a "method map" that connects a relationship method type to a method maker class and, finally, to one particular method type within that class, and its arguments.

There is no default method map for the L<Rose::DB::Object::Metadata::Relationship> base class, but here is the method map from L<Rose::DB::Object::Metadata::Relationship::OneToOne> as an example:

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, ...

=back

Each item in the map is a relationship method type.  For each relationship method type, the method maker class, the method maker method type, and the "interesting" method maker arguments are listed, in that order.

The "..." in the method maker arguments is meant to indicate that arguments have been omitted.  Arguments that are common to all relationship method types are routinely omitted from the method map for the sake of brevity.  If there are no "interesting" method maker arguments, then "..." may appear by itself, as shown above.

The purpose of documenting the method map is to answer the question, "What kind of method(s) will be created by this relationship object for a given method type?"  Given the method map, it's possible to read the documentation for each method maker class to determine how methods of the specified type behave when passed the listed arguments.

To this end, each L<Rose::DB::Object::Metadata::Relationship>-derived class in the L<Rose::DB::Object> module distribution will list its method map in its documentation.  This is a concise way to document the behavior that is specific to each relationship class, while omitting the common functionality (which is documented here, in the relationship base class).

Remember, the existence and behavior of the method map is really implementation detail.  A relationship object is free to implement the public method-making interface however it wants, without regard to any conceptual or actual method map.  It must then, of course, document what kinds of methods it makes for each of its method types, but it does not have to use a method map to do so.

=head1 CLASS METHODS

=over 4

=item B<default_auto_method_types [TYPES]>

Get or set the default list of L<auto_method_types|/auto_method_types>.  TYPES should be a list of relationship method types.  Returns the list of default relationship method types (in list context) or a reference to an array of the default relationship method types (in scalar context).  The default list is empty.

=back

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new object based on PARAMS, where PARAMS are
name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<available_method_types>

Returns the full list of relationship method types supported by this class.

=item B<auto_method_types [TYPES]>

Get or set the list of relationship method types that are automatically created when L<make_methods|/make_methods> is called without an explicit list of relationship method types.  The default list is determined by the L<default_auto_method_types|/default_auto_method_types> class method.

=item B<build_method_name_for_type TYPE>

Return a method name for the relationship method type TYPE.  Subclasses must override this method.  The default implementation causes a fatal error if called.

=item B<class [CLASS]>

Get or set the name of the L<Rose::DB::Object>-derived class that fronts the foreign table referenced by this relationship.

=item B<is_singular>

Returns true of the relationship may refer to more than one related object, false otherwise.  For example, this method returns true for L<Rose::DB::Object::Metadata::Relationship::OneToMany/is_singular> objects, but false for L<Rose::DB::Object::Metadata::Relationship::ManyToOne/is_singular> objects.

Relationship subclasses must override this method and return an appropriate value.

=item B<make_methods PARAMS>

Create object method used to manipulate objects in related tables.  Any applicable column triggers are also added.  PARAMS are name/value pairs.  Valid PARAMS are:

=over 4

=item C<preserve_existing BOOL>

Boolean flag that indicates whether or not to preserve existing methods in the case of a name conflict.

=item C<replace_existing BOOL>

Boolean flag that indicates whether or not to replace existing methods in the case of a name conflict.

=item C<target_class CLASS>

The class in which to make the method(s).  If omitted, it defaults to the calling class.

=item C<types ARRAYREF>

A reference to an array of relationship method types to be created.  If omitted, it defaults to the list of relationship method types returned by L<auto_method_types|/auto_method_types>.

=back

If any of the methods could not be created for any reason, a fatal error will occur.

=item B<methods MAP>

Set the list of L<auto_method_types|/auto_method_types> and method names all at once.  MAP should be a reference to a hash whose keys are method types and whose values are either undef or method names.  If a value is undef, then the method name for that method type will be generated by calling L<build_method_name_for_type|/build_method_name_for_type>, as usual.  Otherwise, the specified method name will be used.

=item B<method_types [TYPES]>

This method is an alias for the L<auto_method_types|/auto_method_types> method.

=item B<method_name TYPE [, NAME]>

Get or set the name of the relationship method of type TYPE.

=item B<name [NAME]>

Get or set the name of the relationship.  This name must be unique among all other relationships for a given L<Rose::DB::Object>-derived class.

=item B<type>

Returns a string describing the type of relationship.  Subclasses must override this method.  The default implementation causes a fatal error if called.

=back

=head1 PROTECTED API

These methods are not part of the public interface, but are supported for use by subclasses.  Put another way, given an unknown object that "isa" L<Rose::DB::Object::Metadata::Relationship>, there should be no expectation that the following methods exist.  But subclasses, which know the exact class from which they inherit, are free to use these methods in order to implement the public API described above.

=over 4 

=item B<method_maker_arguments TYPE>

Returns a hash (in list context) or reference to a hash (in scalar context) of name/value arguments that will be passed to the L<method_maker_class|/method_maker_class> when making the relationship method type TYPE.

=item B<method_maker_class TYPE [, CLASS]>

If CLASS is passed, the name of the L<Rose::Object::MakeMethods>-derived class used to create the object method of type TYPE is set to CLASS.

Returns the name of the L<Rose::Object::MakeMethods>-derived class used to create the object method of type TYPE.

=item B<method_maker_type TYPE [, NAME]>

If NAME is passed, the name of the method maker method type for the relationship method type TYPE is set to NAME.

Returns the method maker method type for the relationship method type TYPE.  

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
