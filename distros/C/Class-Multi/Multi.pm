package Class::Multi;

#
# Copyright (C) 2005,2014 by Kevin Cody-Little <kcody@cpan.org>
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

use Exporter;

# old syntax for PERL 5.004 compat
use vars qw( $VERSION @ISA @EXPORT_OK );

$VERSION	= '1.02';
@ISA		= qw( Exporter );
@EXPORT_OK	= qw( &walk &other &otherpkg );


=head1 Inheritance Traversal Function

=head2 C<< walk( \&testsub, CLASS, @avoid ) >>

Executes the supplied code reference once for each superclass of the supplied
derived class, in the same depth-first order that PERL uses internally.

If an @avoid list is supplied, the code reference will not be executed until
all classes in that list have been seen.

=head2 C<< walk { BLOCK } $derived >>

Executes the { BLOCK } once each for $derived and its superclasses.

=head2 C<< walk { BLOCK } $derived, $derived >>

Executes the { BLOCK } only for $derived's superclasses.

=head2 C<< walk { BLOCK } $derived, __PACKAGE__ >>

Executes the { BLOCK } only for classes that are inherited after the
class in which the expression is found.

=cut

sub walk(&$;@) {
	my $callout = shift;
	my $derived = shift;
	my %looking = map { $_ => 1 } @_;

	# prototyping will catch PEBKACs involving $callout
	return unless defined $derived && length( $derived );

	# the class search is governed by an inverted stack (unshift/shift)
	# inverted to avoid having to reverse( @{"$class\::ISA"} );
	my @stack = ( $derived );

	my ( %trail, $class, $rc );
	while ( $class = shift @stack ) {
		next unless defined( $class ) && length( $class );

		# canonize main:: fudgery
		substr( $class, 0, 2 ) = 'main::'
			if substr( $class, 0, 2 ) eq '::';

		# push $class's supers to stack
		{
			no strict 'refs';	# access symbol table
			unshift @stack, @{$class.'::ISA'};
		}

		# found a class in the avoidance list
		if ( exists $looking{$class} ) {
			delete $looking{$class};
			$trail{$class}++;
			next;
		}

		# the avoidance list isn't empty, do not execute
		if ( keys %looking ) {
			$trail{$class}++;
			next;
		}

		# visit each class only once - "diamond" inheritance
		unless ( exists $trail{$class} && $trail{$class} ) {
			$rc = &$callout( $class );
		}

		# if something nonzero was returned, the loop is done
		return $rc if defined $rc && $rc;

		$trail{$class}++;
	}

	return undef;
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

	# symbol table lookup would be undef if the method doesn't exist
	return walk {
		my $pkg = shift;
		no strict 'refs';
		*{$pkg.'::'.$name}{CODE};
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

	# symbol table lookup would be undef if the method doesn't exist
	return walk {
		my $pkg = shift;
		no strict 'refs';
		( *{$pkg.'::'.$name}{CODE} ) ? $pkg : undef;
	} $origin, $caller;
}


=head1 Multi-Inherited Mandatory Method Call

=head2 C<< $this->OTHER::mymethod( @myargs ); >>

Syntactic sugar.

Equivalent to C<< &{other( $this, 'mymethod' )}( $this, @myargs ); >>.

Like C<SUPER::>, C<OTHER::> expects the requested method to exist.
If it does not, an exception is thrown.

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

	# can't just call other() above, would change caller package ;)
	$func = walk { no strict 'refs'; \&{"$_\::$name"} } $origin, $caller;

	# using this syntax indicates a method is -expected- to exist
	unless ( defined( $func ) && ref( $func ) eq 'CODE' ) {
		confess( "No method '$name' after '$caller' in '$origin'.\n" );
	}

	return &$func( $this, @_ );
}


1;

=head1 AUTHORS

=over

=item Kevin Cody-Little <kcody@cpan.org>

=back

=cut
