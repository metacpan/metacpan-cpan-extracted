package Class::Methodist;

use strict;
use warnings;
use Carp;

=head1 NAME

Class::Methodist - define methods for instance variables in a class

=head1 SYNOPSIS

  package My::Shiny::New::Class;

  use Class::Methodist
  (
   scalar => 'global_config_path',
   hash => 'unique_words',
   list => 'file_names',
   object => { name => 'thing', class => 'My::Thing:Class' },
   enum => { name => 'color', domain => [ 'red', 'green', 'blue' ] },
   scalars => [ 'alpha', 'beta' ]
  );

  sub new {
    my ($class, $alpha) = @_;
    $class->beget(alpha => $alpha, beta => 42);
  }

=head1 DESCRIPTION

This package creates instance variables and methods on a class for
accessing and manipulating those instance variables.
C<Class::Methodist> is similar in spirit to C<Class::MakeMethods>, but
with a simpler interface and more sensible semantics.

Instance variables to be defined are given as a list of I<instance
variable specifications> (a.k.a. I<specification>) when the module is
used.  A specification consists of a pair whose first element is the
I<type> of the variable (e.g., C<scalar>, C<hash>, C<list>) and whose
second element is the I<name> of the variable to be defined.  The
latter must be a valid Perl identifier name.

For each specification, the module defines a type-specific set of
methods on the calling class.  The names of these methods usually
include the name of the instance variable.  In the following sections,
we refer to the instance variable name by the generic identifier
I<inst_var>.

In your constructor you must call the C<beget> class method to
instantiate and initialize each instance of the class.

=head1 CLASS METHODS

=over

=item beget()

This class method instantiates and initializes an object of the class.
It takes the place of an explicit call to the Perl C<bless> function
(which it invokes under the hood).

You may pass arguments to C<beget> to initialize the new object.
These arguments must appear in pairs (as for a hash initializer).  The
first item in each pair should be the name of an attribute defined by
your use of C<Class::Methodist> and the second item in each pair
should be the value to which that attribute is initialized.  Note that
if you initialize I<list> or I<hash> attributes, you must pass the
initializer value as a I<reference> to an array or hash, respectively.

The C<beget> method blesses the new object into the class and returns
the blessed object.  You can either assign the return value to a
variable (often, C<self>) for further construction, or may simply
invoke C<beget> as the final statement in your constructor, which
arranges to return the newly minted object to the caller.

=item import()

This method satisfies the C<import> semantics required of any module
that uses C<Class::Methodist>.  It takes as arguments the list of
specifications provided in the C<use> directive in the calling module.
The method defines the instance variables and their associated methods
in the namespace of the I<calling class>, also referred to as the
I<destination class>.

=cut

sub import {
  my ($my_class, @args) = @_;
  my $dest_class = caller;	# Caller's class for importing methods.

  while (my ($type, $spec) = splice(@args, 0, 2)) {
  SWITCH:
    for ($type) {
      /ctor/ and do {
	define_constructor($dest_class, $spec);
	last SWITCH;
      };

      /enum/ and do {
	define_enum_methods($dest_class, $spec);
	last SWITCH;
      };

      /hash$/ and do {
	define_hash_methods($dest_class, $spec);
	last SWITCH;
      };

      /hash_of_lists/ and do {
	define_hash_of_lists_methods($dest_class, $spec);
	last SWITCH;
      };

      /list/ and do {
	define_list_methods($dest_class, $spec);
	last SWITCH;
      };

      /object/ and do {
	define_object_methods($dest_class, $spec);
	last SWITCH;
      };

      /scalar$/ and do {
	define_scalar_methods($dest_class, $spec);
	last SWITCH;
      };

      /scalars/ and do {
	define_scalar_methods($dest_class, $_) foreach @$spec;
	last SWITCH;
      };

      confess "Invalid type '$type'";
    }
  }

  define_utility_methods($dest_class);
}

#----------------------------------------------------------------

=item verify_method_not_defined($dest_class, $method)

We don't want to overwrite methods already defined in the calling
class.  Check whether C<$method> is defined in the destination class.
If so, throw an exception.

=cut

