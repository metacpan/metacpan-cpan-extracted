package Basset::Object;

#Basset::Object Copyright and (c) 1999, 2000, 2002-2006 James A Thomason III
#Basset::Object is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Basset::Object - used to create objects

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

This is my ultimate object creation toolset to date. It has roots in Mail::Bulkmail, Text::Flowchart, and the
unreleased abstract object constructors that I've tooled around with in the past.

If you want an object to be compatible with anything else I've written, then subclass it off of here.

Of course, you don't have to use this to create subclasses, but you'll run the risk of making something with an inconsistent
interface vs. the rest of the system. That'll confuse people and make them unhappy. So I recommend subclassing off of here
to be consistent. Of course, you may not like these objects, but they do work well and are consistent. Consistency is
very important in interface design, IMHO.

Please read the tutorials at L<http://www.bassetsoftware.com/perl/basset/tutorial/>.

=cut

$VERSION = '1.03';

sub _conf_class {return 'Basset::Object::Conf'};
BEGIN {eval 'use ' . _conf_class()};

use Data::Dumper ();
use Carp;

use Basset::Container::Hash;

use strict;
use warnings;

=pod

=head1 METHODS

=over

=item add_attr

add_attr adds object attributes to the class.

Okay, now we're going to get into some philosophy. First of all, let me state that I *love* Perl's OO implementation.
I usually get smacked upside the head when I say that, but I find it really easy to use, work with, manipulate, and so
on. And there are things that you can do in Perl's OO that you can't in Java or C++ or the like. Perl, for example, can
have *totally* private values that are completely inaccessible (lexicals, natch). private vars in the other languages
can be redefined or tweaked or subclassed or otherwise gotten around in some form. Not Perl.

And I obviously just adore Perl anyway. I get funny looks when I tell people that I like perl so much because it works
the way I think. That bothers people for some reason.

Anyway, as much as I like how it works, I don't like the fact that there's no consistent object type. An object is,
of course, a blessed ((thingie)) (scalar, array, code, hash, etc) reference. And there are merits to using any of those
things, depending upon the situation. Hashes are easy to work with and most similar to traditional objects.

 $object->{$attribute} = $value;

And whatnot. Arrays are much faster (typically 33% in tests I've done), but they suck to work with.

 $object->[15] = $value;	#the hell is '15'?

 (
  by the way, you can make this easier with variables defined to return the value, i.e.
  $object->[$attribute] = $value;	#assuming $attribute == 15
 )

Scalars are speciality and coderefs are left to the magicians. Don't get me wrong, coderefs as objects are nifty, but
they can be tricky to work with.

So, I wanted a consistent interface. I'm not going to claim credit for this idea, since I think I originally read it
in Object Oriented Programming in Perl (Damien's book). In fact, I think the error reporting method I use was also
originally detailed in there. Anyway, I liked it a lot and decided I'd implement my own version of it. Besides, it's
not like I'm the first guy to say that all attributes should be hidden behind mutators and accessors.

Basically, attributes are accessed and mutated via methods.

 $object->attribute($value);

For all attributes. This way, the internal object can be whatever you'd like. I used to use mainly arrays for the speed
boost, but lately I use hashes a lot because of the ease of dumping and reading the structure for debugging purposes.
But, with this consistent interface of using methods to wrapper the attributes, I can change the implementation of
the object (scalar, array, hash, code, whatever) up in this module and *nothing* else needs to change.

Say you implemented a giant system in OO perl. And you chose hashrefs as your "object". But then you needed a big
speed boost later, which you could easily get by going to arrays. You'd have to go through your code and change all
instances of $object->{$attribute} to $object->[15] or whatever. That's an awful lot of work.

With everything wrappered up this way, changes can be made in the super object class and then automagically populate
out everywhere with no code changes. 

Enough with the philosophy, though. You need to know how this works.

It's easy enough:

 package Some::Class;

 Some::Class->add_attr('foo');

Now your Some::Class objects have a foo attribute, which can be accessed as above. If called with a value, it's the mutator
which sets the attribute to the new value and returns the new value. If called without one, it's the accessor which
returns the value.

 my $obj = Some::Class->new();
 $obj->foo('bar');
 print $obj->foo();			#prints bar
 print $obj->foo('boo');	#prints boo
 print $obj->foo();			#prints boo
 print $obj->foo('bang');	#prints bang
 print $obj->foo;			#prings bang

add_attr calls should only be in your module. B<Never in your program>. And they really should be defined up at the top.

Internally, an add_attr call creates a function inside your package of the name of the attribute which reflects through
to the internal _isa_accessor method which handles the mutating and accessing.

You may alternatively pass in a list of attributes, if you don't want to do so much typing.

 __PACKAGE__->add_attr( qw( foo bar baz ) );

Gives you foo, bar, and baz attributes.

There is another syntax for add_attr, to define a different internal accessor:

 Some::Class->add_attr(['foo', 'accessor_creator']);

This creates method called 'foo' which talks to a separate accessor, in this case the closure returned by "accessor_creator" instead of a closure
returned by _isa_accessor. This is useful if you want to create a validating method on your attribute.

Additionally, it creates a normal method going to _isa_accessor called '__b_foo', which is assumed to be the internal attribute
slot your other accessor with use. In general, for a given "attribute", "__b_attribute" will be created for internal use. Also please
note that you shouldn't ever create a method that starts with '__b_' (double underscore) since Basset reserves the right to automatically
create methods named in that fashion. You've been warned.

"other_accessor" will get the object as the first arg (as always) and the name of the internal method as the second.

A sample accessor_creator could look like this:

 Some::Class->add_attr(['foo', 'accessor_creator']);

 sub accessor_creator {
 	my $self = shift;
 	my $attribute = shift;	#the external method name
 	my $prop = shift;		#the internal "slot" that is a normal attribute

 	#now we make our closure:
 	return sub {
 		my $self = shift;
 		if (@_) {
 			my $val = shift;
 			if ($val == 7) {
 				return $self->$prop($val);
 			}
 			else {
 				return $self->error("Cannot store value...must be 7!", "not_7");
 			}
 		}
 		else {
 			return $self->$prop();
 		}
 	}
 }

And, finally, you can also pass in additional arguments as static args if desired.

 Some::Class->add_attr(['foo', 'accessor_creator'], 'bar');

 $obj->foo('bee');

 sub accessor_creator {
 	my $self	= shift;
 	my $method	= shift;
 	my $static 	= shift;	#'bar' in our example

	return sub {
		#do something with static argument
		.
		.
	}
 };

All easy enough. Refer to any subclasses of this class for further examples.

Basset::Object includes two other alternate accessors for you - regex and private.

 Some::Class->add_attr(['user_id', '_isa_regex_accessor', qr{^\d+$}, "Error - user_id must be a number", "NaN"]);

The arguments to it are, respectively, the name of the attribute, the internal accessor used, the regex used to validate, the error message to return, and the error code to return.
If you try to mutate with a value that doesn't match the regex, it'll fail.

 Some::Class->add_attr(['secret', '_isa_private_accessor']);

private accessors add a slight degree of security. All they do is simply restrict access to the attribute unless you are within the class of the object. Note, that this causes
access to automatically trickle down into subclasses.

=cut

sub add_attr {
	my $pkg			= shift;

	no strict 'refs';

	foreach my $record (@_) {
		my ($attribute, $adding_method, $internal_attribute, @args);
		if (ref $record eq 'ARRAY') {
			($attribute, $adding_method, @args) = @$record;
			$internal_attribute = $pkg->privatize($attribute);
			*{$pkg . "::$internal_attribute"}	= $pkg->_isa_accessor($internal_attribute, $attribute)
				unless *{$pkg . "::$internal_attribute"}{'CODE'};
			*{$pkg . "::$attribute"}			= $pkg->$adding_method($attribute, $internal_attribute, @args)
				unless *{$pkg . "::$attribute"}{'CODE'};
		}
		else {
			$attribute = $record;
			*{$pkg . "::$record"} = $pkg->_isa_accessor($record) unless *{$pkg . "::$record"}{'CODE'};
		}

		$pkg->_instance_attributes->{$attribute}++;

	}

	return 1;

}

sub _isa_accessor {
	my $pkg			= shift;
	my $attribute	= shift;
	my $prop		= shift || $attribute;

	return sub {
		my $self = shift;

		return $self->error("Not a class attribute", "BO-08") unless ref $self;

		$self->{$prop} = shift if @_;

		$self->{$prop};
	};
}

# _accessor is the main accessor method used in the system. It defines the most simple behavior as to how objects are supposed
# to work. If it's called with no arguments, it returns the value of that attribute. If it's called with arguments,
# it sets the object attribute value to the FIRST argument passed and ignores the rest
#
# example:
# my $object;
# print $object->attribute7();		#prints out the value of attribute7
# print $object->attribute7('foo');	#sets the value of attribute7 to 'foo', and prints 'foo'
# print $object->attribute7();		#prints out the value of attribute7, which is now known to be foo
#
# All internal accessor methods should behave similarly, read the documentation for add_attr for more information

#tested w/ add_attr, above

sub _isa_regex_accessor {
	my $pkg		= shift;
	my $attribute	= shift;
	my $prop		= shift;
	my $regex		= shift;
	my $error		= shift;
	my $code		= shift;

	return sub {
		my $self = shift;
		if (@_) {
			my $val = shift;
			return $self->error($error, $code) if defined $val && $val !~ /$regex/;

			return $self->$prop($val);
		}
		else {
			return $self->$prop();
		}
	};	
}

sub _isa_private_accessor {
	my $pkg		= shift;
	my $attribute	= shift;
	my $prop		= shift;

	return sub  {
		my $self = shift;
		my @caller = caller;
		return $self->error("Cannot access $prop : private method", "BO-27") unless $caller[0] eq $self->pkg;

		$self->$prop(@_);
	};

}

=pod

=begin btest(add_attr)

sub add_test_accessor {
	my $pkg = shift;
	my $attr = shift;
	my $prop = shift;
	my $extra = shift;

	no strict 'refs';

	return sub   {
				my $self = shift;
				return $self->error("Not a class attribute", "BO-08") unless ref $self;
				$extra;
		};
}

$test->ok(\&__PACKAGE__::test_accessor, "Added test accessor");

my $o = __PACKAGE__->new();
$test->ok($o, "Object created");

$test->ok(__PACKAGE__->add_attr('test_attribute1'), "Added attribute for _accessor");
$test->ok(__PACKAGE__->add_attr('test_attribute1'), "Re-added attribute for _accessor");
$test->ok($o->can('test_attribute1'), "Object sees attribute");
$test->ok(__PACKAGE__->can('test_attribute1'), "Class sees attribute");

$test->is($o->test_attribute1('testval1'), 'testval1', "Method test_attribute1 mutates");
$test->is($o->test_attribute1(), 'testval1', "Method test_attribute1 accesses");
$test->is($o->test_attribute1(undef), undef, "Method test_attribute1 deletes");

$test->is(scalar __PACKAGE__->test_attribute1('testval17'), undef, "Class fails to mutate");
$test->is(scalar __PACKAGE__->test_attribute1(), undef, "Class fails to access");
$test->is(scalar __PACKAGE__->test_attribute1(undef), undef, "Class fails to delete");

$test->ok(__PACKAGE__->add_attr(['test_attribute2', 'add_test_accessor', 'excess']), "Added attribute for test_accessor");
$test->ok(__PACKAGE__->add_attr(['test_attribute2', 'add_test_accessor', 'excess']), "Re-added attribute for test_accessor");
$test->ok($o->can('test_attribute2'), "Object sees attribute");
$test->ok(__PACKAGE__->can('test_attribute2'), "Class sees attribute");

$test->is($o->test_attribute2('testval2'), 'excess', "Method test_attribute2 mutates");
$test->is($o->test_attribute2(), 'excess', "Method test_attribute2 accesses");
$test->is($o->test_attribute2(undef), 'excess', "Method test_attribute2 deletes");

$test->is(scalar __PACKAGE__->test_attribute2('testval18'), undef, "Class fails to mutate");
$test->is(scalar __PACKAGE__->test_attribute2(), undef, "Class fails to access");
$test->is(scalar __PACKAGE__->test_attribute2(undef), undef, "Class fails to delete");

$test->ok(__PACKAGE__->add_attr('test_attribute3', 'static'), "Added static attribute");
$test->ok($o->can('test_attribute3'), "Object sees attribute");
$test->ok(__PACKAGE__->can('test_attribute3'), "Class sees attribute");

$test->is($o->test_attribute3('status'), 'status', "Method test_attribute3 mutates");
$test->is($o->test_attribute3(), 'status', "Method test_attribute3 accesses");
$test->is($o->test_attribute3(undef), undef, "Method test_attribute3 deletes");

$test->is(scalar __PACKAGE__->test_attribute3('testval19'), undef, "Class fails to mutate");
$test->is(scalar __PACKAGE__->test_attribute3(), undef, "Class fails to access");
$test->is(scalar __PACKAGE__->test_attribute3(undef), undef, "Class fails to delete");

$test->ok(__PACKAGE__->add_attr(['test_attribute4', '_isa_regex_accessor', '^\d+$', 'Numbers only', 'test code']), "Added numeric only regex attribute");
$test->ok($o->can('test_attribute4'), "Object sees attribute");
$test->ok(__PACKAGE__->can('test_attribute4'), "Class sees attribute");

$test->isnt(scalar $o->test_attribute4('foo'), 'foo', "Method test_attribute4 fails to set non-numeric");
$test->is($o->error, "Numbers only", "Proper object error message");
$test->is($o->errcode, "test code", "Proper object error code");
$test->isnt(scalar $o->test_attribute4('1234567890a'), '1234567890a', "Method test_attribute4 fails to set non-numeric");
$test->is($o->error, "Numbers only", "Proper object error message");
$test->is($o->errcode, "test code", "Proper object error code");
$test->isnt(scalar $o->test_attribute4('a1234567890'), 'a1234567890', "Method test_attribute4 fails to set non-numeric");
$test->is($o->error, "Numbers only", "Proper object error message");
$test->is($o->errcode, "test code", "Proper object error code");
$test->isnt(scalar $o->test_attribute4('123456a7890'), '123456a7890', "Method test_attribute4 fails to set non-numeric");
$test->is($o->error, "Numbers only", "Proper object error message");
$test->is($o->errcode, "test code", "Proper object error code");
$test->is(scalar $o->test_attribute4('12345'), '12345', "Method test_attribute4 mutates");
$test->is(scalar $o->test_attribute4(), '12345', "Method test_attribute4 accesses");
$test->is(scalar $o->test_attribute4(undef), undef, "Method test_attribute4 deletes");

$test->is(scalar __PACKAGE__->test_attribute4('testval20'), undef, "Class fails to mutate");
$test->is(scalar __PACKAGE__->test_attribute4(), undef, "Class fails to access");
$test->is(scalar __PACKAGE__->test_attribute4(undef), undef, "Class fails to delete");

$test->ok(__PACKAGE__->add_attr(['test_attribute5', '_isa_regex_accessor', 'abcD', 'Must contain abcD', 'test code2']), "Added abcD only regex attribute");
$test->ok($o->can('test_attribute5'), "Object sees attribute");
$test->ok(__PACKAGE__->can('test_attribute5'), "Class sees attribute");

$test->isnt(scalar $o->test_attribute5('foo'), 'foo', "Method test_attribute4 fails to set non-abcD");
$test->is($o->error, "Must contain abcD", "Proper object error message");
$test->is($o->errcode, "test code2", "Proper object error code");
$test->isnt(scalar $o->test_attribute5('abc'), 'abc', "Method test_attribute4 fails to set non-abcD");
$test->is($o->error, "Must contain abcD", "Proper object error message");
$test->is($o->errcode, "test code2", "Proper object error code");
$test->isnt(scalar $o->test_attribute5('bcD'), 'bcD', "Method test_attribute4 fails to set non-abcD");
$test->is($o->error, "Must contain abcD", "Proper object error message");
$test->is($o->errcode, "test code2", "Proper object error code");
$test->isnt(scalar $o->test_attribute5('abD'), 'abD', "Method test_attribute4 fails to set non-abcD");
$test->is($o->error, "Must contain abcD", "Proper object error message");
$test->is($o->errcode, "test code2", "Proper object error code");
$test->is(scalar $o->test_attribute5('abcD'), 'abcD', "Method test_attribute5 mutates");
$test->is(scalar $o->test_attribute5('abcDE'), 'abcDE', "Method test_attribute5 mutates");
$test->is(scalar $o->test_attribute5('1abcD'), '1abcD', "Method test_attribute5 mutates");
$test->is(scalar $o->test_attribute5('zabcDz'), 'zabcDz', "Method test_attribute5 mutates");
$test->is(scalar $o->test_attribute5(), 'zabcDz', "Method test_attribute5 accesses");
$test->is(scalar $o->test_attribute5(undef), undef, "Method test_attribute5 deletes");

$test->is(scalar __PACKAGE__->test_attribute5('testval20'), undef, "Class fails to mutate");
$test->is(scalar __PACKAGE__->test_attribute5(), undef, "Class fails to access");
$test->is(scalar __PACKAGE__->test_attribute5(undef), undef, "Class fails to delete");

package Basset::Test::Testing::__PACKAGE__::add_attr::Subclass1;
our @ISA = qw(__PACKAGE__);

my $sub_class = "Basset::Test::Testing::__PACKAGE__::add_attr::Subclass1";

my $so = $sub_class->new();

$test->ok(scalar $sub_class->add_attr(['secret', '_isa_private_accessor']), 'added secret accessor');
$test->ok($so->can('secret'), "Object sees secret attribute");
$test->is($so->secret('foobar'), 'foobar', 'Object sets secret attribute');
$test->is($so->secret(), 'foobar', 'Object sees secret attribute');

package __PACKAGE__;

$test->is(scalar $so->secret(), undef, 'Object cannot see secret attribute outside');
$test->is($so->errcode, 'BO-27', 'proper error code');

=end btest(add_attr)

=cut

=pod

=item add_class_attr

This is similar to add_attr, but instead of adding object attributes, it adds class attributes. You B<cannot> have
object and class attributes with the same name. This is by design. (error is a special case)

 Some::Class->add_attr('foo');			#object attribute foo
 Some::Class->add_class_attr('bar'):	#class attribute bar

 print $obj->foo();
 print Some::Class->bar();

Behaves the same as an object method added with add_attr, mutating with a value, accessing without one. Note
that add_class_attr does not have the capability for additional internal methods or static values. If you want
those on a class method, you'll have to wrapper the class attribute yourself on a per case basis.

Note that you can access class attributes via an object (as expected), but it's frowned upon since it may be
confusing.

class attributes are automatically initialized to any values in the conf file upon adding, if present.

=cut

=pod

=begin btest(add_class_attr)

my $o = __PACKAGE__->new();
$test->ok($o, "Object created");

$test->ok(__PACKAGE__->add_class_attr('test_class_attribute_1'), "Added test class attribute");
$test->ok(__PACKAGE__->add_class_attr('test_class_attribute_1'), "Re-added test class attribute");
$test->ok($o->can("test_class_attribute_1"), "object can see class attribute");
$test->ok(__PACKAGE__->can("test_class_attribute_1"), "class can see class attribute");

$test->is(__PACKAGE__->test_class_attribute_1('test value 1'), 'test value 1', 'class method call mutates');
$test->is(__PACKAGE__->test_class_attribute_1(), 'test value 1', 'class method call accesses');
$test->is(__PACKAGE__->test_class_attribute_1(undef), undef, 'class method call deletes');

$test->is($o->test_class_attribute_1('test value 2'), 'test value 2', 'object method call mutates');
$test->is($o->test_class_attribute_1(), 'test value 2', 'object method call accesses');
$test->is($o->test_class_attribute_1(undef), undef, 'object method call deletes');

$test->ok(__PACKAGE__->add_class_attr('test_class_attribute_2', 14), "Added test class attribute 2");
$test->ok($o->can("test_class_attribute_2"), "object can see class attribute");
$test->ok(__PACKAGE__->can("test_class_attribute_2"), "class can see class attribute");

$test->is(__PACKAGE__->test_class_attribute_2(), 14, "Class has default arg");
$test->is(__PACKAGE__->test_class_attribute_2(), 14, "Object has default arg");

$test->is(__PACKAGE__->test_class_attribute_2('test value 3'), 'test value 3', 'class method call mutates');
$test->is(__PACKAGE__->test_class_attribute_2(), 'test value 3', 'class method call accesses');
$test->is(__PACKAGE__->test_class_attribute_2(undef), undef, 'class method call deletes');

$test->is($o->test_class_attribute_1('test value 4'), 'test value 4', 'class method call mutates');
$test->is($o->test_class_attribute_1(), 'test value 4', 'object method call accesses');
$test->is($o->test_class_attribute_1(undef), undef, 'object method call deletes');

package Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

my $so = Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->new();
$test->ok($so, "Sub-Object created");

$test->is(scalar __PACKAGE__->test_class_attribute_1("newer test val"), "newer test val", "trickle method class re-mutates");

$test->is(scalar $so->test_class_attribute_1(), "newer test val", "trickle method sub-object accesses super");

$test->is(scalar $so->test_class_attribute_1("testval3"), "testval3", "trickle method sub-object mutates");
$test->is(scalar $so->test_class_attribute_1(), "testval3", "trickle method sub-object accesses");
$test->is(scalar $so->test_class_attribute_1(undef), undef, "trickle method sub-object deletes");

$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->test_class_attribute_1("testval4"), "testval4", "trickle method class mutates");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->test_class_attribute_1(), "testval4", "trickle method subclass accesses");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->test_class_attribute_1(undef), undef, "trickle method subclass deletes");

