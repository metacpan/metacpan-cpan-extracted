# NAME

Data::Object::Role::Proxyable

# ABSTRACT

Proxyable Role for Perl 5

# SYNOPSIS

    package Example;

    use Moo;

    with 'Data::Object::Role::Proxyable';

    sub build_proxy {
      my ($self, $package, $method, @args) = @_;

      if ($method eq 'true') {
        return sub {
          return 1;
        }
      }

      if ($method eq 'false') {
        return sub {
          return 0;
        }
      }

      return undef;
    }

    package main;

    my $example = Example->new;

# DESCRIPTION

This package provides a wrapper around the `AUTOLOAD` routine which processes
calls to routines which don't exist. Adding a `build_proxy` method to the
consuming class acts as a hook into routine dispatching, which processes calls
to routines which don't exist. The `build_proxy` routine is called as a method
and receives `$self`, `$package`, `$method`, and any arguments passed to the
method as a list of arguments, e.g. `@args`. The `build_proxy` method must
return a routine (i.e. a callback) or the undefined value which results in a
"method missing" error.

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-role-proxyable/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-role-proxyable/wiki)

[Project](https://github.com/iamalnewkirk/data-object-role-proxyable)

[Initiatives](https://github.com/iamalnewkirk/data-object-role-proxyable/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-role-proxyable/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-role-proxyable/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-role-proxyable/issues)
