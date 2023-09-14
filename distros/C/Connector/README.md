# NAME

Connector - a generic connection to a hierarchical-structured data set

# DESCRIPTION

The Connector is generic connection to a data set, typically configuration
data in a hierarchical structure. Each connector object accepts the get(KEY)
method, which, when given a key, returns the associated value from the
connector's data source.

Typically, a connector acts as a proxy to a simple data source like
YAML, Config::Std, or to a more complex data source
like an LDAP server or Proc::SafeExec. The standard calling convention
via get(KEY) makes the connectors interchangeable.

In addition, a set of meta-connectors may be used to combine multiple
connectors into more complex chains. The Connector::Multi, for example,
allows for redirection to delegate connectors via symbolic links. If
you have a list of connectors and want to use them in a load-balancing,
round-robin fashion or have the list iterated until a value is found,
use Connector::List and choose the algorithm to perform.

# SYNOPSIS

    use Connector::MODULENAME;

    my $conn = Connector::MODULENAME->new( {
        LOCATION => $path_to_config_for_module,
    });

    my $val = $conn->get('full.name.of.key');

## Connector Class

This is the base class for all Connector implementations. It provides
common helper methods and performs common sanity checking.

Usually this class should not be instantiated directly.

# CONFIGURATION

## die\_on\_undef

Set to true if you want the connector to die when a query reaches a non-exisiting
node. This will affect calls to get/get\_list/get\_hash and will not affect
values that are explicitly set to undef (if supported by the connector!).

# Accessor Methods

Each accessor method is valid only on special types of nodes. If you call them
on a wrong type of node, the connector may retunr unexpected result or simply die.

## exists

## get

Basic method to obtain a scalar value at the leaf of the config tree.

    my $value = $connector->get('smartcard.owners.tokenid.bob');

Each implementation must also accept an arrayref as path. The path is
contructed from the elements. The default behaviour allows strings using
the delimiter character inside an array element. If you want each array
element to be parsed, you need to pass "RECURSEPATH => 1" to the constructor.

    my $value = $connector->get( [ 'smartcard','owners','tokenid','bob.builder' ] );

Some implementations accept control parameters, which can be passed by
_params_, which is a hash ref of key => value pairs.

    my $value = $connector->get( 'smartcard.owners.tokenid.bob' , { version => 1 } );

## get\_list

This method is only valid if it is called on a "n-1" depth node representing
an ordered list of items (array). The return value is an array with all
values present below the node.

    my @items = $connector->get_list( 'smartcard.owners.tokenid'  );

## get\_size

This method is only valid if it is called on a "n-1" depth node representing
an ordered list of items (array). The return value is the number of elements
in this array (including undef elements if they are explicitly given).

    my $count = $connector->get_size( 'smartcard.owners.tokens.bob' );

If the node does not exist, 0 is returned.

## get\_hash

This method is only valid if it is called on a "n-1" depth node representing
a key => value list (hash). The return value is a hash ref.

    my %data = %{$connector->get_hash( 'smartcard.owners.tokens.bob' )};

## get\_keys

This method is only valid if it is called on a "n-1" depth node representing
a key => value list (hash). The return value is an array holding the
values of all keys (including undef elements if they are explicitly given).

    my @keys = $connector->get_keys( 'smartcard.owners.tokens.bob' );

If the node does not exist, an empty list is returned.

## get\_reference \[deprecated\]

Rarely used, returns the value of a reference node. Currently used by
Connector::Multi in combination with Connector::Proxy::Config::Versioned
to create internal links and cascaded connectors. See Connector::Multi
for details.

## set

The set method is a "all in one" implementation, that is used for either type
of value. If the value is not a scalar, it must be passed by reference.

    $connector->set('smartcard.owners.tokenid.bob', $value, $params);

The _value_ parameter holds a scalar or ref to an array/hash with the data to
be written. _params_ is a hash ref which holds additional parameters for the
operation and can be undef if not needed.

# STRUCTURAL METHODS

## get\_meta

This method returns some structural information about the current node as
hash ref. At minimum it must return the type of node at the current path.

Valid values are _scalar, list, hash, reference_. The types match the
accessor methods given above (use `get` for _scalar_).

    my $meta = $connector->get_meta( 'smartcard.owners' );
    my $type = $meta->{TYPE};

When you call a proxy connector without sufficient arguments to perform the
query, you will receive a value of _connector_ for type. Running a get\_\*
method against such a node will cause the connector to die!

## cleanup

Advise connectors to close, release or flush any open handle or sessions.
Should be called directly before the program terminates. Connectors might
be stale and not respond any longer after this was called.

# IMPLEMENTATION GUIDELINES

You SHOULD use the \_node\_not\_exists method if the requested path does not exist
or has an undefined value. This will internally take care of the _die\_on\_undef_
setting and throw an exception or return undef. So you can just write:

    if (path not exists || not defined val) {
        return $self->_node_not_exists( pathspec );
    }

As connectors are often used in eval constructs where the error messages
are swallowed you SHOULD log a verbose error before aborting with
die/confess. You can use the \_log\_and\_die method for this purpose. It will
send a message to the logger on error level before calling "die $message".

## path building

You should always pass the first parameter to the private `_build_path`
method. This method converts any valid path spec representation to a valid
path. It takes care of the RECURSEPATH setting and returns the path
elements as list.

## Supported methods

The methods get, get\_list, get\_size, get\_hash, get\_keys, set, get\_meta are
routed to the appropriate connector.

You MUST implement at minimum one of the three data getters, if get\_list/get\_keys
is omited, the base class will do a get\_list/get\_keys call and return the info
which will be a correct result but might be expensive, so you can provide your
own implementiation if required.

You MUST also implement the get\_meta method. If you have a connector with a
fixed type, you MAY check if the particular path exists and return
the result of _\_node\_not\_exists_.

## cleanup

Connectors that keep locks or use long-lived sessions that are not
bound to the lifetime of the perl process should implement this method
and cleanup their mess. While it would be nice, that connectors can be
revived after cleanup was called, this is not a strict requirement.

# AUTHORS

Scott Hardin <mrscotty@cpan.org>

Martin Bartosch

Oliver Welter

# COPYRIGHT

Copyright 2013/2021 White Rabbit Security Gmbh

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
