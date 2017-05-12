package Class::WeakSingleton;

use 5.006;
use strict;
use warnings;

=head1 NAME

Class::WeakSingleton - A Singleton that expires when all the references to it expire

=cut

our $VERSION = '1.05';

=head1 DESCRIPTION

This is the Class::WeakSingleton module. A Singleton describes an
object class that can have only one instance in any system. An example
of a Singleton might be a print spooler, system registry or database
connection. A "weak" Singleton is not immortal and expires when all
other references to the original instance have expired. This module
implements a Singleton class from which other classes can be derived,
just like L<Class::Singleton>. By itself, the Class::WeakSingleton
module does very little other than manage the instantiation of a
single object. In deriving a class from Class::WeakSingleton, your
module will inherit the Singleton instantiation method and can
implement whatever specific functionality is required.

For a description and discussion of the Singleton class, see
L<Class::Singleton> and "Design Patterns", Gamma et al,
Addison-Wesley, 1995, ISBN 0-201-63361-2.

=head1 SYNOPSIS

  use Class::WeakSingleton;
 
  {
      my $c = Class::WeakSingleton->instance;
      my $d = Class::WeakSingleton->instance;
      die "Mismatch" if $c != $d;
  }   # Class::WeakSingleton->instance expires
  {
      my $e = Class::WeakSingleton->instance;
      {
          my $f = Class::WeakSingleton->instance;
          die "Mismatch" if $e != $f;
      }
  }   # Class::WeakSingleton->instance expires

=head1 OVERRIDABLE CLASS METHODS

=over

=item $singleton = YourClass->instance(...)

Module constructor. Creates an Class::WeakSingleton (or derivative)
instance if one doesn't already exist. A weak reference is stored in
the C<$_instance> variable of the parent package. This means that
classes derived from Class::WeakSingleton will have the variables
defined in *THEIR* package, rather than the Class::WeakSingleton
package. Also, because the stored reference is weak it will be deleted
when all other references to the returned object have been
deleted. The first time the instance is created, the C<<
YourClass->_new_instance(...) >> constructor is called which simply
returns a reference to a blessed hash. This can be overloaded for
custom constructors. Any additional parameters passed to C<<
YourClass->instance(...) >> are forwarded to C<<
YourClass->_new_instance(...) >>.

Returns a normal reference to the existing, or a newly created
Class::WeakSingleton object. If the C<< ->_new_instance(...) >> method
returns an undefined value then the constructer is deemed to have
failed.

=cut

use Scalar::Util 'weaken';

sub instance {

    # instance()

    my $class = shift;

    # get a reference to the _instance variable in the $class package
    my $instance = do {
        ## no critic
        no strict 'refs';
        \${ $class . "::_instance" };
    };

    return $$instance if defined $$instance;

    my $new_instance = $$instance = $class->_new_instance(@_);

    weaken $$instance;

    return $new_instance;
}

=item $singleton = YourClass->_new_instance(...)

Simple constructor which returns a hash reference blessed into the
current class. May be overloaded to create non-hash objects or handle
any specific initialisation required.

Returns a reference to the blessed hash.

=cut

sub _new_instance {
    my $class = shift;

    return bless {}, $class;
}

=back

=head1 USING THE Class::WeakSingleton MODULE

To import and use the Class::WeakSingleton module the following line
should appear in your Perl script:

  use Class::WeakSingleton;

The C<< Class::WeakSingleton->instance(...) >> method is used to
create a new Class::WeakSingleton instance, or return a reference to
an existing instance. Using this method, it is only possible to have a
single instance of the class in any system at any given time. The
instance expires when all references to it also expire.

  {
      my $highlander = Class::WeakSingleton->instance();

Assuming that no Class::WeakSingleton object currently exists, this
first call to C<< Class::WeakSingleton->instance(...) >> will create a
new Class::WeakSingleton object and return a reference to it.  Future
invocations of C<< Class::WeakSingleton->instance(...)  >> will return
the same reference.

      my $macleod    = Class::WeakSingleton->instance();
  }

In the above example, both C<$highlander> and C<$macleod> contain the
same reference to a Class::WeakSingleton instance. There can be only
one.  Except that now that both C<$highlander> and C<$macleod> went
out of scope the singleton did also. So MacLeod is now dead. Boo hoo.

=head1 DERIVING Class::WeakSingleton CLASSES

A module class may be derived from Class::WeakSingleton and will
inherit the C<< ->instance(...) >> method that correctly instantiates
only one object.

  package Database;
  use base 'Class::WeakSingleton';

  # derived class specific code
  sub user_name { shift()->{user_name} }
  sub login {
      my $self = shift;
      my ($user_name, $user_pass) = @_;

      return unless $user_name eq 'JJORE'
                and $user_pass eq 'sekret';

        $self->{user_name} = $user_name;

      return 1;
  }

The Database class defined above could be used as follows:

    use Database;

    do_somestuff();
    do_somestuff();

    sub do_somestuff {
        my $db = Database->instance();

        $db->login(...);
    }

The C<< Database->instance() >> method calls the C<<
Database->_new_instance() >> constructor method the first and only
time a new instance is created (until the instance expires and then it
starts over). All parameters passed to the C<< Database->instance() >>
method are forwarded to C<< Database->_new_instance() >>. In the base
class this method returns a blessed reference to an empty hash array.
Derived classes may redefine it to provide specific object
initialisation or change the underlying object type (to a array
reference, for example).

  package MyApp::Database;
  use base 'Class::WeakSingleton';
  use DBI;

  # Object is an array ref, here are the names for the values
  use constant DB => 0;

  our $ERROR = '';

  # this only gets called the first time instance() is called
  sub _new_instance {
      my $class = shift;
      my $self  = bless [], $class;
      my $db    = shift || "myappdb";
      my $host  = shift || "localhost";

      $self->[ DB ] = DBI->connect("DBI:mSQL:$db:$host")
      if ( not defined $self->[DB] ) {
          $ERROR = "Cannot connect to database: $DBI::errstr\n";
          return undef;
      }

      # any other initialisation...

      # return sucess
      return $self;
  }

Some time later on in a module far, far away...

  package MyApp::FooBar
  use MyApp::Database;

  sub new {
      # usual stuff...

      # this FooBar object needs access to the database; the Singleton
      # approach gives a nice wrapper around global variables.

      # new instance is returned
      my $database = MyApp::Database->instance();

      # more stuff...
      # call some methods
  }

  sub some_methods {
      # more usual stuff

      # Get the same object that was used in new()
      my $database = MyApp::Database->instance;
  }

The Class::WeakSingleton instance() method uses a package variable to
store a reference to any existing instance of the object. This
variable, <$_instance>, is coerced into the derived class package
rather than the base class package.

Thus, in the MyApp::Database example above, the instance variable
would be C<$MyApp::Database::_instance>.

This allows different classes to be derived from Class::WeakSingleton
that can co-exist in the same system, while still allowing only one
instance of any one class to exists.  For example, it would be
possible to derive both 'Database' and 'MyApp::Database' from
Class::WeakSingleton and have a single instance of each.

=head1 AUTHOR

Joshua ben Jore <jjore@cpan.org>

Thanks to Andy Wardley for writing Class::Singleton.

=head1 COPYRIGHT

Copyright (C) 2006 Joshua ben Jore. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the term of the Perl Artistic License.

=head1 SEE ALSO

=over

=item L<Class::Singleton>

=item Design Patterns

Class::WeakSingleton is an implementation of the Singleton class described in 
"Design Patterns", Gamma et al, Addison-Wesley, 1995, ISBN 0-201-63361-2

=back

=cut

