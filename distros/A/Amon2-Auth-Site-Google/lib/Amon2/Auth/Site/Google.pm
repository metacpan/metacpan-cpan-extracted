package Amon2::Auth::Site::Google;
use Mouse;

use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = "0.04";

has client_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has client_secret => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has redirect_url => (
    is  => 'ro',
    isa => 'Str',
);

has scope => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [qw(https://www.googleapis.com/auth/userinfo.profile)] },
);

has user_info => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

has authorize_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://accounts.google.com/o/oauth2/auth',
);

has token_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://accounts.google.com/o/oauth2/token',
);

has token_info_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://www.googleapis.com/oauth2/v1/tokeninfo',
);

has user_info_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://www.googleapis.com/oauth2/v1/userinfo',
);

has ua => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        LWP::UserAgent->new(agent => "Amon2::Auth::Site::Google/$VERSION");
    },
);

no Mouse;
__PACKAGE__->meta->make_immutable;

sub moniker { 'google' }

sub auth_uri {
    my ($self, $c, $callback_uri) = @_;

    my $uri = URI->new($self->authorize_url);
    $uri->query_form(+{
        client_id       => $self->client_id,
        scope           => $self->scope,
        redirect_uri    => $callback_uri,
        response_type   => 'code',
        access_type     => 'offline',
        approval_prompt => 'force',
    });
    return $uri->as_string;
}

sub callback {
    my ($self, $c, $callback) = @_;

    my $res = $self->ua->post($self->token_url, +{
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        code          => $c->req->param('code'),
        redirect_uri  => $self->redirect_url,
        grant_type    => 'authorization_code',
    });
    $res->is_success or do {
        warn $res->decoded_content;
        return $callback->{on_error}->($res->decoded_content);
    };
    my $token = decode_json $res->content;

    my $uri = URI->new($self->token_info_url);
    $uri->query_form(+{ access_token => $token->{access_token} });
    $res = $self->ua->get($uri->as_string);
    my $token_info = decode_json $res->content;
    $res->is_success or do {
        warn $res->decoded_content;
        return $callback->{on_error}->($res->decoded_content);
    };
    $token_info->{audience} eq $self->client_id or do {
        warn 'invalid token';
        return $callback->{on_error}->('invalid token');
    };
    my @args = ($token->{access_token}, $token->{refresh_token});

    if ($self->user_info) {
        my $uri = URI->new($self->user_info_url);
        $uri->query_form(+{ access_token => $token->{access_token} });
        my $res = $self->ua->get($uri->as_string);
        $res->is_success or do {
            warn $res->decoded_content;
            return $callback->{on_error}->($res->decoded_content);
        };
        my $user = decode_json $res->content;
        push @args, $user;
    }

    $callback->{on_finished}->(@args);
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Auth::Site::Google - Google auth integration for Amon2

=head1 SYNOPSIS

    #add config
    +{
        Auth => {
	    Google => {
                client_id     => 'client id',
                client_secret => 'client secret',
                redirect_url  => 'redirect url',
                scope         => ['scope']
            }
        }
    }

    #add app
    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'Google',
        on_finished => sub {
            my ($c, $access_token, $refresh_token, $user) = @_;

            my $id       = $user->{id};       #e.g. 123456789
            my $name     = $user->{name};     #e.g. Nao Takanashi
            my $birthday = $user->{birthday}; #e.g. 1988-07-25

            $c->session->set(google => +{
                access_token  => $access_token,
                refresh_token => $refresh_token,
                user          => $user,
            });

            return $c->redirect('/');
        },
        on_error => sub {
            my ($c, $error_message) = @_;
            ...
        },
    });

=head1 DESCRIPTION

Amon2::Auth::Site::Google is a Google authenticate module for Amon2

=head1 ATTRIBUTES

=over

=item client_id (required)

=item client_secret (required)

=item redirect_url (required)

=item scope (Default: [qw(https://www.googleapis.com/auth/userinfo.profile)])

=item user_info (Default: true)

If true, this module fetch user data immediately after authentication.

=back

=head1 METHODS

=over

=item C<< $auth->auth_uri($c:Amon2::Web, $callback_uri : Str) :Str >>
Get a authenticate URI.

=item C<< $auth->callback($c:Amon2::Web, $callback:HashRef) : Plack::Response >>
Process the authentication callback dispatching.


=over

=item on_error

on_error callback function is called when an error occurs.

The arguments are following:

    sub {
        my ($c, $error_message) = @_;
        ...
    }

=item on_finished

on_finished callback function is called if an authentication was finished.ck function is called After successful authentication.

The arguments are following:

    sub {
        my ($c, $access_token, $refresh_token, $user) = @_;
        ...
    }

If you set $auth-user_info> as a false value, authentication engine does not pass $user.

=back

=back

=head1 SEE ALSO

=over

=item * Using OAuth 2.0 to Access Google APIs
L<https://developers.google.com/accounts/docs/OAuth2>

=item * Amon2::Plugin::Web::Auth
L<https://metacpan.org/module/TOKUHIROM/Amon2-Auth-0.03/lib/Amon2/Plugin/Web/Auth.pm>

=back

=head1 LICENSE

Copyright (C) ntakanashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ntakanashi E<lt>ntakanashi666 at gmail.comE<gt>

=cut

