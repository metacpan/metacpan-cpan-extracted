package Aspect::Point;

=pod

=head1 NAME

Aspect::Point - The Join Point context

=head1 SYNOPSIS

  # An anonymous function suitable for use as advice code
  # across all advice types (as it uses no limited access methods)
  my $advice_code = sub {
      print $_->type;           # The advice type ('before')
      print $_->pointcut;       # The matching pointcut ($pointcut)
      print $_->enclosing;      # Access cflow pointcut advice context
      print $_->sub_name;       # The full package_name::sub_name
      print $_->package_name;   # The package name ('Person')
      print $_->short_name;     # The sub name (a get or set method)
      print $_->self;           # 1st parameter to the matching sub
      print ($_->args)[1];      # 2nd parameter to the matching sub
      $_->original->( x => 3 ); # Call matched sub independently
      $_->return_value(4)       # Set the return value
  };

=head1 DESCRIPTION

Advice code is called when the advice pointcut is matched. In this code,
there is often a need to access information about the join point context
of the advice. Information like:

What is the actual sub name matched?

What are the parameters in this call that we matched?

Sometimes you want to change the context for the matched sub, such as
appending a parameter or even stopping the matched sub from being called
at all.

You do all these things through the C<Join Point>, which is an object
that isa L<Aspect::Point>. It is the only parameter provided to the advice
code. It provides all the information required about the match context,
and allows you to change the behavior of the matched sub.

Note: Modifying parameters through the context in the code of an I<after>
advice, will have no effect, since the matched sub has already been called.

In a future release this will be fixed so that the context for each advice
type only responds to the methods relevant to that context, with the rest
throwing an exception.

=head2 Cflows

If the pointcut of an advice is composed of at least one C<cflow> the
advice code may require not only the context of the advice, but the join
point context of the cflows as well.

This is required if you want to find out, for example, what the name of the
sub that matched a cflow. In the synopsis example above, which method from
C<Company> started the chain of calls that eventually reached the get/set
on C<Person>?

You can access cflow context in the synopsis above, by calling:

  $point->enclosing

You get it from the main advice join point by calling a method named after
the context key used in the cflow spec (which is "enclosing" if a custom name
was not provided, in line with AspectJ terminology). In the synopsis pointcut
definition, the cflow part was equivalent to:

  cflow enclosing => qr/^Company::/
        ^^^^^^^^^

An L<Aspect::Point::Static> will be created for the cflow, and you can access it
using the C<enclosing> method.

=head1 EXAMPLES

Print parameters to matched sub:

  before {
      print join ',', $_->args;
  } $pointcut;

Append a parameter:

  before {
      $_->args( $_->args, 'extra parameter' );
  } $pointcut;

Don't proceed to matched sub, return 4 instead:

  before {
      shift->return_value(4);
  } $pointcut;

Call matched sub again and again until it returns something defined:

  after {
      my $point  = shift;
      my $return = $point->return_value;
      while ( not defined $return ) {
          $return = $point->original($point->params);
      }
      $point->return_value($return);
  } $pointcut;

Print the name of the C<Company> object that started the chain of calls
that eventually reached the get/set on C<Person>:

  before {
      print shift->enclosing->self->name;
  } $pointcut;

=head1 METHODS

=cut

use strict;
use Carp                  ();
use Sub::Uplevel          ();
use Aspect::Point::Static ();

our $VERSION = '1.04';





######################################################################
# Aspect::Point Methods

# sub new {
	# my $class = shift;
	# bless { @_ }, $class;
# }

=pod

=head2 type

The C<type> method is a convenience provided in the situation something has a
L<Aspect::Point> method and wants to know the advice declarator it is made for.

Returns C<"before"> in L<Aspect::Advice::Before> advice, C<"after"> in
L<Aspect::Advice::After> advice, or C<"around"> in
L<Aspect::Advice::Around> advice.

=cut

sub type {
	$_[0]->{type};
}

=pod

=head2 pointcut

  my $pointcut = $_->pointcut;

The C<pointcut> method provides access to the original join point specification
(as a tree of L<Aspect::Pointcut> objects) that the current join point matched
against.

Please note that the pointcut returned is the full and complete pointcut tree,
due to the heavy optimisation used on the actual pointcut code when it is run
there is no way at the time of advice execution to indicate which specific
conditions in the pointcut tree matched and which did not.

Returns an object which is a sub-class of L<Aspect::Pointcut>.

=cut

sub pointcut {
	$_[0]->{pointcut};
}

=pod

=head2 original

  $_->original->( 1, 2, 3 );

