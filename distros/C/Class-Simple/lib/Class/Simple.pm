#$Id: Simple.pm,v 1.29 2008/01/01 16:34:15 sullivan Exp $
#
#	See the POD documentation starting towards the __END__ of this file.

package Class::Simple;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.1';

use Scalar::Util qw(refaddr);
use Carp;
## no critic
use Class::ISA;
## use critic
use List::Util qw( first );

my %STORAGE;
my %PRIVATE;
my %READONLY;
my @internal_attributes = qw(CLASS);

our $AUTOLOAD;

sub AUTOLOAD
{
my $self = shift;
my @args = @_;

	no strict 'refs';

	$AUTOLOAD =~ /(.*)::((get|set|clear|raise|readonly)_)?(\w+)/;
	my $pkg = $1;
	my $full_method = $AUTOLOAD;
	my $prefix = $3 || '';
	my $attrib = $4;
	$prefix = '' if ($attrib =~ /^_/);
	my $store_as = $attrib;
	$store_as =~ s/^_// unless $prefix;

	if (my $get_attributes = $self->can('ATTRIBUTES'))
	{
		my @attributes = &$get_attributes();
		push(@attributes, @internal_attributes);
		croak("$attrib is not a defined attribute in $pkg")
		  unless first {$_ eq $attrib} @attributes;
	}

	#
	#	Make sure that if you add more special prefixes here,
	#	you add them to the $AUTOLOAD regex above, too.
	#
	if ($prefix eq 'set')
	{
		*{$AUTOLOAD} = sub
		{
		my $self = shift;

			my $ref = refaddr($self);
			croak("$attrib is readonly:  cannot set.")
			  if ($READONLY{$ref}->{$store_as});
			if (@_ > 1) {
				# Must be initialized (in new or init) as an array ref or hash ref.
				if (ref $STORAGE{$ref}->{$store_as} eq 'ARRAY') {
					@{$STORAGE{$ref}->{$store_as}}[$_[0]] = $_[1];
					return (@{$STORAGE{$ref}->{$store_as}}[$_[0]]);
				} elsif (ref $STORAGE{$ref}->{$store_as} eq 'HASH') {
					$STORAGE{$ref}->{$store_as}->{$_[0]} = $_[1];
					return ($STORAGE{$ref}->{$store_as}->{$_[0]});
				}
			} else {
				return ($STORAGE{$ref}->{$store_as} = shift(@_));
			}
		};
	}
	elsif ($prefix eq 'get')
	{
		*{$AUTOLOAD} = sub
		{
		my $self = shift;

			my $ref = refaddr($self);
			return ($STORAGE{$ref}->{$store_as});
		};
	}
#
#	Bug #7528 in Perl keeps this from working.
#	http://rt.perl.org/rt3/Public/Bug/Display.html?id=7528
#	I could make people declare methods they want to use lv_
#	with but that goes against the philosophy of being ::Simple.
#
#	elsif ($prefix eq 'lv')
#	{
#		*{$AUTOLOAD} = sub : lvalue
#		{
#		my $self = shift;
#
#			my $ref = refaddr($self);
#			croak("$attrib is readonly:  cannot set.")
#			  if ($READONLY{$ref}->{$store_as});
#			return ($STORAGE{$ref}->{$store_as});
#		};
#	}
	elsif ($prefix eq 'clear')
	{
		my $setter = "set_$attrib";
		*{$AUTOLOAD} = sub
		{
		my $self = shift;

			return ($self->$setter(undef));
		};
	}
	elsif ($prefix eq 'raise')
	{
		my $setter = "set_$attrib";
		*{$AUTOLOAD} = sub
		{
		my $self = shift;

			return ($self->$setter(1));
		};
	}
	elsif ($prefix eq 'readonly')
	{
		my $setter = "set_$attrib";
		*{$AUTOLOAD} = sub
		{
		my $self = shift;

			my $ret = $self->$setter(@_);
			my $ref = refaddr($self);
			$READONLY{$ref}->{$store_as} = 1;
			return ($ret);
		};
	}
	#
	#	All methods starting with '_' can only be called from
	#	within their package.  Not inheritable, which makes
	#	the test easier than something privatized..
	#
	#	Note that we cannot just call get_ and set_ here
	#	because if someone writes their own get_foo and then
	#	_foo is called, _foo will call set_foo, which will
	#	probably store something with _foo, which will call
	#	set_foo, etc.  Sure wish we could somehow share
	#	code with get_ and set_, though.
	#
	elsif (!$prefix && ($attrib =~ /^_/))
	{
		if (my $method = $pkg->can($attrib))
		{
			return &$method($self, @args);
		}

		*{$AUTOLOAD} = sub
		{
		my $self = shift;

			croak("Cannot call $attrib:  Private method to $pkg.")
			  unless ($pkg->isa(Class::Simple::_my_caller()));
			my $ref = refaddr($self);
			if (scalar(@_))
			{
				croak("$attrib is readonly:  cannot set.")
				  if ($READONLY{$ref}->{$store_as});
				return ($STORAGE{$ref}->{$store_as} =shift(@_));
			}
			else
			{
				return ($STORAGE{$ref}->{$store_as});
			}
		};
	}
	else
	{
		my $setter = "set_$store_as";
		my $getter = "get_$store_as";
		*{$AUTOLOAD} = sub
		{
		my $self = shift;

			return (scalar(@_)
			  ? $self->$setter(@_)
			  : $self->$getter());
		};
	}
	return (&{$AUTOLOAD}($self, @args));
}



