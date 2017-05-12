package API::Instagram;

# ABSTRACT: Object Oriented Interface for the Instagram REST and Search APIs

our $VERSION = '0.013';

use Moo;
# with 'MooX::Singleton';

use Carp;
use strict;
use warnings;
use Digest::MD5 'md5_hex';

use URI;
use JSON;
use Furl;

use API::Instagram::User;
use API::Instagram::Location;
use API::Instagram::Tag;
use API::Instagram::Media;
use API::Instagram::Media::Comment;
use API::Instagram::Search;

has client_id         => ( is => 'ro', required => 1 );
has client_secret     => ( is => 'ro', required => 1 );
has redirect_uri      => ( is => 'ro', required => 1 );
has scope             => ( is => 'ro', default => sub { 'basic' } );
has response_type     => ( is => 'ro', default => sub { 'code'  } );
has grant_type        => ( is => 'ro', default => sub { 'authorization_code' } );
has code              => ( is => 'rw', isa => sub { confess "Code not provided"        unless $_[0] } );
has access_token      => ( is => 'rw', isa => sub { confess "No access token provided" unless $_[0] } );
has no_cache          => ( is => 'rw', default => sub { 0 } );

has _ua               => ( is => 'ro', default => sub { Furl->new() } );
has _obj_cache        => ( is => 'ro', default => sub { { User => {}, Media => {}, Location => {}, Tag => {}, 'Media::Comment' => {} } } );
has _endpoint_url     => ( is => 'ro', default => sub { 'https://api.instagram.com/v1'                 } );
has _authorize_url    => ( is => 'ro', default => sub { 'https://api.instagram.com/oauth/authorize'    } );
has _access_token_url => ( is => 'ro', default => sub { 'https://api.instagram.com/oauth/access_token' } );

has _debug => ( is => 'rw', lazy => 1 );

my $instance;
sub BUILD { $instance = shift }