sub verify_method_not_defined {
  my ($dest_class, $method) = @_;

  use Devel::Symdump;
  my @functions = Devel::Symdump->new($dest_class)->functions();

  if (grep { $_ eq $method } @functions) {
    confess "Method '$method' already exists in class '$dest_class'";
  }
}

#----------------------------------------------------------------

=item define_method($dest_class, $method, $sub_ref)

Define a method named C<$method> in the destination class
C<$dest_class> to be the subroutine refererenced by C<$sub_ref>.  It
is an error to define a method that already exists.  This method is
the business end of this module in that all the following
type-specific methods invoke C<define_method> in order to create the
method(s) associated with each instance variable.

=back

=cut

sub define_method {
  my ($dest_class, $method, $sub_ref) = @_;

  # Try turning this off for now.  Called a *lot*.  May not be of much
  # benefit.
  #
  # verify_method_not_defined($dest_class, $method);

  my $fq_name = sprintf('%s::%s', $dest_class, $method);
  {
    no strict 'refs';
    *{$fq_name} = $sub_ref;
  }
}

#----------------------------------------------------------------

{
  my %methodist_info;

  ## Return whether the named class has Methodist-internal data.  This
  ## subroutine was added to allow us to handle properly inheritance
  ## from classes that don't use Methodist (e.g., Class::Singleton).
  sub _has_methodist_info {
    my $dest_class = shift;
    exists $methodist_info{$dest_class};
  }

  ## Add @values to the list stored under $key in the Methodist-internal
  ## data for this class.
  sub _add_methodist_info {
    my ($dest_class, $key, @values) = @_;
    push @{$methodist_info{$dest_class}{$key}}, @values;
  }

  ## Return the list of values stored under $key in the
  ## Methodist-internal data for this class.  If no data are stored
  ## under that key, return an empty list.
  sub _get_methodist_info {
    my ($dest_class, $key) = @_;
    $methodist_info{$dest_class}{$key} ||= [ ];
    return @{$methodist_info{$dest_class}{$key}};
  }
}

#----------------------------------------------------------------

=head2 Constructor

Define a constructor in the destination class as follows:

   ctor => 'new'

The generated constructor simply blesses an anonymous hash into the
destination class.

=cut

sub define_constructor {
  my ($dest_class, $name) = @_;

  ## Bless a hash reference into the destination class.
  define_method($dest_class, $name,
		sub {
		  $dest_class->beget();
		});
}

#----------------------------------------------------------------

=head2 Enum

Define methods in the destination class for a scalar-valued instance
variable that is constrained to take one of an enumerated series of
values.

   enum => { name => 'colors',
             domain => [ qw/red green blue/ ],
             default => 'blue' }

The C<name> and C<domain> attributes are required.  If the C<default>
attribute is provided, its value must evaluate to a member of the
domain.

=over

=cut

sub define_enum_methods {
  my ($dest_class, $spec) = @_;

  my $name = $spec->{name};
  my @domain = @{$spec->{domain}};

  _add_methodist_info($dest_class, attributes => [ enum => $name ]);

  if (defined $spec->{default}) {
    croak sprintf("Default (%s) not among %s",
		  $spec->{default}, join(', ', @domain))
      unless (grep(/$spec->{default}/, @domain));
    _add_methodist_info($dest_class,
			default => [ $name => $spec->{default} ]);
  }

=item I<inst_var>(...)

The method named the same as the instance variable is the setter and
getter.  If called with no arguments, returns the current value of the
enumerated attribute.  If called with an argument, the scalar is set
to that value, provided the value is one of the values enumerated in
the C<domain> list.  If the value is not in the domain, throws an
error.

=back

=cut

  define_method($dest_class, $name,
		sub {
		  my ($self, $arg) = @_;
		  if (defined($arg)) {
		    if (grep(/$arg/, @domain)) {
		      $self->{$name} = $arg;
		    } else {
		      croak sprintf("%s not among %s",
				    $arg, join(', ', @domain));
		    }
		  }
		  $self->{$name};
		});
}

#----------------------------------------------------------------

=head2 Hash

Define methods in the destination class for a hash-valued instance
variable called I<inst_var> as follows:

   hash => 'inst_var'

