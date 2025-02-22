package Rose::Object::MakeMethods::Generic;

use strict;

use Carp();

our $VERSION = '0.859';

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

our $Have_CXSA;

TRY:
{
  local $@;

  eval
  {
    require Class::XSAccessor;

    (my $version = $Class::XSAccessor::VERSION) =~ s/_//g;

    unless($version >= 0.14)
    {
      die "Class::XSAccessor $Class::XSAccessor::VERSION is too old";
    }
  };

  $Have_CXSA = $@ ? 0 : 1;
}

our $Debug = 0;

sub scalar
{
  my($class, $name, $args) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set_init')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {
      return $_[0]->{$key} = $_[1]  if(@_ > 1);

      return defined $_[0]->{$key} ? $_[0]->{$key} :
        ($_[0]->{$key} = $_[0]->$init_method());
    }
  }
  elsif($interface eq 'get_set')
  {
    if($Have_CXSA && !$ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'})
    {
      $methods{$name} = 
      {
        make_method => sub
        {
          my($name, $target_class, $options) = @_;

          $Debug && warn "Class::XSAccessor make method ($name => $key) in $target_class\n";

          Class::XSAccessor->import(
            accessors => { $name => $key }, 
            class     => $target_class,
            replace   => $options->{'override_existing'} ? 1 : 0);
        },
      };
    }
    else
    {
      $methods{$name} = sub
      {
        return $_[0]->{$key} = $_[1]  if(@_ > 1);
        return $_[0]->{$key};
      }
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub boolean
{
  my($class, $name, $args) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set_init')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {
      return $_[0]->{$key} = $_[1] ? 1 : 0  if(@_ > 1);

      return defined $_[0]->{$key} ? $_[0]->{$key} :
        ($_[0]->{$key} = $_[0]->$init_method() ? 1 : 0);
    }
  }
  elsif($interface eq 'get_set')
  {
    if(exists $args->{'default'})
    {
      if($args->{'default'})
      {
        $methods{$name} = sub
        {
          return $_[0]->{$key} = $_[1] ? 1 : 0  if(@_ > 1);
          return defined $_[0]->{$key} ? $_[0]->{$key} : ($_[0]->{$key} = 1)
        }
      }
      else
      {
        $methods{$name} = sub
        {
          return $_[0]->{$key} = $_[1] ? 1 : 0  if(@_ > 1);
          return defined $_[0]->{$key} ? $_[0]->{$key} : ($_[0]->{$key} = 0)
        }
      }
    }
    else
    {
      $methods{$name} = sub
      {
        return $_[0]->{$key} = $_[1] ? 1 : 0  if(@_ > 1);
        return $_[0]->{$key};
      }
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub hash
{
  my($class, $name, $args) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set_init')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return hash contents
      unless(@_)
      {
        $self->{$key} = $self->$init_method()  unless(defined $self->{$key});
        return wantarray ? %{$self->{$key}} : $self->{$key};
      }

      # If called with a hash ref, set value
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $self->{$key} = $_[0];
      }
      else
      {      
        # If called with an index, get that value, or a slice for array refs
        if(@_ == 1)
        {
          # Initialize hash if undefined
          $self->{$key} = $self->$init_method()  unless(defined $self->{$key});

          return ref $_[0] eq 'ARRAY' ? @{$self->{$key}}{@{$_[0]}} : 
                                        $self->{$key}{$_[0]};
        }

        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        while(@_)
        {
          local $_ = shift;
          $self->{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'get_set_inited')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return hash contents
      unless(@_)
      {
        $self->{$key} = {}  unless(defined $self->{$key});
        return wantarray ? %{$self->{$key}} : $self->{$key};
      }

      # If called with a hash ref, set value
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $self->{$key} = $_[0];
      }
      else
      {      
        # If called with an index, get that value, or a slice for array refs
        if(@_ == 1)
        {
          return ref $_[0] eq 'ARRAY' ? @{$self->{$key}}{@{$_[0]}} : 
                                        $self->{$key}{$_[0]};
        }

        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        while(@_)
        {
          local $_ = shift;
          $self->{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'get_set_all')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return hash contents
      return wantarray ? %{$self->{$key}} : $self->{$key}  unless(@_);

      # Set hash to arguments
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $self->{$key} = $_[0];
      }
      else
      {
        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        $self->{$key} = {};

        while(@_)
        {
          local $_ = shift;
          $self->{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'get_set_init_all')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return hash contents
      unless(@_)
      {
        $self->{$key} = $self->$init_method()  unless(defined $self->{$key});
        return wantarray ? %{$self->{$key}} : $self->{$key};
      }

      # If called with no arguments, return hash contents
      return wantarray ? %{$self->{$key}} : $self->{$key}  unless(@_);

      # Set hash to arguments
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $self->{$key} = $_[0];
      }
      else
      {
        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        $self->{$key} = {};

        while(@_)
        {
          local $_ = shift;
          $self->{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'clear')
  {
    $methods{$name} = sub
    {
      $_[0]->{$key} = {}
    }
  }
  elsif($interface eq 'reset')
  {
    $methods{$name} = sub
    {
      $_[0]->{$key} = undef;
    }
  }
  elsif($interface eq 'delete')
  {
    $methods{($interface eq 'manip' ? 'delete_' : '') . $name} = sub
    {
      Carp::croak "Missing key(s) to delete"  unless(@_ > 1);

      delete @{shift->{$key}}{@_};
    }
  }
  elsif($interface eq 'exists')
  {
    $methods{$name . ($interface eq 'manip' ? '_exists' : '')} = sub
    {
      Carp::croak "Missing key argument"  unless(@_ == 2);
      defined $_[0]->{$key} ? exists $_[0]->{$key}{$_[1]} : undef;
    }
  }
  elsif($interface =~ /^(?:keys|names)$/)
  {
    $methods{$name} = sub
    {
      wantarray ? (defined $_[0]->{$key} ? keys %{$_[0]->{$key}} : ()) :
                  (defined $_[0]->{$key} ? [ keys %{$_[0]->{$key}} ] : []);
    }
  }
  elsif($interface eq 'values')
  {
    $methods{$name} = sub
    {
      wantarray ? (defined $_[0]->{$key} ? values %{$_[0]->{$key}} : ()) :
                  (defined $_[0]->{$key} ? [ values %{$_[0]->{$key}} ] : []);
    }
  }
  elsif($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return hash contents
      unless(@_)
      {
        return wantarray ? (defined $self->{$key} ? %{$self->{$key}} : ()) : $self->{$key}  
      }

      # If called with a hash ref, set value
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $self->{$key} = $_[0];
      }
      else
      {      
        # If called with an index, get that value, or a slice for array refs
        if(@_ == 1)
        {
          return ref $_[0] eq 'ARRAY' ? @{$self->{$key}}{@{$_[0]}} : 
                                        $self->{$key}{$_[0]};
        }

        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        while(@_)
        {
          local $_ = shift;
          $self->{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$self->{$key}} : $self->{$key};
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub array
{
  my($class, $name, $args) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set_init')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return array contents
      unless(@_)
      {
        $self->{$key} = $self->$init_method()  unless(defined $self->{$key});
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      # If called with a array ref, set new value
      if(@_ == 1 && ref $_[0] eq 'ARRAY')
      {
        $self->{$key} = $_[0];
      }
      else
      {
        $self->{$key} = [ @_ ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'get_set_inited')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return array contents
      unless(@_)
      {
        $self->{$key} = [] unless(defined $self->{$key});
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      # If called with a array ref, set new value
      if(@_ == 1 && ref $_[0] eq 'ARRAY')
      {
        $self->{$key} = $_[0];
      }
      else
      {
        $self->{$key} = [ @_ ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'get_set_item')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      Carp::croak "Missing array index"  unless(@_);

      if(@_ == 2)
      {
        return $self->{$key}[$_[0]] = $_[1];
      }
      else
      {
        return $self->{$key}[$_[0]]
      }
    }
  }
  elsif($interface eq 'unshift')
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      Carp::croak "Missing value(s) to add"  unless(@_);
      unshift(@{$self->{$key}}, (@_ == 1 && ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_);
    }
  }
  elsif($interface eq 'shift')
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      return splice(@{$self->{$key}}, 0, $_[0])  if(@_);
      return shift(@{$self->{$key}})
    }
  }
  elsif($interface eq 'clear')
  {
    $methods{$name} = sub
    {
      $_[0]->{$key} = []
    }
  }
  elsif($interface eq 'reset')
  {
    $methods{$name} = sub
    {
      $_[0]->{$key} = undef;
    }
  }
  elsif($interface =~ /^(?:push|add)$/)
  {
    if(my $init_method = $args->{'init_method'})
    {
      $methods{$name} = sub
      {
        my($self) = shift;

        Carp::croak "Missing value(s) to add"  unless(@_);

        $self->{$key} = $self->$init_method()  unless(defined $self->{$key});
        push(@{$self->{$key}}, (@_ == 1 && ref $_[0] && ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_);
      }    
    }
    else
    {
      $methods{$name} = sub
      {
        my($self) = shift;

        Carp::croak "Missing value(s) to add"  unless(@_);

        push(@{$self->{$key}}, (@_ == 1 && ref $_[0] && ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_);
      }
    }
  }
  elsif($interface eq 'pop')
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      return splice(@{$self->{$key}}, -$_[0])  if(@_);
      return pop(@{$self->{$key}})
    }
  }
  elsif($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return array contents
      unless(@_)
      {
        return wantarray ? (defined $self->{$key} ? @{$self->{$key}} : ()) : $self->{$key}  
      }

      # If called with a array ref, set new value
      if(@_ == 1 && ref $_[0] eq 'ARRAY')
      {
        $self->{$key} = $_[0];
      }
      else
      {
        $self->{$key} = [ @_ ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

1;

__END__

=head1 NAME

Rose::Object::MakeMethods::Generic - Create simple object methods.

=head1 SYNOPSIS

  package MyObject;

  use Rose::Object::MakeMethods::Generic
  (
    scalar => 
    [
      'power',
      'error',
    ],

    'scalar --get_set_init' => 'name',

    'boolean --get_set_init' => 'is_tall',

    boolean => 
    [
      'is_red',
      'is_happy' => { default => 1 },
    ],

    array =>
    [
      jobs       => {},
      job        => { interface => 'get_set_item', hash_key => 'jobs' },
      clear_jobs => { interface => 'clear', hash_key => 'jobs' },
      reset_jobs => { interface => 'reset', hash_key => 'jobs' },
    ],

    hash =>
    [
      param        => { hash_key => 'params' },
      params       => { interface => 'get_set_all' },
      param_names  => { interface => 'keys', hash_key => 'params' },
      param_values => { interface => 'values', hash_key => 'params' },
      param_exists => { interface => 'exists', hash_key => 'params' },
      delete_param => { interface => 'delete', hash_key => 'params' },

      clear_params => { interface => 'clear', hash_key => 'params' },
      reset_params => { interface => 'reset', hash_key => 'params' },
    ],
  );

  sub init_name    { 'Fred' }
  sub init_is_tall { 1 }
  ...

  $obj = MyObject->new(power => 5);

  print $obj->name; # Fred

  $obj->do_something or die $obj->error;

  $obj->is_tall;        # true
  $obj->is_tall(undef); # false (but defined)
  $obj->is_tall;        # false (but defined)

  $obj->is_red;         # undef
  $obj->is_red(1234);   # true
  $obj->is_red('');     # false (but defined)
  $obj->is_red;         # false (but defined)

  $obj->is_happy;       # true

  $obj->params(a => 1, b => 2);   # add pairs
  $val = $obj->param('b');        # 2
  $obj->param_exists('x');        # false

  $obj->jobs('butcher', 'baker'); # add values
  $obj->job(0 => 'sailor');       # set value
  $job = $obj->job(0);            # 'sailor'

=head1 DESCRIPTION

L<Rose::Object::MakeMethods::Generic> is a method maker that inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.  All methods work only with hash-based objects.

=head1 METHODS TYPES

=over 4

=item B<scalar>

Create get/set methods for scalar attributes.

=over 4

=item Options

=over 4

=item C<hash_key>

The key inside the hash-based object to use for the storage of this attribute. Defaults to the name of the method.

=item C<init_method>

The name of the method to call when initializing the value of an undefined attribute.  This option is only applicable when using the C<get_set_init> interface.  Defaults to the method name with the prefix C<init_> added.

=item C<interface>

Choose one of the two possible interfaces.  Defaults to C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a simple get/set accessor method for an object attribute.  When called with an argument, the value of the attribute is set.  The current value of the attribute is returned.

=item C<get_set_init>

Behaves like the C<get_set> interface unless the value of the attribute is undefined.  In that case, the method specified by the C<init_method> option is called and the attribute is set to the return value of that method.

=back

=back

Example:

    package MyObject;

    use Rose::Object::MakeMethods::Generic
    (
      scalar => 'power',
      'scalar --get_set_init' => 'name',
    );

    sub init_name { 'Fred' }
    ...

    $obj->power(99);    # returns 99
    $obj->name;         # returns "Fred"
    $obj->name('Bill'); # returns "Bill"

=item B<boolean>

Create get/set methods for boolean attributes.  For each argument to these methods, the only thing that matters is whether it evaluates to true or false.  The return value is either, true, false (but defined), or undef if the value has never been set.

=over 4

=item Options

=over 4

=item C<default>

Determines the default value of the attribute.  This option is only applicable when using the C<get_set> interface.

=item C<hash_key>

The key inside the hash-based object to use for the storage of this attribute. Defaults to the name of the method.

=item C<init_method>

The name of the method to call when initializing the value of an undefined attribute.  Again, the only thing that matters about the return value of this method is whether or not it is true or false.  This option is only applicable when using the C<get_set_init> interface. Defaults to the method name with the prefix C<init_> added.

=item C<interface>

Choose one of the two possible interfaces.  Defaults to C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a simple get/set accessor method for a boolean object attribute. When called with an argument, the value of the attribute is set to true if the argument evaluates to true, false (but defined) otherwise.  The current value of the attribute is returned.

If L<Class::XSAccessor> version 0.14 or later is installed and the C<ROSE_OBJECT_NO_CLASS_XSACCESOR> environment variable is not set to a true value, then L<Class::XSAccessor> will be used to generated the method.

=item C<get_set_init>

Behaves like the C<get_set> interface unless the value of the attribute is undefined.  In that case, the method specified by the C<init_method> option is called and the attribute is set based on the boolean value of the return value of that method.

=back

=back

Example:

    package MyObject;

    use Rose::Object::MakeMethods::Generic
    (
      'boolean --get_set_init' => 'is_tall',

      boolean => 
      [
        'is_red',
        'is_happy' => { default => 1 },
      ],
    );

    sub init_is_tall { 'blah' }
    ...

    $obj->is_tall;        # returns true
    $obj->is_tall(undef); # returns false (but defined)
    $obj->is_tall;        # returns false (but defined)

    $obj->is_red;         # returns undef
    $obj->is_red(1234);   # returns true
    $obj->is_red('');     # returns false (but defined)
    $obj->is_red;         # returns false (but defined)

    $obj->is_happy;       # returns true

=item B<hash>

Create methods to manipulate hash attributes.

=over 4

=item Options

=over 4

=item C<hash_key>

The key inside the hash-based object to use for the storage of this attribute.  Defaults to the name of the method.

=item C<init_method>

The name of the method to call when initializing the value of an undefined hash attribute.    This method should return a reference to a hash, and is only applicable when using the C<get_set_init> interface. Defaults to the method name with the prefix C<init_> added.

=item C<interface>

Choose which interface to use.  Defaults to C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

If called with no arguments, returns a list of key/value pairs in list context or a reference to the actual hash stored by the object in scalar context.

If called with one argument, and that argument is a reference to a hash, that hash reference is used as the new value for the attribute.  Returns a list of key/value pairs in list context or a reference to the actual hash stored by the object in scalar context.

If called with one argument, and that argument is a reference to an array, then a list of the hash values for each key in the array is returned.

If called with one argument, and it is not a reference to a hash or an array, then the hash value for that key is returned.

If called with an even number of arguments, they are taken as name/value pairs and are added to the hash.  It then returns a list of key/value pairs in list context or a reference to the actual hash stored by the object in scalar context.

Passing an odd number of arguments greater than 1 causes a fatal error.

=item C<get_set_init>

Behaves like the C<get_set> interface unless the attribute is undefined. In that case, the method specified by the C<init_method> option is called and the attribute is set to the return value of that method, which should be a reference to a hash.

=item C<get_set_inited>

Behaves like the C<get_set> interface unless the attribute is undefined. In that case, it is initialized to an empty hash before proceeding as usual.

=item C<get_set_all>

If called with no arguments, returns a list of key/value pairs in list context or a reference to the actual hash stored by the object in scalar context.

If called with one argument, and that argument is a reference to a hash, that hash reference is used as the new value for the attribute.  Returns a list of key/value pairs in list context or a reference to the actual hash stored by the object in scalar context.

Otherwise, the hash is emptied and the arguments are taken as name/value pairs that are then added to the hash.  It then returns a list of key/value pairs in list context or a reference to the actual hash stored by the object in scalar context.

=item C<get_set_init_all>

Behaves like the C<get_set_all> interface unless the attribute is undefined. In that case, the method specified by the C<init_method> option is called and the attribute is set to the return value of that method, which should be a reference to a hash.

=item C<clear>

Sets the attribute to an empty hash.

=item C<reset>

Sets the attribute to undef.

=item C<delete>

Deletes the key(s) passed as arguments.  Failure to pass any arguments causes a fatal error.

=item C<exists>

Returns true of the argument exists in the hash, false otherwise. Failure to pass an argument or passing more than one argument causes a fatal error.

=item C<keys>

Returns the keys of the hash in list context, or a reference to an array of the keys of the hash in scalar context.  The keys are not sorted.

=item C<names>

An alias for the C<keys> interface.

=item C<values>

Returns the values of the hash in list context, or a reference to an array of the values of the hash in scalar context.  The values are not sorted.

=back

=back

Example:

    package MyObject;

    use Rose::Object::MakeMethods::Generic
    (
      hash =>
      [
        param        => { hash_key =>'params' },
        params       => { interface=>'get_set_all' },
        param_names  => { interface=>'keys',   hash_key=>'params' },
        param_values => { interface=>'values', hash_key=>'params' },
        param_exists => { interface=>'exists', hash_key=>'params' },
        delete_param => { interface=>'delete', hash_key=>'params' },

        clear_params => { interface=>'clear', hash_key=>'params' },
        reset_params => { interface=>'reset', hash_key=>'params' },
      ],
    );
    ...

    $obj = MyObject->new;

    $obj->params; # undef

    $obj->params(a => 1, b => 2); # add pairs
    $val = $obj->param('b'); # 2

    %params = $obj->params; # copy hash keys and values
    $params = $obj->params; # get hash ref

    $obj->params({ c => 3, d => 4 }); # replace contents

    $obj->param_exists('a'); # false

    $keys = join(',', sort $obj->param_names);  # 'c,d'
    $vals = join(',', sort $obj->param_values); # '3,4'

    $obj->delete_param('c');
    $obj->param(f => 7, g => 8);

    $vals = join(',', sort $obj->param_values); # '4,7,8'

    $obj->clear_params;
    $params = $obj->params; # empty hash

    $obj->reset_params;
    $params = $obj->params; # undef

=item B<array>

Create methods to manipulate array attributes.

=over 4

=item Options

=over 4

=item C<hash_key>

The key inside the hash-based object to use for the storage of this attribute.  Defaults to the name of the method.

=item C<init_method>

The name of the method to call when initializing the value of an undefined array attribute.    This method should return a reference to an array.  This option is only applicable when using the C<get_set_init>, C<push>, and C<add> interfaces.  When using the C<get_set_init> interface, C<init_method> defaults to the method name with the prefix C<init_> added.

=item C<interface>

Choose which interface to use.  Defaults to C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

If called with no arguments, returns the array contents in list context or a reference to the actual array stored by the object in scalar context.

If called with one argument, and that argument is a reference to an array, that array reference is used as the new value for the attribute. Returns the array contents in list context or a reference to the actual array stored by the object in scalar context.

If called with one argument, and that argument is not a reference to an array, or if called with more than one argument, then the array contents are replaced by the arguments.  Returns the array contents in list context or a reference to the actual array stored by the object in scalar context.

=item C<get_set_init>

Behaves like the C<get_set> interface unless the attribute is undefined. In that case, the method specified by the C<init_method> option is called and the attribute is set to the return value of that method, which should be a reference to an array.

=item C<get_set_inited>

Behaves like the C<get_set> interface unless the attribute is undefined. In that case, it is initialized to an empty array before proceeding as usual.

=item C<get_set_item>

If called with one argument, returns the item at that array index.

If called with two arguments, sets the item at the array index specified by the first argument to the value specified by the second argument.

Failure to pass any arguments causes a fatal error.

=item C<exists>

Returns true of the argument exists in the hash, false otherwise. Failure to pass an argument or passing more than one argument causes a fatal error.

=item C<add>

An alias for the C<push> interface.

=item C<push>

If called with a list or a reference to an array, the contents of the list or referenced array are added to the end of the array.  If called with no arguments, a fatal error will occur.

=item C<pop>

Remove an item from the end of the array and returns it.  If an integer argument is passed, then that number of items is removed and returned. Otherwise, just one is removed and returned.

=item C<shift>

Remove an item from the start of the array and returns it.  If an integer argument is passed, then that number of items is removed and returned. Otherwise, just one is removed and returned.

=item C<unshift>

If called with a list or a reference to an array, the contents of the list or referenced array are added to the start of the array.  If called with no arguments, a fatal error will occur.

=item C<clear>

Sets the attribute to an empty array.

=item C<reset>

Sets the attribute to undef.

=back

=back

Example:

    package MyObject;

    use Rose::Object::MakeMethods::Generic
    (
      array =>
      [
        jobs       => {},
        job        => { interface => 'get_set_item', 
                        hash_key  => 'jobs' },
        clear_jobs => { interface => 'clear', hash_key => 'jobs' },
        reset_jobs => { interface => 'reset', hash_key => 'jobs' },
      ],
    );
    ...

    $obj = MyObject->new;

    $jobs = $obj->jobs; # undef

    $obj->clear_jobs();
    $jobs = $obj->jobs; # ref to empty array

    $obj->jobs('butcher', 'baker'); # add values
    $vals = join(',', $obj->jobs);  # 'butcher,baker'

    $obj->jobs([ 'candlestick', 'maker' ]); # replace values

    $vals = join(',', $obj->jobs); # 'candlestick,maker'

    $job = $obj->job(0);      # 'candlestick'
    $obj->job(0 => 'sailor'); # set value
    $job = $obj->job(0);      # 'sailor'

    $obj->reset_jobs;
    $jobs = $obj->jobs; # undef

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
