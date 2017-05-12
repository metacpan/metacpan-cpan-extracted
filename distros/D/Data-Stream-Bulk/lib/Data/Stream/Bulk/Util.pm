package Data::Stream::Bulk::Util;
BEGIN {
  $Data::Stream::Bulk::Util::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::Util::VERSION = '0.11';
}

use strict;
use warnings;
# ABSTRACT: Utility functions for L<Data::Stream::Bulk>

use Data::Stream::Bulk::Nil;
use Data::Stream::Bulk::Array;

use Scalar::Util qw(refaddr);

use namespace::clean;

use Sub::Exporter -setup => {
	exports => [qw(nil bulk cat filter unique)],
};

# use constant nil => Data::Stream::Bulk::Nil->new;
sub nil () { Data::Stream::Bulk::Nil->new }

sub bulk (@) { return @_ ? Data::Stream::Bulk::Array->new( array => [ @_ ] ) : nil }

sub cat (@) { return @_ ? shift->cat(@_) : nil }

sub filter (&$) {
	my ( $filter, $stream ) = @_;
	$stream->filter($filter);
}

sub unique ($) {
	my %seen;
	shift->filter(sub { [ grep { !$seen{ref($_) ? refaddr($_) : $_}++ } @$_ ] }); # FIXME Hash::Util::FieldHash::Compat::id()?
}

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::Util - Utility functions for L<Data::Stream::Bulk>

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use Data::Stream::Bulk::Util qw(array);

	use namespace::clean;

	# Wrap a list in L<Data::Stream::Bulk::Array>
	return bulk(qw(foo bar gorch baz));

	# return an empty resultset
	return nil();

=head1 DESCRIPTION

This module exports convenience functions for use with L<Data::Stream::Bulk>.

=head1 EXPORTS

L<Sub::Exporter> is used to create the C<import> routine, and all of its
aliasing/currying goodness is of course supported.

=over 4

=item nil

Creates a new L<Data::Stream::Bulk::Nil> object.

Takes no arguments.

=item bulk @items

Creates a new L<Data::Stream::Bulk::Array> wrapping C<@items>.

=item cat @streams

Concatenate several streams together.

Returns C<nil> if no arguments are provided.

=item filter { ... } $stream

Calls C<filter> on $stream with the provided filter.

=item unique $stream

Filter the stream to remove duplicates.

Note that memory use may potentially scale to O(k) where k is the number of
distinct items, because this is implemented in terms of a seen hash.

In the future this will be optimized to be iterative for sorted streams.

References are keyed by their refaddr (see L<Hash::Util::FieldHash/id>).

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