This specification defines the following methods in the destination
class:

=over

=cut

sub define_hash_methods {
  my ($dest_class, $name) = @_;

  _add_methodist_info($dest_class, attributes => [ hash => $name ]);

=item I<inst_var>($key, [$value])

The method having the same name as the instance variable is the setter
and getter:

   my $value = $obj->inst_var('key');
   $obj->inst_var(key => 'value');

When called with a single argument, there are two cases.  First, if
the argument is a hash reference, replace the contents of the hash
with that of the referenced hash.  Second, if it is not a hash
reference, treat it as a key; the method returns the value stored
under that key.

When called with more than one argument, treat the arguments as
key-value pairs and store them in the hash.  There must be an even
number of arguments (i.e., they must be pairs).  Return the value of
the last pair.

=cut

  define_method($dest_class, $name,
		sub {
		  my ($self, @args) = @_;
		  my $rtn = undef;

		  if (@args == 1) {
		    if (ref $args[0] eq 'HASH') {
		      $self->{$name} = $args[0];
		    } else {
		      $rtn = $self->{$name}{$args[0]};
		    }
		  } else {
		    while (my ($key, $val) = splice(@args, 0, 2)) {
		      $rtn = $self->{$name}{$key} = $val;
		    }
		  }
		  return $rtn;
		});

=item I<inst_var>_exists($key)

Method that returns whether a key exists in the hash.

   if ($obj->inst_var_exists('key')) { ... }

=cut

  define_method($dest_class, "${name}_exists",
		sub {
		  my ($self, $key) = @_;
		  confess "Must supply key" unless defined $key;
		  exists $self->{$name}{$key} ? 1 : undef;
		});

=item I<inst_var>_keys()

Method that returns the list of keys in the hash.

   my @keys = $obj->inst_var_keys();

=cut

  define_method($dest_class, "${name}_keys",
		sub {
		  my $self = shift;
		  sort keys %{$self->{$name}};
		});

=item I<inst_var>_values()

Method that returns the list of values in the hash.

   my @values = $obj->inst_var_values();

=cut

  define_method($dest_class, "${name}_values",
		sub {
		  my $self = shift;
		  sort values %{$self->{$name}}
		});

=item I<inst_var>_clear()

Method that clears the hash.

   $obj->inst_var_clear();

=cut

  define_method($dest_class, "${name}_clear",
		sub {
		  my $self = shift;
		  $self->{$name} = { };
		});

=item I<inst_var>_delete($key)

Delete the hash element with the given key.

   $obj->inst_var_delete($key)

=cut

  define_method($dest_class, "${name}_delete",
		sub {
		  my ($self, $key) = @_;
		  delete $self->{$name}{$key};
		});

=item I<inst_var>_size()

Return the number of key-value pairs stored in the hash.

   my $size = inst_var_size();

=cut

  define_method($dest_class, "${name}_size",
		sub {
		  my $self = shift;
		  scalar keys %{$self->{$name}};
		});

=item I<inst_var>_inc($key, [$n])

Add the value of C<$n> to the value found under C<$key> in the hash.
The value of C<$n> defaults to one, yielding a simple increment
operation.  Return the new value.

=back

=cut

  define_method($dest_class, "${name}_inc",
		sub {
		  my ($self, $key, $n) = @_;
		  $n = 1 unless defined $n;
		  $self->{$name}{$key} += $n;
		});
}

#----------------------------------------------------------------

=head2 Hash of Lists

Define methods in the destination class for a hash-of-lists instance
variable called I<inst_var> as follows:

   hash_of_lists => 'inst_var'

This specification defines the following methods in the destination
class:

=over

=cut

