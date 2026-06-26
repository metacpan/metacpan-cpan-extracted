package Apple::AppStoreConnect;

use 5.008;
use strict;
use warnings;

use Carp;
use Crypt::JWT qw(encode_jwt);
use JSON;

=head1 NAME

Apple::AppStoreConnect - Apple App Store Connect API client

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    use Apple::AppStoreConnect;

    my $asc = Apple::AppStoreConnect->new(
        issuer => $API_key_issuer,  # API key issuer ID
        key_id => $key_id,          # App Store Connect API key ID
        key    => $private_key      # Encrypted private key (PEM)
    );
    
    # Custom API request
    my $res = $asc->get(url => $url);

    # List apps / details convenience function
    $res = $asc->get_apps();                                          # List of apps
    $res = $asc->get_apps(id => $app_id);                             # App details
    $res = $asc->get_apps(id => $app_id, path => 'customerReviews');  # App reviews

    # List App Store versions, optionally with localizations
    $res = $asc->get_app_store_versions(id => $app_id, platform => 'IOS');
    $res = $asc->get_app_store_versions(id => $app_id, localizations => 1);
    $res = $asc->get_app_store_versions(id => $app_id, localizations => 'en-US');

    # Latest beta feedback for alerting
    $res = $asc->get_beta_feedback_screenshot_submissions(id => $app_id, platform => 'IOS');
    $res = $asc->get_beta_feedback_crash_submissions(id => $app_id, crash_log => 1);


=head1 DESCRIPTION

Apple::AppStoreConnect provides basic access to the Apple App Store Connect API.

Please see the L<official API documentation|https://developer.apple.com/documentation/appstoreconnectapi>
for usage and all possible requests.

You can also use it with the L<Apple Store Server API>.

=head1 CONSTRUCTOR

=head2 C<new>

    my $asc = Apple::AppStoreConnect->new(
        key_id      => $key_id,
        key         => $private_key?,
        key_file    => $private_key_pem?,
        issuer      => "57246542-96fe-1a63-e053-0824d011072a",
        scope       => \@scope?,
        timeout     => $timeout_sec?,
        expiration  => $expire_secs?,
        ua          => $lwp_ua?,
        curl        => $use_curl?,
        jwt_payload => {%extra_payload}
    );
  
Required parameters:

=over 4

=item * C<key_file> : The encrypted App Store Connect API private key file that you
create under B<Users and Access> -> B<Keys> on the App Store Connect portal. On the portal
you download a PKCS8 format file (.p8), which you first need to convert to the PEM format.
On a Mac you can convert it simply:

   openssl pkcs8 -nocrypt -in AuthKey_<key_id>.p8 -out AuthKey_<key_id>.pem

=item * C<key> : Instead of the C<.pem> file, you can pass its contents directly
as a string.

=item * C<key_id> : The ID of the App Store Connect API key created on the App Store
Connect portal  (B<Users and Access> section).

=item * C<issuer> : Your API Key B<issuer ID>. Can be found at the top of the API keys
on the App Store Connect Portal (B<Users and Access> section).

=back

Optional parameters:

=over 4

=item * C<scope> : An arrayref that defines the token scope. Example entry:
C<["GET /v1/apps?filter[platform]=IOS"]>.

=item * C<timeout> : Timeout for requests in secs. Default: C<30>.

=item * C<ua> : Pass your own L<LWP::UserAgent> to customise the agent string etc.

=item * C<curl> : If true, fall back to using the C<curl> command line program.
This is useful if you have issues adding https support to L<LWP::UserAgent>, which
is the default method for the API requests.

=item * C<expiration> : Token expiration time in seconds. Tokens are cached until
there are less than 10 minutes left to expiration. Default: C<900> - the API will
not accept more than 20 minutes expiration time for most requests.

=item * C<jwt_payload> : Extra items to append to the JWT payload. Allows extending
the module to support more/newer versions of Apple APIs. For example, for the Apple
Store Server API you'd need to add:

 jwt_payload => {bid => $bundle_id}

=back

=head1 METHODS

=head2 C<get>

    my $res = $asc->get(
        url    => $url,
        raw    => $raw?,
        params => \%query_params?
    );