#
#	Call all the DEMOLISH()es and then delete from %STORAGE.
#
sub DESTROY
{
my $self = shift;

	$self->_travel_isa('DESTROY', 'DEMOLISH');
	my $ref = refaddr($self);
	delete($STORAGE{$ref}) if exists($STORAGE{$ref});
	delete($READONLY{$ref}) if exists($READONLY{$ref});
}



#
#	Travel up the class's @ISA and run $func, if we can.
#	To keep from running a sub more than once we flag
#	$storage in %STORAGE.
#
sub _travel_isa
{
my $self = shift;
my $storage = shift;
my $func = shift;

	my $ref = refaddr($self);
	$STORAGE{$ref}->{$storage}= {} unless exists($STORAGE{$ref}->{$storage});
	my @path = reverse(Class::ISA::super_path($self->CLASS));
	foreach my $c (@path)
	{
		next if ($c eq __PACKAGE__);
		next if $STORAGE{$ref}->{$storage}->{$c}++;

		my $cn = "${c}::can";
		if (my $in = $c->can($func))
		{
			$self->$in(@_);
		}
	}
	$self->$func(@_) if $self->can($func);;
}



#
#	Make a scalar.  Bless it.  Call init.
#
sub new
{
my $class = shift;

	#
	#	Support for NONEW.
	#
	{
		no strict 'refs';
		my $classy = "${class}::";
		croak("Cannot call new() in $class.")
		  if exists(${$classy}{'NONEW'});
	}

	#
	#	This is how you get an anonymous scalar.
	#
	my $self = \do{my $anon_scalar};
	bless($self, $class);
	$self->readonly_CLASS($class);

	$self->init(@_);
	return ($self);
}



