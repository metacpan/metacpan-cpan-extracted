# NAME

CHI::Driver::SharedMem - Cache data in shared memory

# VERSION

Version 0.18

# SYNOPSIS

[CHI](https://metacpan.org/pod/CHI) driver which stores data in shared memory objects for persistence
over processes.
Size is an optional parameter containing the size of the shared memory area,
in bytes.
Shmkey is a mandatory parameter containing the IPC key for the shared memory
area.
See [IPC::SharedMem](https://metacpan.org/pod/IPC%3A%3ASharedMem) for more information.

    use CHI;
    my $cache = CHI->new(
        driver => 'SharedMem',
        max_size => 2 * 1024,   # Size of the cache
        shm_size => 32 * 1024,  # Size of the shared memory area
        shm_key => 12344321,    # Choose something unique, but the same across
                                # all caches so that namespaces will be shared,
                                # but we won't step on any other shm areas
    );
    # ...

The shared memory area is stored thus:

        # Number of bytes in the cache [ int ]
        'cache' => {
                'namespace1' => {
                        'key1' => 'value1',
                        'key2' => 'value2',
                        # ...
                },
                'namespace2' => {
                        'key1' => 'value3',
                        'key3' => 'value2',
                        # ...
                }
                # ...
        }

# SUBROUTINES/METHODS

## store

Stores an object in the cache.
The data are serialized into JSON.

## fetch

Retrieves an object from the cache

## remove

Remove an object from the cache

## clear

Removes all data from the current namespace

## get\_keys

Gets a list of the keys in the current namespace

## get\_namespaces

Gets a list of the namespaces in the cache

## default\_discard\_policy

Use an LRU algorithm to discard items when the cache can't add anything

## discard\_policy\_lru

When the Shared memory area is getting close to full, discard the least recently used objects

## BUILD

Constructor - validate arguments

## DEMOLISH

If there is no data in the shared memory area, and no-one else is using it,
it's safe to remove it and reclaim the memory.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-chi-driver-sharedmem at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-SharedMem](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-SharedMem).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Max\_size is handled, but if you're not consistent across the calls to each cache,
the results are unpredictable because it's used to create the size of the shared memory
area.

The shm\_size argument should be deprecated and only the max\_size argument used.

# SEE ALSO

[CHI](https://metacpan.org/pod/CHI), [IPC::SharedMem](https://metacpan.org/pod/IPC%3A%3ASharedMem)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CHI::Driver::SharedMemory

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/CHI-Driver-SharedMem](https://metacpan.org/dist/CHI-Driver-SharedMem)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-SharedMemory](https://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-SharedMemory)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=CHI-Driver-SharedMemory](http://matrix.cpantesters.org/?dist=CHI-Driver-SharedMemory)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=CHI::Driver::SharedMemory](http://deps.cpantesters.org/?module=CHI::Driver::SharedMemory)

# LICENSE AND COPYRIGHT

Copyright 2010-2023 Nigel Horne.

This program is released under the following licence: GPL2
