package Class::Multi;

#
# Copyright (C) 2005,2014,2017 by Kevin Cody-Little <kcody@cpan.org>
# All rights reserved.
#
# This software may be modified and/or redistributed under the
# terms of the GNU Lesser General Public License v2.1 or later.
#

=head1 NAME

Class::Multi - Multiple inheritance support functions.

=head1 SYNOPSIS

=over

=item * A flexible inheritance traversal function.

=item * A calling-class-relative metaphor of C<can()>.

=item * A calling-class-relative metaphor of C<SUPER::>.

=back

=cut

use strict;
use warnings;

use Carp;
use Exporter;

# old syntax for PERL 5.004 compat
use vars qw( $VERSION @ISA @EXPORT_OK );

$VERSION	= '1.03';
@ISA		= qw( Exporter );
@EXPORT_OK	= qw( &walk &walk_width &walk_depth &other &otherpkg );


=head1 Inheritance Traversal Function

=head2 C<< walk_depth( \&testsub, CLASS, @avoid ) >>

=head2 C<< walk_width( \&testsub, CLASS, @avoid ) >>

=head2 C<< walk_width_up( \&testsub, CLASS, @avoid ) >>

Executes the supplied code reference once for each superclass of the supplied
derived class, until the code reference returns true.

walk_depth uses the same depth-first search order that Perl uses internally.

walk_width uses a breadth-first search order that is more appropriate for
diamond inheritance situations. Thus, and also since Perl already provides
methods that use depth-first, all of the other functions in this package
use the breadth-first search order.

walk_width_up uses breadth-first, but starts with the base class and works
its way toward the derived. This is more appropriate for a constructive
purpose where the base class should initialize first, where walk_width
is more appropriate for a destructive purpose where the base class
should be called last.

If an @avoid list is supplied, the code reference will not be executed until
all classes in that list have been seen, whichever direction it's going.

=head2 C<< walk_width { BLOCK } $derived >>

Executes the { BLOCK } once each for $derived and its superclasses.

=head2 C<< walk_width { BLOCK } $derived, $derived >>

Executes the { BLOCK } only for $derived's superclasses.

=head2 C<< walk_width { BLOCK } $derived, __PACKAGE__ >>

Executes the { BLOCK } only for classes that are inherited after the
class in which the expression is found.

=cut

my $walk_raw = sub {
	my $width = shift;
	my $callout = shift;
	my $derived = shift;
	my %looking = map { $_ => 1 } @_;

	# prototyping will catch PEBKACs involving $callout
	return unless defined $derived && length( $derived );

	# the class search is breadth-first, by fifo queue
	my @queue = ( $derived );

	my ( %trail, $class, $rc );
	while ( $class = shift @queue ) {
		next unless defined( $class ) && length( $class );

		# canonize main:: fudgery
		substr( $class, 0, 2 ) = 'main::'
			if substr( $class, 0, 2 ) eq '::';

		# push $class's supers to queue
		{
			no strict 'refs';	# access symbol table

			if ( $width ) {
				push @queue, @{$class.'::ISA'};
			}

			else {
				unshift @queue, @{$class.'::ISA'};
			}

		}

		# skip it if we've seen it
		# visit each class only once - "web" inheritance
		next if exists $trail{$class};
		$trail{$class}++;

		# found a class in the avoidance list
		if ( exists $looking{$class} ) {
			delete $looking{$class};
			next;
		}

		# the avoidance list isn't empty, do not execute
		next if %looking;

		# call the given code reference
		{
			local $_ = $class;
			$rc = &$callout( $class );
		}

		# if something nonzero was returned, the loop is done
		return $rc if $rc;

	}

	return undef;
};

sub walk_width(&$;@) {
	&$walk_raw( 1, @_ );
}

sub walk_depth(&$;@) {
	&$walk_raw( 0, @_ );
}

sub walk(&$;@) {
	confess( "Class::Multi::walk is deprecated. Use walk_width or walk_depth instead.\n" );
	&$walk_raw( 0, @_ );
}

