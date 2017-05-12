package Catalyst::Authentication::Credential::OAuth;
use Moose;
use MooseX::Types::Moose qw/ Bool HashRef /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use Net::OAuth;
#$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
use LWP::UserAgent;
use HTTP::Request::Common;
use String::Random qw/ random_string /;
use Catalyst::Exception ();
use namespace::autoclean;

our $VERSION = '0.04';

has debug => ( is => 'ro', isa => Bool );
has providers => ( is => 'ro', isa => HashRef, required => 1 );
has ua => ( is => 'ro', lazy_build => 1, init_arg => undef, isa => 'LWP::UserAgent' );

sub BUILDARGS {
    my ($self, $config, $c, $realm) = @_;

    return $config;
}

sub BUILD {
    my ($self) = @_;
    $self->ua; # Ensure lazy value is built.
}

sub _build_ua {
    my $self = shift;

    LWP::UserAgent->new;
}

sub authenticate {
	my ($self, $c, $realm, $auth_info) = @_;

    Catalyst::Exception->throw( "Provider is not defined." )
        unless defined $auth_info->{provider} || defined $self->providers->{ $auth_info->{provider} };

    my $provider = $self->providers->{ $auth_info->{provider} };

    for ( qw/ consumer_key consumer_secret request_token_endpoint access_token_endpoint user_auth_endpoint / ) {
        Catalyst::Exception->throw( $_ . " is not defined for provider ". $auth_info->{provider} )
            unless $provider->{$_};
    }

    my %defaults = (
	consumer_key => $provider->{consumer_key},
	consumer_secret => $provider->{consumer_secret},
        timestamp => time,
        nonce => random_string( 'ccccccccccccccccccc' ),
        request_method => 'GET',
        signature_method => 'HMAC-SHA1',
	oauth_version => '1.0a',
        callback => $c->uri_for( $c->action, $c->req->captures, @{ $c->req->args } )->as_string
    );

	$c->log_debug( "authenticate() called from " . $c->request->uri ) if $self->debug;

    my $oauth_token = $c->req->method eq 'GET'
        ? $c->req->query_params->{oauth_token}
        : $c->req->body_params->{oauth_token};

	if( $oauth_token ) {

		my $response = Net::OAuth->response( 'user auth' )->from_hash( $c->req->params );

		my $request = Net::OAuth->request( 'access token' )->new(
			%defaults,
			token => $response->token,
			token_secret => '',
			request_url => $provider->{access_token_endpoint},
			verifier => $c->req->params->{oauth_verifier},
		);
		$request->sign;

		my $ua_response = $self->ua->request( GET $request->to_url );
		Catalyst::Exception->throw( $ua_response->status_line.' '.$ua_response->content )
			unless $ua_response->is_success;

		$response = Net::OAuth->response( 'access token' )->from_post_body( $ua_response->content );

		my $user = +{
			token => $response->token,
			token_secret => $response->token_secret,
			extra_params => $response->extra_params
		};

		my $user_obj = $realm->find_user( $user, $c );

		return $user_obj if ref $user_obj;

		$c->log->debug( 'Verified OAuth identity failed' ) if $self->debug;

		return;
	}
	else {
		my $request = Net::OAuth->request( 'request token' )->new(
			%defaults,
			request_url => $provider->{request_token_endpoint}
		);
		$request->sign;

		my $ua_response = $self->ua->request( GET $request->to_url );

		Catalyst::Exception->throw( $ua_response->status_line.' '.$ua_response->content )
			unless $ua_response->is_success;

		my $response = Net::OAuth->response( 'request token' )->from_post_body( $ua_response->content );

		$request = Net::OAuth->request( 'user auth' )->new(
			%defaults,
			token => $response->token,
		);

		$c->res->redirect( $request->to_url( $provider->{user_auth_endpoint} ) );
	}

}



1;


__END__

=head1 NAME

Catalyst::Authentication::Credential::OAuth - OAuth credential for Catalyst::Plugin::Authentication framework.

=head1 VERSION

0.02

=head1 SYNOPSIS

In MyApp.pm

    use Catalyst qw/
        Authentication
        Session
        Session::Store::FastMmap
        Session::State::Cookie
    /;


In myapp.conf

    <Plugin::Authentication>
        default_realm	oauth
        <realms>
            <oauth>
                <credential>
                    class	OAuth
                    <providers>
                        <example.com>
                            consumer_key             my_app_key
                            consumer_secret          my_app_secret
                            request_token_endpoint   http://example.com/oauth/request_token
                            access_token_endpoint    http://example.com/oauth/access_token
                            user_auth_endpoint       http://example.com/oauth/authorize
                        </example.com>
                    </providers>
                </credential>
            </oauth>
        </realms>
    </Plugin::Authentication>


In controller code,

    sub oauth : Local {
        my ($self, $c) = @_;

        if( $c->authenticate( { provider => 'example.com' } ) ) {
            #do something with $c->user
        }
    }



=head1 USER METHODS

=over 4

=item $c->user->token

=item $c->user->token_secret

=item $c->user->extra_params - whatever other params the provider sends back

=back

=head1 AUTHOR

Cosmin Budrica E<lt>cosmin@sinapticode.comE<gt>

Bogdan Lucaciu E<lt>bogdan@sinapticode.comE<gt>

With contributions from:

  Tomas Doran E<lt>bobtfish@bobtfish.netE</gt>


=head1 BUGS

Only tested with twitter

=head1 COPYRIGHT

Copyright (c) 2009 Sinapticode. All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
