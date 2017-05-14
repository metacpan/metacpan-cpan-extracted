# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

package Class::Maker;

	require 5.005_62; use strict; use warnings;
	
	no warnings 'once';

	our $VERSION = "0.06";
	
	use Class::Maker::Basic::Handler::Attributes;
	
	use Class::Maker::Basic::Fields;

	use Carp qw(cluck);
	
	use Exporter;
	
	use subs qw(class);
	
	our $DEBUG = 0;
	
	our $TRACE = ( \*STDOUT, \*STDERR )[ ($ENV{CLASSMAKER_TRACE}||2) - 1 ];
	
	our %EXPORT_TAGS = ( 'all' => [ qw(class) ] );
	
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	
	our @EXPORT = ();
	
	our @ISA = qw( Exporter );
	
	our $pkg = '<undefined class>';
	
	our $cpkg = $pkg;
	
	our $explicit = 0;
	
	# Preloaded methods go here.
	
	sub import
	{
		Class::Maker->export_to_level( 1, @_ );
	}
	
	sub class
	{
		class_import( scalar caller, @_ );
	}
	
	sub class_import
	{
			# $class is the caller package
	
		my ( $class, @args ) = @_;
	
		return unless @args;
	
			# construct the destination package for the classes:
			#
			#	- we create the class within the current package (default)
			#	- or create it in the current package
			#	- or when starting with 'main::' or '::' we create it with the main package
	
		unless( ref $args[0]  )
		{	
			if( $args[0] =~ /^[\.\*]/ )
			  {		
			    $args[0] =~ s/^[\.\*]//;

			    $pkg = $class.'::'.$args[0];

			    print $Class::Maker::TRACE "Class::Maker *DEBUG*: DETECTED '.' IN CLASS NAME - CREATING CLASS IN SUBPACKAGE: $pkg" if $DEBUG;
			  }
			else
			  {
			    $pkg = ( $args[0] =~ s/^(?:main)?::// ) ? $args[0] : $class.'::'.$args[0];
			  }
		}
		else
		{
				# We had no explicit destination package, so create the class in the current package
	
			$pkg = $class;
		}
	
			#remember caller package
	
		$cpkg = $class;
	
			# init class 'cause somebody could give an empty parameter
			# list for abstract classes
	
		Class::Maker::Basic::Fields::isa( [] );
	
		Class::Maker::Basic::Fields::configure( { ctor => 'new', dtor => 'delete' } );
	
		foreach my $arg ( @args )
		{
			if( ref($arg) eq 'HASH' )
			{
				no strict 'refs';
	
				Class::Maker::Reflection::install( $arg );
	
				foreach my $func ( sort { $b cmp $a } keys %$arg )
				{
						# fields for the class attributes/isa/configure/..
	
					"Class::Maker::Basic::Fields::${func}"->( $arg->{$func}, $arg );
				}
			}
		}
	}
	
	sub _make_method
	{
		no strict 'refs';
	
		my $type = shift;
	
		my $name = shift;
	
			$Class::Maker::Basic::Handler::Attributes::name = $explicit ? "${pkg}::$name" : $name;
	
			no strict 'refs';
	
			if( *{ "Class::Maker::Basic::Handler::Attributes::${type}" }{CODE} )
			{
				return *{ "${pkg}::$name" } = Class::Maker::Basic::Handler::Attributes->$type;
			}
	
	return *{ "${pkg}::$name" } = Class::Maker::Basic::Handler::Attributes->default;
	}

#
# Reflection
#

package Class::Maker::Reflex;		# returned by Class::Maker::Reflection::reflect

	no warnings 'once';

	sub definition : method
	{
		my $this = shift;

	return $this->{def};
	}
	
	sub parents : method
	{
		my $this = shift;

		return unless exists $this->{isa};	
				
	return Class::Maker::Reflection::inheritance_isa( @{ $this->{isa} } );
	}

package Class::Maker::Reflection;

	no warnings 'once';

	our $DEBUG = $Class::Maker::DEBUG;

	use Data::Dump qw(dump);

        sub DEBUG : lvalue { $DEBUG }
	
	
		# DEEP : Whether reflect should traverse the @ISA tree and return all parent reflex's
	
	our $DEEP = 0;
	
	our $DEFINITION = 'CLASS';
	
	sub _get_definition
	{
		my $class = shift;
	
			no warnings;
	
			no strict 'refs';
	
	return \${ "${class}::".$Class::Maker::Reflection::DEFINITION };
	}
	
	sub _get_isa
	{
		no strict 'refs';
	
	return @{ $_[0].'::ISA'};
	}
	
	sub install
	{
		${ Class::Maker::Reflection::_get_definition( $pkg ) } = $_[0];
	}
	
	sub reflect
	{
		my $class = ref( $_[0] ) || $_[0] || die;
	
			my $rfx = bless {  name => $class  }, 'Class::Maker::Reflex';
	
				# - First get the "${$DEFINITION}" href containing the class definition
				# - find the functions of that class declerated with ': method'
				# - catch up the parent class reflection if DEEP is activated
				# - update "${$DEFINITION}"->{isa} with its real @ISA
	
			$rfx->{def} = ${ Class::Maker::Reflection::_get_definition( $class ) };
	
			$rfx->{methods} = find_methods( $rfx->{name} );
	
			no strict 'refs';
	
			if( $DEEP && defined *{ "${class}::ISA" }{ARRAY} )
			{
				$rfx->{isa} = \@{ *{ "${class}::ISA" }{ARRAY} };
	
				$rfx->{parents}->{$_} = reflect( $_ ) for @{ $rfx->{isa} };
			}
	
	return $rfx;
	}
	
	sub classes
	{
		no strict 'refs';
	
		my @found;
	
		my $path = shift if @_ > 1;
	
		foreach my $pkg ( @_ )
		{
			next unless $pkg =~ /::$/;
	
			$path .= $pkg;
	
			if( $path =~ /(.*)::$/ )
			{
				my $clean_path = $1;
	
				if( $path ne 'main::' )
				{
					if( my $href_cls = reflect( $clean_path ) )
					{
						push @found, { $clean_path => $href_cls };
					}
				}
	
				foreach my $symbol ( sort keys %{$path} )
				{
					if( $symbol =~ /::$/ && $symbol ne 'main::' )
					{
						push @found,  classes( $path, $symbol );
					}
				}
			}
		}
	
	return @found;
	}
	
	use attributes;
	
	sub find_methods
	{
		my $class = shift;
	
			my $methods = [];
	
			no strict 'refs';
	
			foreach my $pkg ( $class.'::' )
			{
				foreach ( sort keys %{$pkg} )
				{
					unless( /::$/ )
					{
						if( defined *{ "$pkg$_" }{CODE} )
						{
							if( my $type = attributes::get( \&{ "$pkg$_" } ) )
							{
								push @$methods, "$_" if $type =~ /method/i;
							}
						}
					}
				}
			}
	
	return $methods;
	}

#    my @obj = @{ Class::Maker::Reflection::find_object_in_namespace_that_isa( main => [qw( NotExisting ) ], 'Parse::Grammar::POQL::TestShopping' => [ 'Person', 'Shopping::Cart' ] )->{objects} };
	
	sub find
	{
		my %request = @_;

		my $result_report = {};

		my @result;
	
				# parsing all references in a package (via symbol table)
	
			while( my ( $where, $what ) = each %request )
			{
				no strict 'refs';
	
				foreach my $pkg ( $where.'::' )
				{
				    printf $Class::Maker::TRACE "Searching in package '$where' for '%s' instances\n", Data::Dump::dump($what) if DEBUG;
	
					foreach ( sort keys %{$pkg} )
					{
						unless( /::$/ )
						{
						    print $Class::Maker::TRACE defined *{ "$pkg$_" } ? "PKG: " : "" if DEBUG;			    
						    print $Class::Maker::TRACE "$pkg$_\n" if DEBUG;

							if( defined *{ "$pkg$_" } )
							{
								my $sref = \${ "$pkg$_" };
	
								if( ref( $sref ) eq 'REF' )
								{
								    print $Class::Maker::TRACE "\tREF: $pkg$_\n" if DEBUG;

									my $type = ref( $$sref );

								    if( Class::Maker::Reflection::inheritance_isa( $type ) )
								    {
									print $Class::Maker::TRACE "\tISA: ", Data::Dump::dump( Class::Maker::Reflection::inheritance_isa( $type ) ), "\n" if DEBUG;

									print $Class::Maker::TRACE "\tDUMP: ", Data::Dump::dump( $$sref ), "\n" if DEBUG;
								    }

									print $Class::Maker::TRACE "\n" if DEBUG;

								    for my $isa_maybe ( @$what )
								    {
									printf $Class::Maker::TRACE "** GRABBED ABOVE OBJECT **\n\n\n" if $$sref->isa( $isa_maybe ) && DEBUG;
									
									if( $$sref->isa( $isa_maybe ) )
									{
									    push @{ $result_report->{alpha} }, "$pkg$_";

									    push @{ $result_report->{objects} }, $$sref;
									}
								    }
								}
							}
						}
					}
				}
			}
	
	return $result_report;
	}




	
		# helpers
	
	sub _isa_tree
	{
		my $list = shift;
	
		my $level = shift;
	
		for my $child ( @_ )
		{
			my @parents = Class::Maker::Reflection::_get_isa( $child );
	
			$level++;
	
			push @{ $list->{$level} }, $child;
	
			warn sprintf "\@%s::ISA = qw(%s);",$child , join( ' ', @parents ) if $Class::Maker::DEBUG;
	
			_isa_tree( $list, $level, @parents );
	
			$level--;
		}
	}
	
		# returns the isa tree sorted by level of recursion
	
		# 5 -> Exporter
		# 4 -> Object::Debugable
		# 3 -> Person, Exporter
		# 2 -> Employee, Exporter, Object::Debugable
		# 1 -> Doctor
	
	sub isa_tree
	{
		my $list = {};
	
		_isa_tree( $list, 0, @_ );
	
	return $list;
	}
	
		# returns the isa tree in a planar list (for con-/destructor queue's)
	
	sub inheritance_isa
	{
		warn sprintf "SCANNING ISA FOR (%s);", join( ', ', @_ ) if $Class::Maker::DEBUG;
	
		my $construct_list = isa_tree( @_ );
	
		my @ALL;
	
		foreach my $level ( sort { $b <=> $a } keys %$construct_list )
		{
			push @ALL, @{ $construct_list->{$level} };
		}
	
	return \@ALL;
	}

1;

__END__

=head1 NAME

Class::Maker - classes, reflection, schemas, serialization, attribute- and multiple inheritance

=head1 SYNOPSIS

  use Class::Maker qw(:all);

  class Something;

  class Person,
  {
     isa => [ 'Something' ],

     public =>
     {
       scalar => [qw( name age internal )],
     },

     private
     {
       int => [qw( internal )],
     },
  };

  sub Person::hello
  {
    my $this = shift;

    $this->_internal( 2123 ); # the private one

    printf "Here is %s and i am %d years old.\n",  $this->name, $this->age;
  };

  my $p = Person->new( name => Murat, age => 27 );

  $p->hello;


=head1 DESCRIPTION

This package is for everybody who wants to program oo-perl and does not really feel comfortable with the common way. Class::Maker introduces the concept of classes via a "class" function. It automatically creates packages, ISA, new and attribute-handlers. The classes can inherit from common perl-classes and class-maker classes. Single and multiple inheritance is supported.

Reflection is transparently implemented and allows one to inspect the class properties and methods during runtime. This is  helpfull for implementing persistance and serialization. A Tangram (see cpan) schema generator is included to the package, so one can use Tangram object-persistance on the fly as long as he uses Class::Maker classes.

=head1 INTRODUCTION

When you want to program oo-perl, mostly you suffer under the flexibility of perl. It is so flexibel, you have to do alot by hand. Here an example (slightly modified) from perltoot perl documentation for demonstration:

 package Person;

 @ISA = qw(Something);

 sub new {
    my $self  = {};
    $self->{NAME}   = undef;
    $self->{AGE}    = undef;
    bless($self);           # but see below
    return $self;
 }

 sub name {
    my $self = shift;
    if (@_) { $self->{NAME} = shift }
    return $self->{NAME};
 }

 sub age {
    my $self = shift;
    if (@_) { $self->{AGE} = shift }
    return $self->{AGE};
 }

C++ has really straightforward class decleration style. It looks really beautiful. At that time many cpan modules tried to compensate with perl idiom, i still rather missed something. This package though has a "class" function which transparetly decleares perl classes with some rememberance to other languages. It smoothly integrates into perl code and handles may issues a beginner would immediately stumble (such as package issues etc). So the above example could be now written as:

 use Class::Maker qw(class);

 class 'Person',
 {
   isa => [ 'SomeBaseClass' ],

   public =>
   {
     scalar => [qw( name age )],
   },
 };

When using "class", you do not explictly need "package". The function does all symbol creation for you. It is more a class decleration (like in java/cpp/..). So here we now leap into the documentation.

=head1 FUNCTIONS

=head2 class()

The 'class' function is very central to Class::Maker. 

 class 'Class',
 {
   ..FIELDS..
 };

[Note] The parantheses for the class() function are optional.

Here 'Class' is the Name for the class. It is also the name for the package where the symbols for the class are created. Examples: 'Animal', 'Animal::Spider', 'Histology::Structures::Epithelia'.

Normally the class is created related to the main package:

  package Far::Far::Away;

  class 'Galaxy',
  {
  };

Like with B<package> 'Galaxy' would become to 'main::Galaxy' (and not Far::Far::Away::Galaxy).

=head2 FIELDS

Fields are the keys in the hashref given as the second (or first if the first argument (classname) is omitted) argument to "class". Here are the basic fields (for adding new fields read the Class::Maker::Basic::Fields).

=head3 isa => aref

Same as the @ISA array in an package (see perltoot). 

Some short-cut syntax is available:

a) when the name is started with an '.' or '*' the package name is extrapolated to that name:

 package Far::Far::Away;

 class Galaxy,
 {
   isa => [qw( .AnotherGalaxy )],
 };

