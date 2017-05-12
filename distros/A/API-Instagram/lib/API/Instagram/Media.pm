package API::Instagram::Media;

# ABSTRACT: Instagram Media Object

use Moo;
use Time::Moment;

has id             => ( is => 'ro', required => 1 );
has type           => ( is => 'lazy' );
has link           => ( is => 'lazy' );
has filter         => ( is => 'lazy' );
has images         => ( is => 'lazy' );
has videos         => ( is => 'lazy' );
has user           => ( is => 'lazy', coerce => \&_coerce_user           );
has tags           => ( is => 'lazy', coerce => \&_coerce_tags           );
has location       => ( is => 'lazy', coerce => \&_coerce_location       );
has users_in_photo => ( is => 'lazy', coerce => \&_coerce_users_in_photo );
has caption        => ( is => 'lazy', coerce => sub { $_[0]->{text} if $_[0] and ref $_[0] eq 'HASH' } );
has created_time   => ( is => 'lazy', coerce => sub { Time::Moment->from_epoch( $_[0] ) } );
has _api           => ( is => 'lazy' );
has _data          => ( is => 'rwp', lazy => 1, builder => 1, clearer => 1 );

sub likes {
	my $self = shift;
	$self->_clear_data if shift;
	$self->_data->{likes}->{count}
}

sub last_likes {
	my $self = shift;
	$self->_clear_data if shift;
	my $api  = $self->_api;
	[ map { $api->user($_) } @{ $self->_data->{likes}->{data} } ]
}

sub get_likes {
	my $self = shift;
	my %opts = @_;
	my $url  = sprintf "media/%s/likes", $self->id;
	my $api  = $self->_api;
	[ map { $api->user($_) } $api->_get_list( { %opts, url => $url } ) ]
}

sub like {
	my $self = shift;
	my $url  = sprintf "media/%s/likes", $self->id;
	$self->_api->_post( $url )
}

sub dislike {
	my $self = shift;
	my $url  = sprintf "media/%s/likes", $self->id;
	$self->_api->_del( $url )
}

sub comments {
	my $self = shift;
	$self->_clear_data if shift;
	$self->_data->{comments}->{count}
}

sub last_comments {
	my $self = shift;
	$self->_clear_data if shift;
	my $api  = $self->_api;
	[ map { $api->_comment( { %$_, media => $self } ) } @{ $self->_data->{comments}->{data} } ]
}

sub get_comments {
	my $self = shift;
	my %opts = @_;
	my $url  = sprintf "media/%s/comments", $self->id;
	my $api  = $self->_api;
	[ map { $api->_comment( { %$_, media => $self } ) } $api->_get_list( { %opts, url => $url } ) ]
}

sub comment {
	my $self = shift;
	my $text = shift;
	my $url  = sprintf "media/%s/comments", $self->id;
	$self->_api->_post( $url, { text => $text } )
}


sub _build__api           { API::Instagram->instance       }
sub _build_user           { shift->_data->{user}           }
sub _build_tags           { shift->_data->{tags}           }
sub _build_location       { shift->_data->{location}       }
sub _build_users_in_photo { shift->_data->{users_in_photo} }
sub _build_type           { shift->_data->{type}           }
sub _build_link           { shift->_data->{link}           }
sub _build_filter         { shift->_data->{filter}         }
sub _build_images         { shift->_data->{images}         }
sub _build_videos         { shift->_data->{videos}         }
sub _build_caption        { shift->_data->{caption }       }
sub _build_created_time   { shift->_data->{created_time}   }

sub _build__data {
	my $self = shift;
	my $url  = sprintf "media/%s", $self->id;
	$self->_api->_get( $url );
}

############################################################
# Attributes coercion that API::Instagram object reference #
############################################################
sub _coerce_user     { API::Instagram->instance->user    ( $_[0] ) };
sub _coerce_location { API::Instagram->instance->location( $_[0] ) if $_[0] };

sub _coerce_tags {
	my $data = $_[0];
	return if ref $data ne 'ARRAY';
	[ map { API::Instagram->instance->tag($_) } @$data ]
};
	