Fetches the requested API url, by default, it will use L<JSON> to decode it
directly to a Perl hash, unless you request C<raw> result as a string.

Requires L<LWP::UserAgent>, unless the C<curl> option was set.

If the request is not successful, it will C<die> throwing the C<< HTTP::Response->status_line >>.

=over 4
 
=item * C<url> : A URL to an API endpoint. Can pass the full URL, e.g. C<url =E<gt> 'https://api.appstoreconnect.apple.com/v1/apps'>,
or you can omit the part up to I<v1/> (i.e. C<url =E<gt> 'apps'>).

=item * C<params> : Any other query params that you need to pass
(see L<API documentation|https://developer.apple.com/documentation/appstoreconnectapi>).

=back

=head2 C<get_response>

    my $res = $asc->get_response(
        url    => $url,
        raw    => $raw?,
        params => \%query_params?
    );

Same as C<get> except it returns the full L<HTTP::Response> from the API (so you
can handle bad requests yourself).

=head1 CONVENIENCE METHODS

=head2 C<jwt>

    my $jwt = $asc->jwt(
        iat => $iat?,
        exp => $exp?
    );

Returns the JSON Web Token string in case you need it. Will return a cached one
if it has more than 5 minutes until expiration and you don't explicitly pass an
C<exp> argument.

=over 4
 
=item * C<iat> : Specify the token creation timestamp. Default is C<time()>.

=item * C<exp> : Specify the token expiration timestamp. Passing this parameter
will force the creation of a new token. Default is C<time()+900> (or what you
specified in the constructor).

=back

=head2 C<get_apps>

    my $res = $asc->get_apps(
        id       => $app_id?,
        path     => $path?,
        platform => $platform?,
        params   => \%query_params?
    );

Without arguments it is similar to C<get(url=E<gt>"apps">, fetching the list of apps,
but does some extra processing to return a Perl hash with app IDs as keys and the
app attributes as values.

There are optional arguments to get details of a specific app or app resource:

=over 4
 
=item * C<id> : The app ID. Specifying just the id will return the details for a
single app.

=item * C<path> : Requires C<id> and is similar to C<get(url=E<gt>"apps/$app_id/$path")>,
returning a specific resource type for an app, except it does the convenience processing
where a hash with the ids of this resource as keys are returned and the attributes
as values (unless the specific resource does not follow that pattern).
See API documentation for C<path> support (e.g. C<builds>, C<appAvailability>,
C<appPriceSchedule>, C<customerReviews> etc.).

=item * C<platform> : Optional shortcut for C<filter[platform]>, for example
C<IOS>, C<MAC_OS>, C<TV_OS>, or C<VISION_OS>.

=item * C<params> : Any other query params that you need to pass
(see L<API documentation|https://developer.apple.com/documentation/appstoreconnectapi>).

=back

=head2 C<get_app_store_versions>

    my $res = $asc->get_app_store_versions(
        id                  => $app_id,
        platform            => $platform?,
        localizations       => $localizations?,
        localization_fields => $localization_fields?,
        params              => \%query_params?
    );

    my $versions = $asc->get_app_store_versions(
        id                  => $app_id,
        platform            => 'IOS',
        localization_fields => 'locale,whatsNew',
        params              => {
            'fields[appStoreVersions]' => 'platform,versionString,appVersionState'
        }
    );

Returns an arrayref of App Store versions for the app, automatically fetching
all pages. Each entry is a hash of the resource attributes, with C<id> and
C<type> added.

When C<localizations> is requested, one additional API call is made per
version to fetch its localizations.

=over 4

=item * C<id> : The app ID.

=item * C<platform> : Optional shortcut for C<filter[platform]>, for example
C<IOS>, C<MAC_OS>, C<TV_OS>, or C<VISION_OS>.

=item * C<localizations> : If true, each version entry will include a
C<localizations> arrayref. Passing C<1> fetches all localizations. Passing a
locale string, for example C<en-US>, fetches only that locale.

=item * C<localization_fields> : Optional fields to return for each
C<appStoreVersionLocalizations> resource, for example C<locale,whatsNew>. If
specified, C<localizations> defaults to C<1>.

=item * C<params> : Any other query params to pass to the
C<apps/$app_id/appStoreVersions> request.

=back

=head2 C<get_beta_feedback_screenshot_submissions>

    my $res = $asc->get_beta_feedback_screenshot_submissions(
        id       => $app_id,
        platform => $platform?,
        limit    => $limit?,
        sort     => $sort?,
        params   => \%query_params?
    );

Returns an arrayref of beta feedback screenshot submissions for the app. By
default, results are sorted newest first using C<-createdDate>, with C<limit>
set to C<50>. Only up to C<limit> results are returned; pagination is not
performed.

=over 4

=item * C<id> : The app ID.

=item * C<platform> : Optional shortcut for C<filter[appPlatform]>, for example
C<IOS>, C<MAC_OS>, C<TV_OS>, or C<VISION_OS>.

=item * C<limit> : Optional maximum number of results to return. Default C<50>.

=item * C<sort> : Optional sort order. Default C<-createdDate>.

=item * C<params> : Any other query params to pass to the
C<apps/$app_id/betaFeedbackScreenshotSubmissions> request, for example
C<fields[betaFeedbackScreenshotSubmissions]> or C<include>.

=back

=head2 C<get_beta_feedback_crash_submissions>

    my $res = $asc->get_beta_feedback_crash_submissions(
        id               => $app_id,
        platform         => $platform?,
        limit            => $limit?,
        sort             => $sort?,
        crash_log        => $crash_log?,
        crash_log_fields => $crash_log_fields?,
        params           => \%query_params?
    );

Returns an arrayref of beta feedback crash submissions for the app. By default,
results are sorted newest first using C<-createdDate>, with C<limit> set to
C<50>. Only up to C<limit> results are returned; pagination is not performed.
If C<crash_log> is true, each returned crash submission includes a C<crashLog>
hashref with the linked crash log; one additional API call is made per
submission to fetch it.

=over 4

=item * C<id> : The app ID.

=item * C<platform> : Optional shortcut for C<filter[appPlatform]>, for example
C<IOS>, C<MAC_OS>, C<TV_OS>, or C<VISION_OS>.

=item * C<limit> : Optional maximum number of results to return. Default C<50>.

=item * C<sort> : Optional sort order. Default C<-createdDate>.

=item * C<crash_log> : If true, fetch C<betaFeedbackCrashSubmissions/$id/crashLog>
for each crash submission and attach it as C<crashLog>.

=item * C<crash_log_fields> : Optional fields to return for each C<betaCrashLogs>
resource, for example C<logText>.

=item * C<params> : Any other query params to pass to the
C<apps/$app_id/betaFeedbackCrashSubmissions> request, for example
C<fields[betaFeedbackCrashSubmissions]> or C<include>. Passing
C<fields[betaCrashLogs]> here is also supported; it is applied to the crash log
request.

=back

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless($self, $class);

    my %args = @_;

    ($self->{$_} = $args{$_} || croak("$_ (string) required."))
        foreach qw/issuer key_id/;

    unless ($args{key}) {
        croak("key or key_file required.") unless $args{key_file};
        open my $fh, '<', $args{key_file} or die "Can't open file $!";
        $args{key} = do { local $/; <$fh> };
    }
    $self->{key}        = \$args{key};
    $self->{timeout}    = $args{timeout} || 30;
    $self->{expiration} = $args{expiration} || 900;
    $self->{$_}         = $args{$_} for qw/ua curl scope jwt_payload/;
    $self->{base_url}   = "https://api.appstoreconnect.apple.com/v1/";

    return $self;
}

sub get {
    my $self = shift;
    my %args = @_;

    my $resp = $self->get_response(%args);

    unless ($self->{curl}) {
        die $resp->status_line unless $resp->is_success;
        $resp = $resp->decoded_content;
    }

    return $args{raw} ? $resp : JSON::decode_json($resp);
}

sub get_response {
    my $self = shift;
    my %args = @_;

    croak("url required") unless $args{url};
    $args{url} = $self->{base_url}.$args{url} unless $args{url} =~ /^http/;

    my $jwt = $self->jwt;
    my $url = _build_url(%args);

    unless ($self->{curl} || $self->{ua}) {
        require LWP::UserAgent;
        $self->{ua} = LWP::UserAgent->new(
            agent   => "libwww-perl Apple::AppStoreConnect/$VERSION",
            timeout => $self->{timeout}
        );
    }

    return _fetch($self->{ua}, $url, $jwt);
}

sub get_apps {
    my $self = shift;
    my %args = @_;
    my %params = $args{params} ? %{$args{params}} : ();
    $params{'filter[platform]'} = $args{platform} if $args{platform};
    $args{params} = \%params if %params;

    $args{url} = $self->{base_url} . 'apps';
    $args{url} .= "/$args{id}" if $args{id};
    $args{url} .= "/$args{path}" if $args{path};
    my $res = $self->get(%args);

    return _process_data($res);
}

sub get_app_store_versions {
    my $self = shift;
    my %args = @_;

    croak("id required") unless $args{id};

    my %params = $args{params} ? %{$args{params}} : ();
    $params{'filter[platform]'} = $args{platform} if $args{platform};
    $params{limit} ||= 200;
    my $localizations = $args{localizations};
    $localizations ||= 1 if $args{localization_fields};

    my $versions = _flatten_resources($self->_get_all_pages(
        url    => "apps/$args{id}/appStoreVersions",
        params => \%params,
    ));

    if ($localizations) {
        foreach my $version (@$versions) {
            my %localization_params = (limit => 200);
            $localization_params{'filter[locale]'} = $localizations
                unless $localizations eq '1';
            $localization_params{'fields[appStoreVersionLocalizations]'} = $args{localization_fields}
                if $args{localization_fields};

            $version->{localizations} = _flatten_resources($self->_get_all_pages(
                url    => "appStoreVersions/$version->{id}/appStoreVersionLocalizations",
                params => \%localization_params,
            ));
        }
    }

    return $versions;
}

sub get_beta_feedback_screenshot_submissions {
    my $self = shift;
    return $self->_get_beta_feedback_submissions(
        resource => 'betaFeedbackScreenshotSubmissions',
        @_,
    );
}

sub get_beta_feedback_crash_submissions {
    my $self = shift;
    my %args = @_;

    my %params = $args{params} ? %{$args{params}} : ();
    my $crash_log_fields = $args{crash_log_fields};
    $crash_log_fields ||= delete $params{'fields[betaCrashLogs]'};
    $args{params} = \%params;

    my $crashes = $self->_get_beta_feedback_submissions(
        resource => 'betaFeedbackCrashSubmissions',
        %args,
    );

    if ($args{crash_log}) {
        foreach my $crash (@$crashes) {
            my %params;
            $params{'fields[betaCrashLogs]'} = $crash_log_fields
                if $crash_log_fields;

            my $res = $self->get(
                url    => "betaFeedbackCrashSubmissions/$crash->{id}/crashLog",
                params => \%params,
            );
            $crash->{crashLog} = _flatten_resource($res->{data});
        }
    }

    return $crashes;
}

sub jwt {
    my $self = shift;
    my %args = @_;

    # Return cached one
    return $self->{jwt}
        if !$args{exp} && $self->{jwt_exp} && $self->{jwt_exp} >= time() + 300;

    return $self->_new_jwt(%args);
}

sub _new_jwt {
    my $self = shift;
    my %args = @_;

    $args{iat} ||= time();
    $self->{jwt_exp} = $args{exp} || (time() + $self->{expiration});

    my $data = {
        iss => $self->{issuer},
        aud => "appstoreconnect-v1",
        exp => $self->{jwt_exp},
        iat => $args{iat},
    };

    $data->{scope} = $self->{scope} if $self->{scope};
    $data = {
        %$data,
        %{$self->{jwt_payload}}
    } if $self->{jwt_payload};

    $self->{jwt}   = encode_jwt(
        payload       => $data,
        alg           => 'ES256',
        key           => $self->{key},
        extra_headers => {
            kid => $self->{key_id},
            typ => "JWT"
        }
    );

    return $self->{jwt};
}

sub _fetch {
    my ($ua, $url, $jwt) = @_;

    return _curl($url, $jwt) unless $ua;

    return $ua->get($url, Authorization => "Bearer $jwt");
}

sub _curl {
    return `curl "$_[0]" -A "Curl Apple::AppStoreConnect/$VERSION" -s -H 'Authorization: Bearer $_[1]'`;
}

sub _build_url {
    my %args = @_;
    my $url  = $args{url};
    return $url unless ref($args{params});

    my $params = join("&", map {"$_=$args{params}->{$_}"} keys %{$args{params}});

    $url .= "?$params" if $params;

    return $url;
}

sub _get_beta_feedback_submissions {
    my $self = shift;
    my %args = @_;

    croak("id required") unless $args{id};
    croak("resource required") unless $args{resource};

    my %params = $args{params} ? %{$args{params}} : ();
    $params{'filter[appPlatform]'} = $args{platform} if $args{platform};
    $params{limit} ||= $args{limit} || 50;
    $params{sort} ||= $args{sort} || '-createdDate';

    my $res = $self->get(
        url    => "apps/$args{id}/$args{resource}",
        params => \%params,
    );

    return _flatten_resources($res->{data});
}

sub _get_all_pages {
    my $self = shift;
    my %args = @_;

    my @data;
    while ($args{url}) {
        my $res = $self->get(%args);
        push @data, @{$res->{data}}
            if ref($res) && ref($res->{data}) && ref($res->{data}) eq 'ARRAY';

        my $next = ref($res) && ref($res->{links}) eq 'HASH'
            ? $res->{links}->{next}
            : undef;
        last unless $next;

        %args = (url => $next);
    }

    return \@data;
}

sub _flatten_resources {
    my $data = shift;

    return $data unless ref($data) && ref($data) eq 'ARRAY';

    return [
        map {
            my $item = $_;
            my $res = ref($item->{attributes}) eq 'HASH'
                ? {%{$item->{attributes}}}
                : {};
            $res->{id} = $item->{id} if $item->{id};
            $res->{type} = $item->{type} if $item->{type};
            $res;
        } @$data
    ];
}

sub _flatten_resource {
    my $data = shift;
    my $res = _flatten_resources([$data]);
    return $res->[0];
}

sub _process_data {
    my $hash = shift;
    if (ref($hash) && ref($hash->{data}) && ref($hash->{data}) eq 'ARRAY') {
        my $res;
        foreach my $item (@{$hash->{data}}) {
            if ($item->{id} && $item->{attributes}) {
                $res->{$item->{id}} = {%{$item->{attributes}}};
                $res->{$item->{id}}->{type} = $item->{type} if $item->{type};
            }
        }
        return $res if $res;
    }
    return $hash;
}

=head1 NOTES

=head2 Apple Store Server API

You can use this module with the L<Apple Store Server API|https://developer.apple.com/documentation/appstoreserverapi>
by passing your app's bundle ID to the JWT payload. So there is just one addition to the constructor call:

    my $assa = Apple::AppStoreConnect->new(
        issuer      => $API_key_issuer,
        key_id      => $key_id,
        key         => $private_key,
        jwt_payload => {bid => $bundle_id}
    );

You can then pass custon Store Server API requests:

    my $res = $assa->get(url => "https://api.storekit.itunes.apple.com/inApps/v2/history/$transactionId");

=head2 POST/PATCH/DELETE requests

Note that currently only GET requests are implemented, as that is what I needed.
However, POST/PATCH/DELETE can be added upon request.

=head2 403 Unauthorized etc errors

If you suddenly start getting unauthorized errors with a token that should be valid,
log onto App Store Connect and see if you have any documents pending approval (e.g
tax documents, new terms etc).

=head1 AUTHOR

Dimitrios Kechagias, L<https://metacpan.org/author/DKECHAG>

=head1 BUGS

Please report any bugs or feature requests either on L<GitHub|https://github.com/dkechag/Apple-AppStoreConnect> (preferred), or on RT (via the email
C<bug-Apple-AppStoreConnect at rt.cpan.org> or L<web interface|https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apple-AppStoreConnect>).

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 GIT

L<https://github.com/dkechag/Apple-AppStoreConnect>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
