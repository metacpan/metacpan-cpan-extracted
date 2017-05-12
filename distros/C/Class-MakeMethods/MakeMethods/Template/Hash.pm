package Class::MakeMethods::Template::Hash;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.0;

sub generic {
  {
    'params' => {
      'hash_key' => '*',
    },
    'code_expr' => { 
      _VALUE_ => '_SELF_->{_STATIC_ATTR_{hash_key}}',
      '-import' => { 'Template::Generic:generic' => '*' },
      _EMPTY_NEW_INSTANCE_ => 'bless {}, _SELF_CLASS_',
      _SET_VALUES_FROM_HASH_ => 'while ( scalar @_ ) { local $_ = shift(); $self->{ $_ } = shift() }'
    },
    'behavior' => {
      'hash_delete' => q{ delete _VALUE_ },
      'hash_exists' => q{ exists _VALUE_ },
    },
    'modifier' => {
      # XXX the below doesn't work because modifiers can't have params,
      # although interfaces can... Either add support for default params
      # in modifiers, or else move this to another class.
      # X Should there be a version which uses caller() instead of target_class?
      'class_keys' => { 'hash_key' => '"*{target_class}::*{name}"' },
    }
  }
}

########################################################################

=head1 NAME

Class::MakeMethods::Template::Hash - Method interfaces for hash-based objects

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Hash (
    new             => [ 'new' ],
    scalar          => [ 'foo', 'bar' ]
  );
  
  package main;

  my $obj = MyObject->new( foo => "Foozle", bar => "Bozzle" );
  print $obj->foo();
  $obj->bar("Bamboozle"); 

=head1 DESCRIPTION

These meta-methods create and access values within blessed hash objects.

B<Common Parameters>: The following parameters are defined for Hash meta-methods.

=over 4

=item hash_key

The hash key to use when retrieving values from each hash instance. Defaults to '*', the name of the meta-method.

Changing this allows you to change an accessor method name to something other than the name of the hash key used to retrieve its value.

Note that this parameter is not portable to the other implementations, such as Global or InsideOut.

You can take advantage of parameter expansion to define methods whose hash key is composed of the defining package's name and the individual method name, such as C<$self-E<gt>{I<MyObject>-I<foo>}>:

      'hash_key' => '*{target_class}-*{name}'

=back

B<Common Behaviors>

=over 4

=item Behavior: delete

Deletes the named key and associated value from the current hash instance.

=back

=head2 Standard Methods

The following methods from Generic are all supported:

  new
  scalar
  string
  string_index
  number 
  boolean
  bits (*)
  array
  hash
  tiedhash
  hash_of_arrays
  object
  instance
  array_of_objects
  code
  code_or_scalar

See L<Class::MakeMethods::Template::Generic> for the interfaces and behaviors of these method types.

The items marked with a * above are specifically defined in this package, whereas the others are formed automatically by the interaction of this package's generic settings with the code templates provided by the Generic superclass. 

=cut

# This is the only one that needs to be specifically defined.
sub bits {
  {
    '-import' => { 'Template::Generic:bits' => '*' },
    'params' => {
      'hash_key' => '*{target_class}__*{template_name}',
    },
  }
}

########################################################################

=head2 struct

  struct => [ qw / foo bar baz / ];

Creates methods for setting, checking and clearing values which
are stored by position in an array. All the slots created with this
meta-method are stored in a single array.

The argument to struct should be a string or a reference to an
array of strings. For each string meta-method x, it defines two
methods: I<x> and I<clear_x>. x returns the value of the x-slot.
If called with an argument, it first sets the x-slot to the argument.
clear_x sets the slot to undef.

Additionally, struct defines three class method: I<struct>, which returns
a list of all of the struct values, I<struct_fields>, which returns
a list of all the slots by name, and I<struct_dump>, which returns a hash of
the slot-name/slot-value pairs.

=cut

sub struct {
  ( {
    'interface' => {
      default => { 
	  '*'=>'get_set', 'clear_*'=>'clear',
	  'struct_fields'=>'struct_fields', 
	  'struct'=>'struct', 'struct_dump'=>'struct_dump' 
      },
    },
    'params' => {
      'hash_key' => '*{target_class}__*{template_name}',
    },
    'behavior' => {
      '-init' => sub {
	my $m_info = $_[0]; 
	
	$m_info->{class} ||= $m_info->{target_class};
	
	my $class_info = 
	 ($Class::MakeMethods::Template::Hash::struct{$m_info->{class}} ||= []);
	if ( ! defined $m_info->{sfp} ) {
	  foreach ( 0..$#$class_info ) { 
	    if ( $class_info->[$_] eq $m_info->{'name'} ) {
	      $m_info->{sfp} = $_; 
	      last 
	    }
	  }
	  if ( ! defined $m_info->{sfp} ) {
	    push @$class_info, $m_info->{'name'};
	    $m_info->{sfp} = $#$class_info;
	  }
	}
	return;	
      },
      
      'struct_fields' => sub { my $m_info = $_[0]; sub {
	my $class_info = 
	  ( $Class::MakeMethods::Template::Hash::struct{$m_info->{class}} ||= [] );
	  @$class_info;
	}},
      'struct' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  $self->{$m_info->{hash_key}} ||= [];
	  if ( @_ ) { @{$self->{$m_info->{hash_key}}} = @_ }
	  @{$self->{$m_info->{hash_key}}};
	}},
      'struct_dump' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  my $class_info = 
	    ( $Class::MakeMethods::Template::Hash::struct{$m_info->{class}} ||= [] );
	  map { ($_, $self->$_()) } @$class_info;
	}},
      
      'get_set' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  $self->{$m_info->{hash_key}} ||= [];
	
	  if ( @_ ) {
	    $self->{$m_info->{hash_key}}->[ $m_info->{sfp} ] = shift;
	  }
	  $self->{$m_info->{hash_key}}->[ $m_info->{sfp} ];
	}},
      'clear' => sub { my $m_info = $_[0]; sub {
	  my $self = shift;
	  $self->{$m_info->{hash_key}} ||= [];
	  $self->{$m_info->{hash_key}}->[ $m_info->{sfp} ] = undef;
	}},
    },
  } )
}

########################################################################

=head1  SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Template> for more about this family of subclasses.

See L<Class::MakeMethods::Template::Generic> for information about the various accessor interfaces subclassed herein.

=cut

1;
