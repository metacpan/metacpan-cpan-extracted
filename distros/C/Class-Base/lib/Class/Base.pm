#============================================================= -*-perl-*-
#
# Class::Base
#
# DESCRIPTION
#   Module implementing a common base class from which other modules
#   can be derived.
#
# AUTHOR
#   Andy Wardley    <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2002 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#
#========================================================================

package Class::Base;

use strict;

our $VERSION  = '0.08';


#------------------------------------------------------------------------
# new(@config)
# new(\%config)
#
# General purpose constructor method which expects a hash reference of 
# configuration parameters, or a list of name => value pairs which are 
# folded into a hash.  Blesses a hash into an object and calls its 
# init() method, passing the parameter hash reference.  Returns a new
# object derived from Class::Base, or undef on error.
#------------------------------------------------------------------------

sub new {
    my $class  = shift;

    # allow hash ref as first argument, otherwise fold args into hash
    my $config = defined $_[0] && UNIVERSAL::isa($_[0], 'HASH') 
	? shift : { @_ };

    no strict 'refs';
    my $debug = defined $config->{ debug } 
                      ? $config->{ debug }
              : defined $config->{ DEBUG }
                      ? $config->{ DEBUG }
                      : ( do { local $^W; ${"$class\::DEBUG"} } || 0 );

    my $self = bless {
	_ID    => $config->{ id    } || $config->{ ID    } || $class,
	_DEBUG => $debug,
	_ERROR => '',
    }, $class;

    return $self->init($config)
	|| $class->error($self->error());
}


#------------------------------------------------------------------------
# init()
#
# Initialisation method called by the new() constructor and passing a 
# reference to a hash array containing any configuration items specified
# as constructor arguments.  Should return $self on success or undef on 
# error, via a call to the error() method to set the error message.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    return $self;
}


#------------------------------------------------------------------------
# clone()
#
# Method to perform a simple clone of the current object hash and return
# a new object.
#------------------------------------------------------------------------

sub clone {
    my $self = shift;
    bless { %$self }, ref($self);
}


#------------------------------------------------------------------------
# error()
# error($msg, ...)
# 
# May be called as a class or object method to set or retrieve the 
# package variable $ERROR (class method) or internal member 
# $self->{ _ERROR } (object method).  The presence of parameters indicates
# that the error value should be set.  Undef is then returned.  In the
# abscence of parameters, the current error value is returned.
#------------------------------------------------------------------------

sub error {
    my $self = shift;
    my $errvar;

    { 
	# get a reference to the object or package variable we're munging
	no strict qw( refs );
	$errvar = ref $self ? \$self->{ _ERROR } : \${"$self\::ERROR"};
    }
    if (@_) {
	# don't join if first arg is an object (may force stringification)
	$$errvar = ref($_[0]) ? shift : join('', @_);
	return undef;
    }
    else {
	return $$errvar;
    }
}



#------------------------------------------------------------------------
# id($new_id)
#
# Method to get/set the internal _ID field which is used to identify
# the object for the purposes of debugging, etc.
#------------------------------------------------------------------------

sub id {
    my $self = shift;

    # set _ID with $obj->id('foo')
    return  ($self->{ _ID } = shift) if ref $self && @_;

    # otherwise return id as $self->{ _ID } or class name 
    my $id = $self->{ _ID } if ref $self;
    $id ||= ref($self) || $self;

    return $id;
}


#------------------------------------------------------------------------
# params($vals, @keys)
# params($vals, \@keys)
# params($vals, \%keys)
#
# Utility method to examine the $config hash for any keys specified in
# @keys and copy the values into $self.  Keys should be specified as a 
# list or reference to a list of UPPER CASE names.  The method looks 
# for either the name in either UPPER or lower case in the $config 
# hash and copies the value, if defined, into $self.  The keys can 
# also be specified as a reference to a hash containing default values
# or references to handler subroutines which will be called, passing 
# ($self, $config, $UPPER_KEY_NAME) as arguments.
#------------------------------------------------------------------------