#
#	Flag the given method(s) as being private to the class
#	(and its children unless overridden).
#
sub privatize
{
my $class = shift;

	foreach my $method (@_)
	{
		no strict 'refs';

		#
		#	Can't privatize something that is already private
		#	from an ancestor.
		#
		foreach my $private_class (keys(%PRIVATE))
		{
			next unless $PRIVATE{$private_class}->{$method};
			croak("Cannot privatize ${class}::$method:  already private in $private_class.")
			  unless $private_class->isa($class);
		}

		#
		#	Can't retroactively make privatize something.
		#
		my $called_by = _my_caller();
		croak("Attempt to privatize ${class}::$method from $called_by.  Can only privatize in your own class.")
		  if ($class ne $called_by);
		$PRIVATE{$class}->{$method} = 1;

		#
		#	Although it is duplication of code (which I hope
		#	to come up with a clever way to avoid at some point),
		#	it is a better solution to have privatize() create
		#	these subs now.  Otherwise, having the private test
		#	done in AUTOLOAD gets to be fairly convoluted.
		#	Defining them here makes the tests a lot simpler.
		#
		my $getter = "${class}::get_$method";
		my $setter = "${class}::set_$method";
		my $generic = "${class}::$method";
		*{$getter} = sub
		{
		my $self = shift;

			no strict 'refs';
			croak("Cannot call $getter:  Private method to $class.")
			  unless $class->isa(Class::Simple::_my_caller());
			my $ref = refaddr($self);
			return ($STORAGE{$ref}->{$method});
		};
		*$setter = sub
		{
		my $self = shift;

			no strict 'refs';
			croak("Cannot call $setter:  Private method to $class.")
			  unless $class->isa(Class::Simple::_my_caller());
			my $ref = refaddr($self);
			croak("$method is readonly:  cannot set.")
			  if ($READONLY{$ref}->{$method});
			return ($STORAGE{$ref}->{$method} = shift(@_));
		};
		*$generic = sub
		{
		my $self = shift;

			no strict 'refs';
			croak("Cannot call $generic:  Private method to $class.")
			  unless $class->isa(Class::Simple::_my_caller());
			my $ref = refaddr($self);
			return (scalar(@_)
			  ? $self->$setter(@_)
			  : $self->$getter());
		};
		my $ugen = "_${generic}";
		*$ugen = *$generic;
	}
}



#
#	Bubble up the caller() stack until we leave this package.
#
sub _my_caller
{
	for (my $i = 0; my $c = caller($i); ++$i)
	{
		return ($c) unless $c eq __PACKAGE__;
	}
	return (__PACKAGE__); # Shouldn't get here but just in case
}



#
#	This will not be called if the child classes have
#	their own.  In case they don't (and they really shouldn't
#	because they should be using BUILD() instead), this is the default.
#
sub init
{
my $self = shift;

        #
        # If we see an even number of arguments, assume they are initializers.
        # Don't like that behavior?  Override init().
        #
        if (scalar(@_) && scalar(@_) % 2 == 0) {
                my %args = @_;
                while ( my ($k, $v) = each(%args) )
                {
                        $self->$k($v);
                }
        }

	$self->_travel_isa('init', 'BUILD', @_);
	return ($self);
}



##
##	toJson() and fromJson() are DUMP and SLURP equivalents for JSON.
##	I'm not sure if they're all that useful yet so they're silently
##	lurking here for now.
##
#sub toJson
#{
#my $self = shift;
#
#	croak("Cannot use toJson(): module JSON::XS not found.\n")
#	  unless (eval 'require JSON::XS; 1');
#
#	my $ref = refaddr($self);
#	my $json = JSON::XS->new();
#	return $json->encode($STORAGE{$ref});
#}
#
#
#
#sub fromJson
#{
#my $self = shift;
#my $str = shift;
#
#	return $self unless $str;
#
#	croak("Cannot use fromJson(): module JSON::XS not found.\n")
#	  unless (eval 'require JSON::XS; 1');
#
#	my $json = JSON::XS->new();
#	my $obj = $json->decode($str);
#	my $ref = refaddr($self);
#	$STORAGE{$ref} = $obj;
#
#	return ($self);
#}



#
#	Callback for Storable to serialize objects.
#
sub STORABLE_freeze
{
my $self = shift;
my $cloning = shift;

	croak("Cannot use STORABLE_freeze(): module Storable not found.\n")
	  unless (eval 'require Storable; 1');

	my $ref = refaddr($self);
	return Storable::freeze($STORAGE{$ref});
}



