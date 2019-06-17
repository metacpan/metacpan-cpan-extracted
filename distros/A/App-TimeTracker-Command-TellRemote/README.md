# NAME

App::TimeTracker::Command::TellRemote - App::TimeTracker plugin for telling generic remotes

# VERSION

version 3.000

# DESCRIPTION

We use an internal IRC channel for internal communication. And we all want (need) to know what other team members are currently doing. This plugin helps us making sharing this information easy.

After running some commands, this plugin prepares a short message and
sends it (together with an authentification token) to a small
webserver-cum-irc-bot (`Bot::FromHTTP`, not yet on CPAN, but basically
just a slightly customized/enhanced pastebin).

The messages is transfered as a GET-Request like this:

    http://yourserver/?message=some message&token=a58875d576e8c09a...

# CONFIGURATION

## plugins

add `TellRemote` to your list of plugins

## tell\_remote

add a hash named `tell_remote`, containing the following keys:

### host

The hostname of the server `Bot::FromHTTP` is running on. Might also contain a special port number (`http://ircbox.vpn.yourcompany.com:9090`)

### secret

A shared secret used to calculate the authentification token. The token is calculated like this:

    my $token = Digest::SHA::sha1_hex($message, $secret);

# NEW COMMANDS

none

# CHANGES TO OTHER COMMANDS

## start, stop, continue

After running the respective command, a message is sent to the
remote that could for example post the message to IRC.

### New Options

#### --tell\_remote

Defaults to true, but you can use:

    ~/perl/Your-Secret-Project$ tracker start --no_tell_remote

to **not** send a message

# AUTHOR

Thomas Klausner <domm@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2019 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
