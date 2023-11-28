[![Actions Status](https://github.com/sanko/At.pm/actions/workflows/linux.yaml/badge.svg)](https://github.com/sanko/At.pm/actions) [![Actions Status](https://github.com/sanko/At.pm/actions/workflows/windows.yaml/badge.svg)](https://github.com/sanko/At.pm/actions) [![Actions Status](https://github.com/sanko/At.pm/actions/workflows/osx.yaml/badge.svg)](https://github.com/sanko/At.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/At.svg)](https://metacpan.org/release/At)
# NAME

At - The AT Protocol for Social Networking

# SYNOPSIS

```perl
use At;
use Time::Piece;
my $at = At->new( host => 'https://fun.example' );
$at->server->createSession( identifier => 'sanko', password => '1111-aaaa-zzzz-0000' );
$at->repo->createRecord(
    collection => 'app.bsky.feed.post',
    record     => { '$type' => 'app.bsky.feed.post', text => "Hello world! I posted this via the API.", createdAt => gmtime->datetime . 'Z' }
);
```

# DESCRIPTION

The AT Protocol is a 'social networking technology created to power the next generation of social applications.' At.pm
currently supports session creation and simple text posts. It's like day two, so...

At.pm uses perl's new class system which requires perl 5.38.x or better.

## At::Bluesky

```perl
my $bsky = At::Bluesky->new( identifier => 'sanko', password => ... );
$bsky->post( text => 'Easy!' );
```

Creates an At object with the host set to `https://bluesky.social`, loads all the lexicon extensions related to the
social networking site, and exposes a lot of sugar (such as simple post creation).

# Methods

Honestly, to keep to the layout of the underlying protocol, almost everything is handled in members of this class.

## `new( ... )`

Creates an AT client and initiates an authentication session.

```perl
my $client = At->new( host => 'https://bsky.social' );
```

Expected parameters include:

- `host` - required

    Host for the account. If you're using the 'official' Bluesky, this would be 'https://bsky.social' but you'll probably
    want `At::Bluesky->new(...)` because that client comes with all the bits that aren't part of the core protocol.

## `repo( [...] )`

```perl
my $repo = $at->repo; # Grab default
my $repo = $at->repo( did => 'did:plc:ju7kqxvmz8a8k5bapznf1lto2gkki6miw3' ); # You have permissions?
```

Returns an AT repository. Without arguments, this returns the repository returned by AT in the session data.

## `server( )`

Returns an AT service.

# Repo Methods

Repo methods generally require an authorized session. The AT Protocol treats 'posts' and other data as records stored
in repositories.

## `createRecord( ... )`

Create a new record.

```perl
$at->repo->createRecord(
    collection => 'app.bsky.feed.post',
    record     => { '$type' => 'app.bsky.feed.post', text => "Hello world! I posted this via the API.", createdAt => gmtime->datetime . 'Z' }
);
```

Expected parameters include:

- `collection` - required

    The NSID of the record collection.

- `record` - required

    Depending on the type of record, this could be anything. It's undefined in the protocol itself.

# Server Methods

Server methods may require an authorized session.

## `createSession( ... )`

```perl
$at->server->createSession( identifier => 'sanko', password => '1111-2222-3333-4444' );
```

Expected parameters include:

- `identifier` - required

    Handle or other identifier supported by the server for the authenticating user.

- `password` - required

    You know this!

## `describeServer( )`

Get a document describing the service's accounts configuration.

```
$at->server->describeServer();
```

This method does not require an authenticated session.

# See Also

https://atproto.com/

https://en.wikipedia.org/wiki/Bluesky\_(social\_network)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
