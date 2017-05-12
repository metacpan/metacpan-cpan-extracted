package Data::Stream::Bulk::Nil;
BEGIN {
  $Data::Stream::Bulk::Nil::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::Nil::VERSION = '0.11';
}
use Moose;
# ABSTRACT: An empty L<Data::Stream::Bulk> iterator

use namespace::clean -except => 'meta';

with qw(Data::Stream::Bulk) => { -excludes => [qw/loaded filter list_cat all items/] };

sub items { return () }

sub all { return () }

sub next { undef }

sub is_done { 1 }

sub list_cat {
	my ( $self, $head, @rest ) = @_;

	return () unless $head;
	return $head->list_cat(@rest);
}

sub filter { return $_[0] };

sub loaded { 1 }

__PACKAGE__->meta->make_immutable;

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::Nil - An empty L<Data::Stream::Bulk> iterator

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	return Data::Stream::Bulk::Nil->new; # empty set

=head1 DESCRIPTION

This iterator can be used to return the empty resultset.

=head1 METHODS

=over 4

=item is_done

Always returns true.

=item next

Always returns undef.

=item items

=item all

Always returns the empty list.

=item list_cat

Skips $self

=item filter

Returns $self

=item loaded

Returns true.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

