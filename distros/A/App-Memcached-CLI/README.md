[![Build Status](https://travis-ci.org/key-amb/perl5-App-Memcached-CLI.svg?branch=master)](https://travis-ci.org/key-amb/perl5-App-Memcached-CLI)
# NAME

**memcached-cli** - Interactive/Batch CLI for Memcached

# SYNOPSIS

Run an interactive CLI:

```
memcached-cli <HOST[:PORT] | /path/to/socket> [OPTIONS]
memcached-cli --addr|-a <HOST[:PORT] | /path/to/socket> [OPTIONS]
memcached-cli [OPTIONS]  # Connect to 127.0.0.1:11211
```

These above turns into interactive mode like below:

```
memcached@SERVER:PORT>
memcached@SERVER:PORT> set foo Foo
OK
memcached@SERVER:PORT> add bar Bar 300
OK
memcached@SERVER:PORT> gets foo bar
Key:foo Value:Foo       Length:3B       Flags:0 Cas:219
Key:bar Value:Bar       Length:3B       Flags:0 Cas:220
memcached@SERVER:PORT> \cd 1  # Alias of 'cachedump'
Key:foo Value:Foo       Length:3B       Expire:2016-03-26 00:30:27      Flags:0 Cas:219
Key:bar Value:Bar       Length:3B       Expire:2016-03-26 09:53:19      Flags:0 Cas:220
Key:baz Value:Baz       Length:3B       Expire:2016-03-26 10:49:05      Flags:123       Cas:221
memcached@SERVER:PORT> delete foo
OK
memcached@SERVER:PORT> flush_all
OK
memcached@SERVER:PORT> \q     # Quit interactive mode
```

Run as batch script:

```
memcached-cli [options] <command> [<args>]
```

Show Help/Manual:

```
# For general usage
memcached-cli -h|--help
memcached-cli --man

# For available commands
memcached@SERVER:PORT> help
memcached@SERVER:PORT> help <command>
```

# DESCRIPTION

This script runs an interactive CLI or batch utility for Memcached.

In interactive mode, it connects to a specified Memcached server and
interactively executes each command you run.

In batch mode, you can execute any command which you can do in interactive mode.

# COMMANDS

NOTE:

A couple of features of following commands derives from
[memcached/memcached-tool](https://github.com/memcached/memcached/blob/master/scripts/memcached-tool)

- **display|\\d**

    Displays slabs statistics.

    This command comes from _memcached/memcached-tool_.

- **stats|\\s** _REGEXP_

    Shows general statistics of memcached server by `stats` command.
    You can filter the parameters of stats by optional _REGEXP_ argument.

    Comes from _memcached/memcached-tool_.

- **settings|config|\\c** _REGEXP_

    Shows memcached server settings by `stats settings` command.
    You can filter the parameters of stats by optional _REGEXP_ argument.

    Comes from _memcached/memcached-tool_, too.

- **cachedump|\\cd** _CLASS_ \[_NUMBER_\]

    Shows detailed information including expiration times of some items in specified
    slab _CLASS_.

    You can specify _NUMBER_ of items to show.
    Without _NUMBER_ option, shows 20 items only by default.

- **detaildump|\\dd**

    Reports statistics about data access using KEY prefix. The default separator for
    prefix is ':'.

    If you have not enabled reporting at Memcached start-up, you can enable it by
    command `detail on`.

    See man **memcached(1)** for details.

- **detail** _MODE_

    Enables or disables stats collection for `stats detail dump` reporting.

    _MODE_ should be either "on" or "off" to enable or to disable.

- **dump\_all**

    Dumps whole data in Memcached server.

    This command comes from _memcached/memcached-tool_.

    Recommended to use in batch mode like bellow:

    ```
    memcached-cli SERVER:PORT dump_all > /path/to/dump.txt
    ```

- **restore\_dump** _FILE_

    Restore data from dump data file created by `dump_all`.

- **randomset|sample** \[_NUMBER_ \[_MAX\_LENGTH_ \[_MIN\_LENGTH_ \[_NAMESPACE_\]\]\]\]

    Generates random sample data and SET all of them.

    By default, it generates 100 data whose length is between 1B and 1000kB with prefix "memcached-cli:sample";

- **get** _KEY1_ \[_KEY2_ ...\]

    Gets items in memcached by specified _KEYs_ and shows their data.

- **gets** _KEY1_ \[_KEY2_ ...\]

    Gets items with _CAS_ data in memcached by specified _KEYs_ and shows their
    data.

- **set** _KEY_ _VALUE_ \[_EXPIRE_ \[_FLAGS_\]\]

    Stores data into memcached by specified _KEY_, _VALUE_ and optional _EXPIRE_
    and _FLAGS_.

- **add** _KEY_ _VALUE_ \[_EXPIRE_ \[_FLAGS_\]\]

    Stores data into memcached by specified _KEY_, _VALUE_ and optional _EXPIRE_
    and _FLAGS_ only when there is NO data with the same _KEY_ in the server.

- **replace** _KEY_ _VALUE_ \[_EXPIRE_ \[_FLAGS_\]\]

    Stores data into memcached by specified _KEY_, _VALUE_ and optional _EXPIRE_
    and _FLAGS_ only when there IS data with the same _KEY_ in the server.

- **append** _KEY_ _VALUE_

    Appends _VALUE_ after existing data in memcached which has specified _KEY_.

- **prepend** _KEY_ _VALUE_

    Puts _VALUE_ before existing data in memcached which has specified _KEY_.

- **cas** _KEY_ _VALUE_ _CAS_ \[_EXPIRE_ \[_FLAGS_\]\]

    Stores data into memcached by specified _KEY_, _VALUE_ and optional _EXPIRE_
    and _FLAGS_ only when _CAS_ of data is not changed from specified _CAS_ value.

- **touch** _KEY_ _EXPIRE_

    Update data expiration time with specified _KEY_ and _EXPIRE_.

- **incr** _KEY_ _VALUE_

    Add numeric _VALUE_ for a data with specified _KEY_.

- **decr** _KEY_ _VALUE_

    Subtract numeric _VALUE_ from a data with specified _KEY_.

- **delete** _KEY_

    Deletes one item in memcached by specified _KEY_.

- **flush\_all|flush** \[_DELAY_\]

    Invalidates all data in memcached by `flush_all` command.

    With _DELAY_ option, invalidation is delayed for specified seconds.

    See official documentation of _memcached_ for details.

- **call** _COMMAND_ \[_ARGS_ ...\]

    Executes any commands given as arguments.

    With this command, you can execute any command against Memcached including what
    is not implemented as normal commands in this program.

    Here are some examples:

    ```
    > call stats conns
    > call slabs reassign 6 10
    > call flush_all
    ```

    LIMITATION:

    Multi-lined queries like `set` are not supported.

- **version**

    Shows memcahed server version.

- **quit|exit|\\q**

    Exits program in interactive mode.

- **help|\\h** \[_COMMAND_\]

    Shows available _COMMANDs_ and summary of their usage.

    With optional _COMMAND_ argument, shows detailed information of it.

# OPTIONS

- **-t|--timeout=Int**

    Sets connection timeout. Default is 1 seconds.

- **-d|--debug**

    Shows debug logs.

# SEE ALSO

[App::Memcached::CLI::Main](https://metacpan.org/pod/App::Memcached::CLI::Main),
**memcached(1)**,
[http://www.memcached.org/](http://www.memcached.org/)

# AUTHORS

YASUTAKE Kiyoshi <yasutake.kiyoshi@gmail.com>

# LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.
