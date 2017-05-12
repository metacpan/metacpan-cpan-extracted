package Class::MakeMethods::Template::ClassName;

use Class::MakeMethods::Template '-isasubclass';
$VERSION = 1.008;

sub _diagnostic { &Class::MakeMethods::_diagnostic }

########################################################################
###### CLASS NAME MANIPULATIONS
########################################################################

=head1 NAME

Class::MakeMethods::Template::ClassName - Access object's class 

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::ClassName (
    subclass_name => [ 'type' ]
  );
  ...
  package main;
  my $object = MyObject->new;

  $object->type('Foo')
  # reblesses object to MyObject::Foo subclass

  print $object->type();
  # prints "Foo".

=head1 DESCRIPTION

These method types access or change information about the class an object is associated with.

=head2 class_name

Called without arguments, returns the class name.

If called with an argument, reblesses object into that class. 
If the class doesn't already exist, it will be created.

=head2 subclass_name

Called without arguments, returns the subclass name.

If called with an argument, reblesses object into that subclass. 
If the subclass doesn't already exist, it will be created.

The subclass name is written as follows:

=over 4

=item *

if it's the original, defining class: empty

=item *

if its a a package within the namespace of the original: the distingushing name within that namespace, without leading C<::>

=item *

if it's a package elsewhere: the full name with leading C<::>

=back

=cut