sub _coerce_users_in_photo {
	my $data = $_[0];
	return if ref $data ne 'ARRAY';
	[
		map {{
			user     => API::Instagram->instance->user( $_->{user} ),
			position => $_->{position},
		}} @$data
	]
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Instagram::Media - Instagram Media Object

=head1 VERSION

version 0.013

=head1 SYNOPSIS

	my $media = $instagram->media(3);

	printf "Caption: %s\n", $media->caption;
	printf "Posted by %s (%d likes)\n\n", $media->user->username, $media->likes;

	my $location = $media->location;
	printf "Media Location: %s (%f,%f)", $location->name, $location->latitude, $location->longitude;

=head1 DESCRIPTION

See L<http://instagr.am/developer/endpoints/media/>.

=head1 ATTRIBUTES

=head2 id

Returns media id.

=head2 type

Returns media type.

=head2 user

Returns the L<API::Instagram::User> object of the user who posted the media.

=head2 link

Returns media shortlink.

=head2 filter

Returns media filter.

=head2 tags

Returns a list L<API::Instagram::Tag> objects of media tags.

=head2 location

Returns media L<API::Instagram::Location> object.

=head2 images

	my $thumbnail = $media->images->{thumbnail};
	printf "URL: %s (%d x %d)" $thumbnail->{url}, $thumbnail->{width}, $thumbnail->{height};

Returns media images options and details.

=head2 videos

	my $standart = $media->videos->{standart_resolution};
	printf "URL: %s (%d x %d)" $standart->{url}, $standart->{width}, $standart->{height};

Returns media videos options and details, when video type.

=head2 users_in_photo

	for my $each ( @{ $media->users_in_photo } ) {

		my $user     = $each->{user};
		my $position = $each->{position};

		printf "%s is at %f, %f\n", $user->username, $position->{x}, $position->{y};

	}

Returns a list of L<API::Instagram::User> objects of users tagged in the media with their coordinates.

=head2 caption

Returns media caption text.

=head2 created_time

Returns the media date in a L<Time::Moment> object.

=head1 METHODS

=head2 likes

	printf "Total Likes: %d\n", $media->likes; # Total likes when object was created

	or

	printf "Total Likes: %d\n", $media->likes(1); # Up to date total likes

Returns media total likes.
If you set C<1> as parameter it will renew all media data and return an up-do-date total likes.

Note: C<1> as parameter also updates total comments, last likes and last comments.

=head2 last_likes

	for my $user ( @{ $media->last_likes } ) {
		say $user->username;
	}

Returns a list of C<API::Instagram::User> of the last users who liked the media.
If you set C<1> as parameter it will renew all media data and return an up-do-date list.

Note: C<1> as parameter also updates total likes, total comments and last comments.

=head2 get_likes

	my @likers = $media->get_likes( count => 5 );

Returns a list of L<API::Instagram::User> objects of users who liked the media.

Accepts C<count>.

=head2 like

	$media->like;

Sets a like on the media by the authenticated user.

=head2 dislike

	$media->dislike;

Removes a like on the media by the authenticated user.

=head2 comments

	printf "Total Comments: %d\n", $media->comments; # Total comments when object was created

	or

	printf "Total Comments: %d\n", $media->comments(1); # Up to date total comments

Returns media total comments.
If you set C<1> as parameter it will renew all media data and return an up-do-date total comments.

Note: C<1> as parameter also updates total likes, last likes and last comments.

=head2 last_comments

	for my $comment ( @{ $media->last_comments } ) {
		printf "%s: %s\n", $comment->from->username, $comment->text;
	}

Returns a list of C<API::Instagram::Media::Comment> of the last comments on the media.
If you set C<1> as parameter it will renew all media data and return an up-do-date list.

Note: C<1> as parameter also updates total likes, total comments and last likes.

=head2 get_comments

	my @comments = $media->get_comments( count => 5 );

Returns a list of L<API::Instagram::Media::Comment> objects of the media.

Accepts C<count>.

=head2 comment

	$media->comment("Nice pic!");

Creates a comment on the media.

Note: This endpoint is restrict, check  L<https://help.instagram.com/contact/185819881608116> for more information.

=head1 AUTHOR

Gabriel Vieira <gabriel.vieira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gabriel Vieira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