In a pointcut, the C<original> method returns a C<CODE> reference to the
original function before it was hooked by the L<Aspect> weaving process.

Calls made to the function are unprotected, parameters and calling context will
not be replicated into the function, return params and exception will not be
caught.

=cut

sub original {
	$_[0]->{original};
}

=pod

=head2 sub_name

  # Prints "Full::Function::name"
  before {
      print $_->sub_name . "\n";
  } call 'Full::Function::name';

The C<sub_name> method returns a string with the full resolved function name
at the join point the advice code is running at.

=cut

sub sub_name {
	$_[0]->{sub_name};
}

=pod

=head2 package_name

  # Prints "Just::Package"
  before {
      print $_->package_name . "\n";
  } call 'Just::Package::name';

The C<package_name> parameter is a convenience wrapper around the C<sub_name>
method. Where C<sub_name> will return the fully resolved function name, the
C<package_name> method will return just the namespace of the package of the
join point.

=cut

sub package_name {
	my $name = $_[0]->{sub_name};
	return '' unless $name =~ /::/;
	$name =~ s/::[^:]+$//;
	return $name;
}

=pod

=head2 short_name

  # Prints "name"
  before {
      print $_->short_name . "\n";
  } call 'Just::Package::name';

The C<short_name> parameter is a convenience wrapper around the C<sub_name>
method. Where C<sub_name> will return the fully resolved function name, the
C<short_name> method will return just the name of the function.

=cut

sub short_name {
	my $name = $_[0]->{sub_name};
	return $name unless $name =~ /::/;
	$name =~ /::([^:]+)$/;
	return $1;
}

=pod

=head2 args

  # Add a parameter to the function call
  $_->args( $_->args, 'more' );

The C<args> method allows you to get or set the list of parameters to a
function. It is the method equivalent of manipulating the C<@_> array.

It uses a slightly unusual calling convention based on list context, but does
so in a way that allows your advice code to read very naturally.

To summarise the situation, the three uses of the C<args> method are listed
below, along with their C<@_> equivalents.

  # Get the parameters as a list
  my @list = $_->args;     # my $list = @_;
  
  # Get the number of parameters
  my $count = $_->args;    # my $count = @_;
  
  # Set the parameters
  $_->args( 1, 2, 3 );     # @_ = ( 1, 2, 3 );

As you can see from the above example, when C<args> is called in list context
it returns the list of parameters. When it is called in scalar context, it
returns the number of parameters. And when it is called in void context, it
sets the parameters to the passed values.

Although this is somewhat unconventional, it does allow the most common existing
uses of the older C<params> method to be changed directly to the new C<args>
method (such as the first example above).

And unlike the original, you can legally call C<args> in such a way as to set
the function parameters to be an empty list (which you could not do with the
older C<params> method).

  # Set the function parameters to a null list
  $_->args();

=cut

