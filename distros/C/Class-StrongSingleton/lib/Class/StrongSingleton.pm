
package Class::StrongSingleton;

use strict;
use warnings;

our $VERSION = '0.02';

my %instances;
my %constructors;
	
## protected initializer
sub _init_StrongSingleton {
	# do not let us be called by anything which
	# is not derived from Class::StrongSingleton
    (UNIVERSAL::isa((caller)[0], 'Class::StrongSingleton')) 
        || die "Illegal Operation : _init_StrongSingleton can only be called by a subclass of Class::StrongSingleton";	
	my ($self) = @_;
	(ref($self))
		|| die "Illegal Operation : _init_StrongSingleton can only be called as an instance method";
	# get the class name
	my $class = ref($self);
	(!exists($instances{$class})) 
		|| die "Illegal Operation : cannot call _init_StrongSingleton with a valid Singleton instance";
	# assuming new was the name of our
	# constructor, otherwise ...
	my $constructor = $self->can("new");
	(defined($constructor)) 
		|| die "Illegal Operation : Singleton objects must have a 'new' method";
	# store the constructor for later
	$constructors{$class} = $constructor;
	# put the instance in the instances table
	$instances{$class} = $self;	
	no strict 'refs';
	no warnings 'redefine';	
	# then override the new method to return the
	# single instance. 
	*{"${class}::new"} = sub { return $_[0]->instance() };				
}

# for backwards compatability we retain the old _init
*_init = \&_init_StrongSingleton;

### destructor
sub DESTROY {
	my ($self) = @_;
	# get the class name
	my $class = ref($self) || $self;
	# if there is no valid singleton, then 
	# we can just return
	return unless exists($instances{$class});	
	# otherwise ...
	no strict 'refs';
	no warnings 'redefine';
	# return the contructor to its original state
	*{"${class}::new"} = $constructors{$class};
	# delete completely the unique instance
	delete $instances{$class};
	# at this point all should be back to normal	
}

### methods

sub instance {
	my $self = shift;
	# get the class name or 
	# if it is being called from 
	# the class, then use that string
	my $class = ref($self) || $self;
	# return single instance of self, assuming there is one
	return $instances{$class} if exists $instances{$class};
	# otherwise we call new for you
	return $class->new(@_);
}

1;

__END__

=head1 NAME

Class::StrongSingleton - A stronger and more secure Singleton base class.

=head1 SYNOPSIS

  package My::Singleton::Class;

  use base qw(Class::StrongSingleton);
  
  sub new {
     my ($class, %my_params) = @_;
	 # create our object instance
	 my $instance = { %my_params };
	 bless($instance, $class);
	 # and initialize it as a singleton
	 $instance->_init_StrongSingleton();
	 return $instance;
  }
  
  1;
  
  # later in your code ...
  
  # create the first instance of our class
  my $instance = My::Singleton::Class->new(param => "value");
  
  # try to create a 'new' one again, and
  # you end up with the same instance, not
  # a new one
  my $instance2 = My::Singleton::Class->new(param => "other value");

  # calling 'instance' returns the singleton
  # instance expected
  my $instance3 = My::Singleton::Class->instance();
  
  # although rarely needed, if you have to
  # you can destroy the singleton
  
  # either through the instance
  $instance->DESTROY();
  # or through the class
  My::Singleton::Class->DESTROY();
  
  # of course, this is assuming you 
  # did not override DESTORY yourself
  
  # Also calling 'instance' before calling 'new'
  # will returns a new singleton instance
  my $instance = My::Singleton::Class->instance();  

=head1 DESCRIPTION

This module is an alternative to L<Class::Singleton> and L<Class::WeakSingleton>, and provides a more secure Singleton class in that it takes steps to prevent the possibility of accidental creation of multiple instances and/or the overwriting of existsing Singleton instances. For a detailed comparison please see the L<SEE ALSO> section.

Here is a description of how it all works. First, the user creates the first Singleton instance of the class in the normal way.

  my $obj = My::Singleton::Class->new("variable", "parameter");

This instance is then stored inside a lexically scoped variable within the Class::StrongSingleton package. This prevents the variable from being accessed by anything but methods from the Class::StrongSingleton package. At this point as well, the C<new> method to the class is overridden so that it will always return the Singleton instance. This prevents any accidental overwriting of the Singleton instance. This means that any of the follow lines of code all produce the same instance:

  my $instance = $obj->instance();
  my $instance = My::Singleton::Class->instance();
  my $instance = $obj->new();
  my $instance = My::Singleton::Class->new();

Personally, I see this an an improvement over the usual I<Gang of Four> style Singletons which discourages the use of the 
C<new> method entirely. Through this method, a user can be able to use the Singleton class in a normal way, not having to know it's actually a Singleton. This can be handy if your design changes and you no longer need the class as a Singleton.

=head1 METHODS

=over 4

=item B<_init_StrongSingleton>

This method is used to initialize the Singleton instance, your class B<must> call this. This is a protected method, meaning it can only be called by a subclass of Class::StrongSingleton, otherwise it will throw an exception. It also must be called as an instance method and not as a class method, which means that your constructor should look something like this:

  sub new {
	my $class = shift;
	my $instance = bless({}, $class);
	$instance->_init_StrongSingleton();
	return $instance;
  }

