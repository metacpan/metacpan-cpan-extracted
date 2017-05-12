[![Build Status](https://travis-ci.org/sanko/anyevent-bittorrent.svg?branch=master)](https://travis-ci.org/sanko/anyevent-bittorrent)
# NAME

AnyEvent::BitTorrent - Yet Another BitTorrent Client Module

# Synopsis

        use AnyEvent::BitTorrent;
        my $client = AnyEvent::BitTorrent->new( path => 'some.torrent' );
        AE::cv->recv;

# Description

This is a painfully simple BitTorrent client written on a whim that implements
the absolute basics. For a full list of what's currently supported, what you
will likely find in a future version, and what you'll never get from this, see
the section entitled "[This Module is Lame!](#this-module-is-lame)"

# Methods

The API, much like the module itself, is simple.

Anything you find by skimming the source is likely not ready for public use
and will be subject to change before `v1.0.0`. Here's the public interface as
of this version:

## `new( ... )`

        my $c = AnyEvent::BitTorrent->new(
                path         => 'some/legal.torrent',
                basedir      => './storage/',
                port         => 6881,
                on_hash_pass => sub { ... },
                on_hash_fail => sub { ... },
                state        => 'stopped',
                piece_cache  => $quick_restore
        );

This constructor understands the following arguments:

- `path`

    This is the only required parameter. It's the path to a valid .torrent file.

- `basedir`

    This is the base directory all data will be stored in and/or read from.
    Multifile torrents will create another directory below this to store all
    files.

    By default, this is the current working directory when
    [`new( ... )`](#new) is called.

- `port`

    This is the preferred port local host binds and expects incoming peers to
    connect to.

    By default, this is a zero; the system will pick a port number randomly.

- `on_hash_fail`

    This is a subroutine called whenever a piece fails to pass
    [hashcheck](#hashcheck). The callback is handed the piece's index.

- `on_hash_pass`

    This is a subroutine called whenever a piece passes its
    [hashcheck](#hashcheck). The callback is handed the piece's index.

- `state`

    This must be one of the following:

    - `started`

        This is the default. The client will attempt to create new connections, make
        and fill requests, etc. This is normal client behavior.

    - `paused`

        In this state, connections will be made and accepted but no piece requests
        will be made or filled. To resume full, normal behavior, you must call
        [`start( )`](#start).

    - `stopped`

        Everything is put on hold. No new outgoing connections are attempted and
        incoming connections are rejected. To resume full, normal behavior, you must
        call [`start( )`](#start).

- `piece_cache`

    This is the index list returned by [`piece_cache( )`](#piece_cache) in a
    previous instance. Using this should make a complete resume system a trivial
    task.

## `hashcheck( [...] )`

This method expects...

- ...a list of integers. You could use this to check a range of pieces (a
single file, for example).

            $client->hashcheck( 1 .. 5, 34 .. 56 );

- ...a single integer. Only that specific piece is checked.

            $client->hashcheck( 17 );

- ...nothing. All data related to this torrent will be checked.

            $client->hashcheck( );

As pieces pass or fail, your `on_hash_pass` and `on_hash_fail` callbacks are
triggered.

## `start( )`

Sends a 'started' event to trackers and starts performing as a client is
expected. New connections are made and accepted, requests are made and filled,
etc.

## `stop( )`

Sends a stopped event to trackers, closes all connections, stops attempting
new outgoing connections, rejects incoming connections and closes all open
files.

## `pause( )`

The client remains mostly active; new connections will be made and accepted,
etc. but no requests will be made or filled while the client is paused.

## `infohash( )`

Returns the 20-byte SHA1 hash of the value of the info key from the metadata
file.

## `peerid( )`

Returns the 20 byte string used to identify the client. Please see the
[spec](#peerid-specification) below.

## `port( )`

Returns the port number the client is listening on.

## `size( )`

Returns the total size of all [files](#files) described in the torrent's
metadata.

## `name( )`

Returns the UTF-8 encoded string the metadata suggests we save the file (or
directory, in the case of multi-file torrents) under.

## `uploaded( )`

Returns the total amount uploaded to remote peers.

## `downloaded( )`

Returns the total amount downloaded from other peers.

## `left( )`

Returns the approximate amount based on the pieces we still
[want](#wanted) multiplied by the [size of pieces](#piece_length).

## `piece_length( )`

Returns the number of bytes in each piece the file or files are split into.
For the purposes of transfer, files are split into fixed-size pieces which are
all the same length except for possibly the last one which may be truncated.

## `bitfield( )`

Returns a packed binary string in ascending order (ready for `vec()`). Each
index that the client has is set to one and the rest are set to zero.

## `wanted( )`

Returns a packed binary string in ascending order (ready for `vec()`). Each
index that the client has or simply does not want is set to zero and the rest
are set to one.

This value is calculated every time the method is called. Keep that in mind.

## `complete( )`

Returns true if we have downloaded everything we [wanted](#wanted) which
is not to say that we have all data and can [seed](#seed).

## `seed( )`

Returns true if we have all data related to the torrent.

## `files( )`

Returns a list of hash references with the following keys:

- `length`

    Which is the size of file in bytes.

- `path`

    Which is the absolute path of the file.

- `priority`

    Download priority for this file. By default, all files have a priority of
    `1`. There is no built in scale; the higher the priority, the better odds a
    piece from it will be downloaded first. Setting a file's priority to `1000`
    while the rest are still at `1` will likely force the file to complete before
    any other file is started.

    We do not download files with a priority of zero.

## `peers( )`

Returns the list of currently connected peers. The organization of these peers
is not yet final so... don't write anything you don't expect to break before
we hit `v1.0.0`.

## `state( )`

Returns `active` if the client is [started](#start), `paused` if client
is [paused](#pause), and `stopped` if the client is currently
[stopped](#stop).

## `piece_cache( )`

Pieces which overlap files with zero priority are stored in a part file which
is indexed internally. To save this index (for resume, etc.) store the values
returned by this method and pass it to [new( )](#new).

## `trackers( )`

Returns a list of hashes, each representing a single tier of trackers as
defined by [BEP12](https://metacpan.org/pod/Net::BitTorrent::Protocol::BEP12). The hashes contain the
following keys:

- `complete`

    The is a count of complete peers (seeds) as returned by the most recent
    announce.

- `failures`

    This is a running total of the number of failed announces we've had in a row.
    This value is reset when we have a successful announce.

- `incomplete`

    The is a count of incomplete peers (leechers) as returned by the most recent
    announce.

- `peers`

    Which is a compact collection of IPv4 peers returned by the tracker. See
    [BEP23](https://metacpan.org/pod/Net::BitTorrent::Protocol::BEP23).

- `peers6`

    Which is a compact collection of IPv6 peers returned by the tracker. See
    [BEP07](https://metacpan.org/pod/Net::BitTorrent::Protocol::BEP07).

- `urls`

    Which is a list of URLs.

# This Module is Lame!

Yeah, I said it.

There are a few things a BitTorrent client must implement (to some degree) in
order to interact with other clients in a modern day swarm.
[AnyEvent::BitTorrent](https://metacpan.org/pod/AnyEvent::BitTorrent) is meant to meet that bare
minimum but it's based on [Moo](https://metacpan.org/pod/Moo) so you could always subclass it to add more
advanced functionality. Hint, hint!

## What is currently supported?

Basic stuff. We can make and handle piece requests. Deal with cancels,
disconnect idle peers, unchoke folks, fast extensions, file download
priorities. Normal... stuff. HTTP trackers.

## What will probably be supported in the future?

DHT (which will likely be in a separate dist), IPv6 stuff... I'll get around
to those.

Long term, UDP trackers may be supported.

For a detailed list, see the TODO file included with this distribution.

## What will likely never be supported?

We can't have nice things. Protocol encryption, uTP, endgame tricks, ...these
will probably never be included in [AnyEvent::BitTorrent](https://metacpan.org/pod/AnyEvent::BitTorrent).

## What should I use instead?

If you're reading all of this with a scowl, there are many alternatives to
this module, most of which are sure to be better suited for advanced users. I
suggest (in no particular order):

- [BitFlu](http://bitflu.workaround.ch/). It's written in Perl but you'll
still need to be on a Linux, \*BSD, et al. system to use it.
- [Net::BitTorrent](https://metacpan.org/pod/Net::BitTorrent) ...in the future. I _do not_ suggest using either
the current stable or unstable versions found on CPAN. The next version is
being worked on and will be based on [Reflex](https://metacpan.org/pod/Reflex).

If you're working on a Perl based client and would like me to link to it, send
a bug report to the tracker [listed below](#bug-reports).

# Subclassing AnyEvent::BitTorrent

TODO

If you subclass this module and change the way it functions to that which in
any way proves harmful to individual peers or the swarm at large, rather than
damage [AnyEvent::BitTorrent](https://metacpan.org/pod/AnyEvent::BitTorrent)'s reputation, override the peerid attribute.
Thanks.

# PeerID Specification

[AnyEvent::BitTorrent](https://metacpan.org/pod/AnyEvent::BitTorrent) may be identified in a swarm by its peer id. As of
this version, our peer id is in 'Azureus style' with a single digit for the
Major version, two digits for the minor version, and a single character to
indicate stability (stable releases marked with `S`, unstable releases marked
with `U`). It looks sorta like:

        -AB110S-  Stable v1.10.0 relese (typically found on CPAN, tagged in repo)
        -AB110U-  Unstable v1.10.X release (private builds, early testing, etc.)

# Bug Reports

If email is better for you, [my address is mentioned below](#author) but I
would rather have bugs sent through the issue tracker found at
http://github.com/sanko/anyevent-bittorrent/issues.

Please check the ToDo file included with this distribution in case your bug
is already known (...I probably won't file bug reports to myself).

# See Also

[Net::BitTorrent::Protocol](https://metacpan.org/pod/Net::BitTorrent::Protocol) - The package which does all of the wire protocol
level heavy lifting.

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

# License and Legal

Copyright (C) 2011-2016 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
[The Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).
See the `LICENSE` file included with this distribution or
[notes on the Artistic License 2.0](http://www.perlfoundation.org/artistic_2_0_notes)
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by-sa/3.0/us/legalcode).
See the
[clarification of the CCA-SA3.0](http://creativecommons.org/licenses/by-sa/3.0/us/).

Neither this module nor the [Author](#author) is affiliated with BitTorrent,
Inc.