sub params {
    my $self = shift;
    my $vals = shift;
    my ($keys, @names);
    my ($key, $lckey, $default, $value, @values);


    if (@_) {
	if (ref $_[0] eq 'ARRAY') {
	    $keys  = shift;
	    @names = @$keys;
	    $keys  = { map { ($_, undef) } @names };
	}
	elsif (ref $_[0] eq 'HASH') {
	    $keys  = shift;
	    @names = keys %$keys;
	}
	else {
	    @names = @_;
	    $keys  = { map { ($_, undef) } @names };
	}
    }
    else {
	$keys = { };
    }

    foreach $key (@names) {
	$lckey = lc $key;

	# look for value provided in $vals hash
	defined($value = $vals->{ $key })
	    || ($value = $vals->{ $lckey });

	# look for default which may be a code handler
	if (defined ($default = $keys->{ $key })
	    && ref $default eq 'CODE') {
	    eval {
		$value = &$default($self, $key, $value);
	    };
	    return $self->error($@) if $@;
	}
	else {
	    $value = $default unless defined $value;
	    $self->{ $key } = $value if defined $value;
	}
	push(@values, $value);
	delete @$vals{ $key, lc $key };
    }
    return wantarray ? @values : \@values;
}


#------------------------------------------------------------------------
# debug(@args)
#
# Debug method which prints all arguments passed to STDERR if and only if
# the appropriate DEBUG flag(s) are set.  If called as an object method
# where the object has a _DEBUG member defined then the value of that 
# flag is used.  Otherwise, the $DEBUG package variable in the caller's
# class is used as the flag to enable/disable debugging. 
#------------------------------------------------------------------------

sub debug {
    my $self  = shift;
    my ($flag);

    if (ref $self && defined $self->{ _DEBUG }) {
	$flag = $self->{ _DEBUG };
    }
    else {
	# go looking for package variable
	no strict 'refs';
	$self = ref $self || $self;
	$flag = ${"$self\::DEBUG"};
    }

    return unless $flag;

    print STDERR '[', $self->id, '] ', @_;
}


#------------------------------------------------------------------------
# debugging($flag)
#
# Method to turn debugging on/off (when called with an argument) or to 
# retrieve the current debugging status (when called without).  Changes
# to the debugging status are propagated to the $DEBUG variable in the 
# caller's package.
#------------------------------------------------------------------------

sub debugging {
    my $self  = shift;
    my $class = ref $self;
    my $flag;

    no strict 'refs';

    my $dbgvar = ref $self ? \$self->{ _DEBUG } : \${"$self\::DEBUG"};

    return @_ ? ($$dbgvar = shift)
	      :  $$dbgvar;

}


1;


=head1 NAME

Class::Base - useful base class for deriving other modules 

=head1 SYNOPSIS

    package My::Funky::Module;
    use base qw( Class::Base );

    # custom initialiser method
    sub init {
	my ($self, $config) = @_;

	# copy various params into $self
	$self->params($config, qw( FOO BAR BAZ ))
	    || return undef;

	# to indicate a failure
	return $self->error('bad constructor!') 
	    if $something_bad;

	# or to indicate general happiness and well-being
	return $self;
    }

    package main;

    # new() constructor folds args into hash and calls init()
    my $object = My::Funky::Module->new( foo => 'bar', ... )
	  || die My::Funky::Module->error();

    # error() class/object method to get/set errors
    $object->error('something has gone wrong');
    print $object->error();

    # debugging() method (de-)activates the debug() method
    $object->debugging(1);

    # debug() prints to STDERR if debugging enabled
    $object->debug('The ', $animal, ' sat on the ', $place);


=head1 DESCRIPTION

Please consider using L<Badger::Base> instead which is the successor of
this module.

This module implements a simple base class from which other modules
can be derived, thereby inheriting a number of useful methods such as
C<new()>, C<init()>, C<params()>, C<clone()>, C<error()> and
C<debug()>.

For a number of years, I found myself re-writing this module for
practically every Perl project of any significant size.  Or rather, I
would copy the module from the last project and perform a global
search and replace to change the names.  Each time it got a little
more polished and eventually, I decided to Do The Right Thing and
release it as a module in it's own right.

