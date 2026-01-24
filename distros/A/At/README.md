# NAME

At - The AT Protocol for Social Networking

# SYNOPSIS

```perl
use At;
my $at = At->new( host => 'bsky.social' );

# Authentication (The Modern Way)
my $auth_url = $at->oauth_start( 'user.bsky.social', 'http://localhost', 'http://127.0.0.1:8888/' );
# ... Redirect user to $auth_url, then get $code and $state from callback ...
$at->oauth_callback( $code, $state );

# Creating a Post
$at->post( 'com.atproto.repo.createRecord' => {
    repo       => $at->did,
    collection => 'app.bsky.feed.post',
    record     => {
        text      => 'Hello from Perl!',
        createdAt => At::_now->to_string
    }
});

# Streaming the Firehose
my $fh = $at->firehose(sub ( $header, $body, $err ) {
    return warn $err if $err;
    say "New event: " . $header->{t};
});
$fh->start();
# ... Start event loop (e.g. Mojo::IOLoop->start) ...
```

# DESCRIPTION

At.pm is a toolkit for interacting with the AT Protocol which powers decentralized social networks like Bluesky.

Unless you're designing a new client around the AT Protocol, you are probably looking for [Bluesky.pm](https://metacpan.org/pod/Bluesky).

## Rate Limits

At.pm attempts to keep track of rate limits according to the protocol's specs. Requests are categorized (`auth`,
`repo`, `global`) and tracked per-identifier.

If you approach a limit (less than 10% remaining), a warning is issued. If you exceed a limit, a warning is issued with
the time until reset.

