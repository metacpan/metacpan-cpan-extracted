package Aspect::Legacy;

=pod

=head1 NAME

Aspect::Legacy - Legacy Compatibility for Aspect.pm

=head1 DESCRIPTION

B<Aspect::Legacy> implements emulated support for the L<Aspect> module as it
existed in various forms prior to the 1.00 release in 2010.

This includes both full legacy support for the original Ran Eilam release series
ending in release 0.12, and for code written against the 0.16 to 0.99
development release series.

In it's default usage, it is intended as a drop-in upgrade for any old
Aspect-oriented code broken by changes in the second-generation
(version 0.90 or later) implementation created during 2010. To upgrade our old
code, simple change C<use Aspect;> to C<use Aspect::Legacy;> and it should
continue to function as normal.

=cut

use strict;
use Aspect   ();
use Exporter ();

our $VERSION   = '1.04';
our @ISA       = 'Exporter';
our @EXPORT    = qw( aspect before after call cflow );
our $INSTALLED = 0;

# Install deprecated functionality
*Aspect::after_throwing       = *Aspect::Legacy::after_throwing;
*Aspect::after_returning      = *Aspect::Legacy::after_returning;
*Aspect::Point::params        = *Aspect::Legacy::params;
*Aspect::Point::params_ref    = *Aspect::Legacy::params_ref;
*Aspect::Point::append_param  = *Aspect::Legacy::append_param;
*Aspect::Point::append_params = *Aspect::Legacy::append_params;

# Namespace aliasing to old names
*Aspect::if_true               = *Aspect::true;
*Aspect::Point::short_sub_name = *Aspect::Point::short_name;
*Aspect::Point::run_original   = *Aspect::Point::proceed;
*Aspect::Modular::params       = *Aspect::Modular::args;

# Copy original functions into this namespace so they can be exported
*Aspect::Legacy::call   = *Aspect::call;
*Aspect::Legacy::cflow  = *Aspect::cflow;
*Aspect::Legacy::before = *Aspect::before;
*Aspect::Legacy::after  = *Aspect::Legacy::after_returning;
*Aspect::Legacy::aspect = *Aspect::aspect;





######################################################################
# Deprecated Functionality

# Aspect::advice
sub advice {
	my $type = shift;
	if ( $type eq 'before' ) {
		return before(@_);
	} else {
		return after(@_);
	}
}

# Aspect::after_returning
sub after_returning (&$) {
	Aspect::Advice::After->new(
		lexical  => defined wantarray,
		code     => $_[0],
		pointcut => Aspect::Pointcut::And->new(
			Aspect::Pointcut::Returning->new,
			$_[1],
		),
	);
}

# Aspect::after_throwing
sub after_throwing (&$) {
	Aspect::Advice::After->new(
		lexical  => defined wantarray,
		code     => $_[0],
		pointcut => Aspect::Pointcut::And->new(
			Aspect::Pointcut::Throwing->new,
			$_[1],
		),
	);
}

# Aspect::Point::params_ref
sub params_ref {
	$_[0]->{args};
}

# Aspect::Point::params
sub params {
	$_[0]->{args} = [ @_[1..$#_] ] if @_ > 1;
	return CORE::wantarray
		? @{$_[0]->{args}}
		: $_[0]->{args};
}

# Aspect::Point::append_param
sub append_param {
	my $self = shift;
	$self->args( $self->args, @_ );
}

# Aspect::Point::append_params
sub append_params {
	my $self = shift;
	$self->args( $self->args, @_ );
}

=pod

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