sub walk_width_up(&$;@) {
	my ( $callout, $derived, @avoid ) = @_;

	my @classes;
	walk_width { push @classes, $_; 0 } $derived, @avoid;

	my $rc;
	while ( my $class = pop @classes ) {

		# call the given code reference
		local $_ = $class;
		$rc = &$callout( $class );

		# if something nonzero was returned, the loop is done
		return $rc if $rc;
	}

	return;
}


=head1 Multi-Inherited Method Search

=head2 C<< other( $this, METHOD ) >>

C<other> checks if the object or class $this has a method called 'METHOD',
that occurs -AFTER- the calling class in the inheritance tree.

Usage and semantics are otherwise identical to C<UNIVERSAL::can>

The calling class is inferred via C<caller()>.

=cut

sub other($$) {
	my ( $this, $name ) = @_;
	my ( $origin, $caller );

	# a valid class or instance must be supplied
	$origin = ref( $this ) || $this or return;

	# we must be called from code that has a package reference
	$caller = caller() or return;

	no strict 'refs';

	# symbol table lookup would be undef if the method doesn't exist
	return walk_width {
		*{$_.'::'.$name}{CODE};
	} $origin, $caller;
}

=head2 C<< otherpkg( $this, METHOD ) >>

Identical to C<other>, except the package name is returned instead of
the desired method's code reference.

=cut

sub otherpkg($$) {
	my ( $this, $name ) = @_;
	my ( $origin, $caller );

	# a valid class or instance must be supplied
	$origin = ref( $this ) || $this or return;

	# we must be called from code that has a package reference
	$caller = caller() or return;

	no strict 'refs';

	# symbol table lookup would be undef if the method doesn't exist
	return walk_width {
		( *{$_.'::'.$name}{CODE} ) ? $_ : undef;
	} $origin, $caller;
}

=head2 C<< otherrun( $this, METHOD, @myargs ) >>

Identical to C<other>, except the function is run and its result returned
instead of the desired method's code reference.

Equivalent to C<< &{other( $this, METHOD )}( $this, @myargs ); >>.

=cut

sub otherrun($$) {
	my $this = shift;
	my $name = shift;
	my ( $origin, $caller, $func );

	# a valid class or instance must be supplied
	$origin = ref( $this ) || $this or return;

	# we must be called from code that has a package reference
	$caller = caller() or return;

	# symbol table lookup would be undef if the method doesn't exist
	{	no strict 'refs';

		$func = walk_width { *{$_.'::'.$name}{CODE}; } $origin, $caller;
	}

	return $func ? &$func( $this, @_ ) : undef;
}


=head1 Multi-Inherited Iterative Method Call

=head2 C<< $this->EVERY::mymethod( @myargs ); >>
=head2 C<< $this->EVERY::MAY::mymethod( @myargs ); >>
=head2 C<< $this->EVERY::DOWN::mymethod( @myargs ); >>
=head2 C<< $this->EVERY::MAY::DOWN::mymethod( @myargs ); >>

Syntactic sugar.

Calls every implementation of the requested method in all of
$this's base classes. The method must exist at least once.

If you do not want an exception to be thrown if no method is
found, call using $this->EVERY::MAY::mymethod( @myargs );

If you want the subclasses called from the top-down as normal
inheritance does, but breadth-first, use either EVERY::DOWN
or EVERY::MAY::DOWN.

If you do not want to provide an empty method in your base
class to satisfy that, and don't like the ::MAY syntax, then
you can wrap an EVERY invocation in an eval { } call. But,
remember to localize @_ before you do so.

=cut

