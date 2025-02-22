package Rose::Object::MakeMethods;

use strict;

use Carp();

our $VERSION = '0.856';

__PACKAGE__->allow_apparent_reload(1);

our %Made_Method_Custom;

sub import
{
  my($class) = shift;

  return 1  unless(@_);

  my($options, $args) = $class->_normalize_args(@_);

  $options->{'target_class'} ||= (caller)[0];

  $class->make_methods($options, $args);

  return 1;
}

sub make_methods
{
  my($class) = shift;

  my($options, $args) = $class->_normalize_args(@_);

  $options->{'target_class'} ||= (caller)[0];  

  #use Data::Dumper;
  #print STDERR Dumper($options);
  #print STDERR Dumper($args);

  while(@$args)
  {
    $class->__make_methods($options, shift(@$args), shift(@$args));
  }

  return 1;
}

# Can't use the class method maker easily here due to a chicken/egg
# situation, so this code is manually inlined.
my %Inheritable_Scalar;

sub allow_apparent_reload
{
  my($class) = ref($_[0]) ? ref(shift) : shift;

  if(@_)
  {
    return $Inheritable_Scalar{$class}{'allow_apparent_reload'} = shift;
  }

  return $Inheritable_Scalar{$class}{'allow_apparent_reload'}
    if(exists $Inheritable_Scalar{$class}{'allow_apparent_reload'});

  my @parents = ($class);

  while(my $parent = shift(@parents))
  {
    no strict 'refs';
    foreach my $subclass (@{$parent . '::ISA'})
    {
      push(@parents, $subclass);

      if(exists $Inheritable_Scalar{$subclass}{'allow_apparent_reload'})
      {
        return $Inheritable_Scalar{$subclass}{'allow_apparent_reload'}
      }
    }
  }

  return undef;
}

# XXX: This nasty hack should be unneeded now and will probably
# XXX: be removed some time in the future.
our $Preserve_Existing = 0;

sub __make_methods
{
  my($class) = shift;

  #my $options;

  #if(ref $_[0] eq 'HASH')
  #{
  #  $options = shift;
  #}
  #else { $options = {} }

  #$options->{'target_class'} ||= (caller)[0];  

  my $options     = shift;
  my $method_type = shift;
  my $methods     = shift;

  my $target_class = $options->{'target_class'};

  while(@$methods)
  {
    my $method_name = shift(@$methods);
    my $method_args = shift(@$methods);

    my $make = $class->$method_type($method_name => $method_args, $options ||= {});

    Carp::croak "${class}::method_type(...) didn't return a hash ref!"
      unless(ref $make eq 'HASH');

    no strict 'refs';    

    METHOD: while(my($name, $code) = each(%$make))
    {
      Carp::croak "${class}::method_type(...) - key for $name is not a code ref!"
        unless(ref $code eq 'CODE' || (ref $code eq 'HASH' && $code->{'make_method'}));

      if(my $code = $target_class->can($name))
      {
        if($options->{'preserve_existing'} || $Preserve_Existing)
        {
          next METHOD;
        }

        unless($options->{'override_existing'})
        {
          if($class->allow_apparent_reload && $class->apparently_made_method($code))
          {
            next METHOD;
          }

          Carp::croak "Cannot create method ${target_class}::$name - method already exists";
        }
      }

      no warnings;

      if(ref $code eq 'CODE')
      {
        *{"${target_class}::$name"} = $code;
      }
      else
      {
        # XXX: Must track these separately because they do not show up as
        # XXX: being named __ANON__ when fetching the sub_identity()
        $Made_Method_Custom{$target_class}{$name}++;
        $code->{'make_method'}($name, $target_class, $options);
      }
    }
  }

  return 1;
}

sub apparently_made_method
{
  my($class, $code) = @_;

  my($mm_class, $name) = $class->sub_identity($code);
  return 0  unless($class && $name);
  # XXX: RT 54444 - The formerly constant "__ANON__" sub name looks
  # XXX: like this in newer versions of perl when running under the
  # XXX: debugger: "__ANON__[/usr/lib/perl5/.../Some/Module.pm:123]"
  return (($mm_class eq $class && $name =~ /^__ANON__/) ||
          $Made_Method_Custom{$mm_class}{$name}) ? 1 : 0;
}

