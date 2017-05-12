# NAME

Code::TidyAll::Plugin::Go - Provides gofmt and go vet plugins for Code::TidyAll

# VERSION

version 0.02

# SYNOPSIS

In your `.tidyallrc` file:

    [Go::Fmt]
    select = **/*.go

    [Go::Vet]
    select = **/*.go

# DESCRIPTION

This distro ships with two Go-related plugins for [Code::TidyAll](https://metacpan.org/pod/Code::TidyAll). The
`Go::Fmt` plugin formats your code with `gofmt`. The `Go::Vet` plugin runs
`go vet` against your code and dies if that command finds anything to
complain about.

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/Code-TidyAll-Plugin-Go/issues](https://github.com/maxmind/Code-TidyAll-Plugin-Go/issues).

# AUTHOR

Gregory Oschwald <goschwald@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
