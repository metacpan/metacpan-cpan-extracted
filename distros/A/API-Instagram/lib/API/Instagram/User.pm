package API::Instagram::User;

# ABSTRACT: Instagram User Object

use Moo;
use Carp;

has id              => ( is => 'ro', required => 1 );
has username        => ( is => 'lazy' );
has full_name       => ( is => 'lazy' );
has bio             => ( is => 'lazy' );
has website         => ( is => 'lazy' );
has profile_picture => ( is => 'lazy' );
has _api            => ( is => 'lazy' );
has _data           => ( is => 'rwp', lazy => 1, builder => 1, clearer => 1 );

sub media {
	my $self = shift;
	$self->_clear_data if shift;
	return $_->{media} for $self->_data->{counts}
}

sub follows {
	my $self = shift;
	$self->_clear_data if shift;
	return $_->{follows} for $self->_data->{counts}
}

sub followed_by {
	my $self = shift;
	$self->_clear_data if shift;
	return $_->{followed_by} for $self->_data->{counts}
}


sub feed {
	my $self = shift;
	my @list = $self->_self_requests( 'feed', '/users/self/feed', @_ ) or return;
	[ map { $self->_api->media($_) } @list ];
}


sub liked_media {
	my $self = shift;
	my @list = $self->_self_requests( 'liked-media', '/users/self/media/liked', @_ ) or return;
	[ map { $self->_api->media($_) } @list ];
}


sub requested_by {
	my $self = shift;
	my @list = $self->_self_requests( 'requested-by', '/users/self/requested-by', @_ ) or return;
	[ map { $self->_api->user($_) } @list ];
}


sub get_follows {
	shift->_get_relashions( @_, relationship => 'follows' );
}


sub get_followers {
	shift->_get_relashions( @_, relationship => 'followed-by' );
}


sub recent_medias {
	my $self = shift;
	my $url  = sprintf "users/%s/media/recent", $self->id;
	$self->_api->_medias( $url, { @_%2?():@_ }, { token_not_required => 1 } );
}

sub relationship {
	my $self    = shift;
	my $action  = shift;
	my $url     = sprintf "users/%s/relationship", $self->id;
	my @actions = qw/ follow unfollow block unblock approve ignore/;

	use experimental 'smartmatch';
	if ( $action ) {
		if ( $action ~~ @actions ){
			return $self->_api->_post( $url, { action => $action } )
		}
		carp "Invalid action";
	}

	$self->_api->_get( $url );
}


sub _get_relashions {
	my $self = shift;
	my %opts = @_;
	my $url  = sprintf "users/%s/%s", $self->id, $opts{relationship};
	my $api  = $self->_api;
	[ map { $api->user($_) } $api->_get_list( { %opts, url => $url } ) ]
}

sub _self_requests {
	my ($self, $type, $url, %opts) = @_;

	if ( $self->id ne $self->_api->user->id ){
		carp "The $type is only available for the authenticated user";
		return;
	}

	$self->_api->_get_list( { %opts, url => $url } )
}


sub BUILDARGS {
	my $self = shift;
	my $opts = shift;

	$opts->{profile_picture} //= delete $opts->{profile_pic_url} if exists $opts->{profile_pic_url};

	return $opts;
}


sub _build__api            { API::Instagram->instance        }
sub _build_username        { shift->_data->{username}        }
sub _build_full_name       { shift->_data->{full_name}       }
sub _build_bio             { shift->_data->{bio}             }
sub _build_website         { shift->_data->{website}         }
sub _build_profile_picture { shift->_data->{profile_picture} }

sub _build__data {
	my $self = shift;
	my $url  = sprintf "users/%s", $self->id;
	$self->_api->_get( $url );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Instagram::User - Instagram User Object

=for Pod::Coverage BUILDARGS

=head1 VERSION

version 0.013

=head1 SYNOPSIS

	my $me    = $instagram->user;
	my $other = $instagra->user(12345);

	printf "My username is %s and I follow %d other users.\n", $me->username, $me->follows;
	printf "The other user full name is %s", $other->full_name;

=head1 DESCRIPTION

See L<http://instagr.am/developer/endpoints/users/> and L<http://instagram.com/developer/endpoints/relationships/>.

=head1 ATTRIBUTES

=head2 id

Returns user id.

=head2 username

Returns user username.

=head2 full_name

Returns user full name.

=head2 bio

Returns user biography text.

=head2 website

Returns user website.

=head2 profile_picture

Returns user profile picture url.

=head2 media

Returns user total media.

=head2 follows

Returns user total follows.

=head2 followed_by

Returns user total followers.

=head1 METHODS

=head2 feed

	my $medias = $user->feed( count => 5 );
	print $_->caption . $/ for @$medias;

Returns a list of L<API::Instagram::Media> objects of the authenticated user feed.

Accepts C<count>, C<min_id> and C<max_id> as parameters.

=head2 liked_media

	my $medias = $user->liked_media( count => 5 );
	print $_->caption . $/ for @$medias;

Returns a list of L<API::Instagram::Media> objects of medias liked by the authenticated user.

Accepts C<count> and C<max_like_id> as parameters.

=head2 requested_by

	my $requested_by = $user->get_requested_by( count => 5 );
	print $_->username . $/ for @$requested_by;

Returns a list of L<API::Instagram::User> objects of users who requested this user's permission to follow.

Accepts C<count> as parameter.

=head2 get_follows

	my $follows = $user->get_follows( count => 5 );
	print $_->username . $/ for @$follows;

Returns a list of L<API::Instagram::User> objects of users this user follows.

Accepts C<count> as parameter.

=head2 get_followers

	my $followers = $user->get_followers( count => 5 );
	print $_->username . $/ for @$followers;

Returns a list of L<API::Instagram::User> objects of users this user is followed by.

Accepts C<count> as parameter.

=head2 recent_medias

	my $medias = $user->recent_medias( count => 5 );
	print $_->caption . $/ for @$medias;

Returns a list of L<API::Instagram::Media> objects of user's recent medias.

Accepts C<count>, C<min_timestamp>, C<min_id>, C<max_id> and C<max_timestamp> as parameters.

=head2 relationship

	my $relationship = $user->relationship;
	say $relationship->{incoming_status};

Returns a C<HASH> reference contaning information about the relationship of the user with the authenticated user.

This reference contains two keys:

B<outgoing_status:> Authenticated user relationship to the user. Can be C<follows>, C<requested>, C<none>. 

B<incoming_status:> A user's relationship to the authenticated user. Can be C<followed_by>, C<requested_by>, C<blocked_by_you>, C<none>.

	$user->relationship('follow');

When an B<action> (as parameter) is given, it sends a request to modify the relationship to the given one.

The B<action> can be one of C<follow>/C<unfollow>/C<block>/C<unblock>/C<approve>/C<ignore>.

=head1 AUTHOR

Gabriel Vieira <gabriel.vieira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gabriel Vieira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
