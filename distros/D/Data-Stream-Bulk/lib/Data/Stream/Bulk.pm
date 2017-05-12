package Data::Stream::Bulk;
BEGIN {
  $Data::Stream::Bulk::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::VERSION = '0.11';
}
use Moose::Role;
# ABSTRACT: N at a time iteration API

use namespace::clean -except => 'meta';

requires qw(next is_done);

sub items {
	my $self = shift;

	if ( my $a = $self->next ) {
		return @$a;
	} else {
		return ();
	}
}

sub all {
	my $self = shift;

	my @ret;

	while ( my $next = $self->next ) {
		push @ret, @$next;
	}

	return @ret;
}

sub cat {
	my ( $self, @streams ) = @_;

	return $self unless @streams;

	my @cat = $self->list_cat(@streams);

	unless ( @cat ) {
		return Data::Stream::Bulk::Nil->new;
	} elsif ( @cat == 1 ) {
		return $cat[0];
	} else {
		return Data::Stream::Bulk::Cat->new(
			streams => \@cat,
		);
	}
}

sub list_cat {
	my ( $self, $head, @tail ) = @_;

	return $self unless $head;
	return ( $self, $head->list_cat(@tail) );
}

sub filter {
	my ( $self, $filter ) = @_;

	return Data::Stream::Bulk::Filter->new(
		filter => $filter,
		stream => $self,
	);
}

sub chunk {
    my ( $self, $chunk_size ) = @_;

    return Data::Stream::Bulk::Chunked->new(
        chunk_size => $chunk_size,
        stream     => $self,
    );
}

sub loaded { 0 }

# load it *after* the entire role is defined
require Data::Stream::Bulk::Cat;
require Data::Stream::Bulk::Chunked;
require Data::Stream::Bulk::Nil;
require Data::Stream::Bulk::Filter;

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk - N at a time iteration API

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	# get a bulk stream from somewere
	my $s = Data::Stream::Bulk::Foo->new( ... );

	# can be used like this:
	until ( $s->is_done ) {
		foreach my $item ( $s->items ) {
			process($item);
		}
	}

	# or like this:
	while( my $block = $s->next ) {
		foreach my $item ( @$block ) {
			process($item);
		}
	}

=head1 DESCRIPTION

This module tries to find middle ground between one at a time and all at once
processing of data sets.

The purpose of this module is to avoid the overhead of implementing an
iterative api when this isn't necessary, without breaking forward
compatibility in case that becomes necessary later on.

The API optimizes for when a data set typically fits in memory and is returned
as an array, but the consumer cannot assume that the data set is bounded.

The API is destructive in order to minimize the chance that resultsets are
leaked due to improper usage.

=head1 API

=head2 Required Methods

The API requires two methods to be implemented:

=over 4

=item is_done

Should return true if the stream is exhausted.

As long as this method returns a false value (not done) C<next> could
potentially return another block.

=item next

Returns the next block.

Note that C<next> is not guaranteed to return an array reference, even if
C<is_done> returned false prior to calling it.

=back

=head2 Convenience Methods

=over 4

=item items

This method calls C<next> and dereferences the result if there are pending
items.

=item all

Force evaluation of the entire resultset.

Note that for large data sets this might cause swap thrashing of various other
undesired effects. Use with caution.

=item cat @streams

Concatenates this stream with @streams, returning a single stream.

=item list_cat @tail

Returns a possibly cleaned up list of streams.

Used by C<cat>.

Overridden by L<Data::Stream::Bulk::Array>, L<Data::Stream::Bulk::Cat> and
L<Data::Stream::Bulk::Nil> to implement some simple short circuiting.

=item filter $filter

Applies a per-block block filter to the stream.

Returns a possibly new stream with the filtering layered.

C<$filter> is invoked once per block and should return an array reference to
the filtered block.

=item chunk $chunk_size

Chunks the input stream so that each block returned by C<next> will have at
least C<$chunk_size> items.

=item loaded

Should be overridden to return true if all the items are already realized (e.g.
in the case of L<Data::Stream::Bulk::Array>).

Returns false by default.

When true calling C<all> is supposed to be safe (memory usage should be in the
same order of magnitude as stream's own usage).

This is typically useful when tranforming an array is easier than transorming a
stream (e.g. optional duplicate filtering).

=back

=head1 CLASSES

=over 4

=item L<Data::Stream::Bulk::Array>

This class is not a stream at all, but just one block. When the data set easily
fits in memory this class can be used, while retaining forward compatibility
with larger data sets.

=item L<Data::Stream::Bulk::Callback>

Callback driven iteration.

=item L<Data::Stream::Bulk::Chunked>

Wrapper to return larger blocks from an existing stream.

=item L<Data::Stream::Bulk::DBI>

Bulk fetching of data from L<DBI> statement handles.

=item L<Data::Stream::Bulk::DBIC>

L<DBIx::Class::ResultSet> iteration.

=item L<Data::Stream::Bulk::FileHandle>

Iterates over lines in a text file.

=item L<Data::Stream::Bulk::Nil>

An empty result set.

=item L<Data::Stream::Bulk::Cat>

A concatenation of several streams.

=item L<Data::Stream::Bulk::Filter>

A filter wrapping a stream.

=back

=head1 SEE ALSO

L<HOP::Stream>, L<Iterator>, L<Class::Iterator> etc for one by one iteration

L<DBI>, L<DBIx::Class::ResultSet>

L<POE::Filter>

L<Data::Page>

L<Parallel::Iterator>

L<http://en.wikipedia.org/wiki/MapReduce>, LISP, and all that other kool aid

=head1 TODO

=over 4

=item Sorted streams

Add a hint for sorted streams (like C<loaded> but as an attribute in the base
role).

Introduce a C<merge> operation for merging of sorted streams.

Optimize C<unique> to make use of sorting hints for constant space uniquing.

=item More utility functions

To assist in proccessing and creating streams.

=item Coercion tables

L<Moose::Util::TypeConstraints>

=back

=head1 VERSION CONTROL

This module is maintained using git. You can get the latest version from
L<http://github.com/nothingmuch/data-stream-bulk/>.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

