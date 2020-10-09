Name
====

Caller::Hide - hide packages from stack traces

Usage
=====

```perl
package My::Wrapper;
use Caller::Hide qw[ hide_package ];

hide_package(__PACKAGE__);
```

Description
===========

Wrapper modules shown in stack traces can sometimes be confusing.
These can be hidden by overriding caller to skip over the wrappers.
This module provides a single interface to hiding modules from caller
(and stack traces).

Author
======

Szymon Nieznański <snez@cpan.org>

Original caller override code adapted from Hook::LexWrap.

License
=======

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