# $subclass = _pack_subclass( $base, $pckg );
sub _pack_subclass {
  my $base = shift; 
  my $pckg = shift;

  ( $pckg eq $base )              ? '' :
  ( $pckg =~ s/^\Q$base\E\:\:// ) ? $pckg :
				    "::$pckg";
}

# $pckg = _unpack_subclass( $base, $subclass );
sub _unpack_subclass {
  my $base = shift; 
  my $subclass = shift;
  
  ! $subclass              ? $base :			
  ( $subclass =~ s/^::// ) ? $subclass :
			     "$base\::$subclass";
}

# $pckg = _require_class( $package );
sub _require_class {
  my $package = shift;
  
  no strict 'refs';
  unless ( @{$package . '::ISA'} ) { 
    (my $file = $package . '.pm' ) =~ s|::|/|go;
    local $SIG{__DIE__} = sub { die @_ };
    # warn "Auto-requiring package $package \n";
    eval { require $file };
    if ( $@ ) { _diagnostic('mm_package_fail', $package, $@) }
  }
  
  return $package;
}

# $pckg = _provide_class( $base, $package );
sub _provide_class {
  my $base = shift;
  my $package = shift;
  
  # If the subclass hasn't been created yet, do so.
  no strict 'refs';
  unless ( scalar @{$package . '::ISA'} ) {
    # warn "Auto-vivifying $base subclass $package\n";
    @{$package . '::ISA'} = ( $base );
  }
  
  return $package;
}

sub class_name {
  {
    'interface' => {
      default => 'autocreate',
      autocreate => {  '*'=>'autocreate' },
      require => {  '*'=>'require' },
    },
    'behavior' => {
      'autocreate' => q{
	  if ( ! scalar @_ ) {
	    _CLASS_GET_
	  } else {
	    _CLASS_PROVIDE_
	  }
	},
      'require' => q{
	  if ( ! scalar @_ ) {
	    _CLASS_GET_
	  } else {
	    _CLASS_REQUIRE_
	  }
	},
    },
    'code_expr' => {
      _CLASS_GET_ => q{
	  my $class = ref $self || $self;
      },
      _CLASS_REQUIRE_ => q{
	  my $class = Class::MakeMethods::Template::ClassName::_require_class( shift() );
	  _BLESS_AND_RETURN_
      },
      _CLASS_PROVIDE_ => q{
	  my $class = Class::MakeMethods::Template::ClassName::_provide_class( 
		$m_info->{'target_class'}, shift() );
	  _BLESS_AND_RETURN_      
      },
      _BLESS_AND_RETURN_ => q{
	  bless $self, $class if ( ref $self );
	  return $class;
      },
    },
  } 
}

sub subclass_name {
  {
    '-import' => {
      'Template::ClassName:class_name' => '*',
    },
    'code_expr' => {
      _CLASS_GET_ => q{
	my $class = ref $self || $self;
	Class::MakeMethods::Template::ClassName::_pack_subclass( $m_info->{'target_class'}, $class )
      },
      _CLASS_REQUIRE_ => q{
	  my $subclass = Class::MakeMethods::Template::ClassName::_unpack_subclass( 
				$m_info->{'target_class'}, shift() );
	  my $class = Class::MakeMethods::Template::ClassName::_require_class($subclass);
	  _BLESS_AND_RETURN_
      },
      _CLASS_PROVIDE_ => q{
	  my $subclass = Class::MakeMethods::Template::ClassName::_unpack_subclass( 
				$m_info->{'target_class'}, shift() );
	  my $class = Class::MakeMethods::Template::ClassName::_provide_class( 
	      $m_info->{'target_class'}, $subclass );
	  _BLESS_AND_RETURN_
      },
    },
  } 
}


########################################################################
### CLASS_REGISTRY

=head2 static_hash_classname

Provides a shared hash mapping keys to class names.

  class_registry => [ qw/ foo / ]

Takes a single string or a reference to an array of strings as its argument. 
For each string, creates a new anonymous hash and associated accessor methods 
that will map scalar values to classes in the calling package's subclass 
hiearchy.

The accessor methods provide an interface to the hash as illustrated below. 
Note that several of these functions operate quite differently depending on the 
number of arguments passed, or the context in which they are called.

=over 4  

=item @indexes = $class_or_ref->x;

Returns the scalar values that are indexes associated with this class, or the class of this object.

=item $class = $class_or_ref->x( $index );

Returns the class name associated with the provided index value. 

=item @classes = $class_or_ref->x( @indexes );

Returns the associated classes for each index in order.

=item @all_indexes = $class_or_ref->x_keys;

Returns a list of the indexes defined for this registry.

=item @all_classes = $class_or_ref->x_values;

Returns a list of the classes associated with this registry.

=item @all_classes = $class_or_ref->unique_x_values;

Returns a list of the classes associated with this registry, with no more than one occurance of any value.

=item %mapping = $class_or_ref->x_hash;

Return the key-value pairs used to store this attribute

=item $mapping_ref = $class_or_ref->x_hash;

Returns a reference to the hash used for the mapping.

=item $class_or_ref->add_x( @indexes );

Adds an entry in the hash for each of the provided indexes, mapping it to this class, or the class of this object.

=item $class_or_ref->clear_x;

Removes those entries from the hash whose values are this class, or the class of this object.

=item $class_or_ref->clear_xs( @indexes );

Remove all entries from the hash.

=back

=cut

sub static_hash_classname {
  {
    '-import' => {
      'Template::Static:hash' => '*',
    },
    'params' => { 'instance' => {} },
    'interface' => {
      default => { 
	'*'=>'get_classname', 
	'add_*'=>'add_classname', 
	'clear_*'=>'drop_classname', 
	'*_keys'=>'keys', 
	'*_hash'=>'get', 
	'*_values'=>'values', 
	'clear_*s'=>'clear', 
	'unique_*_values'=>'unique_values',
      },
    },
    'behavior' => {
      'get_classname' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  my $class = ( ref($self) || $self );
	  
	  defined $m_info->{'instance'} or $m_info->{'instance'} = {};
	  my $hash = $m_info->{'instance'};
	  
	  if ( ! scalar @_ ) {
	    my @keys = grep { $hash->{$_} eq $class } keys %$hash;
	    return wantarray ? @keys : $keys[0];
	  } elsif (scalar @_ == 1) {
	    return $hash->{ shift() };
	  } else {
	    return @{$hash}{ @_ };
	  }
	}},
      'add_classname' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  my $class = ( ref($self) || $self );
	  
	  defined $m_info->{'instance'} or $m_info->{'instance'} = {};
	  my $hash = $m_info->{'instance'};
	  
	  foreach ( @_ ) { $hash->{$_} = $class }
	}},
      'drop_classname' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  my $class = ( ref($self) || $self );
	  
	  defined $m_info->{'instance'} or $m_info->{'instance'} = {};
	  my $hash = $m_info->{'instance'};
	  
	  foreach ( grep { $hash->{$_} eq $class } keys %$hash ){ 
	    delete $hash{$_} 
	  }
	}},
    },
  }
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Template> for information about this family of subclasses.

=cut

1;
