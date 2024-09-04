[![Actions Status](https://github.com/sanko/Acme-Free-Advice-Slip/actions/workflows/ci.yml/badge.svg)](https://github.com/sanko/Acme-Free-Advice-Slip/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Acme-Free-Advice-Slip.svg)](https://metacpan.org/release/Acme-Free-Advice-Slip)
# NAME

Acme::Free::Advice::Slip - Seek Advice from the Advice Slip API

# SYNOPSIS

```perl
use Acme::Free::Advice::Slip qw[advice];
say advice( 224 )->{advice};
```

# DESCRIPTION

Acme::Free::Advice::Slip provides wisdom from [AdviceSlip.com](https://adviceslip.com/).

# METHODS

These functions may be imported by name or with the `:all` tag.

## `advice( [...] )`

```perl
my $widsom = advice( ); # Random advice
my $advice = advice( 20 ); # Advice by ID
```

Seek advice.

You may request specific advice by ID.

Advice is provided as a hash reference containing the following keys:

- `advice`

    The sage advice you were looking for.

- `id`

    The advice's ID in case you'd like to request it again in the future.

## `search( ... )`

```perl
my @slips = search( 'time' );
```

Seek topical advice.

Advice is provided as a list of hash references containing the following keys:

- `advice`

    The sage advice you were looking for.

- `date`

    The date the wisdom was added to the database. It's in YYYY-MM-DD.

    I'm not sure why this isn't also returned when requesting advice by ID but that's how the backend works.

- `id`

    The advice's ID in case you'd like to request it again in the future.

# LICENSE & LEGAL

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

[AdviceSlip.com](https://adviceslip.com/) is brought to you by [Tom Kiss](https://tomkiss.net/).

# AUTHOR

Sanko Robinson <sanko@cpan.org>

## ...but why?

I'm inflicting this upon the world because [oodler577](https://github.com/oodler577/) invited me to help expand Perl's
coverage of smaller open APIs. Blame them or [join us](https://github.com/oodler577/FreePublicPerlAPIs) in the effort.
