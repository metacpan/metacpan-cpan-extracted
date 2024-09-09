[![Actions Status](https://github.com/sanko/Acme-Free-Advice/actions/workflows/ci.yml/badge.svg)](https://github.com/sanko/Acme-Free-Advice/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Acme-Free-Advice.svg)](https://metacpan.org/release/Acme-Free-Advice)
# NAME

Acme::Free::Advice - Wise words. Dumb code.

# SYNOPSIS

```perl
use Acme::Free::Advice qw[advice];
say advice;
```

# DESCRIPTION

Acme::Free::Advice spits out advice. Good advice. Bad advice. Advice. It's a fortune cookie.

# METHODS

These functions may be imported by name or with the `:all` tag.

## `advice( [...] )`

Tear someone down.

```perl
my $wisdom = advice( ); # Random advice
print advice( ); # stringify
print advice( 'slip' );
```

Expected parameters include:

- `flavor`

    If undefined, a random supported flavor is used.

    Currently, supported flavors include:

    - `slip`

        Uses [Acme::Free::Advice::Slip](https://metacpan.org/pod/Acme%3A%3AFree%3A%3AAdvice%3A%3ASlip)

    - `unsolicited`

        Uses [Acme::Free::Advice::Unsolicited](https://metacpan.org/pod/Acme%3A%3AFree%3A%3AAdvice%3A%3AUnsolicited)

## `flavors( )`

```perl
my @flavors = flavors( );
```

Returns a list of supported advice flavors.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

Sanko Robinson <sanko@cpan.org>

## ...but why?

I'm inflicting this upon the world because [oodler577](https://github.com/oodler577/) invited me to help expand Perl's
coverage of smaller open APIs. Blame them or [join us](https://github.com/oodler577/FreePublicPerlAPIs) in the effort.
