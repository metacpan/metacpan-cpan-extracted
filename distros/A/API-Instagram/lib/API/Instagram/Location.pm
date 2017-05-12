package API::Instagram::Location;

# ABSTRACT: Instagram Location Object

use Moo;
use Carp;

has id        => ( is => 'ro', predicate => 1 );
has latitude  => ( is => 'lazy' );
has longitude => ( is => 'lazy' );
has name      => ( is => 'lazy' );
has _data     => ( is => 'rwp', lazy => 1, builder => 1, clearer => 1 );


sub recent_medias {
	my $self = shift;

	carp "Not available for location with no ID." and return [] unless $self->has_id;

	my $url  = sprintf "locations/%s/media/recent", $self->id;
	API::Instagram->instance->_medias( $url, { @_%2?():@_ } );
}

sub _build_name      { shift->_data->{name}      }
sub _build_latitude  { shift->_data->{latitude}  }
sub _build_longitude { shift->_data->{longitude} }

sub _build__data {
	my $self = shift;
	carp "Not available for location with no ID." and return {} unless $self->has_id;
	my $url  = sprintf "locations/%s", $self->id;
	API::Instagram->instance->_get( $url );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Instagram::Location - Instagram Location Object

=head1 VERSION

version 0.013

=head1 SYNOPSIS

	my $location = $instagram->location(123);

	printf "Media Location: %s (%f,%f)", $location->name, $location->latitude, $location->longitude;

	for my $media ( @{ $location->recent_medias( count => 5) } ) {

		printf "Caption: %s\n", $media->caption;
		printf "Posted by %s (%d likes)\n\n", $media->user->username, $media->likes;

	}

=head1 DESCRIPTION

See L<http://instagr.am/developer/endpoints/locations/>.

=head1 ATTRIBUTES

=head2 id

Returns the location id.

=head2 name

Returns the name of the location.

=head2 latitude

Returns the latitude of the location.

=head2 longitude

Returns the longitude of the location.

=head1 METHODS

=head2 recent_medias

	my $medias = $location->recent_medias( count => 5 );
	print $_->caption . $/ for @$medias;

Returns a list of L<API::Instagram::Media> objects of recent medias from the location.

Accepts C<count>, C<min_timestamp>, C<min_id>, C<max_id> and C<max_timestamp> as parameters.

=head1 AUTHOR

Gabriel Vieira <gabriel.vieira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gabriel Vieira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