$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->test_class_attribute_1("sub value"), "sub value", "Subclass re-mutates");
$test->is(scalar __PACKAGE__->test_class_attribute_1(), "sub value", "Super class affected on access");

$test->is(scalar __PACKAGE__->test_class_attribute_1("super value"), "super value", "Super class re-mutates");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->test_class_attribute_1(), "super value", "Sub class affected on access");

package Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass5;
our @ISA = qw(__PACKAGE__);

sub conf {
	return undef;
};

package __PACKAGE__;

{

	local $@ = undef;

	eval {
		Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass5->add_class_attr('test_class_attr');
	};

	$test->like($@, qr/^Conf file error :/, 'could not add class attr w/o conf file');
}

my $conf = __PACKAGE__->conf();
$conf->{'__PACKAGE__'}->{'_test_attribute'} = 'test value';

$test->ok(__PACKAGE__->add_class_attr('_test_attribute'), 'added test attribute');
$test->is(__PACKAGE__->_test_attribute, 'test value', 'populated with value from conf fiel');

=end btest(add_class_attr)

=cut

sub add_class_attr {
	my $pkg		= shift;
	my $method	= shift;

	no strict 'refs';

	return $method if *{$pkg . "::$method"}{'CODE'};

	#Slick. We'll use a proper closure here.
	my $attr = undef;
	*{$pkg . "::$method"} = sub {
		my $pkg = shift;
		$attr = shift if @_;
		return $attr;
	};

	#see if there's anything in the conf file

	my $conf = $pkg->conf or die "Conf file error : could not read conf file";


	if (exists $conf->{$pkg}->{$method}){
		$pkg->$method($conf->{$pkg}->{$method});
	}
	elsif (@_){
		$pkg->$method(@_);
	}

	$pkg->_class_attributes->{$method}++;

	return $method;
};

=pod

=item add_trickle_class_attr

It's things like this why I really love Perl.

add_trickle_class_attr behaves the same as add_class_attr with the addition that it will trickle the attribute down
into any class as it is called. This is useful for subclasses.

Watch:

 package SuperClass;

 SuperClass->add_class_attr('foo');
 SuperClass->foo('bar');

 package SubClass;
 @ISA = qw(SuperClass);

 print SubClass->foo();			#prints bar
 print SuperClass->foo();		#prints bar

 print SuperClass->foo('baz');	#prints baz
 print SubClass->foo();			#prints baz

 print SubClass->foo('dee');	#prints dee
 print SuperClass->foo();		#prints dee

See? The attribute is still stored in the super class, so changing it in a subclass changes it in the super class as well.
Usually, this behavior is fine, but sometimes you don't want that to happen. That's where add_trickle_class_attr comes
in. Its first call will snag the value from the SuperClass, but then it will have its own attribute that's separate.

Again, watch:

 package SuperClass;

 SuperClass->add_trickle_class_attr('foo');
 SuperClass->foo('bar');

 package SubClass;
 @ISA = qw(SuperClass);

 print SubClass->foo();			#prints bar
 print SuperClass->foo();		#prints bar

 print SuperClass->foo('baz');	#prints baz
 print SubClass->foo();			#prints bar

 print SubClass->foo('dee');	#prints dee (note we're setting the subclass here)
 print SuperClass->foo();		#prints baz

This is useful if you have an attribute that should be unique to a class and all subclasses. These are equivalent:

 package SuperClass;
 SuperClass->add_class_attr('foo');

 package SubClass
 SubClass->add_class_attr('foo');

 and

 package SuperClass;
 SuperClass->add_trickle_class_attr('foo');

You'll usually just use add_class_attr. Only use trickle_class_attr if you know you need to, since you rarely would.
There is a *slight* bit of additional processing required for trickled accessors.

trickled class attributes are automatically initialized to any values in the conf file upon adding, if present.

References are a special case. If you add a hashref, that hashref will automatically be tied to a Basset::Container::Hash.
Do not do this tying yourself, since bad things would occur. Once tied to Basset::Container::Hash, the hashref is now
effectively layered so that subclasses may directly add to the hash without affecting parent values. Subclasses may not delete
keys from the hash, only delete values they have added. Arrays are not tied.

Sometimes, you may be required to access the attribute via a wrapper method. 
For example:

 sub wrapper {
 	my $self	= shift;

 	my $existing = $self->trickled_ref();

 	if (@_) {
 		my $dumped = $self->dump($existing);	#take a dump of the ref
 		no strict; no warnings;					#make sure nothing complains
 		$self->trickled_ref(eval $dump);		#stick in a copy of it
 	}

 	return $self->trickled_ref(@_);
 }

Then you need to access the trickled method through the wrapper you've created. I don't want to
add functionality like that into the add_trickle_class_attr method because I won't know when
the value needs to be changed. You're getting back a reference, but then manipulating the value
of the reference. So once you have a ref back, you immediately start changing the super class's
value. The only way that I could fix it up here is to constantly re-copy the reference on
every single access. But, of course, that then stops it from seeing changes in the super class,
which is inconsistent.

Realistically, if you're using a ref and modifying it, you'll want wrapper methods to do things
like add values within the ref, delete values within the ref, etc, you'll rarely (if ever) access
the actual value of the ref directly. That is to say, you'll rarely change the hash pointed at,
you'll change keys within the hash. So add_foo, delete_foo, change_foo, etc. wrappers that properly
copy the hash as appropriate are the way to go. You can then still properly read the ref by
just using the trickled attribute as always.

See the add_restrictions method below for an example of a wrapper like this.

=cut

sub add_trickle_class_attr { 
	my $internalpkg	= shift;
	my $method		= shift;

	no strict 'refs';

	return $method if *{$internalpkg . "::$method"}{'CODE'};

	my $attr = undef;
	my $initialized = {$internalpkg => 1};

	*{$internalpkg . "::$method"} = sub {

		my $class = shift->pkg;

		unless ($initialized->{$class}) {
			$initialized->{$class}++;
			my $local_conf = $class->conf('local');
			if (defined (my $confval = $local_conf->{$method})) {
				return $class->$method($confval);
			};
		}

		if (@_) {
			if ($class ne $internalpkg) {
				$class->add_trickle_class_attr($method);
				my $val = shift;

				if (ref $val eq 'HASH' && ref $attr eq 'HASH') {
					#the tie blows away the values, so we need to keep a copy.
					my %tmp;
					@tmp{keys %$val} = values %$val;
					tie %$val, 'Basset::Container::Hash', $attr;
					$class->add_trickle_class_attr($method);
					@$val{keys %tmp} = values %tmp;
				}

				return $class->$method($val, @_);
			}
			$attr = shift;
		}

		if (ref $attr eq 'HASH' && $class ne $internalpkg) {
			tie my %empty, 'Basset::Container::Hash', $attr;
			$class->add_trickle_class_attr($method, \%empty);
			return $class->$method();
		}

		return $attr;
	};

	my $conf = $internalpkg->conf;

	if (defined (my $confval = $conf->{$internalpkg}->{$method})) {
		$internalpkg->$method($confval);
	}
	elsif (@_) {
		$internalpkg->$method(@_);
	}

	$internalpkg->_class_attributes->{$method}++;

	return $method;

}

=pod

=begin btest(add_trickle_class_attr)

my $o = __PACKAGE__->new();
$test->ok($o, "Object created");

$test->ok(__PACKAGE__->add_trickle_class_attr('trick_attr1'), "Added test trickle class attribute");
$test->ok(__PACKAGE__->add_trickle_class_attr('trick_attr1'), "Re-added test trickle class attribute");
$test->ok($o->can("trick_attr1"), "object can see trickle class attribute");
$test->ok(__PACKAGE__->can("trick_attr1"), "class can see trickle class attribute");

package Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

my $so = Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->new();
$test->ok($so, "Sub-Object created");

$test->is(scalar $o->trick_attr1("testval1"), "testval1", "trickle method object mutates");
$test->is(scalar $o->trick_attr1(), "testval1", "trickle method object accesses");
$test->is(scalar $o->trick_attr1(undef), undef, "trickle method object deletes");

$test->is(scalar __PACKAGE__->trick_attr1("testval2"), "testval2", "trickle method class mutates");
$test->is(scalar __PACKAGE__->trick_attr1(), "testval2", "trickle method class accesses");
$test->is(scalar __PACKAGE__->trick_attr1(undef), undef, "trickle method class deletes");
$test->is(scalar __PACKAGE__->trick_attr1("newer test val"), "newer test val", "trickle method class re-mutates");

$test->is(scalar $so->trick_attr1(), "newer test val", "trickle method sub-object accesses super");

$test->is(scalar $so->trick_attr1("testval3"), "testval3", "trickle method sub-object mutates");
$test->is(scalar $so->trick_attr1(), "testval3", "trickle method sub-object accesses");
$test->is(scalar $so->trick_attr1(undef), undef, "trickle method sub-object deletes");

$test->is(scalar __PACKAGE__->trick_attr1("supertestval"), "supertestval", "super trickle method class mutates");
$test->is(__PACKAGE__->trick_attr1(), "supertestval", "trickle method class accesses");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->trick_attr1("testval4"), "testval4", "trickle method class mutates");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->trick_attr1(), "testval4", "trickle method subclass accesses");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->trick_attr1(undef), undef, "trickle method subclass deletes");
$test->is(Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->trick_attr1(), undef, "subclass still sees undef as value");

$test->is(scalar __PACKAGE__->trick_attr1("super value"), "super value", "Super class re-mutates");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->trick_attr1("sub value"), "sub value", "Subclass re-mutates");

$test->is(scalar __PACKAGE__->trick_attr1(), "super value", "Super class unaffected on access");
$test->is(scalar __PACKAGE__->trick_attr1("new super value"), "new super value", "Super class re-mutates");
$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_class_attr::Subclass1->trick_attr1(), "sub value", "Sub class unaffected on access");

package Basset::Test::Testing::__PACKAGE__::add_trickle_class_attr::Subclass5;
our @ISA = qw(__PACKAGE__);

sub conf {
	return undef;
};

package __PACKAGE__;

{
	local $@ = undef;
	eval {
		Basset::Test::Testing::__PACKAGE__::add_trickle_class_attr::Subclass5->add_class_attr('test_trickle_attr');
	};
	$test->like($@, qr/^Conf file error :/, 'could not add trickle class attr w/o conf file');
}

=end btest(add_trickle_class_attr)

=cut

=pod

=item add_default_class_attr

This adds a class attribute that is considered to be 'read-only' - it gets its value exclusively
and utterly only from the conf file. Any modifications to this value are discarded in favor of the
conf file value

=cut

sub add_default_class_attr {

	my $pkg = shift;
	my $method = shift;

	no strict 'refs';

	return $method if *{$pkg . "::$method"}{'CODE'};

	#Slick. We'll use a proper closure here.
	my $attr = undef;
	*{$pkg . "::$method"} = sub {

		my $class = shift;

		my $conf = $pkg->conf or die "Conf file error : could not read conf file";

		$conf->{$pkg}->{$method} = shift if @_;

		return $conf->{$pkg}->{$method};
	};

	$pkg->_class_attributes->{$method}++;

	return $method;

}

=pod

=begin btest(add_default_attr)

package Basset::Test::Testing::__PACKAGE__::add_default_class_attr::subclass;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::add_default_class_attr::subclass->add_default_class_attr('some_test_attr'), "Added default class attribute");
$test->ok(Basset::Test::Testing::__PACKAGE__::add_default_class_attr::subclass->add_default_class_attr('some_test_attr'), "Re-added default class attribute");

package Basset::Test::Testing::__PACKAGE__::add_default_class_attr::Subclass5;
our @ISA = qw(__PACKAGE__);

sub conf {
	return undef;
};

package __PACKAGE__;

{
	local $@ = undef;
	eval {
		Basset::Test::Testing::__PACKAGE__::add_default_class_attr::Subclass5->add_class_attr('test_default_attr');
	};
	$test->like($@, qr/^Conf file error :/, 'could not add default class attr w/o conf file');
}

=end btest(add_default_attr)

=cut

=pod

=item attributes

Returns the attributes available to this object, based off of the flag passed in - "instance", "class", or "both".
defaults to "instance".

Note - this method will not return attributes that begin with a leading underscore, as a courtesy.

=cut

sub attributes {
	my $class	= shift->pkg;
	my $type	= shift || 'instance';

	my @attributes = ();

	if ($type eq 'instance') {
		@attributes = keys %{$class->_instance_attributes};
	}
	elsif ($type eq 'class') {
		@attributes = keys %{$class->_class_attributes};
	}
	elsif ($type eq 'both') {
		@attributes = (keys %{$class->_instance_attributes}, keys %{$class->_class_attributes});
	}
	else {
		return $class->error("Cannot get attributes - don't know how to get '$type'", "BO-37");
	}

	return [sort grep {! /^_/} @attributes];
}

=pod

=begin btest(attributes)

package Basset::Test::Testing::__PACKAGE__::attributes::Subclass1;
our @ISA = qw(__PACKAGE__);
my $subclass = "Basset::Test::Testing::__PACKAGE__::attributes::Subclass1";

$subclass->add_attr('foo');
$subclass->add_attr('bar');
$subclass->add_class_attr('baz');
$subclass->add_trickle_class_attr('trick');

$test->is(ref $subclass->attributes('instance'), 'ARRAY', 'instance attributes is array');
$test->is(ref $subclass->attributes('class'), 'ARRAY', 'class attributes is array');
$test->is(ref $subclass->attributes('both'), 'ARRAY', 'both attributes is array');
$test->is(scalar $subclass->attributes('invalid'), undef, 'non token attributes is error');
$test->is($subclass->errcode, 'BO-37', 'proper error code');

my $instance = { map {$_ => 1} @{$subclass->attributes} };
$test->is($instance->{'foo'}, 1, 'foo is instance attribute from anon');
$test->is($instance->{'bar'}, 1, 'bar is instance attribute from anon');
$test->is($instance->{'baz'}, undef, 'baz is not instance attribute from anon');
$test->is($instance->{'trick'}, undef, 'trick is not instance attribute from anon');

my $instance_ex = { map {$_ => 1} @{$subclass->attributes('instance')} };
$test->is($instance_ex->{'foo'}, 1, 'foo is instance attribute from explicit');
$test->is($instance_ex->{'bar'}, 1, 'bar is instance attribute from explicit');
$test->is($instance_ex->{'baz'}, undef, 'baz is not instance attribute from explicit');
$test->is($instance_ex->{'trick'}, undef, 'trick is not instance attribute from explicit');

my $both = { map {$_ => 1} @{$subclass->attributes('both')} };
$test->is($both->{'foo'}, 1, 'foo is instance attribute from both');
$test->is($both->{'bar'}, 1, 'bar is instance attribute from both');
$test->is($both->{'baz'}, 1, 'baz is class attribute from both');
$test->is($both->{'trick'}, 1, 'trick is class attribute from both');

my $class = { map {$_ => 1} @{$subclass->attributes('class')} };
$test->is($class->{'foo'}, undef, 'foo is not instance attribute from class');
$test->is($class->{'bar'}, undef, 'bar is not instance attribute from class');
$test->is($class->{'baz'}, 1, 'baz is class attribute from both');
$test->is($class->{'trick'}, 1, 'trick is class attribute from class');

=end btest(attributes)

=cut

=pod

=item is_attribute

=cut

sub is_attribute {
	my $class = shift->pkg;
	my $attribute = shift;
	my $type = shift || 'instance';

	if ($type eq 'both') {
		return $class->_instance_attributes->{$attribute} || $class->_class_attributes->{$attribute} || 0;
	}
	if ($type eq 'instance') {
		return $class->_instance_attributes->{$attribute} || 0;
	}
	elsif ($type eq 'class') {
		return $class->_class_attributes->{$attribute} || 0;
	}
	else {
		return $class->error("Cannot determine is_attribute for flag : $type", "BO-38");
	}

}

=pod

=begin btest(is_attribute)

package Basset::Test::Testing::__PACKAGE__::is_attribute::Subclass1;
our @ISA = qw(__PACKAGE__);
my $subclass = "Basset::Test::Testing::__PACKAGE__::is_attribute::Subclass1";

$subclass->add_attr('ins1');
$subclass->add_attr('ins2');
$subclass->add_class_attr('class');
$subclass->add_trickle_class_attr('trick');

$test->ok($subclass->is_attribute('ins1') != 0, 'ins1 is instance by default');
$test->ok($subclass->is_attribute('ins2') != 0, 'ins2 is instance by default');

$test->ok($subclass->is_attribute('ins1', 'instance') != 0, 'ins1 is instance by explicitly');
$test->ok($subclass->is_attribute('ins2', 'instance') != 0, 'ins2 is instance by explicitly');

$test->ok($subclass->is_attribute('class') == 0, 'class is not attribute by default');
$test->ok($subclass->is_attribute('class', 'class') != 0, 'class is class attribute by default');

$test->ok($subclass->is_attribute('trick') == 0, 'trick is not attribute by default');
$test->ok($subclass->is_attribute('trick', 'class') != 0, 'trick is class attribute by default');

$test->ok($subclass->is_attribute('ins1', 'both') != 0, 'ins1 is instance by both');
$test->ok($subclass->is_attribute('ins2', 'both') != 0, 'ins2 is instance by both');
$test->ok($subclass->is_attribute('trick', 'both') != 0, 'trick is class attribute by both');
$test->ok($subclass->is_attribute('class', 'both') != 0, 'class is class attribute by both');

$test->ok($subclass->is_attribute('fake_instance') == 0, 'fake_instance is not attribute by default');
$test->ok($subclass->is_attribute('fake_instance','both') == 0, 'fake_instance is not attribute by both');
$test->ok($subclass->is_attribute('fake_instance','instance') == 0, 'fake_instance is not attribute by instance');
$test->ok($subclass->is_attribute('fake_instance','class') == 0, 'fake_instance is not attribute by class');

$test->is(scalar $subclass->is_attribute('ins1', 'invalid'), undef, "invalid is_attribute flag is error condition");
$test->is($subclass->errcode, "BO-38", "proper error code");

=end btest(is_attribute)

=cut

=pod

=item add_wrapper

You can now wrapper methods with before and after hooks that will get executed before or after the method, as desired. Syntax is:

 $class->add_wrapper('(before|after)', 'method_name', 'wrapper_name');

That is, either before or after method_name is called, call wrapper_name first. Before wrappers are good to change the
values going into a method, after wrappers are good to change the values coming back out.

For example,

 sub foo_wrapper {
 	my $self = shift;
 	my @args = @_; # (whatever was passed in to foo)
 	print "I am executing foo!\n";
 	return 1;
 }

 $class->add_wrapper('before', 'foo', 'foo_wrapper');

 Now, $class->foo() is functionally the same as:

 if ($class->foo_wrapper) {
 	$class->foo();
 }

Ditto for the after wrapper.

 if ($class->foo) {
 	$class->after_foo_wrapper;
 }

Wrappers are run in reverse add order. That is, wrappers added later are executed before wrappers added earlier.
Wrappers are inherited in subclasses. Subclasses run all of their wrappers in reverse add order, then run all
super class wrappers in reverse add order.