It doesn't pretend to be an all-encompassing solution for every kind
of object creation problem you might encounter.  In fact, it only
supports blessed hash references that are created using the popular,
but by no means universal convention of calling C<new()> with a list
or reference to a hash array of named parameters.  Constructor failure
is indicated by returning undef and setting the C<$ERROR> package
variable in the module's class to contain a relevant message (which
you can also fetch by calling C<error()> as a class method).

e.g.

    my $object = My::Module->new( 
	file => 'myfile.html',
	msg  => 'Hello World'
    ) || die $My::Module::ERROR;

or:

    my $object = My::Module->new({
	file => 'myfile.html',
	msg  => 'Hello World',
    }) || die My::Module->error();

The C<new()> method handles the conversion of a list of arguments 
into a hash array and calls the C<init()> method to perform any 
initialisation.  In many cases, it is therefore sufficient to define
a module like so:

    package My::Module;
    use Class::Base;
    use base qw( Class::Base );

    sub init {
	my ($self, $config) = @_;
	# copy some config items into $self
	$self->params($config, qw( FOO BAR )) || return undef;
	return $self;
    }

    # ...plus other application-specific methods

    1;

Then you can go right ahead and use it like this:

    use My::Module;

    my $object = My::Module->new( FOO => 'the foo value',
				  BAR => 'the bar value' )
        || die $My::Module::ERROR;

Despite its limitations, Class::Base can be a surprisingly useful
module to have lying around for those times where you just want to
create a regular object based on a blessed hash reference and don't
want to worry too much about duplicating the same old code to bless a
hash, define configuration values, provide an error reporting
mechanism, and so on.  Simply derive your module from C<Class::Base>
and leave it to worry about most of the detail.  And don't forget, you
can always redefine your own C<new()>, C<error()>, or other method, if
you don't like the way the Class::Base version works.

=head2 Subclassing Class::Base

This module is what object-oriented afficionados would describe as an
"abstract base class".  That means that it's not designed to be used
as a stand-alone module, rather as something from which you derive
your own modules.  Like this:

    package My::Funky::Module
    use base qw( Class::Base );

You can then use it like this:

    use My::Funky::Module;

    my $module = My::Funky::Module->new();

=head2 Construction and Initialisation Methods

If you want to apply any per-object initialisation, then simply write
an C<init()> method.  This gets called by the C<new()> method which
passes a reference to a hash reference of configuration options.

    sub init {
	my ($self, $config) = @_;

	...

	return $self;
    }

When you create new objects using the C<new()> method you can either
pass a hash reference or list of named arguments.  The C<new()> method
does the right thing to fold named arguments into a hash reference for
passing to the C<init()> method.  Thus, the following are equivalent:

    # hash reference
    my $module = My::Funky::Module->new({ 
	foo => 'bar', 
	wiz => 'waz',
    });

    # list of named arguments (no enclosing '{' ... '}')
    my $module = My::Funky::Module->new(
	foo => 'bar', 
	wiz => 'waz'
    );

Within the C<init()> method, you can either handle the configuration
yourself:

    sub init {
	my ($self, $config) = @_;

	$self->{ file } = $config->{ file }
	    || return $self->error('no file specified');

	return $self;
    }

or you can call the C<params()> method to do it for you:

    sub init {
	my ($self, $config) = @_;

	$self->params($config, 'file')
	    || return $self->error('no file specified');

	return $self;
    }

=head2 Error Handling

The C<init()> method should return $self to indicate success or undef
to indicate a failure.  You can use the C<error()> method to report an
error within the C<init()> method.  The C<error()> method returns undef,
so you can use it like this:

    sub init {
	my ($self, $config) = @_;

	# let's make 'foobar' a mandatory argument
	$self->{ foobar } = $config->{ foobar }
	    || return $self->error("no foobar argument");

	return $self;
    }

When you create objects of this class via C<new()>, you should now
check the return value.  If undef is returned then the error message
can be retrieved by calling C<error()> as a class method.

    my $module = My::Funky::Module->new()
  	  || die My::Funky::Module->error();

Alternately, you can inspect the C<$ERROR> package variable which will
contain the same error message.

    my $module = My::Funky::Module->new()
  	 || die $My::Funky::Module::ERROR;

