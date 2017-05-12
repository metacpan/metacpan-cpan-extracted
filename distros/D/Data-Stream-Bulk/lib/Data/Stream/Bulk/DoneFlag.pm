package Data::Stream::Bulk::DoneFlag;
BEGIN {
  $Data::Stream::Bulk::DoneFlag::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::DoneFlag::VERSION = '0.11';
}
use Moose::Role;
# ABSTRACT: Implement the C<is_done> method in terms of a flag

use namespace::clean -except => 'meta';

with qw(Data::Stream::Bulk);

requires "get_more";

sub is_done {}
has done => (
	isa => "Bool",
	init_arg => undef,
	reader => "is_done",
	writer => "_done",
);

sub finished {}

sub _set_done {
	my $self = shift;
	$self->_done(1);
	$self->finished;
}

sub next {
	my $self = shift;

	unless ( $self->is_done ) {
		if ( my $more = $self->get_more ) {
			return $more;
		} else {
			$self->_set_done;
			return;
		}
	} else {
		return;
	}
}

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::DoneFlag - Implement the C<is_done> method in terms of a flag

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	package Data::Stream::Bulk::Blah;
	use Moose;

	with qw(Data::Stream::Bulk::DoneFlag);

	sub get_more {
		if ( my @more = more() ) {
			return \@more;
		} else {
			return;
		}
	}

=head1 DESCRIPTION

This role implements the C<Data::Stream::Bulk> core API in terms of one method
(C<get_more>).

As a convenience it calls C<finished> when the stream is exhausted, so that
cleanup may be done.

This is used by classes like L<Data::Stream::Bulk::DBI>,
L<Data::Stream::Bulk::Callback>.

=head1 METHODS

=over 4

=item is_done

Returns the state of the iterator.

=item next

As long as the iterator is not yet done, calls C<get_more>.

If C<get_more> returned a false value instead of an array reference then
C<done> is set, C<finished> is called, and this C<next> does nothing on
subsequent calls.

=item finished

A noop by default. Can be overridden if so desired.

=back

=head1 REQUIRED_METHODS

=over 4

=item get_more

Returns the next block of data as an array ref, or a false value if no items
are left.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

