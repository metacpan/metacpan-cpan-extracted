package Data::Stream::Bulk::Callback;
BEGIN {
  $Data::Stream::Bulk::Callback::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::Callback::VERSION = '0.11';
}
use Moose;
# ABSTRACT: Callback based bulk iterator

use namespace::clean -except => 'meta';

with qw(Data::Stream::Bulk::DoneFlag) => { -excludes => [qw(is_done finished)] };

has callback => (
	isa => "CodeRef|Str",
	is  => "ro",
	required => 1,
	clearer  => "finished",
);

sub get_more {
	my $self = shift;
	my $cb = $self->callback;
	$self->$cb;
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::Callback - Callback based bulk iterator

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	Data::Stream::Bulk::Callback->new(
		callback => sub {
			if ( @more_items = get_some() ) {
				return \@more_items;
			} else {
				return; # done
			}
		},
	}

=head1 DESCRIPTION

This class provides a callback based implementation of L<Data::Stream::Bulk>.

=head1 ATTRIBUTES

=over 4

=item callback

The subroutine that is called when more items are needed.

Should return an array reference for the next block, or a false value if there
is nothing left.

=back

=head1 METHODS

=over 4

=item get_more

See L<Data::Stream::Bulk::DoneFlag>.

Reinvokes C<callback>.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

