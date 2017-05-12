use strict;
use warnings;
use utf8;

package Amon2::Auth::Site::Twitter;
use Mouse;
use Net::Twitter::Lite::WithAPIv1_1;

sub moniker { 'twitter' }

has consumer_key => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);
has consumer_secret => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

sub _nt {
	my ($self) = @_;
    my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key    => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
        ssl             => 1,
    );
	return $nt;
}

sub auth_uri {
	my ($self, $c, $callback_uri) = @_;

	my $nt = $self->_nt();
	my $redirect_uri = $nt->get_authorization_url(callback => $callback_uri);
    $c->session->set( auth_twitter => [ $nt->request_token, $nt->request_token_secret, ] );
	return $redirect_uri;
}

sub callback {
	my ($self, $c, $callback) = @_;

	my $cookie = $c->session->get('auth_twitter')
		or return $callback->{on_error}->("Session error");

	my $nt = $self->_nt();
	$nt->request_token($cookie->[0]);
	$nt->request_token_secret($cookie->[1]);
    if (my $denied = $c->req->param('denied')) {
        return $callback->{on_error}->("Access denied");
    }
	my $verifier = $c->req->param('oauth_verifier');
    my ($access_token, $access_token_secret, $user_id, $screen_name) = eval {
        $nt->request_access_token(verifier => $verifier);
    };
    if ($@) {
        # Net::Twitter::Lite throws exception like following
        # GET https://twitter.com/oauth/access_token failed: 401 Unauthorized at /Users/tokuhirom/perl5/perlbrew/perls/perl-5.15.2/lib/site_perl/5.15.2/Net/Twitter/Lite.pm line 237.
		return $callback->{on_error}->($@);
    } else {
        return $callback->{on_finished}->($access_token, $access_token_secret, $user_id, $screen_name);
    }
}

1;
__END__

=head1 NAME

Amon2::Auth::Site::Twitter - Twitter integration for Amon2

=head1 SYNOPSIS


    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'Twitter',
        on_finished => sub {
            my ($c, $access_token, $access_token_secret, $user_id, $screen_name)
                    = @_;
            $c->session->set('name' => $screen_name);
            $c->session->set('site' => 'twitter');
            return $c->redirect('/');
        }
    });

=head1 DESCRIPTION

This is a twitter authentication module for Amon2. You can call a twitter APIs with this module.

=head1 ATTRIBUTES

=over 4

=item consumer_key

=item consumer_secret

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
        my ($c, $access_token, $access_token_secret, $user_id, $screen_name)
                = @_;
        ...
    }

=back

=back


