package Class::Data::Lazy;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

sub import {
    my $class = shift;
    my $pkg = caller(0);

    for my $name (@_) {
        my $builder = "_build_${name}";
        no strict 'refs';
        *{"${pkg}::${name}"} = sub {
            my $class = shift;
            my $value = $class->$builder();
            no warnings 'redefine';
            *{"${class}::${name}"} = sub { $value };
            return $value;
        };
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Class::Data::Lazy - Create class data with laziness.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Class::Data::Lazy is lazy class data maker.

I want to write lazy class accessor.

=head1 MOTIVATION

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

A. Because C<< $class->config >> is not available when the class is loading.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

If you wan to declare the lazy instance accessor, please try L<Class::Accessor::Lite::Lazy>.

=cut

