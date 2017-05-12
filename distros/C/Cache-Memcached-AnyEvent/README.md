# NAME

Cache::Memcached::AnyEvent - AnyEvent Compatible Memcached Client 

# SYNOPSIS

    use Cache::Memcached::AnyEvent;

    my $memd = Cache::Memcached::AnyEvent->new({
        servers => [ '127.0.0.1:11211' ],
        compress_threshold => 10_000,
        namespace => 'myapp.',
    });

    $memd->get( $key, sub {
        my ($value) = @_;
        warn "got $value for $key";
    });

    $memd->disconnect();

    # use ketama algorithm instead of the traditional one
    my $memd = Cache::Memcached::AnyEvent->new({
        ...
        selector_class => 'Ketama',
        # or, selector => $object 
    });

    # use binary protocol instead of text
    my $memd = Cache::Memcached::AnyEvent->new({
        ...
        protocol_class => 'Binary',
        # or, protocol => $object,
    });

# DESRIPTION

WARNING: BETA QUALITY CODE!

This module implements the memcached protocol as a AnyEvent consumer, and it implments both for text and binary protocols.

# RATIONALE

There's another alternative [AnyEvent](https://metacpan.org/pod/AnyEvent) memcached client, [AnyEvent::Memcached](https://metacpan.org/pod/AnyEvent::Memcached) which is perfectly fine, and I have nothing against you using that module. I just have some specific itches to scratch:

- Prerequisites

    This module, [Cache::Memcached::AnyEvent](https://metacpan.org/pod/Cache::Memcached::AnyEvent), requires the bare minimum prerequisites to install. [AnyEvent::Memcached](https://metacpan.org/pod/AnyEvent::Memcached) requires AnyEvent::Connection and Object::Event ;) Those modules are fine, I just don't use them, so I don't want them.

- Binary Protocol

    I was in the mood to implement the binary protocol. I don't believe it's a requirement to do anything, so this is purely a whim. There's nothing that requires binary protocol in the wild, so it has no practactical advantages. I just wanted to implement it :)

- Cache::Memcached Interface

    In general, this module follows the interface of Cache::Memcached.

So choose according to your needs. If you for some reason don't want AnyEvent::Connection and Object::Event, want a binary protocol, and like to stick with Cache::Memcached interface (relatively speaking), then use this module. Otherwise, read the docs for each module, and choose the one that fits your needs.

# METHODS

All methods interacting with a memcached server which can take a callback
function can also take a condvar instead. For example, 

    $memd->get( "foo", sub {
        my $value = shift;
    } );

is equivalent to

    my $cv = AE::cv {
        my $value = $_[0]->recv;
    };
    $memd->get( "foo", $cv );
    # optionally, call $cv->recv here.

## new(%args) 

- auto\_reconnect => $max\_attempts

    Set to 0 to disable auto-reconnecting

- compress\_threshold => $number
- selector => $object

    The selector is an object responsible for selecting the appropriate
    Memcached server to store a particular key. This object MUST implement
    the following methods:

        $object->set_server( @servernames );
        my $handle = $object->get_handle( $key );

    By default if this argument is not specified, a selector object will
    automatically be created using the value of the `selector_class`
    argument.

- selector\_class => $class\_name\_or\_fragment

    Specifies the selector class to be instantiated. The default value is "Traditional".

    If the class name is preceded by a single '+', then that class name with the
    '+' removed will be used as the class name. Otherwise, the prefix
    "Cache::Memcached::AnyEvent::Selector::" will be added to the value
    ("Traditional" would be transformed to "Cache::Memcached::AnyEvent::Selector::Traditional")

- namespace => $namespace
- procotol => $object

    The protocol is an object responsible for handling the actual talking to
    the memcached servers. This object MUST implement all of the memcached
    interface supported by Cache::Memcached::AnyEvent

    By default if this argument is not specified, a protocol object will
    automatically be created using the value of the `protocol_class`
    argument.

- protocol\_class => $classname

    Specifies the protocol class to be instantiated. The default value is "Text".

    If the class name is preceded by a single '+', then that class name with the
    '+' removed will be used as the class name. Otherwise, the prefix
    "Cache::Memcached::AnyEvent::Protocol::" will be added to the value
    ("Text" would be transformed to "Cache::Memcached::AnyEvent::Protocol::Text")

- reconnect\_delay => $seconds

    Amount of time to wait between reconnect attempts

- servers => \\@servers

    List of servers to use.

`%args` can also be a hashref.

## auto\_reconnect(\[$bool\]);

Get/Set auto\_reconnect flag.

## add($key, $value\[, $exptime, $noreply\], $cb->($rc))

## add\_server( $host\_port )

## append($key, $value, $cb->($rc))

## connect()

Explicitly connects to each server given. You DO NOT need to call this
explicitly.

## decr($key, $delta\[, $initial\], $cb->($value))

## delete($key, $cb->($rc))

## disconnect()

## flush\_all()

## get($key, $cb->($value))

## get\_handle( $host\_port )

## get\_multi(\\@keys, $cb->(\\%values));

## incr($key, $delta\[, $initial\], $cb->($value))

## prepend($key, $value, $cb->($rc));

## protocol($object)

## replace($key, $value\[, $exptime, $noreply\], $cb->($rc))

## remove($key, $cb->($rc))

Alias to delete

## servers()

## set($key, $value\[, $exptime, $noreply\], $cb->($rc))

## stats($cmd, $cb->(\\%stats))

## version( $cb->(\\%result) )

# TODO

- Binary stats is not yet implemented.

# CONTRIBUTING

Contribution is welcome, but please make sure to follow this guideline:

- Please send changes AND tests.

    In case of changes that supposedly fixes incorrect behavior, you MUST provide
    me with a __failing test case__. How should we know if you were hallucinating or just plain stupid if you can't reproduce it yourself?

- Please send code, not an essay.

    Please don't waste time trying to explain in a 10K email for stuff you can write in 10 lines of code.

    I'm sorry, but I'm usually not interested in your opinion until I see some code. Writing essays to describe a software problem is stupid.

- Please avoid emailing patches.

    If at all possible, please use github pull requests instead of emailing me patches. Patches are stupid.

    Please refer to the META.yml file for the repository location.

So to summarize, contribution is welcome, but please don't be stupid.
If you can't follow the guideline, you will not be taken seriously.

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