sub args {
	if ( defined CORE::wantarray ) {
		return @{$_[0]->{args}};
	} else {
		@{$_[0]->{args}} = @_[1..$#_];
	}
}

=pod

=head2 self

  after {
      $_->self->save;
  } My::Foo::set;

The C<self> method is a convenience provided for when you are writing advice
that will be working with object-oriented Perl code. It returns the first
parameter to the method (which should be object), which you can then call
methods on.

The result is advice code that is much more natural to read, as you can see in
the above example where we implement an auto-save feature on the class
C<My::Foo>, writing the contents to disk every time a value is set without
error.

At present the C<self> method is implemented fairly naively, if used outside
of object-oriented code it will still return something (including C<undef> in
the case where there were no parameters to the join point function).

=cut

sub self {
	$_[0]->{args}->[0];
}

=pod

=head2 wantarray

  # Return differently depending on the calling context
  if ( $_->wantarray ) {
      $_->return_value(5);
  } else {
      $_->return_value(1, 2, 3, 4, 5);
  }

The C<wantarray> method returns the L<perlfunc/wantarray> context of the
call to the function for the current join point.

As with the core Perl C<wantarray> function, returns true if the function is
being called in list context, false if the function is being called in scalar
context, or C<undef> if the function is being called in void context.

B<Backcompatibility Note:>

Prior to L<Aspect> 0.98 the wantarray context of the call to the join point
was available not only via the C<wantarray> method, but the advice code itself
was called in matching wantarray context to the function call, allowing you to
use plain C<wantarray> in the advice code as well.

As all the other information about the join point was available through methods,
having this one piece of metadata available different was becoming an oddity.

The C<wantarray> context of the join point is now B<only> available by the
C<wantarray> method.

=cut

sub wantarray {
	$_[0]->{wantarray};
}

=pod

=head2 exception

  unless ( $_->exception ) {
      $_->exception('Kaboom');
  }

The C<exception> method is used to get the current die message or exception
object, or to set the die message or exception object.

=cut

sub exception {
	unless ( $_[0]->{type} eq 'after' ) {
		Carp::croak("Cannot call exception in $_[0]->{exception} advice");
	}
	return $_[0]->{exception} if defined CORE::wantarray();
	$_[0]->{exception} = $_[1];
}

=pod

=head2 return_value

  # Add an extra value to the returned list
  $_->return_value( $_->return_value, 'thing' );

The C<return_value> method is used to get or set the return value for the
join point function, in a similar way to the normal Perl C<return> keyword.

As with the C<args> method, the C<return_value> method is sensitive to the
context in which it is called.

When called in list context, the C<return_value> method returns the join point
return value as a list. If the join point is called in scalar context, this will
be a single-element list containing the scalar return value. If the join point
is called in void context, this will be a null list.

When called in scalar context, the C<return_value> method returns the join
point return value as a scalar. If the join point is called in list context,
this will be the number of vales in the return list. If the join point is called
in void context, this will be C<undef>

When called in void context, the C<return_value> method sets the return value
for the join point using semantics identical to the C<return> keyword.

Because of this change in behavior based on the context in which C<return_value>
is called, you should generally always set C<return_value> in it's own statement
to prevent accidentally calling it in non-void context.

  # Return null (equivalent to "return;")
  $_->return_value;

In advice types that can be triggered by an exception, or need to determine
whether to continue to the join point function, setting a return value via
C<return_value> is seen as implicitly indicating that any exception should be
suppressed, or that we do B<not> want to continue to the join point function.

When you call the C<return_value> method this does NOT trigger an immediate
C<return> equivalent in the advice code, the lines after C<return_value> will
continue to be executed as normal (to provide an opportunity for cleanup
operations to be done and so on).

If you use C<return_value> inside an if/else structure you will still need to
do an explicit C<return> if you wish to break out of the advice code.

Thus, if you wish to break out of the advice code as well as return with an
alternative value, you should do the following.

  return $_->return_value('value');

This usage of C<return_value> appears to be contrary to the above instruction
that setting the return value should always be done on a standalone line to
guarentee void context.

However, in Perl the context of the current function is inherited by a function
called with return in the manner shown above. Thus the usage of C<return_value>
in this way alone is guarenteed to also set the return value rather than fetch
it.

=cut

sub return_value {
	my $self = shift;
	my $want = $self->{wantarray};

	# Handle usage in getter form
	if ( defined CORE::wantarray() ) {
		# Let the inherent magic of Perl do the work between the
		# list and scalar context calls to return_value
		return @{$self->{return_value} || []} if $want;
		return $self->{return_value} if defined $want;
		return;
	}

	# We've been provided a return value
	$self->{exception}    = '';
	$self->{return_value} = $want ? [ @_ ] : pop;
}

sub proceed {
	my $self = shift;

	unless ( $self->{type} eq 'around' ) {
		Carp::croak("Cannot call proceed in $self->{type} advice");
	}

	local $_ = ${$self->{topic}};

	if ( $self->{wantarray} ) {
		$self->return_value(
			Sub::Uplevel::uplevel(
				2,
				$self->{original},
				@{$self->{args}},
			)
		);

	} elsif ( defined $self->{wantarray} ) {
		$self->return_value(
			scalar Sub::Uplevel::uplevel(
				2,
				$self->{original},
				@{$self->{args}},
			)
		);

	} else {
		Sub::Uplevel::uplevel(
			2,
			$self->{original},
			@{$self->{args}},
		);
	}

	${$self->{topic}} = $_;

	return;
}

sub enclosing {
	$_[0]->{enclosing};
}

sub topic {
	Carp::croak("The join point method topic in reserved");
}

sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	$key =~ s/^.*:://;
	Carp::croak "Key does not exist: [$key]" unless exists $self->{$key};
	return $self->{$key};
}

# Improves performance by not having to send DESTROY calls
# through AUTOLOAD, and not having to check for DESTROY in AUTOLOAD.
sub DESTROY () { }





######################################################################
# Optional XS Acceleration

BEGIN {
	local $@;
	eval <<'END_PERL';
use Class::XSAccessor 1.08 {
	replace => 1,
	getters => {
		'type'       => 'type',
		'pointcut'   => 'pointcut',
		'original'   => 'original',
		'sub_name'   => 'sub_name',
		'wantarray'  => 'wantarray',
		'enclosing'  => 'enclosing',
	},
};
END_PERL
}

1;

=pod

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