# Code from Sub::Identify
sub sub_identity
{
  my($class, $code) = @_;

  my @id;

  TRY:
  {
    local $@;

    eval # if this fails, the identity is undefined
    {
      require B;
      my $cv = B::svref_2object($code);
      return  unless($cv->isa('B::CV'));
      @id = ($cv->GV->STASH->NAME, $cv->GV->NAME);
    };

    # Ignore errors
  }

  return @id;
}

# Given the example method types "bitfield" and "scalar", _normalize_args()
# takes args in any of these forms:
#
#     { ... }, # Class options (optionally) go here
#
#     scalar => 'foo',
#
#     'bitfield --opt' => [ 'a', 'b' ],
#
#     'scalar --opt2=blah' => [ 'foo' => { opt => 4, opt2 => 'blee' } ],
#
#     scalar => [ 'a' => { default => 5 }, 'b' ],
# 
#     bitfield =>
#     [
#       bar => { size => 8 },
#       baz => { size => 5, default => '00011' },
#     ],
#
# and returns an options hashref (possibly empty) and a reference
# to an array that is normalized to look like this:
#
# [
#   [
#     'scalar'   => [ 'foo' =>  {} ],
#
#     'bitfield' => 
#     [
#       'a' => { opt => 1 }, 
#       'b' => { opt => 1 }
#     ],
#
#     'scalar' => [ 'foo' => { 'opt' => 4, 'opt2' => 'blee' } ],
#
#     'scalar'=> 
#     [
#       'a' => { 'default' => 5 }, 
#       'b' => {}
#     ],
#
#     'bitfield' => 
#     [ 
#       'bar' => { 'size' => 8 },
#       'baz' => { 'default' => '00011', 'size' => 5 }
#     ]
#   ]
# ]

