[![Actions Status](https://github.com/sanko/App-bsky/actions/workflows/ci.yml/badge.svg)](https://github.com/sanko/App-bsky/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-bsky.svg)](https://metacpan.org/release/App-bsky)
# NAME

bsky - A Command-line Bluesky Client

# SYNOPSIS

```perl
# create user session
$ bsky login [handle] [password]

# view recent posts
$ bsky timeline ...

# create a post
$ bsky post ...
```

# DESCRIPTION

`bsky` is a simple command line client for Bluesky in Perl.

# Commands

```
bsky [global options] command [command options] [arguments...]
```

## config

```
# Print all configuration values
bsky config

# Print a single config value and exit
bsky config wrap

# Set a configuration value
bsky config wrap 100
```

View or change configuration values. See [Configuration](#configuration) for a list of current options.

### Options

```
key         optional
value       optional
```

## show-profile

```
bsky show-profile

bsky show-profile --handle sankor.bsky.social

bsky show-profile --json
```

Show profile.

### Options

```perl
--handle handle     user handle; defaults to the logged in account
-H handle           alternative to --handle
--json              boolean flag; content is printed as JSON objects if given
```

## update-profile

```
bsky update-profile --description "Looks like we made it!"

bsky update-profile --name "John Smith"

bsky update-profile --avatar https://cataas.com/cat?width=100 --banner https://cataas.com/cat?width=1000
```

Update profile elements.

### Options

```
--avatar        optional, avatar image (url or local path)
--banner        optional, banner image (url or local path)
--description   optional, blurb about yourself
--name          optional, display name
```

## show-session

```
bsky show-session

bsky show-session --json
```

Show current session.

### Options

```
--json              boolean flag; content is printed as JSON objects if given
```

## timeline

```
bsky timeline

bsky timeline --json

# shorthand:
bsky tl
```

Display posts from timeline.

### Options

```
--json      boolean flag; content is printed as JSON objects if given
```

## thread

```
thread at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3kjyoh75qne2w
```

Show a thread.

### Options

```
--json      boolean flag; content is printed as JSON objects if given
-n   value  number of items
```

## post

```
post "This is a test"
```

Create a new post.

## like

```
bsky like at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3kjyoh75qne2w
```

Like a post.

## unlike

```
bsky unlike at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3kjyoh75qne2w

bsky unlike at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.like/3kjyml72tqu2y
```

Unlike a post. Either the direct feed URI or the like URI printed by `bsky like ...`.

## likes

```
bsky likes at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3kjyoh75qne2w
```

Show likes on a post.

### Options

```
--json              boolean flag; content is printed as JSON objects if given
```

## repost

```
bsky repost at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3kjyoh75qne2w
```

Repost the post.

## reposts

```
bsky reposts at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3kjyoh75qne2w
```

Show reposts of the post.

### Options

```
--json              boolean flag; content is printed as JSON objects if given
```

## follow

```
bsky follow [handle]

bsky follow sankor.bsky.social

bsky follow did:plc:2lk3pbakx2erxgotvzyeuyem
```

Follow the handle

### Options

```perl
handle          user handle or DID
```

## unfollow

```
bsky unfollow [handle]

bsky unfollow sankor.bsky.social

bsky unfollow did:plc:2lk3pbakx2erxgotvzyeuyem
```

Unfollow the handle

### Options

```perl
handle          user handle or DID
```

## follows

```
bsky follows

bsky follows --handle sankor.bsky.social

bsky follows --json
```

Show follows.

### Options

```perl
--handle handle     user handle; defaults to the logged in account
-H handle           alternative to --handle
--json              boolean flag; content is printed as JSON objects if given
```

## followers

```
bsky followers

bsky followers --handle sankor.bsky.social

bsky followers --json
```

Show followers.

### Options

```perl
--handle handle     user handle; defaults to the logged in account
-H handle           alternative to --handle
--json              boolean flag; content is printed as JSON objects if given
```

## block

```
bsky block [handle]

bsky block sankor.bsky.social

bsky block did:plc:2lk3pbakx2erxgotvzyeuyem
```

Block the handle.

### Options

```perl
handle          user handle or DID
```

## unblock

```
bsky unblock [handle]

bsky unblock sankor.bsky.social

bsky unblock did:plc:2lk3pbakx2erxgotvzyeuyem
```

Unblock the handle.

### Options

```perl
handle          user handle or DID
```

## blocks

```
bsky blocks

bsky blocks --json
```

Show blocks.

### Options

```
--json              boolean flag; content is printed as JSON objects if given
```

## delete

```
bsky delete at://did:p...
```

Delete a post, repost, etc.

## notifications

```
bsky notifications

bsky notifications --all

bsky notifications --json

# shorthand
bsky notif --all
```

Show notifications.

### Options

```
--all               boolean flag, show all notifications
--json              boolean flag; content is printed as JSON objects if given
```

## invite-codes

```
bsky invite-codes

bsky invite-codes --json
```

Show invite codes.

Note that you must be logged in with the account password to view invite codes.

### Options

```
--json              boolean flag; content is printed as JSON objects if given
```

## add-app-password

```
bsky add-app-password "Your app name"
```

Create a new App password.

Note that you must be logged in with the account password to add a new app password.

## revoke-app-password

```
bsky revoke-app-password "Your app name"
```

Delete App password.

Note that you must be logged in with the account password to revoke an app password.

## list-app-passwords

```
bsky list-app-passwords

bsky list-app-passwords --json
```

Show App passwords.

### Options

```
--json              boolean flag; content is printed as JSON objects if given
```

## login

```
bsky login [ident] [password] [--host http://bsky.social]
```

Log into a Bluesky account.

### Options

```
ident
password
--host        optional, defaults to https://bsky.social
```

## help

shows a list of commands or help for one command

# Global Options

```
--help, -h     show help
--version, -v  print the version
-V             print verbose version info
```

# Configuration

Current configuration values include:

- `wrap`

    ```
    bsky config wrap 100
    ```

    Sets word wrap width in characters for terminal output. The default is `0` which disables word wrap.

# See Also

[At](https://metacpan.org/pod/At).pm

[https://github.com/mattn/bsky](https://github.com/mattn/bsky) - Original Golang client

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
