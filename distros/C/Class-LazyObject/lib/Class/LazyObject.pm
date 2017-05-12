package Class::LazyObject;
use strict;
use warnings;

use Carp qw();

BEGIN {
	use vars '$VERSION';
	$VERSION     = '0.10';
}

use vars '$AUTOLOAD';

#We want to inflate calls to methods defined in UNIVERSAL, but we implicitly inherit from UNIVERSAL.
#As long as we predeclare the methods here, they will override those in UNIVERSAL, but since they are never defined, AUTOLOAD will be called:
use subs grep {defined UNIVERSAL::can(__PACKAGE__, $_)} keys %UNIVERSAL::;

sub AUTOLOAD
{
	my $self = $_[0]; #don't shift it, since we will need to access this directly later.

	$AUTOLOAD =~ /.*::(\w+)/;	
	my $method = $1;
	
	my $class_method = (ref($self) || $self).'::Methods';#call all class methods on this.
	
	if (($method eq 'new') && !ref($self))
	{
		#new was called on a class, rather than an object, so we should actually construct ourselves, rather than passing this to whatever we're proxying.
		return $class_method->new(@_);
	}
	
	ref($self) or return $class_method->$method(@_[ 1 .. $#_ ]); #If this was called as a class method, pass it on to ::Methods but don't pass OUR package name.
	
	print "Lazy...\n" if $class_method->get_classdata('debug');
	
	my $object; #this is the object we will eventually replace ourselves with.
	
	if ( ref($$self) && UNIVERSAL::isa($$self, $class_method->get_classdata('class')) )
	{
		$object = $$self;
	}
	else
	{
		$object = $class_method->get_classdata('inflate')->($class_method->get_classdata('class'), $$self);
		$$self = $object; #don't create this again.
	}
	
	$_[0] = $object; #replace ourselves with the object.
		
	goto (
		 	UNIVERSAL::can($_[0], $method) || 
		 	$class_method->_prepareAUTOLOADRef($_[0], ref($_[0]).'::'.$method) || #UNIVERSAL::can can't detect if a method is AUTOLOADed, so we have to.
		 	Carp::croak(sprintf qq{Can\'t locate object method "%s" via package "%s" }, $method, ref $_[0] )#Error message stolen from Class::WhiteHole
		 );
}	

sub DESTROY #You won't AUTOLOAD this! Muahahaha!
{
	undef; #This is here because certain perl versions can't handle completely emtpy subs.
}


#class method to see whether something is lazy?
#class methods for original isa and can

#---------
package Class::LazyObject::Methods;
#stick all of our class methods here so we don't pollute Class::LazyObject's namespace.
#everything in this class should be called as class methods, NOT object methods.

use Carp::Clan '^Class::LazyObject(::|$)';
use Class::Data::TIN  qw(get_classdata);
use Class::ISA;

sub _findAUTOLOADPackage
{
	#Takes 1 argument, either an object or the name of a package.
	#Returns the name of the package containing the sub AUTOLOAD that would be called when $first_arg->AUTOLOAD was called
	#In other words, it traverses the inheritance hierarchy the same way Perl does until it finds an AUTOLOAD, and returns the name of the package containing the AUTOLOAD.
	#Returns undef if AUTOLOAD is not in the inheritance hierarchy.
	
	shift;#Don't care about our package name.
	
	my $object_or_package = shift;
	my $orig_class = ref($object_or_package) || $object_or_package;
	
	return undef unless UNIVERSAL::can($orig_class, 'AUTOLOAD');
	
	my @classes = (Class::ISA::self_and_super_path($orig_class), 'UNIVERSAL');
	
	my $package;
	foreach my $class (@classes)
	{
		no strict 'refs';#Symbol table munging ahead
		$package = $class;
		last if defined(*{$package.'::AUTOLOAD';}{CODE});
	}
	
	return $package;
}

sub _prepareAUTOLOADRef
{
	#Takes 2 arguments:
	#	either an object or the name of a package
	#	the fully qualified method name to make AUTOLOAD think it was called as a result of
	#Sets the appropriate package's $AUTOLOAD so that when the AUTOLOAD method is called on the first argument, it will think it was called as a result of a call to the method specified by the second argument.
	#Returns the result of (UNIVERSAL::can($first_arg, 'AUTOLOAD'));
	
	my $class = shift;

	my ($object, $method) = @_;
	
	if (UNIVERSAL::can($object, 'AUTOLOAD'))#no point in doing any of this if it can't AUTOLOAD.
	{
		my $package = $class->_findAUTOLOADPackage($object);
		
		{
			no strict 'refs';
			*{$package.'::AUTOLOAD'} = \$method;
		}
	}
	
	return UNIVERSAL::can($object, 'AUTOLOAD');
}

#defaults, these are overridable when someone calls ->inherit
Class::Data::TIN->new(__PACKAGE__,
	inflate => sub {return $_[0]->new_inflate($_[1]);},
	debug   => 0,
	);

sub inherit
{
	#calls to Class::LazyObject->inherit are forwarded here.
	
	my $class = shift; #don't care about our own package name.
	my %params = @_;
	
	my @required_params = qw(inflated_class deflated_class);
	
	foreach my $param (@required_params)
	{
		croak "You did not pass '$param', which is a required parameter." unless exists $params{$param};
	}
	
	my %param_map = ( #keys are key names in the parameters passed to this function. Values are corrisponding class data names.
		inflated_class => 'class'
		);
		
	my %class_data = %params;
	delete @class_data{keys %param_map, 'deflated_class'};#we'll stick these in with their appropriate names:
	@class_data{values %param_map} = @params{keys %param_map};#pass the parameters whose names have changed
	
	
	my $method_package = $params{deflated_class}.'::Methods';
	
	{
		no strict 'refs'; #more symbol table munging
		push(@{$method_package.'::ISA'}, __PACKAGE__); #Create a package to hold all the methods, that inherits from THIS class, or add this class to its inheritance if it does exist.  #Should this be $class instead of __PACKAGE__
		#^Push is used instead of unshift so that someone can override their ::Methods package with its own inheritence hierarchy, and methods will be called here only AFTER Perl finds they don't exist in the overridden ISA.
	}
	
	Class::Data::TIN->new($method_package, %class_data);
}

sub new
{
	my ($own_package, $class, $id) = @_;#first argument is this method's, class, not the lazy object's
	
	if (ref($id) && UNIVERSAL::isa($id, $own_package->get_classdata('class')))
	{
		croak "A Lazy Object's ID cannot be a an object of same class (or of a class inherited from the one) it is proxying!";
	}

	return bless \$id, $class;
}		

1;

#LAUNDRY LIST:
 #LAZYNESS, impatience, hubris
 #should we document the $AUTOLOAD persistence thingy as a caveat?
 #CALLING AUTOLOAD on inflate
 #CAVEAT: can't distinguish between no id and an id of undef.
 #  -solve by storing a Class::LazyObject::NoID object instead of undef?
 #Does goto propogate scalar/list context?
 #Lvalue subs?
 #PROBLEM: Can't inherit from a lazy object (that has already called inherit) it right now without calling inherit because the corrisponding ::Methods class hasn't been created yet. Instead of being completely nonpolluting, can we create a method with a long convoluted name like __________Class_____LazyObject______Find____Methods and use the NEXT module to make redispatch any calls of it that are object method calls instead of static class calls? 
 #Does ORL's can work correctly for classes that inherit from an unrealized class?


__END__

=head1 NAME

Class::LazyObject - Deferred object construction

=head1 SYNOPSIS

    use Class::LazyObject;
    
    package Bob::Class::LazyObject;
    our @ISA = 'Class::LazyObject';
    
    Class::LazyObject->inherit(
    	deflated_class => __PACKAGE__,
    	inflated_class => 'Bob'
    	inflate => sub {
    	               my ($class, $id) = @_;
    	               return $class->new($id);
    	           }
    	);  
    
    package main;
    
    my @bobs;
    foreach (0..10_000)#make 10 thousand lazy Bobs
    {
    	push @bobs, Bob::Class::LazyObject->new($_);
    }
    
    # @bobs now contains lazy objects, not real Bobs.
    # No Bob objects have been constructed yet.
    
    my $single = $bobs[rand @bobs]; #rand returned 10
    
    $single->string;#returns 10.
    #Single is now an actual Bob object. Only one
    #Bob object has been constructed.
    
    
    package Bob;
    #It's really expensive to create Bob objects.
    
    sub string
    {
        #return the scalar passed to ->new()
    }
    
    #other Bob methods here

=head1 DESCRIPTION

Class::LazyObject allows you to create lazy objects. A lazy object holds the
place of another object, (Called the "inflated object"). The lazy object turns
into the inflated object ("inflates") only after a method is called on the lazy
object. After that, any variables holding the lazy object will hold the inflated
object.

In other words, you can treat a lazy object just like the object it's holding
the place of, and it won't turn into a real object until necessary. This also
means that the real object won't be constructed until necessary.

A lazy object takes up less memory than most other objects (it's even smaller
than a blessed empty hash). Constructing a lazy object is also likely to be
computationally cheaper than constructing an inflated object (especially if a
database is involved).

A lazy object can hold a scalar (called the "ID") that is passed to the
constructor for the inflated object.


=head1 WHY

When would you want to use lazy objects? Any time you have a large number of
objects, but you will only need to use some of them and throw the rest of them
away.

=head2 Example

For example, say you have a class C<Word>.  A Word has a name, a part of speech,
and a definition. Word's constructor is passed a name, and then it fetches the
other information about the word from a database (which is a dictionary and so
has thousands of words). C<$word_object-E<gt>others_with_this_pos()> returns an
array of all Words in the database with the same part of speech as $word_object.

If you only want to pick 4 words at random that have the same part of speech as
$word_object, hundreds of unnecessary Word objects might be created by
C<others_with_this_pos()>. Each of them would require information to be
retrieved from the database, and stored in memory, only to be destroyed when the
array goes out of scope.

It would be much more efficient if C<others_with_this_pos()> returned an array
of lazy objects, whose IDs were word names. Lazy objects take up less memory
than Word objects and do not require a trip to the database when they are
constructed. The 4 lazy objects that are actually used would turn into Word
objects automatically when necessary.

=head2 But wait!

"But wait," you say, "that example doesn't make any sense!
C<others_with_this_pos()> should just return an array of word names. Just pass
these word names to C<Word>'s constructor!"

Well, I don't know about you, but I use object orientation because I want to be
able to ignore implementation details. So if I ask for words, I want Word
objects, not something else representing Word objects. I want to be able to call
methods on those Word objects.

C<Class::LazyObject> lets you have objects that are almost as small as scalars
holding the word names. These objects can be treated exactly like Word objects.
Once you call a method on any one of them, it suddenly B<is> a word object.
Better yet, you don't have to know about any of this to use the lazy Word
objects. As far as you know, they B<are> word objects.


=head1 SETUP

You need to create a lazy object class for each regular class you want to
inflate to.

=over 4

=item 1. Create a class to hold lazy objects that inflate to a particular class.

    package Bob::Class::LazyObject;

Note that a package whose name is your package name with ::Methods appended
(C<Bob::Class::LazyObject::Methods> for this example) is also automatically
created by Class::LazyObject, so don't use a package with that name for
anything.


=item 2. Make the class inherit from Class::LazyObject.

    package Bob::Class::LazyObject;
    our @ISA = 'Class::LazyObject';


=item 3. Do some configuration

Call C<Class::LazyObject-E<gt>inherit()>.

It takes a series of named parameters (a hash). The only two required parameters
are C<deflated_class> and C<inflated_class>. See L<"inherit"> for more
information.

    package Bob::Class::LazyObject;
    our @ISA = 'Class::LazyObject';
	
    Class::LazyObject->inherit(
    	deflated_class => __PACKAGE__,
    	inflated_class => 'Bob'
    	);

When you call C<Class::LazyObject-E<gt>inherit()>, Class::LazyObject sets some
class data in your lazy object class.

=item 4. Create an inflation constructor in the inflated class

In the class that the lazy object will inflate to, define a class method
C<new_inflate>.  This is called with a single parameter, the ID passed to
C<Class::LazyObject-E<gt>new> when this particular lazy object was created. (If
no ID was passed, C<undef> is passed to C<new_inflate>.) This method should be a
constructor for your class. It must return an object of the inflated class, or
of a class that inherits from the inflated class. (Unless the object isa the
inflated class, bad things will happen.)

If you wish to have the inflation constructor be named something other than
C<new_inflate>, or want it to be called in different way, see 
L<"THE INFLATE SUB">.

The reason C<new_inflate> is called by default rather than just C<new> is so
that you can write C<new> to return lazy objects, unbeknownst to its caller.

=back

That's all it takes to set up a lazy object class.

=head1 CLASS METHODS

Now that you've set up a lazy object class (if you haven't, see L<"SETUP">), how
do you actually make use of it?

The methods here are all class methods, and they must all be called on a class
inherited from C<Class::LazyObject>. If you want to know about object methods
instead, look at L<"OBJECT METHODS">.

=head2 C<new>

    new(ID)
    new()

C<Class::LazyObject-E<gt>new> takes one optional scalar parameter, the object's
ID. This ID is passed to the inflation constructor when the lazy object
inflates.

Note that the ID I<cannot> be an object of the same class that the lazy object
inflates to (or any class that inherits from the class).

=head2 C<inherit>

    inherit(deflated_class => __PACKAGE__, inflated_class => CLASS)
    
    inherit(deflated_class => __PACKAGE__, inflated_class => CLASS,
    	inflate => CODE); #Optional

C<Class::LazyObject-E<gt>inherit> should only be called by any class that
inherits from Class::LazyObject. It takes a hash of named arguments. Only the
C<deflated_class> and C<inflated_class> arguments are required. The arguments
are:

=over 4

=item deflated_class

B<Required>. The package the lazy object should be in before inflating, in other
words, the class that's calling C<inherit>. You should almost always just set
this to C<__PACKAGE__>.

=item inflated_class

B<Required>. The package the lazy object should inflate into.

=item inflate

B<Optional>. Takes a reference to a subroutine. This subroutine will be called
when the lazy object inflates. See L<"THE INFLATE SUB"> for more information.
This allows you to override the default inflation behavior. By default, when a
lazy object inflates, C<Inflated::Class-E<gt>new_inflate> is called and passed
the lazy object's ID as an argument.

=back

=head1 OBJECT METHODS

None, except an AUTOLOAD that catches calls to any other methods.

Calling any method on a lazy object will inflate it and call that method on the
inflated object.

=head1 THE INFLATE SUB

You should pass a reference to a sub as the value of the C<inflate> parameter of
L<the C<inherit> class method|"inherit">. This sub is called when the lazy
object needs to be inflated.

The inflate sub is passed two parameters: the name of the class to inflate into,
and the ID passed to the lazy object's constructor.

The inflate sub should return a newly constructed object.

If you supply an inflate parameter to inherit, you override the default inflate
sub, which is:

    sub {my ($class, $id) = @_; return $class->new_inflate($id);}

But you could define your inflate sub to do whatever you want. 


=head1 Class::LazyObject VS. Object::Realize::Later

Chances are, if you have a problem that needs to be solved, there's a CPAN
module that already solves it.  Class::LazyObject was conceived and implemented
before I knew about L<Object::Realize::Later|Object::Realize::Later>. While the
two modules solve the same type of problem, they do so in very different ways.

Have a look at the L<Object::Realize::Later|Object::Realize::Later> documentation.
Whichever module seems to make more sense to you is the one you should use.

=head2 Philosophy

Both modules help you to implement objects that act as stubs- that is, they do
not provide the full functionality of a particular object, but automatically
turn themselves into that kind of object when that functionality is needed.
There are two approaches to creating such objects.

The first approach is to have an object that can exist in two states: deflated
and inflated. Each of the object's methods must check which state the object is
in, and, if necessary, call a method that inflates the object.

L<Object::Realize::Later|Object::Realize::Later> automates this process. You
define a class for the deflated object that contains only the methods that can
work on the deflated object. L<Object::Realize::Later|Object::Realize::Later>
provides this class with an C<AUTOLOAD> that catches calls to all the methods
that can only handle an inflated object, and calls a user-defined method to
inflate that object. For more detail on this, see
L<Object::Realize::Later/"About lazy loading">.

In the second approach, the deflated object and inflated object are really
separate. The deflated object is a blessed scalar that contains the information
necessary to construct the inflated object. The inflated object isn't even
constructed at all until it is needed. When a method is called on the
deflated object, it passes the scalar to an inflation subroutine that uses the
data in it to call the constructor on the inflated object. In other words, the
deflated object is really just a scalar that knows what object to transform
itself into when methods are called on it.

Class::LazyObject automates creating
a class for deflated objects that inflate to a particular other class. The main
focus of Class::LazyObject is that deflated objects should have as small a
memory footprint as possible, and that you should be able to easily graft lazy
objects onto an existing program with little modification (a constructor can
return a deflated object rather than an inflated object, and everything will
still work as expected). (Note that L<Object::Realize::Later|Object::Realize::Later>
also allows you to have separate deflated and inflated objects, but leaves more of the work to you.)

Because these approaches are so different, they lend themselves to two unique
ways of solving a problem that requires lazy objects. Rather than being
duplications of effort, they carry on the Perl tradition of offering More Than
One Way To Do It.

=head2 Invisibility

Each module differs in how it exposes the fact that an object is a lazy object.

Class::LazyObject treats lazy object-ness as an implementation detail, and attempts
to make it impossible to tell whether an object is a lazy object or not. A deflated object
has the same interface as an inflated object, and acts exactly the same. The only way to actually
tell that an object is deflated is to do C<ref($object)>; but what class an object belongs to is
also considered an implementation detail (as opposed to what the class inherits from or what the object's interface is).
The thinking is that your code should never need to worry about whether an object is inflated or deflated, and should
simply let Class::LazyObject take care of all of the lazy loading details.

Additionally, great pains have been taken in Class::LazyObject to keep the lazy object
namespace free of object methods. You can call B<any> method on a deflated
object and it will be correctly passed on to the inflated class.

L<Object::Realize::Later|Object::Realize::Later> takes a slightly different approach. Lazy loading is considered
a feature of an object, and appropriate details are exposed to allow code to take advantage of this. Code designed
to take an inflated object will work just fine with a deflated one (deflated objects are given
C<can> and C<isa> methods that return the same things as if they had been called on inflated objects). However, 
the methods C<forceRealize> and C<willRealize> are also added to the deflated object class. They allow code
to force an object to inflate, and to check what class an object will inflate to. These are considered features of all lazy objects,
the same way C<can> and C<isa> are features of all objects.

=head2 Importing vs. Inheritance

Another difference is how methods are added to your deflated object class.
L<Object::Realize::Later|Object::Realize::Later> adds several methods directly to your class's namespace. (See L<Object::Realize::Later/Added to YOUR class>.) This
means that you cannot easily extend their functionality or override them, though there is admittedly probably very little need to do so in most cases (except possibly C<AUTOLOAD>).

Deflated object classes that use Class::LazyObject are subclasses of
Class::LazyObject and I<inherit> their functionality, meaning that they can be
easily extended through the usual object-oriented means.
As a downside to this method, however, calls to methods on deflated objects are probably a little
slower.

=head2 Inflation when calling can and isa

With both modules, C<$deflated_object-E<gt>can> and C<$deflated_object-E<gt>isa>
return the same thing either of these calls on an inflated object would return.
Class::LazyObject does this by treating those like any other methods and
inflating the object. L<Object::Realize::Later|Object::Realize::Later>
accomplishes this without inflating the object.

I plan to add functionality to Class::LazyObject at some point to let the user
decide whether or not C<can> and C<isa> should inflate a deflated object or not.
Until then, however, L<Object::Realize::Later|Object::Realize::Later> is much
better in this regard.

=head2 Maturity

L<Object::Realize::Later|Object::Realize::Later> has existed for about two years
longer than Class::LazyObject and has gone through more than a dozen revisions. It has also
been used in the excellent L<Mail::Box|Mail::Box> suite as well as in other
programs.

Class::LazyObject is a new module, still being developed. It will mature over
time. However, if you want a stable, proven module right now, go with
L<Object::Realize::Later|Object::Realize::Later>.

=head1 IMPLEMENTATION

A lazy object is a blessed scalar containing the ID to be passed to the
inflation constructor. AUTOLOAD is used to intercept calls to methods. When a
method is called on a lazy object, it calls the inflation constructor on the
neccesary class, and sets $_[0] to the newly created object, replacing the lazy
object with the full object. The full object is also stored in the blessed
scalar, so that if any other variables hold references to the lazy object, they
can be given the already created full object when they call a method on the lazy
object.

Additional chicanery takes place so that calls to methods inherited from
C<UNIVERSAL> are intercepted, and so that C<AUTOLOAD>ed methods of the inflated
object are called correctly.

=head1 CAVEATS

=head2 The ID cannot be an object of the same class as the inflated class or any class that inherits from the inflated class.

=head2 The C<DESTROY> method does not cause inflation.

There's no way (either that, or it's very difficult) to tell whether the
C<DESTROY> method has been explicitly invoked on a lazy object, or whether Perl
is just trying to destroy the object. It is, however, unlikely that you would
need to explicitly call C<DESTROY> on any of your objects anyway. I may later
add capability to change this behavior.

=head2 C<use Class::LazyObject> B<after> C<use>ing any module that puts subs in C<UNIVERSAL>.

C<Class::LazyObject> has to do extra work to handle calls on lazy objects to
methods defined in C<UNIVERSAL>. It does this work when you C<use
Class::LazyObject>. Therefore, if you add any subs to C<UNIVERSAL> (with
C<UNIVERSAL::exports>, C<UNIVERSAL::moniker>, or C<UNIVERSAL::require>, for
example), only C<use Class::LazyObject> B<afterwards>.

=head2 Explicitly calling C<AUTOLOAD> on a lazy object may not do what you expect.

If you never explicitly call C<$a_lazy_object-E<gt>AUTOLOAD>, this caveat does
not apply to you. (Calling C<AUTOLOAD>ed methods, on the other hand, is fine.)

If you set $AUTOLOAD in a package with a hardcoded value (because you think you
know in which package the AUTOLOAD sub is defined for a particular class) and
then call C<$a_lazy_object-E<gt>AUTOLOAD>, the object will inflate, but a
different method will be called on the inflated object than you intended. If
you're trying to spoof calls to AUTOLOAD, you should really be searching through
the inheritance hierarchy of the object (with the help of something like
Class::ISA) until you find the package that the object's AUTOLOAD method is
defined in, and then set that package's $AUTOLOAD. (In fact, Class::LazyObject
does this kind of AUTOLOAD search itself.)

I will most likely revise this caveat to make more sense.

=head1 BUGS

(The difference between bugs and L<caveats|"CAVEATS"> is that I plan to fix the
bugs.)

=head2 Inheriting from lazy objects

Currently, you cannot easily inherit from a class that inherits from
C<Class::LazyObject>. This will be fixed very soon.

=head2 Objects with C<overload>ed operators

Currently, lazy objects will not intercept overloaded operators. This means that
if your inflated object uses overloaded operators, you cannot use a lazy object
in its place. This may be fixed in future versions by using a combination of
C<nomethod> and C<overload::Method>. See L<overload> to learn more about
overloaded operators.

=head2 C<UNIVERSAL::isa> and C<UNIVERSAL::can>

Currently, C<UNIVERSAL::isa($a_lazy_object,
'Class::The::Lazy::Object::Inflates::To')> is false, though
C<$a_lazy_object-E<gt>isa> will do the right thing. Similarly,
C<UNIVERSAL::can($a_lazy_object, 'method')> won't work like it's supposed to,
but C<$a_lazy_object-E<gt>can> I<will> work correctly. This may be fixed in a
future release.

=head2 Objects implementing C<tie>d datatypes

C<Class::LazyObject> has not yet been tested with objects that implement C<tie>d
datatypes. It may very well work, and then again, it may not. Explicit support
may be added in a future release. See L<perltie> to learn more about C<tie>s.

=head1 AUTHOR

Daniel C. Axelrod, daxelrod@cpan.org

=head1 SEE ALSO

=head2 L<Object::Realize::Later>

Another module for creating lazy objects. See L<"Class::LazyObject VS. Object::Realize::Later">
for a comparison between the two modules.

=head2 http://perlmonks.org/index.pl?node_id=279940

Fergal Daly had the idea for lazy objects before I did. Note that I had the idea
independently, but subsequently discovered his posting.


=head1 COPYRIGHT

Copyright (c) 2003-2004, Daniel C. Axelrod. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