Of course, being a conscientious Perl programmer, you will want to be
sure that the C<$ERROR> package variable is correctly defined.

    package My::Funky::Module
    use base qw( Class::Base );

    our $ERROR;

You can also call C<error()> as an object method.  If you pass an
argument then it will be used to set the internal error message for
the object and return undef.  Typically this is used within the module
methods to report errors.

    sub another_method {
	my $self = shift;

	...

	# set the object error
	return $self->error('something bad happened');
    }

If you don't pass an argument then the C<error()> method returns the
current error value.  Typically this is called from outside the object
to determine its status.  For example:

    my $object = My::Funky::Module->new()
        || die My::Funky::Module->error();

    $object->another_method()
	|| die $object->error();

=head2 Debugging Methods

The module implements two methods to assist in writing debugging code:
debug() and debugging().  Debugging can be enabled on a per-object or
per-class basis, or as a combination of the two.

When creating an object, you can set the C<DEBUG> flag (or lower case
C<debug> if you prefer) to enable or disable debugging for that one
object.

    my $object = My::Funky::Module->new( debug => 1 )
          || die My::Funky::Module->error();

    my $object = My::Funky::Module->new( DEBUG => 1 )
          || die My::Funky::Module->error();

If you don't explicitly specify a debugging flag then it assumes the 
value of the C<$DEBUG> package variable in your derived class or 0 if 
that isn't defined.

You can also switch debugging on or off via the C<debugging()> method.

    $object->debugging(0);	# debug off
    $object->debugging(1);	# debug on

The C<debug()> method examines the internal debugging flag (the
C<_DEBUG> member within the C<$self> hash) and if it finds it set to
any true value then it prints to STDERR all the arguments passed to
it.  The output is prefixed by a tag containing the class name of the
object in square brackets (but see the C<id()> method below for
details on how to change that value).

For example, calling the method as:

    $object->debug('foo', 'bar');   

prints the following output to STDERR:

    [My::Funky::Module] foobar

When called as class methods, C<debug()> and C<debugging()> instead
use the C<$DEBUG> package variable in the derived class as a flag to
control debugging.  This variable also defines the default C<DEBUG>
flag for any objects subsequently created via the new() method.

    package My::Funky::Module
    use base qw( Class::Base );

    our $ERROR;
    our $DEBUG = 0 unless defined $DEBUG;

    # some time later, in a module far, far away
    package main;

    # debugging off (by default)
    my $object1 = My::Funky::Module->new();

    # turn debugging on for My::Funky::Module objects
    $My::Funky::Module::DEBUG = 1;

    # alternate syntax
    My::Funky::Module->debugging(1);

    # debugging on (implicitly from $DEBUG package var)
    my $object2 = My::Funky::Module->new();

    # debugging off (explicit override)
    my $object3 = My::Funky::Module->new(debug => 0);

If you call C<debugging()> without any arguments then it returns the
value of the internal object flag or the package variable accordingly.

    print "debugging is turned ", $object->debugging() ? 'on' : 'off';

=head1 METHODS

=head2 new()

Class constructor method which expects a reference to a hash array of parameters 
or a list of C<name =E<gt> value> pairs which are automagically folded into 
a hash reference.  The method blesses a hash reference and then calls the 
C<init()> method, passing the reference to the hash array of configuration 
parameters.  