my $EVERY_FUNC = sub {
	my $auto = shift;
	my $this = shift;
	my @args = @_;

	# a valid class or instance must be supplied
	my $origin = ref( $this ) || $this or return;

	# find our name and intent
	my @part = split /::/, $auto;
	my $name = pop @part;
	shift @part;

	my $down = 0;
	my $must = 1;

	while ( my $part = shift @part ) {

		if ( $part eq 'MAY' ) {
			$must = 0;
		}

		elsif ( $part eq 'DOWN' ) {
			$down = 1;
		}

		else {
			confess( "Unknown EVERY:: flag '$part'" );
		}

	}

	my @class;

	walk_width { push @class, $_; 0 } $origin;

	if ( not $down ) {
		@class = reverse @class;
	}

	my $count = 0;

	while ( my $class = shift @class ) {

		no strict 'refs';

		if ( my $func = *{"$class\::$name"}{CODE} ) {
			&$func( $this, @args );
			$count++;
		}

	}

	if ( $must and not $count ) {
		confess( "No method '$name' in '$origin'.\n" );
	}

	return $count;
};

package EVERY;
use strict;
use warnings;
sub AUTOLOAD { &$EVERY_FUNC( $EVERY::AUTOLOAD, @_ ) }

package EVERY::DOWN;
use strict;
use warnings;
sub AUTOLOAD { &$EVERY_FUNC( $EVERY::DOWN::AUTOLOAD, @_ ) }

package EVERY::MAY;
use strict;
use warnings;
sub AUTOLOAD { &$EVERY_FUNC( $EVERY::MAY::AUTOLOAD, @_ ) }

package EVERY::MAY::DOWN;
use strict;
use warnings;
sub AUTOLOAD { &$EVERY_FUNC( $EVERY::MAY::DOWN::AUTOLOAD, @_ ) }


=head1 Multi-Inherited Breadth-First Chain-Up Call

=head2 C<< $this->OTHER::mymethod( @myargs ); >>
=head2 C<< $this->OTHER::MAY::mymethod( @myargs ); >>

Syntactic sugar.

Equivalent to C<< &{other( $this, 'mymethod' )}( $this, @myargs ); >>.

Like C<SUPER::>, C<OTHER::> expects the requested method to exist.
If it does not, an exception is thrown.

If you do not want to wrap the call in eval { }, then use OTHER::MAY.

=cut

package OTHER;

use strict;
use warnings;

# old syntax for PERL 5.004 compat
use vars qw( $AUTOLOAD );

use Carp;

sub AUTOLOAD {
	my $this = shift;
	my ( $origin, $caller, $name, $func );

	# a valid class or instance must be supplied
	$origin = ref( $this ) || $this or return;

	# we must be called from code that has a package reference
	$caller = caller() or return;

	# strip any package name from the supplied method name
	( $name = $AUTOLOAD ) =~ s/.*://;

	{	no strict 'refs';

		# can't just call other() above, would change caller package ;)
		$func = Class::Multi::walk_width { *{"$_\::$name"}{CODE} } $origin, $caller;
	}

	# using this syntax indicates a method is -expected- to exist
	unless ( defined( $func ) and ref( $func ) eq 'CODE' ) {
		confess( "No method '$name' after '$caller' in '$origin'.\n" );
	}

	return &$func( $this, @_ );
}


package OTHER::MAY;

use strict;
use warnings;

# old syntax for PERL 5.004 compat
use vars qw( $AUTOLOAD );

use Carp;

sub AUTOLOAD {
	my $this = shift;
	my ( $origin, $caller, $name, $func );

	# a valid class or instance must be supplied
	$origin = ref( $this ) || $this or return;

	# we must be called from code that has a package reference
	$caller = caller() or return;

	# strip any package name from the supplied method name
	( $name = $AUTOLOAD ) =~ s/.*://;

	{	no strict 'refs';

		# can't just call other() above, would change caller package ;)
		$func = Class::Multi::walk_width { *{"$_\::$name"}{CODE} } $origin, $caller;
	}

	return $func ? &$func( $this, @_ ) : undef;
}


1;

=head1 AUTHORS

=over

=item Kevin Cody-Little <kcody@cpan.org>

=back

=cut
