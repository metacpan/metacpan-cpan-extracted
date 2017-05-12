#!/usr/bin/perl

package Class::Workflow::Util::Delta;
use Moose;

use Carp qw/croak/;

use Data::Compare ();

has from => (
	does => "Class::Workflow::Instance",
	is   => "ro",
	required => 1,
);

has to => (
	does => "Class::Workflow::Instance",
	is   => "ro",
	required => 1,
);

has changes => (
	isa => "HashRef",
	is  => "ro",
	auto_deref => 1,
	lazy => 1,
	default => sub { $_[0]->_compute_changes },
);

sub BUILD {
	my $self = shift;

	croak "The instances must be of the same class"
		unless $self->from->meta->name eq $self->to->meta->name;
}

sub _compute_changes {
	my $self = shift;

	my %changes;

	my ( $from, $to ) = ( $self->from, $self->to );

	my @attrs = $from->meta->get_all_attributes;

	foreach my $attr ( grep { $_->name !~ /^(?:prev|state|transition)$/ } @attrs ) {
		my $res = $self->_compare_values(
			$attr,
			$attr->get_value( $from ),
			$attr->get_value( $to ),
		);

		$changes{$attr->name} = $res if $res;
	}

	return \%changes;
}

sub _compare_values {
	my ( $self, $attr, $from, $to ) = @_;

	unless ( Data::Compare::Compare( $from, $to ) ) {
		return { from => $from, to => $to };
	} else {
		return;
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Util::Delta - calculate deltas between workflow instances

=head1 SYNOPSIS

	my $next = $transition->apply( $i );

	my $d = Class::Workflow::Util::Delta->new(
		from => $i,
		to   => $next,
	);

	foreach my $field ( keys %{ $d->changes } ) {
		my $change = $d->changes->{$field};
		print "$field changed from $change->{from} to $change->{to}\n";
	}

=head1 DESCRIPTION

Usually you need to calculate deltas between workflow instances in order to
normalize the database of history changes so that there are no duplicate
fields.

This module lets you create an object that represents the change between any
two instances (not necessarily related), allowing you to represent a history
step.

See L<Class::Workflow::YAML>
