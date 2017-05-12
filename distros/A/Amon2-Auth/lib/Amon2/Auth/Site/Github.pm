use strict;
use warnings;
use utf8;

package Amon2::Auth::Site::Github;
use Mouse;

use Amon2::Auth;
use LWP::UserAgent;
use JSON;
use Amon2::Auth::Util qw(parse_content);
our $VERSION = '0.07';

sub moniker { 'github' }

has client_id => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);
has client_secret => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);
has scope => (
	is => 'ro',
	isa => 'Str',
);

has user_info => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

has ua => (
	is => 'ro',
	isa => 'LWP::UserAgent',
	lazy => 1,
	default => sub {
		my $ua = LWP::UserAgent->new(agent => "Amon2::Auth/$Amon2::Auth::VERSION");
	},
);

has authorize_url => (
	is => 'ro',
	isa => 'Str',
	default => 'https://github.com/login/oauth/authorize',
);
has access_token_url => (
	is => 'ro',
	isa => 'Str',
	default => 'https://github.com/login/oauth/access_token',
);
has redirect_url => (
	is => 'ro',
	isa => 'Str',
);

sub auth_uri {
    my ($self, $c, $callback_uri) = @_;

	my $redirect_uri = URI->new($self->authorize_url);
	my %params;
	if (defined $callback_uri) {
		$params{redirect_uri} = $callback_uri;
	} elsif (defined $self->redirect_url) {
		$params{redirect_uri} = $self->redirect_url;
	}
	for (qw(client_id scope)) {
		next unless defined $self->$_;
		$params{$_} = $self->$_;
	}
	$redirect_uri->query_form(%params);
	return $redirect_uri->as_string;
}

sub callback {
    my ($self, $c, $callback) = @_;

    my $code = $c->req->param('code') or die "Cannot get a 'code' parameter";
    my %params = (code => $code);
    $params{client_id} = $self->client_id;
    $params{client_secret} = $self->client_secret;
    $params{redirect_url} = $self->redirect_url if defined $self->redirect_url;
    my $res = $self->ua->post($self->access_token_url, \%params);
    $res->is_success or die "Cannot authenticate";
    my $dat = parse_content($res->decoded_content);
	if (my $err = $dat->{error}) {
		return $callback->{on_error}->($err);
	}
    my $access_token = $dat->{access_token} or die "Cannot get a access_token";
    my @args = ($access_token);
    if ($self->user_info) {
        my $res = $self->ua->get("https://api.github.com/user?oauth_token=${access_token}");
        $res->is_success or return $callback->{on_error}->($res->status_line);
        my $dat = decode_json($res->decoded_content);
        push @args, $dat;
    }
	return $callback->{on_finished}->( @args );
}

1;
__END__

=head1 NAME

Amon2::Auth::Site::Github - Github integration for Amon2

=head1 SYNOPSIS


    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'Github',
        on_finished => sub {
            my ($c, $token, $user) = @_;
            my $name = $user->{name} || die;
            $c->session->set('name' => $name);
            $c->session->set('site' => 'github');
            return $c->redirect('/');
        }
    });

=head1 DESCRIPTION

This is a github authentication module for Amon2. You can call a github APIs with this module.

=head1 ATTRIBUTES

=over 4

=item client_id

=item client_secret

=item scope

API scope in string.

=item user_info(Default: true)

Fetch user information after authenticate?

=item ua(instance of LWP::UserAgent)

You can replace instance of L<LWP::UserAgent>.

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

on_error callback function is called if an error was occurred.

The arguments are following:

    sub {
        my ($c, $error_message) = @_;
        ...
    }

=item on_finished

on_finished callback function is called if an authentication was finished.

The arguments are following:

    sub {
        my ($c, $access_token, $user) = @_;
        ...
    }

C<< $user >> contains user information. This code contains a information like L<https://api.github.com/users/dankogai>.

If you set C<< $auth->user_info >> as false value, authentication engine does not pass C<< $user >>.

=back

=back