Then '.AnotherGalaxy' becomes expanded to 'Far::Far::Away::AnotherGalaxy'.

=head3 public => href
 
 public => 
 {
   int => [qw(id)],
 },

leads to a attribute-handler which can be used like:

 $obj->id( 123 );

 my $value = $obj->id;

Because the default handler is an lvalue function, the following call is also valid:

 $obj->id = 5678;


These keys are 'type-identifiers' (no fear, its simple), which help you to sort things. In general these are used to create handlers for the type. It is somehow like the get/set like method functions to access class-properties, but its more generalized and not so restrictive. By default, every non-known type-identifier is a simple scalar handler. Class::Maker will not warn you at any point, if you use a unknown type-identifier. So that

   public =>
   {
    scalar => ...
    array => ...
    hash => ...

    _anthing_here_ => ..    
   }

Because b<array> and b<hash> are internally decleared and creating special mutators/handlers they will be not create scalar handlers, 
but 'scalar' and '_anything_here' will create scalara mutators, as they are forwarded to the default scalar handlers; both are internally not explicitly defined. 
The mechanism is extendable, see L<Class::Maker::Basic::Fields>.

=head3 private => href

All properties in the 'private' section, get a '_' prepended to their names.

 private =>
 {
   int => [qw(uid gid)],
 },

