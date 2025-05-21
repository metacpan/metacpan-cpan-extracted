package Amon2::Auth::Site::LINE;

use strict;
use warnings;
use utf8;
use URI;
use JSON;
use Mouse;
use LWP::UserAgent;
 
our $VERSION = '0.05';

sub moniker { 'line' }

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
 
has redirect_uri => (
    is  => 'ro',
    isa => 'Str',
);

has state => (
    is  => 'ro',
    isa => 'Str',
);

has scope => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [qw(profile)] },
);

has nonce => (
    is  => 'ro',
    isa => 'Str',
);

has prompt => (
    is  => 'ro',
    isa => 'Str',
);

has max_age => (
    is  => 'ro',
    isa => 'Int',
);

has ui_locales => (
    is  => 'ro',
    isa => 'Str',
);

has bot_prompt => (
    is  => 'ro',
    isa => 'Str',
);

has user_info => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has state_session_key => (
    is      => 'ro',
    isa     => 'Str',
    default => 'line_login_state',
);

has nonce_session_key => (
    is      => 'ro',
    isa     => 'Str',
    default => 'line_login_nonce',
);

has authorize_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://access.line.me/oauth2/v2.1/authorize',
);

has access_token_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.line.me/oauth2/v2.1/token',
);

has verify_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.line.me/oauth2/v2.1/verify',
);

has profile_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.line.me/v2/profile',
);

has ua => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        LWP::UserAgent->new(agent => "Amon2::Auth::Site::LINE/$VERSION");
    },
);

sub auth_uri {
    my($self, $c, $callback_uri) = @_;

    # required parameters
    my $redirect_uri = $self->redirect_uri || $callback_uri;
    my %params = (
        response_type => 'code',
        client_id     => $self->client_id,
        scope         => join(' ', @{$self->scope}),
        redirect_uri  => $redirect_uri,
        state         => $self->get_state($c),
    );

    # optional parameters
    $params{nonce} = $self->get_nonce($c);

    for my $key (qw(prompt max_age ui_locales bot_prompt)) {
        my $value = $self->$key;
        if (defined $value) {
            $params{$key} = $value;
        }
    }

    my $auth_uri = URI->new($self->authorize_url);
    $auth_uri->query_form(%params);

    return $auth_uri->as_string;
}

sub callback {
    my($self, $c, $callback) = @_;

    # state mismatch
    if ($c->req->param('state') ne $self->get_state($c)) {
        return $callback->{on_error}->('state parameter mismatch');
    }

    # access denied
    if ($c->req->param('error')) {
        return $callback->{on_error}->($c->req->param('error_description'));
    }
 
    my @args = ();

    my %api_response = ();

    # getting an access token
    my $token_data;
    {
        my $redirect_uri = $self->redirect_uri || do { # it should be me
            my $current_uri = $c->req->uri;
            $current_uri->query(undef);
            $current_uri->as_string;
        };
        my $res = $self->ua->post($self->access_token_url => +{
            grant_type    => 'authorization_code',
            code          => $c->req->param('code'),
            redirect_uri  => $redirect_uri,
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
        });
        unless ($res->is_success) {
            warn $res->decoded_content;
            return $callback->{on_error}->($res->status_line);
        }

        $token_data = decode_json($res->content);
        %api_response = (%api_response, %$token_data);
    }

    # verify access token
    my $verify_data;
    {
        my $uri = URI->new($self->verify_url);
        $uri->query_form(access_token => $token_data->{access_token});

        my $res = $self->ua->get($uri->as_string);
        unless ($res->is_success) {
            warn $res->decoded_content;
            return $callback->{on_error}->($res->status_line);
        }

        $verify_data = decode_json($res->content);
        if ($verify_data->{client_id} ne $self->client_id) {
            return $callback->{on_error}->('client_id mismatch');
        }

        push @args, $token_data->{access_token};
        %api_response = (%api_response, %$verify_data);
    }

    # get user profile
    if ($self->user_info && $verify_data->{scope} =~ /\bprofile\b/) {
        my $uri = URI->new($self->profile_url);
        my $res = $self->ua->get(
            $uri->as_string,
            Authorization => 'Bearer ' . $token_data->{access_token},
        );
        $res->is_success or do {
            warn $res->decoded_content;
            return $callback->{on_error}->($res->decoded_content);
        };
        my $user = decode_json($res->content);
        %api_response = (%api_response, %$user);
    }
    push @args, \%api_response;

    $self->clear_state($c);
    $self->clear_nonce($c);

    $callback->{on_finished}->(@args);
}

sub get_state {
    my($self, $c) = @_;
    my $state = $self->state || $c->session->get($self->state_session_key) || do {
        require Crypt::URandom::Token;
        Crypt::URandom::Token::urandom_token(16)
    };
    $self->set_state($c, $state);
    return $state;
}

sub set_state {
    my($self, $c, $state) = @_;
    return $c->session->set($self->state_session_key => $state);
}

sub clear_state {
    my($self, $c) = @_;
    return $c->session->remove($self->state_session_key);
}

sub get_nonce {
    my($self, $c) = @_;
    my $nonce = $self->nonce || $c->session->get($self->nonce_session_key) || do {
        require Crypt::URandom::Token;
        Crypt::URandom::Token::urandom_token(16)
    };
    $self->set_nonce($c, $nonce);
    return $nonce;
}

sub set_nonce {
    my($self, $c, $nonce) = @_;
    return $c->session->set($self->nonce_session_key => $nonce);
}

sub clear_nonce {
    my($self, $c) = @_;
    return $c->session->remove($self->nonce_session_key);
}
 
1;
__END__

=head1 NAME

Amon2::Auth::Site::LINE - LINE integration for Amon2

=head1 SYNOPSIS
 
# in your configuration file

 +{
     Auth => {
         LINE => {
             client_id     => '123456789Z',,
             client_secret => '01234567889abcdef0123456789abcdx',
             scope         => [qw(profile)],
         }
     }
 }

# in your web app

 __PACKAGE__->load_plugin('Web::Auth', {
     module => 'LINE',
     on_finished => sub {
         my($c, $token, $api_response) = @_;
         my $user_id = $api_response->{userId};
         my $name    = $api_response->{displayName};
         $c->session->set(user_id => $user_id);
         $c->session->set(name    => $name);
         return $c->redirect('/');
     },
     on_error => sub {
         my($c, $error_message) = @_;
         ...
     }
 });
 
=head1 DESCRIPTION

This is a LINE Login authentication module for Amon2.
It uses LINE Login v2.1 APIs.

=head1 ATTRIBUTES FOR CONFIGURATION FILE

Following attributes are set in your configuration file such like C<config/production.pl> and so on.

=over 4

=item client_id

Mandatory. It is issued on LINE Developers Console.

=item client_secret

Mandatory. It is issued on LINE Developers Console.

=item redirect_uri

Optional. It's used for some API's C<< redirect_uri >> parameter.
If it's ommited, C<< callback_path >> which is passed as an attribute for argument is used instead of it.

=item state

Optional. If you don't set nothing, it generates a random string.
The C<< state >> parameter is used a system for preventing CSRF on OAuth 2.0. This attribute should not be set some foreseeable fixed value.

=item scope

API scope as an array-ref.
Acceptable values are: C<< profile >>, C<< openid >> and C<< email >>.
See detail: L<https://developers.line.biz/en/docs/line-login/integrate-line-login/#scope>
Default value is C<< ['profile'] >>.

=item nonce

Optional. If you don't set nothing, it generates a random string.
The C<< nonce >> parameter is used a system for preventing replay attack / token interception attack on OpenID Connect. This attribute should not be set some foreseeable fixed value.

=item prompt

Optional. C<< consent >> is acceptable.

=item max_age

Optional. Specified on OpenID Conjnect Core 1.0.

=item ui_locales

Optional. Specified on OpenID Conjnect Core 1.0.

=item bot_prompt

Optional. C<< normal >> and C<< aggressive >> are acceptable.

=item state_session_key

Optional. C<< state >> parameter is kept on session with this specified session key during authentication.
Default values C<< line_login_state >>.

=item nonce_session_key

Optional. C<< nonce >> parameter is kept on session with this specified session key during.
Default values C<< line_login_nonce >>.

=back

=head1 ATTRIBUTES FOR ARGUMENT

=over 4

=item authenticate_path

Optional. Default value is C<< /auth/line/authenticate >>. The path works for "login link".

=item callback_path

Optional. Default value is C<< /auth/line/callback >>.

=item on_finished

Mandatory. The details are described following.

=item on_error

Optional. The details are described following.

=item user_info

Optional. If it's true, this module fetches the user information after authentication.

=back

=head1 METHODS
 
=over 4
 
=item C<< $auth->auth_uri($c:Amon2::Web, $callback_uri : Str) :Str >>

Get a authenticate URI.
 
=item C<< $auth->callback($c:Amon2::Web, $callback:HashRef) : Plack::Response >>

Process the authentication callback dispatching.

C<< $callback >> MUST have two keys.
 
=over 4
 
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
        my ($c, $access_token, $api_response) = @_;
        ...
    }

C<< $api_response >> contains an issued access token, a verified access token validity, and a gotten user profile. And they are all merged into one hash-ref.
This code contains a information like L<https://developers.line.biz/en/reference/line-login/#issue-token-response>, L<https://developers.line.biz/en/reference/line-login/#verify-access-token-response> and L<https://developers.line.biz/en/reference/line-login/#get-profile-response>.
If you set C<< $auth->user_info >> as a false value and/or you don't set C<< profile >> as the C<< scope >> attribute, authentication engine does not pass a gotten user profile.
 
=back
 
=back

=head1 AUTHOR
 
Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>
 
=head1 LICENSE
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 SEE ALSO
 
=over 4
 
=item * LINE Login v2.1 API Reference

L<https://developers.line.biz/en/reference/line-login/>
 
=item * Amon2::Plugin::Web::Auth

L<Amon2::Plugin::Web::Auth>
 
=back
 
=cut
