# NAME

Algorithm::UrataniTakeda - an implementation of the Uratani-Takeda string searching algorithm

# STATUS

This is an experimental implementation.
It may not be correct.

# SYNOPSIS

```perl
use Algorithm::UrataniTakeda;

use experimental qw( signatures ); # for Perl versions before v5.36

my $m = Algorithm::UrataniTakeda->new( \@patterns );

my $match = $m->first($text);

my @all = $m->matches($text);

if ( $m->has_match($text) ) {
    ...
}

sub callback( $pos, $phrase ) {
    ...
    return 1;
}

while (<STDIN>) {
    $m->search( $_, \&callback );
}
```

# DESCRIPTION

This is an implementation of the Uratani-Takeda algorithm for searching for multiple strings.

It combines the Aho-Corasick algorithm with the Boyer-Moore algorithm, and is similar to the Commentz-Walter algorithm.

# RECENT CHANGES

Changes for version v0.1.8 (2026-10-21)

- Enhancements
    - Improved the performance for setting up the fail shift cache.
    - Improved the performance when checking for complete matches.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [List::Util](https://metacpan.org/pod/List%3A%3AUtil)
- [Object::Pad](https://metacpan.org/pod/Object%3A%3APad) version 0.59 or later
- [integer](https://metacpan.org/pod/integer)
- [perl](https://metacpan.org/pod/perl) version v5.26.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Algorithm::UrataniTakeda
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.26 or later.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Algorithm-UrataniTakeda/issues](https://github.com/robrwo/perl-Algorithm-UrataniTakeda/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Algorithm-UrataniTakeda](https://github.com/robrwo/perl-Algorithm-UrataniTakeda)
and may be cloned from [https://github.com/robrwo/perl-Algorithm-UrataniTakeda.git](https://github.com/robrwo/perl-Algorithm-UrataniTakeda.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

This implementation was based on
Uratani N. and Takeda M.,
"A Fast String-Searching Algorithm for Multiple Patterns", **Information, Processing & Management 29 (6)**, pp. 775-791, 1993.
[doi:10.1016/0306-4573(93)90106-N](doi:10.1016/0306-4573\(93\)90106-N).
