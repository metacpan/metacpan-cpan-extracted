package API::Instagram::Tag;

# ABSTRACT: Instagram Tag Object

use Moo;

has name  => ( is => 'ro', required => 1 );
has _data => ( is => 'rwp', lazy => 1, builder => 1, clearer => 1 );

sub media_count {
	my $self = shift;
	$self->_clear_data if shift;
	$self->_data->{media_count}
}


sub recent_medias {
	my $self = shift;
	my $url  = sprintf "tags/%s/media/recent", $self->name;
	API::Instagram->instance->_medias( $url, { @_%2?():@_ } );
}

sub _build__data {
	my $self = shift;
	my $url  = sprintf "tags/%s", $self->name;
	API::Instagram->instance->_get( $url );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Instagram::Tag - Instagram Tag Object

=head1 VERSION

version 0.013

=head1 SYNOPSIS

	my $tag = $instagram->tag('perl');

	printf "Count: %s", $tag->media_count;

	for my $media ( @{ $tag->recent_medias( count => 5) } ) {

		printf "Caption: %s\n", $media->caption;
		printf "Posted by %s (%d likes)\n\n", $media->user->username, $media->likes;

	}

=head1 DESCRIPTION

See L<http://instagr.am/developer/endpoints/tags/>.

=head1 ATTRIBUTES

=head2 name

Returns the Tag name.

=head2 media_count

Returns the total media tagged with it.

=head1 METHODS

=head2 recent_medias

	my $medias = $tag->recent_medias( count => 5 );
	print $_->caption . $/ for @m$edias;

Returns a list of L<API::Instagram::Media> objects of recent medias tagged with it.

Accepts C<count>, C<min_timestamp>, C<min_id>, C<max_id> and C<max_timestamp> as parameters.

=head1 AUTHOR

Gabriel Vieira <gabriel.vieira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gabriel Vieira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
