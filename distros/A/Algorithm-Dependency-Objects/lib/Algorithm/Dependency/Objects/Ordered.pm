#!/usr/bin/perl

package Algorithm::Dependency::Objects::Ordered;
use base qw/Algorithm::Dependency::Objects/;

use strict;
use warnings;

use Scalar::Util qw/refaddr/;
use Carp qw/croak/;

sub schedule {
	my ( $self, @args ) = @_;
	$self->_order($self->SUPER::schedule(@args));
}

sub schedule_all {
	my ( $self, @args ) = @_;
	$self->_order($self->SUPER::schedule_all(@args));
}

sub _order {
	my ( $self, @queue ) = @_;

	my $selected = Set::Object->new( $self->selected->members );

	my $error_marker;
	my @schedule;

	my %dep_set; 

	while (@queue){
		my $obj = shift @queue;

		if ( defined($error_marker) and refaddr($error_marker) == refaddr($obj) ) {
			$self->circular_dep($obj, @queue);
		}
		
		my $dep_set = $dep_set{refaddr $obj} ||= Set::Object->new( $self->get_deps($obj) );

		unless ( $selected->superset($dep_set) ) {
			# we have some missing deps
			# put the object back in the queue
			push @queue, $obj;

			# if we encounter it again without any change
			# then a circular dependency is detected
			$error_marker = $obj unless defined $error_marker;
		} else {
			# the dependancies are a subset of the selected objects,
			# so they are all resolved.
			push @schedule, $obj;

			# mark the object as selected
			$selected->insert($obj);

			# since something changed we can forget about the error marker
			undef $error_marker;
		}
	}

	# return the ordered list
	@schedule;
}

sub circular_dep {
	my ( $self, $obj, @queue ) = @_;

	croak "Circular dependency detected at $obj (queue: @queue)"
}

__PACKAGE__

__END__

=pod

=head1 NAME

Algorithm::Dependency::Objects::Ordered - An ordered dependency set

=head1 SYNOPSIS

	use Algorithm::Dependency::Objects::Ordered;

	my $o = Algorithm::Dependency::Ordered->new(
		objects => \@some_objects,
	);

	foreach my $object ( $o->schedule_all ) {
		print "$object, then...\n";		
	}

	print "done\n";

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=item B<objects>

=item B<selected>

=item B<depends>

=item B<schedule>

=item B<schedule_all>

=item B<circular_dep>

=back

=head1 SEE ALSO

Adam Kennedy's excellent L<Algorithm::Dependency::Ordered> module, upon which this is based.

=head1 AUTHORS

Yuval Kogman

Stevan Little

COPYRIGHT AND LICENSE 

Copyright (C) 2005, 2007 Yuval Kogman, Stevan Little

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

