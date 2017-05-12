package Class::Void;
use strict;
use warnings;
use vars qw($VERSION $Nothin $new); 
$VERSION = 0.05;

use overload q("")     => sub { "" },  # stringify to the empty string (returning undef is poised to create warnings)
            "nomethod" => sub { shift->new }; # call new for all other overloadable operators

$new = sub {
# private sub so my name space doesnt get polluted which anything that could stop the AUTOLOAD sub from executing
	my $scalar;            # allocate an empty scalar
	bless \$scalar, shift; # bless it into the calling package, and return it
};

sub new {
	$Nothin = $new->(shift) unless defined $Nothin; # define $Nothin once
	return $Nothin;
}

sub can {
	my $class   = shift;
	sub { $class->new }
}

sub AUTOLOAD { shift->new };

sub DESTROY  {}; # autoloading DESTROY would lead to an infinite loop because it'd create
                 # a new object which in turn calls destroy immediately and so on
               
q<I ain't seen nothin>

__END__

=head1 NAME

Class::Void - A class that stringifies to nothing for whatever you do with it

=head1 SYNOPSIS
	use Class::Void;
  
	my $object = Class::Void->new;
  
	$object->foo->bar("baz")->foo;
	print $object->employees("bob_smith")->age;
	print $object->bla("test")->foo->bar->baz * 2 / 2 * $object ** 8;

	if(my $coderef = $object->can("sleep")) {
		$coderef->()
	}

	package Foo;
	use base "Class::Void";
	sub new {
		my $class = shift;
		bless {}, $class;
	}


=head1 DESCRIPTION

All method calls against this class or one of its instances return
another instance of the class. The behavior is the same for operations
against its instances. Stringification returns the empty string which means
you can do pretty much everything with this module, in the end you always
get nothing.

=head2 Exceptions

Did I use words like everything, always and all? Well, here are the exceptions:
Methods defined in UNIVERSAL are not overridden, because these methods should
have a common behavior for all classes. This means that your Class::Void objects
will return true for $object->isa("Class::Void").

B<can> is special. It always returns a coderef to a function which has the typical 
behavior of methods defined in C<Class::Void>.

=head2 Subclassing

You may subclass C<Class::Void>. This might be especially useful to give
some meaning to the objects internals by overriding "new" with a method
that returns some kind of blessed reference other than a scalar.

=head1 "Why the hell would I need that?"

Everytime you have some class which isn't quite finished or which doesnt
provide a way to quietly do nothing, you can use this module as a stub
or a plug for the hole. Replacing objects of this class with objects
of another class can change a web page to change data to a page for new
entries in seconds. Another suggested use is to plug dead ends in a tree 
with something which doesn't die on method calls but which doesn't take much 
memory, either.

I'd be very interested in other uses, so please drop me a mail if you did
something fancy with this module.

=head1 BUGS

Using this module might be a bug :-) 

=head1 COPYRIGHT

Copyright 2000-2001 Malte Ubl <ubl@schaffhausen.de> All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut