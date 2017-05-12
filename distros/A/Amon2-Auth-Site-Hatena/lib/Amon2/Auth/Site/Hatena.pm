package Amon2::Auth::Site::Hatena;
use Mouse;

use JSON;
use OAuth::Lite::Token;
use OAuth::Lite::Consumer;
use Woothee;

our $VERSION = '0.04';

has consumer_key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has consumer_secret => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has scope => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { +[qw(read_public)] },
);

has user_info => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has ua => (
    is      => 'ro',
    isa     => 'OAuth::Lite::Consumer',
    lazy    => 1,
    default => sub {
        OAuth::Lite::Consumer->new(
            consumer_key       => $_[0]->consumer_key,
            consumer_secret    => $_[0]->consumer_secret,
            site               => $_[0]->site,
            request_token_path => $_[0]->request_token_path,
            access_token_path  => $_[0]->access_token_path,
        );
    },
);

has site => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://www.hatena.com',
);

has request_token_path => (
    is      => 'ro',
    isa     => 'Str',
    default => '/oauth/initiate',
);

has access_token_path => (
    is      => 'ro',
    isa     => 'Str',
    default => '/oauth/token',
);

has authorize_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://www.hatena.ne.jp/oauth/authorize',
);

has authorize_url_touch => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://www.hatena.ne.jp/touch/oauth/authorize',
);

has authorize_url_mobile => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://www.hatena.ne.jp/mobile/oauth/authorize',
);

has user_info_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://n.hatena.com/applications/my.json',
);

has redirect_url => (
    is  => 'ro',
    isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

sub moniker { 'hatena' }

sub detect_authorize_url_from {
    my ($self, $c) = @_;

    my $category = Woothee->parse($c->req->env->{'HTTP_USER_AGENT'})->{category};
    $category eq 'smartphone'  ? $self->authorize_url_touch  :
    $category eq 'mobilephone' ? $self->authorize_url_mobile :
                                 $self->authorize_url        ;
}

sub auth_uri {
    my ($self, $c, $callback_uri) = @_;

    my $request_token = $self->ua->get_request_token(
        callback_url => $callback_uri || $self->redirect_url,
        scope        => join(',', @{$self->scope}),
    ) or die $self->ua->errstr;

    $c->session->set(auth_hatena => {
        request_token        => $request_token->token,
        request_token_secret => $request_token->secret,
    });

    $self->ua->{authorize_path} = $self->detect_authorize_url_from($c);
    $self->ua->url_to_authorize(token => $request_token);
}

sub callback {
    my ($self, $c, $callback) = @_;
    my $error = $callback->{on_error};

    my $verifier = $c->req->param('oauth_verifier')
        or return $error->("Cannot get a `oauth_verifier' parameter");

    my $session      = $c->session->get('auth_hatena') || {};
    my $token        = $session->{request_token};
    my $token_secret = $session->{request_token_secret};

    return $error->('request_token, request_token_secret are both required')
        if (!$token || !$token_secret);

    my $request_token = OAuth::Lite::Token->new(
        token  => $token,
        secret => $token_secret,
    );
    my $access_token = $self->ua->get_access_token(
        token    => $request_token,
        verifier => $verifier,
    ) or return $error->($self->ua->errstr);

    my @args = ($access_token->token, $access_token->secret);

    if ($self->user_info) {
        my $res = $self->ua->get($self->user_info_url);
        return $error->($self->ua->errstr) if $res->is_error;

        my $data = decode_json($res->decoded_content);
        push @args, $data;
    }

    $callback->{on_finished}->(@args);
}

1;

__END__

=encoding utf8

=head1 NAME

Amon2::Auth::Site::Hatena - Hatena authentication integration for Amon2

=head1 SYNOPSIS

    # config
    +{
        Auth => {
            Hatena => {
                consumer_key    => 'your consumer key',
                consumer_secret => 'your consumer secret',
            }
        }
    }

    # app
    __PACKAGE__->load_plugin('Web::Auth', {
        module   => 'Hatena',
        on_error => sub {
            my ($c, $error_message) = @_;
            ...
        },
        on_finished => sub {
            my ($c, $token, $token_secret, $user) = @_;

            my $name  = $user->{url_name};     #=> eg. antipop (id)
            my $nick  = $user->{display_name}; #=> eg. kentaro (nick)
            my $image = $user->{profile_image_url};

            $c->session->set(hatena => {
                user         => $user,
                token        => $token,
                token_secret => $token_secret,
            });

            $c->redirect('/');
        },
    });

=head1 DESCRIPTION

This is a Hatena authentication module for Amon2. You can easily let
users authenticate via Hatena OAuth API using this module.

=head1 ATTRIBUTES

=over 4

=item consumer_key (required)

=item comsumer_secret (required)

=item scope (Default: C<[qw(read_public)]>)

API scope in ArrayRef.

=item user_info (Default: true)

If true, this module fetch user data immediately after authentication.

=item ua (Default: instance of OAuth::Lite::Consumer)

=back

=head1 METHODS

=over 4

=item C<< $auth->auth_uri($c:Amon2::Web, $callback_uri:Str) >> : Str

Returns an authenticate URI according to C<$ENV{HTTP_USER_AGENT}>. It
can be one of three for PC, smart phone, and JP cell phone.

=item C<< $auth->callback($c:Amon2::Web, $callback:HashRef) >> : Plack::Response

Process the authentication callback dispatching.

=over 4

=item * on_error

I<on_error> callback function is called if an error was occurred.

The arguments are following:

    sub {
        my ($c, $error_message) = @_;
        ...
    }

=item * on_finished

I<on_finished> callback function is called if an authentication was
finished.

The arguments are following:

    sub {
        my ($c, $access_token, $access_token_secret, $user) = @_;
        ...
    }

C<$user> contains user information. If you set C<$auth->user_info> as
a false value, authentication engine does not pass C<$user>.

See L<eg/app.psgi> for details.

=back

=back

=head1 SEE ALSO

=over 4

=item * Hatena Auth Specification

L<http://developer.hatena.ne.jp/ja/documents/auth>

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