sub define_hash_of_lists_methods {
  my ($dest_class, $name) = @_;

  _add_methodist_info($dest_class, attributes => [ hash => $name ]);

=item I<inst_var>(...)

The method having the same name as the instance variable is the setter
and getter.  Its behavior depends on the number of arguments passed to
the method.

When called with no arguments, the method returns all the values
stored in all the lists.

When called with one argument, it is treated as a key into the hash
and returns the values stored in the list having that hash key.

The method returns a list in array context and a reference to a list
in scalar context.

=cut

  define_method($dest_class, $name,
		sub {
		  my ($self, @args) = @_;

		  my @rtn;
		  if (@args == 0) {
		    # Called with no arguments.  Return all the values
		    # stored in all the lists.
		    push @rtn, @$_ foreach values %{$self->{$name}};
		  } elsif (@args == 1) {
		    # Called with one argument.  Return all the values
		    # stored in the list having that value as a key
		    my $key = $args[0];
		    $self->{$name}{$key} = [ ]
		      unless defined $self->{$name}{$key};
		    @rtn = @{$self->{$name}{$key}};
		  } else {
		    confess "Must have zero or one arguments";
		  }

		  # Return values as a list in list context and as a
		  # list reference in scalar context.
		  if (wantarray) {
		    return @rtn;
		  } else {
		    return \@rtn;
		  }
		});

=item I<inst_var>_push($key, @args)

Push C<@args> on the list stored under C<$key>.

=cut

  define_method($dest_class, "${name}_push",
		sub {
		  my ($self, $key, @args) = @_;
		  push @{$self->{$name}{$key}}, @args;
		});

=item I<inst_var>_keys()

Return a list of all the keys in the hash.

=back

=cut

  define_method($dest_class, "${name}_keys",
		sub {
		  my $self = shift;
		  keys %{$self->{$name}};
		});
}

#----------------------------------------------------------------

=head2 List

Define methods in the destination class for a list-valued instance
variable called I<inst_var> as follows:

   list => 'inst_var'

This specification defines the following methods in the destination
class:

=over

=cut

