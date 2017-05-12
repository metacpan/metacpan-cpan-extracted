package Data::Stream::Bulk::Filter;
BEGIN {
  $Data::Stream::Bulk::Filter::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::Filter::VERSION = '0.11';
}
use Moose;
# ABSTRACT: Streamed filtering (block oriented)

use Data::Stream::Bulk;

use namespace::clean -except => 'meta';

has filter => (
	isa => "CodeRef",
	reader => "filter_body",
	required => 1,
);

has stream => (
	does => "Data::Stream::Bulk",
	is   => "ro",
	required => 1,
	handles  => [qw(is_done loaded)],
);

with qw(Data::Stream::Bulk) => { -excludes => 'loaded' };

sub next {
	my $self = shift;

	local $_ = $self->stream->next;
	return $_ && ( $self->filter_body->($_) || [] );
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::Filter - Streamed filtering (block oriented)

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use Data::Stream::Bulk::Filter;

	Data::Stream::Bulk::Filter->new(
		filter => sub { ... },
		stream => $stream,
	);

=head1 DESCRIPTION

This class implements filtering of streams.

=head1 ATTRIBUTES

=over 4

=item filter

The code reference to apply to each block.

The block is passed to the filter both in C<$_> and as the first argument.

The return value should be an array reference. If no true value is returned the
output stream does B<not> end, but instead an empty block is substituted (the
parent stream controls when the stream is depleted).

=item stream

The stream to be filtered

=back

=head1 METHODS

=over 4

=item is_done

=item loaded

Delegated to C<stream>

=item next

Calls C<next> on C<stream> and applies C<filter> if a block was returned.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

