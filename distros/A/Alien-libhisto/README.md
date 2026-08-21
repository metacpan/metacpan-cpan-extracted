# Alien::libhisto

Perl Alien distribution that probes for or builds the `libhisto` fast C histogramming library.

## Installation

```bash
cpanm Alien::libhisto
```

Or from source:

```bash
perl Makefile.PL
make
make test
make install
```

## Synopsis

In your `Makefile.PL`:

```perl
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper qw( Alien::libhisto !export );

WriteMakefile(
    Alien::Base::Wrapper->mm_args2(
        NAME => 'Math::Histo',
        ...
    ),
);
```