You also may not call C<_init_StrongSingleton> once a Singleton instance has been established, if you do, and exception will be thrown. This is an unlikely error, but one that may come up if your class has complex initializers. In general you want the Class::StrongSingleton C<_init_StrongSingleton> method to be the last step in your class initialization process. It should be noted, that this module performs just fine in multiple inheritance situations, just be sure the C<_init_StrongSingleton> method gets properly called.

It is also important to note that there currently is a restriction on constructor names. Your class constructor must be named C<new>, if it is not an exception is thrown in this method. This is because we I<hijack> the constructor function to insure that no new instances are created, and need to be able to access it by name. In future versions (if there is request for it) I will put in functionality to be able to specify a specific constructor name.

B<NOTE:>
In version 0.01 this method was called C<_init>, but since that is all too common a name, and could easily be accidentely overridden in a subclass, it has been changed. However to maintain backwards compatability, C<_init> has been aliased to C<_init_StrongSingleton>.

=item B<instance>

If a Singleton instance already exists for the calling class, this will return that instance. Otherwise it will attempt to call C<new> on the class, and pass any arguments it may have been given.

=item B<DESTROY>

B<WARNING:> As you may have already know, this functionality is a dangerous thing, and something not to be done lightly. Make sure you have a really good reason to do it, otherwise you might want to rethink your usage of Singletons.

That said, I felt it a good idea to include some means of destruction for these Singleton class instances. While more often than not you will want your Singleton to never go out of scope and therefore never need to be destroyed (except maybe during global destruction when the interpreter is exiting), there might be sometimes in a long running system/application that it would be desireable to have the ability to DESTROY (or refresh/reload) the Singleton instance of your class. So for these reasons i have also implemented a destructor for the class (using the built in DESTROY method). 

This destructor will clean up/restore all of the changes made by the C<_init_StrongSingleton> method, so that you class will be restored back to it's original state. Keep in mind, that perl will never call this DESTROY method itself, since there will always be a reference to the Singleton instance stored internally. So if you want to create a new instance you must call the DESTROY method yourself.

  my $instance1 = $obj->instance();
  $obj->DESTORY()
  my $instance2 = SingletonDerivedObject->new();
	
Now the Singleton instance stored in $instance1 is different than the Singleton instance in $instance2. 

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. This code is derived from code which has been in production use for over 2 years without incident.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Class/StrongSingleton.pm  100.0  100.0   66.7  100.0  100.0  100.0   97.1
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0  100.0   66.7  100.0  100.0  100.0   97.1
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

This module is an alternative to L<Class::Singleton> and L<Class::WeakSingleton>, and provides a more secure Singleton class in that it takes steps to prevent the possibility of accidental creation of multiple instances and/or the overwriting of existsing Singleton instances.

If you think this module is ridiculous overkill written by a paranoid freak, then by all means, use either L<Class::Singleton> or L<Class::WeakSingleton>, I will not be offended. However, if you think I may not be as crazy as people some think, then here is a list of what I see as valuable additions/changes that this module contributes to the world of perl Singletons. 

=over 4

=item The actual Singleton instance is not accessable to any other module.

Both Class::Singleton and Class::WeakSingleton store the Singleton instance in a package variable called C<_instance> which is easily accessable from anywhere else in your code. I know this is just another case of "don't go there because you were not invited", personally I just don't like the idea that the Singleton is unprotected.

Class::StrongSingleton stores the Singleton instance in a lexically scoped package variable within the Class::StrongSingleton package itself, so short of some crazy low level pad-walking, you cannot get to it.

=item Classes can have 'normal' constructors.

The original Gang of Four Singleton pattern calls for the method C<instance> to be used to call a private or protected constructor. I feel this restriction has more to do with the C++ language than it does with common sense. Both Class::Singleton and Class::WeakSingleton expect you to call C<instance>, and to implement a private constructor called C<_new_instance>, which the subclasser is expected to override. 

Class::StrongSingleton takes a different approach, to initialize your Singleton, you must call C<_init_StrongSingleton> as an instance method on a subclass of Class::StrongSingleton. An C<instance> method is provided, but it is not the only constructor, but instead, just an accessor for the Singleton instance. Class::StrongSingleton allows you to use the standard constructor C<new> to create your Singleton, and then I<hijacks> the C<new> method so that it will only ever return the Singleton instance. 

All this may sound complicated (or maybe just stupid), but I do have my reasons. Singletons are a design "trick" to get around global variables, and sometimes can be overused/abused. On occasion, I have found myself refactoring out Singletons, to improve the design and/or efficiency of an application. Using the style of this module where C<new> can be used quite normally, it makes it much easier to remove Singletons. 

=item It is very difficult to create duplicate or errant instances of a Singleton.

With both Class::Singleton and Class::WeakSingleton a simple call to C<_new_instance> will result in a non-Singleton instance of your Singleton class. Yes, yes, I know,... this is another case of "don't go there because you were not invited". 

With Class::StrongSingleton; calling C<new> will return the Singleton, calling C<instance> will return the Singleton and directly calling C<_init_StrongSingleton> will result in an exception. A class must purposfully create a constructor method which bypasses  Class::StrongSingleton in order to create a duplicate or errant instance. 

=back

Once again, I am clearly a paranoid programmer, and you may be thinking 'Why doesn't this freak just use Java or something???'. But the fact is, I love programming in perl precisiely because I can do silly stuff like this. If you don't like/appreciate/care-for this style/methodology/illness then just don't use it, I I<really> will not be offended at all :)

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

