# NAME

Class::Data::Lazy - Create class data with laziness.

# SYNOPSIS

    use Class::Data::Lazy qw(
        foo
    );

Is equivalent to:

    sub foo {
        my $class = shift;
        my $value = $class->_build_foo;
        *{"${class}::foo"} = sub { $value };
        return $value;
    }

# DESCRIPTION

Class::Data::Lazy is lazy class data maker.

I want to write lazy class accessor.

# MOTIVATION

When I'm writing a context class for web application, some thing need lazy building.

For example:

    package MyApp;

    use Class::Data::Lazy qw(
        memcached
    );

    sub _build_memcached {
        my $class = shift;
        my $conf = $class->config->{'Cache::Memcached::Fast'}
            or die "Missing configuration for Cache::Memcached::Fast";
        Cache::Memcached::Fast->new($conf);
    }

Q. Why should it be lazy class method?

A. Because `$class->config` is not available when the class is loading.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

If you wan to declare the lazy instance accessor, please try [Class::Accessor::Lite::Lazy](http://search.cpan.org/perldoc?Class::Accessor::Lite::Lazy).
