# NAME

Class::Accessor::Lite::Lazy - Class::Accessor::Lite with lazy accessor feature

# SYNOPSIS

    package MyPackage;

    use Class::Accessor::Lite::Lazy (
        rw_lazy => [
          # implicit builder method name is "_build_foo"
          qw(foo foo2),
          # or specify builder explicitly
          {
            xxx => 'method_name',
            yyy => sub {
              my $self = shift;
              ...
            },
          }
        ],
        ro_lazy => [ qw(bar) ],
        # Class::Accessor::Lite functionality is also available
        new => 1,
        rw  => [ qw(baz) ],
    );

    # or if you specify all attributes' builders explicitly
    use Class::Accessor::Lite::Lazy (
        rw_lazy => {
          foo => '_build_foo',
          bar => \&_build_bar,
        }
    );

    sub _build_foo {
        my $self = shift;
        ...
    }

    sub _build_bar {
        my $self = shift;
        ...
    }

# DESCRIPTION

Class::Accessor::Lite::Lazy provides a "lazy" accessor feature to [Class::Accessor::Lite](http://search.cpan.org/perldoc?Class::Accessor::Lite).

If a lazy accessor without any value set is called, a builder method is called to generate a value to set.

# THE USE STATEMENT

As [Class::Accessor::Lite](http://search.cpan.org/perldoc?Class::Accessor::Lite), the use statement provides the way to create lazy accessors.

- rw\_lazy => \\@name\_of\_the\_properties | \\%properties\_and\_builders

    Creates read / write lazy accessors.

- ro\_lazy => \\@name\_of\_the\_properties | \\%properties\_and\_builders

    Creates read-only lazy accessors.

- new, rw, ro, wo

    Same as [Class::Accessor::Lite](http://search.cpan.org/perldoc?Class::Accessor::Lite).

# FUNCTIONS

- `Class::Accessor::Lite::Lazy->mk_lazy_accessors(@name_of_the_properties)`

    Creates lazy accessors in current package.

- `Class::Accessor::Lite::Lazy->mk_ro_lazy_accessors(@name_of_the_properties)`

    Creates read-only lazy accessors in current package.

# SPECIFYING BUILDERS

As seen in SYNOPSIS, each attribute is specified by either a string or a hashref.

In the string form `$attr` you specify builders implicitly, the builder method name for the attribute _$attr_ is named \_build\__$attr_.

In the hashref form `{ $attr => $method_name | \&builder }` you can explicitly specify builders, each key is the attribute name and each value is
either a string which specifies the builder method name or a coderef itself.

# AUTHOR

motemen <motemen@gmail.com>

# SEE ALSO

[Class::Accessor::Lite](http://search.cpan.org/perldoc?Class::Accessor::Lite)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
