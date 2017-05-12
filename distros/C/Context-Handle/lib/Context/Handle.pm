#!/usr/bin/perl

package Context::Handle;
use base qw/Exporter/;

use strict;
use warnings;

use Want ();
use Carp qw/croak/;

use Context::Handle::RV::Scalar;
use Context::Handle::RV::Void;
use Context::Handle::RV::List;
use Context::Handle::RV::Bool;
use Context::Handle::RV::RefHash;
use Context::Handle::RV::RefArray;
use Context::Handle::RV::RefScalar;
use Context::Handle::RV::RefCode;
use Context::Handle::RV::RefObject;

BEGIN {
	our @EXPORT_OK = qw/context_sensitive/;
}

our $VERSION = "0.01";

sub context_sensitive (&) {
	my $code = shift;
	__PACKAGE__->new( $code, 1 );
}

sub new {
	my $pkg = shift;
	my $code = shift;
	my $caller_level = @_ ? 1 + shift : 1;

	my $self = bless {
		uplevel => $caller_level,
		want_reftype => Want::wantref( $caller_level + 1 ),
		want_count => Want::want_count($caller_level),
		want_wantarray => Want::wantarray_up($caller_level),
		want_bool => Want::want_uplevel($caller_level, "BOOL"),
		want_assign => [ Want::wantassign( $caller_level + 1 ) ],
		want_lvalue => Want::want_lvalue( $caller_level ),
	}, $pkg;

	$self->eval( $code) ;

	$self;
}

sub bool {
	my $self = shift;
	$self->{want_bool} && defined $self->{want_wantarray};
}

sub void {
	my $self = shift;
	not defined $self->{want_wantarray};
}

sub scalar {
	my $self = shift;
	defined $self->{want_wantarray} && $self->{want_wantarray} == 0;
}

sub list {
	my $self = shift;
	$self->{want_wantarray};
}

sub refarray {
	my $self = shift;
	$self->{want_reftype} eq 'ARRAY';
}

sub refhash {
	my $self = shift;
	$self->{want_reftype} eq 'HASH';
}

sub refscalar {
	my $self = shift;
	$self->{want_reftype} eq 'SCALAR';
}

sub refobject {
	my $self = shift;
	$self->{want_reftype} eq 'OBJECT';
}

sub refcode {
	my $self = shift;
	$self->{want_reftype} eq 'CODE';
}

sub refglob {
	my $self = shift;
	$self->{want_reftype} eq 'GLOB';
}


sub rv_subclass {
	my $self = shift;

	if ( $self->scalar ) {
		for (qw/RefArray RefScalar RefHash RefObject RefCode RefGlob/) {
			my $meth = lc;
			return $_ if $self->$meth;
		}

		return "Bool" if $self->bool;

		return "Scalar";
	} else {
		$self->$_ and return ucfirst for qw/void list/;
	}

	die "dunno how to do this context.";
}

sub mk_rv_container {
	my $self = shift;
	my $code = shift;

	my $subclass = $self->rv_subclass;
	"Context::Handle::RV::$subclass"->new($code);
}

sub eval {
	my $self = shift;
	my $code = shift;

	$self->{rv_container} = $self->mk_rv_container($code);
}

sub rv_container {
	my $self = shift;
	$self->{rv_container};
}

sub value {
	my $self = shift;
	$self->rv_container->value;
}

sub return {
	my $self = shift;
	Want::double_return();
	$self->value;
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Context::Handle - A convenient context propagation proxy thingy.

=head1 SYNOPSIS

	use Context::Handle qw/context_sensitive/;

	sub wrapping {
		my $rv = context_sensitive {
			$some_thing->method(); # anything really
		};

		# you can do anything here

		$rv->return; # returns the value in the right context

		# not reached
	}

=head1 DESCRIPTION

This module lets you delegate to another method and return the value without
caring about context propagation.

The level of support is tied to what L<Want> does - this module tries to make
all the distinctions Want can make fully supported, for example array
dereference context, boolean context, etc.

=head1 EXPORTS

Nothing is exported by default.

=over 4

=item context_sensitive BLOCK

This is a convenience shortcut that calls C<new>

=back

=head1 METHODS

=head2 Regular Usage

=over 4

=item new $code

This method invokes $code in the calling sub's context, and returns an object
that saves the return value.

=item rv_container

This instance method returns the return value container object. The only useful
methods for the RV containers is C<value>, which has a delegator anyway.

=item value

This returns the value from the C<rv_container>

=item return

This (ab)uses L<Want> to perform a double return.

Saying

	$rv->return;

is just like

	return $rv->value;

=back

=head2 Introspection

Incidientially due to the needs of the wrapping layer this module also provides
an OO interface to L<Want>, more or less ;-)

=over 4

=item bool

=item void

=item scalar

=item list

=item refarray

=item refhash

=item refscalar

=item refobject

=item refcode

=item refglob

All of these methods return boolean values, with respect to the 

=back

=head1 TODO

=over 4

=item *

pseudoboolean context - the right side of && and the left side of || evaulate
in boolean context, but still return a meaningful value.

=item *

Glob assignment context. I'm not sure how to make the value propagate back once
it's been assigned to the glob - it's hard to know what it is without
inspecting the slots and that's kinda tricky.

=item *

Lvalue assignment

=item *

use L<Sub::Uplevel> to hide the wrapping

=item *

context arity - L<Want>'s count stuff. This can probably be done using
@list[0..$x] = (...), but might need to be emulated with eval. See
C<perldoc -f split>.

=back

=head1 ACKNOWLEGMENTS

Robin Houston for L<Want> and lots of help by email

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2006 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


