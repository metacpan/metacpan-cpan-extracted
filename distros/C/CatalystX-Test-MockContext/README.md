# NAME

CatalystX::Test::MockContext - Conveniently create $c objects for testing

# VERSION

version 0.000004

# SYNOPSIS

```perl
use HTTP::Request::Common;
use CatalystX::Test::MockContext;

my $m = mock_context('MyApp');
my $c = $m->(GET '/');
```

# EXPORTS

## mock\_context

```perl
my $sub = mock_context('MyApp');
```

This function returns a closure that takes an [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) object and returns a
[Catalyst](https://metacpan.org/pod/Catalyst) context object for that request.

# SOURCE

The development version is on github at [https://github.com/robrwo/CatalystX-Test-MockContext](https://github.com/robrwo/CatalystX-Test-MockContext)
and may be cloned from [git://github.com/robrwo/CatalystX-Test-MockContext.git](git://github.com/robrwo/CatalystX-Test-MockContext.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/CatalystX-Test-MockContext/issues](https://github.com/robrwo/CatalystX-Test-MockContext/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see `SECURITY.md` for instructions how to
report security vulnerabilities.

# AUTHOR

Eden Cardim <edencardim@gmail.com>

Currently maintained by Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2025 by Eden Cardim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