Wrapper functions should return a true value upon success, or set an error upon failure.

Performance hit is fairly negligible, since add_wrapper re-wires the symbol table. So be careful using this
functionality with other methods that may re-wire the symbol table (such as Basset::Object::Persistent's _instantiating_accessor)

See also the extended syntax for add_attr, and Basset::Object::Persistent's import_from_db and export_to_db methods
for different places to add in hooks, as well as the delegate attribute, below, for another way to extend code.

The performance hit for wrappers is reasonably small, but if a wrappered method is constantly being hit and the 
wrapping code isn't always used (for example, wrapping an attribute. If your wrapper only does anything
upon mutation, it's wasteful, since the wrapper will still -always- be called), you can suffer badly. In those
cases, an extended attribute or an explicit wrapper function of your own may be more useful. Please note that wrappers
can only be defined on a per-method basis. If you want to re-use wrappers across multiple methods, you'll need your
own wrapping mechanism. For example, using the extended attribute syntax to use a different accessor method.

There is an optional fourth argument - the conditional operator. This is a method (or coderef called as a method) that
is executed before the wrapper is called. If the conditional returns true, the wrapper is then executed. If the conditional
returns false, the wrapper is not executed.

 Some::Class->add_wrapper('after', 'name', 'validation', sub {
 	my $self = shift;
 	return @_;
 } );

That wrapper will only call the 'validation' method upon mutation (that is, when there are arguments passed) and
not upon simple access.

Subclasses may define additional wrapper types.

Please don't wrapper attributes. Things may break if the attribute value is legitimately undef (normally an error condition). Instead,
use the extended add_attr syntax to define a new accessor method for the attribute you wish to wrap. Or simply write your own subroutine
and directly call a separately added attribute yourself.

=cut

sub add_wrapper {

	my $class		= shift;
	my $type		= shift or return $class->error("Cannot add wrapper w/o type", "BO-31");
	my $method		= shift or return $class->error("Cannot add wrapper w/o attribute", "BO-32");
	my $wrapper		= shift or return $class->error("Cannot add wrapper w/o wrapper", "BO-33");
	my $conditional	= shift || 'no_op';

	return $class->error("Cannot add wrapper : class does not know how to $method", "BO-34")
		unless $class->can($method);

	return $class->error("Cannot add wrapper : $method is an attribute. Explicitly wrapper or use a new accessor method", "BO-39")
		if $class->is_attribute($method, 'both');

	my $private = $class->privatize("privately_wrappered_$method");

	no strict 'refs';
	no warnings;

	my $ptr;

	if (*{$class . "::$method"}{'CODE'}) {

		*{$class . "::$private"} = *{$class . "::$method"}{'CODE'};
		#if it's local to us, we're carefully hiding the function, so we need to look
		#at an actual reference to the original
		$ptr = *{$class . "::$private"}{'CODE'};
	} else {
	#otherwise, we need to find out who owns it, and keep a soft pointer to it.
		my @parents = reverse @{$class->isa_path};
		foreach my $parent (@parents) {
			if (*{$parent . "::$method"}{'CODE'}) {
				# but, if it's the parent's, then we need to only point to the name of the method
				# in the parent's class. This allows the parent to add a wrapper on this method
				# after we do, and we still get it.
				$ptr = "${parent}::$method";
				last;
			}
		}
	}

	#of course, we can't do anything unless our wrapper is something the class can do, or it's an anonymous method
	return $class->error("Cannot add wrapper: Class cannot $wrapper", "BO-35")
		unless $class->can($wrapper) || ref $wrapper eq 'CODE';

	if ($type eq 'before') {

		*{$class . "::$method"} = sub {
			my $self = shift;

			if ($self->$conditional(@_)) {
				$self->$wrapper($ptr, @_) or return;
			}

			return $self->$ptr(@_);

		}
	}
	elsif ($type eq 'after') {
		*{$class . "::$method"} = sub {
			my $self = shift;

			my $rc = $self->$ptr(@_) or return;

			return $self->$conditional(@_) ? $self->$wrapper($ptr, $rc, @_) : $rc;
		}
	} else {
		return $class->error("Cannot add wrapper: unknown type $type", "BO-36");
	}

	return 1;

}

=pod

=begin btest(add_wrapper)

my $subclass = "Basset::Test::Testing::__PACKAGE__::add_wrapper";
my $subclass2 = "Basset::Test::Testing::__PACKAGE__::add_wrapper2";

package Basset::Test::Testing::__PACKAGE__::add_wrapper;
our @ISA = qw(__PACKAGE__);

$subclass->add_attr('attr1');
$subclass->add_attr('attr2');
$subclass->add_attr('before_wrapper');
$subclass->add_attr('before_wrapper2');
$subclass->add_attr('after_wrapper');
$subclass->add_attr('after_wrapper2');
$subclass->add_attr('code_wrapper');

my ($meth1, $meth2, $meth3, $meth4);

sub meth1 {
	my $self = shift;
	$meth1 = shift if @_;
	return $meth1;
}

sub meth2 {
	my $self = shift;
	$meth2 = shift if @_;
	return $meth2;
}

sub meth3 {
	my $self = shift;
	$meth3 = shift if @_;
	return $meth3;
}

sub meth4 {
	my $self = shift;
	$meth4 = shift if @_;
	return $meth4;
}

sub wrapper1 {shift->before_wrapper('set')};

sub wrapper2 {
	$_[0]->before_wrapper('B4SET');
	$_[0]->before_wrapper2('set2');
}

sub wrapper3 {
	$_[0]->before_wrapper('ASET1');
	$_[0]->before_wrapper2('ASET2');
	return $_[2];
}

sub wrapper5 {
	$_[0]->before_wrapper('5-BSET1');
	$_[0]->before_wrapper2('5-BSET2');
	$_[0]->after_wrapper('5-ASET1');
	$_[0]->after_wrapper2('5-ASET2');
}

sub conditional_true {
	return 1;
}

sub conditional_false {
	my $self = shift;
	return $self->error("failed false condition", "conditional_false_error_code");
}

package Basset::Test::Testing::__PACKAGE__::add_wrapper2;
our @ISA = ($subclass);

sub wrapper4 {
	shift->after_wrapper('AWRAPPER');
}

package __PACKAGE__;

$test->ok(! $subclass->add_wrapper, "Cannot add wrapper w/o type");
$test->is($subclass->errcode, "BO-31", "proper error code");

$test->ok(! $subclass->add_wrapper('before'), "Cannot add wrapper w/o attribute");
$test->is($subclass->errcode, "BO-32", "proper error code");

$test->ok(! $subclass->add_wrapper('before', 'bogus_wrapper'), "Cannot add wrapper w/o wrapper");
$test->is($subclass->errcode, "BO-33", "proper error code");

$test->ok(! $subclass->add_wrapper('before', 'bogus_attribute', 'bogus_wrapper'), "Cannot add wrapper: bogus attribute");
$test->is($subclass->errcode, "BO-34", "proper error code");

$test->ok(! $subclass->add_wrapper('before', 'attr2', 'bogus_wrapper'), "Cannot add wrapper: cannot wrapper attributes");
$test->is($subclass->errcode, "BO-39", "proper error code");

$test->ok(! $subclass->add_wrapper('before', 'meth2', 'bogus_wrapper'), "Cannot add wrapper: bogus wrapper");
$test->is($subclass->errcode, "BO-35", "proper error code");

$test->ok(! $subclass->add_wrapper('junk', 'meth2', 'wrapper1'), "Cannot add wrapper: bogus type");
$test->is($subclass->errcode, "BO-36", "proper error code");

$test->ok(scalar $subclass->add_wrapper('before', 'meth1', 'wrapper1'), "added wrapper to ref");

my $o = $subclass->new();
$test->ok($o, "got object");

$test->is($o->before_wrapper, undef, "before_wrapper is undef");
$test->is($o->meth1('foo'), 'foo', 'set meth1 to foo');
$test->is($o->before_wrapper, 'set', 'before_wrapper is set');

$test->is($o->before_wrapper(undef), undef, "before_wrapper is undef");

$test->ok(scalar $subclass->add_wrapper('before', 'meth1', 'wrapper2'), "added wrapper to ref");

$test->is($o->before_wrapper, undef, "before_wrapper is undef");
$test->is($o->meth1('bar'), 'bar', 'set meth1 to baz');
$test->is($o->before_wrapper, 'set', 'before_wrapper is set');
$test->is($o->before_wrapper2, 'set2', 'before_wrapper2 is set2');
$test->is($o->after_wrapper, undef, 'after_wrapper is undef');
$test->is($o->after_wrapper2, undef, 'after_wrapper2 is undef');

$test->is($o->before_wrapper(undef), undef, "before_wrapper is undef");
$test->is($o->before_wrapper2(undef), undef, "before_wrapper2 is undef");

$test->ok(scalar $subclass->add_wrapper('after', 'meth1', 'wrapper3'), "added after wrapper to ref");

$test->is($o->before_wrapper, undef, "before_wrapper is undef");
$test->is($o->meth1('baz'), 'baz', 'set meth1 to baz');
$test->is($o->before_wrapper, 'ASET1', 'before_wrapper is ASET1');
$test->is($o->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');

my $o2 = $subclass2->new();
$test->ok($o2, "got sub object");

$test->ok(scalar $subclass2->add_wrapper('before', 'meth1', 'wrapper4'), "added after wrapper to ref");

$test->is($o2->before_wrapper, undef, "before_wrapper is undef");
$test->is($o2->meth1('baz'), 'baz', 'set meth1 to baz');
$test->is($o2->before_wrapper, 'ASET1', 'before_wrapper is ASET1');
$test->is($o2->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
$test->is($o2->after_wrapper, 'AWRAPPER', 'after_wrapper is AWRAPPER');

$test->is($o->before_wrapper(undef), undef, "before_wrapper is undef");
$test->is($o->before_wrapper2(undef), undef, "before_wrapper2 is undef");
$test->is($o->after_wrapper(undef), undef, "after_wrapper2 is undef");
$test->is($o->after_wrapper2(undef), undef, "after_wrapper2 is undef");

$test->ok(scalar $subclass->add_wrapper('before', 'meth1', 'wrapper5'), "added before wrapper to ref");

$test->is($o->before_wrapper, undef, "before_wrapper is undef");
$test->is($o->meth1('bar'), 'bar', 'set meth1 to baz');
$test->is($o->before_wrapper, 'ASET1', 'before_wrapper is set ASET1');
$test->is($o->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
$test->is($o->after_wrapper, '5-ASET1', 'after_wrapper is 5-ASET1');
$test->is($o->after_wrapper2, '5-ASET2', 'after_wrapper2 is 5-ASET2');

$test->is($o2->before_wrapper(undef), undef, "before_wrapper is undef");
$test->is($o2->before_wrapper2(undef), undef, "before_wrapper2 is undef");
$test->is($o2->after_wrapper(undef), undef, "after_wrapper2 is undef");
$test->is($o2->after_wrapper2(undef), undef, "after_wrapper2 is undef");

$test->is($o2->before_wrapper, undef, "before_wrapper is undef");
$test->is($o2->meth1('bar'), 'bar', 'set meth1 to baz');
$test->is($o2->before_wrapper, 'ASET1', 'before_wrapper is set ASET1');
$test->is($o2->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
$test->is($o2->after_wrapper, '5-ASET1', 'after_wrapper is 5-ASET1');
$test->is($o2->after_wrapper2, '5-ASET2', 'after_wrapper2 is 5-ASET2');

$test->is($o->before_wrapper(undef), undef, "before_wrapper is undef");
$test->is($o->before_wrapper2(undef), undef, "before_wrapper2 is undef");
$test->is($o->after_wrapper(undef), undef, "after_wrapper2 is undef");
$test->is($o->after_wrapper2(undef), undef, "after_wrapper2 is undef");

$test->is($o->before_wrapper, undef, "before_wrapper is undef");
$test->is($o->meth1('bar'), 'bar', 'set meth1 to baz');
$test->is($o->before_wrapper, 'ASET1', 'before_wrapper is set ASET1');
$test->is($o->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
$test->is($o->after_wrapper, '5-ASET1', 'after_wrapper is 5-ASET1');
$test->is($o->after_wrapper2, '5-ASET2', 'after_wrapper2 is 5-ASET2');

$test->ok(scalar $subclass->add_wrapper('before', 'meth1', sub {$_[0]->code_wrapper('SET CODE WRAP'); return 1}), 'added coderef wrapper');
$test->is($o->meth1('code'), 'code', 'set meth1 to code');
$test->is($o->code_wrapper, 'SET CODE WRAP', 'properly used coderef wrapper');

$test->ok(scalar $subclass->add_wrapper('before', 'meth3', 'wrapper1', 'conditional_true'), "added conditional_true wrapper");
$test->is($o->before_wrapper(undef), undef, "wiped out before_wrapper");
$test->is($o->meth3('meth 3 val'), 'meth 3 val', 'properly set method 3 value');
$test->is($o->before_wrapper, 'set', 'set before_wrapper');

$test->ok(scalar $subclass->add_wrapper('before', 'meth4', 'wrapper1', 'conditional_false'), "added conditional_false wrapper");
$test->is($o->before_wrapper(undef), undef, "wiped out before_wrapper");
$test->is($o->meth4('meth 4 val'), 'meth 4 val', 'could not set method 4 value');
$test->is($o->errcode, 'conditional_false_error_code', 'proper error code');
$test->is($o->before_wrapper, undef, 'could not set before_wrapper');

=end btest(add_wrapper)

=cut

=pod

=item error and errcode

error rocks. All error reporting is set and relayed through error. It's a standard accessor, and an *almost*
standard mutator. The difference is that when used as a mutator, it returns undef instead of the value
mutated to.

If a method fails, it is expected to return undef and set error.

example:

 sub someMethod {
 	my $self = shift;
 	my $value = shift;

 	if ($value > 10){
 		return 1;		#success
 	}
 	else {
 		return $self->error("Values must be greater than 10");
 	};
 };

 $object->someMethod(15) || die $object->error;	#succeeds
 $object->someMethod(5)	 || die $object->error;	#dies with an error..."Values must be greater than 10"

Be warned if your method can return '0', this is a valid successful return and shouldn't give an error.
But most of the time, you're fine with "true is success, false is failure"

As you can see in the example, we mutate the error attribute to the value passed, but it returns undef.

However, error messages can change and can be difficult to parse. So we also have an error code, accessed
by errcode. This is expected to be consistent and machine parseable. It is mutated by the second argument
to ->error

example:

 sub someMethod {
 	my $self = shift;
 	my $value = shift;

 	if ($value > 10){
 		return 1;		#success
 	}
 	else {
 		return $self->error("Values must be greater than 10", "ERR77");
 	};
 };

 $object->someMethod(15) || die $object->error;		#succeeds
 $object->someMethod(5)	 || die $object->errcode;	#dies with an error code ... "ERR77"

If your code is looking for an error, read the errcode. if a human is looking at it, display the error.
Easy as pie.

Both classes and objects have error methods.

 my $obj = Some::Class->new() || die Some::Class->error();
 $obj->foo() || die $obj->error();

Note that error is a special method, and not just a normal accessor or class attribute. As such:

 my $obj = Some::Class->new();
 Some::Class->error('foo');
 print $obj->error();			#prints undef
 print Some::Class->error();	#prints foo

i.e., you will B<not> get a class error message by calling ->error on an object.

error also posts an 'error' notification to the notification center. See Basset::NotificationCenter for more information.
The notification will not be posted if the optional third "silently" parameter is passed.

 Some::Class->error('foo', 'foo_code', 'silently'); 

->error can (and will) die if an error occurs very very early in the compilation process, namely if an error
occurs before the 'exceptions' attribute is defined. It is assumed that if an error occurs that early on, it's a very
bad thing, and you should bail out.

You may also always cause an exception by passing in the double plus secret fourth parameter - "throw anyway".

 Some::Class->error('foo', 'foo_code', 0, 'HOLY COW BAIL OUT NOW!');

Use the throw anyway parameter with care. It should be reserved to cover coding errors. An issue that if it occurs, there
is no way to continue and the programmer needs to fix it in advance. For example, _accessor throws an exception if you
try to call it as a class method, and with good reason.

=cut

=pod

=begin btest(error)

my $notes = 0;

sub notifier {
	my $self = shift;
	my $note = shift;
	$notes++;
};

my $center = __PACKAGE__->pkg_for_type('notificationcenter');
$test->ok($center, "Got notification center class");

$test->ok(
	scalar
	$center->addObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'error',
		'object' => 'all',
		'method' => 'notifier'
	), "Added observer for error notifications"
);

my $o = __PACKAGE__->new();
$test->ok($o, "Object created");

$test->is(scalar __PACKAGE__->error("classerr"), undef, "Class error set and returns undef");
$test->is($notes, 1, "Posted a notification");
$test->is(scalar __PACKAGE__->error(), 'classerr', "Class error accesses");
$test->is($notes, 1, "No notification");

$test->is(scalar __PACKAGE__->error("classerr2", "classcode2"), undef, "Class error and errcode set and returns undef");
$test->is($notes, 2, "Posted a notification");
$test->is(scalar __PACKAGE__->error(), 'classerr2', "Class error accesses");
$test->is($notes, 2, "No notification");
$test->is(scalar __PACKAGE__->errcode(), 'classcode2', "Class Class errcode accesses");
$test->is($notes, 2, "No notification");

$test->is(scalar $o->error("objerr"), undef, "Object error set and returns undef");
$test->is($notes, 3, "Posted a notification");
$test->is(scalar $o->error(), 'objerr', "Object error accesses");
$test->is($notes, 3, "No notification");
$test->is(scalar __PACKAGE__->error(), 'classerr2', "Class error unaffected");
$test->is($notes, 3, "No notification");

$test->is(scalar $o->error("objerr2", "objcode2"), undef, "Object error and errcode set and returns undef");
$test->is($notes, 4, "Posted a notification");
$test->is(scalar $o->error(), 'objerr2', "Object error accesses");
$test->is($notes, 4, "No notification");
$test->is(scalar $o->errcode(), 'objcode2', "Object errcode accesses");
$test->is($notes, 4, "No notification");
$test->is(scalar __PACKAGE__->error(), 'classerr2', "Class error unaffected");
$test->is($notes, 4, "No notification");
$test->is(scalar __PACKAGE__->errcode(), 'classcode2', "Class errcode unaffected");
$test->is($notes, 4, "No notification");

$test->is(scalar __PACKAGE__->error("classerr3", "clscode3"), undef, "Re-set class error");
$test->is($notes, 5, "Posted notification");
$test->is(scalar $o->error(), 'objerr2', "Object error unchanged");
$test->is($notes, 5, "No notification");
$test->is(scalar $o->errcode(), 'objcode2', "Object errcode unchanged");
$test->is($notes, 5, "No notification");

$test->is(scalar $o->error("objerr3", "objcode3", "silently"), undef, "Silently set error");
$test->is($notes, 5, "No notification");
$test->is(scalar $o->error(), 'objerr3', "Object error accesses");
$test->is($notes, 5, "No notification");
$test->is(scalar $o->errcode(), 'objcode3', "Object errcode accesses");
$test->is($notes, 5, "No notification");
$test->is(scalar __PACKAGE__->error(), 'classerr3', "Class error unaffected");
$test->is($notes, 5, "No notification");
$test->is(scalar __PACKAGE__->errcode(), 'clscode3', "Class errcode unaffected");
$test->is($notes, 5, "No notification");

$test->is(scalar $o->error(["formatted error %d %.2f %s", 13, 3.14, "data"], "ec", "silently"), undef, "Object set formatted error");
$test->is(scalar $o->error, "formatted error 13 3.14 data", "Formatted error accesses");
$test->is(scalar $o->errcode, "ec", "Formatted errcode accesses");
$test->is(scalar __PACKAGE__->error(), 'classerr3', "Class error unaffected");
$test->is($notes, 5, "No notification");
$test->is(scalar __PACKAGE__->errcode(), 'clscode3', "Class errcode unaffected");
$test->is($notes, 5, "No notification");

my $confClass = __PACKAGE__->pkg_for_type('conf');
$test->ok($confClass, "Got conf");

my $cfg = $confClass->conf;
$test->ok($cfg, "Got configuration");

$test->ok($cfg->{"Basset::Object"}->{'exceptions'} = 1, "enables exceptions");

eval {
	$o->error("exception error", "excpcode");
};
$test->ok($@ =~ /^excpcode /, "Caught object exception code");
$test->is($o->last_exception, "exception error", "Caught object exception");
$test->is(__PACKAGE__->last_exception, "exception error", "Caught class exception");
$test->is($notes, 6, "Posted a notification");

eval {
	__PACKAGE__->error("exception error 2", "excpcode2");
};

$test->ok($@ =~ /^excpcode2 /, "Caught object exception code2");
$test->is($o->last_exception, "exception error 2", "Caught object exception");
$test->is(__PACKAGE__->last_exception, "exception error 2", "Caught class exception");
$test->is($notes, 7, "Posted a notification");

eval {
	__PACKAGE__->error("exception error 3", "excpcode3", "silently");
};
$test->ok($@ =~ /^excpcode3/, "Caught object exception code3");
$test->is($o->last_exception, "exception error 3", "Caught object exception");
$test->is(__PACKAGE__->last_exception, "exception error 3", "Caught class exception");
$test->is($notes, 7, "No notification");

$test->is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0,"shut off exceptions");

$test->ok(
	scalar
	$center->removeObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'error',
	), "Removed observer for error notifications"
);

package Basset::Test::Testing::__PACKAGE__::error::Subclass1;
our @ISA = qw(__PACKAGE__);

sub can {
	my $self = shift;
	my $method = shift;
	return 0 if $method =~ /_..._error/;
	return $self->SUPER::can($method);
};

package __PACKAGE__;
{
	local $@ = undef;

	eval {
		Basset::Test::Testing::__PACKAGE__::error::Subclass1->error("some error");
	};
	$test->like($@, qr/^System start up failure/, 'Could not start system when cannot error');
}

package Basset::Test::Testing::__PACKAGE__::error::Subclass2;
our @ISA = qw(__PACKAGE__);

sub can {
	my $self = shift;
	my $method = shift;
	return 0 if $method =~ /_..._errcode/;
	return $self->SUPER::can($method);
};

package __PACKAGE__;

{
	local $@ = undef;

	eval {
		Basset::Test::Testing::__PACKAGE__::error::Subclass2->error("some error");
	};

	$test->like($@, qr/^System start up failure/, 'Could not start system when cannot errcode');

	$test->is(scalar(Basset::Test::Testing::__PACKAGE__::error::Subclass2->error), undef, 'accessing error merely returns');

}

=end btest(error)

=cut

sub error {
	my $self		= shift;

	my $errormethod	= ref $self	? "_obj_error"		: "_pkg_error";
	my $codemethod	= ref $self	? "_obj_errcode"	: "_pkg_errcode";

	# just in case we have an error very early on, we have our escape pod here. If something bad has happened,
	# then just die. We cannot continue.
	unless ($self->can($errormethod) && $self->can($codemethod)) {
		if (@_) {
			croak("System start up failure : @_");
		} else {
			return;
		}
	}

	if (@_){

		$self->$errormethod(shift);
		$self->$codemethod(@_ ? shift : undef);

		if (defined $self->$errormethod()) {

			my $center = $self->pkg_for_type('notificationcenter', 'errorless');

			my $silently		= shift || 0;
			my $throw_anyway	= shift || 0;
			unless ($silently) {
				if (defined $center && $center->can('postNotification')) {
					$center->postNotification(
						'notification'	=> 'error',
						'object'		=> $self,
						'args'			=> [$self->errvals],
					);
				}
			}

			if ($self->can('exceptions') || $throw_anyway) {
				if ($self->exceptions && defined $self->$codemethod()) {
					$self->last_exception($self->$errormethod());
					croak($self->$codemethod());
				};
			#something went horribly wrong very early on. Die with something useful.
			} else {
				die $self->errstring;
			};
		}

		return;
	}
	else {
		my $err = $self->$errormethod();
		if (defined $err && ref $err eq 'ARRAY') {
			my $format = $err->[0];
			if (@$err > 1) {
				$err = sprintf($format, @{$err}[1..$#$err]);
			} else {
				$err = $format;
			};
		}
		return $err;
		#return $self->$errormethod();
	};
};

=pod

=item rawerror

If you're using a formatted error string, ->error will always return the formatted value to you. 
->rawerror will return the formattable data.

 $obj->error('foo');
 print $obj->error(); #prints 'foo'
 print $obj->rawerror(); #prints 'foo'

 $obj->error(['foo %d', 77]);
 print $obj->error(); #prints 'foo 77'
 print $obj->rawerror(); #prints ARRAY0x1341 (etc.)

=cut

=pod

=begin btest(rawerror)

my $o = __PACKAGE__->new();
$test->ok($o, "Object created");

$test->is(scalar __PACKAGE__->error("raw class error", "roe"), undef, "Set class error");
$test->is(scalar __PACKAGE__->rawerror(), "raw class error", "Class raw error accesses");
$test->is(scalar __PACKAGE__->error(["raw class error %d"], "roe"), undef, "Set formatted class error");
$test->is(ref __PACKAGE__->rawerror(), 'ARRAY', "Class formatted raw error accesses");
$test->is(__PACKAGE__->rawerror()->[0], "raw class error %d", "Class formatted raw error accesses");

$test->is(scalar $o->error("raw object error", "roe"), undef, "Set object error");
$test->is(scalar $o->rawerror(), "raw object error", "Object raw error accesses");
$test->is(scalar $o->error(["raw object error %d"], "roe"), undef, "Set formatted object error");
$test->is(ref $o->rawerror(), 'ARRAY', "Object formatted raw error accesses");
$test->is($o->rawerror()->[0], 'raw object error %d', "Object formatted raw error accesses");
$test->ok(ref $o->rawerror() eq 'ARRAY', "Class formatted raw error unaffected");
$test->is(__PACKAGE__->rawerror()->[0], "raw class error %d", "Class formatted raw error unaffected");

=end btest(rawerror)

=cut

sub rawerror {
	my $self = shift;
	my $errormethod	= ref $self	? "_obj_error"		: "_pkg_error";

	return $self->$errormethod();
}

=pod

=item errcode

errcode is an accessor ONLY. You can only mutate the errcode via error, see above.

 print $obj->errcode;

Both objects and classes have errcode methods.

 my $obj = Some::Class->new() || die Some::Class->errcode();
 $obj->foo() || die $obj->errcode

Do not ever ever B<ever> define an error code that starts with "B". Those are reserved for framework
error codes. Otherwise, standard C-style "namespace" conventions apply - give it a reasonably unique
prefix. Preferrably one that helps people identify where the error was. I like to use the the initials
of the module name.

 package Basset::Object::Persistent;  #returns BOP-## error codes.

=cut

=pod

=begin btest(errcode)

$test->is(scalar __PACKAGE__->error("test error", "test code", "silently"), undef, "Class sets errcode");
$test->is(scalar __PACKAGE__->errcode(), "test code", "Class accesses");

=end btest(errcode)

=cut

sub errcode {
	my $self	= shift;
	my $method	= ref $self ? "_obj_errcode"		: "_pkg_errcode";

	return $self->$method(@_);
};

=pod

=item errstring

errstring is a convenience accessor, it returns the error and code concatenated.

$obj->someMethod() || die $obj->errstring; #dies "Values must be greater than 10...with code(ERR77)"

=cut

=pod

=begin btest(errstring)

$test->is(scalar __PACKAGE__->error("test error", "test code"), undef, "Class sets error & errcode");
$test->is(__PACKAGE__->errstring(), "test error...with code (test code)", "Class accesses errstring");

$test->is(scalar __PACKAGE__->error("test error2", "test code2", "silently"), undef, "Class silently sets error & errcode");
$test->is(__PACKAGE__->errstring(), "test error2...with code (test code2)", "Class accesses errstring");

$test->is(scalar __PACKAGE__->error("test error3"), undef, "Class sets error & no errcode");
$test->is(__PACKAGE__->errstring(), "test error3...with code (code undefined)", "Class accesses errstring");

$test->is(scalar __PACKAGE__->error("test error4", undef, "silently"), undef, "Class silently sets error & no errcode");
$test->is(__PACKAGE__->errstring(), "test error4...with code (code undefined)", "Class accesses errstring");

__PACKAGE__->wipe_errors();

$test->is(scalar(__PACKAGE__->errstring), undef, 'errcode returns nothing w/o error and errcode');
__PACKAGE__->errcode('test code');
$test->is(__PACKAGE__->errstring, 'error undefined...with code (test code)', 'errcode returns undefined w/o error');

=end btest(errstring)

=cut

sub errstring {
	my $self = shift;

	if (defined $self->error) {
		return
			$self->error
			 . "...with code (" .
			 (defined $self->errcode ? $self->errcode : 'code undefined')
			 . ")";
	} elsif (defined $self->errcode) {
		return 'error undefined...with code (' . $self->errcode . ')';
	} else {
		return;
	};
};

=pod

=item errvals

similar to errstring, but returns the error and errcode in an array. This is great for bubbling
up error messages. Note that errvals will also include the extra 'silently' parameter to prevent
bubbled errors from posting notifications.

 $attribute = $obj->foo() or return $self->error($obj->errvals);

=cut

=pod

=begin btest(errvals)

my $notes = 0;

sub notifier2 {
	my $self = shift;
	my $note = shift;
	$notes++;
};

my $center = __PACKAGE__->pkg_for_type('notificationcenter');
$test->ok($center, "Got notification center class");

$test->ok(
	scalar
	$center->addObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'error',
		'object' => 'all',
		'method' => 'notifier2'
	), "Added observer for error notifications"
);

my $o = __PACKAGE__->new();
$test->ok($o, "Object created");

$test->is(scalar $o->error("test error", "test code"), undef, "Object set error");
$test->is($notes, 1, "Posted notification");

my @errvals = $o->errvals;
$test->is($notes, 1, "No notification");
$test->is($errvals[0], "test error", "Object accesses error");
$test->is($notes, 1, "No notification");
$test->is($errvals[1], "test code", "Object accesses error");
$test->is($notes, 1, "No notification");
$test->is($errvals[2], "silently", "errvals always silent");
$test->is($notes, 1, "No notification");

$test->ok(
	scalar
	$center->removeObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'error',
	), "Removed observer for error notifications"
);

=end btest(errvals)

=cut

sub errvals {
	my $self = shift;

	return ($self->error, $self->errcode, 'silently');

};

=pod

=item usererror

errors are great, but they can be a bit cryptic. usererror takes the last error message
and re-formats it into a more end user friendly syntax. If there's no way to re-format it, it
just returns the actual error.

Alternatively, you can also use the error translator to change an error code into something
more user friendly

See "errortranslator", below, for more info.

=cut

=pod

=begin btest(usererror)

my $translator = __PACKAGE__->errortranslator();
$test->ok(
	scalar
	__PACKAGE__->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2'
	}),
	'Class set error translator'
);

my $uses_real = __PACKAGE__->use_real_errors();
$test->is(__PACKAGE__->use_real_errors(0), 0, "Uses real errors");

$test->is(scalar __PACKAGE__->error("extra error", "test code"), undef, "Class sets error");
$test->is(__PACKAGE__->usererror(), "friendliest test message 2", "Class gets user error for literal");

$test->is(scalar __PACKAGE__->error(["formatted test error %d", 7], "test code"), undef, "Class sets formatted error");
$test->is(__PACKAGE__->usererror(), "friendliest test message", "Class gets user error for formatted string");

$test->is(scalar __PACKAGE__->error(["formatted test error %d", 9], "test code"), undef, "Class sets formatted error");
$test->is(__PACKAGE__->usererror(), "friendlier test message", "Class gets user error for string format");

$test->is(scalar __PACKAGE__->error("Some test error", "test code"), undef, "Class sets standard error");
$test->is(__PACKAGE__->usererror(), "friendly test message", "Class gets user error for error code");

$test->is(scalar __PACKAGE__->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
$test->is(__PACKAGE__->usererror(), "Some unknown error", "Class gets no user error");

$test->ok(
	scalar
	__PACKAGE__->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2',
		'*' => 'star error',
	}),
	'Class changed error translator'
);

