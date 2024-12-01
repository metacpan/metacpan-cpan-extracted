# NAME

At - The AT Protocol for Social Networking

# SYNOPSIS

```perl
use At;
my $at = At->new( service => 'https://your.atproto.service.example.com/' ); }
$at->login( 'your.identifier.here', 'hunter2' );
$at->post(
    'com.atproto.repo.createRecord' => {
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        record     => { '$type' => 'app.bsky.feed.post', text => 'Hello world! I posted this via the API.', createdAt => $at->now->as_string }
    }
);
```

# DESCRIPTION

Unless you're designing a new client arount the AT Protocol, this is probably not what you're looking for.

Try [Bluesky.pm](https://metacpan.org/pod/Bluesky).

## Rate Limits

At.pm attempts to keep track of rate limits according to the protocol's specs. Right now, we simply `carp` about
nearing the limit but a future release will allow for devs to query these limits.

See also: [https://docs.bsky.app/docs/advanced-guides/rate-limits](https://docs.bsky.app/docs/advanced-guides/rate-limits)

## Session Management

You'll need an authenticated session for most API calls. There are two ways to manage sessions:

- 1. Username/password based (deprecated)
- 2. OAuth based (still being rolled out)

Developers of new code should be aware that the AT protocol will be [transitioning to OAuth in over the next year or
so (2024-2025)](https://github.com/bluesky-social/atproto/discussions/2656) and this distribution will comply with this
change.

# Methods

This module is based on perl's new (as of writing) class system which means it's (obviously) object oriented.

## `new( ... )`

```perl
my $at = At->new( service => ... );
```

Create a new At object. Easy.

Expected parameters include:

- `service` - required

    Host for the service.

- `lexicon`

    Location of lexicons. This allows new [AT Protocol Lexicons](https://atproto.com/specs/lexicon) to be referenced
    without installing a new version of this module.

    Defaults to `/lexicons` under the dist's share directory.

A new object is returned on success.

## `login( ... )`

Create an app password backed authentication session.

```perl
my $session = $bsky->login(
    identifier => 'john@example.com',
    password   => '1111-2222-3333-4444'
);
```

Expected parameters include:

- `identifier` - required

    Handle or other identifier supported by the server for the authenticating user.

- `password` - required

    This is the app password not the account's password. App passwords for Blueskyare generated at
    [https://bsky.app/settings/app-passwords](https://bsky.app/settings/app-passwords).

- `authFactorToken`

Returns an authorized session on success.

### `resume( ... )`

Resumes an app password based session.

```
$bsky->resume( '...', '...' );
```

Expected parameters include:

- `accessJwt` - required
- `refreshJwt` - required

If the `accessJwt` token has expired, we attempt to use the `refreshJwt` to continue the session with a new token. If
that also fails, well, that's kinda it.

The new session is returned on success.

## `did( )`

Gather the [DID](https://atproto.com/specs/did) (Decentralized Identifiers) of the current user. Returns `undef` on
failure or if the client is not authenticated.

## `session( )`

Gather the current AT Protocol session info. You should store the `accessJwt` and `refreshJwt` tokens securely.

## `get( ... )`

```perl
$at->get(
    'com.atproto.repo.getRecord' => {
        repo       => $at->did,
        collection => 'app.bsky.actor.profile',
        rkey       => 'self'
    }
);
```

Sends an HTTP get request to the service.

Expected parameters include:

- `identifier` - required

    Lexicon endpoint.

- `content`

    This will be passed along to the endpoint as query parameters.

On success, the content is returned. If the lexicon is known, the returned data is coerced into simple (blessed)
objects.

On failure, a throwable error object is returned which will have a false boolean value.

In array context, the resonse headers are also returned.

## `post( ... )`

```perl
$at->post(
    'com.atproto.repo.createRecord' => {
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        record     => { '$type' => 'app.bsky.feed.post', text => 'Hello world! I posted this via the API.', createdAt => $at->now->as_string }
    }
);
```

Sends an HTTP POST request to the service.

Expected parameters include:

- `identifier` - required

    Lexicon endpoint.

- `content`

    This will be passed along to the endpoint as encoded JSON.

On success, the content is returned. If the lexicon is known, the returned data is coerced into simple (blessed)
objects.

On failure, a throwable error object is returned which will have a false boolean value.

In array context, the resonse headers are also returned.

# Error Handling

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