So you must access 'uid' with $obj->_uid();

 public =>
 {
   int => [qw(uid gid)],

   string => [qw(name lastname)],

   ref => [qw(father mother)],

   array => [qw(friends)],

   custom => [qw(anything)],
 },

Nothing more, nothing less. The significant part is that no encapsulation as such is present (as in cpp). The only encapsulation is the "secret" that
you have to prepend and '_' in front of the name.

=head3 configure => href

This Field is for general options. Basicly following options are supported:

a) new: The name of the default constructor is 'new'. With this option you can change the name to something of your choice. For instance:

 configure => 
 {
   new => 'connect'
 },

Could be used for database objects. So you would use

 my $obj AnyClass->connect( );

to create an AnyClass object.

PS. Class::Maker provides a very sophisticated default constructor that does a lot (including the inhertance issues) and is explained somewhere else.

c) I<private>: Prefix string (default '_') for private functions can be changed with this.

 private =>
 {
   int => [qw(dummy1)],
 },
 
 configure =>
 {
   private => { prefix => '__' },
 },

would force to access 'dummy1' via ->__dummy1().

=head3 automethod

Reserved.

=head3 has

Reserved. Is planned to be used for 'has a' relationships.

=head3 default => href

Give default values for class attributes. It is the same as the handler was called with the value within the L<_postinit> function.

 default =>
 {
   name => 'John',

   friends => [qw(Petra Jenna)],
 },