$test->is(scalar __PACKAGE__->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
$test->is(__PACKAGE__->usererror(), "star error", "Class gets star error");

$test->is(__PACKAGE__->errortranslator($translator), $translator, 'Class reset error translator');
$test->is(__PACKAGE__->use_real_errors($uses_real), $uses_real, "resets uses real errors");

=end btest(usererror)

=cut

sub usererror {
	my $self = shift;

	return $self->errstring if $self->use_real_errors;

	my $usererror;
	my $rawerror = $self->rawerror;
	my $error;

	if (ref $rawerror) {
		$error = $rawerror->[0];
	} else {
		#the variable name doesn't make sense here, but hey, we'll recycle it.
		$error = $rawerror;
	}

	if (defined $self->errortranslator && defined $self->error && exists $self->errortranslator->{$self->error}) {
		$usererror = $self->errortranslator->{$self->error};
	}
	elsif (defined $self->errortranslator && defined $error && exists $self->errortranslator->{$error}) {
		$usererror = $self->errortranslator->{$error};
	} 
	elsif (defined $self->errortranslator && defined $self->errcode && exists $self->errortranslator->{$self->errcode}) {
		$usererror = $self->errortranslator->{$self->errcode};
	}
	elsif (defined $self->errortranslator && exists $self->errortranslator->{'*'}) {
		$usererror = $self->errortranslator->{'*'};
	}
	else {
		$usererror = $error;
	}

	if (ref $rawerror) {
		return sprintf($usererror, @{$rawerror}[1..$#$rawerror]);
	} else {
		return $usererror;
	}

};

=pod

=item wipe_errors

Wipes out the current error message and error code.

=cut

=pod

=begin btest(wipe_errors)

$test->is(scalar __PACKAGE__->error("test error", "error code"), undef, "Class set error and errcode");
$test->is(__PACKAGE__->error(), "test error", "Class accesses error");
$test->is(__PACKAGE__->errcode(), "error code", "Class accesses errcode");
$test->ok(scalar __PACKAGE__->wipe_errors(), "Class wiped errors");
$test->is(scalar __PACKAGE__->error(), undef, "Class error wiped out");
$test->is(scalar __PACKAGE__->errcode(), undef, "Class errcode wiped out");

my $confClass = __PACKAGE__->pkg_for_type('conf');
$test->ok($confClass, "Got conf");

my $cfg = $confClass->conf;
$test->ok($cfg, "Got configuration");

$test->ok($cfg->{"Basset::Object"}->{'exceptions'} = 1, "enables exceptions");

eval {
	__PACKAGE__->error("test exception", "test exception code");
};
$test->ok($@, "Caught exception");
$test->like($@, qr/test exception code/, "Exception matches");
$test->like(__PACKAGE__->last_exception, qr/test exception/, "Exception is present");
$test->ok(scalar __PACKAGE__->wipe_errors(), "Class wiped errors");
$test->is(__PACKAGE__->last_exception, undef, "last exception wiped out");
$test->is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0,"disables exceptions");

=end btest(wipe_errors)

=cut

sub wipe_errors {
	my $self = shift;

	$self->error(undef);
	$self->errcode(undef);
	$self->last_exception(undef) if $self->can('exceptions');

	return 1;
};

=pod

=item notify

Used for non-fatal messages, usually an error message that shouldn't cause things to abort. Expects at least one argument,
the notification being posted. Additional arguments will be passed through to any handlers.

 sub lockThing {
 	my $self = shift;
 	my $thing = shift;

 	if ($thing->locked) {
 		$self->notify("info", "Cannot lock - thing is already locked");
 	} else {
 		$thing->lock();
 	};

 	return 1;
 }

In this example, we have a method called "lockThing" that locks a thing (whatever that means). But it only locks the thing
if it is not already locked. If it is locked, it sends an informational message that the thing is already locked. But that's not
fatal - we still end up with a locked thing, so we're happy no matter what. No need to kick back an error.

notify is a wrapper around the notification center.

 $obj->notify('foo') == Basset::NotificationCenter->postNotification('object' => $obj, 'notification' => 'foo');

=cut

=pod

=begin btest(notify)

my $test1notes = undef;
my $test2notes = undef;

sub test1notifier {
	my $self = shift;
	my $note = shift;
	$test1notes = $note->{'args'}->[0];
};

sub test2notifier {
	my $self = shift;
	my $note = shift;
	$test2notes = $note->{'args'}->[0];
};

my $center = __PACKAGE__->pkg_for_type('notificationcenter');
$test->ok($center, "Got notification center class");

$test->ok(
	scalar
	$center->addObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'test1',
		'object' => 'all',
		'method' => 'test1notifier'
	), "Added observer for test1 notifications"
);

$test->ok(
	scalar
	$center->addObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'test2',
		'object' => 'all',
		'method' => 'test2notifier'
	), "Added observer for test2 notifications"
);

my $o = __PACKAGE__->new();
$test->ok($o, "Object created");

$test->ok(scalar __PACKAGE__->notify('test1', "Test 1 note 1"), "Class posted notification");
$test->is($test1notes, "Test 1 note 1", "Received note");
$test->is($test2notes, undef, "No note for test 2");

$test->ok(scalar __PACKAGE__->notify('test2', "Test 2 note 2"), "Class posted notification");
$test->is($test2notes, "Test 2 note 2", "Received note");
$test->is($test1notes, "Test 1 note 1", "Test 1 note unchanged");

$test->ok(
	scalar
	$center->removeObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'test1',
	), "Removed observer for test1 notifications"
);

$test->ok(
	scalar
	$center->addObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'test1',
		'object' => $o,
		'method' => 'test1notifier'
	), "Added specific observer for test1 notifications"
);

$test->ok(scalar __PACKAGE__->notify('test1', 'Test 1 note 2'), "Class posted notification");
$test->is($test1notes, "Test 1 note 1", "Test 1 note unchanged");
$test->is($test2notes, "Test 2 note 2", "Test 2 note unchanged");

$test->ok(scalar $o->notify('test1', 'Test 1 note 3'), "Object posted notification");
$test->is($test1notes, "Test 1 note 3", "Recieved note");

$test->is($test2notes, "Test 2 note 2", "Test 2 note unchanged");

$test->ok(
	scalar
	$center->removeObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'test1',
	), "Removed observer for test1 notifications"
);

$test->ok(
	scalar
	$center->removeObserver(
		'observer' => '__PACKAGE__',
		'notification'	=> 'test2',
	), "Removed observer for test2 notifications"
);

=end btest(notify)

=cut

sub notify {
	my $self = shift;
	my $notification = shift;

	my $center = $self->pkg_for_type('notificationcenter');

	if (defined $center && $center->can('postNotification')) {
		$center->postNotification(
			'notification' => $notification,
			'object' => $self,
			'args' => [@_],
		);
	}

	return 1;
};

=pod

=item add_restrictions

Class method. Expects a hash of arrayrefs, listing permissions and method re-maps.

 Some::Package->add_restrictions(
 	'readonly' => [
 		'commit'	=> 'failed_restricted_method',
 		'write'		=> 'failed_restricted_method',
 	],
 	'writeonly' => [
 		'load'		=> 'failed_restricted_method',
 	],
 	'subuser'	=> [
 		'commit'	=> 'validating_commit'
 	]
 );

We require a hash of arrayrefs so that we can guarantee the order in which the methods will be
re-mapped.

This specifies that Some::Package can be restricted in several ways, with a 'readonly' restriction,
a 'writeonly' restriction, and a 'subuser' restriction. If the package is restricted, then the methods
are re-mapped as defined. i.e., if the 'readonly' restriction is in place, then calling 'commit'
actually calls "failed_restricted_method" Add restrictions by calling either add_restricted_method
or (better!) by calling restrict.

 my $inline_class = Some::Package->restrict('readonly');

 my $o = Some::Package->new();
 $o->commit() || die $o->errstring; #succeeds!

 my $o2 = $inline_class->new();
 $o2->commit() || die $o2->errstring; #fails. access to commit is restricted.

see add_restricted_method and restrict, below.

=cut

=pod

=begin btest(add_restrictions)

package Basset::Test::Testing::__PACKAGE__::add_restrictions::Subclass1;
our @ISA = qw(__PACKAGE__);

my %restrictions = (
	'specialerror' => [
		'error' => 'error2',
		'errcode' => 'errcode2'
	],
	'invalidrestriction' => [
		'junkymethod' => 'otherjunkymethod'
	]
);

$test->ok(scalar Basset::Test::Testing::__PACKAGE__::add_restrictions::Subclass1->add_restrictions(%restrictions), "Added restrictions to subclass");