sub instance { $instance //= shift->new(@_) }

sub get_auth_url { 
	my $self = shift;

	carp "User already authorized with code: " . $self->code if $self->code;

	my @auth_fields = qw(client_id redirect_uri response_type scope);
	for ( @auth_fields ) {
		carp "ERROR: $_ required for generating authorization URL" and return unless defined $self->$_;
	}

	my $uri = URI->new( $self->_authorize_url );
	$uri->query_form( map { $_ => $self->$_ } @auth_fields );
	$uri->as_string();
}


sub get_access_token {
	my $self = shift;

	my @access_token_fields = qw(client_id redirect_uri grant_type client_secret code);
	for ( @access_token_fields ) {
		carp "ERROR: $_ required for generating access token." and return unless defined $self->$_;
	}

	my $data = { map { $_ => $self->$_ } @access_token_fields };
	my $json = $self->_request( 'post', $self->_access_token_url, $data, { token_not_required => 1 } );

	wantarray ? ( $json->{access_token}, $self->user( $json->{user} ) ) : $json->{access_token};
}


sub media { shift->_get_obj( 'Media', 'id', shift ) }

sub user { shift->_get_obj( 'User', 'id', shift // 'self' ) }

sub location { shift->_get_obj( 'Location', 'id', shift, 1 ) }

sub tag { shift->_get_obj( 'Tag', 'name', shift ) }

sub search {
	my $self = shift;
	my $type = shift;
	API::Instagram::Search->new( type => $type )
}


sub popular_medias {
	my $self = shift;
	my $url  = "/media/popular";
	$self->_medias( $url, { @_%2?():@_ } );
}

sub _comment { shift->_get_obj( 'Media::Comment', 'id', shift ) }

#####################################################
# Returns cached wanted object or creates a new one #
#####################################################
sub _get_obj {
	my ( $self, $type, $key, $code, $optional_code ) = @_;

	my $data = { $key => $code };
	$data = $code if ref $code eq 'HASH';
	$code = $data->{$key};

	# Returns if CODE is not optional and not defined or if it's not a string
	return if (!$optional_code and !defined $code) or ref $code;

	# Code used as cache key
	my $cache_code = md5_hex( $code // $data);

	# Returns cached value or creates a new object
	my $return = $self->_cache($type)->{$cache_code} //= ("API::Instagram::$type")->new( $data );

	# Deletes cache if no-cache is set
	delete $self->_cache($type)->{$cache_code} if $self->no_cache;

	return $return;
}

###################################
# Returns a list of Media Objects #
###################################
sub _medias {
	my ($self, $url, $params, $opts) = @_;
	$params->{count} //= 33;
	$params->{url}     = $url;
	[ map { $self->media($_) } $self->_get_list( { %$params, url => $url }, $opts ) ]
}

####################################################################
# Returns a list of the requested items. Does pagination if needed #
####################################################################
sub _get_list {
	my $self   = shift;
	my $params = shift;
	my $opts   = shift;

	my $url      = delete $params->{url} || return [];
	my $count    = $params->{count} // 999_999_999;
	$count       = 999_999_999 if $count < 0;
	$params->{count} = $count;

	my $request = $self->_request( 'get', $url, $params, $opts );
	my $data    = $request->{data};

	# Keeps requesting if total items is less than requested
	# and still there is pagination
	while ( my $pagination = $request->{pagination} ){

		last if     @$data >= $count;
		last unless $pagination->{next_url};

		$opts->{prepared_url} = 1;
		$request = $self->_request( 'get', $pagination->{next_url}, $params, $opts );
		push @$data, @{ $request->{data} };
	}

	return @$data;
}

##############################################################
# Requests the data from the given URL with QUERY parameters #
##############################################################
sub _request {
	my ( $self, $method, $url, $params, $opts ) = @_;

	# Verifies access requirements
	unless ( defined $self->access_token ) {
		if ( !$opts->{token_not_required} or !defined $self->client_id ) {
			carp "A valid access_token is required";
			return {}
		}
	}

	# If URL is not prepared, prepares it
	unless ( $opts->{prepared_url} ){

		$url =~ s|^/||;
		$params->{access_token} = $self->access_token;

		# Prepares the URL
		my $uri = URI->new( $self->_endpoint_url );
		$uri->path_segments( $uri->path_segments, split '/', $url );
		$uri->query_form($params);
		$url = $uri->as_string;
	}

	# For debugging purposes
	print "Requesting: $url$/" if $self->_debug;

	# Treats response content
	my $res = decode_json $self->_ua->$method( $url, [], $params )->decoded_content;

	# Verifies meta node
	my $meta = $res->{meta};
	carp "$meta->{error_type}: $meta->{error_message}" if $meta->{code} ne '200';

use Data::Dumper;
# die Dumper $res;
	$res;
}

sub _request_data { shift->_request(@_)->{data} || {} }

sub _del  { shift->_request_data( 'delete', @_ ) }
sub _get  { shift->_request_data( 'get',    @_ ) }
sub _post { shift->_request_data( 'post',   @_ ) }

################################
# Returns requested cache hash #
################################
sub _cache { shift->_obj_cache->{ shift() } }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Instagram - Object Oriented Interface for the Instagram REST and Search APIs

=for Pod::Coverage client_id client_secret grant_type no_cache redirect_uri response_type scope BUILD

=for HTML <a href="https://travis-ci.org/gabrielmad/API-Instagram"><img src="https://travis-ci.org/gabrielmad/API-Instagram.svg?branch=build%2Fmaster"></a>

=for HTML <a href='https://coveralls.io/r/gabrielmad/API-Instagram?branch=build%2Fmaster'><img src='https://coveralls.io/repos/gabrielmad/API-Instagram/badge.png?branch=build%2Fmaster' alt='Coverage Status' /></a>

=head1 VERSION

version 0.013

=head1 SYNOPSIS

	use API::Instagram;

	my $instagram = API::Instagram->new({
			client_id     => $client_id,
			client_secret => $client_secret,
			redirect_uri  => 'http://localhost',
	});

	# Authenticated user feed
	my $my_user = $instagram->user;
	my $feed    = $my_user->feed( count => 5 );

	for my $media ( @$feed ) {

		printf "Caption: %s\n", $media->caption;
		printf "Posted by %s at %s (%d likes)\n\n", $media->user->username, $media->created_time, $media->likes;

	}

=head1 DESCRIPTION

This module implements an OO interface to Instagram REST API.

=head2 Authentication

Instagram API uses the OAuth2 for authentication, requering a C<client_id> and
C<client_secret>. See L<http://instagr.am/developer/register/> for details.

=head3 Authorize

Get the AUTH URL to authenticate.

	use API::Instagram;

	my $instagram = API::Instagram->new({
			client_id     => 'xxxxxxxxxx',
			client_secret => 'xxxxxxxxxx',
			redirect_uri  => 'http://localhost',
			scope         => 'basic',
			response_type => 'code',
			granty_type   => 'authorization_code',
	});

	print $instagram->get_auth_url;

=head3 Authenticate

After authorization, Instagram will redirected the user to the URL in
C<redirect_uri> with a code as an URL query parameter. This code is needed
to obtain an acess token.

	$instagram->code( $code );
	my $access_token = $instagram->get_access_token;

=head3 Request

With the access token its possible to do Instagram API requests using the
authenticated user credentials.

	$instagram->access_token( $access_token );
	my $me = $instagram->user;
	print $me->full_name;

=head1 METHODS

=head2 new

	my $instagram = API::Instagram->new({
			client_id     => $client_id,
			client_secret => $client_secret,
			redirect_uri  => 'http://localhost',
			scope         => 'basic',
			response_type => 'code',
			granty_type   => 'authorization_code',
			no_cache      => 1,
	});

Returns an L<API::Instagram> object.

Set C<client_id>, C<client_secret> and C<redirect_uri> with the ones registered
to your application. See L<http://instagram.com/developer/clients/manage/>.

C<scope> is the scope of access. See L<http://instagram.com/developer/authentication/#scope>.

C<response_type> and C<granty_type> do no vary. See L<http://instagram.com/developer/authentication/>.

By default, L<API::Instagram> caches created objects to avoid duplications. You can disable
this feature setting a true value to C<no_chace> parameter.

=head2 instance

	my $instagram = API::Instagram->instance;
	print $instagram->user->full_name;

	or

	my $instagram = API::Instagram->instance({
			client_id     => $client_id,
			client_secret => $client_secret,
			redirect_uri  => 'http://localhost',
	});

Returns the singleton instance of L<API::Instagram>.

Note: if no instance was created before, creates a new L<API::Instagram> object initialized with arguments provided and then returns it.

=head2 get_auth_url

	my $auth_url = $instagram->get_auth_url;
	print $auth_url;

Returns an Instagram authorization URL.

=head2 get_access_token

	my $access_token = $instagram->get_access_token;

	or

	my ( $access_token, $auth_user ) = $instagram->get_access_token;

Returns the access token string if the context is looking for a scalar, or an
array containing the access token string and the authenticated user
L<API::Instagram::User> object if looking for a list value.

=head2 media

	my $media = $instagram->media( $media_id );
	say $media->type;

Get information about a media object. Returns an L<API::Instagram::Media> object.

=head2 user

	my $me = $instagram->user; # Authenticated user
	say $me->username;

	my $user = $instagram->user( $user_id );
	say $user->full_name;

Get information about an user. Returns an L<API::Instagram::User> object.

=head2 location

	my $location = $instagram->location( $location_id );
	say $location->name;

Get information about a location. Returns an L<API::Instagram::Location> object.

=head2 tag

	my $tag = $instagram->tag('perl');
	say $tag->media_count;

Get information about a tag. Returns an L<API::Instagram::Tag> object.

=head2 search

	my $search = $instagram->search('user');
	my $users = $search->find( q => 'larry' );
	for my $user ( @$users ) {
		say $user->username;
	}

Returns an L<API::Instagram::Search> object, capable to search for the given B<type>.

Where B<type> can be: C<user>, C<media>, C<tag> or C<location>.

See L<API::Instagram::Search> for more details and examples.

=head2 popular_medias

	my $medias = $user->popular_medias( count => 3 );
	print $_->caption . $/ for @$medias;

Returns a list of L<API::Instagram::Media> objects of Instagram most popular media at the moment.

=head1 AUTHOR

Gabriel Vieira <gabriel.vieira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gabriel Vieira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
