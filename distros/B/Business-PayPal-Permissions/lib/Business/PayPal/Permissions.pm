package Business::PayPal::Permissions;
{
    $Business::PayPal::Permissions::VERSION = '0.02';
}

# ABSTRACT: PayPal Permissions

use strict;
use warnings;
use Carp qw/croak/;
use LWP::UserAgent;
use JSON;
use URI::Escape 'uri_escape';
use MIME::Base64 'encode_base64';
use Digest::HMAC_SHA1 'hmac_sha1';

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : {@_};

    # validate
    $args->{username}  or croak 'username is required';
    $args->{password}  or croak 'password is required';
    $args->{signature} or croak 'signature is required';

    if ( $args->{sandbox} ) {
        $args->{app_id} ||= 'APP-80W284485P519543T';
        $args->{url} = 'https://svcs.sandbox.paypal.com/';
    }
    else {
        $args->{url} = 'https://svcs.paypal.com/';
    }

    $args->{app_id} or croak 'app_id is required';

    unless ( $args->{ua} ) {
        my $ua_args = delete $args->{ua_args} || {};
        $args->{ua} = LWP::UserAgent->new(%$ua_args);
    }

    my $ua = $args->{ua};
    $ua->default_header( 'X-PAYPAL-SECURITY-USERID',     $args->{username} );
    $ua->default_header( 'X-PAYPAL-SECURITY-PASSWORD',   $args->{password} );
    $ua->default_header( 'X-PAYPAL-SECURITY-SIGNATURE',  $args->{signature} );
    $ua->default_header( 'X-PAYPAL-REQUEST-DATA-FORMAT', 'JSON' )
      ;    ## JSON is more readable
    $ua->default_header( 'X-PAYPAL-RESPONSE-DATA-FORMAT', 'JSON' );
    $ua->default_header( 'X-PAYPAL-APPLICATION-ID',       $args->{app_id} );
    $args->{ua} = $ua;

    bless $args, $class;
}

sub RequestPermissions {
    my ( $self, $scope, $callback ) = @_;

    $scope ||= ['ACCESS_BASIC_PERSONAL_DATA'];

    my %x = (
        'requestEnvelope' => { errorLanguage => 'en_US', },
        scope             => $scope,
        callback          => $callback,
    );

    my $res =
      $self->{ua}->post( $self->{url} . "Permissions/RequestPermissions",
        Content => encode_json( \%x ) );
    return { error => [ { message => $res->status_line } ] }
      unless $res->is_success;
    my $data = decode_json( $res->content );
    return $data unless $data->{token};

    # construct redirect_url
    my $url =
'https://www.paypal.com/cgi-bin/webscr?cmd=_grant-permission&request_token='
      . $data->{token};
    if ( $self->{sandbox} ) {
        $url =
'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_grant-permission&request_token='
          . $data->{token};
    }
    $data->{redirect_url} = $url;

    return $data;
}

sub GetAccessToken {
    my ( $self, $request_token, $verification_code ) = @_;

    my %x = (
        'requestEnvelope' => { errorLanguage => 'en_US', },
        token             => $request_token,
        verifier          => $verification_code
    );
    my $res = $self->{ua}->post( $self->{url} . "Permissions/GetAccessToken",
        Content => encode_json( \%x ) );
    return { error => [ { message => $res->status_line } ] }
      unless $res->is_success;

    my $data = decode_json( $res->content );
    $self->{__token} = $data->{token} if exists $data->{token};
    $self->{__tokenSecret} = $data->{tokenSecret}
      if exists $data->{tokenSecret};

    return $data;
}

sub GetBasicPersonalData {
    my ( $self, $attribute, $token, $tokenSecret ) = @_;

    $attribute ||= [
        'http://axschema.org/contact/email',
        'http://schema.openid.net/contact/fullname',
        'https://www.paypal.com/webapps/auth/schema/payerID',
        'http://axschema.org/namePerson/first',
        'http://axschema.org/namePerson/last',
        'http://openid.net/schema/company/name',
        'http://axschema.org/contact/country/home'
    ];

    $token       ||= $self->{__token};
    $tokenSecret ||= $self->{__tokenSecret};

    my $ua = $self->{ua};

    my $url = $self->{url} . "Permissions/GetBasicPersonalData";
    my $AUTHORIZATION =
      x_pp_authorization_header( $url, $self->{username}, $self->{password},
        $token, $tokenSecret );

    # FIXME
    $ua->default_headers->remove_header('X-PAYPAL-SECURITY-USERID');
    $ua->default_headers->remove_header('X-PAYPAL-SECURITY-PASSWORD');
    $ua->default_headers->remove_header('X-PAYPAL-SECURITY-SIGNATURE');

    $ua->default_header( 'X-PAYPAL-AUTHORIZATION', $AUTHORIZATION );
    $ua->default_header( 'X-PP-AUTHORIZATION',     $AUTHORIZATION );

    my %x = (
        attributeList     => { attribute     => $attribute },
        'requestEnvelope' => { errorLanguage => 'en_US', }
    );
    my $res = $self->{ua}->post(
        $url,
        Content => encode_json( \%x ),
        'Content-Type', 'application/json'
    );
    return { error => [ { message => $res->status_line } ] }
      unless $res->is_success;
    return decode_json( $res->content );
}

