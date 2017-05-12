package Data::Stream::Bulk::Array;
BEGIN {
  $Data::Stream::Bulk::Array::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::Array::VERSION = '0.11';
}
use Moose;
# ABSTRACT: L<Data::Stream::Bulk> wrapper for simple arrays.

use namespace::clean -except => 'meta';

with qw(Data::Stream::Bulk) => { -excludes => [qw/loaded filter list_cat/] };

has array => (
	isa => "ArrayRef",
	reader  => "_array",
	writer  => "_set_array",
	clearer => "_clear_array",
	predicate => "_has_array",
	required => 1,
);

sub is_done {
	my $self = shift;
	!$self->_has_array;
}

sub next {
	my $self = shift;

	if ( my $array = $self->_array ) {
		$self->_clear_array;
		return $array;
	} else {
		return;
	}
}

# squish several arrays into one
sub list_cat {
	my ( $self, @rest ) = @_;

	return $self unless @rest;

	my @arrays = ( $self );

	# fetch all adjacent arrays
	push @arrays, shift @rest while @rest and $rest[0]->isa(__PACKAGE__);

	if ( @arrays > 1 ) {
		my @cat;
		push @cat, @$_ for map { $_->_array } @arrays;
		return __PACKAGE__->new(
			array => \@cat,
		)->cat( @rest );
	} else {
		my $head = shift @rest;
		return ( $self, $head->list_cat(@rest) );
	}
}

sub filter {
	my ( $self, $filter ) = @_;
	local $_ = $self->next;
	$self->_set_array( $filter->($_) );
	return $self;
}

sub loaded { 1 }

__PACKAGE__->meta->make_immutable;

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::Array - L<Data::Stream::Bulk> wrapper for simple arrays.

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	return Data::Stream::Bulk::Array->new(
		array => \@results,
	);

=head1 DESCRIPTION

This implementation of the L<Data::Stream::Bulk> api wraps an array.

The use case is to keep the consumer of the data set implementation agnostic so
that it can deal with larger data sets if they are encountered, but still
retain most of the simplicity when the current data set easily fits in memory.

=head1 ATTRIBUTES

=over 4

=item array

The array reference to wrap.

=back

=head1 METHODS

=over 4

=item next

Returns the array reference on the first invocation, and nothing thereafter.

=item is_done

Returns true if C<next> has been called.

=item list_cat

Squishes adjacent arrays into a new array.

=item filter $filter

Immediately applies C<$filter> to the internal array and returns C<$self>.

=item loaded

Returns true

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