#
#	Callback for Storable to reconstitute serialized objects.
#
sub STORABLE_thaw
{
my $self = shift;
my $cloning = shift;
my $serialized = shift;

	croak("Cannot use STORABLE_thaw(): module Storable not found.\n")
	  unless (eval 'require Storable; 1');

	my $ref = refaddr($self);
	$STORAGE{$ref} = Storable::thaw($serialized);
}

1;
__END__

=head1 NAME

Class::Simple - Simple Object-Oriented Base Class

=head1 SYNOPSIS

  package Foo:
  use base qw(Class::Simple);

  BEGIN
  {
	Foo->privatize(qw(attrib1 attrib2)); # ...or not.
  }
  my $obj = Foo->new();

  $obj->attrib(1);     # The same as...
  $obj->set_attrib(1); # ...this.

  my $var = $obj->get_attrib(); # The same as...
  $var = $obj->attrib;          # ...this.

  $obj->raise_attrib(); # The same as...
  $obj->set_attrib(1);  # ...this.

  $obj->clear_attrib();    # The same as...
  $obj->set_attrib(undef); # ...this
  $obj->attrib(undef);     # ...and this.

  $obj->readonly_attrib(4);

  sub foo
  {
  my $self = shift;
  my $value = shift;

    $self->_foo($value);
    do_other_things(@_);
    ...
  }

  my $str = Storable::freeze($obj);
  # Save $str to a file
  ...
  # Read contents of file into $new_str
  $new_obj = Storable::thaw($new_str);

  sub BUILD
  {
  my $self = shift;

    # Various initializations
  }

=head1 DESCRIPTION

This is a simple object-oriented base class.  There are plenty of others
that are much more thorough and whatnot but sometimes I want something
simple so I can get just going (no doubt because I am a simple guy)
so I use this.

What do I mean by simple?  First off, I don't want to have to list out
all my methods beforehand.  I just want to use them (Yeah, yeah, it doesn't
catch typos...well, by default--see B<ATTRIBUTES()> below).
Next, I want to be able to
call my methods by $obj->foo(1) or $obj->set_foo(1), by $obj->foo() or
$obj->get_foo().  Don't tell ME I have to use get_ and set_ (I would just
override that restriction in Class::Std anyway).  Simple!

I did want some neat features, though, so these are inside-out objects
(meaning the object isn't simply a hash so you can't just go in and
muck with attributtes outside of methods),
privatization of methods is supported, as is serialization out and back
in again.

It's important to note, though, that one does not have to use the extra
features to use B<Class::Simple>.  All you need to get going is:

	package MyPackage;
	use base qw(Class::Simple);

And that's it.  To use it?:

	use MyPackage;

	my $obj = MyPackage->new();
	$obj->set_attr($value);

Heck, you don't even need that much:

	use Class::Simple;

	my $obj = Class::Simple->new();
	$obj->set_attr($value);

Why would you want to use a (not quite) anonymous object?
Well, you can use it to simulate the interface of a class
to do some testing and debugging.

=head2 Garbage Collection

Garbage collection is handled automatically by B<Class::Simple>.
The only thing the user has to worry about is cleaning up dangling
and circular references.

Example:

	my $a = Foo->new();
	{
		my $b = Foo->new();
		$b->set_yell('Ouch!');
		$a->next = $b;
	}
	print $a->next->yell;

Even though B<$b> goes out of scope when the block exits,
B<$a->next()> still refers to it so B<DESTROY> is never called on B<$b>
and "Ouch!" is printed.
Why is B<$a> referring to an out-of-scope object in the first place?
Programmer error--there is only so much that B<Class::Simple> can fix :-).

=head1 METHODS

=head2 Class Methods

=over 4

=item B<new(>[attr => val...]B<)>

Returns the object and calls B<BUILD()>.

If key/value pairs are included, the keys will be treated as attributes
and the values will be used to initialize its respective attribute.