sub define_list_methods {
  my ($dest_class, $name) = @_;

  _add_methodist_info($dest_class, attributes => [ list => $name ]);

=item I<inst_var>(...)

The method named the same as the instance variable is the setter and
getter.  Its behavior depends on the number of arguments with which it
is invoked.

When called with no arguments, return the contents of the list (when
called in array context) or a reference to the list (when called in
scalar context).

When called with one argument that is a I<reference> to a list,
I<replace> the contents of the list with the contents of the
referenced list.  Otherwise, I<replace> the contents of the list with
the arguments.

=cut

  define_method($dest_class, $name,
		sub {
		  my ($self, @args) = @_;

		  if (@args == 0) {
		    # Called without arguments.  Return the contents
		    # of the list. as a list in list context and as a
		    # list reference in scalar context.
		    if (wantarray) {
		      return @{$self->{$name}};
		    } else {
		      return $self->{$name};
		    }
		  } elsif (@args == 1 and ref $args[0] eq 'ARRAY') {
		    # Called with reference to a list.  Replace the
		    # contents of the list with the elements
		    # referenced.
		    $self->{$name} = $args[0];
		  } else {
		    ## Called with multiple arguments. Replace the
		    ## contents of the list with those arguments
		    $self->{$name} = \@args;
		  }
		});

=item push_I<inst_var>(@args)

Given a list of values, push them on to the end of the list.  Return
the new number of list elements.

=cut

  define_method($dest_class, "push_$name",
		sub {
		  my ($self, @args) = @_;
		  push @{$self->{$name}}, @args;
		  scalar @{$self->{$name}};
		});

=item push_I<inst_var>_if_new(@args)

Given a list of values, push them on to the end of the list unless
they already exist on he list.  Returns the new number of list
elements.  Note that this method uses Perl's C<grep> function and so
is only suitable for short lists.

=cut

  define_method($dest_class, "push_${name}_if_new",
		sub {
		  my ($self, @args) = @_;
		  foreach my $arg (@args) {
		    push @{$self->{$name}}, $arg
		      unless grep($_ eq $arg, @{$self->{$name}});
		  }
		  scalar @{$self->{$name}};
		});

=item pop_I<inst_var>

Pop a single value from the end of the list and return it.

=cut

  define_method($dest_class, "pop_$name",
		sub {
		  my $self = shift;
		  pop @{$self->{$name}};
		});

=item unshift_I<inst_var>(@args)

Given a list of values, unshift them on to the front of the list.
Return the new number of list elements.

=cut

  define_method($dest_class, "unshift_$name",
		sub {
		  my ($self, @args) = @_;
		  unshift @{$self->{$name}}, @args;
		  scalar @{$self->{$name}};
		});

=item shift_I<inst_var>()

Shift a single value from the front of the list and return it.

=cut

  define_method($dest_class, "shift_$name",
		sub {
		  my $self = shift;
		  shift @{$self->{$name}};
		});

=item first_of_I<inst_var>()

Return (but do not remove) the first element in the list.  If the list
is empty, return undef.

=cut

  define_method($dest_class, "first_of_$name",
		sub {
		  my $self = shift;
		  @{$self->{$name}} ? $self->{$name}[0] : undef;
		});

=item last_of_I<inst_var>()

Return (but do not remove) the last element in the list.  If the list
is empty, return undef.

=cut

  define_method($dest_class, "last_of_$name",
		sub {
		  my $self = shift;
		  @{$self->{$name}} ? $self->{$name}[-1] : undef;
		});

=item count_I<inst_var>()

Return the number of elements currently on the list.

=cut

  define_method($dest_class, "count_$name",
		sub {
		  my $self = shift;
		  scalar @{$self->{$name}};
		});

=item clear_I<inst_var>()

Delete the contents of the list.

=cut

  define_method($dest_class, "clear_$name",
		sub {
		  my $self = shift;
		  $self->{$name} = [ ];
		});

=item join_I<inst_var>([$glue])

Return the join of the list.  The list is not modified.  If C<$glue>
is defined, join the list with the given glue.  Otherwise, join the
list with the empty string.

=cut

  define_method($dest_class, "join_$name",
		sub {
		  my ($self, $glue) = @_;
		  $glue = '' unless defined $glue;
		  join($glue, @{$self->{$name}});
		});

=item grep_I<inst_var>($re)

Return the list generated by grepping the list against C<$re>, which
must be a compiled regular express (usually using C<qr//>).

=back

=cut

  define_method($dest_class, "grep_$name",
		sub {
		  my ($self, $re) = @_;
		  grep(/$re/, @{$self->{$name}});
		});
}

#----------------------------------------------------------------

=head2 Object

Define methods in the destination class for an object-valued instance
variable called I<inst_var>.

For specifications of this form (scalar-valued):

   object => 'inst_var'

the scalar is used as the name of the instance variable.

For specifications of this form (hash-reference-valued), the instance
variable is defined by attribute-value pairs in the referenced hash:

   object => { name => 'inst_var',
               class => 'Class::Name',
               delegate => [ 'method1', 'method2' ] }

The I<required> C<name> attribute gives the name of the instance
variable.

The I<optional> C<class> attribute gives the name of the class (or one
of its superclasses) whose objects can be assigned to this instance
variable.  Attempting to set the instance variable to instances of
other classes throws an exception.

The I<optional> C<delegate> attribute takes a reference to a list of
method names.  These methods are defined in the destination class as
methods that invoke the identically-named methods on the object
referenced by the instance variable.

This specification defines the following methods in the destination
class:

=over

=cut

sub define_object_methods {
  my ($dest_class, $spec) = @_;

  my $name = undef;
  my $required_class = undef;
  my @delegate;

  if (ref($spec) eq 'HASH') {
    $name = $spec->{name};
    $required_class = $spec->{class};
    @delegate = @{$spec->{delegate}} if exists $spec->{delegate};
  } else {
    $name = $spec;
  }

  confess "No name specified" unless defined $name;

=item I<inst_var>(...)

The method named the same as the instance variable is its getter and
setter.  When called with an argument, the instance variable is set to
that value.  If the specification includes a C<class> attribute, the
argument must be an object of that class or its subclasses (tested
using Perl's C<isa> built-in).  Returns the value of the instance
variable (which may have just been set).

=cut

  define_method($dest_class, $name,
		sub {
		  my ($self, $arg) = @_;

		  if (defined $arg) {
		    # Called with an argument.
		    confess "Must pass an object as value" unless ref $arg;
		    if ($required_class) {
		      # The 'class' attribute was supplied; the
		      # argument must be of the specified class.
		      my $arg_class = ref $arg;
		      confess "Requires '$required_class', not '$arg_class'"
			unless $arg->isa($required_class);
		    }
		    # Assign the value to the argument.
		    $self->{$name} = $arg;
		  }

		  # Return the current object (whether arguments or not).
		  $self->{$name};
		});

  # Created delegates, if any.
  foreach my $delegate (@delegate) {
    define_method($dest_class, $delegate,
		  sub {
		    my ($self, @args) = @_;
		    $self->{$name}->$delegate(@args);
		  });
  }

=item clear_I<inst_var>()

Undefine the object instance variable.  This method is so named to
make it consistent with other methods defined by this module.

=back

=cut

  define_method($dest_class, "clear_$name",
		sub {
		  my $self = shift;
		  $self->{$name} = undef;
		});
}

#----------------------------------------------------------------

=head2 Scalar

Define methods in the destination class for a scalar-valued instance
variable called I<inst_var> as follows:

   scalar => 'inst_var'

Alternatively, you may supply a hash reference as the argument to the
C<scalar> specification as follows:

  scalar => { name => 'inst_var', default => 42 }

In this case, the I<required> C<name> attribute gives the name of the
scalar in the destination class.  The I<optional> C<default> attribute
supplies an initial value for the scalar in the destination class.

This specification defines the following methods in the destination
class:

=over

=cut

sub define_scalar_methods {
  my ($dest_class, $spec) = @_;

  my $name = undef;

  if (ref($spec) eq 'HASH') {
    $name = $spec->{name};

    if (defined $spec->{default}) {
      _add_methodist_info($dest_class,
			  default => [ $name => $spec->{default} ]);
    }
  } else {
    $name = $spec;
  }

  _add_methodist_info($dest_class, attributes => [ scalar => $name ]);

=item I<inst_var>(...)

The method named the same as the instance variable is the setter and
getter.  If called with no arguments, returns the current value of the
scalar.  If called with an argument, the scalar is assigned that
value.

=cut

  define_method($dest_class, $name,
		sub {
		  my ($self, $arg) = @_;
		  if (defined $arg) {
		    return $self->{$name} = $arg;
		  }
		  $self->{$name};
		});

=item clear_I<inst_var>()

Undefine the instance variable.  This method is so named to make it
consistent with other methods defined by this module.

=cut

  define_method($dest_class, "clear_$name",
		sub {
		  my $self = shift;
		  $self->{$name} = undef;
		});

=item add_to_I<inst_var>($val)

Add numeric $val to the current contents of the scalar.

=cut

  define_method($dest_class, "add_to_$name",
		sub {
		  my ($self, $val) = @_;
		  $self->{$name} += $val;
		});

=item inc_I<inst_var>()

Increment the scalar by one and return its new value.

=cut

  define_method($dest_class, "inc_$name",
		sub {
		  my $self = shift;
		  $self->{$name}++;
		});

=item dec_I<inst_var>()

Decrement the scalar by one and return its new value.

=cut

  define_method($dest_class, "dec_$name",
		sub {
		  my $self = shift;
		  $self->{$name}--;
		});

=item append_to_I<inst_var>($val)

Append string $val to the current contents of the scalar.

=back

=cut

  define_method($dest_class, "append_to_$name",
		sub {
		  my ($self, $val) = @_;
		  $self->{$name} .= $val;
		});
}

#----------------------------------------------------------------

=head2 Scalars

Define methods in the destination class for multiple scalar-valued
instance variables as follows:

   scalars => [ 'alpha', 'beta', 'gamma' ]

This specification is a convenience for defining multiple
scalar-valued instance variables.  It takes a reference to a list of
names and invokes the C<scalar> specification for each.  Hence, the
above specification is entirely equivalent to this one:

   scalar => 'alpha',
   scalar => 'beta',
   scalar => 'gamma'

Note that there is no way to define a default value for each scalar in
the C<scalars> construct; use multiple C<scalar> specifications
instead.

=cut

#----------------------------------------------------------------

=head2 Utility

Define various utility methods.

=over

=cut

{
  use Class::ISA;

  # Cache previous results from self_and_super_path, which takes a
  # fair amount of time and is called a *lot* because it's in beget().
  my %self_and_super;

  # Invoke self_and_super_path (which returns the ordered list of
  # names of classes that Perl would search in order to find a
  # method).  Cache and return results.
  sub _self_and_super {
    my $class = shift;

    my $rtn = undef;
    if (exists $self_and_super{$class}) {
      $rtn = $self_and_super{$class};
    } else {
      my @self_and_super = Class::ISA::self_and_super_path($class);
      $rtn = $self_and_super{$class} = \@self_and_super;
    }

    return $rtn;
  }
}

sub define_utility_methods {
  my $dest_class = shift;

  define_method($dest_class, 'beget',
		sub {
		  my ($dest_class, %initializers) = @_;

		  my $self = bless { }, $dest_class;
		  $self->equip(%initializers);
		});

  define_method($dest_class, 'equip',
		sub {
		  my ($self, %initializers) = @_;

		  foreach my $class (@{_self_and_super(ref $self)}) {
		    next unless _has_methodist_info($class);

		    foreach my $pair (_get_methodist_info($class,
							  'attributes')) {
		      my ($type, $name) = @$pair;
		    SWITCH:
		      for ($type) {
			/scalar|enum/ and do {
			  $self->{$name} = undef;
			  last SWITCH;
			};
			/list/ and do {
			  $self->{$name} = [ ];
			  last SWITCH;
			};
			/hash/ and do {
			  $self->{$name} = { };
			  last SWITCH;
			};
			confess "Invalid type '$type'";
		      }
		    }

		    foreach my $pair (_get_methodist_info($class,
							  'default')) {
		      my ($name, $default) = @$pair;
		      $self->{$name} = $default;
		    }
		  }

		  while (my ($key, $value) = each %initializers) {
		    $self->$key($value);
		  }

		  return $self;
		});

  use Data::Dumper;
  $Data::Dumper::Indent = 1;

=item toString()

Define a method to convert an object to a string using
C<Data::Dumper>.

=cut

  define_method($dest_class, 'toString',
		sub {
		  my $self = shift;
		  Data::Dumper->Dump([ $self ], [ ref $self ]);
		});

=item attributes_as_string(@attributes)

Return a string representation of the object, including attribute
name-value pairs for attributes named in parameter list.

=cut

  sub ansi_magenta { "\e[35m" }
  sub ansi_underline { "\e[4m" }
  sub ansi_reset { "\e[0m" }

  define_method($dest_class, 'attributes_as_string',
		sub {
		  my ($self, @attributes) = @_;
		  my @pairs;
		  foreach my $attribute (@attributes) {
		    my $value = $self->{$attribute} || 'UNDEF';

		    if (ref($value) eq 'ARRAY') {
		      $value = sprintf('[%s]', join(',', @$value));

		    } elsif (ref($value) eq 'HASH') {
		      my @contents =
			map { sprintf("%s=%s", $_, $value->{$_} || 'UNDEF') }
			  sort keys %$value;
		      $value = sprintf('{%s}', join(',', @contents));
		    }

		    # Use ANSI colorization for attribute name.
		    push @pairs,
		      sprintf('%s%s%s=%s',
			      ansi_magenta, $attribute, ansi_reset, $value)
		  }
		  sprintf('(%s %s)', ref($self), join(',', @pairs));
		});

=item dump([$msge])

Define a method to dump an object using C<Data::Dumper>.  If C<$msge>
is defined, print it as a brief descriptive message before dumping the
object.  These methods are defined on all classes that use
C<Methodist>.

=cut

  define_method($dest_class, 'dump',
		sub {
		  my ($self, $msge) = @_;

		  print "==== $msge ====\n" if $msge;
		  print $self->toString();
		});
}

'SDG';				# Return true

__END__

=back

=head1 SEE ALSO

L<Class::MakeMethods>, L<Data::Dumper>

=head1 BUGS

Additional methods could probably be defined for several of the data
types, but these are all the ones I've actually needed in practice.

=head1 AUTHOR

Tom Nurkkala E<lt>tom@nerds4christ.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006 by Tom Nurkkala. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