So after construction the CLASS->name method would return 'John' etc.

=head3 version => scalar

Give the class/objects a version number. Internally the $VERSION is set to that value.

=head3 persistance => href

Here you can set options and add information for the reflect-function. You can also add custom information, you may want to process when you reflect objects.

For example the tangram-schema generator looks for an 'abstract' key, to handle this class as an abstract class:

 persistance =>
 {
   abstract => 1,
 },

You can read more about Persistance under the L<Class::Maker::Extension::Persistance> manpage.

=head1 Global flags

=head2 $Class::Maker::explicit

Internally an instance of a class holds all properties/attributes in an hash (The object is blessed with a hash-ref). The keys are normally 
exactly the same as you declare in the descriptors. In special cases you want inheritance per se, but still might be interested to call parent methods explicitly. Put another way,
when you use 'soft' inheritance, you may have name clashes if a parent object uses the same name for a property as its child.
To compensate that problem, set this global (very early in your program, best is BEGIN block) explicit to something true (i.e. 1). This will lead to internal prepending of the classname to the key name:

BEGIN
  {
	$Class::Maker::explicit = 1;
  }

'A' inherits 'B'. Both have a 'name' property. With explicit internally the fields are distinct:

 A::name
 B::name

[Note] This does not collide with attribute-overloading/inheritance ! Because the first attribute-handler in the isa-tree is always called. You do not have to care for this. Only use this feature, if you have fear that name clashes could appear, beside overloading. Per default it is turned off, because i suppose that most class designers care for name clashes themselfs.

