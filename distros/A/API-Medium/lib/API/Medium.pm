package API::Medium;

# ABSTRACT: Talk with medium.com using their REST API
our $VERSION = '0.902'; # VERSION

use Moose;
use HTTP::Tiny;
use Log::Any qw($log);
use JSON::MaybeXS;
use Module::Runtime 'use_module';

has 'server' => (
    isa     => 'Str',
    is      => 'ro',
    default => 'https://api.medium.com/v1',
);

has 'access_token' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
);

has 'refresh_token' => (
    isa => 'Str',
    is  => 'ro',
);

has '_client' => (
    isa        => 'HTTP::Tiny',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__client {
    my $self = shift;

    return HTTP::Tiny->new(
        agent           => join( '/', __PACKAGE__, $VERSION ),
        default_headers => {
            'Authorization' => 'Bearer ' . $self->access_token,
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
        }
    );
}

sub get_current_user {
    my $self = shift;

    my $res = $self->_request( 'GET', 'me' );

    return $res->{data};
}

sub create_post {
    my ( $self, $user_id, $post ) = @_;

    $post->{publishStatus} ||= 'draft';

    my $res = $self->_request( 'POST', 'users/' . $user_id . '/posts', $post );
    return $res->{data}{url};
}

sub create_publication_post {
    my ( $self, $publication_id, $post ) = @_;

    $post->{publishStatus} ||= 'draft';

    my $res =
        $self->_request( 'POST', 'publications/' . $publication_id . '/posts',
        $post );
    return $res->{data}{url};
}

sub _request {
    my ( $self, $method, $endpoint, $data ) = @_;

    my $url = join( '/', $self->server, $endpoint );

    my $res;
    if ($data) {
        $res = $self->_client->request( $method, $url,
            { content => encode_json($data) } );
    }
    else {
        $res = $self->_client->request( $method, $url );
    }
    if ( $res->{success} ) {
        return decode_json( $res->{content} );
    }
    else {
        $log->errorf( "Could not talk to medium: %i %s",
            $res->{status}, $res->{reason} );
        die join( ' ', $res->{status}, $res->{reason} );
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Medium - Talk with medium.com using their REST API

=head1 VERSION

version 0.902

=head1 SYNOPSIS

  use API::Medium;
  my $m = new({
      access_token=>'your_token',
  });
  my $hash = $m->get_current_user;
  say $hash->{id};

  my $url       = $m->create_post( $user_id, $post );

  my $other_url = $m->create_publication_post( $publication_id, $post );

=head1 DESCRIPTION

It's probably a good idea to read L<the Medium API
docs|https://github.com/Medium/medium-api-docs> first, especially as
the various data structures you have to send (or might get back) are
B<not> documented here.

See F<example/hello_medium.pl> for a complete script.

=head2 Authentication

=head3 OAuth2 Login

Not implemented yet, mostly because medium only support the "web
server" flow and I'm using C<API::Medium> for an installed
application.

=head3 Self-issued access token / Integration token

Go to your L<settings|https://medium.com/me/settings>, scroll down to
"Integration tokens", and either create a new one, or pick the one you
want to use.

=head1 Methods

=head2 new

  my $m = API::Medium->new({
       access_token => $token,
  });

Create a new API client. You will need to pass in your C<$token>, see
above on how to get it. Please make sure no not leak your Integration
Token. If you do, anybody who has it can take over your Medium page!

=head2 get_current_user

  my $data = $m->get_current_user;

Fetch the User "object".

You will need this to get the user C<id> for posting. Depending on
your app you might want to store your C<id> in some config file to
save one API call.

=head2 publications

Not implemented yet. Listing the user's publications

  /users/{{userId}}/publications

=head2 contributors

Not implemented yet. Fetching contributors for a publication.

  /publications/{{publicationId}}/contributors

=head2 create_post

  my $url = $m->create_post( $user_id, $post_data );

Create a new post. If you pass in bad data, Medium will probably
report an error.

C<publishStatus> is set to 'draft' unless you pass in another value.

=head2 create_publication_post

  my $url = $m->create_publication_post( $publication_id, $post_data );

Create a new post under a publication. You will need to figure out the
publication_id by calling the API from the commandline (until
C<publications> is implemented.)

If you pass in bad data, Medium will probably report an error.

C<publishStatus> is set to 'draft' unless you pass in another value.

=head2 TODO

=over

=item * OAuth2 Login

=item * Get a new access_token from refresh_token

=item * C<publications>

=item * C<contributors>

=back

=head2 Thanks

Thanks to Dave Cross for starting L<Cultured
Perl|https://medium.com/cultured-perl>, which prompted me to write
this module so I can auto-post blogposts from L<my private
blog|http://domm.plix.at> to medium.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