See [https://docs.bsky.app/docs/advanced-guides/rate-limits](https://docs.bsky.app/docs/advanced-guides/rate-limits)

# Getting Started

If you are new to the AT Protocol, the first thing to understand is that it is decentralized. Your data lives on a
Personal Data Server (PDS), but your identity is portable.

## Identity (Handles and DIDs)

- **Handle**: A human-friendly name like `alice.bsky.social`.
- **DID**: A persistent, machine-friendly identifier like `did:plc:z72i7...`.

# Authentication and Session Management

There are two ways to authenticate: the modern OAuth system and the legacy password system. Once authenticated, all
other methods (like `get`, `post`, and `subscribe`) work the same way.

Developers of new code should be aware that the AT protocol is transitioning to OAuth and this library strongly
encourages its use.

## The OAuth System (Recommended)

OAuth is the secure, modern way to authenticate. It uses DPoP (Demonstrating Proof-of-Possession) to ensure tokens
cannot be stolen and reused. It's a three step process:

- 1. Start the flow:

    ```perl
    my $auth_url = $at->oauth_start(
        'user.bsky.social',
        'http://localhost',                  # Client ID
        'http://127.0.0.1:8888/callback',    # Redirect URI
        'atproto transition:generic'         # Scopes
    );
    ```

- 2. Redirect the user:

    Open `$auth_url` in a browser. After they approve, they will be redirected to your callback URL with `code` and
    `state` parameters.

- 3. Complete the callback:

    ```
    $at->oauth_callback( $code, $state );
    ```

    See the demonstration scripts `eg/bsky_oauth.pl` and `eg/mojo_oauth.pl` for both a CLI and web based examples.

Once authenticated, you should store your session data securely so you can resume it later without requiring the user
to log in again.

### Resuming an OAuth Session

You need to store the tokens, the DPoP key, and the PDS endpoint. The `_raw` method on the session  object provides a
simple hash for this purpose:

```perl
# After login, save the session
my $data = $at->session->_raw;
# ... store $data securely ...

# Later, resume the session
$at->resume(
    $data->{accessJwt},
    $data->{refreshJwt},
    $data->{token_type},
    $data->{dpop_key_jwk},
    $data->{client_id},
    $data->{handle},
    $data->{pds}
);
```

## The Legacy System (App Passwords)

Legacy authentication is simpler but less secure. It uses a single call to `login`. **Never use your main password;
always use an App Password.**

```
$at->login( 'user.bsky.social', 'your-app-password' );
```

Once authenticated, you should store your session data securely so you can resume it later without requiring the user
to log in again.

### Resuming a Legacy Session

Legacy sessions only require the access and refresh tokens:

```
$at->resume( $access_jwt, $refresh_jwt );
```

**Note:** In both cases, if the access token has expired, `resume()` will automatically attempt to refresh it using the
refresh token.

# Account Management

## Creating an Account

You can create a new account using `com.atproto.server.createAccount`. Note that PDS instances _may_ require an
invite code.

```perl
my $res = $at->post( 'com.atproto.server.createAccount' => {
    handle      => 'newuser.bsky.social',
    email       => 'user@example.com',
    password    => 'secure-password',
    inviteCode  => 'bsky-social-abcde'
});
```

# Working With Data: Records and Repositories

Data in the AT Protocol is stored in "repositories" as "records". Each record belongs to a "collection" (defined by a
Lexicon).

## Creating a Post

Posts are records in, for example, the `app.bsky.feed.post` collection.

```perl
$at->post( 'com.atproto.repo.createRecord' => {
    repo       => $at->did,
    collection => 'app.bsky.feed.post',
    record     => {
        '$type'   => 'app.bsky.feed.post',
        text      => 'Content of the post',
        createdAt => At::_now->to_string,
    }
});
```

## Listing Records

To see what's in a collection:

```perl
my $res = $at->get( 'com.atproto.repo.listRecords' => {
    repo       => $at->did,
    collection => 'app.bsky.feed.post',
    limit      => 10
});

for my $record (@{$res->{records}}) {
    say $record->{value}{text};
}
```

# Drinking from the Firehose: Real-time Streaming

The Firehose is a real-time stream of **all** events happening on the network (or a specific PDS). This includes new
posts, likes, handle changes, deletions, and more.

## Subscribing to the Firehose

```perl
my $fh = $at->firehose(sub ( $header, $body, $err ) {
    if ($err) {
        warn "Firehose error: $err";
        return;
    }

    if ($header->{t} eq '#commit') {
        say "New commit in repo: " . $body->{repo};
    }
});

$fh->start();
```

**Note:** The Firehose requires [CBOR::Free](https://metacpan.org/pod/CBOR%3A%3AFree) and an async event loop to keep the connection alive. Currently, At.pm
supports [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) so you should usually use [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop):

```perl
use Mojo::IOLoop;
# ... setup firehose ...
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
```

# Lexicon Caching

The AT Protocol defines its API endpoints using "Lexicons" (JSON schemas). This library uses these schemas to
automatically coerce API responses into Perl objects.

## How it works

When you call a method like `app.bsky.actor.getProfile`, the library:

- 1. **Checks user-provided paths:** It looks in any directories passed to `lexicon_paths`.
- 2. **Checks local storage:** It looks for the schema in the distribution's `share` directory.
- 3. **Checks user cache:** It looks in `~/.cache/atproto/lexicons/`.
- 4. **Downloads if missing:** If not found, it automatically downloads the schema from the
official AT Protocol repository and saves it to your user cache.

This system ensures that the library can support new or updated features without requiring a new release of the Perl
module.

# METHODS

## `new( [ host =` ..., share => ... \] )>

Constructor.

Expected parameters include:

- `host`

    Host for the service. Defaults to `bsky.social`.

- `share`

    Location of lexicons. Defaults to the `share` directory under the distribution.

- `lexicon_paths`

    An optional path string or arrayref of paths to search for Lexicons before checking the default cache locations. Useful
    for local development with a checkout of the `atproto` repository.

- `http`

    A pre-instantiated [At::UserAgent](https://metacpan.org/pod/At%3A%3AUserAgent) object. By default, this is auto-detected by checking for [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent),
    falling back to [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny).

## `oauth_start( $handle, $client_id, $redirect_uri, [ $scope ] )`

Initiates the OAuth 2.0 Authorization Code flow. Returns the authorization URL.

## `oauth_callback( $code, $state )`

Exchanges the authorization code for tokens and completes the OAuth flow.

## `login( $handle, $app_password )`

Performs legacy password-based authentication. **Deprecated: Use OAuth instead.**

## `resume( $access_jwt, $refresh_jwt, [ $token_type, $dpop_key_jwk, $client_id, $handle, $pds ] )`

Resumes a previous session using stored tokens and metadata.

## `get( $method, [ \%params ] )`

Calls an XRPC query (GET). Returns the decoded JSON response.

## `post( $method, [ \%data ] )`

Calls an XRPC procedure (POST). Returns the decoded JSON response.

## `subscribe( $method, $callback )`

Connects to a WebSocket stream (Firehose).

## `firehose( $callback, [ $url ] )`

Returns a new [At::Protocol::Firehose](https://metacpan.org/pod/At%3A%3AProtocol%3A%3AFirehose) client. `$url` defaults to the Bluesky relay firehose.

## `resolve_handle( $handle )`

Resolves a handle to a DID.

## `collection_scope( $collection, [ $action ] )`

Helper to generate granular OAuth scopes (e.g., `repo:app.bsky.feed.post?action=create`).

## `session()`

Returns the current [At::Protocol::Session](https://metacpan.org/pod/At%3A%3AProtocol%3A%3ASession) object.

## `did()`

Returns the DID of the authenticated user.

# ERROR HANDLING

Exception handling is carried out by returning [At::Error](https://metacpan.org/pod/At%3A%3AError) objects which have untrue boolean values.

# See Also

[Bluesky](https://metacpan.org/pod/Bluesky) - Bluesky client library

[App::bsky](https://metacpan.org/pod/App%3A%3Absky) - Bluesky client on the command line

[https://docs.bsky.app/docs/api/](https://docs.bsky.app/docs/api/)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
