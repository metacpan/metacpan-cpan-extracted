package Data::Stream::Bulk::Chunked;
BEGIN {
  $Data::Stream::Bulk::Chunked::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::Chunked::VERSION = '0.11';
}
use Moose;
# ABSTRACT: combine streams into larger chunks

use namespace::clean -except => 'meta';

with 'Data::Stream::Bulk::DoneFlag';

has stream => (
    is       => 'ro',
    does     => 'Data::Stream::Bulk',
    required => 1,
);

has chunk_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

sub get_more {
    my $self = shift;

    my $s = $self->stream;
    my $size = $self->chunk_size;

    my @data;
    push @data, $s->items
        until $s->is_done || @data >= $size;

    return unless @data;
    return \@data;
}

__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=head1 NAME

Data::Stream::Bulk::Chunked - combine streams into larger chunks

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use Data::Stream::Bulk::Chunked;

  Data::Stream::Bulk::Chunked->new(
      stream     => $s,
      chunk_size => 10000,
  );

=head1 DESCRIPTION

This is a stream which wraps an existing stream to give more items in a single
block. This can simplify application code which does its own processing one
block at a time, and where processing larger blocks is more efficient.

=head1 ATTRIBUTES

=over 4

=item stream

The stream to chunk. Required.

=item chunk_size

The minimum number of items to return in a block. Defaults to 1 (which does
nothing).

=back

=head1 METHODS

=over 4

=item get_more

See L<Data::Stream::Bulk::DoneFlag>.

Returns at least C<chunk_size> items. Note that this isn't guaranteed to return
exactly C<chunk_size> items - it just returns multiple full blocks from the
backend. Also, the final block returned may have less than C<chunk_size> items.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