# http://stackoverflow.com/questions/9578895/generating-paypal-signature-x-paypal-authorization-in-ruby
# Mc Cheung rewritten

sub to_paypal_permissions_query {
    my ($hash_ref) = @_;
    my $return;
    foreach my $key ( sort keys %$hash_ref ) {
        $return .= "$key=$hash_ref->{$key}" . "&";
    }
    chop($return);
    return $return;
}

sub paypal_encode {
    my ($str) = @_;
    $str = uri_escape($str);
    $str =~ s/\./%2E/g;
    $str =~ s/-/%2D/g;
    return $str;
}

sub x_pp_authorization_header {
    my ( $url, $api_user_id, $api_password, $access_token,
        $access_token_verifier )
      = @_;

    my $timestamp = time();
    my $signature =
      x_pp_authorization_signature( $url, $api_user_id, $api_password,
        $timestamp, $access_token, $access_token_verifier );
    return
      "token=${access_token},signature=${signature},timestamp=${timestamp}";
}

sub x_pp_authorization_signature {
    my ( $url, $api_user_id, $api_password, $timestamp, $access_token,
        $access_token_verifier )
      = @_;

    my $key = join( '&',
        paypal_encode($api_password),
        paypal_encode($access_token_verifier) );

    my $params = {
        "oauth_consumer_key"     => $api_user_id,
        "oauth_version"          => "1.0",
        "oauth_signature_method" => "HMAC-SHA1",
        "oauth_token"            => $access_token,
        "oauth_timestamp"        => $timestamp,
    };

    my $sorted_query_string = to_paypal_permissions_query($params);

    my $base = join( '&',
        ( "POST", paypal_encode($url), paypal_encode($sorted_query_string) ) );
    $base =~ s/%([0-9A-F])([0-9A-F])/%\L$1\L$2/g;
    my $digest = hmac_sha1( $base, $key );
    $digest = encode_base64($digest);
    chomp($digest);
    return $digest;
}

1;

__END__

=pod

=head1 NAME

Business::PayPal::Permissions - PayPal Permissions

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Business::PayPal::Permissions;
    use Data::Dumper;

    my $ppp = Business::PayPal::Permissions->new(
        username => $cfg{username}, password => $cfg{password},
        signature => $cfg{signature}, sandbox => 1,
    );

=head1 DESCRIPTION

PayPal Permissions L<https://www.x.com/developers/paypal/documentation-tools/permissions/permissions-service>

=head2 METHODS

=head3 CONSTRUCTION

    my $ppp = Business::PayPal::Permissions->new(
        username => $cfg{username}, password => $cfg{password},
        signature => $cfg{signature},
        app_id  => 'APP-80W284485P519543T',
        sandbox => 1,
    );

=over 4

=item * username

=item * password

=item * signature

credentials from paypal.com

=item * app_id

app id from x.com, use 'APP-80W284485P519543T' for sandbox

=item * debug

=item * sandbox

using sandbox urls

=item * ua_args

passed to LWP::UserAgent

=item * ua

L<LWP::UserAgent> or L<WWW::Mechanize> instance

=back

=head3 RequestPermissions($scope, $callback)

    my $data = $ppp->RequestPermissions(
        ['TRANSACTION_SEARCH', 'TRANSACTION_DETAILS', 'ACCESS_BASIC_PERSONAL_DATA'],
        'http://localhost:5000/cgi-bin/test.pl'
    );

    print redirect($data->{redirect_url}) if exists $data->{redirect_url};
    die $data->{error}->[0]->{message} . "\n" if exists $data->{error};

=head3 GetAccessToken($request_token, $verification_code)

    my $data = $ppp->GetAccessToken( param('request_token'), param('verification_code') );
    die $data->{error}->[0]->{message} . "\n" if exists $data->{error};

    my $token = $data->{token};
    my $tokenSecret = $data->{tokenSecret};

=head3 GetBasicPersonalData

    my $user = $ppp->GetBasicPersonalData(['http://axschema.org/contact/email', 'http://schema.openid.net/contact/fullname', 'https://www.paypal.com/webapps/auth/schema/payerID', 'http://axschema.org/namePerson/first', 'http://axschema.org/namePerson/last', 'http://openid.net/schema/company/name', 'http://axschema.org/contact/country/home']);

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Mc Cheung

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