=head1 INTERNALS

For this example:

 class 'Person',
 {
   isa => [ 'SomeBaseClass' ],

   public =>
   {
     scalar => [qw( name age )],
   },
 };

Following happens in the background, when using 'class':

=over 4

=item 1. 
creates a package "Person".

=item 2. 
sets @Person::ISA to the [ 'SomeBaseClass' ].

=item 3.
creates method handlers for the attributes (including lvalue methods).
While "hash" and "array" keys are really functional keywords, any other
key will simply result in a scalar get/set method.

=back

=item 4.
exports a default constructor (i.e."Person::new()") which handles argument initialization.
It has also a mechanism for initializing the parent objects (including MI).

=item 5.
creates $Person::CLASS holding a hashref to the unmodified second argument to 'class' (or the first, if the package name is omitted). This is essential for reflection: i.e. you can get runtime information about the class. See below. 

=back

=back

=head1 USING AN CLASS/OBJECT

=head2 CONSTRUCTION

Once a class is created it is shipped with a versatile C<new()> constructor. It is central to L<Class::Maker> because it deploy the object correctly, including constructing the multiple-inheritance chain and presetting class fields. To have fine grained control over the construction process following special methods are available for modification during construction. See the L<Class::Maker::Basic::Constructor> deeper explanation of the construction process.

=head2 METHODS

=head2 DESTRUCTION

=head1 RESERVED SYMBOLS

=head2 %CLASS

As said, once a class is created L<Class::Maker> creates a C<CLASS> hash into the package. It is required for the process of runtime introspection (reflection). In general it is mostly similar to the L<FIELDS> hash during decleration, but one shouldnt count on that, because it is surely modified in future. Refer to the L<Class::Maker::Basic::Reflection> for correctly access the introspective freatures. Although today it has the function to:

=over 4

=item -
have dependency/class walking (see the contrib/ directory of the distribution for an example script).

=item -
creating on-the-fly persistance => (for an example with Tangram see below)

=item -
it creates the complete tangram schema tree (Tangram users know how hard it is

=head1 PERFORMANCE

I never seriously benchmarked Class::Maker. Because the internal representation is just the same as for standard perl-classes, only a minimal delay in the constructor (during scan through the class hirarchy for _init() routines) should be apparent. Beware that the accessors for any member of course delay the processsing (wildly guessed to be 3x slower). There is a hack-ish way to circumvent this, and may, increase speed when required:
	- directly going into the object gut with $this->{member}. Beware that the member can be hidden as ->{SUPERCLASS::member}.

=head1 EXAMPLES

All test files (test.pl and t/) are verbose enough for a good overview. Visit the Class::Maker::Examples manpage for examples how to write basic data-type-like classes and basic classes used for i.e. e-commerce applications.

=head1 EXPORT

facultative: qw(reflect schema)
obligate:	qw(class)

class by default. 

[Note] If you care about ns pollution, just use Class::Maker::class directly.

Class::Maker::class 'Person',
{
  ...
};

=head1 KNOWN BUGS/PROBLEMS

isa => [qw( )] isnt in sync with @ISA. When @ISA (or isa) is modified after initation, the $reflex->{isa} will only represent the state during object initiation.

<& /maslib/signatures.mas:author_as_pod,  &>

Contributions (Ideas or Code):

	- Terrence Brannon

=head1 COPYRIGHT

(c) 2001 by Murat Uenalan. All rights reserved.
Note: This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::Maker::Exception>, L<Class::Maker::Basic::Fields>, L<Class::Maker::Basic::Reflection>, L<Class::Maker::Basic::Handler::Attributes>,L<Class::Maker::Basic::Types>,L<Class::Maker::Examples>, L<Class::Maker::Generator>, L<Class::Maker::Extension::Schema::Tangram>.

=head1 Search for Class::Maker::* at CPAN

Also at CPAN: Class::*, Tangram

=head1 LITERATURE

[1] Object-oriented Perl, Damian Conway
[2] Perl Cookbook, Nathan Torkington et al.

=cut
