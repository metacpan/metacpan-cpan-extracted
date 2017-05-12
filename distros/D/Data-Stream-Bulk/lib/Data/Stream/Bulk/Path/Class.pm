package Data::Stream::Bulk::Path::Class;
BEGIN {
  $Data::Stream::Bulk::Path::Class::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::Path::Class::VERSION = '0.11';
}
use Moose;
# ABSTRACT: L<Path::Class::Dir> traversal

use Path::Class;
use Carp qw(croak);

use namespace::clean -except => 'meta';

with qw(Data::Stream::Bulk);

has dir => (
	isa => "Path::Class::Dir",
	is  => "ro",
	required => 1,
);

has depth_first => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has only_files => (
	isa => "Bool",
	is  => "ro",
);

has chunk_size => (
	isa => "Int",
	is  => "rw",
	default => 250,
);

has _stack => (
	isa => "ArrayRef",
	is  => "ro",
	default => sub { [] },
);

has _queue => (
	isa => "ArrayRef",
	is  => "ro",
	lazy => 1,
	default => sub {
		my $self = shift;
		return [ $self->dir ],
	},
);

sub is_done {
	my $self = shift;
	return (
		@{ $self->_stack } == 0
			and
		@{ $self->_queue } == 0
	);
}

sub next {
	my $self = shift;

	my $queue = $self->_queue;
	my $stack = $self->_stack;

	my $depth_first = $self->depth_first;
	my $only_files  = $self->only_files;
	my $chunk_size  = $self->chunk_size;

	my @ret;

	{
		outer: while ( @$stack ) {
			my $frame = $stack->[-1];

			my ( $dh, $parent ) = @$frame;

			while ( defined(my $entry = $dh->read) ) {
				next if $entry eq '.' || $entry eq '..';

				my $path = $parent->file($entry);

				if ( -d $path ) {
					my $dir = $parent->subdir($entry);

					if ( $depth_first ) {
						unshift @$queue, $dir;
					} else {
						push @$queue, $dir;
					}

					last outer;
				} else {
					push @ret, $path;
					return \@ret if @ret >= $chunk_size;
				}
			}

			# we're done reading this dir
			pop @$stack;
		}

		if ( @$queue ) {
			my $dir = shift @$queue;
			my $dh = $dir->open || croak("Can't open directory $dir: $!");

			if ( $depth_first ) {
				push @$stack, [ $dh, $dir ];
			} else {
				unshift @$stack, [ $dh, $dir ];
			}

			unless ( $only_files ) {
				push @ret, $dir;
				return \@ret if @ret >= $chunk_size;
			}

			redo;
		}
	}

	return unless @ret;
	return \@ret;
}


__PACKAGE__->meta->make_immutable;

__PACKAGE__;



=pod

=head1 NAME

Data::Stream::Bulk::Path::Class - L<Path::Class::Dir> traversal

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use Data::Stream::Bulk::Path::Class;

	my $dir = Data::Stream::Bulk::Path::Class->new(
		dir => Path::Class::Dir->new( ... ),
	);

=head1 DESCRIPTION

This stream produces depth or breadth first traversal order recursion through
L<Path::Class::Dir> objects.

Items are read iteratively, and a stack of open directory handles is used to
keep track of state.

=head1 ATTRIBUTES

=over 4

=item chunk_size

Defaults to 250.

=item depth_first

Chooses between depth first and breadth first traversal order.

=item only_files

If true only L<Path::Class::File> items will be returned in the output streams
(no directories).

=back

=head1 METHODS

=over 4

=item is_done

Returns true when no more files are left to iterate.

=item next

Returns the next chunk of L<Path::Class> objects

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

