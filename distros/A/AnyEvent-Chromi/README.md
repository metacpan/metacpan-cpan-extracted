# NAME

AnyEvent::Chromi - Remotely control Google Chrome from Perl

## SYNOPSIS

    # Start in client mode (need "chromix-server" or examples/server.pl)
    my $chromi AnyEvent::Chromi->new(mode => 'client', on_connect => sub {
        my ($chromi) = @_;
        ...
        $chromi->call(...);
    });

    # Start in server mode
    my $chromi AnyEvent::Chromi->new(mode => 'server');

## DESCRIPTION

AnyEvent::Chromi allows you to remotely control Google Chrome from a Perl script.
It requires the Chromi extension [https://github.com/smblott-github/chromi](https://github.com/smblott-github/chromi), which
exposes all of the Chrome Extensions API via a websocket connection.

## METHODS

- $chromi = AnyEvent::Chromi->new(mode => ..., on\_connect => ...);
    - mode => 'client|server'

        If 'server' (default), it will start a websocket server on port 7441 and wait
        for the connection from Chrome (initiated by the Chromi extension). This is the
        most practical way to use AnyEvent::Chromi if you write a long-running script,
        because it doesn't require a separate daemon.

        If 'client', it will connect to port 7441 itself, expecting a websocket server, like
        the one provided by chromix-server, or by the examples/server.pl script.

    - port => N

        Use port N instead of 7441.

    - on\_connect => sub { my ($chromi) = @\_; ... }

        Will be executed as soon as Chrome connects (in server mode), or as the connection
        to the websocket server is done.
- $chromi->call($method, $args, $cb)

    Call the Chrome extension method `$method`, e.g. `chrome.windows.getAll`.

    `$args` is expected to be a ARRAYREF with the arguments for the method. It will be
    converted to JSON by AnyEvent::Chromi.

    `$cb` is a callback for when the reply is received. The first argument to the callback is
    the status (either "done" or "error"), and the second is a ARRAYREF with the data.

    Note: you need to make sure that the JSON::XS serialization is generating the proper
    data types. This is particularly important for booleans, where `Types::Serialiser::true`
    and `Types::Serialiser::false` can be used.

- $chromi->is\_connected

    In server mode: returns true if Chrome is connected and awaits commands.

    In client mode: returns true if connected to chromix-server.

## EXAMPLES

- List all tabs

        $chromi->call(
            'chrome.windows.getAll', [{ populate => Types::Serialiser::true }],
            sub {
                my ($status, $reply) = @_;
                $status eq 'done' or return;
                defined $reply and ref $reply eq 'ARRAY' or return;
                map { say "$_->{url}" } @{$reply->[0]{tabs}};
                $cv->send();
            }

- Focus a tab

        $chromi->call(
            'chrome.tabs.update', [$tab_id, { active => Types::Serialiser::true }],
        );

See also the "examples" directory:

- examples/client.pl

    Lists the URLs of all tabs. Requires chromix-server

- examples/server.pl

    chromix-server replacement written in Perl. Additionally to chromix-server, it
    also properly supports multiple clients with one or more chrome instances.

## AUTHOR

David Schweikert &lt;david@schweikert.ch>, heavily influenced by Chromi/Chromix by
Stephen Blott.

## SEE ALSO

- GitHub project

    [https://github.com/open-ch/AnyEvent-Chromi](https://github.com/open-ch/AnyEvent-Chromi)

- Chromi (Chrome extension)

    [https://github.com/smblott-github/chromi](https://github.com/smblott-github/chromi)

- Chromix (command-line tool)

    [https://http://chromix.smblott.org/](https://http://chromix.smblott.org/)
