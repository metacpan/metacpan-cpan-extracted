package Algorithm::Dependency::Ordered;
# ABSTRACT: Implements an ordered dependency hierarchy

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod Algorithm::Dependency::Ordered implements the most common variety of
#pod L<Algorithm::Dependency>, the one in which the dependencies of an item must
#pod be acted upon before the item itself can be acted upon.
#pod
#pod In use and semantics, this should be used in exactly the same way as for the
#pod main parent class. Please note that the output of the C<depends> method is
#pod NOT changed, as the order of the depends is not assumed to be important.
#pod Only the output of the C<schedule> method is modified to ensure the correct
#pod order.
#pod
#pod For API details, see L<Algorithm::Dependency>.
#pod
#pod =cut

use 5.005;
use strict;
use Algorithm::Dependency ();

our $VERSION = '1.112';
our @ISA     = 'Algorithm::Dependency';


sub schedule {
	my $self   = shift;
	my $source = $self->{source};
	my @items  = @_ or return undef;
	return undef if grep { ! $source->item($_) } @items;

	# The actual items to select will be the same as for the unordered
	# version, so we can simplify the algorithm greatly by using the
	# normal unordered ->schedule method to get the starting list.
	my $rv    = $self->SUPER::schedule( @items );
	my @queue = $rv ? @$rv : return undef;

	# Get a working copy of the selected index
	my %selected = %{ $self->{selected} };

	# If at any time we check every item in the stack without finding
	# a suitable candidate for addition to the schedule, we have found
	# a circular reference error. We need to create a marker to track this.
	my $error_marker = '';

	# Begin the processing loop
	my @schedule = ();
	while ( my $id = shift @queue ) {
		# Have we checked every item in the stack?
		return undef if $id eq $error_marker;

		# Are there any un-met dependencies
		my $Item    = $self->{source}->item($id) or return undef;
		my @missing = grep { ! $selected{$_} } $Item->depends;

		# Remove orphans if we are ignoring them
		if ( $self->{ignore_orphans} ) {
			@missing = grep { $self->{source}->item($_) } @missing;
		}

		if ( @missing ) {
			# Set the error marker if not already
			$error_marker = $id unless $error_marker;

			# Add the id back to the end of the queue
			push @queue, $id;
			next;
		}

		# All dependencies have been met. Add the item to the schedule and
		# to the selected index, and clear the error marker.
		push @schedule, $id;
		$selected{$id} = 1;
		$error_marker  = '';
	}

	# All items have been added
	\@schedule;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Dependency::Ordered - Implements an ordered dependency hierarchy

=head1 VERSION

version 1.112

=head1 DESCRIPTION

Algorithm::Dependency::Ordered implements the most common variety of
L<Algorithm::Dependency>, the one in which the dependencies of an item must
be acted upon before the item itself can be acted upon.

In use and semantics, this should be used in exactly the same way as for the
main parent class. Please note that the output of the C<depends> method is
NOT changed, as the order of the depends is not assumed to be important.
Only the output of the C<schedule> method is modified to ensure the correct
order.

For API details, see L<Algorithm::Dependency>.

=head1 SEE ALSO

L<Algorithm::Dependency>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Dependency>
(or L<bug-Algorithm-Dependency@rt.cpan.org|mailto:bug-Algorithm-Dependency@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