=end btest(add_restrictions)

=cut

sub add_restrictions {
	my $self = shift;
	my %newrestrictions = @_ or return $self->error("Cannot add restriction w/o restrictions", "BO-17");

	my $restrictions = $self->restrictions();

#	@$restrictions{keys %newrestrictions} = values %newrestrictions;

       #this is a nuisance. We're here, so we know that we're adding restrictions.
       #if there's already a restrictions hash, we need to duplicate it here. See the
       #docs for add_trickle_class_attr above for more info on dealing with trickled class attributes
       #that contain references
       if ($restrictions) {
               my $val = $self->dump($restrictions);
               $val =~ /^(\$\w+)/;
               local $@ = undef;
               $restrictions = eval qq{
                       my $1;
                       eval \$val;
               };
       }
       #otherwise, we create a new hash
       else {
               $restrictions = {};
       };

        @$restrictions{keys %newrestrictions} = values %newrestrictions;

       #finally, we can properly set the new hash because we're guaranteed that it's always a copy
       #that we want to operate on.
       $self->restrictions($restrictions);

	return 1;
}

=pod

=item add_restricted_method

Given a restriction and a method, restricts only that method to that restriction.

 Some::Package->add_restricted_method('writeonly', 'commit');

This applies the writeonly restriction to the commit method (as defined above in the add_restrictions
pod). Note that this does not apply the restriction to the 'write' method, only to 'commit'.

You will rarely (if ever) use this method, use 'restrict' instead.

=cut

=begin btest(add_restricted_method)

package Basset::Test::Testing::__PACKAGE__::add_restricted_method::Subclass1;
our @ISA = qw(__PACKAGE__);

my %restrictions = (
	'specialerror' => [
		'error' => 'error2',
		'errcode' => 'errcode2'
	],
	'invalidrestriction' => [
		'junkymethod' => 'otherjunkymethod'
	]
);

__PACKAGE__->add_class_attr('e2');
__PACKAGE__->add_class_attr('c2');

$test->is(__PACKAGE__->e2(0), 0, "set e2 to 0");
$test->is(__PACKAGE__->c2(0), 0, "set c2 to 0");

sub error2 {
	my $self = shift;
	$self->e2($self->e2 + 1);
	return $self->SUPER::error(@_);
}

sub errcode2 {
	my $self = shift;
	$self->c2($self->c2 + 1);
	return $self->SUPER::errcode(@_);
}

$test->ok(scalar Basset::Test::Testing::__PACKAGE__::add_restricted_method::Subclass1->add_restrictions(%restrictions), "Added restrictions to subclass");

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::add_restricted_method::Subclass1->isa('__PACKAGE__'), 'Proper subclass');

my $subclass = Basset::Test::Testing::__PACKAGE__::add_restricted_method::Subclass1->inline_class();
$test->ok(scalar $subclass, "Got restricted class");
$test->ok($subclass->restricted, "Subclass is restricted");
$test->ok(scalar $subclass->isa('Basset::Test::Testing::__PACKAGE__::add_restricted_method::Subclass1'), "Is subclass");
$test->ok(scalar $subclass->isa('__PACKAGE__'), "Is subclass");

$test->ok(scalar $subclass->add_restricted_method('specialerror', 'error'), "Restricted error");
$test->ok(scalar $subclass->add_restricted_method('specialerror', 'errcode'), "Restricted errcode");
$test->ok(! scalar $subclass->add_restricted_method('invalidrestriction', 'junkymethod'), "Could not add invalid restriction");

$test->ok(! scalar $subclass->add_restricted_method('specialerror', 'error2'), "Could not add invalid restricted method");
$test->ok(! scalar $subclass->add_restricted_method('specialerror', 'errcode2'), "Could not add invalid restricted method");
$test->ok(! scalar $subclass->add_restricted_method('specialerror', 'junkymethod2'), "Could not add invalid restricted method");

my $e2 = $subclass->e2;
my $c2 = $subclass->c2;

#we post silently or else error and errcode would be called when it posts the error notification.
$test->is(scalar $subclass->error("test error", "test code", "silently"), undef, "Set error for subclass");

$test->is($subclass->e2, $e2 + 1, "Subclass restricted error incremented");
$test->is($subclass->c2, $c2, "Subclass restricted errcode unchanged");
$test->is($subclass->error(), "test error", "Subclass accesses error method");
$test->is($subclass->e2, $e2 + 2, "Subclass restricted error incremented");
$test->is($subclass->c2, $c2, "Subclass restricted errcode unchanged");
$test->is($subclass->errcode(), "test code", "Subclass accesses errcode method");
$test->is($subclass->e2, $e2 + 2, "Subclass restricted error unchanged");
$test->is($subclass->c2, $c2 + 1, "Subclass restricted errcode incremented");

$test->is(scalar Basset::Test::Testing::__PACKAGE__::add_restricted_method::Subclass1->error("super test error", "super test code", "silently"), undef, "Superclass sets error");
$test->is($subclass->e2, $e2 + 2, "Subclass restricted error unchanged");
$test->is($subclass->c2, $c2 + 1, "Subclass restricted errcode unchanged");

=end btest(add_restricted_method)

=cut

sub add_restricted_method {
	my $pkg			= shift;
	my $restriction	= shift;
	my $method		= shift;

	my $restrictions = $pkg->restrictions;

	my $restriction_set = $restrictions->{$restriction};

	my $restricted_method = undef;

	if (defined $restriction_set) {
		my $map = {@$restriction_set};

		$restricted_method = $map->{$method}
			or return $pkg->error("No method for restriction ($restriction) on method ($method)", "BO-14");

	} else {
		return $pkg->error("Cannot add restricted method ($method) w/o restriction set ($restriction)", "BO-19");
	};

#	my $restricted_method = $restrictions->{$restriction}->{$method}
#		or return $pkg->error("No method for restriction ($restriction) on method ($method)", "BO-14");

	no strict 'refs';

	if (ref $restricted_method eq 'CODE') {
		*{$pkg . "::$method"} = $restricted_method;
		return $method;
	};

	my $parents = $pkg->isa_path;

	#remember the isa path is most distant -> closest. Here we want to look at the closest
	#ancestor that is not restricted.
	#
	#We march up the tree. Once we find a parent (or ourselves) that can perform the method
	#we're looking for, we stop and are happy.
	foreach my $parent (reverse @$parents) {

		my $code = *{$parent . '::' . $restricted_method}{'CODE'};
		if (defined $code ) {
			*{$pkg . "::$method"} = $code;
			return $method;
			last;
		};
	};

	return $pkg->error("could not restrict method - no super class defines $restricted_method", "BO-15");
};

=pod

=item failed_restricted_method

Simple convenience method. Always fails with a known error and errorcode - "Access to this method is
restricted", "BO-16"

=cut

=pod

=begin btest(failed_restricted_method)

package Basset::Test::Testing::__PACKAGE__::failed_restricted_method::Subclass2;
our @ISA = qw(__PACKAGE__);

sub successful {
	return 1;
};

my %restrictions = (
	'failure' => [
		'successful' => 'failed_restricted_method',
	],
);

package __PACKAGE__;

my $subclass = Basset::Test::Testing::__PACKAGE__::failed_restricted_method::Subclass2->inline_class;
$test->ok($subclass, "Got restricted subclass");
$test->ok(scalar $subclass->restricted, "Subclass is restricted");
$test->ok(scalar $subclass->add_restrictions(%restrictions), "Subclass added restrictions");

$test->ok(! scalar __PACKAGE__->failed_restricted_method, "Failed restricted method always fails");
$test->ok(! scalar Basset::Test::Testing::__PACKAGE__::failed_restricted_method::Subclass2->failed_restricted_method, "Failed restricted method always fails");
$test->ok(! scalar $subclass->failed_restricted_method, "Failed restricted method always fails");

$test->ok(scalar Basset::Test::Testing::__PACKAGE__::failed_restricted_method::Subclass2->successful, "Super Success is successful");
$test->ok(scalar $subclass->successful, "Subclass success is successful");
$test->ok(scalar $subclass->add_restricted_method('failure', 'successful'), "Restricted subclass to fail upon success");
$test->ok(scalar Basset::Test::Testing::__PACKAGE__::failed_restricted_method::Subclass2->successful, "Super Success is successful");
$test->ok(! scalar $subclass->successful, "Subclass success fails");

=end btest(failed_restricted_method)

=cut

sub failed_restricted_method {
	return shift->error("Access to this method is restricted", "BO-16");
};

=pod

=item inline_class

Another internal method that you will rarely, if ever call. 

 my $inline_class = Some::Package->inline_class();

This creates a new class, which is a subclass of Some::Package. The only difference is that
it has its restricted flag turned on. To apply restrictions, use the restrict method instead.

=cut

=pod

=begin btest(inline_class)

my $class = __PACKAGE__->inline_class();
$test->ok($class, "Got restricted class");
$test->ok($class->restricted(), "Class is restricted");
$test->ok(! __PACKAGE__->restricted(), "Superclass is not restricted");

=end btest(inline_class)

=cut

our $restrict_counter	= 0;
our %inlined = ();

sub inline_class {
	my $pkg = shift;

	no strict 'refs';
	my $class = $pkg . '::BASSETINLINE::R' . $restrict_counter++;
	@{$class . "::ISA"} = ($pkg);
	$class->restricted(1);

	$inlined{$class}++;

	return $class;
};

sub load_pkg {
	my $class = shift;

	my $newclass = shift or return $class->error("Cannot load_pkg w/o class", "BO-28");
	my $errorless = shift || 0;

	local $@ = undef;
	eval "use $newclass" unless $inlined{$newclass} || $INC{$class->module_for_class($newclass)};

	if ($@) {
		return $errorless ? undef : $class->error("Cannot load class ($newclass) : $@", "BO-29");
	}

	return $newclass;
}

=pod

=begin btest(load_pkg)

my $iclass = __PACKAGE__->inline_class;
$test->ok(scalar __PACKAGE__->load_pkg($iclass), "Can load inline class");

=end btest(load_pkg)

=cut

=pod

=item restrict

Called on a class, this creates a new subclass with restrictions in place.

 my $inline_class = Some::Package->restrict('readonly', 'writeonly', 'subuser');

Will return a new class which is a subclass of Some::Package that has the readonly, writeonly,
and subuser restrictions applied. Note that restrictions are applied in order, so that a later
one may wipe out an earlier one. In this case, the re-defined commit method from subuser wins over
the one defined in writeonly.

This is used to restrict access to class methods, probably depending upon some sort of user permission
scheme.

=cut

=pod

=begin btest(restrict)

package Basset::Test::Testing::__PACKAGE__::restrict::Subclass1;
our @ISA = qw(__PACKAGE__);

sub successful {
	return 1;
};

my %restrictions = (
	'failure' => [
		'successful' => 'failed_restricted_method',
	],
);

$test->ok(Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->add_restrictions(%restrictions), "Subclass added restrictions");

package __PACKAGE__;

$test->ok(scalar __PACKAGE__->can('failed_restricted_method'), "__PACKAGE__ has failed_restricted_method");
$test->ok(scalar Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->can('failed_restricted_method'), "Subclass has failed_restricted_method");

$test->ok(Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->isa('__PACKAGE__'), 'Proper subclass');
$test->ok(! scalar __PACKAGE__->failed_restricted_method, "Method properly fails");
$test->ok(! scalar Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->failed_restricted_method, "Method properly fails");

my $subclass = Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->restrict('failure');

$test->ok($subclass, "Got restricted subclass");

$test->ok($subclass->restricted, "Subclass is restricted");
$test->ok(! Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->restricted, "Superclass unaffected");
$test->ok(! __PACKAGE__->restricted, "Superclass unaffected");

$test->ok(! scalar $subclass->successful, "Subclass restricted");
$test->ok(scalar Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->successful, "Superclass unaffected");

$test->ok(scalar Basset::Test::Testing::__PACKAGE__::restrict::Subclass1->restrict('worthless restriction'), "Added unknown restriction");

=end btest(restrict)

=cut

our $prior				= {};

sub restrict {
	my $pkg = shift;

	my @restrictions = @_ or return $pkg->error("Cannot restrict package w/o restrictions", "BO-13");

	my $key = join(',', $pkg, @restrictions);

	return $prior->{$key} if defined $prior->{$key};

	no strict 'refs';

	my $class = $pkg->inline_class();

	my $pkgrestrictions = $pkg->restrictions();

	my @applied = @{$pkg->applied_restrictions()};

	foreach my $restriction (@restrictions) {

		#keep track of the restrictions we've applied
		push @applied, $restriction;

		#grab our restriction map
		my @map = @{$pkgrestrictions->{$restriction} || []};

		#iterate through it. It's a hash masquerading as an arrayref, so the first
		#element is our key, the second is the value (which we don't need right now)
		while (@map) {
			my $method = shift @map;
			my $restricted_method = shift @map;

			$class->add_restricted_method($restriction, $method)
				or return $pkg->error($class->errvals);
		}
	};

	$prior->{$key} = $class;

	$class->applied_restrictions(\@applied);

	return $class;
}

=pod

=item nonrestricted_parent

Called on a class, returns the first non-restricted parent of that class

=cut

=pod

=begin btest(nonrestricted_parent)

package Basset::Test::Testing::__PACKAGE__::nonrestricted_parent::Subclass1;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

$test->is(__PACKAGE__->nonrestricted_parent, "__PACKAGE__", "__PACKAGE__ own nonrestricted parent");
$test->is(Basset::Test::Testing::__PACKAGE__::nonrestricted_parent::Subclass1->nonrestricted_parent, "Basset::Test::Testing::__PACKAGE__::nonrestricted_parent::Subclass1", "Subclass own nonrestricted parent");

my $subclass = Basset::Test::Testing::__PACKAGE__::nonrestricted_parent::Subclass1->inline_class;
$test->ok($subclass, "Got restricted class");
$test->is($subclass->nonrestricted_parent, "Basset::Test::Testing::__PACKAGE__::nonrestricted_parent::Subclass1", "Restricted class has proper non restricted parent");

my $subclass2 = $subclass->inline_class;
$test->ok($subclass2, "Got restricted class of restricted class");
$test->is($subclass2->nonrestricted_parent, "Basset::Test::Testing::__PACKAGE__::nonrestricted_parent::Subclass1", "Restricted class has proper non restricted parent");

my $subclass3 = __PACKAGE__->inline_class;
$test->ok($subclass3, "Got restricted class");
$test->is($subclass3->nonrestricted_parent, "__PACKAGE__", "Restricted class has proper non restricted parent");

=end btest(nonrestricted_parent)

=cut

sub nonrestricted_parent {
	my $self = shift;

	my $parents = $self->isa_path;

	#remember the isa path is most distant -> closest. Here we want to look at the closest
	#ancestor that is not restricted.
	#
	#We march up the tree. Once we find a parent (or ourselves) that can perform the method
	#we're looking for, we stop and are happy.
	foreach my $parent (reverse @$parents) {
		return $parent unless $parent->restricted();
	};

	return $self->error("class ($self) has no non-restricted parents", "BO-18");
}

=pod

=item dump

->dump dumps out the object (using Data::Dumper internally), this is useful to show you what an object looks like.

 print $obj->dump

Alternatively, you can hand in something to dump.

 print $obj->dump($something_else);

=cut

=pod

=begin btest(dump)

my $o = __PACKAGE__->new();
$test->ok($o, "Created object");
my $o2 = __PACKAGE__->new();
$test->ok($o2, "Created object");

$test->ok($o->dump, "Dumped object");
$test->ok($o->dump(['a']), "Dumped array");
$test->ok($o->dump({'k' => 'v'}), "Dumped hash");
$test->ok($o2->dump, "Dumped other object");
$test->is($o->dump($o2), $o2->dump, "Dumps equal");
$test->is($o->dump, $o2->dump($o), "Dumps equal");

=end btest(dump)

=cut

sub dump {
	my $self = shift;

	return Data::Dumper::Dumper(@_ ? shift : $self);
};

=pod

=item new

Finally! The B<constructor>. It's very easy, for a minimalist object, do this:

 my $obj = Class->new() || die Class->error();

Ta da! You have an object. Any attributes specified in the conf file will be loaded into your object. So if your
conf file defines 'foo' as 'bar', then $obj->foo will now equal 'bar'.

If you'd like, you can also pass in method/value pairs to the constructor.

 my $obj = Class->new(
 	'attribute' => '17',
 	'foo'		=> 'baz',
 	'method'	=> '88'
 ) || die Class->error();

This is (roughly) the same as:

 my $obj = Class->new() || die Class->error();

 $obj->attribute(17) || die $obj->error();
 $obj->foo('baz') || die $obj->error();
 $obj->method(88) || die $obj->error();

Any accessors or methods you'd like may be passed to the constructor. Any unknown pairs will be silently ignored.
If you pass a method/value pair to the constructor, it will override any equivalent method/value pair in the
conf file.

Also note that any methods that return undef are assumed to be errors and will cause your construction to fail. But, if you explicitly pass
in an 'undef' parameter and your method/mutator fails, then we will assume you know what you're doing and it's allowed. You only fail
if you pass in a value other than undef, but the result of the method call is an undef.

 $obj = Class->new(
 	'attr' => undef
 ) || die Class->error;

If you really really need to to explicitly set something to undef, you'll need to do it afterwards:

 $obj = Class->new();
 $obj->method(undef);

Note that in this case, setting 'method' to undef isn't actually an error, since that's what you want to do. But,
the constructor has no way to know when an accessor returning undef is an error, or when you explicitly set the accessor
to undef.

=cut

=pod

=begin btest(new)

my $o = __PACKAGE__->new();

$test->ok($o, "created a new object");

package Basset::Test::Testing::__PACKAGE__::new::Subclass1;
our @ISA = qw(__PACKAGE__);

Basset::Test::Testing::__PACKAGE__::new::Subclass1->add_attr('attr1');
Basset::Test::Testing::__PACKAGE__::new::Subclass1->add_attr('attr2');
Basset::Test::Testing::__PACKAGE__::new::Subclass1->add_attr('attr3');
Basset::Test::Testing::__PACKAGE__::new::Subclass1->add_class_attr('class_attr');

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::new::Subclass1->isa('__PACKAGE__'), "Subclass is subclass");
$test->ok(Basset::Test::Testing::__PACKAGE__::new::Subclass1->can('attr1'), 'class can attr1');
$test->ok(Basset::Test::Testing::__PACKAGE__::new::Subclass1->can('attr2'), 'class can attr2');
$test->ok(Basset::Test::Testing::__PACKAGE__::new::Subclass1->can('attr3'), 'class can attr3');
$test->ok(Basset::Test::Testing::__PACKAGE__::new::Subclass1->can('class_attr'), 'class can class_attr');

my $o2 = Basset::Test::Testing::__PACKAGE__::new::Subclass1->new();
$test->ok($o2, "created a subclass object");

my $o3 = Basset::Test::Testing::__PACKAGE__::new::Subclass1->new(
	'attr1' => 'attr1val',
);

$test->ok($o3, "Created a subclass object");
$test->is(scalar $o3->attr1, 'attr1val', 'subclass object has attribute from constructor');

my $o4 = Basset::Test::Testing::__PACKAGE__::new::Subclass1->new(
	'attr1' => 'attr1val',
	'attr2' => 'attr2val',
);

$test->ok($o4, "Created a subclass object");
$test->is(scalar $o4->attr1, 'attr1val', 'subclass object has attribute from constructor');
$test->is(scalar $o4->attr2, 'attr2val', 'subclass object has attribute from constructor');

my $o5 = Basset::Test::Testing::__PACKAGE__::new::Subclass1->new(
	'attr1' => 'attr1val',
	'attr2' => 'attr2val',
	'attr7' => 'attr7val',
	'attr8' => 'attr8val',
);

$test->ok($o5, "Created a subclass object w/junk values");
$test->is(scalar $o5->attr1, 'attr1val', 'subclass object has attribute from constructor');
$test->is(scalar $o5->attr2, 'attr2val', 'subclass object has attribute from constructor');

#these tests would now pass.
#my $o6 = Basset::Test::Testing::__PACKAGE__::new::Subclass1->new(
#	'attr1' => undef,
#);
#
#$test->ok(! $o6, "Failed to create object w/undef value");

my $o7 = Basset::Test::Testing::__PACKAGE__::new::Subclass1->new(
	'attr1' => 7,
	'attr2' => 0,
);

