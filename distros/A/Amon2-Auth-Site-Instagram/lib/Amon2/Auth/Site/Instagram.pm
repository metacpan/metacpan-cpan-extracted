package Amon2::Auth::Site::Instagram;
use Mouse;

use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = "0.01";

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
    isa     => 'Str',
    default => sub { 'basic' },
);

has user_info => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

has authorize_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.instagram.com/oauth/authorize',
);

has access_token_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.instagram.com/oauth/access_token',
);


has ua => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        LWP::UserAgent->new(agent => "Amon2::Auth::Site::Instagram/$VERSION");
    },
);

no Mouse;
__PACKAGE__->meta->make_immutable;

sub moniker { 'instagram' }

sub auth_uri {
    my ($self, $c, $callback_url) = @_;

    my $uri = URI->new($self->authorize_url);
    $uri->query_form(
        client_id     => $self->client_id,
        redirect_uri  => $self->redirect_url,
        response_type => 'code',
        scope         => $self->scope,
    );

    return $uri->as_string;
}

sub callback {
    my ($self, $c, $callback) = @_;

    my $res = $self->ua->post($self->access_token_url, +{
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        grant_type    => 'authorization_code',
        redirect_uri  => $self->redirect_url,
        code          => $c->req->param('code'),
    });
    $res->is_success or do {
        warn $res->decoded_content;
        return $callback->{on_error}->($res->decoded_content);
    };

    $res = decode_json $res->content;

    my @args = ($res->{access_token});
    push @args, $res->{user} if $self->user_info;

    $callback->{on_finished}->(@args);
}



1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Auth::Site::Instagram - Instagram auth integration for Amon2

=head1 SYNOPSIS

    #add config
    +{
        Auth => {
            client_id     => 'client id',
            client_secret => 'client secret',
            redirect_url  => 'redirect url',
            scope         => 'scope' #e.g. 'likes+comments'
        }
    }

    #add app
    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'Instagram',
        on_finished => sub {
            my ($c, $access_token, $user) = @_;

            my $id        = $user->{id};        #e.g. 123456
            my $full_name = $user->{full_name}; #e.g. nao takanashi

            $c->session->set(instagram => +{
                access_token  => $access_token,
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

Amon2::Auth::Site::Instagram is a Instagram authenticate module for Amon2

=head1 ATTRIBUTES

=over

=item client_id (required)

=item client_secret (required)

=item redirect_url (required)

=item scope (Default: basic)

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

=item * instagram developers site
L<http://instagram.com/developer>

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