sub _normalize_args
{
  my($class) = shift;

  my $i = 0;

  my(@normalized_args, $options);

  while(@_)
  {
    my $method_type = shift || last;

    if(ref $method_type)
    {
      if(ref $method_type eq 'HASH')
      {
        Carp::croak "Options hash ref provided more than once"
          if($options);

        $options = $method_type;
        next;
      }
      elsif(ref $method_type eq 'ARRAY')
      {
        unshift(@_, @$method_type);
        next;
      }
    }

    my %method_options;

    my $i = 0;

    while($method_type =~ s/\s+--(\w+)(?:=(\w+))?//)
    {
      if($i++ || defined $2)
      {
        $method_options{$1} = $2;
      }
      else
      {
        $method_options{'interface'} = $1;
      }
    }

    push(@normalized_args, $method_type);

    my $args = shift;

    if(!ref $args)
    {
      $args = [ $args ];
    }
    elsif(ref $args ne 'ARRAY')
    {
      Carp::croak "Bad invocation of Rose::Object::MakeMethods";
    }

    my @method_args;

    while(@$args)
    {
      my $method_name = shift(@$args);

      if(ref $args->[0])
      {
        unless(ref $args->[0] eq 'HASH')
        {
          Carp::croak "Expected hash ref or scalar after method name, but found $args->[0]";
        }

        push(@method_args, $method_name => { %method_options, %{shift(@$args)} });
      }
      else
      {
        push(@method_args, $method_name => { %method_options });
      }
    }

    push(@normalized_args, \@method_args);
  }

  return($options || {}, \@normalized_args);
}

1;

__END__

=head1 NAME

Rose::Object::MakeMethods - A simple method maker base class.

=head1 SYNOPSIS

  package MyMethodMaker;

  use Rose::Object::MakeMethods;
  our @ISA = qw(Rose::Object::MakeMethods);

  sub widget
  {
    my($class, $name, $args) = @_;

    my $key = $args->{'hash_key'} || $name;
    my $interface = $args->{'interface'} || 'get_set';

    my %methods;

    if($interface =~ /^get_set/)
    {
      $methods{$name} = sub
      {
        my($self) = shift;
        if(@_) { ... }
        ...
        return $self->{$key};
      };
    }

    if($interface eq 'get_set_delete')
    {
      $methods{"delete_$name"} = sub { ... };
    )

    return \%methods;
  }
  ...

  package MyObject;

  sub new { ... }

  use MyMethodMaker
  (
    'widget --get_set_delete' => 'foo',

    'widget' => 
    [
      'bar',
      'baz',
    ]
  );
  ...

  $o = MyObject->new;

  $o->foo($bar);
  $o->delete_foo();

  print $o->bar . $o->baz;
  ...

=head1 DESCRIPTION

L<Rose::Object::MakeMethods> is the base class for a family of method makers. A method maker is a module that's used to define methods in other packages. The actual method makers are subclasses of L<Rose::Object::MakeMethods> that define the names and options of the different kinds of methods that they can make.

There are method makers that make both object methods and class methods. The object method makers are in the C<Rose::Object::MakeMethods::*> namespace. The class method makers are in the C<Rose::Class::MakeMethods::*> namespace for the sake of clarity, but still inherit from L<Class::MethodMaker> and therefore share the same method making interface.

Several useful method makers are included under the C<Rose::Object::MakeMethods::*> and C<Rose::Class::MakeMethods::*> namespaces, mostly for use by other C<Rose::*> objects and classes.

This family of modules is not as powerful or flexible as the one that inspired it: L<Class::MethodMaker>.  I found that I was only using a tiny corner of the functionality provided by L<Class::MethodMaker>, so I wrote this as a simple, smaller replacement.

The fact that many C<Rose::*> modules use L<Rose::Object::MakeMethods> subclasses to make their methods should be considered an implementation detail that can change at any time.

=head1 CLASS METHODS

=over 4

=item B<allow_apparent_reload [BOOL]>

Get or set an attribute that determines whether or not to allow an attempt to re-make the same method using the same class that made it earlier.  The default is true.

This issue comes up when a module is forcibly reloaded, e.g., by L<Apache::Reload> or L<Apache::StatINC>.  When this happens, all the "make methods" actions will be attempted again.  In the absence of the C<preserve_existing> or C<override_existing> options, the L<allow_apparent_reload|/allow_apparent_reload> attribute will be consulted.  If it's true, and if it appears that the method in question was made by this method-maker class, then it behaves as if the C<preserve_existing> option had been passed.  If it is false, then a fatal "method redefined" error will occur.

=item B<import SPEC>

The C<import> class method is mean to be called implicitly as a result of a C<use> statement.  For example:

    use Rose::Object::MakeMethods::Generic
    (
      SPEC
    );

is roughly equivalent to:

    require Rose::Object::MakeMethods::Generic;
    Rose::Object::MakeMethods::Generic->import(SPEC);

where SPEC is a series of specifications for the methods to be created. (But don't call L<import|/import> explicitly; use L<make_methods|/make_methods> instead.)

In response to each method specification, one or more methods are created.

The first part of the SPEC argument is an optional hash reference whose contents are intended to modify the behavior of the method maker class itself, rather than the individual methods being made.  There are currently only two valid arguments for this hash:

=over 4

=item B<target_class CLASS>

Specifies that class that the methods will be added to.  Defaults to the class from which the call was made.  For example, this:

    use Rose::Object::MakeMethods::Generic
    (
      { target_class => 'Foo' },
      ...
    );

Is equivalent to this:

    package Foo;

    use Rose::Object::MakeMethods::Generic
    (
      ...
    );

In general, the C<target_class> argument is omitted since methods are usually indented to end up in the class of the caller.

=item B<override_existing BOOL>

By default, attempting to create a method that already exists will result in a fatal error.  But if the C<override_existing> option is set to a true value, the existing method will be replaced with the generated method.

=item B<preserve_existing BOOL>

By default, attempting to create a method that already exists will result in a fatal error.  But if the C<preserve_existing> option is set to a true value, the existing method will be left unmodified.  This option takes precedence over the C<override_existing> option.

=back

After the optional hash reference full off options intended for the method maker class itself, a series of method specifications should be provided.  Each method specification defines one or more named methods. The components of such a specification are:

=over 4

=item * The Method Type

This is the name of the subroutine that will be called in order to generated the methods (see SUBCLASSING for more information).  It describes the nature of the generated method.  For example, "scalar", "array", "bitfield", "object"

=item * Method Type Arguments

Name/value pairs that are passed to the method maker of the specified type in order to modify its behavior.

=item * Method Names

One or more names for the methods that are to be created.  Note that a method maker of a particular type may choose to modify or ignore these names.  In the common case, for each method name argument, a single method is created with the same name as the method name argument.

=back

Given the method type C<bitfield> and the method arguments C<opt1> and C<opt2>, the following examples show all valid forms for method specifications, with equivalent forms grouped together.

Create a bitfield method named C<my_bits>:

   bitfield => 'my_bits'

   bitfield => [ 'my_bits' ],

   bitfield => [ 'my_bits' => {} ],

Create a bitfield method named C<my_bits>, passing the C<opt1> argument with a value of 2.

   'bitfield --opt1=2' => 'my_bits'

   'bitfield --opt1=2' => [ 'my_bits' ]

   bitfield => [ 'my_bits' => { opt1 => 2 } ]

Create a bitfield method named C<my_bits>, passing the C<opt1> argument with a value of 2 and the C<opt2> argument with a value of 7.

   'bitfield --opt1=2 --opt2=7' => 'my_bits'

   'bitfield --opt1=2 --opt2=7' => [ 'my_bits' ]

   bitfield => [ 'my_bits' => { opt1 => 2, opt2 => 7 } ]

   'bitfield --opt2=7' => [ 'my_bits' => { opt1 => 2 } ]

In the case of a conflict between the options specified with the C<--name=value> syntax and those provided in the hash reference, the ones in the hash reference take precedence.  For example, these are equivalent:

   'bitfield --opt1=99' => 'my_bits'

   'bitfield --opt1=5' => [ 'my_bits' => { opt1 => 99 } ]

If no value is provided for the first option, and if it is specified using the C<--name> syntax, then it is taken as the I<value> of the C<interface> option.  That is, this:

    'bitfield --foobar' => 'my_bits'

is equivalent to these:

    'bitfield --interface=foobar' => 'my_bits'

    bitfield => [ my_bits => { interface => 'foobar' } ]

This shortcut supports the convention that the C<interface> option is used to decide which set of methods to create.  But it's just a convention; the C<interface> option is no different from any of the other options when it is eventually passed to the method maker of a given type.

Any option other than the very first that is specified using the C<--name> form and that lacks an explicit value is simply set to 1. That is, this:

    'bitfield --foobar --baz' => 'my_bits'

is equivalent to these:

    'bitfield --interface=foobar --baz=1' => 'my_bits'

    bitfield => 
    [
      my_bits => { interface => 'foobar', baz => 1 }
    ]

Multiple method names can be specified simultaneously for a given method type and set of options.  For example, to create methods named C<my_bits[1-3]>, all of the same type and with the same options, any of these would work:

     'bitfield --opt1=2' => 
     [
       'my_bits1',
       'my_bits2',
       'my_bits3',
     ]

     bitfield => 
     [
       'my_bits1' => { opt1 => 2 },
       'my_bits2' => { opt1 => 2 },
       'my_bits3' => { opt1 => 2 },
     ]

When options are provided using the C<--name=value> format, they apply to all methods listed inside the array reference, unless overridden. Here's an example of an override:

     'bitfield --opt1=2' => 
     [
       'my_bits1',
       'my_bits2',
       'my_bits3' => { opt1 => 999 },
     ]

In this case, C<my_bits1> and C<my_bits2> use C<opt1> values of 2, but C<my_bits3> uses an C<opt1> value of 999.  Also note that it's okay to mix bare method names (C<my_bits1> and C<my_bits2>) with method names that have associated hash reference options (C<my_bits3>), all inside the same array reference.

Finally, putting it all together, here's a full example using several different formats.

    use Rose::Object::MakeMethods::Generic
    (
      { override_existing => 1 },

      'bitfield' => [ qw(my_bits other_bits) ],

      'bitfield --opt1=5' => 
      [
        'a',
        'b',
      ],

      'bitfield' =>
      [
        'c',
        'd' => { opt2 => 7 },
        'e' => { opt1 => 1 },
        'f' => { }, # empty is okay too
      ]
    );

In the documentation for the various L<Rose::Object::MakeMethods> subclasses, any of the valid forms may be used in the examples.

=item B<make_methods SPEC>

This method is equivalent to the C<import> method, but makes the intent of the code clearer when it is called explicitly.  (The C<import> method is only meant to be called implicitly by C<use>.)

=back

=head1 SUBCLASSING

In order to make a L<Rose::Object::MakeMethods> subclass that can actually make some methods, simply subclass L<Rose::Object::MakeMethods> and define one subroutine for each method type you want to support.

The subroutine will be passed three arguments when it is called:

=over 4

=item * The class of the method maker as a string.  This argument is usually ignored unless you are going to call some other class method.

=item * The method name.  In the common case, a single method with this name is defined, but you are free to do whatever you want with it, including ignoring it.

=item * A reference to a hash containing the options for the method.

=back

The subroutine is expected to return a reference to a hash containing name/code reference pairs.  Note that the subroutine does not actually install the methods.  It simple returns the name of each method that is to be installed, along with references to the closures that contain the code for those methods.

This subroutine is called for each I<name> in the method specifier.  For example, this would result in three separate calls to the C<bitfield> subroutine of the C<MyMethodMaker> class:

    use MyMethodMaker
    (
      bitfield => 
      [
        'my_bits',
        'your_bits'  => { size => 32 },
        'other_bits' => { size => 128 },
      ]
    );

So why not have the subroutine return a single code reference rather than a reference to a hash of name.code reference pairs?  There are two reasons.

First, remember that the name argument ("my_bits", "your_bits", "other_bits") may be modified or ignored by the method maker.  The actual names of the methods created are determined by the keys of the hash reference returned by the subroutine.

Second, a single call with a single method name argument may result in the creation more than one method--usually a "family" of methods.  For example:

    package MyObject;

    use MyMethodMaker
    (
      # creates add_book(), delete_book(), and books() methods
      'hash --manip' => 'book',
    );
    ...

    $o = MyObject->new(...);

    $o->add_book($book);

    print join("\n", map { $_->title } $o->books);

    $o->delete_book($book);

Here, the C<hash> method type elected to create three methods by prepending C<add_> and C<delete_> and appending C<s> to the supplied method name argument, C<book>.

Anything not specified in this documentation is simply a matter of convention.  For example, the L<Rose::Object::MakeMethods> subclasses all use a common set of method options: C<hash_key>, C<interface>, etc.  As you read their documentation, this will become apparent.

Finally, here's an example of a subclass that makes scalar accessors:

    package Rose::Object::MakeMethods::Generic;

    use strict;
    use Carp();

    use Rose::Object::MakeMethods;
    our @ISA = qw(Rose::Object::MakeMethods);

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
        $methods{$name} = sub
        {
          return $_[0]->{$key} = $_[1]  if(@_ > 1);
          return $_[0]->{$key};
        }
      }
      else { Carp::croak "Unknown interface: $interface" }

      return \%methods;
    }

It can be used like this:

    package MyObject;

    use Rose::Object::MakeMethods::Generic
    (
      scalar => 
      [
        'power',
        'error',
      ],

      'scalar --get_set_init' => 'name',
    );

    sub init_name { 'Fred' }
    ...

    $o = MyObject->new(power => 5);

    print $o->name; # Fred

    $o->power(99) or die $o->error;

This is actually a subset of the code in the actual L<Rose::Object::MakeMethods::Generic> module.  See the rest of the C<Rose::Object::MakeMethods::*> and C<Rose::Class::MakeMethods::*> modules for more examples.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