Returns a reference to an object on success or undef on error.  In the latter
case, the C<error()> method can be called as a class method, or the C<$ERROR>
package variable (in the derived class' package) can be inspected to return an
appropriate error message.

    my $object = My::Class->new( foo => 'bar' )	  # params list
	 || die $My::Class::$ERROR;               # package var

or

    my $object = My::Class->new({ foo => 'bar' }) # params hashref
	  || die My::Class->error;                # class method


=head2 init(\%config)

Object initialiser method which is called by the C<new()> method, passing
a reference to a hash array of configuration parameters.  The method may
be derived in a subclass to perform any initialisation required.  It should
return C<$self> on success, or C<undef> on error, via a call to the C<error()>
method.

    package My::Module;
    use base qw( Class::Base );

    sub init {
	my ($self, $config) = @_;

	# let's make 'foobar' a mandatory argument
	$self->{ foobar } = $config->{ foobar }
	    || return $self->error("no foobar argument");

	return $self;
    }

=head2 params($config, @keys)

The C<params()> method accept a reference to a hash array as the 
first argument containing configuration values such as those passed
to the C<init()> method.  The second argument can be a reference to 
a list of parameter names or a reference to a hash array mapping 
parameter names to default values.  If the second argument is not
a reference then all the remaining arguments are taken as parameter
names.  Thus the method can be called as follows:

    sub init {
        my ($self, $config) = @_;

	# either...
	$self->params($config, qw( foo bar ));

	# or...
	$self->params($config, [ qw( foo bar ) ]);

	# or...
	$self->params($config, { foo => 'default foo value',
				 bar => 'default bar value' } );

	return $self;
    }

The method looks for values in $config corresponding to the keys
specified and copies them, if defined, into $self.

Keys can be specified in UPPER CASE and the method will look for 
either upper or lower case equivalents in the C<$config> hash.  Thus
you can call C<params()> from C<init()> like so:

    sub init {
        my ($self, $config) = @_;
        $self->params($config, qw( FOO BAR ))
        return $self;
    }

but use either case for parameters passed to C<new()>:

    my $object = My::Module->new( FOO => 'the foo value',
				  BAR => 'the bar value' )
	|| die My::Module->error();

    my $object = My::Module->new( foo => 'the foo value',
				  bar => 'the bar value' )
	|| die My::Module->error();

Note however that the internal key within C<$self> used to store the
value will be in the case provided in the call to C<params()> (upper
case in this example).  The method doesn't look for upper case
equivalents when they are specified in lower case.

When called in list context, the method returns a list of all the
values corresponding to the list of keys, some of which may be
undefined (allowing you to determine which values were successfully
set if you need to).  When called in scalar context it returns a 
reference to the same list.

=head2 clone()

The C<clone()> method performs a simple shallow copy of the object
hash and creates a new object blessed into the same class.  You may
want to provide your own C<clone()> method to perform a more complex
cloning operation.

    my $clone = $object->clone();

=head2 error($msg, ...)

General purpose method for getting and setting error messages.  When 
called as a class method, it returns the value of the C<$ERROR> package
variable (in the derived class' package) if called without any arguments,
or sets the same variable when called with one or more arguments.  Multiple
arguments are concatenated together.

    # set error
    My::Module->error('set the error string');
    My::Module->error('set ', 'the ', 'error string');

    # get error
    print My::Module->error();
    print $My::Module::ERROR;

When called as an object method, it operates on the C<_ERROR> member
of the object, returning it when called without any arguments, or
setting it when called with arguments.

    # set error
    $object->error('set the error string');

    # get error
    print $object->error();

The method returns C<undef> when called with arguments.  This allows it
to be used within object methods as shown:

    sub my_method {
	my $self = shift;

	# set error and return undef in one
	return $self->error('bad, bad, error')
	    if $something_bad;
    }

=head2 debug($msg, $msg, ...)

Prints all arguments to STDERR if the internal C<_DEBUG> flag (when
called as an object method) or C<$DEBUG> package variable (when called
as a class method) is set to a true value.  Otherwise does nothing.
The output is prefixed by a string of the form "[Class::Name]" where
the name of the class is that returned by the C<id()> method.

=head2 debugging($flag)

Used to get (no arguments) or set ($flag defined) the value of the
internal C<_DEBUG> flag (when called as an object method) or C<$DEBUG>
package variable (when called as a class method).

=head2 id($newid)

The C<debug()> method calls this method to return an identifier for
the object for printing in the debugging message.  By default it
returns the class name of the object (i.e. C<ref $self>), but you can
of course subclass the method to return some other value.  When called
with an argument it uses that value to set its internal C<_ID> field
which will be returned by subsequent calls to C<id()>.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version 0.04 of Class::Base.

=head1 HISTORY

This module began life as the Template::Base module distributed as 
part of the Template Toolkit. 

Thanks to Brian Moseley and Matt Sergeant for suggesting various
enhancments, some of which went into version 0.02.

Version 0.04 was uploaded by Gabor Szabo.

=head1 COPYRIGHT

Copyright (C) 1996-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