=item B<privatize(>qw(method1 method2 ...B<)>

Mark the given methods as being private to the class.
They will only be accessible to the class or its ancestors.
Make sure this is called before you start instantiating objects.
It should probably be put in a B<BEGIN> or B<INIT> block.

=back

=head2 Optional User-defined Methods

=over 4

=item B<BUILD()>

If there is initialization that you would like to do after an
object is created, this is the place to do it.

=item B<NONEW()>

If this is defined in a class, B<new()> will not work for that class.
You can use this in an abstract class when only concrete classes
descended from the abstract class should have B<new()>.

=item B<DEMOLISH()>

If you want to write your own DESTROY, don't.
Do it here in DEMOLISH, which will be called by DESTROY.

=item B<ATTRIBUTES()>

Did I say we can't catch typos?
Well, that's only partially true.
If this is defined in your class, it needs to return an array of
attribute names.
If it is defined, only the attributes returned will be allowed
to be used.
Trying to get or set an attribute not in the list will be a fatal error.
Note that this is an B<optional> method.
You B<do not> have to define your attributes ahead of time to use
Class::Simple.
This provides an optional layer of error-checking.

=back

=head2 Object Methods

=over 4

=item B<init()>

I lied above when I wrote that B<new()> called B<BUILD()>.
It really calls B<init()> and B<init()> calls B<BUILD()>.
Actually, it calls all the B<BUILD()>s of all the ancestor classes
(in a recursive, left-to-right fashion).
If, for some reason, you do not want to do that,
simply write your own B<init()> and this will be short-circuited.

=item B<CLASS>

The class this object was blessed in.
Really used for internal housekeeping but I might as well let you
know about it in case it would be helpful.
It is readonly (see below).

=item B<STORABLE_freeze>

See B<Serialization> below.

=item B<STORABLE_thaw>

See B<Serialization> below.

=back

If you want an attribute named "foo", just start using the following
(no pre-declaration is needed):

=over 4

=item B<foo(>[val]B<)>

Without any parameters, it returns the value of foo.
With a parameter, it sets foo to the value of the parameter and returns it.
Even if that value is undef.

=item B<get_foo()>

Returns the value of foo.

=item B<set_foo(>valB<)>

Sets foo to the value of the given parameter and returns it.

=item B<raise_foo()>

The idea is that if foo is a flag, this raises the flag by
setting foo to 1 and returns it.

=item B<clear_foo()>

Set foo to undef and returns it.

=item B<readonly_foo(>valB<)>

Set foo to the given value, then disallow any further changing of foo.
Returns the value.

=item B<_foo(>[val]B<)>

If you have an attribute foo but you want to override the default method,
you can use B<_foo> to keep the data.
That way you don't have to roll your own way of storing the data,
possibly breaking inside-out.
Underscore methods are automatically privatized.
Also works as B<set__foo> and B<get__foo>.

=back

=head2 Serialization

There are hooks here to work with L<Storable> to serialize objects.
To serialize a Class::Simple-derived object:

    use Storable;

    my $serialized = Storable::freeze($obj);

To reconstitute an object saved with B<freeze()>:

    my $new_obj = Storable::thaw($serialized_str);

=head1 CAVEATS

If an ancestor class has a B<foo> attribute, children cannot have their
own B<foo>.  They get their parent's B<foo>.

I don't actually have a need for DUMP and SLURP but I thought they
would be nice to include.
If you know how I can make them useful for someone who would actually
use them, let me know.

=head1 SEE ALSO

L<Class::Std> is an excellent introduction to the concept
of inside-out objects in Perl
(they are referred to as the "flyweight pattern" in Damian Conway's
I<Object Oriented Perl>).
Many things here, like the name B<DEMOLISH()>, were shamelessly stolen from it.
Standing on the shoulders of giants and all that.

L<Storable>

=head1 AUTHOR

Michael Sullivan, E<lt>perldude@mac.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Michael Sullivan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
