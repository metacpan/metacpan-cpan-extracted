# Chicken::Ipsum

Generate random chicken noises.

> Honk cluck-cluck-cluck bwok cluck! Gobble-gobble cluck waaak cluck-a-buh-gawk
> cluck-a-buh-gawk honk bwwwaaaaaaaaaak? Honk COCK-A-DOODLE-DOO bwok
> cock-a-doodle-doo CLUCKITY cluck-a-buh-gawk bwok cluck. Cluck-a-buh-gawk
> gobble-gobble bwok bwwwaaaaaaaaaak PUK bok bwwwaaaaaaaaaak...
>
> &mdash; Some [chicken][chicken-chicken-chicken], probably

## Why?

Often when developing a website or other application, it's important to have
placeholders for content. This module generates prescribed amounts of clucking,
cawing and other chicken-y noises.

## Usage

This module ships a script, `chicken-ipsum` which generates paragraphs of text:

```sh
$ chicken-ipsum
Cluck cluck-a-buh-gawk bok honk bwak bwak bwok cluckity. BWAK cluck-a-buh-gawk cock-a-doodle-doo puk gobble-gobble waaak gobble-gobble cock-a-doodle-doo. Cluck bwok honk cluck?
```

It accepts a single integer argument, being the number of chicken-y paragraphs to generate.

You can also use the `Chicken::Ipsum` module in your code.

```perl
require Chicken::Ipsum;
my $ci = Chicken::Ipsum->new();

# Generate a string of text with 5 words
$words = $ci->words(5);

# Generate a list of 5 words
@words = $ci->words(5);

# Generate a string of text with 2 sentences
$sentences = $ci->sentences(2);

# Generate a list of 2 sentences
@sentences = $ci->sentences(2);

# Generate a string of text with 3 paragraphs
$paragraphs = $ci->paragraphs(3);

# Generate a list of 3 paragraphs
@paragraphs = $ci->paragraphs(3);
```

## Installation

The simplest way to install `Chicken::Ipsum` is via `cpanm`:

```sh
cpanm Chicken::Ipsum
```

One can also install from source by first cloning the repository:

```sh
git clone https://codeberg.org/h3xx/perl-Chicken-Ipsum.git
```

then installing the build dependencies:

```sh
cpanm Carp List::Util
```

followed by the usual build and test steps:

```sh
perl Makefile.PL
make
make test
```

If all went well, you can now install the distribution by running:

```sh
make install
```

## Author

- Dan Church (h3xx[attyzatzat]gmx[dottydot]com)

## License and Copyright

Copyright (C) 2023 Dan Church.

This library is free software; you can redistribute it and/or modify it under
the [same terms as Perl itself](https://dev.perl.org/licenses/).

## Thanks

Thanks to Sebastian Carlos's [chickenipsum.lol](https://chickenipsum.lol/)
([GitHub](https://github.com/sebastiancarlos/chicken-ipsum)) for the inspiration.

*[Chicken.][chicken-chicken-chicken]*

[chicken-chicken-chicken]: https://isotropic.org/papers/chicken.pdf
