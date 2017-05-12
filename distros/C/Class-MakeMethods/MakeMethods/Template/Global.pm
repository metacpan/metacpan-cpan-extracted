package Class::MakeMethods::Template::Global;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.0;

=head1 NAME

Class::MakeMethods::Template::Global - Method that are not instance-dependent

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Global (
    scalar          => [ 'foo' ]
  );
  
  package main;

  MyObject->foo('bar')
  print MyObject->foo();
  ...
  print $my_instance->foo(); # same thing

=head1 DESCRIPTION

These meta-methods access values that are shared across all instances
of your object in your process. For example, a hash_scalar meta-method
will be able to store a different value for each hash instance you
call it on, but a static_scalar meta-method will return the same
value for any instance it's called on, and setting it from any
instance will change the value that all other instances see.

B<Common Parameters>: The following parameters are defined for Static meta-methods.

=over 4

=item data

The shared value.

=back

=cut

sub generic {
  {
    '-import' => { 
      'Template::Generic:generic' => '*' 
    },
    'code_expr' => { 
      _VALUE_ => '_ATTR_{data}',
    },
    'params' => {
      'data' => undef, 
    }
  }
}

########################################################################

=head2 Standard Methods

The following methods from Generic should be supported:

  scalar
  string
  number 
  boolean
  bits (?)
  array
  hash
  tiedhash (?)
  hash_of_arrays (?)
  object
  instance
  array_of_objects (?)
  code
  code_or_scalar (?)

See L<Class::MakeMethods::Template::Generic> for the interfaces and behaviors of these method types.

The items marked with a ? above have not been tested sufficiently; please inform the author if they do not function as you would expect.

=head1  SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Template> for more about this family of subclasses.

See L<Class::MakeMethods::Template::Generic> for information about the various accessor interfaces subclassed herein.

=cut

1;
