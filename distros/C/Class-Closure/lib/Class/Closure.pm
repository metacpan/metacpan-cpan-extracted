use 5.006; use warnings; use strict;

package Class::Closure;
our $VERSION = '0.303';

use Exporter ();
use Carp ();
use Symbol ();

our @EXPORT = qw(
	has
	public
	method
	accessor
	extends
	does
	destroy
);

our $PACKAGE;
our $EXTENDS;

sub import { _make_new( scalar caller ); goto &Exporter::import }

sub _install ($$) {
	my ( $name, $thing ) = @_;
	no strict 'refs';
	*{ "$PACKAGE\::$name" } = $thing;
}

sub _make_new {
	my ( $pkg ) = @_;

	$PACKAGE = $pkg;
	_install new => sub {
		my $base = ref $_[0] || $_[0];
		local $PACKAGE = my $package = _make_package();

		_install ISA => [ $base ];

		my ( @reblessed, @subisa, %subobj );

		_install DESTROY => sub {
			bless $_->[0], $_->[1] for @reblessed; # bless them back into their original class
			Symbol::delete_package( $package );
		};

		_install isa => sub {
			my ( $self, $class ) = @_;
			do { return 1 if $base->isa( $class ) };
			do { return 1 if $_->isa( $class ) } for @subisa;
			return;
		};

		local $EXTENDS = sub {
			my ( $var ) = @_;

			$var = $var->new if not ref $var;

			my $pkg = ref $var;
			bless $var, $PACKAGE;  # Rebless for virtual behavior

			push @reblessed, [ $var, $pkg ];  # bookkeeping for DESTROY

			push @subisa, $pkg;
			$subobj{ $pkg } = $var;

			return;
		};

		_install can => sub {
			my ( $self, $method ) = @_;

			my $code = do { no strict 'refs'; *{ "$package\::$method" }{'CODE'} };
			return $code if $code;

			for my $pkg ( @subisa ) {
				my $obj = $subobj{ $pkg };
				$code = $pkg->can( $method ) or next;
				my $delegate = sub {
					splice @_, 0, 1, $obj;
					goto &$code;
				};
				{ no strict 'refs'; *{ "$package\::$method" } = $delegate };
				return $delegate;
			}

			return;
		};

		_install AUTOLOAD => sub {
			our $AUTOLOAD =~ s/.*:://;
			if ( my $code = $_[0]->can( $AUTOLOAD ) ) {
				goto &$code;
			}
			elsif ( my $fallback = $_[0]->can( 'FALLBACK' ) ) {
				no strict 'refs';
				local *{ "$base\::AUTOLOAD" } = \$AUTOLOAD;
				goto &$fallback;
			}
			else {
				Carp::croak "Method $AUTOLOAD not found in class $base";
			}
		};

		$pkg->can( 'CLASS' )->( @_ );

		my $self = bless {}, $PACKAGE;

		$self->BUILD( @_[ 1 .. $#_ ] ) if $self->can( 'BUILD' );

		$self;
	};
}

{
my $counter = 0;
sub _make_package {
	"Class::Closure::_package_" . $counter++;
}
}

sub _find_name {
	my ( $var, $code ) = @_;
	require PadWalker;
	my %names = reverse %{ PadWalker::peek_sub( $code ) };
	my $name = $names{ $var } || Carp::croak "Couldn't find lexical name for $var";
	$name =~ s/^[\$\@%]//;
	$name;
}

sub has (\$) : lvalue {
	my ( $var ) = @_;

	require Devel::Caller;
	my $name = _find_name $var, Devel::Caller::caller_cv(1);

	_install $name, sub { $$var };
	$$var;
}

sub public (\$) : lvalue {
	my ( $var ) = @_;

	require Devel::Caller;
	my $name = _find_name $var, Devel::Caller::caller_cv(1);

	_install $name, sub : lvalue { $$var };
	$$var;
}

sub method ($&) {
	&_install;
	return;
}

sub accessor ($@) {
	my ( $name, %arg ) = @_;
	Carp::croak "accessor needs 'get' and 'set' attributes" unless $arg{'get'} && $arg{'set'};
	require Sentinel;
	_install $name, sub : lvalue {
		my $self = shift;
		Sentinel::sentinel(
			get => sub { $arg{'get'}->( $self ) },
			set => sub { $arg{'set'}->( $self, @_ ) },
		);
	};
	return;
}

sub extends($) { &$EXTENDS }

sub destroy(&) { _install DESTROY => \Class::Closure::DestroyDelegate->new( $_[0] ) }

package Class::Closure::DestroyDelegate;
our $VERSION = '0.303';

sub new { bless $_[1] }
sub DESTROY { goto &{$_[0]} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Closure - Encapsulated, declarative class style

=head1 SYNOPSIS

 package Dog;

 use Class::Closure;

 sub CLASS {
     extends Foo::Bar;           # Inherit from another class

     extends $some_object;       # Inherit from a single object (classless)

     my $hungry;                 # private

     has my $face;               # read-only

     public my $leash;           # public

     accessor 'food',            # magical variable-like function
         get => sub { 'None' },
         set => sub { $hungry = 0; };

     method bark => sub { print "Woof!" };   # method (note the semicolon)

     method BUILD => sub { print "A new dog is born" };  # constructor

     destroy { print "Short is the life of a dog" };  # destructor

     method FALLBACK => sub { print "Handling $AUTOLOAD" };
 }

 my $fido = Dog->new;   # "A new dog is born"
 $fido->face;           # Get a read-only attribute
 $fido->leash = 'red';  # public attributes look like variables
 $fido->food = 20;      # This calls the food set accessor

=head1 DESCRIPTION

Class::Closure is a package that makes creating Perl classes less
cumbersome. You can think of it as a more featureful Class::Struct.

To declare a class using Class::Closure, enter a new package, use
Class::Closure, and define a sub called CLASS. Inside this sub will lie
the declarations for the attributes and methods (and subclasses) for
this class.

=head2 Variables

To declare variables, mark them as lexicals within the sub. You may prefix
them with C<has> to make them read-only or C<public> to make them fully
read-write public.

 sub CLASS {
     my $x;             # private
     has my $y;         # read-only
     public my $z;      # public
 }

As of the moment, C<has> and C<public> only support scalar variables.

You can give the variables a default value by assigning to the whole
declaration. For simple private variables this is easy; for read-only
and public variables, it requires extra parentheses:

 sub CLASS {
     my $x         = 1;
     has(my $y)    = 2;
     public(my $z) = 3;
 }

To use these variables within the class, use their plain lexical name
with the sigil. To use them outside the class, call them as methods.
Given the class above:

 $obj->x;      # Illegal; private
 $obj->y;      # Ok, 2.
 $obj->z;      # Ok, 3.
 $obj->z = 32; # Write to $z.

This may be a little different from the usual C<< $obj->z(32) >> syntax
you might be used to. Trust me, this will grow on you.

=head2 Methods

To declare methods, use the C<method> keyword and pass a name and a
reference to a sub:

 sub CLASS {
     method bark => sub {
         print "Woof!\n";
     };
 }

The invocant is still passed in as the first argument as in old-style
OO. The fact is, though, that many times you won't need it, since you
can reference the member variables without it. You still need it to
call functions on yourself, though.

 sub CLASS {
     method chase_tail => sub {
         my ($self) = @_;
         $self->chase($self->find_tail);
     };
 }

=head2 Accessors

Sometimes a change of interface goes from using a public variable to a
function with extra behavior. Some would say that's why you never make
a member variable public. I disagree, since you can just fake one with
the C<accessor> keyword:

 sub CLASS {
     accessor 'number',
             get { print "Getting the number";  42; },
             set { print "Setting the number";  $_[0]->send($_[1]) };
 }
 print $obj->number;  # "Getting the number"  "42"
 $obj->number = 314;  # "Setting the number" ...

=head2 Inheritance

Unlike the standard Perl 5 object model, Class::Closure can inherit from both
classes and variables (like Class::Classless). Also, it keeps their respective
namespaces separate, so they don't accidentally stomp on each other's member
variables, even if they're implemented with the standard object model.

To inherit, use the C<extends> keyword. It can take as an argument either a
class name (make sure you quote it lest you confuse Perl) or an object. If you
need to pass construction parameters to your superclass, just inherit from it
as an object:

 sub CLASS {
     extends MySuperClass->new(@params);
 }

=head2 Constructors and Destructors

The special method BUILD is called whenever a new object is created, with the
blessed object in the first argument and the rest of the construction
parameters in the remaining arguments.

Destructors are a little different. Because of the magic that Class::Closure
has to do to get them to work with inheritance, they have a special syntax:

 sub CLASS {
     destroy { print "Destructing object"; }
 }

Yep, that's all. And you heard me correctly, they work right with inheritance,
unlike the standard C<DESTROY> method.

=head2 FALLBACK

Class::Closure supports an C<AUTOLOAD> feature. But because it uses
C<AUTOLOAD> internally, it has to call it something else. It's called
C<FALLBACK>, and it works just like C<AUTOLOAD> in every way (the name of the
current sub is still even in C<$AUTOLOAD>).

=head2 How does it work?

If you really want to get scary power out of this module, you have to
understand how it works.

The C<CLASS> sub that you defined in your package is actually called
every time an object is created. That's right, so there's no need for a
C<BUILD> at all (but it makes things look cleaner). Class::Closure
exports each one of these "keywords" into your namespace, and they are
used right on the spot to construct the object each time.

Each object's member hash is actually a lexical scratchpad, and it keeps
track of where it is, so you don't have to reference C<$self> all the
time. It has the added plus that each object in an inheritance
heirarchy has it's own scratchpad, so you don't get variable name
conflicts.

In more detail, when you call C<new> on your package, it derives a new
anonymous package for only that object. Then when you use C<method> (or
C<has> or C<public> or C<attribute>, which are really just wrappers
around the same thing), it installs the sub you give into that symbol
table position. These closure's aren't "cloned", but just referenced,
so this doesn't take up the horrible amount of memory you might be
thinking it does.

Then when all references to the object disappear, it uses L<Symbol>'s
C<delete_package> to clean out the anonymous package and free memory (and more
importantly, call C<DESTROY>s) associated with the object.

What does this all mean for you, the user? Since you understand that these
"declarations" are just sub calls at object construction time, you can create
your objects based on a dynamic template:

 sub CLASS {
     my ($class, $mode) = @_;

     if ($mode == 1) {
         method foo => sub { ... };
         method bar => sub { ... };
     }
     else {
         method foo => sub { ... };
         method bar => sub { ... };
     }
 }

That avoids a run-time check on each of the method calls, and makes
things a little easier to read. There's all kinds of other fun stuff
you can do.

=head2 Technical Notes / Bugs / Caveats / Etc.

Included in the distribution is a F<benchmark.pl> script which will test
various aspects of Class::Closure objects against objects created with
the traditional object model. In general, Class::Closure is quite a bit
faster for plain method calls (the extra hash lookup for each attribute
is more overhead than you'd think), but is slower for inherited methods
and I<much> slower for object creation. So it's not good to use
Class::Closure for small, intermediate objects if you're worried about
speed. Fortunately, Perl programs tend not to use these sorts of
objects often.

C<accessor>-like subs with arguments aren't yet supported, but there's
nothing in the design that says they aren't allowed. I'm just lazy, and
I'll happily add them upon request.

You might get in trouble if you try to define method names the same as
the exported keyword names.

There are certainly more bugs, since this is complex, subtle, scary
code. Bug reports/patches welcome.

=head1 SEE ALSO

L<Class::Struct>, L<Class::Classless>

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

Documentation by Luke Palmer.

=head1 COPYRIGHT AND LICENSE

This documentation is copyright (c) 2004 by Luke Palmer.

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