$test->ok($o7, "Created object w/0 value");
$test->is($o7->attr1, 7, 'attr1 value set');
$test->is($o7->attr2, 0, 'attr2 value set');

my $o8 = Basset::Test::Testing::__PACKAGE__::new::Subclass1->new(
	{
		'attr1' => 8,
		'attr2' => 9
	},
	'attr1' => 7
);

$test->ok($o8, "Created object w/0 value");
$test->is($o8->attr1, 7, 'attr1 value set');
$test->is($o8->attr2, 9, 'attr2 value set');

=end btest(new)

=cut

sub new {
	my $class	= shift->pkg;
	my $self	= bless {}, $class;

	return $self->init(
		@_
	) || $class->error($self->errvals);
};

=pod

=item init

The object initializer. Arguably more important than the constructor, but not something you need to worry about.
The constructor calls it internally, and you really shouldn't touch it or override it. But I wanted it here so
you know what it does.

Simply, it iterates through the conf file and mutates any of your object attributes to the value specified in the conf
file. It then iterates through the hash you passed to ->new() and does the same thing, overriding any conf values, if
necessary.

init is smart enough to use all super class values defined in the conf file, in hierarchy order. So if your conf file
contains:

 define package SuperClass

 foo = 'bar'

And you're creating a new SubClass object, then it will get the default of foo = 'bar' as in the conf file, despite
the fact that it was not defined for your own package. Naturally, the more significant definition is used.

 define package SuperClass

 foo = 'bar'

 define package SubClass

 foo = 'baz'

SuperClass objects will default foo to 'bar', SubClass objects will default foo to 'baz'

If the initializer is given a hashref as its first argument, then it will use those values first. Note that
values passed in via a hashref like this may be overridden by defaults AND by passed in arguments.

For example:

 #in your conf file
 define package Some::Class
 foo = bar
 one = two
 alpha = beta

 #in your code

 my $x = Some::Class->new(
 	{
 		'foo' => 'fnar',
 		'mister' => 'peepers',
 		'alpha' => 'kappa',
 	},
 	'alpha' => 'gamma'
 );

 print $x->foo; #prints 'bar' (from conf file)
 print $x->one; #prints 'two' (from conf file)
 print $x->mister; #prints 'peepers' (from initial hash)
 print $x->alpha; #prints 'gamma' (passed argument)

=cut

=pod

=begin btest(init)

package Basset::Test::Testing::__PACKAGE__::init::Subclass2;
our @ISA = qw(__PACKAGE__);

sub conf {
	return undef;
};

package __PACKAGE__;

{
	my $o = undef;
	local $@ = undef;
	$o = Basset::Test::Testing::__PACKAGE__::init::Subclass2->new();
	$test->is($o, undef, 'could not create object w/o conf file');
}

{
	my $o = __PACKAGE__->new('__j_known_junk_method' => 'a');
	$test->ok($o, 'created object');
}

package Basset::Test::Testing::__PACKAGE__::init::Subclass3;
our @ISA = qw(__PACKAGE__);
my $subclass = 'Basset::Test::Testing::__PACKAGE__::init::Subclass3';

sub known_failure {
	my $self = shift;
	return $self->error("I failed", "known_error_code");
}

sub known_failure_2 {
	my $self = shift;
	return;
}

my $obj1 =  $subclass->new();
$test->ok($obj1, "Got empty object w/o known failure");

my $obj2 =  $subclass->new(
	'known_failure' => 1
);

$test->is($obj2, undef, "obj2 not created because of known_failure");
$test->is($subclass->errcode, 'known_error_code', 'proper error code');

my $obj3 =  $subclass->new(
	'known_failure_2' => 1
);

$test->is($obj3, undef, "obj3 not created because of known_failure_2");
$test->is($subclass->errcode, 'BO-03', 'proper error code');

=end btest(init)

=cut

sub init {
	my $self	= shift;

	my $conf = $self->conf or return;

	my $parents = $self->isa_path();

	my %defaults = ();

	if (ref $_[0] eq 'HASH') {
		my $defhash = shift @_;
		@defaults{keys %$defhash} = values %$defhash;
	}

	#initialize our values brought in from the conf file
	foreach my $pkg (@$parents){

		my %pkgdef = map {substr($_,1), $conf->{$pkg}->{$_}} grep {/^-/} keys %{$conf->{$pkg}};

		@defaults{keys %pkgdef} = values %pkgdef;

	}

	my @init = (%defaults, @_);

	#initialize our values passed in to the constructor
#	foreach my $method (keys %init){
#		my $value = $init{$method};
	while (@init) {
		my ($method, $value) = splice(@init, 0, 2);
		#my $method = shift @init;
		#my $value = shift @init;

		if ($self->can($method)){
#			$self->wipe_errors();
			my $return = $self->$method($value);

			return $self->error("Could not initilize method ($method) to  value ($value)"
				. (defined $self->error ? " : " . $self->error : ' ')
				, ($self->errcode || "BO-03")
			) unless defined $return || ! defined $value;
		};
	};

	return $self;
};

=pod

=item pkg

Returns the package (class) of the object. Note that this is not necessarily the same as ref $object. This is
because of some wackiness in how perl handles some internal things that I don't quite understand.
Suffice to say that even if you bless an object into a class Foo, ref $object may not always be 'Foo'.
Sometimes it may be 'main::Foo' and sometimes it may be '::Foo'. I'll leave the reasons why for
others to document. This method is just here to keep that from biting you.

=cut

=pod

=begin btest(pkg)

package main::Basset::Test::Testing::__PACKAGE__::MainSubClass;
our @ISA = qw(__PACKAGE__);

package Basset::Test::Testing::__PACKAGE__::MainSubClass2;
our @ISA = qw(__PACKAGE__);

package ::Basset::Test::Testing::__PACKAGE__::MainSubClass3;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

$test->ok(main::Basset::Test::Testing::__PACKAGE__::MainSubClass->isa('__PACKAGE__'), "Created subclass");
$test->ok(Basset::Test::Testing::__PACKAGE__::MainSubClass2->isa('__PACKAGE__'), "Created subclass");
$test->ok(Basset::Test::Testing::__PACKAGE__::MainSubClass3->isa('__PACKAGE__'), "Created subclass");

my $o = __PACKAGE__->new();
$test->ok($o, "Created object");

my $so1 = main::Basset::Test::Testing::__PACKAGE__::MainSubClass->new();
$test->ok($so1, "Created sub-object");

my $so2 = Basset::Test::Testing::__PACKAGE__::MainSubClass2->new();
$test->ok($so2, "Created sub-object");

my $so3 = Basset::Test::Testing::__PACKAGE__::MainSubClass3->new();
$test->ok($so3, "Created sub-object");

$test->is($o->pkg, "__PACKAGE__", "Superclass works");
$test->is($so1->pkg, "Basset::Test::Testing::__PACKAGE__::MainSubClass", "Subclass works");
$test->is($so2->pkg, "Basset::Test::Testing::__PACKAGE__::MainSubClass2", "Subclass works");
$test->is($so3->pkg, "Basset::Test::Testing::__PACKAGE__::MainSubClass3", "Subclass works");

=end btest(pkg)

=cut

sub pkg {
	my $class = ref($_[0]) || $_[0];
	if (index($class, '::') == 0) {
		$class = substr($class, 2);
	} elsif (index($class, 'main::') == 0) {
		$class = substr($class, 6);
	};

	return $class;
};

=pod

=item factory

Abstract factory constructor. Works just like ->new() except it expects to receive a type. The types are listed in the conf
file to determine which type of object to instantiate.

In conf file:

 define package Basset::Object
 types 	@= user=Basset::User
 types	@= group=Basset::Group

And then, in your program:

 my $user = Basset::Object->factory(
 	'type' => 'user'
 );

 $user is a Basset::User object. Use for objects that are supposed to be used in multiple applications. This allows you to swap
 out particular objects for different (but similar!) ones by just changing the conf file, not all your code.

=cut

=pod

=begin btest(factory)

package Basset::Test::Testing::__PACKAGE__::factory::Subclass;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

my $oldtypes = __PACKAGE__->types();
$test->ok($oldtypes, "Saved old types");
my $newtypes = {%$oldtypes, 'factory_test_type' => '__PACKAGE__'};
$test->is(__PACKAGE__->types($newtypes), $newtypes, "Set new types");
$test->is(__PACKAGE__->pkg_for_type('factory_test_type'), '__PACKAGE__', 'can get class for type');
my $o = __PACKAGE__->new();
$test->ok($o, "Created new object");
my $o2 = __PACKAGE__->factory('type' => 'factory_test_type');
$test->ok($o2, "Factoried new object");
$test->ok($o2->isa('__PACKAGE__'), "Factory object isa class object");
$test->is(__PACKAGE__->types($oldtypes), $oldtypes, "reset old types");

=end btest(factory)

=cut

sub factory {
	my $class = shift;

	my %init = @_;

	if ($init{'type'}) {

		my $abstype = $init{'type'};
		delete $init{'type'};

		my $typeClass = $class->pkg_for_type($abstype) or return;

		return $typeClass->new(%init) || $class->error($typeClass->errvals);
	}
	else {
		return $class->new(@_);
	};
}

=pod

=item copy

Copies the object. B<Be warned>! Copy does a B<deep> copy of the object. So any objects/references/etc
pointed to by the original object will also be copied.

You may optionally pass in a different object/structure and copy that instead.

 my $backupBoard = $game->copy($game->board);

=cut

=pod

=begin btest(copy)

package Basset::Test::Testing::__PACKAGE__::copy::subclass;
our @ISA = qw(__PACKAGE__);

Basset::Test::Testing::__PACKAGE__::copy::subclass->add_attr('attr1');
Basset::Test::Testing::__PACKAGE__::copy::subclass->add_attr('attr2');
Basset::Test::Testing::__PACKAGE__::copy::subclass->add_attr('attr3');

package __PACKAGE__;

my $o = __PACKAGE__->new();
$test->ok($o, "Instantiated object");
my $o2 = $o->copy;
$test->ok($o2, "Copied object");
$test->is(length $o->dump, length $o2->dump, "dumps are same size");

my $o3 = Basset::Test::Testing::__PACKAGE__::copy::subclass->new(
	'attr1' => 'first attribute',
	'attr2' => 'second attribute',
	'attr3' => 'third attribute'
);

$test->ok($o3, "Instantiated sub-object");

$test->is($o3->attr1, 'first attribute', 'Subobject attr1 matches');
$test->is($o3->attr2, 'second attribute', 'Subobject attr2 matches');
$test->is($o3->attr3, 'third attribute', 'Subobject attr3 matches');

my $o4 = $o3->copy;

$test->ok($o4, "Copied sub-object");

$test->is($o4->attr1, 'first attribute', 'Copied subobject attr1 matches');
$test->is($o4->attr2, 'second attribute', 'Copied subobject attr2 matches');
$test->is($o4->attr3, 'third attribute', 'Copied subobject attr3 matches');

$test->is(length $o3->dump, length $o4->dump, "Sub object dumps are same size");

my $array = ['a', 2, {'foo' => 'bar'}];

$test->ok($array, "Got array");

my $array2 = __PACKAGE__->copy($array);

$test->ok($array2, "Copied array");
$test->is($array->[0], $array2->[0], "First element matches");
$test->is($array->[1], $array2->[1], "Second element matches");
$test->is($array->[2]->{'foo'}, $array2->[2]->{'foo'}, "Third element matches");

=end btest(copy)

=cut

sub copy {
	my $self	= shift;
	my $obj		= shift || $self;

	my $objdump = $self->dump($obj);
	$objdump =~ /^(\$\w+)/;

	local $@ = undef;
	return eval qq{
		my $1;
		eval \$objdump;
	};
}

=pod

=item pkg_for_type

Use internally by factory(), also sometimes useful in code. Given a type, returns the class as defined in the conf file.

 my $class = Basset::Object->pkg_for_type('user'); #returns Basset::User (for example)

=cut

=pod

=begin btest(pkg_for_type)

$test->ok(__PACKAGE__->types, "Got types out of the conf file");
my $typesbkp = __PACKAGE__->types();
my $newtypes = {%$typesbkp, 'testtype1' => '__PACKAGE__', 'testtype2' => 'boguspkg'};
$test->ok($typesbkp, "Backed up the types");
$test->is(__PACKAGE__->types($newtypes), $newtypes, "Set new types");
$test->is(__PACKAGE__->pkg_for_type('testtype1'), '__PACKAGE__', "Got class for new type");
$test->ok(! scalar __PACKAGE__->pkg_for_type('testtype2'), "Could not access invalid type");
$test->is(__PACKAGE__->errcode, 'BO-29', 'proper error code');

__PACKAGE__->wipe_errors;
$test->is(scalar(__PACKAGE__->pkg_for_type('testtype2', 'errorless')), undef, "Could not access invalid type w/ second arg");
$test->is(scalar(__PACKAGE__->errcode), undef, 'no error code set w/second arg');
$test->is(scalar(__PACKAGE__->errstring), undef, 'no error string set w/second arg');

my $h = {};

$test->is(__PACKAGE__->types($h), $h, 'wiped out types');
$test->is(scalar(__PACKAGE__->pkg_for_type('testtype3')), undef, 'could not get type w/o types');
$test->is(__PACKAGE__->errcode, 'BO-09', 'proper error code for no types');

$test->is(__PACKAGE__->types($typesbkp), $typesbkp, "Re-set original types");

=end btest(pkg_for_type)

=cut

sub pkg_for_type {
	my $class = shift;
	my $abstype = shift;
	#this is a hack and not publically accessible. If you pass in a second parameter for pkg_for_type,
	#it won't report an error if it doesn't find the class. This should be used in one and only one place -
	#inside of the error method itself. error requests a notification center, and if there is no notification
	#center, then it needs to be able to continue. If pkg_for_type spit back an error, it'd fall into an infinite
	#recursion. So we take the 2nd parameter to prevent that from happening.
	my $errorless = @_ ? shift : 0;

	my $types = $class->types;

	my $pkg = $types->{$abstype};

	if (defined $pkg) {

		return unless $class->load_pkg($pkg, $errorless);

		return $pkg;

	} else {
		return $errorless ? undef : $class->error("No class for type ($abstype)", "BO-09");
	}

};

=pod

=item inherits

This method is deprecated and b<will> be removed in Basset 1.0.4. The concept remains the same, but I, like an idiot, overlooked a
much simpler syntax. Just push the result of pkg_for_type onto @ISA as normal.

use Basset::Object;
our @ISA = Basset::Object->pkg_for_type('object');

Voila! Same effect. You may now proceed to read the long expository explanation here as to why you would do that. This exposition is going
to slide over into the pkg_for_type method.

Basset is a nice framework. It kicks all sorts of ass. But, it's entirely possible that it's not quite functional enough for you.
Let's say you work for some company, WidgetTech.

WidgetTech has information in a database, it's mostly fairly object-relational in nature, you can certainly use Basset::Object::Persistent.
So you go through and write up 50 modules that all inherit from Basset::Object::Persistent. All is right with the world.

3 months later, someone decides that instead of deleting old records from the database, as you'd been doing, you need to instead
leave them there and change their status flag to 'D'. The status flag is already there (you use it for other things, active, pending
suspended, etc.). So you don't need to change anything in your modules - just add the drop down to your interface and all is good.

2 days later, you're getting angry phonecalls from users saying that deleted data is showing up in the system. This is bad. You
forgot that Basset::Object::Persistent doesn't know anything about status flags and just loads up everything. Very bad. 

Options? Well, you could go into every single module (50 of 'em) and override their load_all and delete methods.
But man, that's gonna take forever. And probably get out of sync. And be a maintenance disaster. And it's just not the Basset way.

So what do you do instead? You hack up Basset::Object::Persistent. You modify the load_all method so that it tacks on a where
clause to exclude status of 'D'. You modify delete so that it just changes the status and re-commits. All is right with the world.

A month later, I release a new version of Basset, you forget about the modifications, upgrade, and start getting calls from angry
users. You need to re-hack the system.

So, you realize, this isn't the best way to go. Instead, you write a new object - WidgetTech::Object::Persistent.
WidgetTech::Object::Persistent inherits from Basset::Object::Persistent. You then do a search and replace on your 50 modules to
change occurances of Basset::Object::Persistent to WidgetTech::Object::Persistent. You put your modified load_all and delete methods
in WidgetTech::Object::Persistent and all is right with the world. I release a new version of Basset a week later, you drop it into
place, there are no issues.

Two months later, you decide that you need to override a method in Basset::Object. Or, you want a new method accessible to all of
your objects. Easy - put it in the root class. Now, you've learned enough not to hack up Basset::Object, so you create WidgetTech::Object
and add in your new method to there. Anything that did inherit from Basset::Object should now inherit WidgetTech::Object and everything's
fine.

Whoops. Except for WidgetTech::Object::Persistent. You have an inheritance tree like this:

 Basset::Object
 ^         ^
 |         |
 |       WidgetTech::Object
 |
 Basset::Object::Persistent
 ^
 |
 WidgetTech::Object::Persistent

But you need this:

 Basset::Object
 ^
 |
 WidgetTech::Object
 ^
 |
 Basset::Object::Persistent
 ^
 |
 WidgetTech::Object::Persistent

Your W::O::P inherit B::O::P which inherits B::O. And this all bypasses WidgetTech::Object. You don't want to stick the methods
into WidgetTech::Object::Persistent, since they need to be accessible to all classes, not just persistent ones. You (obviously)
know better than to hack Basset::Object::Persistent to inherit from WidgetTech::Object instead of Basset::Object. So what do you
do?

And all of this long expository setup brings us to the inherits method. Inheritance in Basset does not usually directly use @ISA.
Instead, it uses the inherits class method and a classtype.

 package Basset::Object::Persistent;

 use Basset::Object;
 #deprecated old way:
 #Basset::Object->inherits(__PACKAGE__, 'object');
 #fancy new way:
 @ISA = ( Basset::Object->pkg_for_type('object') );

Voila! That's basically equivalent to:

 package Basset::Object::Persistent;

 use Basset::Object;
 @ISA = qw(Basset::Object);

Now, everybody knows that familiar @ISA = ... syntax, so why change it? If you read that story up above, you already know. This
moves inheritance out of the module tree and into B<your conf file>. So now if you want to use WidgetTech::Objects as your root
object, you just change your conf file:

 types %= object=WidgetTech::Object

And blam-o. You have a new root class. Now, of course, Basset::Object will B<always> be the top level root object in a Basset system.
But you can now pretend that you have a different object instead. This new object sits in between Basset::Object and the rest of the
world. Anything you want to change in Basset::Object is fair game. The only thing that B<must> always be in Basset::Object is the
inherits method. Other modules will expect Basset::Object to call inherits at their start to set up their @ISA for them, so you can't
do away with it entirely.

B<inherits will die if it fails>. It's a compilation error, so it's not going to let you off the hook if it can't set up a relationship.

You'll mostly be fine with using @ISA in your code.

 package WidgetTech::Widget;
 @ISA = qw(WidgetTech::Object::Persistent);

You have control over WidgetTech::Widget and WidgetTech::Object::Persistent, and it's highly unlikely that you'll need to 
change your inheritance tree. Modifications can go in your super class or your subclass as needed and nobody cares about re-wiring
it.

=cut

sub inherits {
	my $self	= shift;
	my $pkg		= shift;
	my @types	= @_;

	no strict 'refs';

	foreach my $type (@types) {
		my $parent = $self->pkg_for_type($type) || die $self->errstring;

		push @{$pkg . "::ISA"}, $parent;
	}

	return 1;
}

=pod

=begin btest(inherits)

package Basset::Test::Testing::__PACKAGE__::inherits::Subclass1;
__PACKAGE__->inherits('Basset::Test::Testing::__PACKAGE__::inherits::Subclass1', 'object');

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::inherits::Subclass1->isa('Basset::Object'), 'subclass inherits from root');

=end btest(inherits)

=cut

=pod

=item isa_path

This is mainly used by the conf reader, but I wanted to make it publicly accessible. Given a class, it
will return an arrayref containing all of the superclasses of that class, in inheritence order.

Note that once a path is looked up for a class, it is cached. So if you dynamically change @ISA, it won't be reflected in the return of isa_path.
Obviously, dynamically changing @ISA is frowned upon as a result.

=cut

=pod

=begin btest(isa_path)

$test->ok(__PACKAGE__->isa_path, "Can get an isa_path for root");
my $path = __PACKAGE__->isa_path;
$test->is($path->[-1], '__PACKAGE__', 'Class has self at end of path');

package Basset::Test::Testing::__PACKAGE__::isa_path::subclass1;
our @ISA = qw(__PACKAGE__);

package Basset::Test::Testing::__PACKAGE__::isa_path::subclass2;
our @ISA = qw(Basset::Test::Testing::__PACKAGE__::isa_path::subclass1);

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::isa_path::subclass1->isa('__PACKAGE__'), 'Subclass of __PACKAGE__');
$test->ok(Basset::Test::Testing::__PACKAGE__::isa_path::subclass2->isa('__PACKAGE__'), 'Sub-subclass of __PACKAGE__');
$test->ok(Basset::Test::Testing::__PACKAGE__::isa_path::subclass1->isa('Basset::Test::Testing::__PACKAGE__::isa_path::subclass1'), 'Sub-subclass of subclass');

$test->ok(Basset::Test::Testing::__PACKAGE__::isa_path::subclass1->isa_path, "We have a path");
my $subpath = Basset::Test::Testing::__PACKAGE__::isa_path::subclass1->isa_path;
$test->is($subpath->[-2], '__PACKAGE__', 'Next to last entry is parent');
$test->is($subpath->[-1], 'Basset::Test::Testing::__PACKAGE__::isa_path::subclass1', 'Last entry is self');

$test->ok(Basset::Test::Testing::__PACKAGE__::isa_path::subclass2->isa_path, "We have a sub path");
my $subsubpath = Basset::Test::Testing::__PACKAGE__::isa_path::subclass2->isa_path;

$test->is($subsubpath->[-3], '__PACKAGE__', 'Third to last entry is grandparent');
$test->is($subsubpath->[-2], 'Basset::Test::Testing::__PACKAGE__::isa_path::subclass1', 'Second to last entry is parent');
$test->is($subsubpath->[-1], 'Basset::Test::Testing::__PACKAGE__::isa_path::subclass2', 'Last entry is self');

package Basset::Test::Testing::__PACKAGE__::isa_path::Subclass3;

our @ISA = qw(__PACKAGE__ __PACKAGE__);

package __PACKAGE__;

my $isa = Basset::Test::Testing::__PACKAGE__::isa_path::Subclass3->isa_path;
$test->ok($isa, "Got isa path");

#$test->is(scalar(@$isa), 2, 'two entries in isa_path');
$test->is($isa->[-2], '__PACKAGE__', 'Second to last entry is parent');
$test->is($isa->[-1], 'Basset::Test::Testing::__PACKAGE__::isa_path::Subclass3', 'Last entry is self');

=end btest(isa_path)

=cut

our $paths = {};

sub isa_path {

	my $class	= $_[0]->can('pkg') ? shift->pkg() : shift;
	$class		= ref $class || $class;
	my $seen	= shift || {};

	return if $seen->{$class}++;

	return $paths->{$class} if defined $paths->{$class};

	no strict 'refs';
	my @i = @{$class . "::ISA"};

	my @s = ();

	foreach my $super (@i){

		next if $seen->{$super};

		#the method invocation is more consistent, but bonks on modules that aren't
		#subclasses of Basset::Object. So we call it as a function to display all modules
		#my $super_isa = $super->can('isa_path') ? $super->isa_path($seen) : [];

		my $super_isa = isa_path($super, $seen);
		push @s, @$super_isa;
	};

	push @s, $class;

	$paths->{$class} = \@s;

	return \@s;

};

=pod

=item module_for_class

Used mainly internally. Converts a perl package name to its file system equivalent. So,
Basset::Object -> Basset/Object.pm and so on.

=cut

=pod

=begin btest(module_for_class)

$test->is(scalar(__PACKAGE__->module_for_class), undef, "Could not get module_for_class w/o package");
$test->is(__PACKAGE__->errcode, "BO-20", 'proper error code');
$test->is(__PACKAGE__->module_for_class('Basset::Object'), 'Basset/Object.pm', 'proper pkg -> file name');
$test->is(__PACKAGE__->module_for_class('Basset::Object::Persistent'), 'Basset/Object/Persistent.pm', 'proper pkg -> file name');
$test->is(__PACKAGE__->module_for_class('Basset::DB::Table'), 'Basset/DB/Table.pm', 'proper pkg -> file name');

=end btest(module_for_class)

=cut

sub module_for_class {
	my $self = shift;
	my $pkg = shift or return $self->error("Cannot check for included-ness w/o package", "BO-20");

	$pkg =~ s!::!/!g;
	$pkg .= '.pm';

	return $pkg;
};

=pod

=item conf

conf is just a convenience wrapper around read_conf_file.

 $obj->conf === Basset::Object::Conf->read_conf_file;

=cut

=pod

=begin btest(conf)

$test->ok(scalar __PACKAGE__->conf, "Class accessed conf file");
my $o = __PACKAGE__->new();
$test->ok(scalar $o, "Got object");
$test->ok(scalar $o->conf, "Object accessed conf file");

=end btest(conf)

=cut

sub conf {
	my $self	= shift->pkg;
	my $local	= shift || 0;

	my $conf = $self->_conf_class->read_conf_file
		or return $self->error($self->_conf_class->errvals);

	if ($local && defined $conf->{$self}) {
		return $conf->{$self};
	}
	elsif ($local) {
		return {};
	}
	else {
		return $conf;
	}
};

=pod

=item today

Convenience method. Returns today's date in a YYYY-MM-DD formatted string

=cut

=pod

=begin btest(today)

$test->like(__PACKAGE__->today, qr/^\d\d\d\d-\d\d-\d\d$/, 'matches date regex');
$test->like(__PACKAGE__->today('abc'), qr/^\d\d\d\d-\d\d-\d\d$/, 'matches date regex despite input');

=end btest(today)

=cut

sub today {
	my @today = localtime;
	sprintf("%04d-%02d-%02d", $today[5] + 1900, $today[4] + 1, $today[3]);
}

=pod

=item now

Convenience method. Returns a timestamp in a YYYY-MM-DD HH:MM:SS formatted string

=cut

=pod

=begin btest(now)

$test->like(__PACKAGE__->now, qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/, 'matches timestamp regex');
$test->like(__PACKAGE__->now('def'), qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/, 'matches timestamp regex despite input');

=end btest(now)

=cut

sub now {
	my @today = localtime;
	sprintf("%04d-%02d-%02d %02d:%02d:%02d", $today[5] + 1900, $today[4] + 1, $today[3], @today[2,1,0]);
}

=pod

=item gen_handle

returns a filehandle in a different package. Useful for when you need to open filehandles and pass 'em around.

 my $handle = Basset::Object->gen_handle();
 open ($handle, "/path/to/my/list");

All but identical to gensym in Symbol by this point.

=cut

=pod

=begin btest(gen_handle)

$test->ok(__PACKAGE__->gen_handle, "Generated handle");
my $h = __PACKAGE__->gen_handle;
$test->ok($h, "Generated second handle");
$test->is(ref $h, "GLOB", "And it's a globref");

=end btest(gen_handle)

=cut

our $handle = 0;

sub gen_handle {
	no strict 'refs';
	my $self = shift;
	my $name = "HANDLE" . $handle++;

	my $h = \*{"Basset::Object::Handle::" . $name};	#You'll note that I don't want my
													#namespace polluted either
	delete $Basset::Object::Handle::{$name};
	return $h;
};

=pod

=item perform

if I were writing this in objective-C, I'd call it performSelectors:withObjects: Ho hum. I've really grown fond of the objective-C
syntax. Anyway, since I can't do that, it's just called perform.

 $object->perform(
 	'methods' => [qw(name password address)],
 	'values' => ['Jim', 'password', 'Chew St']
 ) || die $object->errstring;

Given a list of methods and values, it calls each method in turn with each value passed. If anything fails, it an error and stops
proceeding through the list.

Optionally, you may pass in a dereference hash to dereference an arrayref or hashref.

 $object->perform(
 	'methods' => [qw(name password address permission)],
 	'values' => ['Jim', 'password', 'Chew St', ['PT07', 'AB']],
 	'dereference' => [qw(permission)],
 ) || die $object->errstring;

With the dereference value, it calls

 $object->permission('PT07', 'AB');

Without the dereference value, it calls

 $object->permission(['PT07', 'AB']);

This can (obviously) even be called with a single method. This is preferrable to just calling $obj->$method(@args) in the code
if $method is not guaranteed to be callable since perform automatically does a 'can' check on the method for you.

Optionally, you may also pass in a continue parameter.

 $object->perform(
 	'methods'		=> [qw(name password address permission)],
 	'values'		=> ['Jim', 'password', 'Chew St', ['PT07', 'AB']],
 	'dereference'	=> [qw(permission)],
 	'continue'		=> 1
 ) || die $object->errstring;

continue should be used with great caution. continue will cause execution to continue even if an error occurs. At the end, you'll
still get an undef back, and your error message will be a list of \n delimited error messages, your error code will be a list of \n
delimited error codes. This is appropriate if you want to set multiple attributes at once (or other methods that are indpendent of each
other) and want to report all errors en masse at the end. 

=cut

=pod

=begin btest(perform)

package Basset::Test::Testing::__PACKAGE__::perform::Subclass;
our @ISA = qw(__PACKAGE__);

Basset::Test::Testing::__PACKAGE__::perform::Subclass->add_attr('attr1');
Basset::Test::Testing::__PACKAGE__::perform::Subclass->add_attr('attr2');
Basset::Test::Testing::__PACKAGE__::perform::Subclass->add_attr('attr3');

sub method1 {
	return 77;
}

sub method2 {
	my $self = shift;
	return scalar @_;
};

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::perform::Subclass->isa('__PACKAGE__'), 'we have a subclass');
$test->ok(Basset::Test::Testing::__PACKAGE__::perform::Subclass->can('attr1'), 'subclass has attr1');
$test->ok(Basset::Test::Testing::__PACKAGE__::perform::Subclass->can('attr2'), 'subclass has attr2');
$test->ok(Basset::Test::Testing::__PACKAGE__::perform::Subclass->can('attr2'), 'subclass has attr3');
$test->ok(Basset::Test::Testing::__PACKAGE__::perform::Subclass->can('method1'), 'subclass has method1');
$test->ok(Basset::Test::Testing::__PACKAGE__::perform::Subclass->can('method2'), 'subclass has method2');
$test->is(scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->method1, 77, 'method1 returns 77');
$test->is(scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->method2, 0, 'method2 behaves as expected');
$test->is(scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->method2('a'), 1, 'method2 behaves as expected');
$test->is(scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->method2(0,0), 2, 'method2 behaves as expected');

my $o = Basset::Test::Testing::__PACKAGE__::perform::Subclass->new();

$test->ok($o, "Instantiated object");

my $class = 'Basset::Test::Testing::__PACKAGE__::perform::Subclass';

$test->is(scalar($class->perform), undef, "Cannot perform w/o method");
$test->is($class->errcode, 'BO-04', 'proper error code');
$test->is(scalar($class->perform('methods' => 'able')), undef, "Cannot perform w/o values");
$test->is($class->errcode, 'BO-05', 'proper error code');
$test->is(scalar($class->perform('methods' => 'able', 'values' => 'baker')), undef, "methods must be arrayref");
$test->is($class->errcode, 'BO-11', 'proper error code');
$test->is(scalar($class->perform('methods' => ['able'], 'values' => 'baker')), undef, "values must be arrayref");
$test->is($class->errcode, 'BO-12', 'proper error code');

$test->ok(
	scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->perform(
		'methods' => ['method1'],
		'values' => ['a'],
	),
	"Class performs method1");

$test->ok(
	scalar $o->perform(
		'methods' => ['method1'],
		'values' => ['a'],
	),
	"Object performs method1");

$test->ok(! 
	scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->perform(
		'methods' => ['method2'],
		'values' => [],
	),
	"Class cannot perform method2 w/o args");

$test->ok(
	scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->perform(
		'methods' => ['method2'],
		'values' => ['a']
	),
	"Class performs method2 w/1 arg");

$test->ok(
	scalar Basset::Test::Testing::__PACKAGE__::perform::Subclass->perform(
		'methods' => ['method2'],
		'values' => ['b'],
	),
	"Class performs method2 w/1 arg in arrayref");

$test->ok(! 
	scalar $o->perform(
		'methods' => ['attr1'],
		'values' => []
	),
	"object cannot access attribute w/o args"
);

$test->is(scalar $o->attr1, undef, 'attr1 is undefined');
$test->is(scalar $o->attr2, undef, 'attr2 is undefined');
$test->is(scalar $o->attr3, undef, 'attr3 is undefined');

$test->ok(
	scalar $o->perform(
		'methods' => ['attr1'],
		'values' => ['attr1_val']
	),
	"object performed attr1"
);

$test->is(scalar $o->attr1(), 'attr1_val', 'attr1 set via perform');

$test->ok(
	scalar $o->perform(
		'methods' => ['attr2', 'attr3'],
		'values' => ['attr2_val', 'attr3_val']
	),
	"object performed attr2, attr3"
);

$test->is(scalar $o->attr2(), 'attr2_val', 'attr2 set via perform');
$test->is(scalar $o->attr3(), 'attr3_val', 'attr3 set via perform');

$test->ok(! 
	scalar $o->perform(
		'methods' => ['attr4'],
		'values' => ['attr4_val']
	),
	"object cannot perform unknown method"
);

$test->ok(! 
	scalar $o->perform(
		'methods' => ['attr4', 'attr2'],
		'values' => ['attr4_val', 'attr2_val_2'],
	),
	'object cannot perform unknown method w/known method'
);

$test->is(scalar $o->attr2, 'attr2_val', 'attr2 unchanged');

$test->ok(! 
	scalar $o->perform(
		'methods' => ['attr1'],
		'values' => [undef]
	),
	"object failed trying to perform attr1"
);

$test->ok(! 
	scalar $o->perform(
		'methods' => ['attr1', 'attr2'],
		'values' => [undef, 'attr2_val_2'],
	),
	'object failed trying to perform attr1'
);

$test->is(scalar $o->attr2, 'attr2_val', 'attr2 unchanged');

$test->ok(! 
	scalar $o->perform(
		'methods' => ['attr1', 'attr2'],
		'values' => [undef, 'attr2_val_2'],
		'continue' => 1,
	),
	'object failed trying to perform attr1'
);

$test->is(scalar $o->attr2, 'attr2_val_2', 'attr2 changed due to continue');

my $arr = ['a', 'b'];
$test->ok($arr, "Have an arrayref");

$test->ok(
	scalar $o->perform(
		'methods' => ['attr3'],
		'values' => [$arr],
	),
	"Performed attr3"
);

$test->is($o->attr3, $arr, "attr3 contains arrayref");

$test->ok(
	scalar $o->perform(
		'methods' => ['attr3'],
		'values' => [$arr],
		'dereference' => ['attr3'],
	),
	"Performed attr3 with de-reference"
);

$test->is($o->attr3, 'a', "attr3 contains first element of arrayref");

$test->ok(
	scalar $o->perform(
		'methods' => ['attr2', 'attr3'],
		'values' => [$arr, $arr],
		'dereference' => ['attr2'],
	),
	"Performed attr3 with de-reference"
);

$test->is($o->attr2, 'a', "attr2 contains first element of arrayref");
$test->is($o->attr3, $arr, "attr3 contains arrayref");

=end btest(perform)

=cut

sub perform {
	my $self	= shift;

	my %args	= @_;

	my $methods	= $args{'methods'} or return $self->error("Cannot perform w/o methods", "BO-04");
	my $values	= $args{'values'} or return $self->error("Cannot perform w/o values", "BO-05");
	my $deref	= {map {$_, 1} @{$args{'dereference'} || []}};
	my $continue= $args{'continue'} || 0;

	return $self->error("methods must be arrayref", "BO-11") unless ref $methods eq 'ARRAY';
	return $self->error("values must be arrayref", "BO-12") unless ref $values eq 'ARRAY';

	return $self->error('Cannot perform. Different number of methods and values', 'BO-07') unless @$methods == @$values;

	my @errors = ();
	my @codes = ();

	#non destructive copies
	($methods, $values) = ([@$methods], [@$values]);

	while (@$methods) {
		my $method = shift @$methods;
		my $value = shift @$values;

		my @args = ($value);

		if (ref $value eq 'ARRAY' && $deref->{$method}) {
			@args = @$value;
		} elsif (ref $value eq 'HASH' && $deref->{$method}) {
			@args = %$value;
		};

		if ($self->can($method)) {
			unless (defined $self->$method(@args)) {
				if ($args{'continue'}) {
					push @errors, $self->error();
					push @codes, $self->errcode || "BO-06";
				} else {
					$value = defined $value ? $value : 'value is undefined';
					return $self->error("Could not perform method ($method) with value ($value) : " . $self->error(), $self->errcode || "BO-06");
				}
			}
		} else {
			return $self->error("Object cannot perform method ($method)", "BO-10");
		};
	};

	if (@errors) {
		return $self->error(join("\n", @errors), join("\n", @codes));
	} else {
		return 1;
	};

};

=pod

=item stack_trace

A method useful for debugging. When called, returns a stack trace.

sub some_method {
	my $self = shift;
	#you know something weird happens here.
	print STDERR $self->stack_trace();
};

=cut

=pod

=begin btest(stack_trace)

sub tracer {
	return __PACKAGE__->stack_trace;
};

$test->ok(tracer(), "Got a stack trace");
my $trace = tracer();
$test->ok($trace, "Has a stack trace");
$test->like($trace, qr/Package:/, "Contains word: 'Package:'");
$test->like($trace, qr/Filename:/, "Contains word: 'Filename:'");
$test->like($trace, qr/Line number:/, "Contains word: 'Line number:'");
$test->like($trace, qr/Subroutine:/, "Contains word: 'Subroutine:'");
$test->like($trace, qr/Has Args\? :/, "Contains word: 'Has Args:'");
$test->like($trace, qr/Want array\? :/, "Contains word: 'Want array:'");
$test->like($trace, qr/Evaltext:/, "Contains word: 'Evaltext:'");
$test->like($trace, qr/Is require\? :/, "Contains word: 'Is require:'");

=end btest(stack_trace)

=cut

sub stack_trace {
	my $caller_count = 1;
	my $caller_stack = undef;
	my @verbose_caller = ("Package: ", "Filename: ", "Line number: ", "Subroutine: ", "Has Args? : ",
							"Want array? : ", "Evaltext: ", "Is require? : ");

	push @verbose_caller, ("Hints:  ", "Bitmask:  ") if $] >= 5.006;	#5.6 has a more verbose caller stack.

	while (my @caller = caller($caller_count++)){
		$caller_stack .= "\t---------\n";
		foreach (0..$#caller){
			my $callvalue = defined $caller[$_] ? $caller[$_] : '';
			$caller_stack .= "\t\t$verbose_caller[$_]$callvalue\n";# if $caller[$_];
		};
	};

	$caller_stack .= "\t---------\n";
	return $caller_stack;
};

=pod

=item no_op

no_op is a simple little method that just always returns 1, no matter what. Useful for cases where
you want to be able to call a method and have it succeed, such as a generic place holder.

=cut

=pod

=begin btest(no_op)

$test->ok(__PACKAGE__->no_op, "No op");
$test->is(__PACKAGE__->no_op, 1, "No op is 1");
my $obj = __PACKAGE__->new();
$test->ok($obj, "Got object");
$test->ok($obj->no_op, "Object no ops");
$test->is($obj->no_op, 1, "Object no op is 1");

=end btest(no_op)

=cut

sub no_op { return 1 };

=pod

=item system_prefix

Returns the prefix used by the system for internal methods as generated by add_attr and the like.

=cut

=pod

=begin btest(system_prefix)

$test->is(__PACKAGE__->system_prefix(), '__b_', 'expected system prefix');

=end btest(system_prefix)

=cut

sub system_prefix { return '__b_'};

=pod

=item privatize

Returns a method prepended with the system prefix, useful for making private methods.

 Some::Class->privatize('foo'); #returns Some::Class->system_prefix . 'foo';

=cut

sub privatize {
	my $class = shift;
	my $method = shift or return $class->error("Cannot privatize w/o method", "BO-24");

	my $prefix = $class->system_prefix;
	return index($method, $prefix) >= 0
		? $method
		: $class->system_prefix . $method;
}

