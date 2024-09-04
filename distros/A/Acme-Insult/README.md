[![Actions Status](https://github.com/sanko/Acme-Insult/actions/workflows/ci.yml/badge.svg)](https://github.com/sanko/Acme-Insult/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Acme-Insult.svg)](https://metacpan.org/release/Acme-Insult)
# NAME

Acme::Insult - Code That Wasn't Raised Right

# SYNOPSIS

```perl
use Acme::Insult qw[insult];
say insult;
```

# DESCRIPTION

Acme::Insult is kind of a jerk.

# METHODS

These functions may be imported by name or with the `:all` tag.

## `insult( [...] )`

Tear someone down.

```perl
my $shade = insult( ); # Random insult
print insult( ); # stringify
print insult( 'evil' );
```

Expected parameters include:

- `flavor`

    If undefined, a random supported flavor is used.

    Currently, supported flavors include:

    - `evil`

        Uses [Acme::Insult::Evil](https://metacpan.org/pod/Acme%3A%3AInsult%3A%3AEvil)

    - `glax`

        Uses [Acme::Insult::Glax](https://metacpan.org/pod/Acme%3A%3AInsult%3A%3AGlax)

## `flavors( )`

```perl
my @flavors = flavors( );
```

Returns a list of supported insult flavors.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

Sanko Robinson <sanko@cpan.org>

## ...but why?

I'm inflicting this upon the world because [oodler577](https://github.com/oodler577/) invited me to help expand Perl's
coverage of smaller open APIs. Blame them or [join us](https://github.com/oodler577/FreePublicPerlAPIs) in the effort.
