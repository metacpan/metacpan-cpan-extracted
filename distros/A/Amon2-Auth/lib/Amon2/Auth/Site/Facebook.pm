use strict;
use warnings;
use utf8;

package Amon2::Auth::Site::Facebook;
use Mouse;
use LWP::UserAgent;
use URI;
use JSON;
use Amon2::Auth;

sub moniker { 'facebook' }

for (qw(client_id scope client_secret)) {
	has $_ => (
		is => 'ro',
		isa => 'Str',
		required => 1,
	);
}

has user_info => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

has fields => (
	is => 'rw',
	isa => 'Str',
	default => 'id,name',
);

has ua => (
	is => 'ro',
	isa => 'LWP::UserAgent',
	lazy => 1,
	default => sub {
		my $ua = LWP::UserAgent->new(agent => "Amon2::Auth/$Amon2::Auth::VERSION");
	},
);

sub auth_uri {
	my ($self, $c, $callback_uri) = @_;
	$callback_uri or die "Missing mandatory parameter: callback_uri";

	my $url = URI->new('https://www.facebook.com/dialog/oauth');
	my %params;
	for (qw(client_id scope)) {
		$params{$_} = $self->$_;
	}
	$params{redirect_uri} = $callback_uri;
	$url->query_form(%params);
	return $url->as_string;
}

sub callback {
	my ($self, $c, $callback) = @_;
	if (my $error_description = $c->req->param('error_description')) {
		return $callback->{on_error}->($error_description);
	}

	my $uri = URI->new('https://graph.facebook.com/oauth/access_token');
	my %params;
	for (qw(client_id client_secret)) {
		$params{$_} = $self->$_;
	}
	$params{redirect_uri} = $c->req->uri->as_string;
	$params{redirect_uri} =~ s/\?.+//;
	$params{code} = $c->req->param('code') or die;
	$uri->query_form(%params);
	my $res = $self->ua->get($uri->as_string);
	$res->is_success or do {
		warn $res->decoded_content;
		return $callback->{on_error}->($res->decoded_content);
	};
    my $dat = decode_json($res->decoded_content);
	if (my $err = $dat->{error}) {
		return $callback->{on_error}->($err);
	}
    my $access_token = $dat->{access_token} or die "Cannot get a access_token";
    my @args = ($access_token);
    if ($self->user_info) {
        my $res = $self->ua->get("https://graph.facebook.com/me?fields=@{[$self->fields]}&access_token=${access_token}");
        $res->is_success or return $callback->{on_error}->($res->status_line);
        my $dat = decode_json($res->decoded_content);
        push @args, $dat;
    }
	return $callback->{on_finished}->(@args);
}

1;
__END__

=head1 NAME

Amon2::Auth::Site::Facebook - Facebook integration for Amon2

=head1 SYNOPSIS


    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'Facebook',
        on_finished => sub {
            my ($c, $token, $user) = @_;
            my $name = $user->{name} || die;
            $c->session->set('name' => $name);
            $c->session->set('site' => 'facebook');
            return $c->redirect('/');
        }
    });

=head1 DESCRIPTION

This is a facebook authentication module for Amon2. You can call a facebook APIs with this module.

=head1 ATTRIBUTES

=over 4

=item client_id

=item client_secret

=item scope

API scope in string.

=item user_info(Default: true)

Fetch user information after authenticate?

=item fields(Default: "id,name")

need fields of user information
L<https://developers.facebook.com/docs/facebook-login/permissions/v2.2#reference-public_profile>

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

C<< $user >> contains user information. This code contains a information like L<https://graph.facebook.com/19292868552>.

If you set C<< $auth->user_info >> as false value, authentication engine does not pass C<< $user >>.

=back

=back

