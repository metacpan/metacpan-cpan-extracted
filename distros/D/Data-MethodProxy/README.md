# NAME

Data::MethodProxy - Inject dynamic data into static data.

# SYNOPSIS

```perl
use Data::MethodProxy;

my $mproxy = Data::MethodProxy->new();

my $output = $mproxy->render({
    half_six => ['$proxy', 'main', 'half', 6],
});
# { half_six => 3 }

sub half {
    my ($class, $number) = @_;
    return $number / 2;
}
```

# DESCRIPTION

A method proxy is an array ref describing a class method to call and the
arguments to pass to it.  The first value of the array ref is the scalar
`$proxy`, followed by a package name, then a subroutine name which must
callable in the package, and a list of any subroutine arguments.

```
[ '$proxy', 'Foo::Bar', 'baz', 123, 4 ]
```

The above is saying, do this:

```
Foo::Bar->baz( 123, 4 );
```

The ["render"](#render) method is the main entry point for replacing all found
method proxies in an arbitrary data structure with the return value of
calling the methods.

## Example

Consider this static YAML configuration:

```perl
---
db:
    dsn: DBI:mysql:database=foo
    username: bar
    password: abc123
```

Putting your database password inside of a configuration file is usually
considered a bad practice.  You can use a method proxy to get around this
without jumping through a bunch of hoops:

```perl
---
db:
    dsn: DBI:mysql:database=foo
    username: bar
    password:
        - $proxy
        - MyApp::Config
        - get_db_password
        - foo-bar
```

When ["render"](#render) is called on the above data structure it will
see the method proxy and will replace the array ref with the
return value of calling the method.

A method proxy, in Perl syntax, looks like this:

```
['$proxy', $package, $method, @args]
```

The `$proxy` string can also be written as `&proxy`.  The above is then
converted to a method call and replaced by the return value of the method call:

```
$package->$method( @args );
```

In the above database password example the method call would be this:

```
MyApp::Config->get_db_password( 'foo-bar' );
```

You'd still need to create a `MyApp::Config` package, and add a
`get_db_password` method to it.

# METHODS

## render

```perl
my $output = $mproxy->render( $input );
```

Traverses the supplied data looking for method proxies, calling them, and
replacing them with the return value of the method call.  Any value may be
passed, such as a hash ref, an array ref, a method proxy, an object, a scalar,
etc.  Array and hash refs will be recursively searched for method proxies.

If a circular reference is detected an error will be thrown.

## call

```perl
my $return = $mproxy->call( ['$proxy', $package, $method, @args] );
```

Calls the method proxy and returns its return.

## is\_valid

```
die unless $mproxy->is_valid( ... );
```

Returns true if the passed value looks like a method proxy.

## is\_callable

```
die unless $mproxy->is_callable( ... );
```

Returns true if the passed value looks like a method proxy,
and has a package and method which exist.

# SUPPORT

Please submit bugs and feature requests to the
Data-MethodProxy GitHub issue tracker:

[https://github.com/bluefeet/Data-MethodProxy/issues](https://github.com/bluefeet/Data-MethodProxy/issues)

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
