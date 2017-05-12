package Data::Stream::Bulk::DBIC;
BEGIN {
  $Data::Stream::Bulk::DBIC::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::DBIC::VERSION = '0.11';
}
use Moose;
# ABSTRACT: Iterate DBIC resultsets with L<Data::Stream::Bulk>

use namespace::clean -except => 'meta';

with qw(Data::Stream::Bulk::DoneFlag) => { -excludes => [qw(is_done finished)] };

has resultset => (
	isa => "Object",
	clearer => "finished",
	handles => { next_row => "next" },
	required => 1,
);

sub get_more {
	my $self = shift;

	if ( defined( my $next = $self->next_row ) ) {
		return [ $next ];
	} else {
		return;
	}
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::DBIC - Iterate DBIC resultsets with L<Data::Stream::Bulk>

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	Data::Stream::Bulk::DBIC->new(
		resultset => scalar($schema->rs("Foo")->search(...))
	);

=head1 DESCRIPTION

This is a wrapper for L<DBIx::Class::ResultSet> that fits the
L<Data::Stream::Bulk> api.

Due to the fact that DBIC inflation overhead is fairly negligiable to that of
iteration though, I haven't actually bothered to make it bulk.

If L<DBIx::Class::Cursor> will support n-at-a-time fetching as opposed to
one-at-a-time or all-at-a-time at some point in the future this class will be
updated to match.

=head1 METHODS

=over 4

=item get_more

See L<Data::Stream::Bulk::DoneFlag>.

Returns a single row. In the future this should return more than one row.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