=pod

=begin btest(privatize)

$test->ok(! __PACKAGE__->privatize, 'Cannot privatize w/o method');
$test->is(__PACKAGE__->errcode, "BO-24", "proper error code");

$test->is(__PACKAGE__->privatize('foo'), '__b_foo', "privatized foo");
$test->is(__PACKAGE__->privatize('__b_foo'), '__b_foo', "__b_foo remains __b_foo");

=end btest(privatize)

=cut

=pod

=item deprivatize

Returns a method with the system prefix removed, useful for unmaking private methods.

 Some::Class->deprivatize('__b_foo'); #returns 'foo';

=cut

sub deprivatize {
	my $class = shift;
	my $method = shift or return $class->error("Cannot deprivatize w/o method", "BO-25");

	my $prefix = $class->system_prefix;

	if (index($method, $prefix) == 0) {
		$method = substr($method, length $prefix);
	}

	return $method;
}

=pod

=begin btest(deprivatize)

$test->ok(! __PACKAGE__->deprivatize, 'Cannot deprivatize w/o method');
$test->is(__PACKAGE__->errcode, "BO-25", "proper error code");

$test->is(__PACKAGE__->deprivatize('foo'), 'foo', "deprivatized foo");
$test->is(__PACKAGE__->deprivatize('__b_foo'), 'foo', "deprivatized __b_foo");

=end btest(deprivatize)

=cut

=pod

=item is_private

Returns a true value if the method is private (starts with system prefix), and false otherwise.

 Some::Class->is_private('__b_foo');	#returns true;
 Some::Class->is_private('foo');		#returns false;

=cut

sub is_private {
	my $class = shift;
	my $method = shift or return $class->error("Cannot determine is_private w/o method", "BO-26");

	return index($method, $class->system_prefix) == 0;
}

=pod

=begin btest(deprivatize)

$test->ok(! __PACKAGE__->is_private, 'Cannot is_private w/o method');
$test->is(__PACKAGE__->errcode, "BO-26", "proper error code");

$test->ok(! __PACKAGE__->is_private('foo'), 'foo is not private');
$test->ok(__PACKAGE__->is_private('__b_foo'), '__b_foo is private');

=end btest(deprivatize)

=cut

=pod

=item cast

Returns the object casted to the given class.

 my $object = Some::Class->new();
 my $casted = $object->cast('Some::Class::Subclass');

If passed a second true argument, returns a copy of the object casted.

 my $object = Some::Class->new();
 my $castedCopy = $object->cast('Some::Class::Subclass', 'copy');

=cut

sub cast {
	my $self = shift;

	return $self->error("Can only cast objects", "BO-21") unless ref $self;

	my $class = shift or return $self->error("Cannot cast w/o class", "BO-22");
	my $should_copy = shift || 0;

	my $cast = undef;

	if ($should_copy) {
		$cast = $self->copy or return;
	} else {
		$cast = $self;
	}

	$self->load_pkg($class) or return;

	return bless $cast, $class;

}

=pod

=begin btest(cast)

package Basset::Test::Testing::__PACKAGE__::cast::Subclass1;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

#pretend it was loaded normally
$INC{__PACKAGE__->module_for_class("Basset::Test::Testing::__PACKAGE__::cast::Subclass1")}++;

my $subclass = "Basset::Test::Testing::__PACKAGE__::cast::Subclass1";

$test->ok(! __PACKAGE__->cast, "Cannot cast classes");
$test->is(__PACKAGE__->errcode, "BO-21", "proper error code");

my $o = __PACKAGE__->new();
$test->ok($o, "got object");

$test->ok(! $o->cast, "Cannot cast w/o class");
$test->is($o->errcode, "BO-22", "proper error code");
my $c = $o->cast($subclass, 'copy');
$test->ok($c, "casted object");
$test->is($o->pkg, "__PACKAGE__", "original part of super package");
$test->is($c->pkg, $subclass, "casted object part of sub package");
$test->is($c->errcode, $o->errcode, "error codes match, rest is assumed");

my $o2 = __PACKAGE__->new();
$test->ok($o2, "got object");

$test->ok(! $o2->cast, "Cannot cast w/o class");
$test->is($o2->errcode, "BO-22", "proper error code");
my $c2 = $o2->cast($subclass, 'copy');
$test->ok($c2, "casted object");
$test->is($o2->pkg, "__PACKAGE__", "original part of super package");
$test->is($c2->pkg, $subclass, "casted object part of sub package");
$test->is($c2->errcode, $o->errcode, "error codes match, rest is assumed");

=end btest(cast)

=cut

#used for introspection.
__PACKAGE__->add_trickle_class_attr('_class_attributes', {});
__PACKAGE__->add_trickle_class_attr('_instance_attributes', {});

# _obj_error is the object attribute slot for storing the most recent error that occurred. It is
# set via the first argument to the ->error method when called with an object.
# i.e., $obj->error('foo', 'bar');	#_obj_error is 'foo'
__PACKAGE__->add_attr('_obj_error');

# _obj_errcode is the object attribute slot for storing the most recent error code that occurred. It is
# set via the second argument to the ->error method when called with an object.
# i.e., $obj->error('foo', 'bar');	#_obj_errcode is 'bar'
__PACKAGE__->add_attr('_obj_errcode');

# _pkg_error is the class attribute slot for storing the most recent error that occurred. It is
# set via the first argument to the ->error method when called with a class.
# i.e., $class->error('foo', 'bar');	#_pkg_error is 'foo'
__PACKAGE__->add_trickle_class_attr('_pkg_error');

# _pkg_errcode is the class attribute slot for storing the most recent error code that occurred. It is
# set via the second argument to the ->error method when called with a class.
# i.e., $class->error('foo', 'bar');	#_pkg_errcode is 'bar'
__PACKAGE__->add_trickle_class_attr('_pkg_errcode');

=pod

=back

=head1 ATTRIBUTES

=over

=item errortranslator

The errortranslator needs to be set to a hashref, and it translates programmer 
readable errors into user readable errors. It's clunky and a mess and a hack, but it works.

 __PACKAGE__->errortranslator(
	{
		'violation of key constraint foo: Cannot INSERT' => 'Please specify a value for foo'
	}
 );

 $obj->do_something || die $obj->error(); 	# dies 'violation of key constraint foo: Cannot INSERT'
 $obj->do_something || die $obj->usererror();# dies 'Please specify a value for foo'

The error translator looks at the error values, and if a more friendly user error exists, it returns that one instead.
errortranslator looks at and returns (in order):

 the actual error,
 the raw error, 
 the error code, 
 a '*' wildcard, 
 and then just returns the original error w/o modification.

Be careful using the '*' wildcard. This will translate -any- error message that doesn't have a friendlier version.

=cut

=pod

=begin btest(errortranslator)

my $uses_real = __PACKAGE__->use_real_errors();
$test->is(__PACKAGE__->use_real_errors(0), 0, "Uses real errors");

my $translator = {
	'test error' => 'test message'
};

$test->ok($translator, "Created translator");
$test->is(__PACKAGE__->errortranslator($translator), $translator, "Set translator");
$test->is(scalar __PACKAGE__->error('test error', 'test code'), undef, "Set error");
$test->is(__PACKAGE__->usererror(), 'test message', 'Re-wrote error message');

$test->is(__PACKAGE__->errortranslator($uses_real), $uses_real, 'Class reset uses real error');

=end btest(errortranslator)

=cut

# The error translator turns system defined error messages into user readable error messages.
# It's clunky, but it's the best we've got for now.
__PACKAGE__->add_trickle_class_attr('errortranslator');

=pod

=item use_real_errors

use_real_errors bypasses the errortranslator and only returns the errstring. This is useful so that your developers can get
back useful information, but your users can get back a friendly message.

=cut

=begin btest(use_real_errors)

my $translator = __PACKAGE__->errortranslator();
$test->ok(__PACKAGE__->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2'
	}),
	'Class set error translator'
);

my $uses_real = __PACKAGE__->use_real_errors();

my $confClass = __PACKAGE__->pkg_for_type('conf');
$test->ok($confClass, "Got conf");

my $cfg = $confClass->conf;
$test->ok($cfg, "Got configuration");

$test->ok($cfg->{"Basset::Object"}->{'use_real_errors'} = 1, "enables real errors");

$test->is(scalar __PACKAGE__->error("extra error", "test code"), undef, "Class sets error");
$test->is(__PACKAGE__->usererror(), "extra error...with code (test code)", "Class gets literal error for literal");

$test->is(scalar __PACKAGE__->error(["formatted test error %d", 7], "test code"), undef, "Class sets formatted error");
$test->is(__PACKAGE__->usererror(), "formatted test error 7...with code (test code)", "Class gets literal error for formatted string");

$test->is(scalar __PACKAGE__->error(["formatted test error %d", 9], "test code"), undef, "Class sets formatted error");
$test->is(__PACKAGE__->usererror(), "formatted test error 9...with code (test code)", "Class gets literal error for string format");

$test->is(scalar __PACKAGE__->error("Some test error", "test code"), undef, "Class sets standard error");
$test->is(__PACKAGE__->usererror(), "Some test error...with code (test code)", "Class gets literal error for error code");

$test->is(scalar __PACKAGE__->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
$test->is(__PACKAGE__->usererror(), "Some unknown error...with code (unknown code)", "Class gets no user error");

$test->ok(__PACKAGE__->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2',
		'*' => 'star error',
	}),
	'Class changed error translator'
);

$test->is(scalar __PACKAGE__->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
$test->is(__PACKAGE__->usererror(), "Some unknown error...with code (unknown code)", "Class gets literal star error");

$test->is(__PACKAGE__->errortranslator($translator), $translator, 'Class reset error translator');
#$test->is(__PACKAGE__->errortranslator($uses_real), $uses_real, 'Class reset uses real error');
#$test->ok('foo', 'bar');
$test->is($cfg->{"__PACKAGE__"}->{'use_real_errors'} = $uses_real, $uses_real, "enables reset uses real errors");

=end btest(use_real_errors)

=cut

__PACKAGE__->add_default_class_attr('use_real_errors');

=pod

=item delegate

This is borrows from objective-C, because I like it so much. Basically, the delegate is a simple
catch all place for an additional object that operates on your current object.

 sub some_method {
 	 my $self = shift;
	 #call the delegate when we call some_method
	 if ($self->delegate && $self->delegate->can('foo')) {
		$self->delegate->foo(@useful_arguments);
	 };
 }

=cut

=pod

=begin btest(delegate)

my $o = __PACKAGE__->new();
$test->ok($o, "Set up object");
my $o2 = __PACKAGE__->new();
$test->ok($o2, "Set up second object");
$test->ok(! scalar __PACKAGE__->delegate($o), "Class cannot set delegate");
$test->is(scalar $o->delegate($o2), $o2, "Object set delegate");
$test->is(scalar $o->delegate(), $o2, "Object accessed delegate");
$test->is(scalar $o->delegate(undef), undef, "Object deleted delegate");

=end btest(delegate)

=cut

__PACKAGE__->add_attr('delegate');

=pod

=item types

Defined in your conf file. Lists types used by the factory and pkg_for_type. See those methods for more info.
Use a hashref in the conf file:

 types %= user=Basset::User
 types %= group=Basset::Group
 #etc

That is, types should be an array of values that are = delimited. type=class.

=cut

=pod

=begin btest(types)

$test->ok(__PACKAGE__->types, "Got types out of the conf file");
my $typesbkp = __PACKAGE__->types();
my $newtypes = {%$typesbkp, 'testtype1' => '__PACKAGE__', 'testtype2' => 'boguspkg'};
$test->ok($typesbkp, "Backed up the types");
$test->is(__PACKAGE__->types($newtypes), $newtypes, "Set new types");
$test->is(__PACKAGE__->pkg_for_type('testtype1'), '__PACKAGE__', "Got class for new type");
$test->ok(! scalar __PACKAGE__->pkg_for_type('testtype2'), "Could not access invalid type");
$test->is(__PACKAGE__->types($typesbkp), $typesbkp, "Re-set original types");

=end btest(types)

=cut

#we're careful not to re-define this one, since it was probably already defined in Basset::Object::Conf, which is necessary due to circular
#inheritance issues.
__PACKAGE__->add_trickle_class_attr('types', {}) unless __PACKAGE__->can('types');

#set up our defaults. Config file? Why bother.
__PACKAGE__->types->{'logger'}				||= 'Basset::Logger';
__PACKAGE__->types->{'notificationcenter'}	||= 'Basset::NotificationCenter';
__PACKAGE__->types->{'conf'}				||= 'Basset::Object::Conf';
__PACKAGE__->types->{'driver'}				||= 'Basset::DB';
__PACKAGE__->types->{'table'}				||= 'Basset::DB::Table';
__PACKAGE__->types->{'template'}			||= 'Basset::Template';
__PACKAGE__->types->{'object'}				||= 'Basset::Object';
__PACKAGE__->types->{'persistentobject'}	||= 'Basset::Object::Persistent';
__PACKAGE__->types->{'machine'}				||= 'Basset::Machine';
__PACKAGE__->types->{'state'}				||= 'Basset::Machine::State';
__PACKAGE__->types->{'test'}				||= 'Basset::Test';


=pod

=item restrictions

This stores the restrictions that B<could> be added to this class, but not necessarily the
ones that are in effect. Add new restrictions with the add_restriction method.

=cut

=pod

=begin btest(restrictions)

package Basset::Test::Testing::__PACKAGE__::restrictions::subclass1;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::restrictions::subclass1->isa('__PACKAGE__'), 'proper subclass');
my $restrictions = {
	'foo' => [
		'a' => 'b'
	]
};
$test->ok($restrictions, 'made restrictions');
$test->is(Basset::Test::Testing::__PACKAGE__::restrictions::subclass1->restrictions($restrictions), $restrictions, 'added restrictions');
$test->is(Basset::Test::Testing::__PACKAGE__::restrictions::subclass1->restrictions, $restrictions, 'accessed restrictions');

=end btest(restrictions)

=cut

__PACKAGE__->add_trickle_class_attr('restrictions');

=pod

=begin btest(applied_restrictions)

package Basset::Test::Testing::__PACKAGE__::applied_restrictions::Subclass;
our @ISA = qw(__PACKAGE__);

my %restrictions = (
	'specialerror' => [
		'error' => 'error3',
		'errcode' => 'errcode3'
	],
	'invalidrestriction' => [
		'junkymethod' => 'otherjunkymethod'
	]
);

__PACKAGE__->add_class_attr('e3');
__PACKAGE__->add_class_attr('c3');

$test->is(__PACKAGE__->e3(0), 0, "set e3 to 0");
$test->is(__PACKAGE__->c3(0), 0, "set c3 to 0");

sub error3 {
	my $self = shift;
	$self->e3($self->e3 + 1);
	return $self->SUPER::error(@_);
}

sub errcode3 {
	my $self = shift;
	$self->c3($self->c3 + 1);
	return $self->SUPER::errcode(@_);
}

$test->ok(scalar Basset::Test::Testing::__PACKAGE__::applied_restrictions::Subclass->add_restrictions(%restrictions), "Added restrictions to subclass");

package __PACKAGE__;

$test->ok(Basset::Test::Testing::__PACKAGE__::applied_restrictions::Subclass->isa('__PACKAGE__'), 'Proper subclass');
my $subclass = Basset::Test::Testing::__PACKAGE__::applied_restrictions::Subclass->restrict('specialerror');
$test->ok($subclass, "Restricted error");
$test->ok(! scalar $subclass->add_restricted_method('invalidrestriction', 'junkymethod'), "Could not add invalid restriction");
$test->ok($subclass->restricted, "Subclass is restricted");

$test->ok($subclass->applied_restrictions, "Subclass has applied restrictions");
my $restrictions = $subclass->applied_restrictions;

$test->ok(ref $restrictions eq 'ARRAY', 'applied restrictions are an array');
$test->is(scalar @$restrictions, 1, "Subclass has 1 restriction");
$test->is($restrictions->[0], 'specialerror', 'Correct restriction in place');

=end btest(applied_restrictions)

=cut

__PACKAGE__->add_trickle_class_attr('applied_restrictions', []);

=pod

=item restricted

Boolean flag. returns 0 if the class is non-restricted, or 1 if it is restricted.

=cut

=pod

=begin btest(restricted)

package Basset::Test::Testing::__PACKAGE__::restricted::Subclass1;
our @ISA = qw(__PACKAGE__);

package __PACKAGE__;

$test->ok(! __PACKAGE__->restricted, "__PACKAGE__ is not restricted");
$test->ok(! Basset::Test::Testing::__PACKAGE__::restricted::Subclass1->restricted, "Subclass is not restricted");
my $subclass = __PACKAGE__->inline_class;
$test->ok($subclass, "Subclassed __PACKAGE__");
my $subclass2 = Basset::Test::Testing::__PACKAGE__::restricted::Subclass1->inline_class();
$test->ok($subclass2, "Restricted Basset::Test::Testing::__PACKAGE__::restricted::Subclass1");
$test->ok($subclass->restricted, "Subclass is restricted");
$test->ok($subclass2->restricted, "Subclass is restricted");

=end btest(restricted)

=cut

__PACKAGE__->add_trickle_class_attr('restricted', 0);

=pod

=item exceptions

boolean flag 1/0. Off by default.  Some people, for some silly reason, like to use exceptions. 
Personally, I avoid them like the plague. Nonetheless, I'm an agreeable sort and wanted to provide
the option. Standard procedure is to call a method or bubble up an error:

 sub method {
 	my $self = shift;

 	my $obj = shift;

 	$obj->trysomething() or return $self->error($obj->errvals);
 }

methods return undef, so if the return is undefined, you bubble it back up until something can
handle it. With exceptions enabled, the error method (called somewhere inside $obj's trysomething
method) would instead die with an error of the errorcode passed. Additionally, the error itself
is set in the last_exception attribute. So you write your method call this way, if exceptions
are enabled:

 sub method {
 	my $self = shift;
 	my $obj = shift;

 	eval {
 		$obj->trysomething();
 	}
 	if ($@ =~ /interesting error code/) {
 		print "We died because of " . $obj->last_exception . "\n";
 	} else {
 		$obj->error($obj->errvals);#re-throw the exception
 	}
 }

Note that last_exception should be used to find out the error involved, not the ->error method. This
is because you can't know which object actually threw the exception.

=cut

=pod

=begin btest(exceptions)

my $confClass = __PACKAGE__->pkg_for_type('conf');
$test->ok($confClass, "Got conf");

my $cfg = $confClass->conf;
$test->ok($cfg, "Got configuration");

my $exceptions = $cfg->{"Basset::Object"}->{'exceptions'};

$test->is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0, "disables exceptions");
$test->is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0, "enables exceptions");
$test->is($cfg->{"Basset::Object"}->{'exceptions'} = $exceptions, $exceptions, "reset exceptions");

=end btest(exceptions)

=cut

__PACKAGE__->add_default_class_attr('exceptions');

=pod

=item last_exception

stores the message associated with the last exception

=cut

=pod

=begin btest(last_exception)

my $o = __PACKAGE__->new();
$test->ok($o, "Got object");

my $confClass = __PACKAGE__->pkg_for_type('conf');
$test->ok($confClass, "Got conf");

my $cfg = $confClass->conf;
$test->ok($cfg, "Got configuration");

$test->ok($cfg->{"Basset::Object"}->{'exceptions'} = 1, "enables exceptions");

$test->ok(scalar __PACKAGE__->wipe_errors, "Wiped out errors");
$test->ok(! __PACKAGE__->last_exception, "Last exception is empty");
eval {
	__PACKAGE__->error('test exception', 'test code');
};
$test->like($@, "/test code/", "Thrown exception matches");
$test->like(__PACKAGE__->last_exception, qr/test exception/, "Last exception matches");
$test->like($o->last_exception, qr/test exception/, "Object last exception matches");
$test->is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0,"disables exceptions");

=end btest(last_exception)

=cut

__PACKAGE__->add_class_attr('last_exception');

=pod

=back

=cut

1;
__END__

=head1 SEE ALSO

Basset::Object::Conf, Basset::Object::Persistent

=head1 COPYRIGHT (again) and license

Copyright and (c) 1999, 2000, 2002, 2003, 2004, 2005 James A Thomason III (jim@jimandkoka.com). All rights reserved.

Basset is distributed under the terms of the Artistic License.

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim@jimandkoka.com) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

=cut
