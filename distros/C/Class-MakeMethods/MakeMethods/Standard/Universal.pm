=head1 NAME

Class::MakeMethods::Standard::Universal - Generic Methods


=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Standard::Universal (
    no_op => 'this',
    abstract => 'that',
    delegate => { name=>'play_music', target=>'instrument', method=>'play' },
  );


=head1 DESCRIPTION

The Standard::Universal suclass of MakeMethods provides a [INCOMPLETE].

=head2 Calling Conventions

When you C<use> this package, the method names you provide
as arguments cause subroutines to be generated and installed in
your module.

See L<Class::MakeMethods::Standard/"Calling Conventions"> for more information.

=head2 Declaration Syntax

To declare methods, pass in pairs of a method-type name followed
by one or more method names. 

Valid method-type names for this package are listed in L<"METHOD
GENERATOR TYPES">.

See L<Class::MakeMethods::Standard/"Declaration Syntax"> and L<Class::MakeMethods::Standard/"Parameter Syntax"> for more information.

=cut

package Class::MakeMethods::Standard::Universal;

$VERSION = 1.000;
use strict;
use Carp;
use Class::MakeMethods::Standard '-isasubclass';

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 no_op - Placeholder

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Does nothing.

=back

You might want to create and use such methods to provide hooks for
subclass activity.

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Universal (
    no_op => 'whatever',
  );
  ...
  
  # Doesn't do anything
  MyObject->whatever();

=cut

sub no_op {
  map { 
    my $method = $_;
    $method->{name} => sub { }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 abstract - Placeholder

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Fails with an error message.

=back

This is intended to support the use of abstract methods, that must
be overidden in a useful subclass.

If each subclass is expected to provide an implementation of a given method, using this abstract method will replace the generic error message below with the clearer, more explicit error message that follows it:

  Can't locate object method "foo" via package "My::Subclass"
  The "foo" method is abstract and can not be called on My::Subclass

However, note that the existence of this method will be detected by UNIVERSAL::can(), so it is not suitable for use in optional interfaces, for which you may wish to be able to detect whether the method is supported or not.

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Universal (
    abstract => 'whatever',
  );
  ...
  
  package MySubclass;
  sub whatever { ... }
  
  # Failure
  MyObject->whatever();
  
  # Success
  MySubclass->whatever();

=cut

sub abstract {
  map { 
    my $method = $_;
    $method->{name} => sub { 
      my $self = shift;
      my $class = ref($self) ? "a " . ref($self) . " object" : $self;
      croak("The $method->{name} method is abstract and can not be called on $class");
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 call_methods - Call methods by name

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Accepts a hash of key-value pairs, or a reference to hash of such pairs. For each pair, the key is interpreted as the name of a method to call, and the value is the argument to be passed to that method.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Universal (
    call_methods => 'init',
  );
  ...
  
  my $object = MyObject->new()
  $object->init( foo => 'Foozle', bar => 'Barbados' );
  
  # Equivalent to:
  $object->foo('Foozle');
  $object->bar('Barbados');

=cut

sub call_methods {
  map { 
    my $method = $_;
    $method->{name} => sub { 
      my $self = shift;
      local @_ = %{$_[0]} if ( scalar @_ == 1 and ref($_[0]) eq 'HASH');
      while (scalar @_) { 
	my $key = shift;
	$self->$key( shift ) 
      }
    }
  } (shift)->_get_declarations(@_)
}


########################################################################

=head2 join_methods - Concatenate results of other methods

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Has a list of other methods names as an arrayref in the 'methods' parameter. B<Required>.

=item *

When called, calls each of the named method on itself, in order, and returns the concatenation of their results.

=item *

If a 'join' parameter is provided it is included between each method result.

=item *

If the 'skip_blanks' parameter is omitted, or is provided with a true value, removes all undefined or empty-string values from the results.

=back

=cut

sub join_methods {
  map { 
    my $method = $_;
    $method->{methods} or confess;
    $method->{join} = '' if ( ! defined $method->{join} );
    $method->{skip_blanks} = '1' if ( ! defined $method->{skip_blanks} );
    $method->{name} => sub { 
      my $self = shift;
      my $joiner = $method->{join};
      my @values =  map { $self->$_() } @{ $method->{methods} };
      @values = grep { defined and length } @values if ( $method->{skip_blanks} );
      join $joiner, @values;
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 alias - Call another method

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Calls another method on the same callee.

=back

You might create such a method to extend or adapt your class' interface.

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Universal (
    alias => { name=>'click_here', target=>'complex_machinery' }
  );
  sub complex_machinery { ... }
  ...
  
  $myobj->click_here(...); # calls $myobj->complex_machinery(...)

=cut

sub alias {
  map { 
    my $method = $_;
    $method->{name} => sub { 
      my $self = shift;
      
      my $t_method = $method->{target} or confess("no target");
      my @t_args = $method->{target_args} ? @{$method->{target_args}} : ();
      
      $self->$t_method(@t_args, @_);
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 delegate - Use another object to provide method

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Calls a method on self to retrieve another object, and then calls a method on that object and returns its value.

=back

You might want to create and use such methods to faciliate composition of objects from smaller objects.

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Universal (
    'Standard::Hash:object' => { name=>'instrument' },
    delegate => { name=>'play_music', target=>'instrument', method=>'play' }
  );
  ...
  
  my $object = MyObject->new();
  $object->instrument( MyInstrument->new );
  $object->play_music;

=cut

sub delegate {
  map { 
    my $method = $_;
    $method->{method} ||= $method->{name};
    $method->{name} => sub { 
      my $self = shift;
      
      my $t_method = $method->{target} or confess("no target");
      my @t_args = $method->{target_args} ? @{$method->{target_args}} : ();
      
      my $m_method = $method->{method} or confess("no method");
      my @m_args = $method->{method_args} ? @{$method->{method_args}} : ();
      push @m_args, $self if ( $method->{target_args_self} );
      
      my $obj = $self->$t_method( @t_args )
	or croak("Can't delegate $method->{name} because $t_method is empty");
      
      $obj->$m_method(@m_args, @_);
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Standard> for more about this family of subclasses.

=cut

1;
