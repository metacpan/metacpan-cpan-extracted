# NAME

Apple::AppStoreConnect - Apple App Store Connect API client

# VERSION

Version 0.12

# SYNOPSIS

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

# DESCRIPTION

Apple::AppStoreConnect provides basic access to the Apple App Store Connect API.

Please see the [official API documentation](https://developer.apple.com/documentation/appstoreconnectapi)
for usage and all possible requests.

You can also use it with the ["Apple Store Server API"](#apple-store-server-api).

# CONSTRUCTOR

## `new`

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

- `key_file` : The encrypted App Store Connect API private key file that you
create under **Users and Access** -> **Keys** on the App Store Connect portal. On the portal
you download a PKCS8 format file (.p8), which you first need to convert to the PEM format.
On a Mac you can convert it simply:

        openssl pkcs8 -nocrypt -in AuthKey_<key_id>.p8 -out AuthKey_<key_id>.pem

- `key` : Instead of the `.pem` file, you can pass its contents directly
as a string.
- `key_id` : The ID of the App Store Connect API key created on the App Store
Connect portal  (**Users and Access** section).
- `issuer` : Your API Key **issuer ID**. Can be found at the top of the API keys
on the App Store Connect Portal (**Users and Access** section).

Optional parameters:

- `scope` : An arrayref that defines the token scope. Example entry:
`["GET /v1/apps?filter[platform]=IOS"]`.
- `timeout` : Timeout for requests in secs. Default: `30`.
- `ua` : Pass your own [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) to customise the agent string etc.
- `curl` : If true, fall back to using the `curl` command line program.
This is useful if you have issues adding https support to [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent), which
is the default method for the API requests.
- `expiration` : Token expiration time in seconds. Tokens are cached until
there are less than 10 minutes left to expiration. Default: `900` - the API will
not accept more than 20 minutes expiration time for most requests.
- `jwt_payload` : Extra items to append to the JWT payload. Allows extending
the module to support more/newer versions of Apple APIs. For example, for the Apple
Store Server API you'd need to add:

        jwt_payload => {bid => $bundle_id}

# METHODS

## `get`

    my $res = $asc->get(
        url    => $url,
        raw    => $raw?,
        params => \%query_params?
    );

Fetches the requested API url, by default, it will use [JSON](https://metacpan.org/pod/JSON) to decode it
directly to a Perl hash, unless you request `raw` result as a string.

Requires [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent), unless the `curl` option was set.

If the request is not successful, it will `die` throwing the `HTTP::Response->status_line`.

- `url` : A URL to an API endpoint. Can pass the full URL, e.g. `url => 'https://api.appstoreconnect.apple.com/v1/apps'`,
or you can omit the part up to _v1/_ (i.e. `url => 'apps'`).
- `params` : Any other query params that you need to pass
(see [API documentation](https://developer.apple.com/documentation/appstoreconnectapi)).

## `get_response`

    my $res = $asc->get_response(
        url    => $url,
        raw    => $raw?,
        params => \%query_params?
    );

Same as `get` except it returns the full [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) from the API (so you
can handle bad requests yourself).

# CONVENIENCE METHODS

## `jwt`

    my $jwt = $asc->jwt(
        iat => $iat?,
        exp => $exp?
    );

Returns the JSON Web Token string in case you need it. Will return a cached one
if it has more than 5 minutes until expiration and you don't explicitly pass an
`exp` argument.

- `iat` : Specify the token creation timestamp. Default is `time()`.
- `exp` : Specify the token expiration timestamp. Passing this parameter
will force the creation of a new token. Default is `time()+900` (or what you
specified in the constructor).

## `get_apps`

    my $res = $asc->get_apps(
        id     => $app_id?,
        path   => $path?,
        params => \%query_params?
    );

Without arguments it is similar to `get(url=>"apps"`, fetching the list of apps,
but does some extra processing to return a Perl hash with app IDs as keys and the
app attributes as values.

There are optional arguments to get details of a specific app or app resource:

- `id` : The app ID. Specifying just the id will return the details for a
single app.
- `path` : Requires `id` and is similar to `get(url=>"apps/$app_id/$path")`,
returning a specific resource type for an app, except it does the convenience processing
where a hash with the ids of this resource as keys are returned and the attributes
as values (unless the specific resource does not follow that pattern).
See API documentation for `path` support (e.g. `builds`, `appAvailability`,
`appPriceSchedule`, `customerReviews` etc.).
- `params` : Any other query params that you need to pass
(see [API documentation](https://developer.apple.com/documentation/appstoreconnectapi)).

# NOTES

## Apple Store Server API

You can use this module with the [Apple Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
by passing your app's bundle ID to the JWT payload. So there is just one addition to the constructor call:

    my $assa = Apple::AppStoreConnect->new(
        issuer      => $API_key_issuer,
        key_id      => $key_id,
        key         => $private_key,
        jwt_payload => {bid => $bundle_id}
    );

You can then pass custon Store Server API requests:

    my $res = $assa->get(url => "https://api.storekit.itunes.apple.com/inApps/v2/history/$transactionId");

## POST/PATCH/DELETE requests

Note that currently only GET requests are implemented, as that is what I needed.
However, POST/PATCH/DELETE can be added upon request.

## 403 Unauthorized etc errors

If you suddenly start getting unauthorized errors with a token that should be valid,
log onto App Store Connect and see if you have any documents pending approval (e.g
tax documents, new terms etc).

# AUTHOR

Dimitrios Kechagias, `<dkechag at cpan.org>`

# BUGS

Please report any bugs or feature requests either on [GitHub](https://github.com/dkechag/Apple-AppStoreConnect) (preferred), or on RT (via the email
`bug-Apple-AppStoreConnect at rt.cpan.org` or [web interface](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apple-AppStoreConnect)).

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# GIT

[https://github.com/dkechag/Apple-AppStoreConnect](https://github.com/dkechag/Apple-AppStoreConnect)

# LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
